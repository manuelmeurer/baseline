# frozen_string_literal: true

module Baseline
  module SubscriptionsControllable
    extend ActiveSupport::Concern

    included do
      rate_limit_create

      wrap_parameters :subscription,
        format:  :url_encoded_form,
        include: Subscription.identifiers

      before_action only: %i[show update] do
        if @user = User.find_signed(params[:id])
          I18n.locale = @user.locale
          @subscription_identifiers = Subscription.valid_identifiers_for(@user)
        else
          html_redirect_to(web_home_path)
        end
      end
    end

    def create
      identifier = create_params.fetch(:identifier)

      unless @subscription = Subscription.find_by(identifier:)
        ReportError.call "Unknown subscription identifier: #{identifier}"
        head :not_found
        return
      end

      if validate_turnstile
        do_create
      else
        SpamRequest.create! \
          kind: :subscription,
          data: create_params
      end
    end

    def show
      unauthenticate if ::Current.user&.then { _1 != @user }
      set_noindex_header
    end

    def update
      @user.update_subscriptions(update_params)
      render_turbo_response \
        success_message: t(:success, scope: action_i18n_scope)
    end

    private

      def do_create
        email = create_params.fetch(:email)
        unless EmailValidator.valid?(email)
          ReportError.call "Email is invalid: #{email}"
          head :unprocessable_entity
          return
        end

        user_params = create_params.except(:identifier, :email)
        %i[first_name last_name].each do |field|
          user_params[field] ||= email
        end
        @user =
          User.find_by(email: create_params[:email]) ||
          User
            .new(user_params)
            .tap { _1.email = create_params[:email] }
            .tap { before_create_user(_1) }
            .tap(&:save!)

        message_kind = @user.subscribed?(@subscription.identifier) ?
          :subscription_existing :
          :subscription_new

        @user
          .messages
          .where(kind: message_kind, messageable: @subscription)
          .build
          ._do_create_and_send
      end

      def create_params
        params.expect(subscription: %i[identifier first_name last_name email])
      end

      def update_params
        params.expect(subscription: @subscription_identifiers)
      end

      # Hook method to be overridden in including controllers.
      def before_create_user(user); end
  end
end

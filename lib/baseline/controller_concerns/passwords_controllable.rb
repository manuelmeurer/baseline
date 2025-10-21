# frozen_string_literal: true

module Baseline
  module PasswordsControllable
    extend ActiveSupport::Concern

    included do
      require_unauthenticated_access
      rate_limit_create

      before_action only: %i[edit update] do
        @user = User.find_by_password_reset_token!(params[:token])
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        add_flash :alert, t(:invalid_token, scope: :reset_password)
        html_redirect_to action: :new
      end
    end

    def new
    end

    def create
      if params[:email].blank?
        message = t(:email_blank, scope: :reset_password)
        add_flash :alert, message
        redirect_to action: :new
        return
      end

      if user = find_user(params[:email])
        user
          .messages
          .password_reset
          .build
          ._do_create_and_send \
            delivery_method: :email
      end

      add_flash :notice, t(:email_sent, scope: :reset_password)
      html_redirect_to [::Current.namespace, :login]
    end

    def edit
    end

    def update
      if @user.update(params.permit(:password, :password_confirmation))
        authenticate @user
        add_flash :notice, t(:success, scope: :reset_password)
        html_redirect_to [::Current.namespace, :root]
      else
        error_details = @user.errors.details
        expected_error =
          error_details.keys.difference(%i[password password_confirmation]).none? &&
          (
            error_details[:password].none? ||
            (
              error_details[:password].one? &&
              error_details[:password].first.fetch(:error).in?(%i[too_short too_long])
            )
          ) && (
            error_details[:password_confirmation].none? ||
            (
              error_details[:password_confirmation].one? &&
              error_details[:password_confirmation].first.fetch(:error) == :confirmation
            )
          )
        error_message = if expected_error
          @user.errors.full_messages.to_sentence
        else
          ReportError.call "Unexpected errors: #{error_details}"
          t(:generic_error)
        end
        render_turbo_response \
          error_message:
      end
    end

    private def find_user(email) = User.find_by(email:)
  end
end

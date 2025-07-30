# frozen_string_literal: true

module Baseline
  module PasswordsControllable
    extend ActiveSupport::Concern

    included do
      require_unauthenticated_access

      before_action only: %i[edit update] do
        @user = User.find_by_password_reset_token!(params[:token])
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        add_flash :alert, "Password reset link is invalid or has expired."
        html_redirect_to [:new, ::Current.namespace, :password]
      end
    end

    def new
    end

    def create
      if user = find_user(params[:email])
        UserMailer
          .with(user:)
          .password_reset
          .deliver_later
      end

      add_flash :notice, "Password reset instructions sent (if user with that email address exists)."
      html_redirect_to [::Current.namespace, :root]
    end

    def edit
    end

    def update
      if @user.update(params.permit(:password, :password_confirmation))
        add_flash :notice, "Password has been reset."
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
          "Error, please try again."
        end
        render_turbo_response \
          error_message:
      end
    end

    private def find_user(email)
      User.find_by(email:)
    end
  end
end

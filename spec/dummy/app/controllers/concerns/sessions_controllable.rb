# frozen_string_literal: true

module SessionsControllable
  extend ActiveSupport::Concern

  included do
    require_unauthenticated_access except: :destroy
    rate_limit_create
  end

  def new; end

  def create
    credentials = params.expect(session: %i[email password])
    user        = auth_user_scope.authenticate_by(credentials)

    unless user
      add_flash :alert, "Wrong credentials."
      html_redirect_to [Current.namespace, :login]
      return
    end

    authenticate_and_redirect(user)
  end

  def destroy
    unauthenticate
    render_turbo_response \
      redirect: [Current.namespace, :root]
  end
end

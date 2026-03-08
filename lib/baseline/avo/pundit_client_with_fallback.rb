# frozen_string_literal: true

module Baseline
  module Avo
    class PunditClientWithFallback < ::Avo::Pro::Authorization::Clients::PunditClient
      def authorize(user, record, action, policy_class: nil)
        super
      rescue ::Avo::NoPolicyError
        policy_for(user, record).public_send(action) ?
          true :
          raise(::Avo::NotAuthorizedError.new("Not authorized"))
      end

      def policy(...)
        ::Pundit.policy(...) ||
          ::Baseline::ApplicationPolicy.new(...)
      end

      def policy!(...)
        ::Pundit.policy!(...)
      rescue ::Pundit::NotDefinedError
        ::Baseline::ApplicationPolicy.new(...)
      end

      def apply_policy(user, model, policy_class: nil)
        super
      rescue ::Avo::NoPolicyError
        ::Baseline::ApplicationPolicy::Scope.new(user, model).resolve
      end

      private

        def policy_for(...) = policy(...)
    end
  end
end

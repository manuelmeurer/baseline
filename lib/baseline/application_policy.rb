# frozen_string_literal: true

module Baseline
  class ApplicationPolicy
    # When a policy inherits from this class, check all associations of the policy class
    # and call Avo`s `inherit_association_from_policy` for those that have a corresponding policy class.
    # https://docs.avohq.io/3.0/authorization.html#removing-duplication
    def self.inherited(subclass)
      unless defined?(::Avo::Pro)
        raise "Policies can only be used with Avo Pro."
      end

      subclass.include ::Avo::Pro::Concerns::PolicyHelpers

      klass = subclass
        .to_s
        .delete_suffix("Policy")
        .constantize

      klass
        .reflect_on_all_associations
        .each do |association|
          policy_klass = association
            .class_name
            .then { "#{_1}Policy" }
            .safe_constantize
          next unless policy_klass
          subclass.inherit_association_from_policy \
            association.name,
            policy_klass
        end
    end

    attr_reader :user, :record

    def initialize(user, record)
      @user, @record =
        user, record
    end

    def index?   = true
    def show?    = true
    def create?  = true
    def new?     = create?
    def update?  = true
    def edit?    = update?
    def destroy? = true
    def search?  = true
    def reorder? = true
    def act_on?  = true

    def method_missing(method, ...)
      return true if attachment_policy_method?(method)
      super
    end

    def respond_to_missing?(method, include_private = false)
      return true if attachment_policy_method?(method)
      super
    end

    class Scope
      def initialize(user, scope)
        @user, @scope =
          user, scope
      end

      def resolve = scope.all

      private

        attr_reader :user, :scope
    end

    private

      def attachment_policy_method?(method)
        if attachment = method[/\A(?:upload|delete|download)_(.+)\?\z/, 1]
          if @record.class.reflect_on_attachment(attachment)
            return true
          end
        end

        false
      end
  end
end

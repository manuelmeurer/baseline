# frozen_string_literal: true

module Baseline
  class ApplicationPolicy
    include ::Avo::Pro::Concerns::PolicyHelpers

    # When a policy inherits from this class, check all associations of the policy class
    # and call Avo`s `inherit_association_from_policy` for those that have a corresponding policy class.
    # https://docs.avohq.io/3.0/authorization.html#removing-duplication
    def self.inherited(subclass)
      klass = subclass
        .to_s
        .delete_suffix("Policy")
        .constantize

      klass
        .reflections
        .select { _2.collection? }
        .keys
        .without(%w[versions]) # Papertrail versions
        .each do |association|
          policy_klass = klass
            .reflect_on_association(association)
            .class_name
            .then { "#{_1}Policy" }
            .safe_constantize
          next unless policy_klass
          inherit_association_from_policy \
            association,
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

    class Scope
      def initialize(user, scope)
        @user, @scope =
          user, scope
      end

      def resolve = scope.all

      private

        attr_reader :user, :scope
    end
  end
end

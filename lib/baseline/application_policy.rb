# frozen_string_literal: true

module Baseline
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user, @record =
        user, record
    end

    def index?   = true
    def show?    = true
    def create?  = false
    def new?     = create?
    def update?  = false
    def edit?    = update?
    def destroy? = false
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

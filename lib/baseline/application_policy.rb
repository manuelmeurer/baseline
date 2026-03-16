# frozen_string_literal: true

module Baseline
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user, @record =
        user, record

      define_association_policy_methods!
      define_attachment_policy_methods!
    end

    def index?   = true
    def show?    = true
    def create?  = superadmin?
    def new?     = create?
    def update?  = true
    def edit?    = update?
    def destroy? = superadmin?
    def search?  = true
    def reorder? = true
    def act_on?  = true
    def attach?  = superadmin?
    def detach?  = superadmin?

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

      # Avo checks association-specific policy methods like `view_tickets?` or `create_comments?`
      # using `.methods` (not `respond_to?`). With `explicit_authorization = true`, Avo denies
      # access when the method is missing, hiding has_many sections entirely.
      #
      # Avo's recommended approach is `inherit_association_from_policy` (called in the `inherited`
      # hook of the policy class), but that only works for named subclasses — not when this base
      # class is used directly as a fallback (via PunditClientWithFallback).
      #
      # Instead, we define singleton methods in `initialize` for every association on the record's
      # model. This replaces `inherit_association_from_policy` entirely because it:
      # 1. Works for both subclasses and the fallback policy (no named subclass required)
      # 2. Makes methods visible to Avo's `has_method?` check (which uses `.methods`)
      # 3. Delegates to the associated model's policy if one exists (e.g. TicketPolicy),
      #    otherwise falls back to the base policy method (e.g. `index?`)
      ASSOCIATION_POLICY_ACTIONS = {
        view:    :index?,
        create:  :create?,
        edit:    :update?,
        update:  :update?,
        destroy: :destroy?,
        show:    :show?,
        reorder: :reorder?,
        act_on:  :act_on?,
        attach:  :attach?,
        detach:  :detach?
      }.freeze

      def define_association_policy_methods!
        model_class = @record.unless(Class, &:class)
        return unless model_class.respond_to?(:reflect_on_all_associations)

        model_class
          .reflect_on_all_associations
          .reject { _1.options[:polymorphic] }
          .each do |association|
            policy_class = "#{association.class_name}Policy".safe_constantize

            ASSOCIATION_POLICY_ACTIONS.each do |action, base_method|
              method_name = :"#{action}_#{association.name}?"

              # Skip if the subclass explicitly defines this method — let the
              # hand-written override win over the auto-generated delegation.
              next if self.class.method_defined?(method_name, false)

              if policy_class
                define_singleton_method(method_name) do
                  policy_class.new(user, record).public_send(base_method)
                end
              else
                define_singleton_method(method_name) do
                  public_send(base_method)
                end
              end
            end
          end
      end

      # Avo checks `upload_avatar?`, `delete_avatar?`, `download_avatar?` for Active Storage
      # attachments. All are permitted by default.
      ATTACHMENT_POLICY_ACTIONS = %i[upload delete download].freeze

      def define_attachment_policy_methods!
        model_class = @record.unless(Class, &:class)
        return unless model_class.respond_to?(:reflect_on_all_attachments)

        model_class.reflect_on_all_attachments.each do |attachment|
          ATTACHMENT_POLICY_ACTIONS.each do |action|
            define_singleton_method(:"#{action}_#{attachment.name}?") { true }
          end
        end
      end

      def superadmin? = user.role?(:superadmin)
  end
end

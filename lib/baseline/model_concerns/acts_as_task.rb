# frozen_string_literal: true

module Baseline
  module ActsAsTask
    extend ActiveSupport::Concern

    included do
      include HasTimestamps[:done_at, :due_on],
              TouchAsync[:taskable]

      TODOIST_DESCRIPTION_DIVIDER = "--- DON'T EDIT BELOW THIS LINE ---".freeze
      TODOIST_DESCRIPTION_DIVIDER_REGEX = /\s*#{Regexp.escape TODOIST_DESCRIPTION_DIVIDER}[\s\S]*\z/.freeze
      MARKDOWN_LINK_REGEX = %r{
        \[
          [^\]]+
        \]
        \(
          ([^\)]+)
        \)
      }ix.freeze

      enum :priority,
        %i[low medium high],
        prefix:   true,
        default:  :medium,
        validate: true

      belongs_to :creator, polymorphic: true, optional: true
      belongs_to :responsible, polymorphic: true
      belongs_to :taskable, polymorphic: true, optional: true

      scope :identifier_prefix,    -> { where("identifier LIKE ?", "#{_1}%") }
      scope :too_old_for_todoist,  -> { done_before(6.months.ago) }
      scope :overdue,              -> { due_before(Date.today) }
      scope :due_today,            -> { where(due_on: Date.current) }

      cattr_accessor :processing_todoist_event

      after_commit do
        unless
          self.class.processing_todoist_event ||
          previous_changes.keys.sort == %w[todoist_id updated_at]

          Baseline::Tasks::Todoist::Update.call_async \
            (persisted? ? self : as_json),
            previous_changes
        end
      end

      validates :title, presence: true
      validates :due_on, presence: true
      validates :responsible_type, inclusion: { in: -> { valid_responsibles }, allow_nil: true }
      validates :creator_type,     inclusion: { in: -> { valid_creators },     allow_nil: true }
      validates :todoist_id, uniqueness: { allow_nil: true }

      validate on: :create, if: :responsible do
        if responsible.try(:deactivated?)
          errors.add :responsible, message: "must not be deactivated"
        end
      end

      after_initialize if: :new_record? do
        self.due_on      ||= Date.current
        self.responsible ||= default_responsible
      end
    end

    class_methods do
      # This will generate corresponding scopes and methods.
      def status_scopes
        {
          done:   nil,
          undone: nil
        }
      end
    end

    def to_s
      %("#{title}" on #{due_on ? I18n.l(due_on) : "?"})
    end

    def too_old_for_todoist?
      self.class.too_old_for_todoist.exists?(id)
    end

    def responsible_admin_todoist_access_token
      if responsible.is_a?(AdminUser)
        responsible.todoist_access_token
      end
    end

    def todoist_description
      meta = [
        avo_url,
        if taskable
          [
            %(#{taskable.model_name.human} "#{taskable}"),
            taskable.avo_url
          ].compact.join("\n")
        end
      ].compact.join("\n\n")

      [
        details,
        meta
      ].compact.join("\n\n#{TODOIST_DESCRIPTION_DIVIDER}\n\n")
    end

    def todoist_description=(value)
      self.details = value
        .sub(TODOIST_DESCRIPTION_DIVIDER_REGEX, "")
        .gsub(MARKDOWN_LINK_REGEX, "\\1")
    end

    def todoist_priority
      return unless priority

      self
        .class
        .priorities
        .fetch(priority)
        .+(2)
        .tap {
          unless (1..4).cover?(_1)
            raise "Expected Todoist priority to be betwen 1 and 4."
          end
        }
    end

    def todoist_priority=(value)
      priority   = [value - 2, 0].max
      priorities = self.class.priorities.values

      if priorities.include?(priority)
        self.priority = priority
      else
        raise "Priority #{priority} is invalid, expected one of #{priorities}."
      end
    end
  end
end

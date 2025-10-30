# frozen_string_literal: true

module Baseline
  module ActsAsEmailDelivery
    extend ActiveSupport::Concern

    included do
      include HasSections,
              HasTimestamps[:sent_at, :scheduled_at]

      belongs_to :admin_user, optional: true
      belongs_to :deliverable, polymorphic: true, inverse_of: :email_delivery

      validates :subject, presence: true
      validates :recipients, presence: true
      validates :sections, presence: true
      validates :bounced_emails,
        absence: { if: :unsent? },
        array_uniqueness: true
      validates :rejected_emails,
        absence: { if: :sent? },
        array_uniqueness: true

      validate if: -> { deliverable.respond_to?(:valid_recipients) } do
        invalid_recipients = recipients.keys - deliverable.valid_recipients
        if invalid_recipients.any?
          errors.add :recipients, message: "contain invalid elements: #{invalid_recipients.to_sentence}"
        end
      end
      validate do
        %i[rejected_emails bounced_emails].each do |attribute|
          invalids = public_send(attribute) - recipients.values
          if invalids.any?
            errors.add attribute, message: "contain invalid elements: #{invalids.join(", ")}"
          end
        end
      end

      scope :rejected,   -> { where.not(rejected_emails: []) }
      scope :unrejected, -> { where(rejected_emails: []) }
      scope :clones_of,  ->(email_delivery) {
        where(
          subject: email_delivery.subject,
          **%i[
            recipients
            cc_recipients
            bcc_recipients
          ].index_with { email_delivery.read_attribute _1 }
        ).excluding(email_delivery)
          .select {
            _1.sections.size == email_delivery.sections.size &&
              _1.sections.each_with_index.all? { |section, index| section.clone_of?(email_delivery.sections[index]) }
          }
      }

      before_validation on: :create do
        if recipients.none? &&
          deliverable.respond_to?(:valid_recipients) &&
          deliverable.valid_recipients.one?

          self.recipients = deliverable.valid_recipients
        end
      end

      [nil, :cc, :bcc].each do |prefix|
        attribute = [prefix, :recipients].compact.join("_").to_sym

        # https://stackoverflow.com/a/45849743/155050
        scope :"with_#{attribute}_email", ->(email) { where(%(jsonb_path_exists(#{attribute}, '$.** ? (@ == "#{email}")'))) }

        define_method attribute do
          super().transform_keys do
            GlobalID.find! _1
          rescue ActiveRecord::RecordNotFound
            _1
          end
        end

        define_method "#{attribute}=" do |value|
          unless value.is_a?(Hash)
            value = Array(value)
          end
          if value.is_a?(Array)
            value = value
              .compact_blank
              .each_with_object({}) do |gid_and_email_or_record, hash|
                if gid_and_email_or_record.is_a?(String)
                  gid, email = gid_and_email_or_record.split(";", 2)
                  record = GlobalID.find!(gid)
                else
                  record = gid_and_email_or_record
                end
                hash[record] = email.presence || record.email
              end
          end
          value = value.transform_keys { _1.to_gid.to_s }

          write_attribute attribute, value
        end
      end
    end

    def form_of_address
      recipients.first.try(:form_of_address) || :informal
    end

    def locale
      deliverable.try(:locale) ||
        deliverable.try(:language)&.locale
    end

    def attached_files
      deliverable.try(:attached_files) || {}
    end

    def to_s
      to   = recipients.map { "#{_1} (#{_2})" }.to_sentence.presence || "no recipients"
      sent = sent? ? "sent on #{I18n.l sent_at}" : "unsent"

      "Email delivery to #{to} (#{sent})"
    end

    def postmark_message_stream = nil
    def header_url              = nil
    def web_url                 = nil
    def unsubscribe_params      = nil
    def unsubscribe_url         = nil

    %i[bounced rejected].each do |type|
      define_method "#{type}?" do
        public_send("#{type}_emails").any?
      end
    end
  end
end

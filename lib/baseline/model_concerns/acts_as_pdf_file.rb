# frozen_string_literal: true

module Baseline
  module ActsAsPDFFile
    extend ActiveSupport::Concern

    included do
      include HasFriendlyID,
              TouchAsync[:pdfable]

      belongs_to :pdfable, polymorphic: true, optional: true
      belongs_to :original, class_name: to_s, optional: true

      has_many :copies, class_name: to_s, foreign_key: :original_id

      has_one_attached_and_accepts_nested_attributes_for :file, production_service: :cloudflare

      before_validation on: :create do
        if original && respond_to?(:assign_attributes_from_original, true)
          assign_attributes_from_original
        end
      end

      validates :title, presence: true
      validates :file, attached: true, content_type: { in: :pdf, message: "must be PDF" }

      delegate :to_s, to: :title
    end

    private

      def should_generate_new_friendly_id?
        title_changed? || super
      end

      def custom_slug
        [new_slug_identifier, title].join(" ")
      end

      def assign_attributes_from_original
        self.title = original.title
        self.file  = {
          io:       StringIO.new(original.file.download),
          filename: original.file.filename.to_s
        }
      end
  end
end

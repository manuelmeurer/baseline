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

      before_validation on: :create, if: :original do
        io = if Rails.env.development? && original.file.service_name != Rails.application.config.active_storage.service.to_s
          Rails
            .root
            .join("spec", "support", "dummy.pdf")
            .then {
              File.open _1
            }
        else
          StringIO.new(original.file.download)
        end

        self.title = original.title
        self.file  = {
          io:,
          filename: original.file.filename.to_s
        }
      end

      validates :title, presence: true
      validates :file, attached: true, content_type: { in: :pdf, message: "must be PDF" }

      delegate :to_s, to: :title

      private

        def should_generate_new_friendly_id?
          title_changed? || super
        end

        def custom_slug
          [new_slug_identifier, title].join(" ")
        end
    end
  end
end

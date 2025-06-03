# frozen_string_literal: true

module Baseline
  module HasPDFFiles
    def self.[](many:)
      Module.new do
        extend ActiveSupport::Concern

        included do
          params = {
            as:         :pdfable,
            dependent:  :destroy,
            inverse_of: :pdfable
          }
          method, association =
            many ?
              %i[has_many pdf_files] :
              %i[has_one pdf_file]

          public_send method, association, **params

          accepts_nested_attributes_for \
            association,
            allow_destroy: true,
            update_only:   true,
            reject_if:     -> { _1.values_at(:file, :original_id).all?(&:blank?) }
        end
      end
    end
  end
end

# frozen_string_literal: true

module Baseline
  module HasDummyImageAttachment
    def self.[](attribute)
      Module.new do
        extend ActiveSupport::Concern

        define_method :"#{attribute}_or_dummy" do
          attached = public_send(attribute)
          return attached if attached.attached?

          cache_key = [
            :attachment_dummy_blob_id,
            self.class.to_s.underscore,
            attribute
          ]
          if blob_id = Rails.cache.read(cache_key)
            return ActiveStorage::Blob.find(blob_id)
          end

          image_assets = Rails.application.image_assets("dummy")
          file = image_assets.values.detect {
            File.basename(_1).start_with? "#{self.class.to_s.underscore}_#{attribute}."
          }
          unless file
            raise "No dummy image found for: #{self.class}##{attribute}"
          end

          ActiveStorage::Blob.create_and_upload!(
            filename: File.basename(file),
            io:       file
          ).tap {
            Rails.cache.write(cache_key, _1.id)
          }
        end
      end
    end
  end
end

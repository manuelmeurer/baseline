# frozen_string_literal: true

module Baseline
  module HasDummyImageAttachment
    def self.[](attribute)
      Module.new do
        extend ActiveSupport::Concern

        define_method :"#{attribute}_or_dummy" do
          public_send(attribute).unless(-> { _1.attached? }) do
            public_send("dummy_#{attribute}")
          end
        end

        define_method :"dummy_#{attribute}" do
          cache_key = [
            :attachment_dummy_blob_id,
            self.class.to_s.underscore,
            attribute
          ]
          if blob_id = Rails.cache.read(cache_key)
            begin
              blob = ActiveStorage::Blob.find(blob_id)
            rescue ActiveRecord::RecordNotFound
              Rails.cache.delete(cache_key)
            else
              return blob
            end
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

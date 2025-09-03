# frozen_string_literal: true

module Baseline
  module TouchAsync
    def self.[](*associations)
      Module.new do
        extend ActiveSupport::Concern

        included do
          @touch_async_associations ||= Set.new
          @touch_async_associations.merge \
            associations.map(&:to_sym)

          after_commit on: %i[create update] do
            if saved_changes?
              Toucher.new.add(self)
              unless Toucher.enqueued?
                Toucher.call_async
              end
            end
          end
        end

        class_methods do
          def touch_async_associations
            Array(@touch_async_associations)
              .if(base_class != self) {
                _1 + base_class.try(:touch_async_associations)
              }
          end
        end
      end
    end
  end
end

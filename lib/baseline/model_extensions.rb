module Baseline
  module ModelExtensions
    extend ActiveSupport::Concern

    included do
      %i(one many).each do |one_or_many|
        has_attached_method = :"has_#{one_or_many}_attached"

        define_singleton_method has_attached_method do |*args, production_service: nil, **kwargs|
          if production_service && Rails.env.production?
            kwargs[:service] = production_service
          end

          super *args, **kwargs
        end

        define_singleton_method :"#{has_attached_method}_and_accepts_nested_attributes_for" do |attribute, **kwargs|
          attachment_attribute = [
            attribute,
            one_or_many == :many ? :attachments : :attachment
          ].join("_")
          .to_sym

          public_send has_attached_method, attribute, **kwargs
          accepts_nested_attributes_for attachment_attribute, allow_destroy: true
        end
      end
    end
  end
end

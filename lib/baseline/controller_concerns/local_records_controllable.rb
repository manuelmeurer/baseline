# frozen_string_literal: true

module Baseline
  module LocalRecordsControllable
    extend ActiveSupport::Concern

    included do
      before_action only: :show do
        next unless params[:draft] && params[:format]
        mime_type = Marcel::MimeType.for(extension: params[:format]).split("/").last.to_sym
        next unless mime_type.in?(ApplicationRecord.common_image_file_types)
        file = [params[:id], params[:format]].join(".")
        self
          .class
          .name
          .delete_suffix("Controller")
          .singularize
          .constantize
          .path
          .join("drafts", file)
          .then {
            File.exist?(_1) ?
              send_file(_1, disposition: :inline) :
              head(:not_found)
          }
      end
    end
  end
end

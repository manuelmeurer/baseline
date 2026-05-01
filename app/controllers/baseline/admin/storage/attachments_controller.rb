# frozen_string_literal: true

module Baseline
  module Admin
    module Storage
      class AttachmentsController < BaseController
        before_action :ensure_storage_available
        before_action :set_attachment, only: :show

        def index
          @record_types = ActiveStorage::Attachment.distinct.pluck(:record_type).compact.sort
          @content_types = ActiveStorage::Blob
            .joins(:attachments)
            .distinct
            .pluck(:content_type)
            .compact
            .sort

          scope = Baseline::Storage::AttachmentFilter
            .new(ActiveStorage::Attachment.includes(:blob).order(created_at: :desc), params)
            .apply

          @total_count = scope.count
          @attachments = paginate(scope)
        end

        def show
          @blob = @attachment.blob
        end

        _baseline_finalize

        private

          def set_attachment
            @attachment = ActiveStorage::Attachment.find(params[:id])
          end
      end
    end
  end
end

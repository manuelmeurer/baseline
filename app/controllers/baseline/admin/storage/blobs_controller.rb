# frozen_string_literal: true

module Baseline
  module Admin
    module Storage
      class BlobsController < BaseController
        before_action :ensure_storage_available
        before_action :set_blob, only: :show

        def index
          @content_types = ActiveStorage::Blob.distinct.pluck(:content_type).compact.sort
          @service_names = ActiveStorage::Blob.distinct.pluck(:service_name).compact.sort

          scope = Baseline::Storage::BlobFilter
            .new(ActiveStorage::Blob.order(created_at: :desc), params)
            .apply

          @total_count = scope.count
          @blobs       = paginate(scope)
        end

        def show
          @attachments = @blob.attachments.order(created_at: :desc)
        end

        _baseline_finalize

        private

          def set_blob
            @blob = ActiveStorage::Blob.find(params[:id])
          end
      end
    end
  end
end

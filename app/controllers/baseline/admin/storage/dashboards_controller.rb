# frozen_string_literal: true

module Baseline
  module Admin
    module Storage
      class DashboardsController < BaseController
        def show
          return unless storage_available?

          @blobs_count           = ActiveStorage::Blob.count
          @attachments_count     = ActiveStorage::Attachment.count
          @total_storage         = ActiveStorage::Blob.sum(:byte_size)
          @orphaned_blobs_count  = orphaned_blobs.count
          @largest_blob          = ActiveStorage::Blob.order(byte_size: :desc).first
          @recent_blobs          = ActiveStorage::Blob.order(created_at: :desc).limit(5)
          @content_types         = ActiveStorage::Blob.group(:content_type)
            .count
            .sort_by { -_2 }
            .first(8)
        end

        _baseline_finalize

        private

          def orphaned_blobs
            ActiveStorage::Blob
              .left_outer_joins(:attachments)
              .where(active_storage_attachments: { id: nil })
          end
      end
    end
  end
end

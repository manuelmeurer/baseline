# frozen_string_literal: true

module Baseline
  module Admin
    module Storage
      class BaseController < Baseline::Admin::BaseController
        helper_method \
          :active_storage_blob_path,
          :attachment_record_label,
          :format_storage_bytes,
          :media_previewable_blob?,
          :pagination_links,
          :storage_available?

        private

          def page_title = "Storage"

          def ensure_storage_available
            return if storage_available?

            redirect_to storage_dashboard_path,
              alert: "Active Storage tables are not available."
          end

          def storage_available?
            Baseline::Storage.available?
          end

          def format_storage_bytes(bytes)
            Baseline::Storage.format_bytes(bytes)
          end

          def media_previewable_blob?(blob)
            blob&.content_type.to_s.match?(
              %r{\A(image|video|audio)/|\Aapplication/pdf\z}
            )
          end

          def active_storage_blob_path(blob, disposition: :inline)
            main_app.rails_blob_path(
              blob,
              disposition:,
              only_path:   true
            )
          end

          def attachment_record_label(attachment)
            attachment.record.then { "#{_1} (ID: #{_1.id})" }
          rescue ActiveRecord::RecordNotFound, NameError
            "Record not found"
          end

          def paginate(scope, per_page: 25)
            @per_page = per_page
            @page     = [params[:page].to_i, 1].max
            scope.limit(@per_page).offset((@page - 1) * @per_page)
          end

          def pagination_links(total_count)
            return if total_count <= @per_page.to_i

            total_pages  = (total_count.to_f / @per_page).ceil
            current_page = [@page.to_i, 1].max

            helpers.safe_join([
              pagination_link("Previous", current_page - 1, disabled: current_page == 1),
              helpers.tag.span("Page #{current_page} of #{total_pages}", class: "join-item btn btn-disabled"),
              pagination_link("Next", current_page + 1, disabled: current_page == total_pages)
            ])
          end

          def pagination_link(label, page, disabled:)
            if disabled
              helpers.tag.span(label, class: "join-item btn btn-disabled")
            else
              helpers.link_to(
                label,
                url_for(request.query_parameters.merge(page:)),
                class: "join-item btn"
              )
            end
          end
      end
    end
  end
end

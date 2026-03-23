# frozen_string_literal: true

module Baseline
  module AdminPreviewsControllable
    extend ActiveSupport::Concern

    included do
      layout "baseline/admin_preview"

      before_action do
        I18n.locale = :de
        @record = GlobalID.find!(params[:record_gid])
        @i18n_scope = [action_name, @record.class.to_s.underscore.pluralize]
      end
    end

    def header_images
      render "baseline/header_images/preview"
    end
  end
end

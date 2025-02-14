# frozen_string_literal: true

module Baseline
  module I18nScopes
    extend ActiveSupport::Concern

    included do
      private

        helper_method def base_i18n_scope
          controller_path.split("/").map(&:to_sym)
        end

        helper_method def action_i18n_scope(suffix = normalized_action_name.to_sym)
          Array(base_i18n_scope) + [suffix]
        end
    end
  end
end

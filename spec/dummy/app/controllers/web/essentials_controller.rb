# frozen_string_literal: true

module Web
  class EssentialsController < BaseController
    include Baseline::EssentialsControllable

    def render_manifest? = true

    private

      def allow_robots? = true

      _baseline_finalize
  end
end

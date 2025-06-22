# frozen_string_literal: true

module Baseline
  module Spec
    module CapybaraHelpers
      def visit_and_verify_url(url, expected_url = url)
        visit_with_retry url
        expect(page).to have_current_path(expected_url)
      end

      def visit_with_retry(url)
        Octopoller.poll retries: 5, errors: Timeout::Error do
          visit url
        end
      end

      def wait_for_turbo
        20.times do
          return if page.evaluate_script('typeof window["Turbo"] !== "undefined"')
          sleep 0.1
        end

        raise "Turbo not loaded after a few seconds."
      end
    end
  end
end

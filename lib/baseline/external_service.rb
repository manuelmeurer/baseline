# frozen_string_literal: true

module Baseline
  class ExternalService < Service
    class RequestError < Error
      attr_reader :status

      def initialize(message, status:)
        @status = status
        super message
      end
    end

    class << self
      def inherited(subclass)
        subclass.instance_variable_set :"@calls",   []
        subclass.instance_variable_set :"@actions", {}
      end

      attr_reader :calls
      attr_reader :actions

      def add_action(name, return_unless_prod: true, &block)
        @actions[name] =
          if Baseline.configuration.env == :production
            block
          else
            ->(*params) {
              calls << [Time.current, name, params]
              return_unless_prod
            }
          end
      end

      def method_missing(method, ...)
        @actions.key?(method) ?
          new.call(method, ...) :
          super
      end
    end

    def call(method, ...)
      self
        .class
        .actions
        .fetch(method) {
          raise NoMethodError, "undefined method `#{method}' for #{self}"
        }
        .call(...)
    end

    private

      def request(method, path_or_url, base_url: nil,
                                       accept:   "application/json",
                                       params:   nil,
                                       json:     nil,
                                       form:     nil,
                                       body:     nil)

        base_url ||= begin
          self.class::BASE_URL
        rescue NameError
        end

        url =
          base_url&.then { File.join(_1, path_or_url) } ||
          path_or_url

        if request_params.present?
          params = request_params.merge(params || {})
        end

        require "http"
        require "octopoller"

        response    = nil
        tries       = 0
        auth_header = request_auth(*[base_url].take(method(:request_auth).arity))
        headers     = request_headers.merge(accept: accept)

        loop do
          response = Octopoller.poll(retries: 10) do
            HTTP
              .if(auth_header) { _1.auth(_2) }
              .if(request_basic_auth) { _1.basic_auth(_2) }
              .follow
              .headers(headers)
              .public_send(method, url, params:, json:, form:, body:)
          rescue Errno::ECONNRESET
            :re_poll
          end

          break unless
            !response.status.success? &&
            request_retry_reasons.any? { response.status.public_send "#{_1}?" } &&
            tries < 10

          tries += 1
          sleep 1
        end

        response_json = if response.content_type.mime_type == "application/json" &&
                           response.to_s.present?

          JSON.parse(response.to_s, symbolize_names: true)
        end

        unless response.status.success?
          error_message = [
            "Error #{response.status} calling #{method.upcase} #{url}",
            response.to_s
          ].compact_blank
           .join(": ")

          raise RequestError.new(error_message, status: response.status)
        end

        response_json || response.to_s
      end

      def request_auth          = nil
      def request_basic_auth    = nil
      def request_params        = {}
      def request_headers       = {}
      def request_retry_reasons = %i(server_error too_many_requests)

      def wait_for(condition = nil, &block)
        unless condition || block
          raise "wait_for requires a condition or a block."
        end

        result = nil

        10.times do
          break if result = (condition || block).call
          sleep 0.5
        end

        result or (block&.call if condition)
      end

      def with_playwright_chromium(**browser_params)
        require "playwright"

        playwright_params = {
          playwright_cli_executable_path: "npx playwright@#{Playwright::COMPATIBLE_PLAYWRIGHT_VERSION}"
        }

        if browser_params[:proxy].is_a?(String)
          require "addressable"
          browser_params[:proxy] = Addressable::URI
            .parse(browser_params[:proxy])
            .then {
              username, password = _1.user, _1.password
              _1.user = _1.password = nil
              {
                server:   _1.to_s,
                username: username,
                password: password
              }
            }
        end

        Playwright.create(**playwright_params) do |playwright|
          playwright.chromium.launch(**browser_params) do |browser|
            yield browser
          end
        end
      end

      def ignoring_playwright_timeout
        require "playwright"
        yield
      rescue Playwright::TimeoutError
      end
  end
end

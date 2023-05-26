module Baseline
  class ExternalService < Service
    class << self
      def inherited(subclass)
        subclass.cattr_accessor :calls, default: []
      end

      def add_method(name, return_unless_prod: true, &block)
        define_method name,
          if defined?(Rails) && Rails.env.production?
            block
          else
            ->(*params) {
              self.class.calls << [Time.current, name, params]
              return_unless_prod
            }
          end
      end

      def method_missing(method, *args, **kwargs, &block)
        if new.respond_to?(method)
          new.public_send method, *args, **kwargs, &block
        else
          super
        end
      end
    end

    def call(*args, **kwargs)
      public_send *args, **kwargs
    end

    private

      def request(method, path_or_url, base_url: nil,
                                       accept:   Mime[:json],
                                       params:   nil,
                                       json:     nil,
                                       form:     nil,
                                       body:     nil)

        base_url ||= begin
                       self.class::BASE_URL
                     rescue NameError
                     end
        url = base_url&.then { File.join(_1, path_or_url) } ||
              path_or_url

        if request_params.present?
          params = request_params.merge(params || {})
        end

        require "http"

        response    = nil
        tries       = 0
        auth_header = request_auth(*[base_url].take(method(:request_auth).arity))
        headers     = request_headers.merge(accept: accept)

        loop do
          response = HTTP.then { auth_header ? _1.auth(auth_header) : _1 }
                         .then { |request| request_basic_auth&.then { request.basic_auth _1 } || request }
                         .follow
                         .headers(headers)
                         .public_send(method, url, params:, json:, form:, body:)

          break unless (response.status.server_error? || response.status.too_many_requests?) &&
                       tries < 10

          tries += 1
          sleep 1
        end

        response_json = if response.content_type.mime_type == Mime[:json] &&
                           response.to_s.present?

          JSON.parse(response.to_s, symbolize_names: true)
        end

        unless response.status.success?
          error = [
            "Error #{response.status} calling #{method.upcase} #{url}",
            response.to_s
          ].compact_blank
           .join(": ")

          raise Error, error
        end

        response_json || response.to_s
      end

      def request_auth       = nil
      def request_basic_auth = nil
      def request_params     = {}
      def request_headers    = {}

      def wait_for(condition)
        result = nil

        20.times do
          break if result = condition.call
          sleep 0.5
        end

        result or (yield if block_given?)
      end
  end
end

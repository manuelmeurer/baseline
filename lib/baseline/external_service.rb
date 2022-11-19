module Baseline
  class ExternalService < Service
    class << self
      def inherited(subclass)
        subclass.cattr_accessor :calls, default: []
      end

      def add_method(name, return_unless_prod: true, &block)
        define_method name,
          if Rails.env.production?
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

      def request(method, path, base_url: nil,
                                accept:   Mime[:json],
                                params:   nil,
                                json:     nil,
                                form:     nil,
                                body:     nil)

        base_url ||= self.class::BASE_URL
        url        = File.join(base_url, path)

        if request_params.present?
          params = request_params.merge(params || {})
        end

        response    = nil
        tries       = 0
        auth_header = request_auth_header(*[base_url].take(method(:request_auth_header).arity))
        headers     = request_headers.merge(accept: accept)
        loop do
          response = HTTP.then { auth_header ? _1.auth(auth_header) : _1 }
                         .headers(headers)
                         .public_send(method, url, params:, json:, form:, body:)

          break unless response.status.too_many_requests? && tries < 10

          tries += 1
          sleep 1
        end

        response_json = if response.content_type.mime_type == Mime[:json] &&
                           response.to_s.present?

          JSON.parse(response.to_s)
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

      def request_auth_header = nil
      def request_params      = {}
      def request_headers     = {}

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

# frozen_string_literal: true

require "active_storage/service/s3_service"

module ActiveStorage
  class Service::CloudflareR2Service < Service::S3Service
    def initialize(public_host: nil, **options)
      @public_host = public_host
      super(**options)
    end

    private

    def public_url(key, **)
      return super unless @public_host.present?
      "#{@public_host}/#{key}"
    end
  end
end

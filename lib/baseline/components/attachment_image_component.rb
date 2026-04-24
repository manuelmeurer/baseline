# frozen_string_literal: true

require "openssl"
require "base64"

module Baseline
  class AttachmentImageComponent < ApplicationComponent
    SIZES = {
      xxs:   25,
      xs:    50,
      sm:   100,
      md:   250,
      lg:   500,
      xl:   750,
      xxl: 1000
    }.freeze
    CLOUDFLARE_VERSIONS = SIZES.each_with_object({}) do |(key, size), versions|
      base = { format: "auto", quality: 85 }

      variants = {
        "#{key}_fit":           base.merge(width: size, height: size, fit: "scale-down"),
        "#{key}_fit_grayscale": base.merge(width: size, height: size, fit: "scale-down", saturation: 0),
        "#{key}_thumb":         base.merge(width: size, height: size, fit: "cover",      gravity: "face", zoom: 0.6)
      }

      variants.each { versions[_1.to_sym]     = _2 }
      variants.each { versions[:"wide_#{_1}"] = _2.merge(width: size * 2) }
    end.freeze

    def initialize(attached_or_blob, version, only_path: false, **options)
      @attached_or_blob, @version, @only_path, @options =
        attached_or_blob, version, only_path, options
    end

    def call
      is_blob = !@attached_or_blob.respond_to?(:attached?)

      case
      when is_blob
        # We'll assume a dummy image and replace "thumb" with "fit" in the version,
        # so that the CDN does not zoom in on the face.
        @version = @version
          .to_s
          .sub("thumb", "fit")
          .to_sym
      when !@attached_or_blob.attached?
        if Rails.env.production?
          raise "Attached #{@attached_or_blob.inspect} is not attached."
        else
          return
        end
      end

      @blob = @attached_or_blob.unless(is_blob, &:blob)

      case
      when @blob.service_name == "cloudflare"
        render_cloudflare
      when @blob.service.class.to_s.demodulize == "DiskService"
        render_local
      else
        raise "Unexpected service_name: #{@blob.service_name}"
      end
    end

    private

      def render_cloudflare
        options = CLOUDFLARE_VERSIONS.fetch(@version).sort.map { _1.join("=") }.join(",")
        path = "/#{options}/#{@blob.key}"
        signing_key = Rails.application.env_credentials.cloudflare.image_signing_key!
        signature = OpenSSL::HMAC
          .digest("SHA256", signing_key, path)
          .byteslice(0, 16)
          .then { Base64.urlsafe_encode64(_1, padding: false) }
        url = "https://img.#{Rails.application.env_credentials(:production).host!}/#{signature}#{path}"
        @only_path ? url : helpers.image_tag(url, **@options)
      end

      def render_local
        transformation =
          case @version
          when /_fit/   then :resize_to_fit
          when /_thumb/ then :resize_to_fill
          else raise "Unexpected version: #{@version}"
          end
        variant = @blob.variant(
          transformation => CLOUDFLARE_VERSIONS.fetch(@version).fetch_values(:width, :height)
        )
        suffix = @only_path ? :path : :tag
        helpers.public_send \
          :"image_#{suffix}",
          helpers.main_app.polymorphic_url(variant, host: Rails.application.env_credentials.host!),
          **@options
      end
  end
end

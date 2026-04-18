# frozen_string_literal: true

require "openssl"
require "base64"

module Baseline
  class AttachmentImageComponent < ApplicationComponent
    CF_SIG_BYTES = 16
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
        "#{key}_thumb":         base.merge(width: size, height: size, fit: "cover",      gravity: "face")
      }

      variants.each { versions[_1.to_sym]     = _2 }
      variants.each { versions[:"wide_#{_1}"] = _2.merge(width: size * 2) }
    end.freeze
    CLOUDINARY_VERSIONS = SIZES.each_with_object({}) do |(key, size), versions|
      base = {
        quality:      :auto,
        fetch_format: :auto,
        width:        size,
        height:       size
      }

      variants = {
        "#{key}_fit":           base.merge(crop: :fit),
        "#{key}_fit_grayscale": base.merge(crop: :fit, effect: :grayscale),
        "#{key}_thumb":         base.merge(crop: :thumb, gravity: :face)
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

      blob = @attached_or_blob.unless(is_blob, &:blob)

      case blob.service_name
      when "cloudflare"
        render_cf_image(blob)
      when "cloudinary"
        MigrateBlobToCloudflare.call_async(blob.id)
        render_cloudinary(blob)
      else
        if blob.service.class.to_s.demodulize == "DiskService"
          render_local(blob)
        else
          raise "Unexpected service_name: #{blob.service_name.inspect}"
        end
      end
    end

    private

      def render_cf_image(blob)
        options = CLOUDFLARE_VERSIONS.fetch(@version)
        url = cf_url(blob.key, **options)
        @only_path ? url : helpers.image_tag(url, **@options)
      end

      def cf_url(key, **options)
        opts = options.sort.map { _1.join("=") }.join(",")
        path = "/#{opts}/#{key}"
        "https://img.#{Rails.application.env_credentials.host!}/#{cf_sign(path)}#{path}"
      end

      def cf_sign(path)
        signing_key = Rails.application.env_credentials.cloudflare.image_signing_key!

        OpenSSL::HMAC
          .digest("SHA256", signing_key, path)
          .byteslice(0, CF_SIG_BYTES)
          .then { Base64.urlsafe_encode64(_1, padding: false) }
      end

      def render_cloudinary(blob)
        suffix = @only_path ? :path : :tag
        helpers.public_send \
          :"cl_image_#{suffix}",
          blob.key,
          transformation: CLOUDINARY_VERSIONS.fetch(@version),
          **@options
      end

      def render_local(blob)
        transformation =
          case @version
          when /_fit/   then :resize_to_fit
          when /_thumb/ then :resize_to_fill
          else raise "Unexpected version: #{@version}"
          end
        variant = blob.variant(
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

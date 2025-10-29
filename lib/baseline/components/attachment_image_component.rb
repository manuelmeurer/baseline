# frozen_string_literal: true

module Baseline
  class AttachmentImageComponent < ApplicationComponent
    CLOUDINARY_VERSIONS = {
      xs:    50,
      sm:   100,
      md:   250,
      lg:   500,
      xl:   750,
      xxl: 1000
    }.inject({}) do |versions, (key, size)|
      {
        "#{key}_fit": {
          crop: :fit
        },
        "#{key}_fit_blackwhite": {
          crop:   :fit,
          effect: :blackwhite
        },
        "#{key}_fit_blackwhite_10": {
          crop:   :fit,
          effect: "blackwhite:10"
        },
        "#{key}_fit_grayscale": {
          crop:   :fit,
          effect: :grayscale
        },
        "#{key}_fit_rounded": {
          crop:   :fit,
          radius: 20
        },
        "#{key}_thumb": {
          crop:    :thumb,
          gravity: :face
        },
        "#{key}_thumb_rounded": {
          crop:    :thumb,
          gravity: :face,
          radius:  20
        }
      }.transform_values {
        _1.merge \
          quality:      :auto,
          fetch_format: :auto,
          width:        size,
          height:       size
      }.then {
        _1.merge(
          _1.transform_keys   { :"wide_#{it}" }
            .transform_values { it.merge(width: it.fetch(:width) * 2) }
        )
      }.then {
        versions.merge _1
      }
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
        # so that Cloudinary does not zoom in on the face.
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

      suffix = @only_path ? :path : :tag

      cloudinary_options = CLOUDINARY_VERSIONS.fetch(@version)

      # Don't compare `@attached_or_blob.service.class` directly since the
      # ActiveStorage::Service::* subclasses don't exist if they are not used.
      case service_name = @attached_or_blob.service.class.to_s.demodulize
      when "DiskService"
        transformation =
          case @version
          when /_fit/   then :resize_to_fit
          when /_thumb/ then :resize_to_fill
          else raise "Unexpected version: #{@version}"
          end
        variant = @attached_or_blob.variant(
          transformation => cloudinary_options.fetch_values(:width, :height)
        )
        helpers.public_send \
          :"image_#{suffix}",
          polymorphic_url(variant, host: Rails.application.env_credentials.host!),
          **@options
      when "CloudinaryService"
        helpers.public_send \
          :"cl_image_#{suffix}",
          @attached_or_blob.key,
          **cloudinary_options,
          **@options
      else
        raise "Unexpected service: #{service_name}"
      end
    end
  end
end

# frozen_string_literal: true

require "cloudinary"

Rails.application.env_credentials.cloudinary&.then {
  Cloudinary.config \
    cloud_name:           _1.cloud_name!,
    api_key:              _1.api_key!,
    api_secret:           _1.api_secret!,
    enhance_image_tag:    _1.enhance_image_tag,
    static_image_support: _1.static_image_support
}

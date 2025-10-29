# frozen_string_literal: true

require "cloudinary"

if cloudinary_config = Rails.application.env_credentials.cloudinary
  Cloudinary.config \
    cloud_name: cloudinary_config.cloud_name!,
    api_key:    cloudinary_config.api_key!,
    api_secret: cloudinary_config.api_secret!
end

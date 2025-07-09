# frozen_string_literal: true

require "email_validator"

EmailValidator
  .default_options
  .merge! \
    mode:         :strict,
    require_fqdn: true

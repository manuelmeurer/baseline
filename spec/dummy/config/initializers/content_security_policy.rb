# frozen_string_literal: true

# If the asset host does not use HTTPS (e.g. http://localhost.me),
# we need to add it explicitly to the content security policies.
def add_http_asset_host(*options)
  Rails
    .application
    .config
    .asset_host
    .then { options << _1 if _1.start_with?("http://") } ||
      options
end

Rails.application.config.content_security_policy do |policy|
  policy.default_src *add_http_asset_host(:self, :https)
  policy.font_src    *add_http_asset_host(:self, :https, :data)
  policy.img_src     *add_http_asset_host(:self, :https, :data)
  policy.object_src  :none
  policy.script_src  *add_http_asset_host(:self, :https, :unsafe_inline, :unsafe_eval)
  policy.style_src   *add_http_asset_host(:self, :https, :unsafe_inline)

  # https://docs.sentry.io/platforms/javascript/session-replay/#content-security-policy-csp
  policy.worker_src :self, :blob

  if Rails.env.development?
    policy.connect_src \
      :self,
      :https,
      "http://localhost:3035",
      "ws://localhost:3035",
      "ws://localhost:3000"
  else
    # https://docs.sentry.io/product/security-policy-reporting/#content-security-policy
    policy.connect_src :self, :https, "sentry.io"
  end
end

Rails.application.config.content_security_policy_nonce_generator  = proc { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = []
Rails.application.config.content_security_policy_report_only      = true

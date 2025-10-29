# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include Baseline::MailerCore[from_name: "Baseline Dummy"]
end

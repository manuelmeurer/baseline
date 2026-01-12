# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  def self.from_name = "Baseline Dummy"
  include Baseline::MailerCore
end

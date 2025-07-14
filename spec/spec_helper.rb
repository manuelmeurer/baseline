# frozen_string_literal: true

require 'bundler/setup'
require 'rspec'
require 'view_component/test_helpers'
require 'active_support'
require 'action_view'
require 'action_controller'

# Load our baseline library
require_relative '../lib/baseline'

# Setup Rails-like environment for testing
class TestController < ActionController::Base
  def current_url_or_sub_url?(url)
    false
  end
end

# Mock ApplicationComponent base class
module Baseline
  class ApplicationComponent < ViewComponent::Base
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Context

    def current_url_or_sub_url?(url)
      false
    end

    def link_to(text, url, options = {})
      content_tag(:a, text, options.merge(href: url))
    end
  end
end

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component

  config.before(:each, type: :component) do
    @controller = TestController.new
    @request = ActionController::TestRequest.create
    @controller.request = @request
  end
end
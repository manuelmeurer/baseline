# frozen_string_literal: true

require "timeout"
require "baseline/poller"
require "baseline/spec/capybara_helpers"

RSpec.describe Baseline::Spec::CapybaraHelpers do
  def build_helper(status_codes)
    page_class = Struct.new(:status_code)
    expectation_target_class = Class.new do
      def initialize(actual, expectations)
        @actual       = actual
        @expectations = expectations
      end

      def to(matcher)
        @expectations << [@actual, matcher]
      end
    end

    Class.new do
      include Baseline::Spec::CapybaraHelpers

      attr_reader :expectations, :page, :visited_urls

      define_method :initialize do |codes|
        @expectations = []
        @page = page_class.new
        @status_codes = codes
        @visited_urls = []
      end

      define_method :expect do |actual|
        expectation_target_class.new actual, expectations
      end

      def have_current_path(path)
        [:have_current_path, path]
      end

      def have_http_status(status)
        [:have_http_status, status]
      end

      def visit(url)
        visited_urls << url
        page.status_code = @status_codes.shift
      end
    end.new(status_codes)
  end

  it "revisits once when the driver reports status code zero" do
    helper = build_helper([0, 200])

    helper.visit_and_verify_url "/info", "/expected-info"

    expect(helper.visited_urls).to eq ["/info", "/info"]
    expect(helper.expectations).to eq([
      [helper.page, [:have_http_status, :success]],
      [helper.page, [:have_current_path, "/expected-info"]]
    ])
  end

  it "does not revisit when the driver reports a success status code" do
    helper = build_helper([200])

    helper.visit_and_verify_url "/info"

    expect(helper.visited_urls).to eq ["/info"]
    expect(helper.expectations).to eq([
      [helper.page, [:have_http_status, :success]],
      [helper.page, [:have_current_path, "/info"]]
    ])
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::Helper, type: :helper do
  describe "#inline_svg" do
    let(:filename) { "icons/icon.svg" }

    it "raises on non-SVG files" do
      expect {
        helper.inline_svg("foo.png")
      }.to raise_error(/Must be a SVG file/)
    end

    it "returns original content when no attributes given" do
      result = helper.inline_svg(filename)

      expect(result).to include("<svg")
      expect(result).to be_html_safe
    end

    it "merges class with existing classes on svg" do
      result = helper.inline_svg(filename, class: "w-4 h-4")

      svg = Nokogiri::XML(result).at_css("svg")
      expect(svg["class"].split).to contain_exactly("w-4", "h-4")
    end

    it "sets arbitrary attributes on svg" do
      result = helper.inline_svg(filename, id: "my-icon", role: "img")

      svg = Nokogiri::XML(result).at_css("svg")
      expect(svg["id"]).to eq("my-icon")
      expect(svg["role"]).to eq("img")
    end

    it "converts underscores in attribute names to dashes" do
      result = helper.inline_svg(filename, aria_label: "logo")

      svg = Nokogiri::XML(result).at_css("svg")
      expect(svg["aria-label"]).to eq("logo")
    end

    it "flattens nested hashes into dashed attribute names" do
      result = helper.inline_svg(filename, data: { foo_bar: "nope", baz: "yep" })

      svg = Nokogiri::XML(result).at_css("svg")
      expect(svg["data-foo-bar"]).to eq("nope")
      expect(svg["data-baz"]).to eq("yep")
    end

    it "flattens deeply nested hashes" do
      result = helper.inline_svg(filename, data: { controller: { name: "alert" } })

      svg = Nokogiri::XML(result).at_css("svg")
      expect(svg["data-controller-name"]).to eq("alert")
    end
  end
end

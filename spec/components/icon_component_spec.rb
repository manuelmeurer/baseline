# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::IconComponent do
  describe "#call" do
    it "renders an icon with the default version (regular)" do
      result = render_inline(described_class.new(:accept))

      expect(result.css("i.fa-regular").first).to be_present
      expect(result.css("i.fa-circle-check").first).to be_present
    end

    it "renders an icon with a specific version" do
      result = render_inline(described_class.new(:accept, version: :solid))

      expect(result.css("i.fa-solid").first).to be_present
      expect(result.css("i.fa-circle-check").first).to be_present
    end

    it "renders an icon with a custom identifier" do
      result = render_inline(described_class.new("user"))

      expect(result.css("i.fa-user").first).to be_present
    end

    it "renders an icon with size" do
      result = render_inline(described_class.new(:accept, size: "2x"))

      expect(result.css("i.fa-2x").first).to be_present
    end

    it "renders an icon with fixed width" do
      result = render_inline(described_class.new(:accept, fixed_width: true))

      expect(result.css("i.fa-fw").first).to be_present
    end

    it "merges custom CSS classes" do
      result = render_inline(described_class.new(:accept, class: "custom-class"))

      expect(result.css("i.custom-class").first).to be_present
    end

    it "raises an error for invalid version" do
      expect {
        described_class.new(:accept, version: :invalid)
      }.to raise_error(/is not a valid versions/)
    end

    it "raises an error for invalid identifier with scope" do
      expect {
        described_class.new(:nonexistent, scope: nil)
      }.to raise_error(KeyError)
    end
  end
end

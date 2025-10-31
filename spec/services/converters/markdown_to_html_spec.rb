require "rails_helper"

RSpec.describe Baseline::Converters::MarkdownToHTML do
  describe ".call" do
    it "preserves typographic sequences in URLs" do
      texts = [
        "Visit https://example.com/foo--bar... for details",
        "Visit [this website](https://example.com/foo--bar...) for details"
      ]

      texts.each do |text|
        html = described_class.call(text)

        expect(html).to include("https://example.com/foo--bar...")
        expect(html).not_to include("&mdash;")
        expect(html).not_to include("…")
      end
    end
  end
end

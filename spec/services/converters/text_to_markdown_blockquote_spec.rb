require "rails_helper"

RSpec.describe Baseline::Converters::TextToMarkdownBlockquote do
  describe ".call" do
    it "returns empty string for blank input" do
      expect(described_class.call("")).to eq("")
      expect(described_class.call(nil)).to eq("")
    end

    it "prefixes a single line with >" do
      expect(described_class.call("Hello")).to eq("> Hello")
    end

    it "prefixes each line with > for multi-line string" do
      input = "Hello\nWorld"
      expect(described_class.call(input)).to eq("> Hello\n> World")
    end

    it "handles Windows-style line endings" do
      input = "Hello\r\nWorld"
      expect(described_class.call(input)).to eq("> Hello\n> World")
    end

    it "prefixes each line including blank ones from consecutive line breaks" do
      [
        "Hello\n\nWorld",
        "Hello\n\n\nWorld",
        "Hello\n\n\n\nWorld",
        "Hello\n\n World",
        "Hello\n\n\n World",
        "Hello\n\n\n\n World",
        "Hello \n\nWorld",
        "Hello \n\n\nWorld",
        "Hello \n\n\n\nWorld",
        "Hello \n\n World",
        "Hello \n\n\n World",
        "Hello \n\n\n\n World"
      ].each do |input|
        expect(described_class.call(input)).to eq("> Hello\n>\n> World")
      end
    end

    it "accepts an array and prefixes each element" do
      expect(described_class.call(["Hello", "World"])).to eq("> Hello\n> World")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::Converters::HTMLToMarkdown do
  describe ".call" do
    it "returns empty string for blank input" do
      expect(described_class.call("")).to eq("")
      expect(described_class.call(nil)).to eq("")
      expect(described_class.call("   ")).to eq("")
    end

    it "converts a paragraph" do
      expect(described_class.call("<p>Hello world</p>")).to eq("Hello world\n")
    end

    it "converts bold text" do
      expect(described_class.call("<p>Hello <strong>world</strong></p>")).to eq("Hello **world**\n")
    end

    it "converts italic text" do
      expect(described_class.call("<p>Hello <em>world</em></p>")).to eq("Hello _world_\n")
    end

    it "converts links" do
      expect(described_class.call('<p><a href="https://example.com">click</a></p>')).to eq(
        "[click](https://example.com)\n"
      )
    end

    it "converts inline code" do
      expect(described_class.call("<p>Use <code>foo</code> here</p>")).to eq("Use `foo` here\n")
    end

    it "converts code blocks" do
      expect(described_class.call('<pre><code class="language-ruby">puts "hello"</code></pre>')).to eq(
        "```\nputs \"hello\"\n```"
      )
    end

    it "converts headings" do
      expect(described_class.call("<h1>Heading 1</h1>")).to eq("# Heading 1")
      expect(described_class.call("<h2>Heading 2</h2>")).to eq("## Heading 2")
      expect(described_class.call("<h3>Heading 3</h3>")).to eq("### Heading 3")
    end

    it "converts unordered lists" do
      expect(described_class.call("<ul><li>item 1</li><li>item 2</li></ul>")).to eq(
        "- item 1\n- item 2\n"
      )
    end

    it "converts ordered lists" do
      expect(described_class.call("<ol><li>item 1</li><li>item 2</li></ol>")).to eq(
        "1. item 1\n2. item 2\n"
      )
    end

    it "converts blockquotes" do
      expect(described_class.call("<blockquote><p>This is a quote</p></blockquote>")).to eq(
        "> This is a quote\n"
      )
    end

    it "converts images" do
      expect(described_class.call('<img src="https://example.com/img.png" alt="alt text" />')).to eq(
        " ![alt text](https://example.com/img.png)"
      )
    end

    it "converts multiple paragraphs" do
      expect(described_class.call("<p>Paragraph one.</p><p>Paragraph two.</p>")).to eq(
        "Paragraph one.\n\nParagraph two.\n"
      )
    end

    it "removes HTML comments" do
      expect(described_class.call("<p>Hello</p><!-- comment --><p>world</p>")).to eq(
        "Hello\n\nworld\n"
      )
    end

    it "converts tables" do
      expect(described_class.call("<table><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td>1</td><td>2</td></tr></tbody></table>")).to eq(
        "| A | B |\n| --- | --- |\n| 1 | 2 |\n"
      )
    end

    it "converts line breaks" do
      expect(described_class.call("<p>Line one<br />Line two</p>")).to eq(
        "Line one  \nLine two\n"
      )
    end

    it "converts horizontal rules" do
      expect(described_class.call("<hr />")).to eq("* * *")
    end

    it "converts strikethrough" do
      expect(described_class.call("<p><del>deleted</del></p>")).to eq("~~deleted~~\n")
    end

    it "converts nested formatting" do
      expect(described_class.call("<p><strong><em>bold italic</em></strong></p>")).to eq(
        "**_bold italic_**\n"
      )
    end
  end
end

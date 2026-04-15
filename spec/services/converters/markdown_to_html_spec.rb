# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::Converters::MarkdownToHTML do
  describe ".call" do
    it "returns empty string for blank input" do
      expect(described_class.call("")).to eq("")
      expect(described_class.call(nil)).to eq("")
      expect(described_class.call("   ")).to eq("")
    end

    it "converts a paragraph" do
      expect(described_class.call("Hello world")).to eq("<p>Hello world</p>")
    end

    it "converts bold text" do
      expect(described_class.call("Hello **world**")).to eq("<p>Hello <strong>world</strong></p>")
    end

    it "converts italic text" do
      expect(described_class.call("Hello *world*")).to eq("<p>Hello <em>world</em></p>")
    end

    it "converts links" do
      expect(described_class.call("[click here](https://example.com)")).to eq(
        '<p><a href="https://example.com" target="_blank" rel="nofollow noopener">click here</a></p>'
      )
    end

    describe "external link attributes" do
      it "adds target and rel to external links" do
        expect(described_class.call("[ext](https://example.com)")).to eq(
          '<p><a href="https://example.com" target="_blank" rel="nofollow noopener">ext</a></p>'
        )
      end

      it "does not add attributes to internal links" do
        host = Rails.application.env_credentials.host!
        expect(described_class.call("[internal](https://#{host}/path)")).to eq(
          %(<p><a href="https://#{host}/path">internal</a></p>)
        )
      end

      it "does not add attributes to subdomain links of the internal host" do
        host = Rails.application.env_credentials.host!
        expect(described_class.call("[sub](https://www.#{host}/path)")).to eq(
          %(<p><a href="https://www.#{host}/path">sub</a></p>)
        )
      end

      it "does not add attributes to relative links" do
        expect(described_class.call("[rel](/foo/bar)")).to eq(
          '<p><a href="/foo/bar">rel</a></p>'
        )
      end

      it "does not add attributes to heading anchors" do
        expect(described_class.call("# Heading 1")).to eq(
          '<h1><a href="#heading-1" aria-hidden="true" class="anchor" id="heading-1"></a>Heading 1</h1>'
        )
      end
    end

    it "converts inline code" do
      expect(described_class.call("Use `foo` here")).to eq("<p>Use <code>foo</code> here</p>")
    end

    it "converts code blocks" do
      expect(described_class.call("```ruby\nputs \"hello\"\n```")).to eq(
        "<pre><code class=\"language-ruby\">puts &quot;hello&quot;\n</code></pre>"
      )
    end

    it "converts headings" do
      expect(described_class.call("# Heading 1")).to eq(
        '<h1><a href="#heading-1" aria-hidden="true" class="anchor" id="heading-1"></a>Heading 1</h1>'
      )
      expect(described_class.call("## Heading 2")).to eq(
        '<h2><a href="#heading-2" aria-hidden="true" class="anchor" id="heading-2"></a>Heading 2</h2>'
      )
      expect(described_class.call("### Heading 3")).to eq(
        '<h3><a href="#heading-3" aria-hidden="true" class="anchor" id="heading-3"></a>Heading 3</h3>'
      )
    end

    it "converts unordered lists" do
      expect(described_class.call("- item 1\n- item 2\n- item 3")).to eq(
        "<ul>\n<li>item 1</li>\n<li>item 2</li>\n<li>item 3</li>\n</ul>"
      )
    end

    it "converts ordered lists" do
      expect(described_class.call("1. item 1\n2. item 2\n3. item 3")).to eq(
        "<ol>\n<li>item 1</li>\n<li>item 2</li>\n<li>item 3</li>\n</ol>"
      )
    end

    it "converts blockquotes" do
      expect(described_class.call("> This is a quote")).to eq(
        "<blockquote>\n<p>This is a quote</p>\n</blockquote>"
      )
    end

    it "converts images" do
      expect(described_class.call("![alt text](https://example.com/img.png)")).to eq(
        '<p><img src="https://example.com/img.png" alt="alt text" /></p>'
      )
    end

    it "converts strikethrough (GFM)" do
      expect(described_class.call("~~deleted~~")).to eq("<p><del>deleted</del></p>")
    end

    it "converts multiple paragraphs" do
      expect(described_class.call("Paragraph one.\n\nParagraph two.")).to eq(
        "<p>Paragraph one.</p>\n<p>Paragraph two.</p>"
      )
    end

    it "preserves inline HTML" do
      expect(described_class.call("Hello <strong>world</strong>")).to eq(
        "<p>Hello <strong>world</strong></p>"
      )
    end

    it "converts tables (GFM)" do
      expect(described_class.call("| A | B |\n|---|---|\n| 1 | 2 |")).to eq(
        "<table>\n<thead>\n<tr>\n<th>A</th>\n<th>B</th>\n</tr>\n</thead>\n<tbody>\n<tr>\n<td>1</td>\n<td>2</td>\n</tr>\n</tbody>\n</table>"
      )
    end

    it "converts hard line breaks" do
      expect(described_class.call("Line one  \nLine two")).to eq(
        "<p>Line one<br />Line two</p>"
      )
    end

    it "converts soft line breaks to <br />" do
      expect(described_class.call("Line one\nLine two")).to eq(
        "<p>Line one<br />Line two</p>"
      )
    end

    it "removes trailing line breaks" do
      expect(described_class.call("Hello  \n")).to eq("<p>Hello</p>")
    end

    it "does not apply typographic replacements in URLs" do
      texts = [
        "Visit [this website](https://example.com/foo--bar...) for details"
      ]

      texts.each do |text|
        html = described_class.call(text)

        expect(html).to include("https://example.com/foo--bar...")
        expect(html).not_to include("&mdash;")
        expect(html).not_to include("…")
      end
    end

    describe "sanitize option" do
      it "strips HTML tags when sanitize is true" do
        expect(described_class.call("Hello **world**", sanitize: true)).to eq("Hello world")
      end

      it "keeps HTML tags when sanitize is false" do
        expect(described_class.call("Hello **world**", sanitize: false)).to eq(
          "<p>Hello <strong>world</strong></p>"
        )
      end
    end

    describe "avoid_paragraphs option" do
      it "replaces <p> tags with <br /> when avoid_paragraphs is true" do
        expect(described_class.call("Paragraph one.\n\nParagraph two.", avoid_paragraphs: true)).to eq(
          "Paragraph one.<br /><br />Paragraph two."
        )
      end

      it "keeps <p> tags when avoid_paragraphs is false" do
        expect(described_class.call("Hello world", avoid_paragraphs: false)).to eq(
          "<p>Hello world</p>"
        )
      end
    end

    describe "add_class_to_first_paragraph option" do
      it "adds class to first <p> tag" do
        expect(described_class.call("Hello world", add_class_to_first_paragraph: "lead")).to eq(
          '<p class="lead">Hello world</p>'
        )
      end

      it "only adds class to the first paragraph" do
        expect(described_class.call("Paragraph one.\n\nParagraph two.", add_class_to_first_paragraph: "lead")).to eq(
          "<p class=\"lead\">Paragraph one.</p>\n<p>Paragraph two.</p>"
        )
      end
    end
  end
end

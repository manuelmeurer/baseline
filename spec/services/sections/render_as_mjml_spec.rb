require "rails_helper"

RSpec.describe Baseline::Sections::RenderAsMJML do
  def render(html, headline: nil)
    section = instance_double("Section",
      headline:,
      content_html: Nokogiri::HTML.fragment(html),
      persisted?:   false
    )

    described_class.call(section)
  end

  describe "code elements" do
    it "renders inline code within text" do
      result = render("Use <code>bundle exec</code> to run it")
      expect(result).to eq "<mj-text>Use <code>bundle exec</code> to run it</mj-text>"
    end

    it "renders a code block inside pre" do
      result = render("<pre><code>puts 'hello'</code></pre>")
      expect(result).to eq "<mj-text><code>puts 'hello'</code></mj-text>"
    end
  end
end

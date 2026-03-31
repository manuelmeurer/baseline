# frozen_string_literal: true

module Baseline
  module ActsAsLocalRecord
    extend ActiveSupport::Concern

    PUBLISHED_PATH_REGEX = %r{
      /
      (?<year>\d{4})
      /
      (?<month>\d{2})
      -
      (?<day>\d{2})
      -
      (?<slug>.+)
      \.md
      \z
    }x.freeze
    DRAFT_PATH_REGEX = %r{
      /
      drafts
      /
      (?<slug>.+)
      \.md
      \z
    }x.freeze
    META_REGEX = %r{
      \A
      ---
      \n
      (?<yaml>.+?)
      \n
      ---
      \n*
    }mix.freeze
    FRONTMATTER_KEYS = %w[
      title
      summary
      image
      tags
      reference_gid
      author_gid
    ].freeze

    included do
      include HasTimestamps[:published_on]

      belongs_to :reference, polymorphic: true, optional: true
      belongs_to :author, polymorphic: true, optional: true

      validates :type, presence: true
      validates :slug, presence: true
      validates :title, presence: true
      validates :content, presence: true
      validates :published_on, uniqueness: { scope: %i[type slug], allow_nil: true }
    end

    class_methods do
      def path = Rails.root.join("lib", to_s.underscore.pluralize)

      def drafts
        if descendants.any?
          return descendants.flat_map(&__method__)
        end

        path
          .join("drafts", "*.md")
          .then { Dir[_1] }
          .map {
            new file: _1
          }
      end
    end

    def file=(value)
      unless match = value.match(PUBLISHED_PATH_REGEX) || value.match(DRAFT_PATH_REGEX)
        raise ArgumentError, "Invalid file name: #{value}"
      end

      self.source = File.read(value)
      self.slug   = match[:slug]
    end

    def source=(value)
      value
        .slice(META_REGEX, :yaml)
        .then {
          YAML.safe_load _1
        }.then {
          assign_attributes _1
        }

      self.author ||= default_author if respond_to?(:default_author, true)
      self.content = value.sub(META_REGEX, "")
    end

    def source
      [
        frontmatter,
        content
      ].compact_blank.join("\n\n")
    end

    def frontmatter
      FRONTMATTER_KEYS
        .index_with {
          public_send _1
        }.compact_blank
        .presence
        &.to_yaml(line_width: -1)
        &.gsub(/\\U([0-9A-Fa-f]{8})/) { [$1.hex].pack('U') }
        &.concat("---")
    end

    def path
      self
        .class
        .path
        .join(published_on&.year&.to_s || "drafts")
        .to_s
    end

    def file
      [
        published_on&.strftime("%m-%d"),
        "#{slug}.md"
      ].compact
        .join("-")
        .then {
          File.join(path, _1)
        }
    end

    def to_param
      [
        published_on&.iso8601,
        slug
      ].compact.join("-")
    end

    def sections
      digest = ActiveSupport::Digest.hexdigest(content.to_s)
      return @sections if defined?(@sections_digest) && @sections_digest == digest
      @sections_digest = digest

      @sections = Baseline::Sections::InitializeFromMarkdown.call(content)
    end

    def read_minutes
      return unless content

      content
        .scan(/\w+/)
        .size
        .to_f
        ./(200)
        .round
        .then { [_1, 1].max }
    end

    def headlines
      sections
        .map(&:headline)
        .compact_blank
    end

    def image_url
      return unless image.present?

      case
      when image.match?(URLFormatValidator.regex)
        image
      when File.join(path, image).then { File.exist? _1 }
        Rails
          .application
          .routes
          .url_helpers
          .web_blog_post_draft_path(image)
      else
        Cloudinary::Utils.cloudinary_url(
          image,
          width:        800,
          crop:         :limit,
          quality:      :auto,
          fetch_format: :auto,
          analytics:    false
        )
      end
    end

    def save_to_file
      FileUtils.mkdir_p File.dirname(file)
      File.write(file, "#{source}\n")
    end
  end
end

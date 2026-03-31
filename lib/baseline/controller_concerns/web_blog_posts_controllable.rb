# frozen_string_literal: true

module Baseline
  module WebBlogPostsControllable
    extend ActiveSupport::Concern

    included do
      include Baseline::LocalRecordsControllable

      around_action do |_, block|
        I18n.with_locale :de, &block
      end

      before_action only: :show do
        @blog_post = find_local_record(scope)
      end

      before_action only: :feed do
        unless params[:format] == "xml"
          redirect_to url_for(format: :xml)
        end
      end
    end

    def index
      @blog_posts = scope

      if params[:draft]
        set_noindex_header
        expires_now
      else
        return if non_dev_fresh_when(@blog_posts)
        expires_soon
      end
    end

    def show
      @schema_data = {
        "@context":       "https://schema.org/",
        "@type":          "BlogPosting",
        headline:         @blog_post.title,
        description:      @blog_post.summary,
        image:            @blog_post.image_url,
        datePublished:    @blog_post.published_on&.iso8601,
        dateModified:     @blog_post.published_on&.iso8601,
        publisher:        helpers.organization_schema_data(include_context: false),
        mainEntityOfPage: url_for(only_path: false),
        author: {
          "@type": "Person",
          name:    @blog_post.author.name
        }
      }.compact

      set_og_data \
        type:        "article",
        image:       @blog_post.image_url,
        url:         url_for([:web, @blog_post]),
        description: @blog_post.summary,
        article: {
          published_time: @blog_post.published_on&.iso8601,
          modified_time:  @blog_post.published_on&.iso8601,
          tag:            @blog_post.tags,
          author: {
            first_name: @blog_post.author.first_name,
            last_name:  @blog_post.author.last_name,
            username:   @blog_post.author.slug,
            gender:     @blog_post.author.gender
          }
        }

      if params[:draft]
        set_noindex_header
        expires_now
      else
        return if non_dev_fresh_when(@blog_post)
        expires_soon
      end

      render layout: "web_aside"
    end

    def feed
      @blog_posts = scope
    end

    private

      def scope
        params[:draft] ?
          BlogPost.drafts :
          published_blog_posts
      end

      def page_title
        action_name == "show" ?
          @blog_post.title :
          super
      end
  end
end

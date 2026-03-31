# frozen_string_literal: true

module Baseline
  module ActsAsBlogPost
    def url
      Rails.application.routes.url_helpers.url_for(
        published? ?
          [:web, self] :
          [:web, :blog_post_draft, id: slug]
      )
    end
  end
end

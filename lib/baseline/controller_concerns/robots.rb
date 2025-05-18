# frozen_string_literal: true

module Baseline
  module Robots
    extend ActiveSupport::Concern

    # This is a bit hacky... we need to allow unauthenticated access to the "robots" action,
    # but we can't just say `allow_unauthenticated_access, only: :robots` since the Authentication
    # concern might not be included yet. This is why we do it in a before_action, which is invoked
    # on every request, but make sure to only call `allow_unauthenticated_access` once, and if the
    # first request is for robots, redirect so that the authentication is actually skipped on the
    # second request.
    included do
      mattr_accessor :robots_unauthenticated_access_set

      before_action prepend: true do
        next if self.class.robots_unauthenticated_access_set

        # We need to find the class that has includes the Authentication concern,
        # it might be a superclass of the current class.
        self
          .class
          .ancestors
          .select { _1.respond_to? :allow_unauthenticated_access }
          .last
          .try(:allow_unauthenticated_access, only: :robots)

        self.class.robots_unauthenticated_access_set = true

        if action_name == "robots"
          redirect_to params.permit!
        end
      end
    end

    def robots
      response = {
        allow: <<~ROBOTS,
            User-agent: *
            Allow: /
          ROBOTS
        disallow: <<~ROBOTS
            User-agent: *
            Disallow: /
          ROBOTS
      }.fetch(params[:id].to_sym)

      render plain: response
    end
  end
end

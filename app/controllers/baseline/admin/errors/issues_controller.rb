# frozen_string_literal: true

module Baseline
  module Admin
    module Errors
      class IssuesController < ApplicationController
        before_action :set_issue, only: %i[show resolve unresolve]

        def index
          scope = params[:status] == "resolved" ? Baseline::Errors::Issue.resolved : Baseline::Errors::Issue.unresolved

          @issues = scope.recent_first.limit(100)
        end

        def show; end

        def resolve
          @issue.resolve!

          redirect_back fallback_location: issue_path(@issue)
        end

        def unresolve
          @issue.unresolve!

          redirect_back fallback_location: issue_path(@issue)
        end

        _baseline_finalize

        private

          def set_issue
            @issue = Baseline::Errors::Issue.find(params[:id])
          end
      end
    end
  end
end

# frozen_string_literal: true

module Baseline
  module External
    class Todoist < ::External::Base
      BASE_URL  = "https://api.todoist.com/api/v1".freeze
      PAGE_SIZE = 200

      mattr_accessor :project_name

      def call(access_token, ...)
        @access_token = access_token
        super(...)
      end

      # Projects

      add_action :get_project_id do
        if project_name.blank?
          raise Error, "Project name is missing."
        end

        cache_key = [
          :todoist_project_id,
          @access_token,
          project_name
        ].join(":")

        Rails.cache.fetch cache_key do
          call(@access_token, :get_projects)
            .select {
              _1.fetch(:name) == project_name
            }.unless(-> { _1.one? }) {
              raise Error, "Found #{_1.size} Todoist projects with name #{project_name}."
            }.first
            .fetch(:id)
        end
      end

      add_action :get_projects do
        paginate_get "projects"
      end

      # Tasks

      add_action :get_tasks do |due_today: false|
        project_id = call(@access_token, :get_project_id)
        paginate_get(
          "tasks",
          params: { project_id: }
        ).if(due_today) do |tasks|
          tasks.select { _1[:due]&.fetch(:date)&.<=(Date.current.iso8601) }
        end
      end

      add_action :create_task do |done, attributes|
        request(
          :post,
          "tasks",
          json: attributes.merge(project_id: call(@access_token, :get_project_id))
        ).tap do |response|
          close_or_reopen_task response, done
        end
      end

      add_action :update_task do |id, done, attributes|
        request(
          :post,
          "tasks/#{id}",
          json: attributes
        ).tap do |response|
          close_or_reopen_task response, done
        end
      end

      add_action :close_task do |id|
        request :post, "tasks/#{id}/close"
      end

      add_action :reopen_task do |id|
        request :post, "tasks/#{id}/reopen"
      end

      add_action :delete_task do |id|
        request :delete, "tasks/#{id}"
      end

      private

        def request_auth
          unless @access_token
            raise Error, "Access token is missing."
          end

          "Bearer #{@access_token}"
        end

        def prepare_paginate_params(params)
          params.reverse_merge(
            limit: PAGE_SIZE
          )
        end

        def next_url_and_params(response, url, params)
          if cursor = response[:next_cursor]
            params[:cursor] = cursor
            [url, params]
          end
        end

        def close_or_reopen_task(response, done)
          id, completed = response.fetch_values(:id, :is_completed)
          case
          when completed && !done then :reopen_task
          when !completed && done then :close_task
          end&.then {
            self.class.call_async @access_token, _1, id
          }
        end
    end
  end
end

# frozen_string_literal: true

module Baseline
  class DownloadFile < ApplicationService
    def call(url, filename = nil)
      require "http"
      require "addressable"

      filename ||= Addressable::URI
        .parse(url)
        .then {
          File.basename(_1.path)
        }

      pathname = Rails.root.join(
        "tmp",
        "downloaded_files",
        ActiveSupport::Digest.hexdigest(url),
        filename
      )

      unless pathname.exist?
        FileUtils.mkdir_p(pathname.dirname)
        HTTP
          .follow
          .get(url)
          .unless(-> { _1.status.success? }) { raise Error, "Could not fetch #{url}" }
          .then {
            File.binwrite pathname, _1.to_s
          }
      end

      if block_given?
        begin
          yield pathname
        ensure
          FileUtils.rm_f pathname
        end
      end

      pathname
    end
  end
end

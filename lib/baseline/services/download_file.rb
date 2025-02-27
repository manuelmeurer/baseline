# frozen_string_literal: true

require "http"
require "addressable"

module Baseline
  class DownloadFile < ApplicationService
    def call(url, filename = nil)
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

        data = HTTP
          .follow
          .get(url)
          .tap { raise Error, "Could not fetch #{url}" unless _1.status.success? }
          .to_s

        File.open(pathname, "wb") {
          _1.write data
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

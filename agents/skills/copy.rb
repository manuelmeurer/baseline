#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "thor"
end

class Copy < Thor
  include Thor::Actions

  default_command :copy

  def self.exit_on_failure? = true

  desc "copy", "Copy agent skills into Claude/Codex skill directories"
  option :dry_run, type: :boolean, default: false, desc: "Show actions without changing the filesystem"
  option :force, type: :boolean, default: false, desc: "Overwrite existing files or symlinks"
  def copy
    require "fileutils"

    targets = %w[.claude .codex].map {
      File.join(ENV.fetch("HOME"), _1, "skills")
    }

    dirs = Dir
      .children(__dir__)
      .sort
      .select { File.directory?(File.join(__dir__, _1)) }

    dirs.each do |dir|
      dir_path = File.join(__dir__, dir)

      targets.each do |target|
        target_path = File.join(target, dir)

        if File.exist?(target_path) || File.symlink?(target_path)
          if options[:dry_run]
            action = options[:force] ? "force remove" : "skip"
            say "Would #{action} #{target_path} (already exists)", :blue
            next
          end

          unless options[:force]
            say "Skipping #{target_path} (already exists)", :yellow
            next
          end

          FileUtils.rm_rf(target_path)
          say "Removed #{target_path}", :yellow
        end

        if options[:dry_run]
          say "Would copy #{dir_path} -> #{target_path}", :green
        else
          FileUtils.cp_r(dir_path, target_path)
          say "Copied #{dir_path} -> #{target_path}", :green
        end
      end
    end
  end
end

Copy.start(ARGV)

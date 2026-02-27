#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "thor"
end

class Link < Thor
  include Thor::Actions

  default_command :link

  def self.exit_on_failure? = true

  TARGETS = %w[.claude .agents].map {
    File.join(ENV["HOME"], _1, "skills")
  }

  desc "link", "Symlink each skill folder to ~/.claude/skills and ~/.agents/skills"
  option :dry_run, type: :boolean, default: false, desc: "Show actions without changing the filesystem"
  option :force, type: :boolean, default: false, desc: "Overwrite existing files or symlinks"
  def link
    require "fileutils"

    skills_dir = __dir__
    skill_folders = Dir
      .children(skills_dir)
      .select { File.directory?(File.join(skills_dir, _1)) }
      .sort

    TARGETS.each do |target_dir|
      ensure_directory(target_dir)

      skill_folders.each do |folder|
        source = File.join(skills_dir, folder)
        target = File.join(target_dir, folder)
        create_symlink(source, target)
      end

      check_broken_symlinks(target_dir, skills_dir)
    end
  end

  private

    def ensure_directory(dir)
      if Dir.exist?(dir)
        if options[:dry_run]
          say "Would skip #{dir} (already exists)", :yellow
        end
      elsif options[:dry_run]
        say "Would create directory #{dir}", :blue
      else
        FileUtils.mkdir_p(dir)
        say "Created directory #{dir}", :green
      end
    end

    def create_symlink(source, target)
      if File.exist?(target) || File.symlink?(target)
        if options[:dry_run]
          action = options[:force] ? "force remove" : "skip"
          say "Would #{action} #{target} (already exists)", :blue
          return
        end

        unless options[:force]
          say "Skipping #{target} (already exists)", :yellow
          return
        end

        FileUtils.rm_f(target)
        say "Removed #{target}", :yellow
      end

      if options[:dry_run]
        say "Would link #{source} -> #{target}", :green
      else
        File.symlink(source, target)
        say "Linked #{source} -> #{target}", :green
      end
    end

    def check_broken_symlinks(target_dir, skills_dir)
      return unless Dir.exist?(target_dir)

      Dir
        .children(target_dir)
        .each do |name|

        path = File.join(target_dir, name)

        next unless File.symlink?(path)
        next if File.exist?(path)

        link_target = File.readlink(path)
        next unless link_target.start_with?(skills_dir)

        say "Broken symlink: #{path} -> #{link_target}", :red
      end
    end
end

Link.start(ARGV)

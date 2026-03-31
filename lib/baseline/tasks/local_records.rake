# frozen_string_literal: true

namespace :local_records do
  task publish: :environment do
    IMAGE_REGEX = /
      (
        \!
        \[
          [^\]]*
        \]
        \(
          <?
          ([^\)]+?)
          >?
        \)
      )
    /ix

    # Make sure all descendants of LocalRecord are loaded.
    Rails.application.eager_load!

    drafts = LocalRecord.drafts.index_with do |draft|
      %(#{draft.class.model_name.human}: "#{draft.title}")
    end

    case
    when drafts.none?
      puts "No drafts found."
      exit 1
    when drafts.many?
      puts "#{drafts.count} drafts found."
      puts "Select draft to publish:"
      puts
      drafts.values.each_with_index do |label, index|
        puts %([#{index + 1}] #{label})
      end
      puts
      puts "Enter number of draft to publish or press Ctrl+C to cancel."

      index = STDIN.gets.chomp

      unless index.match?(/\A\d+\z/) && (1..drafts.count).cover?(index.to_i)
        puts "Unexpected input, aborting."
        exit 1
      end

      @draft = drafts.keys[index.to_i - 1]
    else
      @draft = drafts.keys.first
    end

    puts
    puts %(Shall I go ahead and publish #{drafts[@draft]}?)
    puts "Press Ctrl+C to cancel or Enter to continue."

    STDIN.gets

    upload_images

    draft_file = @draft.file

    @draft.published_on = Date.current
    puts "Saving source to: #{@draft.file}"
    @draft.save_to_file

    puts "Deleting draft file: #{draft_file}"
    FileUtils.rm draft_file

    puts "Creating blog post in database."
    new_blog_posts = Baseline::LocalRecords::UpsertAll.call

    puts
    puts "Draft published successfully!"
    puts "Check it out:"
    puts
    puts Rails.application.routes.url_helpers.url_for([:web, new_blog_posts.last])
  end
end

def upload_images
  Rails
    .application
    .env_credentials(:production)
    .cloudinary!
    .then {
      Cloudinary.config \
        cloud_name: _1.cloud_name!,
        api_key:    _1.api_key!,
        api_secret: _1.api_secret!
    }

  if @draft.image&.then { !_1.match?(URLFormatValidator.regex) }
    file = File.join(@draft.path, @draft.image)

    case
    when File.exist?(file)
      puts "Found local header image #{@draft.image}, uploading to Cloudinary."
      filename = upload_image(file)
      @draft.image = filename
      puts "Deleting file: #{file}"
      FileUtils.rm file
    when !@draft.image.split(".").first.then { Cloudinary::Api.resource _1 }
      puts "Header image file not found locally or on Cloudinary: #{file}"
      exit 1
    end
  end

  @draft
    .content
    .scan(IMAGE_REGEX)
    .each do |tag, image|
      next if image.match?(URLFormatValidator.regex)

      puts "Found image #{image}, uploading to Cloudinary."
      file = File.join(@draft.path, image)
      unless File.exist?(file)
        puts "Image file not found: #{file}"
        exit 1
      end
      url = upload_image(file, return_url: true)
      @draft.content = tag
        .sub(/<?#{image}>?\)\z/, "#{url})")
        .then {
          @draft.content.gsub tag, _1
        }

      puts "Deleting file: #{file}"
      FileUtils.rm file
    end
end

def upload_image(file, return_url: false)
  Baseline::LocalRecords::UploadImage
    .call(@draft, file)
    .if(return_url) {
      Cloudinary::Utils.cloudinary_url \
        _1,
        width:        1024,
        crop:         :limit,
        quality:      :auto,
        fetch_format: :auto,
        analytics:    false
    }
end

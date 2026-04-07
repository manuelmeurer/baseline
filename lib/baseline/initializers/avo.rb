# frozen_string_literal: true

require "avo"

::Avo.configure do |config|
  config.app_name                      = "Admin Dashboard"
  config.click_row_to_view_record      = true
  config.currency                      = "EUR"
  config.license_key                   = Rails.application.env_credentials.avo.license_key!
  config.root_path                     = "cms"
  config.authorization_client          = Baseline::Avo::PunditClientWithFallback
  config.explicit_authorization        = true
  config.raise_error_on_missing_policy = false
  config.current_user_method do
    ::Current.admin_user
  end
  config.branding = {
    logo:     "brand/avo_logo.png",
    logomark: "brand/avo_logomark.png",
    favicon:  "icons/favicon.ico"
  }
end

require "url_manager"

::Avo::Engine.routes.default_url_options = ::URLManager.url_options(:admin)

class ::Avo::BaseAction
  include Baseline::Avo::ActionHelpers

  module ErrorHandler
    def handle(...)
      super
    rescue => error
      if error.class <= self.class::Error
        raise error
      else
        raise self.class::Error, error
      end
    end
  end

  def self.inherited(subclass)
    subclass.const_set :Error, Class.new(StandardError)
    subclass.prepend ErrorHandler
  end
end

if defined?(Lexxy)
  ::Avo.asset_manager.add_stylesheet "lexxy"
end

# Prevent has_one fields from trying to load unpersisted records (e.g. auto-built
# by `super || build_*`), which would generate a URL without a related_id and hit
# the has_many index route, causing a NoMethodError on `scope`.
class ::Avo::Fields::HasOneField
  module PersistedValue
    def value(...)
      result = super
      result&.persisted? ? result : nil
    end
  end
  prepend PersistedValue
end

# Wrap some patches in after_initialize so the classes are autoloaded before we
# reopen them — at initializer time the constants don't exist yet and `class`
# would create a hollow Object subclass instead of reopening the real class.
Rails.application.config.after_initialize do
  # Add a "Show" button next to the "Edit" button on has_one/belongs_to
  # association panels in show views, linking to the associated resource's
  # own show page.
  ::Avo::Views::ResourceShowComponent.prepend(Module.new do
    def controls
      result = super
      return result unless @reflection.present?

      if edit_index = result.index { _1.is_a?(::Avo::Resources::Controls::EditButton) }
        result.insert(edit_index, ::Avo::Resources::Controls::ShowButton.new)
      end
      result
    end
  end)

  ::Avo::ResourceComponent.class_eval do
    private def render_show_button(control)
      return unless @resource.record.present?

      a_link helpers.resource_path(record: @resource.record, resource: @resource),
        style: :text,
        color: :primary,
        title: control.title,
        data: {
          turbo_frame: "_top",
          tippy: control.title ? :tooltip : nil
        },
        icon: "avo/eye" do
        control.label || I18n.t("avo.view").capitalize
      end
    end
  end

  # Extend global search (Cmd+K) to include matching sidebar navigation items
  # above the regular search results.
  ::Avo::SearchController.prepend(Module.new do
    def index
      super

      q = params[:q].to_s.strip
      return if q.blank?

      root = ::Avo.configuration.root_path
      navigation_results = ::Avo
        .resource_manager
        .resources_for_navigation
        .select { _1.navigation_label.downcase.include?(q.downcase) }
        .sort_by(&:navigation_label)
        .map do |resource|
          {
            _id:    resource.route_key,
            _label: resource.navigation_label,
            _url:   "/#{root}/resources/#{resource.route_key}"
          }
        end

      if navigation_results.present?
        body = JSON
          .parse(response.body)
          .reverse_merge(
            _navigation: {
              header: "Pages (#{navigation_results.size})",
              help: "",
              results: navigation_results,
              count: navigation_results.size
            }
          )
        response.body = body.to_json
      end
    end
  end)

  # When Rails stores a polymorphic _type for an STI model, it uses the base
  # class name (e.g. "OutgoingInvoice" instead of "FreelancerInvoice"). Avo's
  # BelongsToField edit component doesn't handle this, so we normalize the
  # polymorphic type/id to match one of the field's declared types.
  ::Avo::Fields::BelongsToField::EditComponent.prepend(Module.new do
    def initialize(...)
      super
      normalize_sti_polymorphic_association!
    end

    def polymorphic_class
      normalized_polymorphic_class || super
    end

    def polymorphic_id
      @resource.record["#{@field.foreign_key}_id"] || super
    end

    def polymorphic_record
      record = @field.value
      if record.present? &&
         polymorphic_class.present? &&
         record.is_a?(polymorphic_class.safe_constantize)
        return record
      end

      super
    end

    private

      def normalize_sti_polymorphic_association!
        return unless is_polymorphic?

        normalized_class = normalized_polymorphic_class
        return unless normalized_class.present?

        record = @resource.record
        type_attribute = "#{@field.foreign_key}_type"
        id_attribute = "#{@field.foreign_key}_id"

        record[type_attribute] = normalized_class
        record[id_attribute] ||= @field.value&.id
      end

      def normalized_polymorphic_class
        return @normalized_polymorphic_class if defined?(@normalized_polymorphic_class)

        stored_class_name = @resource.record["#{@field.foreign_key}_type"]
        @normalized_polymorphic_class =
          if stored_class_name.blank?
            nil
          elsif @field.types.map(&:to_s).include?(stored_class_name)
            stored_class_name
          else
            normalize_sti_polymorphic_class(stored_class_name)
          end
      end

      def normalize_sti_polymorphic_class(stored_class_name)
        stored_class = stored_class_name.safe_constantize
        return stored_class_name unless stored_class

        candidate_types = @field.types.select do |type|
          candidate_class = type.to_s.safe_constantize
          candidate_class && candidate_class < stored_class
        end
        return stored_class_name if candidate_types.empty?

        matching_types = candidate_types.select do |type|
          @field.value.is_a?(type)
        end
        return matching_types.first.to_s if matching_types.one?
        return stored_class_name unless matching_types.empty?

        candidate_types.one? ? candidate_types.first.to_s : stored_class_name
      end
  end)
end

# When Rails stores a polymorphic _type for an STI model, it uses the base class
# name (e.g. "OutgoingInvoice" instead of "FreelancerInvoice"). If no Avo resource
# exists for the base class, fall back to a resource for one of its STI descendants.
class ::Avo::Resources::ResourceManager
  module STIFallback
    def get_resource_by_model_class(klass)
      result = super
      return result if result

      model_class = klass.to_s.safe_constantize
      return unless model_class.try(:descendants)&.any?

      model_class.descendants.each do |descendant|
        resource = super(descendant.name)
        return resource if resource
      end

      nil
    end
  end
  prepend STIFallback
end

class ::Avo::Fields::BooleanField
  def as_toggle? = @args.key?(:as_toggle) ? !!@args[:as_toggle] : true
end

# Default to the Rails app timezone (config.time_zone) instead of the browser's
# timezone for all datetime and time fields.
class ::Avo::Fields::DateTimeField
  module AppTimezone
    def timezone
      super ||
        Rails.application.config.time_zone.presence or
          raise "Rails app timezone not set."
    end
  end
  prepend AppTimezone
end

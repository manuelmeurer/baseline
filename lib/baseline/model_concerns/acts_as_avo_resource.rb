# frozen_string_literal: true

module Baseline
  module ActsAsAvoResource
    extend ActiveSupport::Concern

    class_methods do
      def _baseline_finalize
        if defined?(@_baseline_finalized)
          raise "Avo resource #{name} has already been finalized."
        end

        self.title = :to_s

        self.row_controls_config = {
          float: true
        }

        if model_class.respond_to?(:search)
          self.search = {
            query: -> {
              query.search(params[:q])
            }
          }
        end

        @_baseline_finalized = true
      end
    end

    def truncate_on_index
      -> {
        value.if(view == "index") {
          tag.span \
            truncate(_1, length: 50),
            title: _1
        }
      }
    end

    def polymorphic_types_with_resource(attribute)
      model_class
        .polymorphic_types(attribute)
        .select { ::Avo::Resources.const_defined?(_1, false) }
        .map(&:constantize)
    end

    def filters
      if model_class.respond_to?(:search)
        filter Baseline::Avo::Filters::Search
      end
    end

    def email_field(attribute = :email, **options)
      field attribute,
        **options.reverse_merge(
          as: :text
        ) do
          mail_to record.send(attribute)
        end
    end

    def url_field(attribute = :url, **options)
      field attribute,
        **options.reverse_merge(
          as: :text,
          format_display_using: -> {
            if value.present?
              link_to \
                helpers.pretty_url(value, truncate: view == "index"),
                value,
                title: value,
                **helpers.external_link_attributes
            end
          }
        )
    end

    def enum_field(attribute, **options)
      field attribute,
        as:   :select,
        enum: model_class.public_send(attribute.pluralize)
    end

    def locale_field(attribute = :locale, **options)
      field attribute,
        **options.reverse_merge(
          as:      :select,
          options: Baseline::Avo::Filters::Language.new.options.invert
        )
    end

    def image_field(attribute = :photo)
      field attribute,
        as:       :file,
        is_image: true,
        only_on:  :forms
      field attribute,
        as:      :text,
        only_on: :display,
        format_using: -> {
          if value.attached?
            size = view == "index" ? :xs_thumb : :md_fit
            link_to Rails.application.routes.url_helpers.url_for(value), **helpers.external_link_attributes do
              render helpers.component(:attachment_image, value, size)
            end
          end
        }
    end

    def polymorphic_field(attribute, **options)
      field attribute,
        **options.reverse_merge(
          as:             :belongs_to,
          polymorphic_as: attribute,
          types:          polymorphic_types_with_resource(attribute),
          default:        -> { params[:"#{attribute}_gid"]&.then { GlobalID.find(_1) } },
          searchable:     true
        )
    end

    def array_field(attribute, **options)
      field attribute,
        **options.reverse_merge(
          as: :textarea,
          format_using: -> {
            view.form? ?
              value.join("\n") :
              value.join(", ")
          },
          update_using: -> {
            value.split("\n")
          }
        )
    end

    def discover_fields
      discover_columns
      discover_associations
    end

    def timestamp_fields
      field :created_at, as: :text, only_on: :display do
        l record.created_at
      end
      field :updated_at, as: :text, only_on: :show do
        l record.updated_at
      end
    end
  end
end

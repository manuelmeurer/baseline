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
              query
                .search(params[:q])
                .order(created_at: :desc)
            },
            item: -> {
              {
                description: record.search_description
              }
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

    def field(attribute, **options, &block)
      return super if options.key?(:as)

      field_options(attribute, options)
        .unless(Array) { [_1] }
        .each {
          super attribute, **_1, &block
        }
    end

    def field_options(attribute, options)
      column                 = model_class.schema_columns[attribute]
      attribute_suffix       = attribute.to_s.split("_").last.to_sym
      association_reflection = model_class.reflections[attribute.to_s]
      attachment_reflection  = model_class.reflect_on_all_attachments.detect { _1.name == attribute }

      case
      when attribute == :id
        options.merge(as: :id)
      when attribute_suffix == :email
        [
          options.merge(as: :text, only_on: :forms, default: params[attribute]),
          options.merge(as: :text, only_on: :display, format_using: -> { mail_to value })
        ]
      when attribute_suffix == :url
        options.reverse_merge(
          as:      :text,
          default: params[attribute],
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
      when attribute_suffix == :locale
        options.reverse_merge(
          as:      :select,
          default: params[attribute],
          options: Baseline::Avo::Filters::Language.new.options.invert
        )
      when attribute_suffix == :amount
        options.reverse_merge(
          as:      :text,
          default: params[attribute],
          format_display_using: -> {
            value.format
          }
        )
      when attribute_suffix == :country
        options.reverse_merge(
          as:      :country,
          default: params[attribute],
          format_using: -> {
            value.alpha2
          }
        )
      when attachment_reflection.is_a?(ActiveStorage::Reflection::HasOneAttachedReflection)
        [
          options.reverse_merge(
            as:       :file,
            is_image: true,
            only_on:  :forms
          ),
          options.reverse_merge(
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
          )
        ]
      when attachment_reflection.is_a?(ActiveStorage::Reflection::HasManyAttachedReflection)
        options.merge(as: :has_many)
      when model_class.defined_enums.key?(attribute.to_s)
        choices = model_class
          .public_send(attribute.pluralize)
          .keys
          .index_by {
            model_class.human_enum_name attribute, _1
          }
        options.reverse_merge(
          as:      :select,
          default: params[attribute],
          options: choices
        )
      when association_reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
        options.reverse_merge({
          as:         :belongs_to,
          default:    -> { params[:"#{attribute}_gid"]&.then { GlobalID.find(_1) } },
          searchable: true
        }.if(association_reflection.options[:polymorphic]) {
          _1.merge \
            polymorphic_as: attribute,
            types:          polymorphic_types_with_resource(attribute)
        })
      when association_reflection.class.in?([ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::ThroughReflection])
        options.merge(as: :has_many)
      when association_reflection.is_a?(ActiveRecord::Reflection::HasOneReflection)
        options.merge(as: :has_one)
      when column && column[:array]
        options.reverse_merge(
          as:      :textarea,
          default: params[attribute],
          format_using: -> {
            view.form? ?
              value.join("\n") :
              value.join(", ")
          },
          update_using: -> {
            value.split("\n")
          }
        )
      when column && column[:type] == :string
        options.reverse_merge(as: :text, format_index_using: -> { value&.truncate(50) })
      when attribute.end_with?("?") || (column && column[:type] == :boolean)
        options.reverse_merge(as: :boolean)
      when column && column[:type] == :text
        options.reverse_merge(as: :textarea, format_index_using: -> { value&.truncate(50) })
      when column && column[:type].in?(%i[json jsonb])
        options.reverse_merge(as: :code, pretty_generated: true)
      when column && column[:type] == :datetime
        options.reverse_merge(as: :date_time)
      when column && column[:type] == :date
        options.reverse_merge(as: :date)
      when column && column[:type].in?(%i[float integer bigint decimal])
        options.reverse_merge(as: :number)
      else
        raise "Unexpected attribute: #{attribute}"
      end
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

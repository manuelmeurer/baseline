# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module Base
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

        def polymorphic_types_with_resource(attribute)
          model_class
            .polymorphic_types(attribute)
            .select { ::Avo::Resources.const_defined?(_1, false) }
            .map(&:constantize)
        end

        def filters
          if model_class.respond_to?(:search)
            filter Avo::Filters::Search
          end
          if model_class.respond_to?(:statuses)
            filter Avo::Filters::Status
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
          if real_model_class = options[:delegated_model_class]&.constantize
            attribute = attribute.to_s.delete_prefix("#{real_model_class.name.underscore}_").to_sym
          else
            real_model_class = model_class
          end

          column                 = real_model_class.schema_columns[attribute]
          column_type            = column[:type] if column
          attribute_suffix       = attribute.to_s.split("_").last.to_sym
          association_reflection = real_model_class.reflections[attribute.to_s]
          attachment_reflection  = real_model_class.reflect_on_all_attachments.detect { _1.name == attribute }
          default                = params[attribute] || try(:"default_#{attribute}")
          index_truncate         = { html: { index: { wrapper: { classes: "max-w-xs truncate" } } } }

          case
          when attribute == :id
            options.merge(as: :id)
          when attribute_suffix == :email
            [
              options.merge(as: :text, only_on: :forms, default:),
              options.merge(as: :text, only_on: :display, format_using: -> { mail_to value })
            ]
          when attribute_suffix == :url
            options
              .reverse_merge(index_truncate)
              .reverse_merge(
                default:,
                as: :text,
                format_display_using: -> {
                  if value.present?
                    link_to \
                      helpers.pretty_url(value, truncate: false),
                      value,
                      title: value,
                      **helpers.external_link_attributes
                  end
                }
              )
          when attribute_suffix == :locale
            options.reverse_merge(
              default:,
              as:      :select,
              options: Baseline::Avo::Filters::Language.new.options.invert
            )
          when attribute_suffix == :amount
            options.reverse_merge(
              default:,
              as: :text,
              format_display_using: -> {
                value.format
              }
            )
          when attribute_suffix == :country
            options.reverse_merge(
              default:,
              as: :country,
              format_using: -> {
                value&.alpha2
              }
            )
          when attachment_reflection.is_a?(ActiveStorage::Reflection::HasOneAttachedReflection)
            [
              options.reverse_merge(
                as:      :file,
                only_on: :forms
              ),
              options.reverse_merge(
                as:      :text,
                only_on: :display,
                format_using: -> {
                  if value.attached?
                    url  = Rails.application.routes.url_helpers.url_for(value)
                    case value.content_type
                    when Mime[:pdf]
                      tag.iframe \
                        src:   url,
                        style: "width: 100%; height: 600px;"
                    when /\Aimage\//
                      size = view == "index" ? :xs_thumb : :md_fit
                      link_to url, **helpers.external_link_attributes do
                        render helpers.component(:attachment_image, value, size)
                      end
                    else
                      raise "Unexpected content type: #{value.content_type}"
                    end
                  end
                }
              )
            ]
          when attachment_reflection.is_a?(ActiveStorage::Reflection::HasManyAttachedReflection)
            options.merge(as: :files)
          when model_class.defined_enums.key?(attribute.to_s)
            choices = model_class
              .public_send(attribute.pluralize)
              .keys
              .index_by {
                model_class.human_enum_name attribute, _1
              }
            options.reverse_merge(
              default:,
              as:      :select,
              options: choices
            )
          when association_reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
            options
              .reverse_merge(index_truncate)
              .reverse_merge({
                as:         :belongs_to,
                default:    params[:"#{attribute}_id"]&.then { association_reflection.klass.find(_1) },
                searchable: true
              }.if(association_reflection.options[:polymorphic]) {
                _1.merge \
                  default:        params[:"#{attribute}_gid"]&.then { GlobalID.find(it) },
                  polymorphic_as: attribute,
                  types:          polymorphic_types_with_resource(attribute)
              })
          when association_reflection.class.in?([ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::ThroughReflection])
            options
              .reverse_merge(index_truncate)
              .reverse_merge(as: :has_many)
          when association_reflection.is_a?(ActiveRecord::Reflection::HasOneReflection)
            options
              .reverse_merge(index_truncate)
              .reverse_merge(as: :has_one)
          when column && column[:array]
            options.reverse_merge(
              default:,
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
          when column_type == :string
            options
              .reverse_merge(index_truncate)
              .reverse_merge(as: :text)
          when attribute.end_with?("?") || column_type == :boolean
            options.reverse_merge(as: :boolean)
          when column_type == :text
            options
              .reverse_merge(index_truncate)
              .reverse_merge(
                as:                 :textarea,
                # format_show_using:  -> { helpers.auto_link(value, sanitize: false, html: helpers.external_link_attributes).html_safe }
              )
          when column_type.in?(%i[json jsonb])
            options.reverse_merge(
              as:               :code,
              pretty_generated: true
            )
          when column_type == :datetime
            options.reverse_merge(
              as:     :date_time,
              format: "ff"
            )
          when column_type == :date
            options.reverse_merge(as: :date)
          when column_type.in?(%i[float integer bigint decimal])
            options.reverse_merge(as: :number)
          else
            raise "Unexpected attribute: #{attribute}"
          end
        end

        def actions_field(&block)
          field :actions, as: :text do
            if actions = Array(instance_exec(&block)).compact.presence
              tag.div \
                safe_join(actions),
                class: "flex gap-2"
            else
              "-"
            end
          end
        end

        def timestamp_fields
          field :created_at, only_on: :display
          field :updated_at, only_on: :show
        end
      end
    end
  end
end

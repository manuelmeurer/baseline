# frozen_string_literal: true

module Baseline
  class FormFieldComponent < ApplicationComponent
    attr_reader :error_class, :placeholder
    attr_accessor :id, :attribute, :data

    def initialize(type,
        form:,
        field:              nil,
        attribute:          field.attribute,
        full_width:         false,
        hint:               Baseline::NULL_VALUE,
        i18n_params:        {},
        i18n_scope:         nil,
        identifier:         form.object_name,
        show_label:         Current.namespace.in?(%i(admin recruiters)) ? :horizontal : :vertical,
        suffix:             nil,
        value_attributes:   {},
        wrapper_attributes: {},
        data:               Baseline::NULL_VALUE,
        direct_upload:      Baseline::NULL_VALUE,
        file_label:         Baseline::NULL_VALUE,
        multiple:           Baseline::NULL_VALUE,
        required:           Baseline::NULL_VALUE,
        show_url_field:     !multiple || multiple == Baseline::NULL_VALUE,
        options:            {},
        include_blank:      false,
        disabled:           false,
        readonly:           false,
        value:              Baseline::NULL_VALUE
      )

      if type == :radio && value == Baseline::NULL_VALUE
        raise ArgumentError, "value is required for radio buttons"
      end

      {
        data:          {},
        direct_upload: false,
        file_label:    I18n.t(:select_file),
        multiple:      false,
        required:      false
      }.each do |attr, default|
        next unless binding.local_variable_get(attr) == Baseline::NULL_VALUE

        val = if field
          attr == :required ?
            field.required? :
            field.option(attr, default: default)
        else
          default
        end

        binding.local_variable_set(attr, val)
      end

      if hint == Baseline::NULL_VALUE
        hint = I18n.t(attribute,
          scope:   [Current.namespace, :form_hints, identifier],
          default: nil,
          **i18n_params
        )
      end

      # Don't use `object&.` here since `object` might be nil or false.
      id = [
        identifier,
        form.object.then { _1.id if _1 },
        attribute,
        (value if type == :radio)
      ].compact
        .join("_")

      %i(
        attribute
        data
        direct_upload
        disabled
        field
        file_label
        form
        hint
        i18n_params
        i18n_scope
        id
        identifier
        include_blank
        multiple
        options
        readonly
        required
        show_url_field
        suffix
        type
        value
        value_attributes
        wrapper_attributes
      ).each {
        instance_variable_set "@#{_1}", binding.local_variable_get(_1)
      }

      case show_label
      when :horizontal then @horizontal_label = true
      when :vertical   then @vertical_label   = true
      when :floating   then @floating_label   = true
      when false       then @no_label         = true
      else raise "Unexpected show_label: #{show_label}"
      end

      case
      when @horizontal_label
        @value_attributes[:class] = Array(@value_attributes[:class]).concat(form_classes(type: full_width ? :input_full_width : :input))
      when @floating_label
        @value_attributes[:class] = Array(@value_attributes[:class]) << "form-floating"
      end

      @wrapper_attributes[:class] = Array(@wrapper_attributes[:class]) << "form-field-#{identifier}-#{attribute}"

      if @horizontal_label
        @wrapper_attributes[:class] << "row"
      end

      # Don't use `@form.object&.errors` here since `@form.object` might be false.
      if @form.object
        @errors = @form.object.errors[attribute]
      end
      if @errors.present?
        @error_class = "is-invalid"
      end
    end

    def before_render
      human_attribute_name = @form.object ?
        helpers.custom_human_attribute_name(@form.object.class, @attribute) :
        @attribute.to_s.humanize

      # Handle nested forms with object names like `foo[bar_attributes][0]`.
      @i18n_scopes = @form
        .object_name
        .to_s
        .split(/[\[\]\d]+/)
        .compact_blank
        .map { _1.delete_suffix("_attributes") }
        .presence ||
          [@identifier]

      %i(
        label
        help_text
        placeholder
      ).each do |attr|
        [
          Current.namespace,
          attr.to_s.pluralize,
          *@i18n_scopes,
          @attribute,
          *Array(@i18n_scope)
        ].then {
          t _1.pop,
            scope:   _1,
            default: (human_attribute_name if attr == :label),
            **@i18n_params
        }.then {
          instance_variable_set "@#{attr}", _1
        }
      end

      # A placeholder is required for floating labels.
      if @floating_label
        @placeholder ||= "dummy for floating label"
      end
    end

    def label_tag
      css_class = case
        when @vertical_label then "form-label"
        when @floating_label then ""
        else ["col-form-label", *form_classes(type: :label)].join(" ")
        end.if(@required) {
          _1.split
            .append("required")
            .join(" ")
        }

      @form.label @attribute, @label, class: css_class, for: @id
    end

    private

      def field_params
        {
          class:       "form-control",
          id:          @id,
          data:        @data,
          placeholder: @placeholder,
          required:    @required,
          disabled:    @disabled,
          readonly:    @readonly
        }.if(@value != Baseline::NULL_VALUE) {
          _1.merge value: @value
        }
      end

      def content_for_type
        send :"#{@type}_content"
      end

      def base_content
        content.presence or
          raise "No content given."
      end

      def text_content
        @form.text_field @attribute,
          **field_params
      end

      def email_content
        @form.email_field @attribute,
          **field_params
      end

      def password_content
        @form.password_field @attribute,
          **field_params
      end

      def url_content
        @form.url_field @attribute,
          **field_params
      end

      def date_content
        @form.date_field @attribute,
          **field_params
      end

      def number_content
        @form.number_field @attribute,
          **field_params
      end

      def text_area_content
        @form.text_area @attribute,
          **field_params
      end

      def select_content
        @form.select @attribute,
          @options,
          {
            include_blank: @include_blank,
            disabled:      @disabled_options
          },
          class:       "form-select",
          id:          @id,
          data:        data_merge(@data, helpers.stimco(:select2)),
          placeholder: @placeholder,
          required:    @required,
          disabled:    @disabled
      end

      def country_content
        helpers.select_country @form,
          data:     @data,
          required: @required
      end

      def radio_content
        params = field_params
          .merge(class: "form-check-input")
          .tap { _1.delete :value }

        tag.div class: "form-check" do
          safe_join [
            @form.radio_button(@attribute, @value, **params),
            @form.label(@attribute, @label, value: @value, class: "form-check-label")
          ]
        end
      end

      def switch_content
        params = field_params
          .merge(class: "form-check-input")
          .if(-> { _1.delete :value }) {
            _1.merge checked: !!_2
          }

        tag.div class: "form-check form-switch" do
          @form.check_box @attribute,
            **params
        end
      end

      def file_content
        if @direct_upload
          @data = data_merge(@data, helpers.stimco(:direct_upload))
        end

        # TODO: if a file is already attached, it should be displayed here,
        # and a hidden field should be set so it is persisted (unless a new file or remote_*_url is set).
        # if attachment.attached? && form.object.new_record?
        #   image_tag attachment.blob.url
        #   form.hidden_field attribute, value: attachment.blob.url
        # end

        tag.div class: "d-flex flex-column gap-3" do
          tag.div class: "input-group file-input" do
            safe_join [
              @form.label(@attribute, @file_label, class: "input-group-text", for: @id),
              @form.file_field(@attribute,
                direct_upload: @direct_upload,
                accept:        @form.object.class.accepted_file_types(@attribute),
                multiple:      @multiple,
                **field_params
              )
            ]
          end.if(@show_url_field) {
            _1 << @form.url_field(:"remote_#{@attribute}_url",
              class:       "form-control",
              placeholder: t(:or_enter_url)
            )
          }
        end
      end

      def suggestions
        return unless @field

        suggestions = @field
          .option(:suggestions)
          .if(Proc) {
            _1.call(@field.resource)
          }

        return unless suggestions.present?

        stimco = helpers.stimco(:suggestions, default: "", to_h: false)

        suggestions.map do |suggestion|
          key, value = suggestion.unless(Array) { [suggestion, suggestion] }
          value, type = if [Date, Time, ActiveSupport::TimeWithZone].include?(value.class)
            klass = value.is_a?(ActiveSupport::TimeWithZone) ? Time : value.class
            [value.iso8601, klass.to_s.downcase]
          else
            [value, :string]
          end
          data = stimco.action(:fill,
            key:   key,
            value: value,
            type:  type
          )
          link_to key, "#",
            tabindex: -1,
            class:    "btn btn-sm btn-outline-secondary",
            data:     data
        end.then {
          tag.div \
            _1.join(" ").html_safe,
            class: "mt-2",
            data:  stimco.to_h
        }
      end
  end
end

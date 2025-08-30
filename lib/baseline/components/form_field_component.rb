# frozen_string_literal: true

module Baseline
  class FormFieldComponent < ApplicationComponent
    attr_reader :error_class, :placeholder
    attr_accessor :id, :attribute, :data

    def initialize(form, type, field_or_attribute,
        full_width:         false,
        hint:               NOT_SET,
        i18n_key:           nil,
        i18n_params:        {},
        i18n_scope:         nil,
        identifier:         form.object_name,
        label_style:        Current.default_label_style,
        suffix:             nil,
        id:                 nil,
        value_attributes:   {},
        wrapper_attributes: {},
        data:               NOT_SET,
        required:           NOT_SET,
        disabled:           false,
        readonly:           false,
        value:              NOT_SET,
        label:              NOT_SET,
        help_text:          NOT_SET,
        placeholder:        NOT_SET,
        autocomplete:       nil,
        margin_bottom:      4,
        **options
      )

      field, attribute =
        field_or_attribute.is_a?(Symbol) ?
          [nil,                field_or_attribute] :
          [field_or_attribute, field_or_attribute.attribute]

      if type == :radio && value == NOT_SET
        raise ArgumentError, "value is required for radio buttons"
      end

      i18n_key   ||= attribute
      identifier ||= attribute

      {
        data:     {},
        required: false
      }.each do |attr, default|
        next unless binding.local_variable_get(attr) == NOT_SET

        val = if field
          attr == :required ?
            field.required? :
            field.option(attr, default:)
        else
          default
        end

        binding.local_variable_set(attr, val)
      end

      if hint == NOT_SET
        hint = I18n.t(attribute,
          scope:   [::Current.namespace, :form_hints, identifier],
          default: nil,
          **i18n_params
        )
      end

      id ||= [
        identifier,
        form.object.then { _1.try(:slug) || _1.id if _1 }, # Don't use `form.object&.` since `form.object` might be false.
        attribute,
        case type
        when :radio  then value
        when :switch then options[:checked_value]
        end
      ].compact
        .join("_")

      %i[
        attribute
        autocomplete
        data
        disabled
        field
        form
        help_text
        hint
        i18n_key
        i18n_params
        i18n_scope
        id
        identifier
        label
        options
        placeholder
        readonly
        required
        suffix
        type
        value
        value_attributes
        wrapper_attributes
      ].each {
        instance_variable_set "@#{_1}", binding.local_variable_get(_1)
      }

      case label_style
      when :horizontal then @horizontal_label = true
      when :vertical   then @vertical_label   = true
      when :floating   then @floating_label   = true
      when :inline     then @inline_label     = true
      when false       then @no_label         = true
      else raise "Unexpected label_style: #{label_style}"
      end

      case
      when @horizontal_label
        @value_attributes[:class] = Array(@value_attributes[:class]).concat(form_classes(type: full_width ? :input_full_width : :input))
      when @floating_label
        @value_attributes[:class] = Array(@value_attributes[:class]) << "form-floating"
      end

      @wrapper_attributes[:class] = Array(@wrapper_attributes[:class]) << "form-field-#{identifier}-#{attribute}"

      if margin_bottom
        @wrapper_attributes[:class] << "mb-#{margin_bottom}"
      end

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

      %i[
        label
        help_text
        placeholder
      ].each do |attr|
        next unless instance_variable_get("@#{attr}") == NOT_SET

        [
          ::Current.namespace,
          attr.to_s.pluralize,
          *@i18n_scopes,
          @i18n_key,
          *Array(@i18n_scope)
        ].then {
          t _1.join("."),
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

    def label_tag(css_class = NOT_SET)
      if css_class == NOT_SET
        css_class =
          case
          when @vertical_label then "form-label"
          when @floating_label then ""
          else ["col-form-label", *form_classes(type: :label)].join(" ")
          end.if(@required) {
            _1.split
              .append("required")
              .join(" ")
          }
      end

      @form.label \
        @attribute,
        @label,
        class: css_class,
        for:   @id
    end

    private

      def field_attributes
        {
          class:        "form-control",
          id:           @id,
          data:         @data,
          placeholder:  @placeholder,
          required:     @required,
          disabled:     @disabled,
          readonly:     @readonly,
          autocomplete: @autocomplete
        }.if(@value != NOT_SET) {
          _1.merge value: @value
        }
      end

      def content_for_type
        content_method = :"#{@type}_content"
        if respond_to?(content_method, true)
          send content_method
        else
          raise "Unknown content type: #{@type}"
        end
      end

      def base_content
        content.presence or
          raise "No content given."
      end

      def text_content
        @form.text_field @attribute,
          **field_attributes
      end

      def email_content
        @form.email_field @attribute,
          **field_attributes
      end

      def password_content
        @form.password_field @attribute,
          **field_attributes
      end

      def url_content
        @form.url_field @attribute,
          **field_attributes
      end

      def date_content
        @form.date_field @attribute,
          **field_attributes
      end

      def number_content
        @form.number_field @attribute,
          **field_attributes
      end

      def text_area_content
        @form.text_area @attribute,
          **field_attributes
      end

      def select_content
        expected_options = %i[
          choices
          disabled
          include_blank
        ]
        invalid_options = @options.keys - expected_options
        if invalid_options.any?
          raise ArgumentError, "Invalid options: #{invalid_options.join(", ")}"
        end

        unless choices = @options.delete(:choices)
          raise Error, "Missing choices."
        end

        @data = data_merge(@data, helpers.stimco(:select2))

        html_options = field_attributes.merge(class: "form-select")

        @form.select @attribute,
          choices,
          @options,
          html_options
      end

      def country_content
        helpers.select_country @form,
          data:     @data,
          required: @required
      end

      def radio_content
        options = field_attributes
          .merge(class: "form-check-input")
          .except(:value)

        tag.div class: "form-check" do
          safe_join [
            @form.radio_button(@attribute, @value, options),
            (label_tag("form-check-label") if @inline_label)
          ]
        end
      end

      def switch_content
        expected_options = %i[
          checked_value
          unchecked_value
          checked
          include_hidden
          multiple
        ]
        invalid_options = @options.keys - expected_options
        if invalid_options.any?
          raise ArgumentError, "Invalid options: #{invalid_options.join(", ")}"
        end

        value_options = {
          checked_value:   1,
          unchecked_value: 0
        }.map {
          @options.delete(_1) || _2
        }
        options = field_attributes
          .merge(@options)
          .merge(class: "form-check-input")

        tag.div class: "form-check form-switch" do
          safe_join [
            @form.checkbox(@attribute, options, *value_options),
            (label_tag("form-check-label") if @inline_label)
          ]
        end
      end

      def switches_content
        expected_options = %i[
          choices
        ]
        invalid_options = @options.keys - expected_options
        if invalid_options.any?
          raise ArgumentError, "Invalid options: #{invalid_options.join(", ")}"
        end

        choices = @options.fetch(:choices)
        expected_choice_options = %i[
          checked
          label
        ]

        checkboxes = choices.map do |value, options|
          invalid_choice_options = options.keys - expected_choice_options
          if invalid_choice_options.any?
            raise ArgumentError, "Invalid choice options: #{invalid_choice_options.join(", ")}"
          end

          options[:label] ||= value

          helpers.render self.class.new(
            @form,
            :switch,
            @field || @attribute,
            label_style:    :inline,
            multiple:       true,
            include_hidden: false,
            checked_value:  value,
            **options
          )
        end

        safe_join checkboxes, "\n"
      end

      def file_content
        expected_options = %i[
          direct_upload
          multiple
          show_url_field
        ]
        invalid_options = @options.keys - expected_options
        if invalid_options.any?
          raise ArgumentError, "Invalid options: #{invalid_options.join(", ")}"
        end

        show_url_field = @options.key?(:show_url_field) ?
          @options.delete(:show_url_field) :
          !@options[:multiple]

        if @options[:direct_upload]
          @data = data_merge(@data, helpers.stimco(:direct_upload))
        end

        options = field_attributes
          .merge(@options)
          .merge(accept: @form.object.class.accepted_file_types(@attribute))

        field = @form.file_field(@attribute, **options)

        return field unless show_url_field

        tag.div class: "d-flex flex-column gap-3" do
          safe_join [
            field,
            @form.url_field(:"remote_#{@attribute}_url",
              class:       "form-control",
              placeholder: t(:or_enter_url)
            )
          ], "\n"
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
            key:,
            value:,
            type:
          )
          link_to key, "#",
            tabindex: -1,
            class:    "btn btn-sm btn-outline-secondary",
            data:
        end.then {
          tag.div \
            _1.join(" ").html_safe,
            class: "mt-2",
            data:  stimco.to_h
        }
      end
  end
end

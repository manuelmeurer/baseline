# frozen_string_literal: true

module Baseline
  class IconComponent < ApplicationComponent
    VERSIONS = %i[
      solid
      regular
      light
      duotone
      thin
      brands
    ].freeze

    ICON_CLASSES = {
      nil => {
        accept:   "fa-circle-check",
        reject:   "fa-circle-xmark",
        add:      "fa-circle-plus",
        remove:   "fa-trash",
        edit:     "fa-pen",
        view:     "fa-eye",
        info:     "fa-circle-info",
        warning:  "fa-triangle-exclamation",
        announce: "fa-bullhorn",
        external: "fa-square-up-right",
        back:     "fa-arrow-left-long",
        forward:  "fa-arrow-right-long",
        yes:      "fa-thumbs-up",
        no:       "fa-thumbs-down"
      }
    }.freeze

    def initialize(identifier, scope: nil, version: :regular, size: nil, fixed_width: false, **kwargs)
      unless version.in?(VERSIONS)
        raise "#{version} is not a valid versions: #{VERSIONS.join(", ")}"
      end

      @version, @size, @fixed_width, @kwargs =
        version, size, fixed_width, kwargs

      @icon_class =
        case
        when identifier.class.in?([Symbol, Integer])
          case ic = ICON_CLASSES.fetch(scope) { Baseline.configuration.custom_icon_classes.fetch(scope) }
          when Hash  then ic.fetch(identifier.to_sym)
          when Array then ic[identifier] or raise "#{identifier} not found in icon classes: #{ic.join(", ")}"
          else raise "Unexpected classes: #{ic.class}"
          end
        when scope
          raise "Scope should be nil if identifier is not a symbol."
        else
          "fa-#{identifier}"
        end
    end

    def call
      tag.i \
        class: [
          "fa-#{@version}",
          @size&.then { "fa-#{_1}" },
          ("fa-fw" if @fixed_width),
          @icon_class,
          @kwargs.delete(:class)
        ].compact,
        **@kwargs
    end
  end
end

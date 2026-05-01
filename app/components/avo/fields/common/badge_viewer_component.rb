# frozen_string_literal: true

# Override Avo's BadgeViewerComponent to remove whitespace-nowrap/truncate classes,
# add overflow ellipsis styles, and split badge values by underscore.
# We need to re-implement the full class because ViewComponent requires the class
# file to exist alongside the template for proper template resolution.

class Avo::Fields::Common::BadgeViewerComponent < Avo::BaseComponent
  prop :value
  prop :options

  def after_initialize
    @backgrounds = {
      info:    "bg-blue-500",
      success: "bg-green-500",
      danger:  "bg-red-500",
      warning: "bg-yellow-500",
      neutral: "bg-gray-500"
    }
  end

  def classes
    background = :info

    @options.invert.each do |values, type|
      if [values].flatten.map(&:to_s).include?(@value.to_s)
        background = type.to_sym
        next
      end
    end

    classes = "rounded-md uppercase px-2 py-1 text-xs font-bold block text-center w-full "
    classes += "#{@backgrounds[background]} text-white" if @backgrounds[background].present?
    classes
  end
end

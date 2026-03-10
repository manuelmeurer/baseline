# frozen_string_literal: true

# Override Avo's BadgeViewerComponent to remove whitespace-nowrap/truncate classes,
# add overflow ellipsis styles, and split badge values by underscore.
# We need to re-implement the full class because ViewComponent requires the class
# file to exist alongside the template for proper template resolution.

# Verify original implementation hasn't changed from version 3.28.0, when this override was created.
Baseline::VerifyGemFileSource.call(
  "avo",
  "app/components/avo/fields/common/badge_viewer_component.rb" => "957956fc5c191e4085c9be3f7c4ff19eb980ccf5ccce7035bb2e4b1c37189d81",
  "app/components/avo/fields/common/badge_viewer_component.html.erb" => "5af2075ae05a191803cc318d6364f46c67670b573480cd4cd781306e53198f9b"
)

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

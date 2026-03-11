# frozen_string_literal: true

# Override Avo's belongs_to index component to show a circular user photo
# next to the name when the associated record includes ActsAsUser.

# Verify original implementation hasn't changed from version 3.28.0, when this override was created.
Baseline::VerifyGemFileSource.call(
  "avo",
  "app/components/avo/fields/belongs_to_field/index_component.rb" => "f4e1b6ba6d5c0103bec6ab40dbd003e28409e96c9ff5066aa2a4c0695df16d6a",
  "app/components/avo/fields/belongs_to_field/index_component.html.erb" => "dd8112e982a972ce0b2c8fd978b5ffd9d9a3b54f5c17beb31cc92180ec93243f"
)

class Avo::Fields::BelongsToField::IndexComponent < Avo::Fields::IndexComponent
  def call
    index_field_wrapper(**field_wrapper_args) do
      link_to helpers.resource_view_path(
        record: @field.index_link_to_record,
        resource: @field.index_link_to_resource
      ) do
        user_avatar_label
      end
    end
  end

  private

  def user_avatar_label
    if @field.value.respond_to?(:photo_or_dummy)
      photo = @field.value.photo_or_dummy
      src = Rails.application.routes.url_helpers.url_for(photo.variant(resize_to_fill: [20, 20]))
      tag.span(class: "flex items-center gap-1") do
        tag.img(src:, class: "w-5 h-5 rounded-full object-cover") +
          @field.label
      end
    else
      @field.label
    end
  end
end

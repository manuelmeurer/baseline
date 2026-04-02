# frozen_string_literal: true

# Override Avo's belongs_to show component to show a circular user photo
# next to the name when the associated record includes ActsAsUser.

# Verify original implementation hasn't changed from version 3.28.0, when this override was created.
Baseline::VerifyGemFileSource.call(
  "avo",
  "app/components/avo/fields/belongs_to_field/show_component.rb" => "1159ce15668d42f9e3a9e65a0c2ad2eef1c85bce3949f6a95a556f90412e3c3d",
  "app/components/avo/fields/belongs_to_field/show_component.html.erb" => "e742000e7d15497796ff990ff6e0d3e152e61e782ae3bb87d40a25cff974427d"
)

class Avo::Fields::BelongsToField::ShowComponent < Avo::Fields::ShowComponent
  def call
    field_wrapper(**field_wrapper_args) do
      link_to resource_view_path, data: {turbo_frame: @field.target} do
        user_avatar_label
      end
    end
  end

  private

  def resource_view_path
    helpers.resource_view_path(
      record: @field.value,
      resource: @field.target_resource,
      via_resource_class: @resource.class.to_s,
      via_record_id: @resource.record_param
    )
  end

  def user_avatar_label
    if @field.value.respond_to?(:photo_or_dummy)
      photo = @field.value.photo_or_dummy
      src = helpers.main_app.url_for(photo.variant(resize_to_fill: [20, 20]))
      tag.span(class: "flex items-center gap-1") do
        tag.img(src:, class: "rounded-full object-cover", style: "width: 1.8rem; height: 1.8rem") +
          @field.label
      end
    else
      @field.label
    end
  end
end

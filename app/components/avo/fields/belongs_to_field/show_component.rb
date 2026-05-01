# frozen_string_literal: true

# Override Avo's belongs_to show component to show a circular user photo
# next to the name when the associated record includes ActsAsUser.

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
      tag.span(class: "flex items-center gap-2") do
        tag.img(src:, class: "rounded-full object-cover", style: "width: 1.8rem; height: 1.8rem") +
          @field.label
      end
    else
      @field.label
    end
  end
end

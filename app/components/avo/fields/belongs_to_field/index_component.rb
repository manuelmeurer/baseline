# frozen_string_literal: true

# Override Avo's belongs_to index component to show a circular user photo
# next to the name when the associated record includes ActsAsUser.

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

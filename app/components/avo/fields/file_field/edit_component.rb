# frozen_string_literal: true

# Overridden to add a URL text field below the file picker,
# allowing admins to attach files by pasting a remote URL.
# The remote_*_url= setter is defined in Baseline::ModelCore.

# Verify original implementation hasn't changed from version 3.28.0, when this override was created.
Baseline::VerifyGemFileSource.call(
  "avo",
  "app/components/avo/fields/file_field/edit_component.rb" => "7ac6fd5c8d4f701ac4d6d5b8ffa727650f3c05dd48d972015afbfc8fe980fbeb",
  "app/components/avo/fields/file_field/edit_component.html.erb" => "6d83c98fa2c64a79f5696f1dcbc5e017f923a951de586c7b227f1040ff9b919f"
)

class Avo::Fields::FileField::EditComponent < Avo::Fields::EditComponent
  include Avo::Fields::Concerns::FileAuthorization
end

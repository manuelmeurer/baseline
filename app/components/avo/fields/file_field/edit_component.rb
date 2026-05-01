# frozen_string_literal: true

# Overridden to add a URL text field below the file picker,
# allowing admins to attach files by pasting a remote URL.
# The remote_*_url= setter is defined in Baseline::ModelCore.

class Avo::Fields::FileField::EditComponent < Avo::Fields::EditComponent
  include Avo::Fields::Concerns::FileAuthorization
end

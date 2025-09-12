# frozen_string_literal: true

require "paper_trail"

PaperTrail.config.has_paper_trail_defaults = {
  on: %i[create update destroy]
}

PaperTrail.request.whodunnit = -> {
  (::Current.admin_user || ::Current.user)&.then {
    _1.to_gid.to_s
  }
}

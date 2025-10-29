# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    include Baseline::Authentication[:with_admin_user]
  end
end

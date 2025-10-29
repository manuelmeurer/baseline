# frozen_string_literal: true

module Web
  class BaseController < ApplicationController
    include Baseline::SetLocale,
            Baseline::WebBaseControllable
  end
end

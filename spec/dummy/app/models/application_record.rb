# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Baseline::ModelCore

  primary_abstract_class
end

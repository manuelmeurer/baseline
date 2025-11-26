# frozen_string_literal: true

class Deactivation < ApplicationRecord
  include Baseline::ActsAsDeactivation
end

# == Schema Information
#
# Table name: deactivations
#
#  id                 :integer          not null, primary key
#  deactivatable_type :string           not null
#  details            :text
#  initiator_type     :string
#  reason             :string           not null
#  revoked_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  deactivatable_id   :integer          not null
#  initiator_id       :integer
#

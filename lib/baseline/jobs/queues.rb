# frozen_string_literal: true

class Baseline::Jobs::Queues
  include Enumerable

  delegate :each, to: :values
  delegate :values, to: :queues_by_id, private: true
  delegate :size, :length, :to_s, :inspect, to: :queues_by_id

  def initialize(queues)
    @queues_by_id = queues.index_by(&:id).with_indifferent_access
  end

  def to_h
    queues_by_id.dup
  end

  def [](name)
    queues_by_id[name.to_s.parameterize]
  end

  private
    attr_reader :queues_by_id
end

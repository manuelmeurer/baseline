# frozen_string_literal: true

ActiveJob::JobsRelation = Baseline::Jobs::Relation unless ActiveJob.const_defined?(:JobsRelation, false)

module Baseline
  module ModelExtensions
    extend ActiveSupport::Concern

    included do
      %i(one many).each do |one_or_many|
        has_attached_method = :"has_#{one_or_many}_attached"

        define_singleton_method has_attached_method do |*args, production_service: nil, **kwargs|
          if production_service && Rails.env.production?
            kwargs[:service] = production_service
          end

          super *args, **kwargs
        end

        define_singleton_method :"#{has_attached_method}_and_accepts_nested_attributes_for" do |attribute, **kwargs|
          attachment_attribute = [
            attribute,
            one_or_many == :many ? :attachments : :attachment
          ].join("_")
           .to_sym

          public_send has_attached_method, attribute, **kwargs
          accepts_nested_attributes_for attachment_attribute, allow_destroy: true
        end
      end

      %i(has_many has_one belongs_to).each do |association_method|
        define_singleton_method association_method do |*args, **kwargs|
          super(*args, **kwargs).each do |association, reflection|
            polymorphic_reflection = reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection) &&
                                     reflection.options[:polymorphic]

            if polymorphic_reflection
              define_method "#{reflection.name}_gid" do
                public_send(reflection.name)&.to_gid&.to_s
              end

              define_method "#{reflection.name}_gid=" do |value|
                object = if value.present?
                  GlobalID::Locator.locate!(value)
                end
                public_send "#{reflection.name}=", object
              end
            end

            with_scope_name = :"with_#{association}"
            unless respond_to?(with_scope_name)
              scope with_scope_name, ->(param = true) {
                generate_joins_scope = -> { joins(association.to_sym).distinct }
                case param
                when Class
                  unless polymorphic_reflection
                    raise "A parameter of type #{param.class} only makes sense for polymorphic associations."
                  end
                  where "#{association}_type": param.to_s
                when ActiveRecord::Base, Array
                  if reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
                    where(association => param)
                  else
                    generate_joins_scope.call.where(reflection.klass.table_name => { id: param })
                  end
                when ActiveRecord::Relation
                  case
                  when polymorphic_reflection
                    where "#{association}_type": param.klass.to_s,
                          "#{association}_id":   param
                  else
                    generate_joins_scope.call.merge(param)
                  end
                when true
                  if reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
                    where.not(reflection.foreign_key => nil)
                  else
                    generate_joins_scope.call.where.not(reflection.klass.table_name => { id: nil })
                  end
                else
                  raise "Unexpected parameter to #{name}.#{with_scope_name}: #{param} (#{param.class})"
                end
              }
            end

            without_scope_name = :"without_#{association}"
            unless respond_to?(without_scope_name)
              scope without_scope_name, ->(record_or_scope = true) {
                case
                when record_or_scope == true
                  if reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
                    where(reflection.foreign_key => nil)
                  else
                    # We have to use `unscoped` here, otherwise all scopes that are currently applied
                    # to this Relation would be duplicated in the subquery.
                    where.not(id: unscoped.public_send(with_scope_name))
                  end
                when record_or_scope.respond_to?(:none?) && record_or_scope.none?
                  return
                else
                  # We have to use `unscoped` here, otherwise all scopes that are currently applied
                  # to this Relation would be duplicated in the subquery.
                  where.not(id: unscoped.public_send(with_scope_name, record_or_scope))
                end
              }
            end
          end
        end
      end
    end

    class_methods do
      def inherited(subclass)
        super

        if subclass.table_exists?
          timestamps = %w(created_at updated_at).select do |timestamp|
            subclass.column_names.include?(timestamp)
          end
          if timestamps.any?
            subclass.include HasTimestamps[*timestamps]
          end
        end
      end
    end
  end
end

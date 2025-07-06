# frozen_string_literal: true

module Baseline
  module ModelCore
    extend ActiveSupport::Concern

    included do
      { one: 1, many: 2 }.each do |one_or_many, pluralize_count|
        has_attached_method = :"has_#{one_or_many}_attached"

        define_singleton_method has_attached_method do |name, production_service: nil, **kwargs|
          if production_service && Rails.env.production?
            kwargs[:service] = production_service
          end

          super name, **kwargs

          clone_method_name = [
            name,
            "clone_id".pluralize(pluralize_count)
          ].join("_")
            .then { :"#{_1}=" }

          define_method clone_method_name do |ids|
            ids.each do |id|
              ActiveStorage::Attachment.find(id).then {
                public_send(name).attach \
                  io:       StringIO.new(_1.download),
                  filename: _1.filename.to_s
              }
            end
          end

          if one_or_many == :one
            attr_reader :"remote_#{name}_url"

            define_method "remote_#{name}_url=" do |value|
              instance_variable_set :"@remote_#{name}_url", value.presence

              return unless value.present?

              begin
                file = Baseline::DownloadFile.call(value)
              rescue Baseline::DownloadFile::Error => error
                if error.cause.is_a?(HTTP::RequestError)
                  errors.add name, message: %(could not be downloaded from "#{value}": #{error.cause.message} (#{error.cause.class}))
                else
                  raise error
                end
              else
                public_send(name).attach \
                  io:       File.open(file),
                  filename: file.basename
              end
            end
          end
        end

        define_singleton_method :"#{has_attached_method}_and_accepts_nested_attributes_for" do |attribute, **kwargs|
          attachment_attribute = [
            attribute,
            "attachment".pluralize(pluralize_count)
          ].join("_")
            .to_sym

          public_send has_attached_method, attribute, **kwargs

          accepts_nested_attributes_for \
            attachment_attribute,
            allow_destroy: true
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
                  GlobalID.find!(value)
                end
                public_send "#{reflection.name}=", object
              end
            end

            with_scope_name = :"with_#{association}"
            unless respond_to?(with_scope_name)
              scope with_scope_name, ->(param = true, exact: false) {
                generate_joins_scope = -> { joins(association.to_sym).distinct }
                generate_filter_by_id_scope = -> {
                  generate_joins_scope
                    .call
                    .where(reflection.klass.table_name => { id: param })
                }

                case param
                when Class
                  unless polymorphic_reflection
                    raise "A parameter of type #{param.class} only makes sense for polymorphic associations."
                  end
                  where "#{association}_type": param.to_s
                when ActiveRecord::Base, Array
                  case
                  when param.is_a?(Array) && exact
                    if param.empty?
                      public_send :"without_#{association}"
                    else
                      param_ids = param.map {
                        _1.class.in?([String, Integer]) ?
                          _1.to_i :
                          _1.id
                      }.sort
                      ids = to_a.select {
                        _1.public_send(association).pluck(:id).sort ==
                          param_ids
                      }
                      where(id: ids)
                    end
                  when reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
                    where(association => param)
                  else
                    generate_filter_by_id_scope.call
                  end
                when ActiveRecord::Relation
                  case
                  when exact
                    if param.none?
                      public_send :"without_#{association}"
                    else
                      param_ids = param.pluck(:id).sort
                      ids = to_a.select {
                        _1.public_send(association).pluck(:id).sort ==
                          param_ids
                      }
                      where(id: ids)
                    end
                  when polymorphic_reflection
                    where "#{association}_type": param.klass.to_s,
                          "#{association}_id":   param
                  when param.values.key?(:limit)
                    # If the relation has a limit, we need to explicitly filter by ID,
                    # otherwise the limit will be applied to the complete query and return wrong results.
                    generate_filter_by_id_scope.call
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

      delegate \
        :service_namespace,
        :service_namespaces,
        to: :class
    end

    def method_missing(method, *args, _async: false, _after: nil, **kwargs)
      return super unless service_name = method[/\A_do_(.+)/, 1]&.classify

      service = service_namespaces
        .lazy
        .map do |namespace|
          suppress NameError do
            namespace.const_get(service_name)
          end
        end
        .compact
        .first

      unless service
        raise "Could not find service #{service_name} for #{self.class}."
      end

      if persisted?
        if service.enqueued_or_processing?(self)
          raise "#{self.class} {service_name} is already in progress."
        end
        if service.scheduled_at(self)
          raise "#{self.class} {service_name} is already scheduled."
        end
      end

      case
      when _after
        service.call_in _after, self, *args, **kwargs
      when _async
        service.call_async self, *args, **kwargs
      else
        service.call self, *args, **kwargs
      end
    end

    class_methods do
      def accepted_file_types(attribute)
        unless reflect_on_attachment(attribute)
          raise "#{attribute} is not an attachment."
        end

        return unless validator = validators
          .grep(ActiveStorageValidations::ContentTypeValidator)
          .detect { _1.attributes == [attribute.to_sym] }

        validator
          .options
          .then { _1[:in] || _1.fetch(:with) }
          .then { Array(_1) }
          .map {
            case _1
            when String
            when Symbol then Marcel::MimeType.for(extension: _1) || raise("Unexpected extension: #{_1}")
            else raise "Unexpected value: #{_1.class}"
            end
          }.join(", ")
      end

      def translates_with_fallback(*)
        translates(*, fallback: :any)
      end

      def service_namespace
        service_namespaces.first or
          raise "Could not find service namespace for #{name}."
      end

      def service_namespaces
        ancestors
          .take_while { _1 != ApplicationRecord }
          .grep(Class)
          .map {
            _1.to_s
              .pluralize
              .safe_constantize
          }.compact
      end

      if defined?(::Ransack)
        def ransackable_attributes(auth_object = nil)
          authorizable_ransackable_attributes
        end
      end

      # Do not reference any ApplicationModel descendants in this method!
      def _baseline_finalize
        if base_class != self
          raise "Don't call #{__method__} in a class that does not inherit from ApplicationRecord."
        end

        proceed = Kernel.suppress(ActiveRecord::NoDatabaseError) do
          table_exists?
        end

        return unless proceed

        if @_baseline_finalized
          raise "Model #{name} has already been finalized."
        end

        unless instance_methods(false).include?(:to_s)
          define_method :to_s do
            try(:name) ||
              try(:title) ||
              "#{model_name.human} #{try(:slug) || id || "[new]"}"
          end
        end

        if timestamp_attributes = %w(created_at updated_at).intersection(column_names).presence
          include HasTimestamps[*timestamp_attributes]
        end

        unless to_s == "Task" || columns.map(&:name).include?("tasks")
          has_many :tasks, as: :taskable, dependent: :destroy
        end

        columns.each do |column|
          attribute = column.name.to_sym
          array     = column.try(:array) # Postgres only

          if column.type.in?(%i[string text]) && !array
            normalizes attribute,
              with: -> { _1.to_s.encode("UTF-8").strip.unicode_normalize.presence }
          end

          case
          when column.type == :string
            method_name = attribute.to_s.pluralize
            unless respond_to?(method_name, true)
              define_singleton_method method_name do
                pluck(Arel.sql("DISTINCT #{attribute}"))
                  .compact
                  .sort
              end
            end
          when column.type == :boolean
            not_attributes = %i(un not_).map {
              [_1, attribute].join.to_sym
            }
            unless [attribute, *not_attributes].any? { respond_to? _1, true }
              scope attribute, -> { where(attribute => true) }
              not_attributes.each do |not_attribute|
                scope not_attribute, -> { where(attribute => false) }
              end
            end
          when array
            define_method("#{attribute}=") do |value|
              if value.is_a?(String)
                value = value.split(/(\r?\n)+/)
              end
              value
                .map { _1.is_a?(String) ? _1.strip : _1 }
                .uniq
                .compact_blank
                .then { super _1 }
            end

            scope :"with_#{attribute}", ->(*values) {
              where.overlap(attribute => values)
            }
          when column.type.in?(%i(json jsonb))
            scope :"with_#{attribute}", ->(*values) {
              if values.empty?
                case connection.adapter_name
                when "PostgreSQL"
                  [[], {}].inject(self) {
                    _1.where("#{attribute} != '#{_2}'::#{column.type}")
                  }
                when "SQLite"
                  [[], {}].inject(self) {
                    _1.where("#{attribute} != '#{_2}'")
                  }
                else raise "Unexpected database adapter: #{connection.adapter_name}"
                end
              else
                values.inject(self) do |scope, value|
                  case connection.adapter_name
                  when "PostgreSQL"
                    value.is_a?(Hash) ?
                      scope.where.contains(attribute => value) :
                      scope.where("#{attribute} ? :value", value: value.to_s)
                  when "SQLite"
                    scope.where("EXISTS (
                      SELECT 1 FROM json_each(#{attribute})
                      WHERE value = ?
                    )", value)
                  else raise "Unexpected database adapter: #{connection.adapter_name}"
                  end
                end
              end
            }
          end
        end

        @_baseline_finalized = true
      end
    end
  end
end

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
                when Class, String
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
        :resolve_service,
        to: :class
    end

    class_methods do
      def inherited(subclass)
        if subclass.base_class&.then { _1 != subclass }
          return super
        end

        super

        if defined?(PaperTrail) &&
          Baseline.configuration.no_paper_trail_classes.exclude?(subclass.to_s) &&
          !subclass.respond_to?(:paper_trail_options)

          subclass.has_paper_trail

          def subclass.versions
            PaperTrail::Version.where(item_type: name)
          end
        end
      end

      def custom_human_attribute_name(attribute)
        I18n.t attribute,
          scope:   [::Current.namespace, :human_attribute_names, to_s.underscore],
          default: human_attribute_name(attribute)
      end

      def last_changed_after(attribute, datetime, by: nil)
        if by && (!by.is_a?(ActiveRecord::Relation) || by.klass != User)
          raise "Expected a relation on the User class."
        end

        PaperTrail::Version
          .where(object_changes_contain_key_where(attribute))
          .where(created_at: datetime..)
          .if(by) { _1.where(whodunnit: by.select("id::text")) }
          .then { with_versions _1 }
      end

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
            it.if(Symbol) {
              Marcel::MimeType.for(extension: _1) or
                raise "Unexpected extension: #{_1}"
            }
          }
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
            _1.to_s.pluralize
          }.then {
            _1 + _1.map { "Baseline::#{it}" }
          }.map(&:safe_constantize)
          .compact
      end

      def resolve_service(service_name)
        service_name = service_name.to_s.gsub("__", "/")

        @resolved_services ||= {}
        @resolved_services[service_name] ||= begin
          service_namespaces
            .lazy
            .map do |namespace|
              Kernel.suppress NameError do
                namespace.const_get(service_name.camelize)
              end
            end
            .compact
            .first or
              raise "Could not find service #{service_name} for #{self.class}."
        end
      end

      def enum_with_human_name(name, ...)
        enum(name, ...)
        define_method "human_#{name}" do
          self.class.human_enum_name name, public_send(name)
        end
      end

      def human_enum_name(enum, value, modifier = nil)
        return if value.blank?

        key = [
          enum.pluralize,
          modifier
        ].compact
          .join("_")

        scope = [
          :activerecord,
          :attributes,
          model_name.i18n_key,
          key
        ]

        I18n.t value,
          scope:,
          default: value.humanize
      end

      def common_image_file_types = %i[jpeg png svg webp gif]

      if defined?(::Ransack)
        def ransackable_attributes(auth_object = nil)
          authorizable_ransackable_attributes
        end
      end

      def polymorphic_types(association)
        unless reflect_on_association(association).try(:polymorphic?)
          raise "#{association} is not a polymorphic association of #{self}."
        end

        cache_key = ApplicationRecord
          .descendants
          .map(&:name)
          .sort
          .push(association.to_s)
          .join
          .then { ActiveSupport::Digest.hexdigest(_1) }

        @polymorphic_types_cache ||= {}
        @polymorphic_types_cache[cache_key] ||= begin
          ApplicationRecord.descendants.select {
            it.reflections.values.any? {
              (_1.try(:collection?) || _1.try(:has_one?)) &&
                _1.klass == self &&
                _1.options[:as] == association
            }
          }.map(&:name)
        end
      end

      def db_and_table_exist?
        table_exists?
      rescue ActiveRecord::NoDatabaseError
        false
      end

      def object_changes_contain_key_where(key)
        {
          postgresql: ["object_changes ? :key", key:],
          sqlite:     ["json_extract(object_changes, ?) IS NOT NULL", "$.#{key}"]
        }.fetch(connection.adapter_name.downcase.to_sym) {
          raise "Unexpected database adapter: #{connection.adapter_name}"
        }
      end

      def schema_columns
        return @schema_columns if defined?(@schema_columns)
        return {} unless db_and_table_exist?

        schema_path = Rails.root.join("db", "schema.rb")
        unless File.exist?(schema_path)
          raise "Could not find schema file at #{schema_path}."
        end

        content = File.read(schema_path)

        # Find the create_table block for this model
        create_table_regex = /create_table\s+"#{Regexp.escape(table_name)}".*?do\s+\|t\|(.*?)\n\s+end/m
        unless table_block = content[create_table_regex, 1]
          raise "Could not find create_table block for #{table_name} in schema.rb."
        end

        columns = {}
        table_block.each_line do |line|
          # Skip non-column lines (indexes, check_constraints, etc.)
          next unless line.match?(/^\s+t\.(\w+)\s+"(\w+)"/)

          # Parse lines like:
          # t.datetime "updated_at", precision: nil, null: false
          # t.integer "min_days"
          # t.string "sluggable_type", limit: 50
          match = line.match(/^\s+t\.(\w+)\s+"(\w+)"(?:,\s*(.*))?/)
          next unless match

          column_type = match[1].to_sym
          column_name = match[2]
          options     = match[3]

          column_data = { type: column_type }

          options&.scan(/(\w+):\s*([^,]+)/) do |key, value|
            parsed_value =
              case value.strip
              when "nil"      then nil
              when "true"     then true
              when "false"    then false
              when /^\d+$/    then value.to_i
              when /^"(.+)"$/ then $1
              when /^\[\]$/   then []
              when /^\{\}$/   then {}
              else value.strip
              end

            column_data[key.to_sym] = parsed_value
          end

          columns[column_name.to_sym] = column_data
        end

        @schema_columns = columns.sort.to_h
      end

      # Do not reference any ApplicationModel descendants in this method!
      def _baseline_finalize
        if base_class != self
          raise "Don't call #{__method__} in a class that does not inherit from ApplicationRecord."
        end

        if defined?(@_baseline_finalized)
          raise "Model #{name} has already been finalized."
        end

        if respond_to?(:status_scopes)
          define_singleton_method :statuses do
            status_scopes.keys
          end

          status_scopes.each do |status, scopes|
            next unless scopes

            predicate_method = "#{status}?".to_sym

            if respond_to?(status, true)
              raise "Status scope #{status} is invalid, a scope or class method by that name already exists in #{name}."
            end
            if instance_methods.include?(predicate_method)
              raise "Status scope #{status} is invalid, an instance method named `#{predicate_method}` already exists in #{name}."
            end

            scope status, -> {
              scopes.inject(all) {
                _1.public_send(_2)
              }
            }

            define_method predicate_method do
              self
                .class
                .public_send(status)
                .exists?(id)
            end
          end

          define_method :status do
            self
              .class
              .statuses
              .detect {
                public_send "#{_1}?"
              } or
                raise "Could not determine status."
          end
        end

        included_modules.each do |mod|
          next unless enum_array_attribute = mod.try(:enum_array_attribute)

          default_enum_array_method = :"default_#{enum_array_attribute}"
          if instance_methods.include?(default_enum_array_method)
            after_initialize if: :new_record? do
              unless public_send(enum_array_attribute).present?
                public_send "#{enum_array_attribute}=", public_send(default_enum_array_method)
              end
            end
          end
        end

        if instance_methods.include?(:password) && instance_methods.include?(:default_password)
          after_initialize if: :new_record? do
            self.password ||= default_password
          end

          define_method :password_changed? do
            !authenticate(default_password)
          end
        end

        schema_columns
          .keys
          .select { _1.match?(/(?:\A|_)locale\z/) }
          .each do |locale_attribute|

          default_locale_method = :"default_#{locale_attribute}"
          if instance_methods.include?(default_locale_method)
            after_initialize if: :new_record? do
              unless public_send(locale_attribute)
                public_send "#{locale_attribute}=", public_send(default_locale_method)
              end
            end
          end
        end

        if instance_method(:to_s).owner == Kernel
          define_method :to_s do
            try(:name) ||
              try(:title) ||
              "#{model_name.human} #{try(:slug) || id || "[new]"}"
          end
        end

        if timestamp_attributes = %i[created_at updated_at].intersection(schema_columns.keys).presence
          include HasTimestamps[*timestamp_attributes]
        end

        if to_s == "User" && reflect_on_association(:subscriptions)
          scope :subscribed, ->(identifier, before: nil) {
            unless Subscription.identifiers.include?(identifier.to_s)
              raise "Identifier is not valid: #{identifier}"
            end

            with_subscriptions(Subscription.public_send(identifier))
              .if(before) {
                _1.merge(UserSubscription.created_before(_2))
              }
          }

          define_method :subscribe do |identifier|
            unless Subscription.valid_identifiers_for(self).include?(identifier.to_s)
              raise "Identifier is not valid for user: #{identifier}"
            end

            subscription = Subscription.public_send(identifier)

            unless subscriptions.exists?(id: subscription)
              subscriptions << subscription
            end
          end

          define_method :unsubscribe do |identifier|
            unless Subscription.valid_identifiers_for(self).include?(identifier.to_s)
              raise "Identifier is not valid for user: #{identifier}"
            end

            subscription = Subscription.public_send(identifier)

            if subscriptions.exists?(id: subscription)
              subscriptions.destroy(subscription)
            end
          end

          define_method :subscribed? do |identifier|
            unless Subscription.valid_identifiers_for(self).include?(identifier.to_s)
              raise "Identifier is not valid for user: #{identifier}"
            end

            subscriptions.exists?(identifier:)
          end

          define_method :update_subscriptions do |params|
            invalid_subscriptions = params.keys - Subscription.valid_identifiers_for(self)
            if invalid_subscriptions.any?
              raise "Invalid subscription identifiers for this user: #{invalid_subscriptions.join(", ")}"
            end

            params.each do |identifier, active|
              if ActiveRecord::Type::Boolean.new.cast(active)
                subscribe(identifier)
              else
                unsubscribe(identifier)
              end
            end
          end
        end

        unless to_s == "Task" || schema_columns.key?(:tasks)
          has_many :tasks,
            as:        :taskable,
            dependent: :destroy
        end

        schema_columns.each do |attribute, options|
          column_type = options.fetch(:type)
          array       = options[:array] # Postgres only

          if column_type.in?(%i[string text]) && !array
            normalizes attribute,
              with: -> { _1.to_s.encode("UTF-8").strip.unicode_normalize.presence }
          end

          case
          when column_type == :string
            method_name = attribute.pluralize
            unless respond_to?(method_name, true)
              define_singleton_method method_name do
                pluck(Arel.sql("DISTINCT #{attribute}"))
                  .compact
                  .sort
              end
            end
          when column_type == :boolean
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
          when column_type.in?(%i[json jsonb])
            scope :"with_#{attribute}", ->(*values) {
              if values.empty?
                case connection.adapter_name
                when "PostgreSQL"
                  [[], {}].inject(self) {
                    _1.where("#{attribute} != '#{_2}'::#{column_type}")
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

    def method_missing(method, *args, **kwargs, &block)
      return super unless service_name = method[/\A_do_(.+)/, 1]

      service = resolve_service(service_name)

      if persisted?
        if service.enqueued_or_processing?(self)
          raise "#{service} is already in progress."
        end
        if service.scheduled_at(self)
          raise "#{service} is already scheduled."
        end
      end

      after, async = kwargs.delete(:_after), kwargs.delete(:_async)

      case
      when after
        service.call_in after, self, *args, **kwargs, &block
      when async
        service.call_async self, *args, **kwargs, &block
      else
        service.call self, *args, **kwargs, &block
      end
    end

    def last_changed_at(attribute)
      versions
        .where(self.class.object_changes_contain_key_where(attribute))
        .maximum(:created_at)
    end

    def last_changed_after?(attribute, datetime)
      last_changed_at(attribute)&.after?(datetime)
    end

    def human_enum_name(enum, modifier = nil)
      self.class.human_enum_name \
        enum,
        public_send(enum),
        modifier
    end

    def clone_of?(resource)
      return false unless resource.is_a?(self.class)

      self.class.clone_fields.all? do |field|
        [resource, self]
          .map { _1.public_send(field) }
          .map { _1.if(ActionText::RichText, &:to_s) }
          .uniq
          .size == 1
      end
    end

    def clone=(value)
      self.clone_id = value&.id
    end

    def clone_id=(value)
      @clone_id = value

      if clone == self
        raise "Cannot clone self."
      end

      self.class.clone_fields.each do |field|
        field
          .unless(Hash, { field => nil })
          .each do |_field, copy_or_clone|
            if self.class.reflect_on_association(_field) && !copy_or_clone
              raise "#{_field} is an association of #{self.class}, please set copy_or_clone."
            end

            value = clone.public_send(_field)

            if copy_or_clone
              case copy_or_clone
              when :copy
              when :clone
                value =
                  case value
                  when ActiveRecord::Relation then value.map(&:do_clone)
                  when ActiveRecord::Base     then value.do_clone
                  else raise "Unexpected value class: #{value.class}"
                  end
              else raise "Unexpected value for copy_or_clone: #{copy_or_clone}"
              end
            else
              case value
              when ActionText::RichText
                value = value.to_s
              when ActiveStorage::Attached::One
                next unless value.attached?
                _field = :"remote_#{_field}_url"
                value  = Rails.application.routes.url_helpers.rails_blob_url(value)
              end
            end

            public_send "#{_field}=", value
          end
        end
    end

    def clone
      @clone_id&.then {
        self.class.find _1
      }
    end

    def do_clone(attributes = {})
      if new_record?
        raise "Must be persisted to clone."
      end

      self.class.new \
        attributes.merge(clone_id: id)
    end

    def search_description = I18n.l(created_at)

    def avo_url
      suppress NoMethodError do
        ::Avo::Engine.routes.url_helpers.url_for([:resources, self])
      end
    end
  end
end

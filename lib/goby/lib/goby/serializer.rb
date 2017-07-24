module Goby
  class Serializer
    attr_reader :object, :context, :base_url

    def initialize(object, options = {})
      options = options.dup
      @object = object
      @context = options[:context]
      @base_url = options[:base_url] || ''

      @fields = (options[:fields] && options[:fields][_type]) ? options[:fields][_type] : available_fields

      # TODO: Recursive includes
      @includes = options[:include] || []

      @options = options
    end

    def _id
      object.id.to_s
    end

    def _type
      # de-demodulerize
      self.class._type || object.class.name.tableize
    end

    def _attributes
      self.class._attributes || {}
    end

    def _associations
      self.class._associations || {}
    end

    def self_link
      "#{base_url}/#{_type}/#{_id}"
    end

    # Override to further limit the available fields based on object and context
    def available_fields
      self.class.available_fields context, :serializing
    end

    # Override to further limit the available filters based on object and context
    def available_filters
      self.class.available_filters context
    end

    # Override to further limit the available sorts based on object and context
    def available_sorts
      self.class.available_sorts context
    end

    # Override to further limit the available includes based on object and context
    def available_includes
      self.class.available_includes context, :serializing
    end

    def relationship_related_link(association_name)
      "#{self_link}/#{association_name}"
    end

    def attributes
      return {} if @fields.empty?

      valid_fields = available_fields

      hash = {}

      _attributes.each do |name, options|
        key = options[:as] || name
        next unless @fields.include? key
        raise Goby::Exceptions::InvalidField.new(_type, key) unless valid_fields.include?(key)
        hash[key] = object_value(name, options)
      end

      hash
    end

    def links
      hash = {}

      hash[:self] = self_link if self_link

      hash
    end

    def relationships
      return {} if @includes.empty?

      hash = {}

      valid_includes = available_includes || []

      _associations.each do |name, options|
        key = options[:as] || name

        next unless @includes.include? key
        raise Goby::Exceptions::InvalidInclude.new(_type, key) unless valid_includes.include?(key)

        relationship = {}

        if options[:link]
          relationship[:links] = {}
          relationship[:links][:related] = relationship_related_link(name)
        end

        if options[:type] == :one
          related_object = object_value(name, options)

          if related_object.nil?
            relationship[:data] = nil
          else
            relationship[:data] = {}

            related_serializer = Goby::Serializer.find_serializer(related_object, @options)

            relationship[:data][:id] = related_serializer._id
            relationship[:data][:type] = related_serializer._type
          end
        else
          related_objects = object_value(name, options)

          relationship[:data] = []

          related_objects.each do |related_object|
            related_serializer = Goby::Serializer.find_serializer(related_object, @options)

            relationship[:data] << {
              id: related_serializer._id,
              type: related_serializer._type
            }
          end
        end

        hash[key] = relationship unless relationship.empty?
      end

      hash
    end

    def relationship(related_name, options)
      object_value(related_name, options)
    end

    private

    def object_value(attribute_name, _options)
      respond_to?(attribute_name) ? send(attribute_name) : object.send(attribute_name)
    end

    class << self
      attr_reader :_attributes, :_associations

      def _type
        @_type ||= name.sub('Serializer', '').tableize
      end

      def type(name)
        @_type = name
      end

      def _paging
        @_paging ||= :enabled
      end

      # :always = paging is always on and cannot be disabled with ?page=false
      # :enabled (default) = paging is on by default and can be turned off with ?page=false
      # :disabled = paging is off by default and can be enabled with ?page={number:x, size:y}
      # :never = paging is off and cannot be enabled with ?page={number:x, size:y}
      # TODO: Implement
      def paging(mode)
        @_paging = mode
      end

      # Override to customize the list of available attributes by context or controller action
      # Called by the request parser and during the serialization process
      def available_fields(_context, _scope)
        (_attributes || {}).select { |_attribute, options| options[:field] }.map { |attribute, options| options[:as] || attribute }
      end

      def available_filters(_context)
        (_attributes || {}).select { |_attribute, options| options[:filter] }.map { |attribute, options| options[:as] || attribute }
      end

      def available_sorts(_context)
        (_attributes || {}).select { |_attribute, options| options[:sort] }.map { |attribute, options| options[:as] || attribute }
      end

      def available_includes(_context, _scope)
        (_associations || {}).map { |association, options| options[:as] || association }
      end

      def attributes(*names)
        options = names.extract_options!
        names.each { |name| add_attribute(name, options) }
      end

      def fields(*names)
        options = names.extract_options!
        names.each { |name| add_attribute(name, options.merge(field: true, filter: false, sort: false)) }
      end

      def filters(*names)
        options = names.extract_options!
        names.each { |name| add_attribute(name, options.merge(field: false, filter: true, sort: false)) }
      end

      def sorts(*names)
        options = names.extract_options!
        names.each { |name| add_attribute(name, options.merge(field: false, filter: false, sort: true)) }
      end

      # Singular aliases for convenience
      alias attribute attributes
      alias field fields
      alias filter filters
      alias sort sorts

      def has_one(name, options = {})
        options[:type] = :one
        add_association(name, options)
      end

      def has_many(name, options = {})
        options[:type] = :many
        add_association(name, options)
      end

      def find_serializer_class_name(object)
        return object.serializer_class_name.to_s if object.respond_to?(:serializer_class_name)

        "#{object.class.name}Serializer"
      end

      def find_serializer_class(object)
        class_name = find_serializer_class_name(object)
        class_name.constantize
      end

      def find_serializer(object, options)
        find_serializer_class(object).new(object, options)
      end

      def serialize(objects, options)
        options = options.dup
        options[:collection] ||= objects.is_a? Enumerable
        options[:include] ||= []
        options[:fields] ||= {}

        serialize_options = {
          context: options[:context],
          serializer: options[:serializer],
          include: options[:include],
          fields: options[:fields],
          base_url: options[:base_url]
        }

        primary_data = if options[:collection] && (objects.nil? || !objects.present?)
                         []
                       elsif !options[:collection] && (objects.nil? || !objects.present?)
                         nil
                       elsif options[:collection]
                         serialize_collection objects, serialize_options
                       else
                         serialize_object objects, serialize_options
        end

        hash = {
          data: primary_data
        }

        hash[:links] = options[:links] if options[:links]
        hash[:meta] = options[:meta] if options[:meta]

        unless !objects.present? || options[:include].empty?
          included_data = {}
          objects = [objects].flatten

          serializer_class = find_serializer_class objects.first

          data_options = serialize_options.merge serializer: serializer_class

          objects.each do |object|
            included_data.merge! collect_included_data(object, data_options)
          end

          hash[:included] = included_data.map do |_key, association|
            serialize_object association, serialize_options.except(:include)
          end
        end

        hash
      end

      private

      # name: attribute name on object
      def add_attribute(name, options = {})
        options[:field] ||= options.fetch(:field, true)
        options[:filter] ||= options.fetch(:filter, true)
        options[:sort] ||= options.fetch(:sort, true)

        @_attributes ||= {}
        @_attributes[name.to_sym] = options
      end

      def add_association(name, options = {})
        options[:link] ||= options.fetch(:link, Goby.config.related_links)

        @_associations ||= {}
        @_associations[name] = options
      end

      def serialize_collection(objects, options = {})
        return [] if objects.nil? || !objects.present?

        objects.map { |object| serialize_object object, options }
      end

      def serialize_object(object, options = {})
        return if object.nil?

        serializer_class = options[:serializer] || find_serializer_class(object)

        serializer = serializer_class.new(object, options)

        hash = {}

        hash[:id] = serializer._id if serializer._id && !serializer._id.empty?
        hash[:type] = serializer._type

        attributes = serializer.attributes
        links = serializer.links
        relationships = serializer.relationships

        hash[:attributes] = attributes unless attributes.empty?
        hash[:links] = links unless links.empty?
        hash[:relationships] = relationships unless relationships.empty?

        hash
      end

      def collect_included_data(object, options)
        return if options[:include].empty?

        serializer_class = options[:serializer] || find_serializer_class(object)
        serializer = serializer_class.new(object, options)

        data = {}

        options[:include].each do |association_name|
          association_options = serializer_class._associations[association_name]

          associations = serializer.relationship(association_name, association_options)

          next if associations.nil?

          if association_options[:type] == :one
            data["#{association_name}.#{associations.id}".to_sym] = associations
          else
            associations.each { |association| data["#{association_name}.#{association.id}".to_sym] = association }
          end
        end

        data
      end
    end
  end
end

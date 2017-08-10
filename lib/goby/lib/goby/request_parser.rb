module Goby
  class RequestParser
    attr_reader :serializer, :fields, :included_resources, :filters, :sort_by, :pagination, :errors

    def initialize(model_class, context, params)
      @model_class = model_class
      @context = context

      type = model_class.name.tableize

      @serializer = serializer_for type

      @errors = []

      @errors.concat Goby::Exceptions::InvalidResource.new(type).errors if @serializer.nil?

      @fields = nil
      @included_resources = nil
      @filters = nil
      @sort_by = nil
      @pagination = nil

      parse_params params
    end

    def params
      hash = {}

      hash[:fields] = fields unless fields.nil?
      hash[:include] = included_resources unless included_resources.nil?
      hash[:filter] = filters unless filters.nil?
      hash[:sort] = sort_by unless sort_by.nil?
      hash[:page] = pagination unless pagination.nil?

      hash
    end

    private

    attr_reader :model_class, :context

    def parse_params(params)
      return if params[:action].nil?

      parse_method = "parse_#{params[:action]}_params".to_sym

      if respond_to? parse_method, true
        send parse_method, params
      end
    end

    def parse_index_params(params)
      parse_fields(params[:fields], :index)
      parse_included_resources(params[:include], :index)
      parse_filters(params[:filter])
      parse_sort_by(params[:sort])
      parse_pagination(params[:page])
    end

    def parse_show_params(params)
      parse_fields(params[:fields], :show)
      parse_included_resources(params[:include], :show)
    end

    def parse_create_params(params)
      parse_fields(params[:fields], :create)
      parse_included_resources(params[:include], :create)
    end

    def parse_update_params(params)
      parse_fields(params[:fields], :update)
      parse_included_resources(params[:include], :update)
    end

    def parse_destroy_params(_params)
      # noop
    end

    def parse_fields(fields, action)
      return if fields.nil?

      @fields = {}

      unless fields.is_a? ActionController::Parameters
        @errors.concat(Goby::Exceptions::InvalidFieldsFormat.new.errors)
        return
      end

      fields.each do |field, value|
        @fields[field] = value.blank? ? nil : value.split(',').map(&:strip).map(&:to_sym)
      end

      validate_fields(action)
    end

    def validate_fields(action)
      # Validate the fields
      @fields.each do |type, values|
        @fields[type] = []

        next @errors.concat Goby::Exceptions::InvalidField.new(type, 'nil').errors if values.nil?

        field_serializer = serializer_for type

        next @errors.concat Goby::Exceptions::InvalidResource.new(type).errors if field_serializer.nil?
        next @errors.concat Goby::Exceptions::InvalidResource.new(type).errors unless field_serializer.respond_to?(:available_fields)

        valid_fields = field_serializer.available_fields context, action

        values.each do |field|
          if valid_fields.include? field
            @fields[type].push field
          else
            @errors.concat Goby::Exceptions::InvalidField.new(type, field).errors
          end
        end
      end
    end

    def parse_included_resources(includes, action)
      return if includes.nil?
      return if serializer.nil?

      resources = includes.split(',').map(&:to_sym)
      return if resources.empty?

      @included_resources = []

      unless serializer.respond_to?(:available_includes)
        return @errors.concat Goby::Exceptions::InvalidResource.new(serializer._type).errors
      end

      valid_associations = serializer.available_includes context, action

      resources.each do |resource|
        if valid_associations.include? resource
          @included_resources.push resource
        else
          @errors.concat Goby::Exceptions::InvalidInclude.new(serializer._type, resource).errors
        end
      end
    end

    def parse_filters(filters)
      return if filters.nil?
      return if serializer.nil?

      unless filters.is_a?(Hash) || filters.is_a?(ActionController::Parameters)
        @errors.concat Goby::Exceptions::InvalidFiltersFormat.new(filters).errors
      end

      @filters = []

      unless serializer.respond_to?(:available_filters)
        return @errors.concat Goby::Exceptions::InvalidResource.new(serializer._type).errors
      end

      valid_filters = serializer.available_filters context

      filters.each_pair do |filter, value|
        if valid_filters.include? filter.to_sym
          @filters << [[filter.to_sym, value]].to_h
        else
          @errors.concat Goby::Exceptions::FilterNotAllowed.new(filter).errors
        end
      end
    end

    def parse_sort_by(sorts)
      return if sorts.nil?
      return if serializer.nil?

      unless serializer.respond_to?(:available_sorts)
        return @errors.concat Goby::Exceptions::InvalidResource.new(serializer._type).errors
      end

      valid_sorts = serializer.available_sorts context

      @sort_by = sorts.split(',').map do |sort|
        criteria = sort[0] == '-' ? [sort[1..-1], 'desc'] : [sort, 'asc']
        criteria.map!(&:to_sym)

        unless valid_sorts.include? criteria.first
          @errors.concat Goby::Exceptions::InvalidSortCriteria.new(serializer._type, sort).errors
        end

        [criteria].to_h
      end
    end

    def parse_pagination(paging)
      default_page_size = Goby.config.default_page_size
      max_page_size = Goby.config.max_page_size

      # Allow paging to be disabled
      # TODO: Allow the serializer to disallow disabling paging
      return if paging == false

      @pagination = {}

      if paging.nil?
        @pagination[:number] = 1
        @pagination[:size] = default_page_size
      else
        paging.permit(:number, :size)
        @pagination[:number] = [paging[:number].to_i, 1].max
        @pagination[:size] = (paging[:size] || default_page_size).to_i
      end

      unless max_page_size.zero? || (1..max_page_size).cover?(@pagination[:size])
        @errors.concat Goby::Exceptions::InvalidPageValue.new(:size, @pagination[:size]).errors
      end
    rescue ActionController::UnpermittedParameters => e
      @errors.concat Goby::Exceptions::InvalidPaginationParam.new(e.params).errors
    end

    def serializer_for(type)
      "#{type.singularize}_serializer".classify.safe_constantize
    end
  end
end

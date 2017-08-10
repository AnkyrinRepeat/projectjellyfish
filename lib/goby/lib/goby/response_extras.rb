module Goby
  class ResponseExtras
    attr_reader :fields, :include, :filter, :sort, :page

    def initialize(objects, options)
      @objects = objects
      @request = options[:request]
      @action = options[:action]
      @base_url = options[:base_url] || ''

      @fields = nil
      @includes = nil
      @filters = nil
      @sorts = nil
      @page = {}
      @meta = {}

      build_extras
    end

    def extras
      hash = {}

      hash[:links] = links unless links.empty?
      hash[:meta] = @meta unless @meta.empty?

      hash
    end

    def links
      @links ||= begin
        hash = {}

        hash[:self] = page_link(:self)
        hash[:first] = page_link(:first) if @page[:first]
        hash[:prev] = page_link(:prev) if @page[:prev]
        hash[:next] = page_link(:next) if @page[:next]
        hash[:last] = page_link(:last) if @page[:last]

        hash
      end
    end

    private

    attr_reader :objects, :request, :action, :base_url, :id

    def build_extras
      build_method = "build_#{action}_extras"

      if respond_to? build_method, true
        send build_method
      end
    end

    def build_index_extras
      unparse_fields
      unparse_includes
      unparse_filters
      unparse_sorts
      unparse_pagination
    end

    def build_show_extras
      unparse_fields
      unparse_includes
    end

    def build_create_extras
      unparse_fields
      unparse_includes
    end

    def build_update_extras
      unparse_fields
      unparse_includes
    end

    def build_destroy_extras
      # noop
    end

    def unparse_fields
      return unless request.fields

      @fields = request.fields.map do |type, fields|
        "fields[#{type}]=#{fields.join(',')}"
      end.join '&'

      @meta[:fields] = request.fields.each_with_object({}) { |e, k| k[e[0]] = e[1].join ',' }
    end

    def unparse_includes
      return unless request.included_resources

      @includes = 'include=' + request.included_resources.join(',')

      @meta[:include] = request.included_resources.join(',')
    end

    def unparse_filters
      return unless request.filters

      @filters = request.filters.map do |filter|
        field, value = filter.to_a.first
        "filter[#{field}]=#{value}"
      end.join '&'

      @meta[:filters] = request.filters.inject({}) { |a, e| a.merge(e) }
    end

    def unparse_sorts
      return unless request.sort_by

      @meta[:sort] = request.sort_by.map do |sort|
        field, direction = sort.to_a.first
        "#{direction == :desc ? '-' : ''}#{field}"
      end.join(',')

      @sorts = 'sort=' + @meta[:sort]
    end

    def unparse_pagination
      return unless request.pagination

      total_pages = (objects.total_count.to_f / request.pagination[:size]).ceil

      page = request.pagination

      # Include page[size]=x only when it differs from the default
      page_size = page[:size] != Goby.config.default_page_size ? "&page[size]=#{page[:size]}" : ''
      page_number = page[:number]

      @page[:self] = "page[number]=#{page_number}&page[size]=#{page[:size]}"
      if total_pages.positive?
        @page[:first] = "page[number]=1#{page_size}" unless page_number == 1
        @page[:prev] = "page[number]=#{page_number - 1}#{page_size}" if page_number > 1
        @page[:next] = "page[number]=#{page_number + 1}#{page_size}" if page_number < total_pages
        @page[:last] = "page[number]=#{total_pages}#{page_size}" unless page_number == total_pages
      end

      @meta[:page] = page
      @meta[:total_pages] = total_pages
      @meta[:total_results] = objects.total_count
    end

    def resource_id
      return nil unless objects.respond_to? :id

      objects.id.to_s
    end

    def page_link(page)
      url = base_url
      url += "/#{resource_id}" if resource_id

      query = [
        @fields,
        @filters,
        @includes,
        @page[page],
        @sorts
      ].compact.join('&')

      url += "?#{URI.escape query}" if query.present?

      url
    end
  end
end

module Goby
  class ResourceLinks
    attr_reader :fields, :include, :filter, :sort, :page

    def initialize(objects, options)
      @objects = objects
      @request = options[:request]
      @action = options[:action]
      @base_url = options[:base_url] || ''

      @fields = nil
      @include = nil
      @filter = nil
      @sort = nil
      @page = {}

      build_links
    end

    def links
      hash = {}

      hash[:self] = page_link(:self)
      hash[:first] = page_link(:first) if @page[:first]
      hash[:prev] = page_link(:prev) if @page[:prev]
      hash[:next] = page_link(:next) if @page[:next]
      hash[:last] = page_link(:last) if @page[:last]

      hash
    end

    private

    attr_reader :objects, :request, :action, :base_url, :id

    def build_links
      build_method = "build_#{action}_links"

      if respond_to? build_method, true
        send build_method
      end
    end

    def build_index_links
      unparse_fields
      unparse_includes
      unparse_filters
      unparse_sorts
      unparse_pagination
    end

    def build_show_links
      unparse_fields
      unparse_includes
    end

    def build_create_links
      unparse_fields
      unparse_includes
    end

    def build_update_links
      unparse_fields
      unparse_includes
    end

    def build_destroy_links
      # noop
    end

    def unparse_fields
      return unless request.fields

      @fields = request.fields.map do |type, fields|
        "fields[#{type}]=#{fields.join(',')}"
      end.join('&')
    end

    def unparse_includes
      return unless request.included_resources

      @includes = 'include=' + request.included_resources.join(',')
    end

    def unparse_filters
      return unless request.filters

      @filters = request.filters.map do |filter|
        field, value = filter.to_a.first
        "filter[#{field}]=#{value}"
      end.join '&'
    end

    def unparse_sorts
      return unless request.sort_by

      @sorts = 'sort=' + request.sort_by.map do |sort|
        field, direction = sort.to_a.first
        "#{direction == :desc ? '-' : ''}#{field}"
      end.join(',')
    end

    def unparse_pagination
      return unless request.pagination

      total_pages = (objects.total_count.to_f / request.pagination[:size]).ceil

      page = request.pagination

      # Include page[size]=x only when it differs from the default
      page_size = page[:size] != Goby.config.default_page_size ? "&page[size]=#{page[:size]}" : ''

      @page[:self] = "page[number]=#{page[:number]}&page[size]=#{page[:size]}"
      if total_pages > 0
        @page[:first] = "page[number]=1#{page_size}" unless page[:number] == 1
        @page[:prev] = "page[number]=#{page[:number] - 1}#{page_size}" if page[:number] > 1
        @page[:next] = "page[number]=#{page[:number] + 1}#{page_size}" if page[:number] < total_pages
        @page[:last] = "page[number]=#{total_pages}#{page_size}" unless page[:number] == total_pages
      end
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

      url += "?#{URI.escape query}" unless query.blank?

      url
    end
  end
end

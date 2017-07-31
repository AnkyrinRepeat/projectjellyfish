module Goby
  class Service
    module Model
      extend ActiveSupport::Concern

      attr_reader :model_id

      def model
        @model ||= model!
      end

      private

      def setup_params!
        @model_id = params[:id]
        @sort_by = params[:sort] || self.class.sort_columns
        @included = params[:include]
        @filters = params[:filter]
        @pagination = params[:page]
      end

      def model!
        send "#{model_action}_model!"
      rescue ActiveRecord::RecordNotFound
        raise Goby::Exceptions::RecordNotFound, model_id
      end

      def create_model!
        model_class.new
      end

      def find_model!
        query_with(model_class).find model_id
      end

      alias update_model! find_model!

      def collection_model!
        query_with model_class.all
      end

      def model_class
        self.class.model_class
      end

      def model_action
        self.class.model_action
      end

      def query_with(query)
        query = sort_query! query
        query = include_query! query
        query = filter_query! query
        query = paginate_query! query

        query
      end

      def sort_query!(query)
        return query unless @sort_by

        query.order @sort_by
      end

      def include_query!(query)
        return query unless @included

        # Skip trying to include any association that isn't on the model
        associations = model_class.reflect_on_all_associations.map(&:name)

        query.includes associations & @included
      end

      def filter_query!(query)
        return query unless @filters

        columns = model_class.column_names.map(&:to_sym)

        @filters.inject(query) do |q, filter|
          key, value = filter.each_pair.first
          if columns.include? key
            q.where filter
          elsif q.respond_to? key
            # TODO: Dangerous!
            # This is dangerous! If filters are ever passed in without
            # being vetted then the following and more is possible
            # q.public_send :destroy_all, '1=1'
            q.public_send key, value
          else
            # Silently fail through
            q
          end
        end
      end

      def paginate_query!(query)
        return query unless @pagination

        query.page(@pagination[:number]).per(@pagination[:size])
      end

      def sort_default
        self.class.sort_default
      end

      def include_relations
        self.class.include_relations
      end

      module ClassMethods
        attr_reader :model_class, :model_action, :sort_columns

        def model(model_class, model_action = :find)
          @model_class = model_class
          action(model_action) unless model_action.nil?
        end

        def action(model_action)
          @model_action = model_action
        end

        # Allow setting a default set of sorting
        # sort_by name: :desc, :updated_at
        def sort_by(*columns)
          @sort_columns = columns
        end
      end
    end
  end
end

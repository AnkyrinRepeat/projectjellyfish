module Goby
  class Service
    module Logging
      extend ActiveSupport::Concern

      included do
        cattr_accessor(:logger) { ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT)) }

        around_perform do |service, block, _|
          tag_logger(service.class.name) do
            payload = { service: service }
            ActiveSupport::Notifications.instrument('perform_start.goby_service', payload.dup)
            ActiveSupport::Notifications.instrument('perform.goby_service', payload) do
              block.call
            end
          end
        end
      end

      private

      def tag_logger(*tags)
        if logger.respond_to?(:tagged)
          tags.unshift 'Goby::Service' unless logger_tagged_by_goby_service?
          logger.tagged(*tags) { yield }
        else
          yield
        end
      end

      def logger_tagged_by_goby_service?
        logger.formatter.current_tags.include?('Goby::Service')
      end

      class LogSubscriber < ActiveSupport::LogSubscriber
        def perform_start(event)
          debug do
            service = event.payload[:service]
            "Performing #{service.class.name}"
          end
        end

        def perform(event)
          debug do
            service = event.payload[:service]
            "Performed #{service.class.name} in #{event.duration.round(2)}ms"
          end
        end

        private

        def logger
          Goby::Service.logger
        end
      end
    end
  end
end

Goby::Service::Logging::LogSubscriber.attach_to :goby_service

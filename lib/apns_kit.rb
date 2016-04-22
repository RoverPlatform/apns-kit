require "apns_kit/version"
require "apns_kit/certificate"
require "apns_kit/connection"
require "apns_kit/request"
require "apns_kit/response"
require "apns_kit/notification"
require "apns_kit/client"
require "logger"

module ApnsKit
    class << self

        PREFIX = "ApnsKit".freeze

        def logger
            return @logger if defined?(@logger)
            @logger = rails_logger || default_logger
        end

        def logger=(logger)
            @logger = logger
        end

        def log_debug(message)
            logger.debug(format_message(message)) if logger.debug?
        end

        def log_error(message)
            logger.error(format_message(message)) if logger.error?
        end

        def log_fatal(message)
            logger.fatal(format_message(message)) if logger.fatal?
        end

        def log_info(message)
            logger.info(format_message(message)) if logger.info?
        end

        def log_warn(message)
            logger.warn(format_message(message)) if logger.warn?
        end

        def default_logger
            logger = Logger.new($stdout)
            logger.level = Logger::INFO
            logger
        end

        def rails_logger
            defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
        end

        private

        def format_message(message)
            format("%s | %s".freeze, PREFIX, message)
        end

    end
end

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

        def logger
            return @logger if defined?(@logger)
            @logger = rails_logger || default_logger
        end

        def logger=(logger)
            @logger = logger
        end

        def default_logger
            logger = Logger.new($stdout)
            logger.level = Logger::INFO
            logger.formatter = proc do |severity, datetime, progname, msg|
                "[#{datetime} ##{$$}] #{severity} -- : APNs Kit | #{msg}\n"
            end
            logger
        end

        def rails_logger
            defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
        end

    end
end

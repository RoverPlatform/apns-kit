require 'uri'
require 'concurrent'

module ApnsKit

    APPLE_PRODUCTION_API_URI = URI.parse("https://api.push.apple.com:443").freeze
    APPLE_DEVELOPMENT_API_URI = URI.parse("https://api.development.push.apple.com:443").freeze

    class Client

        attr_reader :pool_size

        attr_reader :connection_pool

        attr_reader :default_topic

        class << self

            def production(certificate, pool_size: 1, heartbeat_interval: 60)
                client = self.new(APPLE_PRODUCTION_API_URI, certificate, pool_size: pool_size, heartbeat_interval: heartbeat_interval)
                client
            end

            def development(certificate, pool_size: 1, heartbeat_interval: 60)
                client = self.new(APPLE_DEVELOPMENT_API_URI, certificate, pool_size: pool_size, heartbeat_interval: heartbeat_interval)
            end

        end

        def initialize(uri, certificate, pool_size: 1, heartbeat_interval: 60)
            @pool_size = pool_size
            @connection_pool = @pool_size.times.map { ApnsKit::Connection.new(uri, certificate) }.freeze
            @default_topic = certificate.app_bundle_id
            if heartbeat_interval > 0
                ApnsKit.logger.info("Setting up heartbeat checker")
                @heartbeat_checker = Concurrent::TimerTask.new { @connection_pool.each(&:ping) }
                @heartbeat_checker.execution_interval = heartbeat_interval
                @heartbeat_checker.execute
            end
        end

        def shutdown
            @heartbeat_checker.shutdown if @heartbeat_checker
            @connection_pool.each(&:close)
            return true
        end

        def send_async(*notifications, &block)
            notifications.flatten!
            notifications.each { |notification| notification.topic = default_topic if notification.topic.nil? }
            request = ApnsKit::Request.new(notifications)

            if block
                Concurrent::Future.execute{ request.perform_nonblocking_send(connection_pool.sample, &block) }
            else
                Concurrent::Future.execute{ request.perform_nonblocking_send(connection_pool.sample) }
            end

            return true
        end

        def send(*notifications)
            return [] if notifications.empty?
            notifications.flatten!
            notifications.each { |notification| notification.topic = default_topic if notification.topic.nil? }
            request = ApnsKit::Request.new(notifications)
            return Concurrent::Future.execute{ request.perform_blocking_send(connection_pool.sample) }.value
        end

        def to_s
            "uri=#{connection_pool.first.uri} connected=#{connection_pool.map(&:connected)} pool_size=#{pool_size}"
        end

        def inspect
            "#<ApnsKit::Client:#{"0x00%x" % (object_id << 1)} #{to_s}>"
        end

    end
end

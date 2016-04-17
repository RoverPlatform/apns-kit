require 'concurrent'

module ApnsKit
    class Request


        def initialize(notifications)
            @notifications = notifications
        end

        def perform_blocking_send(connection)
            connection.open

            responses = Concurrent::Array.new
            latch = Concurrent::CountDownLatch.new(@notifications.size)

            perform_nonblocking_send(connection) do |response|
                responses.push(response)
                latch.count_down
            end

            latch.wait
            return responses
        end

        def perform_nonblocking_send(connection)
            connection.open

            ApnsKit.logger.info("Sending #{@notifications.size} notifications")
            @notifications.each do |notification|
                stream = connection.http.new_stream

                response = ApnsKit::Response.new
                response.notification = notification

                stream.on(:headers) do |headers|
                    headers = Hash[*headers.flatten]
                    response.headers = headers
                    ApnsKit.logger.debug("Received headers #{headers}")
                    if response.success?
                        yield response if block_given?
                    end
                end

                stream.on(:data) do |data|
                    response.raw_body ||= ""
                    response.raw_body << data
                    ApnsKit.logger.debug("Received data #{data}")
                    yield response if block_given?
                end

                stream.headers(notification.header, end_stream: false)
                stream.data(notification.payload)
            end

        end

    end
end

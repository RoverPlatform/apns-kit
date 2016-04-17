require 'json'

module ApnsKit
    class Response

        STATUS_CODES = {
            200 => "Success",
            400 => "Bad request",
            403 => "There was an error with the certificate",
            405 => "The request used a bad :method value. Only POST requests are supported",
            410 => "The device token is no longer active for the topic",
            413 => "The notification payload was too large",
            429 => "The server received too many requests for the same device token",
            500 => "Internal server error",
            503 => "The server is shutting down and unavailable",
        }.freeze

        INVALID_TOKEN_REASONS = Set.new(["Unregistered", "BadDeviceToken", "DeviceTokenNotForTopic"]).freeze

        attr_accessor :headers, :raw_body, :notification

        def id
            headers["apns-id"]
        end

        def status
            headers[":status"].to_i
        end

        def message
            STATUS_CODES[status]
        end

        def success?
            status == 200
        end

        def body
            @body ||= raw_body.nil? ? {} : JSON.load(raw_body)
        end

        def failure_reason
            body["reason"]
        end

        def invalid_token?
            !success? && INVALID_TOKEN_REASONS.include?(failure_reason)
        end

        def unregistered?
            !success? && failure_reason == "Unregistered"
        end

        def bad_device_token?
            !success? && failure_reason == "BadDeviceToken"
        end

        def device_token_not_for_topic?
            !success? && failure_reason == "DeviceTokenNotForTopic"
        end

        def to_s
            "#{status} (#{message}) notification=#{notification}"
        end

        def inspect
            "#<ApnsKit::Response:#{"0x00%x" % (object_id << 1)} #{to_s}>"
        end
    end
end

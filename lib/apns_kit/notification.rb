require 'json'

module ApnsKit
    class Notification

        MAXIMUM_PAYLOAD_SIZE = 4096

        attr_accessor :token

        attr_accessor :id

        attr_accessor :alert

        attr_accessor :topic

        attr_accessor :custom_data

        def initialize(options)
            @token = options.delete(:token) || options.delete(:device)
            @alert = options.delete(:alert)
            @badge = options.delete(:badge)
            @sound = options.delete(:sound)
            @category = options.delete(:category)
            @expiry = options.delete(:expiry)
            @id = options.delete(:id)
            @priority = options.delete(:priority)
            @content_available = options.delete(:content_available)
            @topic = options.delete(:topic)

            @custom_data = options
        end

        def id
            @id ||= SecureRandom.uuid.upcase
        end

        def valid?
            payload.bytesize <= MAXIMUM_PAYLOAD_SIZE
        end

        def header
            json = {
                ':scheme' => 'https',
                ':method' => 'POST',
                ':path' => "/3/device/#{token}",
                'apns-id' => id,
                'content-length' => payload.bytesize.to_s,
                'apns-topic' => topic
            }

            json.merge!({ "apns-expiry" => @expiry }) if @expiry
            json.merge!({ "apns-priority" => @priority }) if @priority
            return json
        end

        def payload
            json = {}.merge(@custom_data || {}).inject({}){|h,(k,v)| h[k.to_s] = v; h}

            json['aps'] ||= {}
            json['aps']['alert'] = @alert if @alert
            json['aps']['badge'] = @badge.to_i rescue 0 if @badge
            json['aps']['sound'] = @sound if @sound
            json['aps']['category'] = @category if @category
            json['aps']['content-available'] = 1 if @content_available

            JSON.dump(json)
        end
    end
end

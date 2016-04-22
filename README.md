# ApnsKit

**NOTE!** this gem is currently under development and no tests have been written yet.

A simple to use gem that interfaces with Apple's new HTTP/2 APNs Service

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'apns_kit', '~> 0.1.1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apns_kit

## Usage

```ruby
require 'apns_kit'

certificate = ApnsKit::Certificate.new(File.read("path_to_certificate.pem"), "password_or_nil")

# create a production client (you can also call ApnsKit::Client.development with the same options)
# pool_size is the number of open connections defaults to 1 (advisable to keep the default value)
# heartbeat_interval sends a ping to APNs servers to check if the connection is still alive defaults to 60 seconds
client = ApnsKit::Client.production(certificate, pool_size: 1, heartbeat_interval: 30)

# Build the notification 
notification = ApnsKit::Notification.new (
    token: "a1ee474316e40f6cfb028c6c508dd0c4e49a2855e55765586789896d0fd03e22",
    alert: "Hello!",
    badge: 1,
    sound: "mysound.caf",
    content_available: true,
    data: { event_id: 1 } # data can be named to anything. Supports multiple custom keys as well  
)
```
### Blocking send
This will block the calling thread until all notifications have been sent and we get a response for all
```ruby
# Can send an individual notifications or an array of them
responses = client.send(notification)
# [#<ApnsKit::Response:0x007fc0bc065520 200 (Success) notification=#<ApnsKit::Notification:0x007fc0bc0b68d0>>] 
```
### Non Blocking send
This will not block the calling thread but instead use a callback for individual responses
```ruby
client.send_async(notification) do |response|
    if response.success?
        puts "Awesome!"
    else
        puts "Failed: #{response.message} reason: #{response.reason}
    end
end
```

### Fire and forget
You can also skip passing the block
```ruby
client.send_async(notification)
```

### Client considerations
If you do not provide a topic for a notification the client will use the app bundle id in your certificate as the topic.

Do not setup and forget about clients. If you are using short term connections you need to call `client.shutdown` to terminate the connection and the threads that it creates. If however you are using the client as a long running connection you can leave them open. If for some reason the connection is dropped the client will reinitiate the connection on your behalf.

## Logger
ApnsKit will use the Rails logger if its present. If not it creates its own logger to `STDOUT`. You can change and modify the logger however you like
```ruby
new_logger = Logger.new("some_path.log")
ApnsKit.logger = new_logger
```

# Classes
### ApnsKit::Response
```ruby
# response = <ApnsKit::Response:0x007fc0bc065520 200 (Success) notification=#<ApnsKit::Notification:0x007fc0bc0b68d0>>
response.id                         # returns the id of the notification
response.status                     # returns the http status
response.message                    # converts the status to a meaningful message
response.success?                   # convenience method checking if the status was 200
response.body                       # the json body of the response
response.failure_reason             # convenience method to pull out the failure reason from the body
response.invalid_token?             # returns true if the token was invalid
response.unregistered?              # returns true if the token wasn't registered
response.bad_device_token?          # returns true if the token wasn't properly formatted
response.device_token_not_for_topic? # The device token does not match the specified topic
response.notification               # the ApnsKit::Notification for this response
```

### ApnsKit::Notification
```ruby
notification = ApnsKit::Notification.new (
    token: "a1ee474316e40f6cfb028c6c508dd0c4e49a2855e55765586789896d0fd03e22",
    alert: "Hello!",
    badge: 1,
    sound: "",
    category: "",
    expiry:  1460992609 # A UNIX epoch date expressed in seconds (UTC),
    priority: 5,
    content_available: true,
    data: { event_id: 1 } # data can be named to anything. Supports multiple custom keys as well  
)
```
### ApnsKit::Certificate
```ruby
certificate = ApnsKit::Certificate.new(File.read("path_to_certificate.pem"), "password_or_nil")

certificate.production?     # returns true if the certificate can be used to connect to APNs production environment
certificate.development?    # returns true if the certificate can be used to connect to APNs development environment
certificate.universal?      # returns true if the certificate can be used to connect to APNs production and development environment
certificate.app_bundle_id   # the app bundle id this certificate was issued for
```
## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

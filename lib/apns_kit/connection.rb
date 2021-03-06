require 'socket'
require 'openssl'
require 'http/2'
require 'thread'
require 'uri'

module ApnsKit
    class Connection

        attr_reader :connected

        attr_reader :uri

        attr_reader :http

        def initialize(uri, certificate)
            @uri = uri
            @certificate = certificate
            @connected = false
            @mutex = Mutex.new
        end

        def open
            if !connected && (@thread.nil? || @thread.stop?)
                start
            end
        end

        def close
            shutdown if !@thread.nil?
        end

        def ping
            if @http
                ApnsKit.log_debug("Sending ping")
                @http.ping("whatever")
            end
        end

        private

        def setup_connection!
            @mutex.synchronize do
                ApnsKit.log_info("Setting up connection")
                ctx = @certificate.ssl_context
                tcp = TCPSocket.new(@uri.host, @uri.port)

                @socket = OpenSSL::SSL::SSLSocket.new(tcp, ctx)

                @socket.sync_close = true
                @socket.hostname = @uri.hostname
                @socket.connect

                @connected = true

                @http = HTTP2::Client.new
                @http.on(:frame) do |bytes|
                    ApnsKit.log_debug("Sending bytes: #{bytes.unpack("H*").first}")
                    @socket.print bytes
                    @socket.flush
                end

                ping
                ApnsKit.log_info("Connection established")
            end
        end

        def start
            setup_connection!
            @thread = Thread.new {
                loop do
                    begin
                        if @socket.closed?
                            close_connection!
                            ApnsKit.log_warn("Socket was closed")
                            break
                        elsif !@socket.eof?
                            data = @socket.readpartial(1024)
                            ApnsKit.log_debug("Received bytes: #{data.unpack("H*").first}")
                            @http << data
                        end
                    rescue => e
                        close_connection!
                        ApnsKit.log_warn("#{e.class} exception: #{e.message} - closing socket")
                        e.backtrace.each { |l| ApnsKit.log_debug(l) }
                        raise e
                    end
                end
            }
            return true
        end

        def shutdown
            @thread.exit
            @thread.join
            close_connection!
        end

        def close_connection!
            @mutex.synchronize do
                ApnsKit.log_info("Closing connection")
                @socket.close if @socket
                @connected = false
                @http = nil
                ApnsKit.log_info("Connection closed")
            end
        end

    end
end

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
                ApnsKit.logger.debug("Sending ping")
                @http.ping("whatever")
            end
        end

        private

        def setup_connection!
            ApnsKit.logger.info("Setting up connection")
            ctx = @certificate.ssl_context
            tcp = TCPSocket.new(@uri.host, @uri.port)

            @socket = OpenSSL::SSL::SSLSocket.new(tcp, ctx)

            @socket.sync_close = true
            @socket.hostname = @uri.hostname
            @socket.connect

            @connected = true

            @http = HTTP2::Client.new
            @http.on(:frame) do |bytes|
                ApnsKit.logger.debug("Sending bytes: #{bytes.unpack("H*").first}")
                @socket.print bytes
                @socket.flush
            end

            ping
            ApnsKit.logger.info("Connection established")
        end

        def start
            setup_connection!
            @thread = Thread.new {
                loop do
                    if @socket.closed?
                        @connected = false
                        ApnsKit.logger.warn("Socket was closed")
                        break
                    elsif !@socket.eof?
                        data = @socket.readpartial(1024)
                        ApnsKit.logger.debug("Received bytes: #{data.unpack("H*").first}")

                        begin
                            @http << data
                        rescue => e
                            @connected = false
                            @http = nil
                            ApnsKit.logger.warn("#{e.class} exception: #{e.message} - closing socket")
                            e.backtrace.each { |l| ApnsKit.logger.debug(l) }
                            @socket.close
                            raise e
                        end
                    end
                end
            }
            return true
        end

        def shutdown
            ApnsKit.logger.info("Closing connection")
            @thread.exit
            @thread.join
            @socket.close
            @connected = false
            @http = nil
            ApnsKit.logger.info("Connection closed")
        end


    end
end

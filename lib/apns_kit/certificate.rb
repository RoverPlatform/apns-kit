module ApnsKit
    class Certificate

        def initialize(cert_data, passphrase = nil)
            @key = OpenSSL::PKey::RSA.new(cert_data, passphrase)
            @certificate = OpenSSL::X509::Certificate.new(cert_data)
        end

        def ssl_context
            @ssl_context ||= OpenSSL::SSL::SSLContext.new.tap do |context|
                context.key = @key
                context.cert = @certificate
            end
        end

        def production?
            extension(PRODUCTION_ENV_EXTENSION).present?
        end

        def development?
            extension(DEVELOPMENT_ENV_EXTENSION).present?
        end

        def universal?
            extension(UNIVERSAL_CERTIFICATE_EXTENSION).present?
        end

        def app_bundle_id
            @app_bundle_id ||= @certificate.subject.to_a.find { |key, *_| key == "UID" }[1]
        end

    end
end

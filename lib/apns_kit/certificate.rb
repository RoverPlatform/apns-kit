module ApnsKit
    class Certificate

        class << self

            def from_p12_file(data, passphrase = nil)
                p12 = OpenSSL::PKCS12.new(data, passphrase)
                ApnsKit::Certificate.new(p12.key, p12.certificate)
            end

            def from_pem_file(data, passphrase = nil)
                key = OpenSSL::PKey::RSA.new(data, passphrase)
                certificate = OpenSSL::X509::Certificate.new(data)
                ApnsKit::Certificate.new(key, certificate)
            end

        end

        def initialize(key, certificate)
            @key = key
            @certificate = certificate
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

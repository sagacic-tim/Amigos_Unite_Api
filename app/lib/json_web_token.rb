# app/lib/json_web_token.rb
module JsonWebToken
    class << self
        def encode(payload, exp = 24.hours.from_now)
            payload[:exp] = exp.to_i
            JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
        end

        def decode(token)
            body = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key)[0]
            HashWithIndifferentAccess.new(body)
        rescue JWT::ExpiredSignature
            # Handle the case where the token is expired
            { error: 'Token has expired' }
        rescue JWT::VerificationError
            # Handle the case where the token is invalid
            { error: 'Token is invalid' }
        end
    end
end
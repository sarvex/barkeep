require "faraday"
require "json"

OAUTH_ENDPOINT = "https://accounts.google.com/o/oauth2/auth"
TOKEN_ENDPOINT = "https://www.googleapis.com/oauth2/v3/token"
IDENTITY_ENDPOINT = "https://www.googleapis.com/oauth2/v2/userinfo"

credentials_filename = File.expand_path(File.join(File.dirname(__FILE__),
                                                  "../../config/google-oauth2-credentials.json"))
CREDENTIALS = (File.exist?(credentials_filename) ? JSON.parse(File.read(credentials_filename)) : nil)

module GoogleOAuth2
  def self.validate_configuration
    if CREDENTIALS.nil?
      raise "No credentials file found"
    elsif CREDENTIALS["web"]["redirect_uris"].size == 0
      raise "No redirect uri configured"
    end
  end

  def self.generate_oauth_url
    validate_configuration()

    params = {
      :response_type => "code",
      :client_id => CREDENTIALS["web"]["client_id"],
      :redirect_uri => CREDENTIALS["web"]["redirect_uris"].first,
      :scope => "email"
    }

    OAUTH_ENDPOINT + "?" + params.map { |k, v| "#{k}=#{v}" }.join("&")
  end

  def self.fetch_email(authorization_code)
    validate_configuration()

    token_response = Faraday.post(TOKEN_ENDPOINT, {
      :code => authorization_code,
      :client_id => CREDENTIALS["web"]["client_id"],
      :client_secret => CREDENTIALS["web"]["client_secret"],
      :redirect_uri => CREDENTIALS["web"]["redirect_uris"].first,
      :grant_type => "authorization_code"
    })
    tokens = JSON.parse(token_response.body)

    identity_response = Faraday.get(IDENTITY_ENDPOINT, { :access_token => tokens["access_token"] })
    userinfo = JSON.parse(identity_response.body)

    userinfo["email"]
  end
end

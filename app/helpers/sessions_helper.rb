module SessionsHelper

  def client
    @client ||= OpenIDConnect::Client.new(
      identifier: ENV['PP_CLIENT_ID'],
      secret: ENV['PP_CLIENT_SECRET'],
      redirect_uri: ENV['PP_REDIRECT_URI'],
      host: ENV['PP_OIDC_HOST'],
      authorization_endpoint: 'http://dev.presspass.com/openid/authorize',
      token_endpoint: 'http://dev.presspass.com/openid/token',
      userinfo_endpoint: 'http://dev.presspass.com/openid/userinfo'
    )
  end

  def authorization_uri
    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    client.authorization_uri(
      scope: scope,
      state: session[:state],
      nonce: session[:nonce]
    )
  end

  def scope
    default_scope = %w(profile name)

    # Add scope for social provider if social login is requested
    if params[:provider].present?
      default_scope << params[:provider]
    else
      default_scope
    end
  end

  def log_in(access_token)
    puts "ACCESS_TOKEN: #{access_token}"
    session[:access_token] = access_token
  end

  def log_out
    session.delete(:access_token)
    @current_user = nil
  end

  def user_info
    return nil unless session[:access_token].present?

    access_token = OpenIDConnect::AccessToken.new(
      access_token: session[:access_token],
      client: client
    )

    access_token.userinfo!
  end

  def current_user
    @current_user ||= user_info
  end
end

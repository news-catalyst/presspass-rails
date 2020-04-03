class SessionsController < ApplicationController
  # this maps to `/presspass/login` and should be the URL specified in PressPass as the client login URL
  def new
    # TODO: get the api hosted on https and remove this bit of hacky code:
    secure_auth_uri = authorization_uri
    unsecure_auth_uri = authorization_uri.gsub("https", "http")
    redirect_to unsecure_auth_uri
  end

  # this maps to `/presspass/callback` and should be specified in PressPass as the redirect URI
  def callback
    # Authorization Response
    code = params[:code]

    # Token Request
    client.authorization_code = code
    access_token = client.access_token! # => OpenIDConnect::AccessToken

    if access_token
      log_in(access_token.to_s)
      redirect_to '/dashboard'
    else
      redirect_to root_url
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end
end

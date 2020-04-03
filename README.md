# PressPass for Ruby on Rails

You can add PressPass auth to your Rails application by following this guide. PressPass provides OIDC (OpenID Connect) authentication. For more info on OIDC, check out [https://openid.net/connect/](https://openid.net/connect/).

## Setup

While you're welcome to use your solution of choice, we'll be using the [openid-connect] rubygem in this guide.

```Gemfile
gem 'openid-connect'
```

```
bundle install
```

You'll need to set the following environment variables:

```
# PP_CLIENT_ID is the unique identifier of your client app defined in PressPass and can be found by logging into presspass and viewing the client details
PP_CLIENT_ID=123456

# PP_CLIENT_SECRET may be blank, but if your client requires this value you can find it by logging into presspass and viewing the client details
PP_CLIENT_SECRET=123456789012345

# PP_REDIRECT_URI refers to a route in your rails application; in our guide we map it in `config.routes.rb` to `/presspass/callback`
PP_REDIRECT_URI=http://localhost:3000/presspass/callback

# PP_OIDC_HOST is the full hostname of presspass
PP_OIDC_HOST=dev.presspass.com
```

We'll keep our example Rails app very simple for purposes of clarity here - your Rails app will no doubt have a lot more going on. We'll have one route that is protected - `/dashboard` - and the rest will handle OIDC integration.

Create a sessions controller and helper (or add to your existing files):

```sessions_controller.rb
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
```

```sessions_helper.rb
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
```

Edit your routes to support the login, logout and callback/redirect URIs:

```config/routes.rb
  get 'presspass/login', to: 'sessions#new', as: 'new_session'
  get 'presspass/callback', to: 'sessions#callback', as: 'session_callback'
  get 'presspass/logout', to: 'sessions#destroy', as: 'destroy_session'

  get 'dashboard', to: 'dashboard#index'
```

Create a dashboard controller that requires user authentication; we use this in our example Rails app to verify authentication is working.

```dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :require_current_user

  def index
  end
end
```

And finally, setup a basic view for the `/dashboard` route:

```/app/views/dashboard/index.html.erb
<h1>Dashboard</h1>
<p>
  You must be authenticated to see this page so if you're seeing it then
  everything worked as expected 🎉
</p>
<h2>Current User</h2>
<pre><%= current_user.inspect %></pre>
```

Ensure you've `export`ed the environment variables. Start up your Rails application.

```
rails server
```

Now, navigate to your client in PressPass. Make sure you enter the following URLs exactly as you've defined them as routes in your Rails application:

- Redirect URIs: `http://dev.presspass.com:3000/presspass/callback`
- Login URL: `http://dev.presspass.com:3000/presspass/login`

## How this all works

There are two, potentially three, steps to OIDC auth:

1. Login: in our rails app, all the login route does is redirect to the configured OIDC provider's (PressPass) authorization endpoint
2. Callback: once PressPass is authorized, this is where we redirect people back to your app. An access token is requested, and the person is authenticated.
3. (optional) User Info: call this PressPass endpoint to request basic data on the user.

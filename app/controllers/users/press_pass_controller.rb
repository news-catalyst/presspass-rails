require Rails.root.join('lib', 'pp_oidc')
class Users::PressPassController < ApplicationController
  def login
    pp_worker = PressPassOIDC::Worker.new("http://dev.presspass.com/openid", "989522", "", "http://dev.presspass.com:3000/users/redirect")
    @nonce = generate_nonce
    session[:nonce] = @nonce

    @auth_uri = pp_worker.auth_uri(@nonce)
    Rails.logger.info "redirecting to auth uri: #{@auth_uri}"
    redirect_to @auth_uri
  end

  def redirect
  end

private
  def generate_nonce
    rand(10 ** 30).to_s.rjust(30,'0')
  end

end

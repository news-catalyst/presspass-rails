Rails.application.routes.draw do
  # login url for presspass
  get 'presspass/login', to: 'sessions#new', as: 'new_session'
  # redirect uri for presspass
  get 'presspass/callback', to: 'sessions#callback', as: 'session_callback'
  get 'presspass/logout', to: 'sessions#destroy', as: 'destroy_session'

  get 'dashboard', to: 'dashboard#index'

  root 'dashboard#index'
end

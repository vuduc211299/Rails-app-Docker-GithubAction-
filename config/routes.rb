Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  devise_scope :user do
    unauthenticated :user do
      root to: 'devise/sessions#new'
    end
  end

  authenticated :user do
    root 'images#index', as: :authenticated_root
    resources :images
  end

  get '*path', to: 'application#not_found'
end

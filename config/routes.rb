Rails.application.routes.draw do
  devise_for :users,
    skip: [:registrations, :passwords, :sessions],
    controllers: {
      omniauth_callbacks: 'users/omniauth_callbacks'
    }

  devise_scope :user do
    get 'sign_in', to: 'devise/sessions#new', as: :new_user_session
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  authenticated :user do
    root "universes#index", as: :authenticated_root

    resources :universes do
      member do
        post :regenerate
      end

      resources :chapters do
        resources :scenes do
          resources :beats
        end
      end

      resources :characters
      resources :locations
    end

    # Keep stories for backward compatibility if needed
    resources :stories do
      member do
        post :regenerate
      end
    end
  end

  root "home#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end

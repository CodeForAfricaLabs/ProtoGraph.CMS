Rails.application.routes.draw do

  resources :datacast_accounts
  resources :datacasts
  devise_for :users, controllers: { registrations: 'registrations' } do
      #get 'sign_in', to: 'devise/sessions#new'
      get 'sign_out', to: 'devise/sessions#destroy'
  end

  get "/auth/:provider", to: lambda{ |env| [404, {}, ["Not Found"]] }, as: :oauth
  get '/auth/:provider/callback', to: 'authentications#create'
  get '/auth/failure', to: 'authentications#failure'

  resources :accounts do
    resources :permissions
    resources :permission_invites
    get '/authentications', to: 'authentications#index', as: 'authentication'
    resources :services_attachables, only: [:destroy]
    resources :template_streams do
        get 'flip_public_private', on: :member
        resources :template_stream_cards
    end
    resources :template_data do
      get 'flip_public_private', on: :member
      resources :template_cards, only: [:new]
    end
    resources :template_cards do
      get 'flip_public_private', on: :member
    end
  end

  root 'static_pages#index'

        # resources :thrreads do
        #   resources :thrread_files, only: [:update]
        # end
        # resources :cards do
        #   resources :card_files, only: [:update]
        # end
        # resources :assets do
        #   resources :asset_files, only: [:update]
        # end

end

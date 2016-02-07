Fsek::Application.routes.draw do

  get :cookies_information, controller: :static_pages, as: :cookies, path: :cookies
  get :about, controller: :static_pages, path: :om

  # User-related routes
  devise_for :users, skip: [:sessions, :registrations], controllers: {registrations: "registrations"}
  devise_scope :user do
    get 'avbryt_reg' => 'registrations#cancel', as: :cancel_user_registration
    post 'anvandare/skapa' => 'registrations#create', as: :user_registration
    get 'anvandare/registrera' => 'registrations#new', as: :new_user_registration
    # delete 'anvandare/ta_bort/:id' => 'users#destroy', :as => :admin_destroy_user

    #sessions
    get 'logga_in' => 'devise/sessions#new', as: :new_user_session
    post 'logga_in' => 'devise/sessions#create', as: :user_session
    delete 'logga_ut' => 'devise/sessions#destroy', as: :destroy_user_session
  end

  # Scope to change urls to swedish
  scope path_names: {new: 'ny', edit: 'redigera'} do
    namespace :admin do
      resources :users, path: :anvandare, only: [:index]
    end

    resource :user, path: :anvandare, as: :own_user, only: [:update] do
      get '', action: :edit, as: :edit
      patch :password, path: :losenord, action: :update_password
      patch :account, path: :konto, action: :update_account
    end

    resources :users, path: :anvandare, only: [:show] do
      get :avatar, on: :member
    end

    resources :constants


    resources :votes, path: :voteringar, only: :index do
      resources :vote_posts, only: [:new, :create]
    end

    namespace :admin do
      resources :votes, path: :voteringar, controller: :votes do
        get 'change_state', on: :member
      end
      resources :vote_users, path: :motesanvandare, controller: :vote_users do
        get 'change_state', on: :member
        get 'make_all_not_present', on: :collection
      end
    end

    resources :notices, path: :notiser do
      post :display, path: :visa, on: :member
      get :image, path: :bild, on: :member
    end

    resources :menus, path: :meny, except: :show

    resources :faqs, path: :faq

    resources :contacts, path: :kontakt do
      post :mail, on: :member
    end

    namespace :admin do
      resources :news, path: :nyheter
    end

    resources :news, path: :nyheter, only: [:index, :show]

    resources :documents, path: :dokument, only: [:index, :show]

    namespace :admin do
      resources :documents, path: :dokument, except: :show
    end

    namespace :admin do
      resources :permissions, only: [] do
        get '/:post_id', action: :show_post, on: :collection, as: :post
        patch '(/:post_id)', action: :update_post, on: :collection, as: :update
        get '', action: :index, on: :collection, as: :index
      end
    end
  end

  root 'static_pages#index'
end
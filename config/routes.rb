Rails.application.routes.draw do
  # Root
  root "dashboard#index"

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  match "logout", to: "sessions#destroy", via: [:get, :delete]

  # Dashboard
  get "dashboard", to: "dashboard#home"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Reports & Teacher Feedback
  resources :reports, only: [:show]
  resources :submissions, only: [] do
    resource :teacher_feedback, only: [:show, :update]
  end

  # Admin namespace
  namespace :admin do
    root "dashboard#index"
    resources :passages do
      resources :items, except: [:index]
    end
    resources :items, only: [:index]
    resources :assessment_versions do
      member do
        post :publish
      end
    end
    resources :book_catalogs
    resources :users
  end

  # School Manager namespace
  namespace :school_manager do
    root "dashboard#index"
    resources :students do
      collection do
        get :import
        post :import, action: :create_import
      end
    end
    resources :classes, controller: "school_classes"
    resources :reports, only: [:index, :show]
  end

  # Teacher namespace
  namespace :teacher do
    root "dashboard#index"
    resources :sessions do
      member do
        post :distribute
        get :progress
      end
    end
    resources :submissions, only: [:index, :show] do
      resource :feedback, controller: "feedbacks", only: [:show, :update] do
        member do
          post :approve
          post :regenerate_section
        end
      end
    end
    resources :feedbacks, only: [:index]
    resources :reports, only: [:index, :show] do
      member do
        post :generate
        get :preview
        get :download
        post :share
      end
    end
  end

  # Student namespace
  namespace :student do
    root "dashboard#index"
    resources :assessments, only: [:index, :show] do
      member do
        get :take
        post :submit
        patch :save_progress
      end
    end
    resources :reports, only: [:index, :show]
  end

  # Parent namespace
  namespace :parent do
    root "dashboard#index"
    resources :reports, only: [:index, :show]
  end

  # API namespace
  namespace :api do
    namespace :v1 do
      resources :schools, only: [:index, :show]
      resources :classes, controller: "school_classes", only: [:index, :show]
      resources :items, only: [:index, :show]
      resources :sessions, only: [:index, :show]
      resources :submissions, only: [:show]
      resources :reports, only: [:show]
    end
  end
end

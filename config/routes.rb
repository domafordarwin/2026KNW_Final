Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :reports, only: [:show]
  resources :submissions, only: [] do
    resource :teacher_feedback, only: [:show, :update]
  end

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

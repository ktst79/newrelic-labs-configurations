Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :settings

  namespace :api, { format: 'json' } do
    resources :settings, only: [:index]
  end  
end

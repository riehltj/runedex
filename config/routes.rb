Rails.application.routes.draw do
  resources :rune_arts, path: "arts"
  get "up" => "rails/health#show", as: :rails_health_check
  root "rune_arts#index"
end

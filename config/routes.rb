Rails.application.routes.draw do
  resources :rune_arts, path: "arts" do
    post :refresh_prices, on: :collection
    patch :collect, on: :member
  end
  get "up" => "rails/health#show", as: :rails_health_check
  root "rune_arts#index"
end

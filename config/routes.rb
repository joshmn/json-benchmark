Rails.application.routes.draw do
  root to: 'homes#index'
  resources :homes, only: [:index]
end

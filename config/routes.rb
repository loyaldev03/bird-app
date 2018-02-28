Rails.application.routes.draw do

  devise_for :users#, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  
  root "home#index"

  get 'about', to: 'home#about'

  resources :contacts, only: [:index, :create]
  resources :slider_images
end

Rails.application.routes.draw do
  root "articles#index"

  resources :articles do
    resources :comments, only: [:new, :create, :edit, :update, :destroy]
  end
end

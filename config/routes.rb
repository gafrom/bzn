Rails.application.routes.draw do
  root 'welcome#home'

  devise_for :users

  namespace :admin, path: 'fiddle' do
    root 'dashboard#home'

    resources :products, only: [:index, :show, :edit, :update]
  end

  get 'export/mapping', to: 'export#mapping', as: :export_mapping
  get 'export/catalog(/:file_suffix)', to: 'export#catalog', as: :export_catalog
end

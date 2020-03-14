require 'sidekiq/web'

Rails.application.routes.draw do
  root 'welcome#home'

  devise_for :users

  namespace :admin, path: 'fiddle' do
    root 'dashboard#home'
    authenticate :user do
      mount Sidekiq::Web => '/jobs'
    end

    resources :products, only: [:index, :show, :edit, :update]

    get 'export/catalog(/:file_suffix)', to: 'export#catalog', as: :export_catalog

    resources :report_tasks, only: :create do
      member { get :enqueue }
    end

    get 'wide-syncs', to: 'wide_sync_jobs#index', as: :wide_syncs
    get 'narrow-syncs', to: 'narrow_sync_jobs#index', as: :narrow_syncs
  end
end

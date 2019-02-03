Rails.application.routes.draw do
  root 'welcome#home'

  devise_for :users

  namespace :admin, path: 'fiddle' do
    root 'dashboard#home'

    resources :products, only: [:index, :show, :edit, :update]

    get 'export/catalog(/:file_suffix)', to: 'export#catalog', as: :export_catalog

    post '/reports', to: 'reports#create', as: :daily_report_tasks

    resources :daily_report_tasks, only: [] do
      member { get :enqueue }
    end
  end
end

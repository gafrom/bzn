Rails.application.routes.draw do
  get :fiddle, to: 'welcome#home'

  get 'export/mapping', to: 'export#mapping', as: :export_mapping
  get 'export/catalog(/:file_suffix)', to: 'export#catalog', as: :export_catalog
end

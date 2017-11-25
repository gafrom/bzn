Rails.application.routes.draw do
  get :fiddle, to: 'welcome#home'

  get 'export/mapping', to: 'export#mapping', as: :export_mapping
  get 'export/catalog/:batch_index', to: 'export#catalog', as: :export_catalog
end

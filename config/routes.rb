Rails.application.routes.draw do
  get 'welcome/home'

  get :fiddle, to: 'welcome#home'
end

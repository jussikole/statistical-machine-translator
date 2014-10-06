Translator::Application.routes.draw do
  get 'translate', to: 'json#translate'

  root to: 'home#index'
end

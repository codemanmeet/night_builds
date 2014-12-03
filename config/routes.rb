NightBuilds::application.routes.draw do
  root :to => 'home#index'
  post '/hook', to: 'home#hook'
end

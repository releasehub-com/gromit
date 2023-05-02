Vapey::Rails::Engine.routes.draw do
  post '/search', to: 'vapey#search'
  post '/upsert', to: 'vapey#upsert'
end

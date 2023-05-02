Vapey::Rails::Engine.routes.draw do

  scope '/', defaults: { format: :json } do
    get '/healthcheck', to: 'vapey#healthcheck'
    post '/search', to: 'vapey#search'
    post '/upsert', to: 'vapey#upsert'
  end
end

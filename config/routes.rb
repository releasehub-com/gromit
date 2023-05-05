Gromit::Engine.routes.draw do

  scope '/', defaults: { format: :json } do
    get '/healthcheck', to: 'gromit#healthcheck'
    post '/search', to: 'gromit#search'
    post '/upsert', to: 'gromit#upsert'
  end
end

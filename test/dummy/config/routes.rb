Rails.application.routes.draw do
  mount Vapey::Rails::Engine => "/vapey-rails"
end

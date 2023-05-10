require 'rails_helper'

RSpec.describe Gromit::GromitController, type: :controller do
  routes { Gromit::Engine.routes }

  describe 'GET #healthcheck' do
    it 'returns a healthy status' do
      get :healthcheck
    end
  end
end

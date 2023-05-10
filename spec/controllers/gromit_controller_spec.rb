require 'rails_helper'

RSpec.describe Gromit::GromitController, type: :controller do
  routes { Gromit::Engine.routes }

  let(:gromit) { instance_double(Gromit::Search) }

  before do
    allow(Gromit::Search).to receive(:new).and_return(gromit)
  end

  describe 'GET #healthcheck' do
    context 'when Redis connection is healthy' do
      before do
        allow(gromit).to receive(:redis).and_return(double('redis', ping: 'PONG'))
        allow(gromit).to receive(:create_index)
      end

      it 'returns a healthy status' do
        # c = Gromit::GromitController.new
        # get c.healthcheck, format: :json
        get :healthcheck, format: :json
        expect(response.body).to include('healthy')
      end
    end

  end
end


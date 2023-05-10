require 'rails_helper'

RSpec.describe Gromit::GromitController, type: :controller do
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
        get :healthcheck, as: :json
        expect(response.body).to include('healthy')
      end
    end

    context 'when Redis connection is unhealthy' do
      before do
        allow(gromit).to receive(:redis).and_return(double('redis', ping: 'ERROR'))
      end

      it 'returns an unhealthy status' do
        get :healthcheck
        expect(response.body).to include('unhealthy')
      end
    end
  end

  describe 'GET #search' do
    let(:embedding) { [0.1, 0.2, 0.3] }
    let(:result) { 'search result' }

    before do
      allow(gromit).to receive(:find_by_embedding).with(embedding).and_return(result)
    end

    it 'returns search result' do
      get :search, params: { embedding: embedding }
      expect(response.body).to include(result)
    end
  end

  describe 'POST #upsert' do
    let(:id) { 'test_id' }
    let(:params) { { id: id, key: 'value' } }
    let(:redis_double) { double('redis') }

    before do
      allow(gromit).to receive(:redis).and_return(redis_double)
      allow(redis_double).to receive(:json_set)
    end

    it 'upserts the record and returns success status' do
      post :upsert, params: params

      expect(redis_double).to have_received(:json_set).with("item:#{id}", Rejson::Path.root_path, params.stringify_keys)
      expect(response.body).to include('success')
    end
  end
end

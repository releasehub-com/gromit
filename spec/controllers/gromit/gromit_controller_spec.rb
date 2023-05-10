require 'rails_helper'

RSpec.describe Gromit::GromitController, type: :controller do
  routes { Gromit::Engine.routes }
  let(:redis) { double('Redis') }
  let(:gromit) { double('Gromit') }

  describe 'GET #healthcheck' do
    context "no exceptions thrown" do
      before do
        expect(Gromit::Search).to receive(:new).and_return(gromit)
        expect(gromit).to receive(:redis).and_return(redis)
      end

      it "has a healthy redis" do
        expect(redis).to receive(:ping).and_return("PONG")
        expect(gromit).to receive(:create_index)

        get :healthcheck
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({"status"=>"healthy", "message"=>"Redis connection is healthy"})
      end

      it "has an unhealthy redis" do

        expect(redis).to receive(:ping).and_return("DONG")
        expect(gromit).not_to receive(:create_index)
        
        get :healthcheck
        expect(response).to have_http_status(Gromit::GromitController::IM_A_TEAPOT)
        expect(JSON.parse(response.body)).to eq({"status"=>"unhealthy", "message"=>"Redis connection is unhealthy"})
      end
    end

    context "redis errors" do
      it 'has a bad command error' do
        expect(Gromit::Search).to receive(:new).and_wrap_original do |klass, *args|
          gromit = klass.call(*args)

          expect(gromit).to receive(:redis).and_raise(Redis::CommandError)

          gromit
        end

        get :healthcheck
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({"status"=>"unhealthy", "message"=>"Unknown command error"})
      end

      it 'has a command error, but the index is fine' do
        error = Redis::CommandError.new("Index already exists")

        expect(Gromit::Search).to receive(:new).and_wrap_original do |klass, *args|
          gromit = klass.call(*args)

          expect(gromit).to receive(:redis).and_raise(error)

          gromit
        end

        get :healthcheck
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({"status"=>"healthy", "message"=>"Redis connection is healthy"})
      end

      it 'cannont connect to redis' do
        error = Redis::CannotConnectError.new("redis has gone away")

        expect(Gromit::Search).to receive(:new).and_wrap_original do |klass, *args|
          gromit = klass.call(*args)

          expect(gromit).to receive(:redis).and_raise(error)

          gromit
        end

        get :healthcheck
        expect(response).to have_http_status(Gromit::GromitController::IM_A_TEAPOT)
        expect(JSON.parse(response.body)).to eq({"status"=>"unhealthy", "message"=>"Redis connection error: redis has gone away"})
      end
    end
  end

  
  describe 'POST #search' do
    it "calls find_by_embeddings with correct params" do
      embedding_params = {"some" => "stuff"}
      params = {embedding: embedding_params}

      expect(Gromit::Search).to receive(:new).and_return(gromit)
      expect(gromit).to receive(:find_by_embedding).with(embedding_params).and_return("some result")

      post :search, params: params
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({"data" => "some result"})
    end
  end

  describe 'POST #upsert' do
    it "upserts correctly" do
      item_id = "23434324"
      params = {"id" => item_id, "other" => "stuff"}

      expect(Gromit::Search).to receive(:new).and_return(gromit)
      expect(gromit).to receive(:redis).and_return(redis)
      expect(redis).to receive(:json_set).with("item:#{item_id}", ".", params)

      post :upsert, params: params 
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        {"status" => "success", "message" => "Record upserted successfully", "key" =>  "item:#{item_id}"})
    end
  end

end

module Gromit
  class GromitController < ApplicationController
    skip_before_action :verify_authenticity_token

    def healthcheck
      gromit = Gromit::Search.new

      begin
        # Send a PING command to Redis
        redis_ping_response = gromit.redis.ping

        # Check if the Redis server responded with "PONG"
        if redis_ping_response == 'PONG'

          # create the index if it's not already there
          gromit.create_index
        else
          render json: { status: 'unhealthy', message: 'Redis connection is unhealthy' }
        end
      rescue Redis::CommandError, Redis::CannotConnectError => e
        if e.message == "Index already exists"
          render json: { status: 'healthy', message: 'Redis connection is healthy' }
        else
          render json: { status: 'unhealthy', message: "Redis connection error: #{e.message}" }
        end
      end
    end

    def search
      gromit = Gromit::Search.new
      result = gromit.find_by_embedding(params[:embedding])
      render json: result
    end

    def upsert
      gromit = Gromit::Search.new

      # Hopefully don't have to do this
      ## json_params = JSON.parse(request.raw_post) 

      # Extract the key and value from the request data
      id = params[:id]

      # Upsert the record into the Redis database
      gromit.redis.json_set("item:#{id}", Rejson::Path.root_path, params.deep_stringify_keys)

      # Return a success response
      render json: { status: 'success', message: "Record upserted successfully", key: "item:#{id}" }
    end


  end
end

require 'rejson'

module Gromit
  class GromitController < ApplicationController
    IM_A_TEAPOT = 418

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
          render json: { status: 'healthy', message: 'Redis connection is healthy' }
        else
          render json: { status: 'unhealthy', message: 'Redis connection is unhealthy' }, status: IM_A_TEAPOT
        end
      rescue Redis::CommandError, Redis::CannotConnectError => e
        if e.is_a?(Redis::CommandError)
          if e.message == "Index already exists" 
            render json: { status: 'healthy', message: 'Redis connection is healthy' }
          else
            render json: { status: 'unhealthy', message: "Unknown command error" }, status: :bad_request
          end
        else
          render json: { status: 'unhealthy', message: "Redis connection error: #{e.message}" }, status: IM_A_TEAPOT
        end
      end
    end

    def search
      gromit = Gromit::Search.new
      result = gromit.find_by_embedding(params[:embedding])
      render json: { data: result }
    end

    def upsert
      gromit = Gromit::Search.new

      # Hopefully don't have to do this
      ## json_params = JSON.parse(request.raw_post) 

      # Extract the key and value from the request data
      id = params[:id]

      data = params.to_unsafe_h.deep_stringify_keys

      # Upsert the record into the Redis database
      gromit.redis.json_set("item:#{id}", Rejson::Path.root_path.str_path, data.except("action", "controller"))

      # Return a success response
      render json: { status: 'success', message: "Record upserted successfully", key: "item:#{id}" }
    end


  end
end

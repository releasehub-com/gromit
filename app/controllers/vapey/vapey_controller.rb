module Vapey
  class VapeyController < ApplicationController

    def healthcheck
      vapey = Vapey::Search.new

      begin
        # Send a PING command to Redis
        redis_ping_response = vapey.redis.ping

        # Check if the Redis server responded with "PONG"
        if redis_ping_response == 'PONG'

          # create the index if it's not already there
          vapey.create_index
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
      vapey = Vapey::Search.new
      result = vapey.find_by_embedding(params[:embedding])
      render json: result
    end

    def upsert
      vapey = Vapey::Search.new

      # Hopefully don't have to do this
      ## json_params = JSON.parse(request.raw_post) 

      # Extract the key and value from the request data
      id = params[:id]

      # Upsert the record into the Redis database
      vapey.redis.json_set("item:#{id}", Rejson::Path.root_path, params.deep_stringify_keys)

      # Return a success response
      render json: { status: 'success', message: "Record upserted successfully", key: "item:#{id}" }
    end


  end
end

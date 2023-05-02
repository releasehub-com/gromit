module Vapey
  module Rails
    class VapeyController < ApplicationController

      def healthcheck
        begin
          # Send a PING command to Redis
          redis_ping_response = redis.ping

          # Check if the Redis server responded with "PONG"
          if redis_ping_response == 'PONG'

            # create the index if it's not already there
            find_or_create_index
            render json: { status: 'healthy', message: 'Redis connection is healthy' }
          else
            render json: { status: 'unhealthy', message: 'Redis connection is unhealthy' }
          end
        rescue Redis::CannotConnectError => e
          # Handle connection errors
          render json: { status: 'unhealthy', message: "Redis connection error: #{e.message}" }
        end
      end

      def search
        result = search_docs_with_embedding(params[:embedding])
        render json: result
      end

      def upsert
        # Hopefully don't have to do this
        ## json_params = JSON.parse(request.raw_post) 

        # Extract the key and value from the request data
        id = params[:id]

        # Upsert the record into the Redis database
        redis.json_set("item:#{id}", Rejson::Path.root_path, params.deep_stringify_keys)

        # Return a success response
        render json: { status: 'success', message: "Record upserted successfully", key: "item:#{id}" }
      end

      def search_docs_with_embedding(embedding)
        results = redis.call([
          "FT.SEARCH", "index", "@embedding:[VECTOR_RANGE $r $BLOB]=>{$YIELD_DISTANCE_AS: my_scores}",
          "PARAMS", "4", "BLOB", embedding.pack("E*"), "r", "5",
          "LIMIT", "0", "10", "SORTBY", "my_scores", "DIALECT", "2"
        ])
        count = results[0]

        output = []
        results[1..].each_slice(2) do |key,value|
          data = JSON.parse(value[3])
          result = { key: key }.merge(data)
          result.delete("embedding")
          output << result
        end

        output
      end

      def find_or_create_index
        schema = {
          id: "TAG",
          page_id: "TAG",
          section_id: "TAG",
          file: "TEXT",
          title: "TEXT",
          content: "TEXT",
          checksum: "TEXT",
          token_count: "NUMERIC",
          embedding: "VECTOR FLAT 6 DIM 1536 DISTANCE_METRIC COSINE TYPE FLOAT64",
        }
        preamble = "FT.CREATE index ON JSON PREFIX 1 item: SCHEMA "
        command = (preamble + schema.map{|name,type| "$.#{name} AS #{name} #{type}"}.join(" ")).split(" ")
        redis.call(command)
      rescue StandardError => e
        # Rails.logger.info "redis err: #{e}"
        puts "redis err: #{e}"
      end

      def redis
        @redis ||= Redis.new(host: ENV.fetch("REDIS_HOST") { "127.0.0.1" }, port: ENV.fetch("REDIS_PORT") { "6379" }.to_i)
      end

    end
  end
end

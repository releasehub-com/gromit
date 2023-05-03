require "vapey/version"
require "vapey/engine"

module Vapey
  class Search

    def find_by_embedding(embedding)
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

    def recreate_index
      redis.call(["FT.DROP", "index"])
      create_index
    end

    def create_index
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
    end

    def redis
      @redis ||= Redis.new(host: ENV.fetch("REDIS_HOST") { "127.0.0.1" }, port: ENV.fetch("REDIS_PORT") { "6379" }.to_i)
    end

  end
end

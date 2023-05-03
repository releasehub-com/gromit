require 'bundler/setup'
require 'openai'
require 'dotenv'
require 'optparse'
require 'redis'
require 'rejson'
require 'active_support/all'

require_relative 'markdown_parser'

Dotenv.load


class Vapey::Rails::Reindexer
  attr_accessor :redis

  class << self
    def invoke
      options = { drop: false }
      OptionParser.new do |opts|
        opts.banner = "Usage: reindexer.rb [options]"

        opts.on('-s', '--source SOURCE_DIR', 'Source directory') do |source_dir|
          options[:source_dir] = source_dir
        end

        opts.on('-d', '--drop', 'Drop and create index before reindexing') do 
          options[:drop] = true
        end

      end.parse!

      # Validate the presence of source and destination directories
      unless options[:source_dir]
        puts "Error: source directory (-s or --source) must be specified."
        exit 1
      end

      # Instantiate the ToMkDocs class and perform the conversion
      reindexer = Reindexer.new
      reindexer.run(options[:source_dir], drop: options[:drop]) 

      puts "Reindexer completed successfully."
    end
  end

  def initialize
    @redis ||= Redis.new(host: ENV.fetch("REDIS_HOST") { "127.0.0.1" }, port: ENV.fetch("REDIS_PORT") { "6379" }.to_i)
  end

  def run(directory = nil, drop: false)

    if drop
      recreate_index
    end

    directory ||= ENV.fetch("DOCS_DIRECTORY") { "/Users/david/development/docs/examples" }
    sections = MarkdownParser.process(directory)
    sections.each do |section|
      puts "indexing: #{section[:file]} section: #{section[:section_title]}"
      data = section.stringify_keys
      id = data['id']
      redis.json_set("item:#{id}", Rejson::Path.root_path, data)
    end
  end

  def recreate_index
    puts "dropping index"
    redis.call(["FT.DROP", "index"])
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
    puts "creating index"
    redis.call(command)
  rescue StandardError => e
    puts "err: #{e}"
  end

end

if __FILE__ == $0
  Vapey::Rails::Reindexer::invoke
end

require 'bundler/setup'
require 'openai'
require 'optparse'
require 'redis'
require 'rejson'
require_relative 'markdown_parser'

class Gromit::Reindexer
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
      reindexer = Gromit::Reindexer.new
      reindexer.run(options[:source_dir], drop: options[:drop])

      puts "Reindexer completed successfully."
    end
  end

  def initialize
    @redis ||= Gromit::MarkdownParser.redis
  end

  def run(directory = nil, drop: false)
    gromit = Gromit::Search.new

    if drop
      gromit.recreate_index
    end

    #TODO do we really want david's examples as the default here?
    directory ||= ENV.fetch("DOCS_DIRECTORY") { "/Users/david/development/docs/examples" }
    sections = Gromit::MarkdownParser.process(directory)
    sections.each do |section|
      puts "indexing: #{section[:file]} section: #{section[:section_title]}"
      data = section.transform_keys(&:to_s)
      id = data['id']
      gromit.redis.json_set("item:#{id}", Rejson::Path.root_path, data)
    end
  end

end

if __FILE__ == $0
  Gromit::Reindexer::invoke
end

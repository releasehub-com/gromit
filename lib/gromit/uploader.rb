require 'bundler/setup'
require 'openai'
require 'httparty'
require 'dotenv'
require 'pathname'
require 'optparse'

require_relative 'markdown_parser'

Dotenv.load


class Gromit::Uploader

  class << self
    def invoke
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: uploader.rb [options]"

        opts.on('-s', '--source SOURCE_DIR', 'Source directory') do |source_dir|
          options[:source_dir] = source_dir
        end
      end.parse!

      path = Pathname.new(options.fetch(:source_dir, ''))
      unless path.exist?
        puts "Error: The source directory (-s or --source) doesn't exist or is not specified."
        exit 1
      end

      sections = Gromit::MarkdownParser.process(path.to_s)
      sections.each do |section|
        puts "uploading: #{section[:file]} section: #{section[:section_title]}"
        Uploader::Partay.post('/upsert', { headers: {"Content-Type": "application/json"}, body: section.to_json })
      end
    end
  end

  class Partay
    include HTTParty
    base_uri ENV.fetch("BASE_URL") { "127.0.0.1:9292" }
  end

end

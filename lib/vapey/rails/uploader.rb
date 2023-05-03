require 'bundler/setup'
require 'openai'
require 'httparty'
require 'dotenv'

Dotenv.load


class Vapey::Rails::Uploader

  def run(directory = nil)
    directory ||= ENV.fetch("DOCS_DIRECTORY") { "/Users/david/development/docs/examples" }
    sections = MarkdownParser.process(directory)
    sections.each do |section|
      puts "uploading: #{section[:file]} section: #{section[:section_title]}"
      Uploader::Partay.post('/upsert', { headers: {"Content-Type": "application/json"}, body: section.to_json })
    end
  end

  class Partay
    include HTTParty
    base_uri ENV.fetch("BASE_URL") { "127.0.0.1:9292" }
  end

end

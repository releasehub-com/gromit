
class Gromit::MarkdownParser
  attr_reader :sections

  class << self 

    def redis
      @@redis ||= Redis.new(host: ENV.fetch("REDIS_HOST") { "127.0.0.1" }, port: ENV.fetch("REDIS_PORT") { "6379" }.to_i)
    end

    def openai
      @@openai ||= OpenAI::Client.new(access_token: ENV.fetch("OPENAPI_ACCESS_TOKEN"))
    end

    def process(directory)

      git_file_list(directory).map do |file|
        file_path = File.expand_path(File.join(directory, file))

        next unless file.match(/\.md$/)

        puts "processing file: #{file_path}"

        page_id = Digest::SHA1.hexdigest(file_path)
        title = File.read(file_path).lines.first.strip.gsub(/^#\s+/,'')
        checksum = Digest::MD5.hexdigest(File.read(file_path))

        parser = Gromit::MarkdownParser.new(file_path)
        sections = parser.sections.map do |section|
          section = process_markdown(section)
          section_title = section.lines.first.strip.gsub(/^i[#]+\s+/,'')
          section_id = Digest::MD5.hexdigest(section)
          id = Digest::MD5.hexdigest("#{page_id}:#{section_id}")

          # get cached embedding or call out to openai
          token_count, embedding = get_embedding(section, section_id)

          {
            id: id,
            page_id: page_id,
            section_id: section_id,
            file: file,
            title: title,
            section_title: section_title,
            content: section,
            checksum: checksum,
            token_count: token_count,
            embedding: embedding,
          }

        end
      end.compact.flatten
    end

    def get_embedding(section, section_id)
      token_count = nil
      embedding = nil
      data = redis.get(section_id)

      if data.nil?

        # OpenAI recommends replacing newlines with spaces for best results (specific to embeddings)
        input = section.gsub(/\n/m, ' ')
        response = openai.embeddings(parameters: { input: input, model: "text-embedding-ada-002"})

        token_count = response['usage']['total_tokens']
        embedding = response['data'].first['embedding']

        redis.set(section_id, {'token_count' => token_count, 'embedding' => embedding}.to_json)
      else
        cached_embedding = JSON.parse(data)
        token_count = cached_embedding['token_count']
        embedding = cached_embedding['embedding']
      end
      [token_count, embedding]
    end

    def git_file_list(dir)
      `cd #{dir} && git ls-files`.split("\n")
    end

    def process_markdown(file)
      mkdocs_url = "https://docs-mkdocs.releaseapp.io"

      # handle images
      # TODO: deal with spaces??
      file.gsub!(/(!\[[^\]]*?\])([\(<]+)[\.\/]+\.gitbook\/assets\/(.*?)([\)>]+)/m) do
        "#{$1}#{$2}#{mkdocs_url}/img/#{$3}#{$4}"
      end

      # remove the .md extension from the end of the URLs from gitbook
      file.gsub!(/(\[[^\]]+?\])\((.*?)\.md([#a-z0-9]*)\)/) do |match|
        "#{$1}(#{$2}#{$3})" 
      end

      # handle "mentions" 
      file.gsub!(/\[([^\]]+?).md\]\((.*?)\.md([#a-z0-9]*) "mention"\)/) do |match|
        link = "#{$2}#{$3}"
        title = $1.gsub("-", ' ').titleize
        "[#{title}](#{link})" 
      end

      # convert gitbook hints to admonitions
      # multi-line shortest match ...
      file.gsub!(/{%\s+hint style="(.*?)"\s+?%}(.*?){% endhint %}/m) do |match|
        ret = "!!! #{$1}\n"
        ret += $2.lines.map{|line| "    #{line}" }.join()
        ret
      end

      file
    end

  end

  def initialize(file_path)
    @file_path = file_path
    @sections = []
    parse_file
  end

  def parse_file
    current_section = []
    File.read(@file_path).lines do |line|
      # Check if the line is a header (starts with one or more '#' characters)
      if header?(line)
        # Save the previous section if it's not empty
        @sections << current_section.join unless current_section.empty?
        # Start a new section
        current_section = [line]
      else
        # Add the line to the current section
        current_section << line
      end
    end
    # Save the last section if it's not empty
    @sections << current_section.join unless current_section.empty?
  end

  private

  # Check if a line is a Markdown header
  def header?(line)
    line.strip.start_with?('#')
  end
end


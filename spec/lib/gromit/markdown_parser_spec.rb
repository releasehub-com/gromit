RSpec.describe Gromit::MarkdownParser do
  let(:sample_directory) { 'spec/fixtures/sample_directory' }
  let(:sample_file_path) { "#{sample_directory}/file1.md" }
  
  describe ".redis" do
    before do
      allow(ENV).to receive(:fetch).with("REDIS_HOST") { "127.0.0.1" }
      allow(ENV).to receive(:fetch).with("REDIS_PORT") { "6379" }
    end

    it "creates a Redis instance with the correct host and port" do
      redis_instance = described_class.redis

      expect(redis_instance).to be_an_instance_of(Redis)
      expect(redis_instance._client.host).to eq("127.0.0.1")
      expect(redis_instance._client.port).to eq(6379)
    end

    it "uses the same Redis instance for subsequent calls" do
      redis_instance_1 = described_class.redis
      redis_instance_2 = described_class.redis

      expect(redis_instance_1).to be(redis_instance_2)
    end
  end

  describe '.openai' do
    before do
      allow(ENV).to receive(:fetch).with("OPENAPI_ACCESS_TOKEN") { "sometoken" }
    end

    it "creates open an open ai client with correct access token" do
      openai_client = described_class.openai
      
      expect(openai_client).to be_an_instance_of(OpenAI::Client)
      expect(OpenAI.configuration.access_token).to eq("sometoken")
    end

    it "only creates a new client once" do
      openai_client1 = described_class.openai
      openai_client2 = described_class.openai
      
      expect(openai_client1).to be(openai_client2)
    end
  end

  describe '.process' do
    it 'processes markdown files and returns sections with metadata' do
      allow(Gromit::MarkdownParser).to receive(:git_file_list).and_return(['file1.md'])
      allow(Gromit::MarkdownParser).to receive(:get_embedding).and_return([10, [1.0, 2.0, 3.0]])

      sections = Gromit::MarkdownParser.process(sample_directory)

      expect(sections.size).to eq(4)
      sections.each do |section|
        expect(section).to have_key(:id)
        expect(section).to have_key(:page_id)
        expect(section).to have_key(:section_id)
        expect(section).to have_key(:file)
        expect(section).to have_key(:title)
        expect(section).to have_key(:section_title)
        expect(section).to have_key(:content)
        expect(section).to have_key(:checksum)
        expect(section).to have_key(:token_count)
        expect(section).to have_key(:embedding)
      end
    end
  end

  describe '.get_embedding' do
    let(:section) { "This is a sample section content." }
    let(:section_id) { "a1b2c3d4e5" }
    let(:token_count) { 10 }
    let(:embedding) { [1.0, 2.0, 3.0] }
    let(:response) do
      {
        'usage' => { 'total_tokens' => token_count },
        'data' => [
          { 'embedding' => embedding }
        ]
      }
    end
    let(:cached_data) { { 'token_count' => token_count, 'embedding' => embedding }.to_json }

    let(:openai_client) { double('OpenAIClient', embeddings: response)}
    let(:redis) { double('Redis') }

    before do
      allow(described_class).to receive(:openai).and_return(openai_client)
      allow(described_class).to receive(:redis).and_return(redis)
    end

    it 'returns the token count and embedding for the given section' do
      expect(redis).to receive(:get).with(section_id).and_return(nil)
      expect(redis).to receive(:set).with(
        section_id, 
        {'token_count' => token_count, 'embedding' => embedding}.to_json
      )

      input = section.gsub(/\n/m, ' ')
      expect(openai_client).to receive(:embeddings).with(
        parameters: { input: input, model: "text-embedding-ada-002"}
      ).and_return(response)

      result = Gromit::MarkdownParser.get_embedding(section, section_id)

      expect(result).to eq([token_count, embedding])
    end

    it 'caches the token count and embedding in Redis' do
      data = {'token_count' => token_count, 'embedding' => embedding}
      expect(redis).to receive(:get).with(section_id).and_return(data.to_json)

      result = Gromit::MarkdownParser.get_embedding(section, section_id)

      expect(result).to eq([token_count, embedding])
    end
  end

  describe '.git_file_list' do
    it 'runs the correct system command' do
      dir = "some/dir"
      result = "dummy/config/blah.txt
      test/asdfaff/config/asdf/assets.rb"
      response = result.split("\n")
      cmd = "cd #{dir} && git ls-files"

      expect(described_class).to receive(:`).with(cmd).and_return(result)

      expect(Gromit::MarkdownParser.git_file_list(dir)).to eq(response)
    end
  end

  describe '.process_markdown' do
    let(:file_path) { "spec/fixtures/readme_sample.md" }
    let(:file) { File.read(file_path) }

    #tried doing the below a HERE doc first, but there was some new line or invisible formatting errors
    #when i do it as one long string it seems to work
    let(:markdown_expects) do 
      "---\ndescription: Release simplifies development by making the creation of environments easy\n---\n\n# Welcome" \
      " to Release\n!!! success\n    \n    Find out more about Release:\n    \n    * [Request a demo of Release to get " \
      "started](https://releasehub.com)\n    * [Send questions directly to the team](mailto:hello@releasehub.com)\n\n\n\n" \
      "### Static sites\n\nRelease supports standalone **static sites** running without Docker backends. These sites are" \
      " pushed into a CDN and hosted on your behalf. [See Static service deployment](reference-guide/static-service-deployment)" \
      " for more information.\n\nCan be set to expire automatically, can be renewed during push event or manually " \
      "[Environment Expiration](reference-guide/environment-expiration)\n\n!!! fail\n    \n    Don't fail\n    \n\n\n![]" \
      "(https://docs-mkdocs.releaseapp.io/img/2-repo-select-go-nginx-new.png)\n![](https://docs-mkdocs.releaseapp.io/img/rails" \
      "\\_postgres\\_redis\\_backend\\_name.png)\n![Domains page](<https://docs-mkdocs.releaseapp.io/img/Screen Shot 2022-03-30" \
      " at 12.52.48 PM.png>)\n"
    end

    it "processes the file" do
      expect(described_class.process_markdown(file)).to eq(markdown_expects)
    end

  end

  describe '.new' do
    it "sets file_path, sections and calls parse file" do
      allow_any_instance_of(described_class).to receive(:parse_file)
      
      subject = described_class.new("some/path")
      
      expect(subject.file_path).to eq("some/path")
      expect(subject.sections).to be_empty
    end
  end

  describe '#parse_file' do

    it "parses a file into sections" do
      expects = ["# File1 Title\n\n",
        "## Section 1\n\nThis is content for Section 1.\n\n- Item 1\n- Item 2\n\n![Example Image](.gitbook/assets/example_image.png)\n\n",
        "## Section 2\n\nThis is content for Section 2.\n\n1. Ordered Item 1\n2. Ordered Item 2\n\n[Link to another file](file2.md)\n\n",
        "## Section 3\n\nThis is content for Section 3.\n\n> This is a quote.\n\n[Link to a specific section](file2.md#section-1)\n\n\n",
        "# File1 Title\n\n",
        "## Section 1\n\nThis is content for Section 1.\n\n- Item 1\n- Item 2\n\n![Example Image](.gitbook/assets/example_image.png)\n\n",
        "## Section 2\n\nThis is content for Section 2.\n\n1. Ordered Item 1\n2. Ordered Item 2\n\n[Link to another file](file2.md)\n\n",
        "## Section 3\n\nThis is content for Section 3.\n\n> This is a quote.\n\n[Link to a specific section](file2.md#section-1)\n\n\n"]

      subject = described_class.new(sample_file_path)

      expect(subject.parse_file).to eq(expects)
    end
  end
end
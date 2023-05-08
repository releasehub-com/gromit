RSpec.describe Gromit::Search do
  let(:subject) { described_class.new }
  let(:embedding) { [0.1, 0.2, 0.3, 0.4, 0.5, 0.6] * 256 } # 6-dimensional vector repeated 256 times to form a 1536-dimensional vector
  
  context "with redis double" do
    let(:redis) { instance_double("Redis") }

    before do
      allow(subject).to receive(:redis).and_return(redis)
    end

    describe "#find_by_embedding" do
      let(:results) do
        [
          2,
          "item:1", 
          [0,1,2,"{\"file\":\"file1.md\",\"title\":\"Title 1\",\"content\":\"Content 1\",\"checksum\":\"abcd1234\",\"token_count\":15}"],
          "item:2", 
          ['x','y','z',"{\"file\":\"file2.md\",\"title\":\"Title 2\",\"content\":\"Content 2\",\"checksum\":\"efgh5678\",\"token_count\":10}"]
        ]
      end

      before do
        allow(redis).to receive(:call).and_return(results)
      end

      it "searches the index by embedding and returns the results" do
        output = subject.find_by_embedding(embedding)

        expect(output).to be_an(Array)
        expect(output.size).to eq(2)

        output.each do |result|
          expect(result).to include(:key, "file", "title", "content", "checksum", "token_count")
          expect(result).not_to include("embedding")
        end
      end
    end

    describe "#recreate_index" do
      it "drops index and calls create_index" do
        expect(redis).to receive(:call).with(["FT.DROP", "index"])
        expect(subject).to receive(:create_index)

        subject.recreate_index
      end
    end

    describe "#create_index" do

      it "creates the index in redis with create index command based on schema" do
        schema = Gromit::Search::EMBEDDINGS_SCHEMA
        preamble = Gromit::Search::EMBEDDINGS_PREAMBLE
        command = (preamble + schema.map{|name,type| "$.#{name} AS #{name} #{type}"}.join(" ")).split(" ")

        expect(redis).to receive(:call).with(command)

        subject.create_index
      end
    end
  end

  describe "#redis" do
    let(:redis) { double('DoubleRedis') }
    
    before do
      expect(Gromit::MarkdownParser).to receive(:redis).and_return(redis)
    end

    it "gets redis object from the markdown parser class" do
      expect(subject.redis).to be(redis)
    end

    it "uses the same Redis instance for subsequent calls" do
      redis_instance_1 = subject.redis
      redis_instance_2 = subject.redis

      expect(redis_instance_1).to be(redis_instance_2)
    end
  end

end


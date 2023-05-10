RSpec.describe Gromit::Reindexer do
  let(:redis) { double('Redis') }
  let(:source_dir) { 'spec/fixtures/source_directory' } # Change this to the actual path of the test source directory

  let(:sections) do
    [
      {
        id: 1,
        file: 'file1.md',
        section_title: 'Section 1',
        content: 'This is content for Section 1.'
      },
      {
        id: 2,
        file: 'file2.md',
        section_title: 'Section 2',
        content: 'This is content for Section 2.'
      }
    ]
  end

  describe '.invoke' do

    it 'exits because source_dir is not specified' do
      expect { described_class.invoke }.to raise_error(SystemExit)
    end

    it 'runs the reindexer on the source directory' do
      ARGV.clear
      ARGV.concat(['-s', source_dir])
      expect(Gromit::Reindexer).to receive(:new).and_wrap_original do |klass, *args|
        reindexer = klass.call(*args)

        expect(reindexer).to receive(:run).with(source_dir, drop: false)

        reindexer
      end

      described_class.invoke
    end
  end

  describe '.new' do
    it "initializes object and sets redis" do
      expect(Gromit::MarkdownParser).to receive(:redis).and_return(redis)
      reindexer = described_class.new
      expect(reindexer.redis).to be(redis)
    end
  end

  describe '#run' do
    before do
      allow(Gromit::MarkdownParser).to receive(:redis).and_return(redis)
      allow(Rejson::Path).to receive(:root_path).and_return("some/root/path")
    end

    it "drops index" do
      expect(Gromit::Search).to receive(:new).and_wrap_original do |klass, *args|
        search = klass.call(*args)

        expect(search).to receive(:recreate_index)

        search
      end

      expect(Gromit::MarkdownParser).to receive(:process).with(source_dir).and_return([])

      subject.run(source_dir, drop: true)
    end

    it "uses env variable for docs directory and parses sections" do
      expect(Gromit::Search).to receive(:new).and_wrap_original do |klass, *args|
        search = klass.call(*args)
        allow(search).to receive(:redis).and_return(redis)

        sections.each do |section|
          data = section.transform_keys(&:to_s)
          id = data['id']

          expect(redis).to receive(:json_set).with("item:#{id}", 'some/root/path', data)
        end

        search
      end

      expect(ENV).to receive(:fetch).with("DOCS_DIRECTORY").and_return("docs/dir")
      expect(Gromit::MarkdownParser).to receive(:process).with("docs/dir").and_return(sections)

      subject.run
    end
  end

end

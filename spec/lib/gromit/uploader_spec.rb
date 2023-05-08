RSpec.describe Gromit::Uploader do
  describe '.invoke' do
    let(:source_dir) { 'spec/fixtures/sample_source_dir' }
    let(:sections) do
      [
        {
          file: 'file1.md',
          section_title: 'Section 1',
          content: 'This is content for Section 1.'
        },
        {
          file: 'file2.md',
          section_title: 'Section 2',
          content: 'This is content for Section 2.'
        }
      ]
    end

    before do
      allow(Gromit::MarkdownParser).to receive(:process).and_return(sections)
    end

    it 'processes markdown files and uploads sections' do
      sections.each do |section|
        expect(Gromit::Uploader::Partay).to receive(:post).with(
          '/upsert',
          {headers: { "Content-Type" => "application/json"}, body: section.to_json}
        )
      end

      ARGV.replace(["-s", source_dir])
      
      allow(Pathname).to receive(:new).and_wrap_original do |klass, *args|
        path = klass.call(*args)

        allow(path).to receive(:exist?).and_return(true)

        path
      end

      Gromit::Uploader.invoke
    end

    context 'when the source directory does not exist' do
      it 'exits with an error message' do
        ARGV.replace(["-s", "/not/a/real/dir"]) 

        expect { Gromit::Uploader.invoke }.to raise_error(SystemExit)
      end
    end
  end
end


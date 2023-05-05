%w[
  markdown_parser
  reindexer
  uploader
].each { |name| require_relative name }

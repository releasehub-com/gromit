# frozen_string_literal: true

require_relative "lib/gromit/version"

Gem::Specification.new do |spec|
  spec.name        = "gromit"
  spec.version     = Gromit::VERSION
  spec.authors     = ["David Giffin"]
  spec.email       = ["david@giffin.org"]
  spec.homepage    = "https://github.com/releasehub-com/gromit"
  spec.summary     = "gromit: vector search and indexing of your documentation"
  spec.description = "gromit uses Redis and OpenAI embeddings to index your documentation"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/releasehub-com/gromit"
  spec.metadata["changelog_uri"] = "https://github.com/releasehub-com/gromit"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.0"

  spec.add_runtime_dependency "httparty"
  spec.add_runtime_dependency "rails", ">= 7.0.1"
  spec.add_runtime_dependency "redis", "~> 4.2"
  spec.add_runtime_dependency "rejson-rb", ">= 1.0.1"
  spec.add_runtime_dependency "ruby-openai"
end

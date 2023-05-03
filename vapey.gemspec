require_relative "lib/vapey/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "vapey-rails"
  spec.version     = Vapey::Rails::VERSION
  spec.authors     = ["David Giffin"]
  spec.email       = ["david@giffin.org"]
  spec.homepage    = "https://github.com/releasehub-com/vapey"
  spec.summary     = "vapey: vector search and indexing of your documentation"
  spec.description = "vapey uses redis and openai embeddings to index your documentation"
    spec.license     = "MIT"
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/releasehub-com/vapey-rails"
  spec.metadata["changelog_uri"] = "https://github.com/releasehub-com/vapey-rails/README.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.1"
  spec.add_dependency "redis", "~> 4.2"
  spec.add_dependency "rejson-rb", ">= 1.0.1"
  spec.add_dependency "ruby-openai"
  spec.add_dependency "httparty"
  spec.add_dependency "dotenv"
  spec.add_dependency "rspec"
  spec.add_dependency "rspec-expectations"
end

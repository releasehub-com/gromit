require "rails"

module Gromit
  class Engine < ::Rails::Engine
    isolate_namespace Gromit

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end

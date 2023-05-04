module Vapey
  class Engine < ::Rails::Engine
    isolate_namespace Vapey

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end

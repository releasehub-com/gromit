module Vapey
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Vapey::Rails
    end
  end
end

require 'rails'
require 'thinkingtank/init'

class ThinkingTankRailtie < ::Rails::Railtie
    rake_tasks do
        require 'thinkingtank/tasks'
    end

    config.before_initialize do
        require 'thinkingtank/activerecord_extensions'
    end
end

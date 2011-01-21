require 'thinkingtank/init'

if defined?(Rails::Railtie)
    # Rails 3
    # The Railtie will load the Activerecord extensions at the appropriate
    # point in the boot process
    require 'thinkingtank/railtie'
else
    # Rails 2
    # Load the extensions now, since we don't have fine-grained control like
    # in a Railtie
    require 'thinkingtank/activerecord_extensions'
end

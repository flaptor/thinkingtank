# Require these to allow requiring thinkingtank outside a Rails app, e.g.
# for testing.
require 'rubygems'
require 'indextank'

require 'erb'
require 'yaml'
require 'singleton'

module ThinkingTank
    class Builder
        def initialize(model, &block)
            @index_fields = []
            self.instance_eval &block
        end
        def indexes(*args)
            options = args.extract_options!
            args.each do |field|
                @index_fields << field
            end
        end
        def index_fields
            return @index_fields
        end
        def method_missing(method)
            return method
        end
    end
    class Configuration
        include Singleton
        attr_accessor :app_root, :client
        def initialize
            self.app_root = Rails.root if defined?(Rails.root)
            self.app_root = RAILS_ROOT if defined?(RAILS_ROOT)
            self.app_root = Merb.root  if defined?(Merb)
            self.app_root ||= Dir.pwd

            path = "#{app_root}/config/indextank.yml"
            return unless File.exists?(path)

            conf = YAML::load(ERB.new(IO.read(path)).result)[environment]
            api_url = ENV['INDEXTANK_API_URL'] || conf['api_url']
            index_name = conf['index_name'] || 'default_index'
            self.client = IndexTank::Client.new(api_url).indexes(index_name)
        end
        def environment
            if defined?(Merb)
                Merb.environment
            elsif defined?(Rails.env)
                Rails.env
            elsif defined?(RAILS_ENV)
                RAILS_ENV
            else
                ENV['RAILS_ENV'] || 'development'
            end
        end
    end
    
    module IndexMethods

        def update_index
            it = ThinkingTank::Configuration.instance.client
            idx_obj = self.to_indexable_obj
            
            it.document(idx_obj[:docid]).add(idx_obj[:fields])
        end

        def to_indexable_obj
            
            idx_obj = {}
            idx_obj[:docid] = self.class.name + ' ' + self.id.to_s
            
            fields = {}
            self.class.thinkingtank_builder.index_fields.each do |field|
                val = self.instance_eval(field.to_s)
                fields[field.to_s] = val.to_s unless val.nil?
            end
            fields[:__any] = fields.values.join " . "
            fields[:__type] = self.class.name
            
            idx_obj[:fields] = fields

            return idx_obj
        end

        def delete_from_index
            it = ThinkingTank::Configuration.instance.client
            docid = self.class.name + ' ' + self.id.to_s
            it.document(docid).delete()            
        end
    end

end

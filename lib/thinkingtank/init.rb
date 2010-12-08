require 'thinkingtank/indextank_client'

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
            self.app_root = Merb.root  if defined?(Merb)
            self.app_root ||= Dir.pwd

            path = "#{app_root}/config/indextank.yml"
            return unless File.exists?(path)

            conf = YAML::load(ERB.new(IO.read(path)).result)[environment]
            api_url = ENV['HEROKUTANK_API_URL'] || conf['api_url']
            self.client = IndexTank::ApiClient.new(api_url).get_index(conf['index_name'])
        end
        def environment
            if defined?(Merb)
                Merb.environment
            elsif defined?(Rails.env)
                Rails.env
            else
                ENV['RAILS_ENV'] || 'development'
            end
        end
    end
    
    module IndexMethods
        def update_index
            it = ThinkingTank::Configuration.instance.client
            docid = self.class.name + ' ' + self.id.to_s
            data = {}
            self.class.thinkingtank_builder.index_fields.each do |field|
                val = self.instance_eval(field.to_s)
                data[field.to_s] = val.to_s unless val.nil?
            end
            data[:__any] = data.values.join " . "
            data[:__type] = self.class.name
            it.add_document(docid, data)
        end
    end

end

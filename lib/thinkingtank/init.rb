require 'indextank'

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
            self.app_root = RAILS_ROOT if defined?(RAILS_ROOT)
            self.app_root = Merb.root  if defined?(Merb)
            self.app_root ||= Dir.pwd

            path = "#{app_root}/config/indextank.yml"
            return unless File.exists?(path)

            conf = YAML::load(ERB.new(IO.read(path)).result)[environment]
            self.client = IndexTank.new(conf['api_key'], :index_code => conf['index_code'], :index_name => conf['index_name'])
        end
        def environment
            if defined?(Merb)
                Merb.environment
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
            docid = self.class.name + ' ' + self.id.to_s
            data = {}
            self.class.thinkingtank_builder.index_fields.each do |field|
                val = self.instance_eval(field.to_s)
                data["_" + field.to_s] = val.to_s unless val.nil?
            end
            data[:text] = data.values.join " . "
            data[:type] = self.class.name
            it.add(docid, data)
        end
    end

end

class << ActiveRecord::Base
    @indexable = false
    def search(*args)
        options = args.extract_options!
        query = args.join(' ')
        if options.has_key? :conditions
            options[:conditions].each do |field,value|
                field = "_#{field}" # underscore prepended to ActiveRecord fields
                query += " #{field}:(#{value})"
            end
        end
        # TODO : add relevance functions

        it = IndexTankPlugin::Configuration.instance.client
        models = []
        ok, res = it.search("#{query.to_s} type:#{self.name}")
        if ok
            res['docs'].each do |doc|
                type, docid = doc['docid'].split(" ", 2)
                models << self.find(id=docid)
            end
        end
        return models
    end

    def define_index(name = nil, &block)
        include ThinkingTank::IndexMethods
        @thinkingtank_builder = ThinkingTank::Builder.new self, &block
        @indexable = true
        after_save :update_index
    end

    def is_indexable?
        return @indexable
    end

    def thinkingtank_builder
        return @thinkingtank_builder
    end
end



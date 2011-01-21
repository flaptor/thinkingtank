require 'thinkingtank/init'
require 'active_record'

class << ActiveRecord::Base
    @indexable = false
    def search(*args)
        return indextank_search(true, *args)
    end
    def search_raw(*args)
        return indextank_search(false, *args)
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

    private

    def indextank_search(models, *args)
        options = args.extract_options!
        query = args.join(' ')

        # transform fields in query

        if options.has_key? :conditions
            options[:conditions].each do |field,value|
                query += " #{field}:(#{value})"
            end
        end

        options.slice!(:snippet, :fetch, :function)

        it = ThinkingTank::Configuration.instance.client
        models = []
        res = it.search("__any:(#{query.to_s}) __type:#{self.name}", options)
        if models
            res['results'].each do |doc|
                type, docid = doc['docid'].split(" ", 2)
                models << self.find(id=docid)
            end
            return models
        else
            res['results'].each do |doc|
                type, docid = doc['docid'].split(" ", 2)
                doc['model'] = self.find(id=docid)
            end
            return res
        end
    end
end

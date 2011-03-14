# Load init for Rails 2, since it directly loads this file
require 'thinkingtank/init'
require 'active_record'

def load_models
    app_root = ThinkingTank::Configuration.instance.app_root
    dirs = ["#{app_root}/app/models/"] + Dir.glob("#{app_root}/vendor/plugins/*/app/models/")
    
    dirs.each do |base|
        Dir["#{base}**/*.rb"].each do |file|
            model_name = file.gsub(/^#{base}([\w_\/\\]+)\.rb/, '\1')

            next if model_name.nil?
            next if ::ActiveRecord::Base.send(:subclasses).detect { |model|
                model.name == model_name
            }

            begin
                model_name.camelize.constantize
            rescue LoadError
                model_name.gsub!(/.*[\/\\]/, '').nil? ? next : retry
            rescue NameError
                next
            rescue StandardError
                STDERR.puts "Warning: Error loading #{file}"
            end
        end
    end
end

def reindex_models
    it = ThinkingTank::Configuration.instance.client
    if it.nil?
        puts "!!! Couldn't create a client. Does config/indextank.yml have the correct info?"
        return false
    end

    if it.exists?
        puts "Deleting existing index"
        it.delete
    end
    puts "Creating a new empty index"
    it.add
    puts "Waiting for the index to be ready (this might take a while)"
    while not it.running?
        print "."
        STDOUT.flush
        sleep 0.5
    end
    print "\n"
    STDOUT.flush


    subclasses = nil
    if ActiveRecord::Base.respond_to?(:descendants)
        # Rails 3.0.0 and higher
        subclasses = ActiveRecord::Base.descendants
    elsif Object.respond_to?(:subclasses_of)
        # Rails 2
        subclasses = Object.subclasses_of(ActiveRecord::Base)
    end

    if subclasses.nil?
        STDERR.puts "Couldn't detect models to index."
        return false
    else
        subclasses.each do |klass|
            reindex klass if klass.is_indexable?
        end
    end
end

def reindex(klass, batch = false)
    it = ThinkingTank::Configuration.instance.client
    docs = []

    klass.find(:all).each do |obj|
        puts "re-indexing #{obj.class.name}:#{obj.id}"
        docs << obj.to_indexable_obj
        
        if docs.size >= 20
            it.batch_insert docs
            docs = []
        end
    end
    it.batch_insert docs
end

namespace :indextank do
    # MUST have a description for it to show up in rake -T!
    desc "Reindex all models. This deletes and recreates the index."
    task :reindex => :environment do
        load_models
        reindex_models
    end
end

namespace :it do
    desc "An alias for indextank:reindex"
    task :reindex => "indextank:reindex"
end

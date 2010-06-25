Gem::Specification.new do |s|
  s.name = %q{thinkingtank}
  s.version = "0.0.1"
  s.date = %q{2010-05-19}
  s.authors = ["Flaptor"]
  s.email = %q{indextank@flaptor.com}
  s.summary = %q{Thinking-Sphinx-like Indextank plugin.}
  s.homepage = %q{http://indextank.com/}
  s.description = %q{ActiveRecord extension that allows to define models that should be indexed in an existing IndexTank index.
    It supports a very similar syntax to ThinkingSphinx allowing to easily port an existing project.}
  s.files = [ "rails/init.rb", "lib/indextank.rb", "lib/thinkingtank/init.rb", "README", "tasks/rails.rake", "lib/thinkingtank/tasks.rb"]
end

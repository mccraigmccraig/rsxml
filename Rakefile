require 'rubygems'
require 'rake'

begin
  require "yard"

  YARD::Rake::YardocTask.new do |t|
    t.files = ["README.md", "lib/**/*.rb"]
  end
rescue LoadError
  desc message = %{"gem install yard" to generate documentation}
  task("yard") { abort message }
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "rsxml"
  gem.homepage = "http://github.com/trampoline/rsxml"
  gem.license = "MIT"
  gem.summary = %Q{an s-expression representation of XML documents in Ruby}
  gem.description = %Q{convert XML documents to an s-expression representation and back again in Ruby}
  gem.email = "craig@trampolinesystems.com"
  gem.authors = ["Trampoline Systems Ltd"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency "nokogiri", ">= 1.4.4"
  gem.add_development_dependency "rspec", "~> 1.3.1"
  gem.add_development_dependency "rr", ">= 0.10.5"
  gem.add_development_dependency "jeweler", ">= 1.5.2"
  gem.add_development_dependency "rcov", ">= 0"
  gem.add_development_dependency "yard", ">= 0.7.1"
end
Jeweler::RubygemsDotOrgTasks.new

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

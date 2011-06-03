
require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

#
# GEM SPEC

spec = Gem::Specification.new do |s|

    s.name              = "ruleby"
    s.version           = "0.8.b10"
    s.authors           = [ "Joe Kutner", "Matt Smith" ]
    s.email             = 'jpkutner@gmail.com'
    s.homepage          = "http://ruleby.org"
    s.platform          = Gem::Platform::RUBY
    s.summary           = "Rete based Ruby Rule Engine"
    s.required_ruby_version = '>= 1.8.2'
    #s.license           = "GPL3"

    s.require_paths     = [ "lib" ]
    s.test_file         = "tests/test.rb"
    s.has_rdoc          = true
    s.rubyforge_project = 'ruleby'
    s.description = <<EOF
Ruleby is a rule engine written in the Ruby language. It is a system for executing a set 
of IF-THEN statements known as production rules. These rules are matched to objects using 
the forward chaining Rete algorithm. Ruleby provides an internal Domain Specific Language 
(DSL) for building the productions that make up a Ruleby program.
EOF
    
    #s.extra_rdoc_files  = [ 'README.txt' ]
    
    #[ 'other-gem', 'yet-another-gem' ].each do |d|
    #    s.requirements << d
    #    s.add_dependency d
    #end

    files = FileList[ "{lib}/**/*" ]
    #files.exclude "rdoc" 
    s.files = files.to_a
end

#
# tasks

CLEAN.include("pkg", "rdoc")

task :default => [ :clean, :repackage ]

FileList['tasks/**/*.rake'].each { |task| import task }


#
# PACKAGING

Rake::GemPackageTask.new(spec) do |pkg|
    #pkg.need_tar = true
end

Rake::PackageTask.new(spec.name, spec.version) do |pkg|

    pkg.need_zip = true
    pkg.package_files = FileList[
        "Rakefile",
        "*.txt",
        "lib/**/*",
        "tests/**/*"
    ].to_a
    #pkg.package_files.delete("MISC.txt")
    class << pkg
        def package_name
            "#{@name}-#{@version}-src"
        end
    end
end


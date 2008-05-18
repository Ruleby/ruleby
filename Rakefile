
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
    s.version           = "0.4"
    s.authors           = [ "Joe Kutner", "Matt Smith" ]
    s.email             = 'matt@ruleby.org'
    s.homepage          = "http://ruleby.org"
    s.platform          = Gem::Platform::RUBY
    s.summary           = "Rete based Ruby Rule Engine"
    s.required_ruby_version = '>= 1.8.2'
    #s.license           = "GPL3"

    s.require_paths     = [ "lib" ]
    s.autorequire       = "ruleby"
    s.test_file         = "tests/test.rb"
    s.has_rdoc          = true
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


#
# TESTING

Rake::TestTask.new(:test) do |t|
    t.libs << "tests"
    t.test_files = FileList['tests/test.rb']
    t.verbose = true
end

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

#
# DOCUMENTATION

#ALLISON=`allison --path`
#ALLISON="/Library/Ruby/Gems/1.8/gems/allison-2.0.3/lib/allison.rb"

Rake::RDocTask.new do |rd|

    #rd.main = "README.txt"
    #rd.rdoc_dir = "html/rufus-verbs"

    rd.rdoc_files.include(
        "LICENSE.txt", 
        "lib/**/*.rb")

    rd.title = "ruleby rdoc"

    rd.options << '-N' # line numbers
    rd.options << '-S' # inline source

    #rd.template = ALLISON if File.exist?(ALLISON)
end


#
# WEBSITE

#task :upload_website => [ :clean, :rdoc ] do
#    account = "whoever@rubyforge.org"
#    webdir = "/var/www/gforge-projects/ruleby"
#    sh "rsync -azv -e ssh html/source #{account}:#{webdir}/"
#end


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
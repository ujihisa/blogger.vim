require 'fileutils'

BLOGGER_FILES= ["autoload/metarw/blogger.vim", "autoload/metarw/blogger.rb"]

task :zip do
  print "version: "
  version = STDIN.gets.chomp
  print "OK? "
  exit unless STDIN.gets.chomp == 'y'

  sh "mkdir -p blogger-#{version}/autoload/metarw"
  BLOGGER_FILES.each do |f|
    sh "cp", f, "blogger-#{version}/autoload/metarw/"
  end
  sh "zip -r blogger-#{version}.zip blogger-#{version}"
  sh "rm -r blogger-#{version}"
end

task :zip do
  print "version: "
  version = STDIN.gets.chomp
  print "OK? "
  exit unless STDIN.gets.chomp == 'y'

  sh "mkdir -p blogger-#{version}/autoload/metarw"
  sh "cp", "blogger.vim", "blogger-#{version}/autoload/metarw/"
  sh "cp", "blogger.rb", "blogger-#{version}/autoload/metarw/"
  sh "cp", "html2text", "blogger-#{version}/autoload/metarw/"
  sh "zip -r blogger-#{version}.zip blogger-#{version}"
  sh "rm -r blogger-#{version}"
end

require 'fileutils'

RUNTIME_PATH = "#{ENV["HOME"]}/.vim"
METARW_PATH = "#{RUNTIME_PATH}/autoload/metarw"
BLOGGER_FILES= ["blogger.vim","blogger.rb","html2text"]

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

task :install do
  Dir.mkdir METARW_PATH unless File.exist? METARW_PATH
  FileUtils.cp_r BLOGGER_FILES, METARW_PATH
  File.chmod 0755, "#{METARW_PATH}/html2text"
  puts "blogger.vim successfully installed."
  puts "And then add the following to your .vimrc:"
  puts "    let g:blogger_blogid = 'your_blogid_here'"
  puts "    let g:blogger_email = 'your_email_here'"
  puts "    let g:blogger_pass = 'your_blogger_password_here'"
  puts "`{blogid}` is a big digit number. See the html source of your blog and find  `blogId=****`."
end

task :uninstall do
  BLOGGER_FILES.each {|f| FileUtils.remove_entry_secure "#{METARW_PATH}/#{f}" if File.exist? "#{METARW_PATH}/#{f}"}
  begin
    FileUtils.rmdir "#{METARW_PATH}"
  rescue
    puts "Notice: #{METARW_PATH} directory not empty."
  end
end

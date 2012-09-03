#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'open3'
require 'rubygems'
require 'nokogiri'
require 'net-https-wrapper'
require 'open-uri'
require 'cgi'

class Array
  # maph :: [a] -> (a -> b) -> Hash
  def maph(&block)
    map(&block).inject({}) {|memo, (key, value)| memo.update(key => value) }
  end
end

class Gist
  class GistFileOneNotFound < Exception;end
  class GistNotFound < Exception; end
  class GitIsNotConfigured < Exception; end

  def self.create(o = {})
    opt = {:text => '', :description => nil, :ext => 'txt'}.merge(o)
    a = self.new
    a.instance_variable_set("@text", opt[:text])
    r = Net::HTTP.post_form(
      URI.parse('http://gist.github.com/gists'),
      {
        'file_contents[gistfile1]' => opt[:text],
        'file_name[gistfile1]' => nil,
        'file_ext[gistfile1]' => ".#{opt[:ext]}"
      }.merge(self.auth))
    a.instance_variable_set("@url", r['Location'])
    a.instance_variable_set("@ext", opt[:ext])
    a.instance_variable_set(
      "@gist_id", URI.parse(a.url).path.gsub(/^\//, ''))
    a.set_description opt[:description] unless opt[:description].nil?
    a
  end

  def self.load(id)
    self.new(id)
  end

  def set_description(desc)
    Net::HTTP.post_form(
      URI.parse('http://gist.github.com/gists/'+@gist_id+'/update_description'),
      {'description' => desc}.merge(self.class.auth))
    self
  end

  def url
    @url
  end

  def initialize(gist_id=nil)
    raise ArgumentError, 'gist_id is not vaild id' if
      gist_id.to_i.zero? && !gist_id.nil?
    return unless gist_id
    @url     = "http://gist.github.com/#{gist_id.to_s}"
    @text    = open("#{@url}.txt").read
    begin
      open("#{@url}.js").read
    rescue OpenURI::HTTPError
      raise Gist::GistNotFound
    end
    @ext = open(@url).read.
      gsub(/.+http:\/\/gist\.github\.com\/#{gist_id.to_s}\.js\?file=gistfile1\.([a-zA-Z0-9]+).+/m) { $1 }
    raise Gist::GistFileOneNotFound if @ext =~ /^<!DOCTYPE/
    @gist_id = gist_id.to_s
  end

  def ext
    @ext
  end

  def embed
    '<script src="http://gist.github.com/' + @gist_id +
      '.js?file=gistfile1.' + ext + '"></script>'
  end

  def text
    @text
  end

  def text=(x)
    @text = x
  end

  def gist_id
    @gist_id
  end

  def updatable?
    update(nil, open("#{@url}.txt").read, false)['Location'] != 'http://gist.github.com/gists'
  end

  def update(new_ext=nil, new_text=nil, return_self=true)
    r = Net::HTTP.post_form(
      URI.parse("http://gist.github.com/gists/"+@gist_id),
      {
        "file_contents[gistfile1.#{@ext}]" => new_text.nil? ? @text : new_text,
        "file_ext[gistfile1.#{@ext}]" => (@ext != new_ext && !new_ext.nil?) ? ".#{new_ext}" : ".#{@ext}",
        "file_name[gistfile1.#{ext}]" => "",
        "_method" => "put"
      }.merge(self.class.auth))
    return_self ? self : r
  end

  def self.auth(raise_error_if_empty=true)
    user  = `git config --global github.user`.strip
    token = `git config --global github.token`.strip
    raise GitIsNotConfigured, 'Access to [GitHub\'s account settings](https://github.com/account), and click Global git config information. Then type `git config` lines to your shell.' if (user.empty? || token.empty?) && raise_error_if_empty
    user.empty? ? {} : { :login => user, :token => token }
  end
end

module Blogger
  class RateLimitException < Exception; end
  class UnknownError < Exception; end
  class EmptyEntry < Exception; end

  @@gist = false
  def self.gist; @@gist; end
  def self.gist=(x); @@gist = x; end

  # list :: String -> Int -> IO [Hash]
  def self.list(blogid, page)
    __pagenate_get__(blogid, page).xpath('//xmlns:entry[xmlns:link/@rel="alternate"]').
      map {|i|
        tmp = [:published, :updated, :title].
          maph {|s| [s, i.at(s.to_s).content] }.
          update(
            :content =>
            i.at('content') ? i.at('content').content : i.at('summary').content).
          update(:uri => i.at('link[@rel="alternate"]')['href'])
      }
  end

  # show :: String -> String -> IO [String]
  def self.show(blogid, uri)
    xml = __find_xml_recursively__(blogid) {|x|
      x.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:link[@rel='edit']")
    }
    title = xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:title").content
    body = xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:content").content
    body = body.gsub(%r|<div class="blogger-post-footer">.*?</div>|, '')
    __title2firstline__(title) + "\n\n" + html2text(body)
  end

  # login :: String -> String -> String
  def self.login(email, pass)
    a = Net::HTTP.post(
      'https://www.google.com/accounts/ClientLogin',
      {
        'Email' => email,
        'Passwd' => pass,
        'service' => 'blogger',
        'accountType' => 'HOSTED_OR_GOOGLE',
        'source' => 'ujihisa-bloggervim-1'
    }.map {|i, j| "#{i}=#{j}" }.join('&'),
    {'Content-Type' => 'application/x-www-form-urlencoded'})
    a.body.lines.to_a.maph {|i| i.split('=') }['Auth'].chomp
  end

  # create :: String -> String -> String -> IO String
  def self.create(blogid, token, str)
    xml = Net::HTTP.post(
      "http://www.blogger.com/feeds/#{blogid}/posts/default",
      text2xml(str),
        {
        "Authorization" => "GoogleLogin auth=#{token}",
        'Content-Type' => 'application/atom+xml'
      })
      raise RateLimitException if xml.body == "Blog has exceeded rate limit or otherwise requires word verification for new posts"
      x = Nokogiri::XML(xml.body)
      raise UnknownError, xml.body unless /published/ =~ x.to_s
      elem = x.at('//xmlns:link[@rel="alternate"]')
      uri = elem != nil ? elem['href'] : "DRAFT"
  end

  # update :: String -> String -> String -> String -> IO ()
  def self.update(blogid, uri, token, str)
    lines = str.lines.to_a
    title = __firstline2title__(lines.shift.strip)
    body = self.text2html(lines.join)

    xml = __find_xml_recursively__(blogid) {|x|
      x.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:link[@rel='edit']")
    }
    put_uri = xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:link[@rel='edit']")['href']

    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:title").content = title
    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:content").content = body
    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']")['xmlns'] = 'http://www.w3.org/2005/Atom'
    Nokogiri::XML(Net::HTTP.put(
      put_uri,
      # The line below is very hacky and intentional. It removes xmlns/thr
      Nokogiri::XML(xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']").to_s.gsub(/<gd:image.*\/>/, '').gsub(/<thr:total>.*<\/thr:total>/, '')).to_s,
      {
        "Authorization" => "GoogleLogin auth=#{token}",
        'Content-Type' => 'application/atom+xml'
    }).body).at('//xmlns:link[@rel="alternate"]')['href']
  end

  def self.__find_xml_recursively__(blogid)
    xml = nil
    (0..1/0.0).each do |n|
      xml = __pagenate_get__(blogid, n)
      break if yield(xml)
    end
    xml
  end

  def self.__pagenate_get__(blogid, page)
    xml = Net::HTTP.get(URI.parse(
      "http://www.blogger.com/feeds/#{blogid}/posts/default?max-results=30&start-index=#{30*page+1}"))
    xml = Nokogiri::XML(xml)
    raise EmptyEntry if xml.xpath('//xmlns:entry').empty?
    xml
  end

  # __firstline2title__ :: String -> String
  def self.__firstline2title__(firstline)
    firstline.gsub(/^#*\s*/, '')
  end

  # __title2firstline__ :: String -> String
  def self.__title2firstline__(title)
    '# ' << title.gsub(/#/, '\#')
  end

  # text2xml :: String -> String
  def self.text2xml(text)
    lines = text.lines.to_a
    title = __firstline2title__(lines.shift.strip)
    body = self.text2html(lines.join)

    body.gsub!('&quot;', '"')
    title.gsub!('&quot;', '"')

    body.gsub!(/(\\?)&/) {|s| $1.empty? ? '&amp;' : '&' }
    title.gsub!(/(\\?)&/) {|s| $1.empty? ? '&amp;' : '&' }

    xml = <<-EOF.gsub(/^\s*\|/, '')
    |<entry xmlns='http://www.w3.org/2005/Atom' xmlns:app='http://purl.org/atom/app#'>
    |  <title type='text'>#{title.gsub(/&/, '&amp;')}</title>
    |  <content type='xhtml'>
    |    <div xmlns="http://www.w3.org/1999/xhtml">
    |      #{body}
    |    </div>
    |  </content>
    EOF
    if title =~ /^DRAFT/
      xml += "<app:control><app:draft>yes</app:draft></app:control>"
    end
    xml += "</entry>"
  end

  # html2text :: String -> String
  def self.html2text(html)
    r = IO.popen('pandoc --from=html --to=markdown', 'r+') {|io|
      io.puts html.gsub(/<script (.+?)>/) { '%script '+$1+"%"}.gsub(/<\/script>/, '%/script%')
      io.close_write
      io.read.gsub(/%script\n/, "%script ").gsub(/%script (.+?)%/) {'<script '+$1+'>'}.gsub(/%\/script%/, '</script>')
    }

    #<script src=['"]http:\/\/gist.github.com\/([0-9]+)\.js\?file=gistfile1.([a-zA-Z0-9]+)['"] ?\/>
    # expand gist if editable
    r.gsub!(/<script src=['"]http:\/\/gist.github.com\/([0-9]+)\.js\?file=gistfile1.([a-zA-Z0-9]+)['"](><\/script>| ?\/>)/) do |s|
      if Blogger.gist
        g  = Gist.new($1)
        if g.updatable?
          c  = '<gist options="'+$1+' '+$2+'" />'
          c << "\n"
          c << g.text.split(/\r?\n/).map {|x| '    ' + x }.join("\n")
          c << "\n"
        else; s
        end
      else; s
      end
    end
    r
  end

  def self.text2html(mkd)
    text = Open3.capture2e("pandoc --from=markdown --to=html", :stdin_data => mkd)[0]
    # update gist if editable.
    text.gsub!(/<p><gist option="([0-9]+) ([a-zA-Z0-9]+)" ?\/><\/p>\n*<pre><code>(.+)<\/code><\/pre>/m) do
      text = $3
      begin
        g = Gist.new($1)
      rescue GistNotFound, GistFileOneNotFound
        g = Gist.create(:text => text, :ext => $3, :description => "Blogger.vim #{Time.now}")
        g.embed
      else
        if g.editable?
          g.text = text
          g.update($3).embed
        else
          g = Gist.create(:text => text, :ext => $3, :description => "Blogger.vim #{Time.now}")
          g.embed
        end
      end
    end
    if Blogger.gist
      text.gsub!(/<pre><code>(.+?)<\/code><\/pre>/m) do |s|
        text2 = $1
        if $1.split(/\r?\n/).size >= 5
          g = Gist.create(:text => CGI.unescapeHTML(text2), :description => "Blogger.vim #{Time.now}")
          g.embed
        else; s
        end
      end
    end
    text
  end
end

if __FILE__ == $0
  if ARGV[0] == '--gist'
    Blogger.gist = true
    ARGV.shift
  end

  case ARGV.shift
  when 'list'
    puts (Blogger.list(ARGV[0], 0) + (begin; Blogger.list(ARGV[0], 1); rescue Blogger::EmptyEntry; []; end)).map {|e| "#{e[:title]} -- #{e[:uri]}" }
  when 'show'
    puts Blogger.show(ARGV[0], ARGV[1])
  when 'create'
    uri = Blogger.create(ARGV[0], Blogger.login(ARGV[1], ARGV[2]), STDIN.read)
    if /darwin/ =~ RUBY_PLATFORM
      IO.popen('pbcopy', 'w') {|io| io.write uri } rescue nil
    end
    puts uri
  when 'update'
    puts Blogger.update(ARGV[0], ARGV[1], Blogger.login(ARGV[2], ARGV[3]), STDIN.read)
  else
    puts "read README.md"
  end
end

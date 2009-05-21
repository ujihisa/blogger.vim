#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'rubygems'
require 'nokogiri'
require 'markdown'

class Net::HTTP
  def self.post(uri, data, header)
    __post_or_put__(:post, uri, data, header)
  end

  def self.put(uri, data, header)
    __post_or_put__(:put, uri, data, header)
  end

  def self.__post_or_put__(method, uri, data, header)
    uri = URI.parse(uri)
    i = new(uri.host, uri.port)
    unless uri.port == 80
      i.use_ssl = true
      i.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    i.__send__(method, uri.path, data, header)
  end
end

class Array
  # maph :: [a] -> (a -> b) -> Hash
  def maph(&block)
    map(&block).inject({}) {|memo, (key, value)| memo.update(key => value) }
  end
end

module Blogger
  class RateLimitException < Exception; end

  # list :: String -> IO [Hash]
  def self.list(blogid)
    xml = Net::HTTP.get(URI.parse("http://www.blogger.com/feeds/#{blogid}/posts/default"))
    Nokogiri::XML(xml).xpath('//xmlns:entry[xmlns:link/@rel="alternate"]').
      map {|i|
        [:published, :updated, :title, :content].
          maph {|s| [s, i.at(s.to_s).content] }.
          update(:uri => i.at('link[@rel="alternate"]')['href'])
      }
  end

  # show :: String -> String -> IO [String]
  def self.show(blogid, uri)
    entry = list(blogid).find {|e| e[:uri] == uri }
    entry[:title] + "\n\n" + html2text(entry[:content])
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
    Nokogiri::XML(xml.body).at('//xmlns:link[@rel="alternate"]')['href']
  end

  # update :: String -> String -> String -> String -> IO ()
  def self.update(blogid, uri, token, str)
    lines = str.lines.to_a
    title = lines.shift.strip
    body = Markdown.new(lines.join).to_html

    xml = Net::HTTP.get(URI.parse("http://www.blogger.com/feeds/#{blogid}/posts/default")) # not dry!
    xml = Nokogiri::XML(xml)
    put_uri = xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:link[@rel='edit']")['href']
    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:title").content = title
    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:content").content = body
    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']")['xmlns'] = 'http://www.w3.org/2005/Atom'
    Net::HTTP.put(
      put_uri,
      xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']").to_s,
      {
        "Authorization" => "GoogleLogin auth=#{token}",
        'Content-Type' => 'application/atom+xml'
      })
  end

  # text2xml :: String -> String
  def self.text2xml(text)
    lines = text.lines.to_a
    title = lines.shift.strip
    body = Markdown.new(lines.join).to_html
    <<-EOF.gsub(/^\s*\|/, '')
    |<entry xmlns='http://www.w3.org/2005/Atom'>
    |  <title type='text'>#{title}</title>
    |  <content type='xhtml'>
    |    <div xmlns="http://www.w3.org/1999/xhtml">
    |      #{body}
    |    </div>
    |  </content>
    |</entry>
    EOF
  end

  # html2text :: String -> String
  def self.html2text(html)
    memo = []
    IO.popen("#{File.dirname(__FILE__)}/html2text", 'r+') {|io|
      io.puts html
      io.close_write

      mode = :normal
      while line = io.gets do
        if /^    / =~ line
          mode = :code
        elsif line.chomp == '' && mode == :code
          line = io.gets
        else
          mode = :normal
        end
        memo << line
      end
    }
    memo.join
  end
end

if __FILE__ == $0
  case ARGV.shift
  when 'list'
    puts Blogger.list(ARGV[0]).map {|e| "#{e[:title]} -- #{e[:uri]}" }
  when 'show'
    puts Blogger.show(ARGV[0], ARGV[1])
  when 'create'
    puts Blogger.create(ARGV[0], Blogger.login(ARGV[1], ARGV[2]), STDIN.read)
  when 'update'
    puts Blogger.update(ARGV[0], ARGV[1], Blogger.login(ARGV[2], ARGV[3]), STDIN.read)
  else
    puts "read README.md"
  end
end

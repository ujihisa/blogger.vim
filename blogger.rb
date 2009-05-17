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

  # post :: String -> String -> String -> String -> IO String
  def self.post(email, pass, str, blogid)
    a = login(email, pass)
    xml = Net::HTTP.post(
      "http://www.blogger.com/feeds/#{blogid}/posts/default",
      text2xml(str),
      {
        "Authorization" => "GoogleLogin auth=#{a}",
        'Content-Type' => 'application/atom+xml'
      }).body
    raise RateLimitException if xml == "Blog has exceeded rate limit or otherwise requires word verification for new posts"
    Nokogiri::XML(xml).at('//xmlns:link[@rel="alternate"]')['href']
  end

  # update :: String -> String -> String -> String -> String -> IO ()
  def self.update(email, pass, str, blogid, uri)
    a = login(email, pass)

    lines = str.lines.to_a
    title = lines.shift.strip
    body = Markdown.new(lines.join).to_html

    xml = Net::HTTP.get(URI.parse("http://www.blogger.com/feeds/#{blogid}/posts/default")) # not dry!
    xml = Nokogiri::XML(xml)
    put_uri = xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:link[@rel='edit']")['href']
    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:title").content = title
    xml.at("//xmlns:entry[xmlns:link/@href='#{uri}']/xmlns:content").content = <<-EOF.gsub(/^\s*\|/, '')
    |<div xmlns="http://www.w3.org/1999/xhtml">
    |  #{body}
    |</div>
    EOF
    xml.at('//xmlns:entry')['xmlns'] = 'http://www.w3.org/2005/Atom'
    Net::HTTP.put(
      put_uri,
      xml.at('//xmlns:entry').to_s,
      {
        "Authorization" => "GoogleLogin auth=#{a}",
        'Content-Type' => 'application/atom+xml'
      }).body
  end


  # list :: String -> IO [Hash]
  def self.list(blogid)
    xml = Net::HTTP.get(URI.parse("http://www.blogger.com/feeds/#{blogid}/posts/default"))
    Nokogiri::XML(xml).xpath('//xmlns:entry[xmlns:link/@rel="alternate"]').
      map {|i|
        hash = {}
        [:published, :updated, :title, :content].each {|s| hash[s] = i.at(s.to_s).content }
        hash[:uri] = i.at('link[@rel="alternate"]')['href']
        hash
      }
  end

  # get :: String -> String -> IO [String]
  def self.get(blogid, uri)
    entry = list(blogid).find {|e| e[:uri] == uri }
    entry[:title] + "\n\n" + IO.popen("#{File.dirname(__FILE__)}/html2text", 'r+') {|io|
      io.puts entry[:content]
      io.close_write
      io.read
    }
  end

  # login :: String -> String -> String
  def self.login(email, pass)
    return @@login if defined? @@login
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
    @@login = a.body.lines.to_a.maph {|i| i.split('=') }['Auth'].chomp
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
end

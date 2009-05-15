#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'rubygems'
require 'nokogiri'
require 'markdown'

class Net::HTTP
  def self.post(uri, data, header)
    uri = URI.parse(uri)
    i = new(uri.host, uri.port)
    unless uri.port == 80
      i.use_ssl = true
      i.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    i.post(uri.path, data, header)
  end
end

class Array
  # maph :: [a] -> (a -> b) -> Hash
  def maph(&block)
    map(&block).inject({}) {|memo, (key, value)| memo.update(key => value) }
  end
end

module Blogger
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
    Nokogiri::HTML(xml).xpath('//link[attribute::rel="alternate"]').first['href']
  end

  # list :: String -> IO [String]
  def self.list(blogid)
    xml = Net::HTTP.get(URI.parse("http://www.blogger.com/feeds/#{blogid}/posts/default"))
    Nokogiri::HTML(xml).xpath('//entry/link[attribute::rel="alternate"]').map {|i| i['href'] }
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

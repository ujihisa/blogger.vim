#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'rubygems'
require 'nokogiri'

class Net::HTTP
  def self.post(uri, data, header)
    uri = URI.parse(uri)
    i = new(uri.host, uri.port)
    i.use_ssl = true
    i.verify_mode = OpenSSL::SSL::VERIFY_NONE
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
  # post :: String -> String -> IO String
  def self.post(str, blogid)
    Net::HTTP.post(
      "http://www.blogger.com/feeds/#{blogid}/posts/default",
      text2xml(str),
      {'Content-Type' => 'application/atom+xml'})
  end

  # login :: String -> String -> IO Hash
  def self.login(email, pass)
    a = Net::HTTP.post(
      'https://www.google.com/accounts/ClientLogin',
      {
        'Email' => email,
        'Passwd' => pass,
        'service' => 'xapi',
        'accountType' => 'HOSTED_OR_GOOGLE',
        'source' => 'ujihisa-bloggervim-1'
      }.map {|i, j| "#{i}=#{j}" }.join('&'),
      {'Content-Type' => 'application/x-www-form-urlencoded'})
    a.body.lines.to_a.maph {|i| i.split('=') }
  end

  # text2xml :: String -> String
  def self.text2xml(text)
    lines = text.lines.to_a
    title = lines.shift.strip
    body = lines.join("<br />")
    <<-EOF.gsub(/^\s*\|/, '')
    |<entry xmlns='http://www.w3.org/2005/Atom'>
    |  <title type='text'>#{title}</title>
    |  <content type='xhtml'>
    |    <div xmlns="http://www.w3.org/1999/xhtml">
    |      <p>#{body}</p>
    |    </div>
    |  </content>
    #|  <category scheme="http://www.blogger.com/atom/ns#" term="marriage" />
    #|  <category scheme="http://www.blogger.com/atom/ns#" term="Mr. Darcy" />
    |</entry>
    EOF
  end
end

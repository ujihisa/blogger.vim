#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'

module Blogger
  # post :: String -> IO String
  def self.post(str)
    'ok'
  end

  # text2xml :: String -> String
  def self.text2xml(text)
    lines = text.lines.to_a
    title = lines.shift.strip
    body = lines.join("<br />")
    <<-EOF.gsub(/^\s*\|/, '')
    |<entry xmlns='http://www.w3.org/2005/Atom'>
    |  <title type='text'>Marriage!</title>
    |  <content type='xhtml'>
    |    <div xmlns="http://www.w3.org/1999/xhtml">
    |      <p>Mr. Darcy has <em>proposed marriage</em> to me!</p>
    |      <p>He is the last man on earth I would ever desire to marry.</p>
    |      <p>Whatever shall I do?</p>
    |    </div>
    |  </content>
    |  <category scheme="http://www.blogger.com/atom/ns#" term="marriage" />
    |  <category scheme="http://www.blogger.com/atom/ns#" term="Mr. Darcy" />
    |</entry>
    EOF
  end
end

require File.dirname(__FILE__) + '/../blogger.rb'

class DateTime
  def inspect
    to_s
  end
end

describe 'Array#maph' do
  it 'wraps Enumerable#map to get Hash directly' do
    hash = [1, 2, 3].maph {|i| [i.to_s, i*2] }
    hash.should == {
      '1' => 2,
      '2' => 4,
      '3' => 6
    }
  end
end

describe Blogger do
  before(:each) do
    @new_entry_str = "# hi\n\nIt's sunny today.\nyay!\n\n* item1\n* item2\n\n" <<
    '<object width="425" height="344"><param name="movie"></param><embed src="http://www.youtube.com/v/UF8uR6Z6KLc&amp;hl=en&amp;fs=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object>'
    @email = 'blogger.vim@gmail.com'
    @pass = 'bloggervimvim' # I hope you never change it...
    @blogid = '7772225564702673313'
  end

  describe '.login' do
    it 'gets token' do
      a = Blogger.login(@email, @pass)
      a.should be_instance_of(String)
      a.size.should == 182
    end
  end

  describe '.create' do
    it 'creates a new entry by the argument string' do
      token = Blogger.login(@email, @pass)
      uri = Blogger.create(@blogid, token, @new_entry_str)
      uri.should match(/^http:\/\/wwwwwwwwwwwwwwwwwwzw3.blogspot.com/)
    end
  end


  describe '.list' do
    it 'retrieves blog entry hashes' do
      entries = Blogger.list(@blogid, 0)

      entries.should be_instance_of(Array)

      entry = entries.first
      entry.should be_instance_of(Hash)
      entry[:uri].should match(/^http:/)
      entry[:published].should match(/#{Time.now.year}/)
      entry[:updated].should match(/#{Time.now.year}/)
      entry[:title].should match(/hi/)
      entry[:content].should match(/yay!/)
    end

    it 'is ordered by latest' do
      entries = Blogger.list(@blogid, 0).map {|e|
        DateTime.parse(e[:published])
      }
      entries.sort.reverse.should == entries
    end
  end

  describe '.show' do
    it 'retrieves the blog post of the argument' do
      uri = Blogger.list(@blogid, 0).first[:uri]
      text = Blogger.show(@blogid, uri)
        text.should be_instance_of(String)
      text.should match(/yay!/)
    end
  end

  describe '.update' do
    it 'updates the entry of the given uri with the argument string' do
      uri = Blogger.list(@blogid, 0)[2][:uri]
      token = Blogger.login(@email, @pass)
      Blogger.update(@blogid, uri, token, "hi updated\n\nupdated\n#{rand}\n\nyay!")
      Blogger.show(@blogid, uri).should match(/updated/)
    end

    it 'updates an old entry' do
      uri = 'http://wwwwwwwwwwwwwwwwwwzw3.blogspot.com/2009/05/hi_764.html'
      token = Blogger.login(@email, @pass)
      Blogger.update(@blogid, uri, token, "hi updated\n\nupdated\n#{rand}\n\nyay!")
      Blogger.show(@blogid, uri).should match(/updated/)
    end
  end

  describe '.__firstline2title__' do
    it 'ignores head hashes with spaces' do
      Blogger.__firstline2title__("aaa").should == 'aaa'
      Blogger.__firstline2title__("#aaa").should == 'aaa'
      Blogger.__firstline2title__("##aaa").should == 'aaa'
      Blogger.__firstline2title__("# aaa").should == 'aaa'
      Blogger.__firstline2title__("#  aaa").should == 'aaa'
    end
  end

  describe '.__title2firstline__' do
    it 'adds hash on the first, and escaped the title' do
      Blogger.__title2firstline__("aaa").should == '# aaa'
      Blogger.__title2firstline__("a#aa").should == '# a\#aa'
    end
  end

  describe '.text2xml' do
    it 'translate the argument text to xml' do
      xml = Blogger.text2xml(@new_entry_str)
      doc = Nokogiri::XML(xml)
      doc.xpath('//xmlns:entry/xmlns:title').first.content.should == 'hi'
      doc.xpath('//xmlns:entry/xmlns:content').first.content.should match(/It's sunny today/)
    end
  end

  describe '.html2text' do
    it 'encodes html to markdown style text' do
      g = Gist.create(:text => 'hi :D')
      Blogger.gist = false
      html = <<-EOF.gsub(/^\s+\|/, '')
      |<p>It's sunny today.
      |yay!</p>

      |<ul>
      |<li>item1</li>
      |<li>item2</li>
      |</ul>
      |<pre><code>
      |this is
      |a pen
      |
      |hehehe
      |</code></pre>
      |
      |<p>Gist!</p>
      |
      |#{g.embed}
      EOF
      text = <<-EOF.gsub(/^\s+\|/, '')
      |It's sunny today. yay!
      |
      |-   item1
      |-   item2
      |
      |    this is
      |    a pen
      |    
      |    hehehe
      |
      |Gist!
      |
      |#{g.embed}
      EOF
      Blogger.gist = true
      html = <<-EOF.gsub(/^\s+\|/, '')
      |<p>It's sunny today.
      |yay!</p>
      |
      |<ul>
      |<li>item1</li>
      |<li>item2</li>
      |</ul>
      |<pre><code>
      |this is
      |a pen
      |
      |hehehe
      |</code></pre>
      |
      |<p>Gist!</p>
      |
      |#{g.embed}
      EOF
      text = <<-EOF.gsub(/^\s+\|/, '')
      |It's sunny today. yay!
      |
      |-   item1
      |-   item2
      |
      |    this is
      |    a pen
      |    
      |    hehehe
      |
      |Gist!
      |
      |<gist options="#{g.gist_id} txt" />
      |    hi :D
      |
      |
      |
      EOF
      Blogger.html2text(html).should == text
      Blogger.gist = false
    end
  end

  describe '.text2html' do
  end
end

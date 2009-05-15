require 'blogger.rb'

describe Blogger do
  before(:each) do
    @new_entry_str = "hi\n\nIt's sunny today.\nyay!"
  end

  describe '.post' do
    it 'creates a new entry by the argument string' do
      uri = Blogger.post(@new_entry_str)
      uri.should match(/^http/)
    end
  end

  describe '.text2xml' do
    it 'translate the argument text to xml' do
      xml = Blogger.text2xml(@new_entry_str)
      doc = Nokogiri::HTML(xml)
      doc.xpath('//title').first.content.should == 'hi'
    end
  end
end

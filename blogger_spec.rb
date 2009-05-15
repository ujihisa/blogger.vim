require 'blogger.rb'

describe 'Net::HTTP.post' do
  it 'wraps posting using .new, #post and #body' do
    nh = mock('nh')
    Net::HTTP.should_receive(:new).with('aaa.bbb').and_return(nh)
    def nh.post(a, b, c); self end
    def nh.body; 'ok' end
    Net::HTTP.post(
      'http://aaa.bbb/ccc/ddd',
      'data',
      {'a' => 'b'}).should == 'ok'
  end
end

describe Blogger do
  before(:each) do
    @new_entry_str = "hi\n\nIt's sunny today.\nyay!"
    @pass = 'bloggervimvim' # I hope you never change it...
    @blogid = '2754163879208528226'
  end

  describe '.post' do
    it 'creates a new entry by the argument string' do
      uri = Blogger.post(@new_entry_str, @blogid)
      uri.should match(/^http/)
    end
  end

  describe '.text2xml' do
    it 'translate the argument text to xml' do
      xml = Blogger.text2xml(@new_entry_str)
      doc = Nokogiri::HTML(xml)
      doc.xpath('//title').first.content.should == 'hi'
      doc.xpath('//div/p').first.content.should match(/It's sunny today/)
    end
  end
end

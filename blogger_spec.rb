require 'blogger.rb'

describe 'Net::HTTP.post' do
  it 'wraps posting using .new, #post and #body' do
    nh = mock('nh')
    Net::HTTP.should_receive(:new).with('aaa.bbb', 80).and_return(nh)
    def nh.use_ssl=(a); end
    def nh.verify_mode=(a); end
    def nh.post(a, b, c); 'ok' end
    Net::HTTP.post(
      'http://aaa.bbb/ccc/ddd',
      'data',
      {'a' => 'b'}).should == 'ok'
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
    @new_entry_str = "hi\n\nIt's sunny today.\nyay!"
    @email = 'blogger.vim@gmail.com'
    @pass = 'bloggervimvim' # I hope you never change it...
    @blogid = '2754163879208528226'
  end

  describe '.post' do
    it 'creates a new entry by the argument string' do
      uri = Blogger.post(@email, @pass, @new_entry_str, @blogid)
      uri.should match(/^http/)
    end
  end

  describe '.login' do
    it 'gets token' do
      a = Blogger.login(@email, @pass)
      a.should be_instance_of(String)
      a.size.should == 161
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

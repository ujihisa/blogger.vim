require 'blogger.rb'

class Gist
  def self.auth
    {:login => 'bloggervim', :token => '2702e0f532e76bf078323ce3506c2a43'}
  end
end


describe Gist do
  describe '.create' do
    it 'with simple text' do
      open(Gist.create(:text => 'Hi! :-)').url+'.txt').read.should match(/Hi! :-\)/)
    end

    it 'with description and text' do
      open(Gist.create(:text => 'Hi! With description',
                       :description => ':-)').url).read \
          .should match(/<span id="gist-text-description" class="edit">:-\)/)
    end

    it 'with ext and text' do
      open(Gist.create(:text => 'class Foo; end',
                       :ext => 'rb').url).read \
          .should match(/<a href="\/raw\/\d+\/[a-zA-Z0-9]+\/gistfile1.rb">/)
    end
  end

  describe 'some atributes' do
    before(:all) do
      @a = Gist.create(:text => 'Hi! :-)')
    end

    it '.url' do
      @a.url.should match(/http:\/\/gist\.github\.com\//)
    end

    it '.ext' do
      @a.ext.should == 'txt'
    end

    it '.embed embed tag' do
      @a.embed \
        .should \
         match(/<script src="http:\/\/gist.github.com\/.+\.js\?file=gistfile1\.txt"><\/script>/)
    end

    it '.text' do
      @a.text == 'Hi! :-)'
      @a.text = 'Hi!! :-)'
      @a.text.should == 'Hi!! :-)'
    end

    it '.gist_id' do
      @a.gist_id.should match(/\d+/)
    end

    it '.updatable?' do
      @a.updatable?.should be_true
    end
  end

  describe '.new' do
    before(:all) do
      @gist_id = Gist.create(:text => 'Yey :-D').gist_id
      @g = Gist.new(@gist_id)
    end

    it 'load exist gist' do
      @g.text.should == 'Yey :-D'
    end
  end


  describe '.update' do
    before(:all) do
      @g = Gist.create(:text => 'Yey!Yey!Yey!')
    end

    it 'can put text attribute' do
      @g.text = 'Yey!!Yey!!Yey!!'
      @g.update.should == @g
      Gist.new(@g.gist_id).text.should == 'Yey!!Yey!!Yey!!'
    end

    it 'can put text with argument' do
      @g.update(nil,'Yey!!!Yey!!!Yey!!!')
      Gist.new(@g.gist_id).text.should == 'Yey!!!Yey!!!Yey!!!'
    end

    it 'can put with new ext' do
      @g.update('rb')
      Gist.new(@g.gist_id).ext.should == 'rb'
    end

    it 'can return Net::HTTPResponse' do
      @g.update(nil,nil,false).should be_a_kind_of(Net::HTTPResponse)
    end
  end
end



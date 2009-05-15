require 'blogger.rb'

describe Blogger do
  describe '.post' do
    it 'creates a new entry by the argument string' do
      @new_entry_str = "hi\n\nIt's sunny today.\nyay!"
      uri = Blogger.post(@new_entry_str)
      uri.should match(/^http/)
    end
  end
end

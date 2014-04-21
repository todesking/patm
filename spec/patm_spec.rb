require File.join(File.dirname(__FILE__), '..', 'lib', 'patm.rb')

describe Patm do
  it 'should do pattern matching with case-when expression' do
    p = Patm
    case [1, 2, 3]
    when m = p.match([1, p._1, p._2])
      [m._1, m._2]
    else
      []
    end
      .should == [2, 3]
  end
end

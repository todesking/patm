require File.join(File.dirname(__FILE__), '..', 'lib', 'patm.rb')

module PatmHelper
  extend RSpec::Matchers::DSL

  matcher :match_to do|expected|
    match do|actual|
      actual.execute(Patm::Match.new, expected)
    end
  end

  def pat(p)
    Patm::Pattern.build_from(p)
  end
end

describe Patm do
  include PatmHelper

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

  describe '::Pattern' do
    subject { pat(1) }
    it { should match_to(1) }
    it { should_not match_to(2) }
  end
end

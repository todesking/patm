require File.join(File.dirname(__FILE__), '..', 'lib', 'patm.rb')
require 'pry'

module PatmHelper
  extend RSpec::Matchers::DSL

  matcher :these_matches do|*matches|
    match do|actual|
      matches.all?{|m| m.matches?(actual) }
    end
  end

  matcher :match_to do|expected|
    match do|actual|
      exec(actual, expected)
    end

    def exec(actual, expected)
      @match = Patm::Match.new
      actual.execute(@match, expected)
    end

    def match; @match; end

    def and_capture(g1, g2 = nil, g3 = nil)
      these_matches(
        self, _capture(self, g1, g2, g3)
      )
    end
  end

  matcher :_capture do|m, g1, g2, g3|
    match do|_|
      [m.match[1], m.match[2], m.match[3]] == [g1, g2, g3]
    end
  end

end

describe "Usage:" do
  it 'with case expression' do
    p = Patm
    case [1, 2, 3]
    when m = p.match([1, p._1, p._2])
      [m._1, m._2]
    else
      []
    end
      .should == [2, 3]
  end

  it 'with predefined Rule' do
    p = Patm
    r = p::Rule.new do|r|
      r.on [1, p._1, p._2] do|m|
        [m._1, m._2]
      end
      r.else {|obj| [] }
    end
    r.apply([1, 2, 3]).should == [2, 3]
  end

  it 'with RuleCache' do
    p = Patm
    rs = p::RuleCache.new

    rs.match(:pattern_1, [1, 2, 3]) do|r|
      r.on [1, p._1, p._2] do|m|
        [m._1, m._2]
      end
      r.else {|obj| [] }
    end
      .should == [2, 3]

    rs.match(:pattern_1, [1, 3, 5]) {|r| fail "should not reach here" }.should == [3, 5]
  end
end

describe Patm::Pattern do
  include PatmHelper
  def self.pattern(plain, &b)
    context "pattern '#{plain.inspect}'" do
      subject { Patm::Pattern.build_from(plain) }
      instance_eval(&b)
    end
    context "pattern '#{plain.inspect}'(Compiled)" do
      subject { Patm::Pattern.build_from(plain).compile }
      instance_eval(&b)
    end
  end

  pattern 1 do
    it { should match_to(1) }
    it { should_not match_to(2) }
  end

  pattern [] do
    it { should match_to [] }
    it { should_not match_to {} }
    it { should_not match_to [1] }
  end

  pattern [1,2] do
    it { should match_to [1,2] }
    it { should_not match_to [1] }
    it { should_not match_to [1, -1] }
    it { should_not match_to [1,2,3] }
  end

  pattern Patm::ANY do
    it { should match_to 1 }
    it { should match_to ["foo", "bar"] }
  end

  pattern [1, Patm::ANY, 3] do
    it { should match_to [1, 2, 3] }
    it { should match_to [1, 0, 3] }
    it { should_not match_to [1, 0, 4] }
  end

  pattern Patm.or(1, 2) do
    it { should match_to 1 }
    it { should match_to 2 }
    it { should_not match_to 3 }
  end

  pattern Patm._1 do
    it { should match_to(1).and_capture(1) }
    it { should match_to('x').and_capture('x') }
  end

  pattern Patm._1 & Patm._2 do
    it { should match_to(1).and_capture(1, 1) }
  end

  pattern [0, Patm._1, Patm._2] do
    it { should match_to([0, 1, 2]).and_capture(1, 2) }
    it { should_not match_to(['x', 1, 2]).and_capture(1, 2) }
  end

  pattern [0, 1, Patm::ARRAY_REST] do
    it { should_not match_to([0]) }
    it { should match_to([0, 1]) }
    it { should match_to([0, 1, 2, 3]) }
  end

  pattern [0, 1, Patm::ARRAY_REST & Patm._1] do
    it { should match_to([0, 1]).and_capture([]) }
    it { should match_to([0, 1, 2, 3]).and_capture([2, 3]) }
  end

  pattern [0, 1, Patm::ARRAY_REST, 2, 3] do
    it { should match_to(0,1,2,3) }
    it { should match_to(0,1,10,20,30,2,3) }
    it { should_not match_to(0,1,3) }
  end
end

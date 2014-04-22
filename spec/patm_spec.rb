require File.join(File.dirname(__FILE__), '..', 'lib', 'patm.rb')

module PatmHelper
  extend RSpec::Matchers::DSL

  matcher :match_to do|expected|
    match do|actual|
      actual.execute(Patm::Match.new, expected)
    end
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
    def self.pattern(plain, &b)
      context "pattern '#{plain.inspect}'" do
        subject { Patm::Pattern.build_from(plain) }
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

  end
end

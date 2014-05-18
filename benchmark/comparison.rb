require 'benchmark'

def benchmark(klass, n)
  puts "Benchmark: #{klass}"
  validate(klass)

  Benchmark.bm('pattern-match'.size) do|b|
    obj = klass.new
    test_values = obj.test_values
    b.report("manual") do
      n.times { test_values.each {|val| obj.manual(val) } }
    end
    b.report("PATM") do
      n.times { test_values.each {|val| obj.patm(val) } }
    end
    b.report("pattern-match") do
      n.times { test_values.each {|val| obj.pattern_match(val) } }
    end
  end
  puts
end

def validate(klass)
  obj = klass.new
  obj.test_values.each do|val|
    man = obj.manual(val)
    patm = obj.patm(val)
    pm = obj.pattern_match(val)
    if patm != pm || man != pm
      raise "ERROR: Result not match. val=#{val.inspect}, manual: #{man.inspect}, PATM: #{patm.inspect}, pattern-match: #{pm.inspect}"
    end
  end
end

load File.join(File.dirname(__FILE__), '../lib/patm.rb')
require 'pattern-match'

class SimpleConst
  extend Patm::DSL

  def manual(obj)
    if obj == 1
      100
    elsif obj == 2
      200
    else
      300
    end
  end

  define_matcher :patm do|r|
    r.on(1) { 100 }
    r.on(2) { 200 }
    r.else { 300 }
  end

  def pattern_match(obj)
    match(obj) do
      with(1) { 100 }
      with(2) { 200 }
      with(_) { 300 }
    end
  end

  def test_values
    [1, 2, 3]
  end
end

class ArrayDecomposition
  extend Patm::DSL

  def manual(obj)
    return 100 unless obj
    return nil unless obj.is_a?(Array)
    return nil if obj.size != 3
    return nil unless obj[0] == 1

    if  obj[2] == 2
      obj[1]
    else
      [obj[1], obj[2]]
    end
  end

  define_matcher :patm do|r|
    _1, _2 = Patm._1, Patm._2
    r.on([1, _1, 2]) {|m| m._1 }
    r.on([1, _1, _2]) {|m| [m._1, m._2] }
    r.on(nil) { 100 }
    r.else { nil }
  end

  def pattern_match(obj)
    match(obj) do
      with(_[1, _1, 2]) { _1 }
      with(_[1, _1, _2]) { [_1, _2] }
      with(nil) { 100 }
      with(_) { nil }
    end
  end

  def test_values
    [
      [],
      [1, 9, 2],
      [1, 9, 3],
      [1, 9, 1],
      [1],
      "foo",
      nil
    ]
  end
end

class VarArray
  extend Patm::DSL

  def manual(obj)
    return nil unless obj.is_a?(Array) && obj.size >= 2 && obj[0] == 1 && obj[1] == 2
    return obj[2..-1]
  end

  define_matcher :patm do|r|
    r.on([1, 2, Patm._xs[1]]) {|m| m[1] }
    r.else { nil }
  end

  def pattern_match(obj)
    match(obj) do
      with(_[1, 2, *_1]) { _1 }
      with(_) { nil }
    end
  end

  def test_values
    [
      nil,
      100,
      [],
      [1, 2],
      [1, 2, 3],
      [1, 2, 3, 4],
      [1, 10, 100],
    ]
  end
end


puts "RUBY_VERSION: #{RUBY_VERSION}"
puts

benchmark SimpleConst, 100000
benchmark ArrayDecomposition, 10000
benchmark VarArray, 10000

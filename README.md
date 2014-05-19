# PATM: PATtern Matcher for Ruby

## Usage

```ruby
require 'patm'
```

```ruby
# With case(simple but slow)
def match(obj)
  p = Patm
  _xs = Patm._xs
  case obj
  when m = Patm.match([:x, p._1, p._2])
    [m._2, m._1]
  when m = Patm.match([1, _xs&p._1])
    m._1
  end
end

match([1, 2, 3])
# => [2, 3]

match([:x, :y, :z])
# => [:z, :y]

match([])
# => nil
```

```ruby
# With DSL
class A
  extend ::Patm::DSL

  define_matcher :match1 do|r|
    p = Patm
    r.on [:x, p._1, p._2] do|m|
      [m._1, m._2]
    end
  end

  define_matcher :match2 do|r|
    r.on [:a, Patm._xs & Patm._1] do|m, _self|
      _self.match1(m._1)
    end
    # ...
  end
end

A.new.match1([:x, 1, 2])
# => [1, 2]
```

```ruby
# With pre-built Rule
rule = Patm::Rule.new do|r|
  p = Patm
  _xs = Patm._xs
  r.on [:x, p._1, p._2] do|m|
    [m._2, m._1]
  end
  r.on [1, _xs&p._1] do|m|
    m._1
  end
end

rule.apply([1,2,3])
# => [2, 3]

rule.apply([:x, :y, :z])
# => [:z, :y]

rule.apply([])
# => nil
```

```ruby
# With cached rules
class A
  def initialize
    @rules = Patm::RuleCache.new
  end

  def match1(obj)
    @rules.match(:match1, obj) do|r|
      p = Patm
      r.on [:x, p._1, p._2] do|m|
        [m._1, m._2]
      end
    end
  end

  def match2(obj)
    @rules.match(:match2, obj) do|r|
      # ...
    end
  end
end
 ```

## Patterns

### Value

Value patterns such as `1, :x, String, ...` matches if `pattern === target_value` is true.

### Array

`[1, 2, _any]` matches `[1, 2, 3]`, `[1, 2, :x]`, etc.

`[1, 2, _xs]` matches `[1, 2]`, `[1, 2, 3]`, `[1, 2, 3, 4]`, etc.

`[1, _xs, 2]` matches `[1, 2]`, `[1, 10, 2]`, etc.

Note: More than one `_xs` in same array is invalid.

### Hash

`{a: 1}` matches `{a: 1}`, `{a: 1, b: 2}`, etc.

`{a: 1, Patm.exact => true}` matches only `{a: 1}`.

`{a: 1, b: Patm.opt(2)}` matches `{a: 1}`, `{a: 1, b: 2}`.

### Capture

`_1`, `_2`, etc matches any value, and capture the value as correspond match group.

`Pattern#[capture_name]` also used for capture.`Patm._any[:foo]` capture any value as `foo`.

Captured values are accessible through `Match#_1, _2, ...` and `Match#[capture_name]`

### Compose

`_1&[_any, _any]` matches any two element array, and capture the array as _1.
`Patm.or(1, 2)` matches 1 or 2.


## Performance

see [benchmark code](./benchmark/comparison.rb) for details

```
# MacBook Air(Late 2010) C2D 1.8GHz, OS X 10.9.2

RUBY_VERSION: 2.0.0

Benchmark: SimpleConst
                    user     system      total        real
manual          0.160000   0.000000   0.160000 (  0.159555)
patm            1.020000   0.000000   1.020000 (  1.053630)
patm_case       1.800000   0.000000   1.800000 (  1.941674)
pattern_match  23.430000   0.210000  23.640000 ( 28.264229)

Benchmark: ArrayDecomposition
                    user     system      total        real
manual          0.050000   0.000000   0.050000 (  0.051879)
patm            0.400000   0.000000   0.400000 (  0.410650)
patm_case       2.080000   0.010000   2.090000 (  2.255956)
pattern_match  16.760000   0.160000  16.920000 ( 19.039155)

Benchmark: VarArray
                    user     system      total        real
manual          0.060000   0.000000   0.060000 (  0.070630)
patm            0.330000   0.000000   0.330000 (  0.370033)
patm_case       1.700000   0.000000   1.700000 (  1.766639)
pattern_match  13.500000   0.170000  13.670000 ( 20.414078)
```


## Changes

### 2.0.1

- Bugfix: About pattern `Patm._1 & Array`.
- Bugfix: Compiler bug fix.

### 2.0.0

- Named capture
- Patm::GROUPS is obsolete. Use `pattern[number_or_name]` or `Patm._1, _2, ...` instead.
- More optimize for compiled pattern.
- Hash patterns

### 1.0.0

- DSL
- Compile is enabled by default
- Change interface

### 0.1.0

- Faster matching with pattern compilation
- Fix StackOverflow bug for `[Patm.or()]`

### 0.0.1

- Initial release


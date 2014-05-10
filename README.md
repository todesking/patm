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


## Changes

### 2.0.1(unreleased)

- Bugfix: About pattern `Patm._1 & Array`.

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


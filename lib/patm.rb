module Patm
  class Pattern

    def self.build_from(plain)
      case plain
      when Pattern
        plain
      when ::Array
        array = plain.map{|a| build_from(a)}
        rest_index = array.index(&:rest?)
        if rest_index
          head = array[0...rest_index]
          rest = array[rest_index]
          tail = array[(rest_index+1)..-1]
          Arr.new(head, rest, tail)
        else
          Arr.new(array)
        end
      when ::Hash
        Hash.new(
          plain.each_with_object({}) do|(k, v), h|
            h[k] = build_from(v) if k != Patm.exact
          end,
          plain[Patm.exact]
        )
      else
        Obj.new(plain)
      end
    end

    # Use in Hash pattern.
    def opt
      Opt.new(self)
    end

    def execute(match, obj); true; end

    def opt?
      false
    end

    def rest?
      false
    end

    def &(rhs)
      And.new([self, rhs])
    end

    def [](name)
      self & Named.new(name)
    end

    def compile
      src, context, _ = self.compile_internal(0)

      Compiled.new(self.inspect, src || "true", context)
    end

    # free_index:Numeric -> target_name:String -> [src:String|nil, context:Array, free_index:Numeric]
    # variables: _ctx, _match, (target_name)
    def compile_internal(free_index, target_name = "_obj")
      [
        "_ctx[#{free_index}].execute(_match, #{target_name})",
        [self],
        free_index + 1
      ]
    end

    class Compiled < self
      def initialize(desc, src, context)
        @desc = desc
        @context = context
        singleton_class = class <<self; self; end
        @src = <<-RUBY
        def execute(_match, _obj)
          _ctx = @context
#{src}
        end
        RUBY
        singleton_class.class_eval(@src)
      end

      attr_reader :src

      def compile_internal(free_index, target_name = "_obj")
        raise "Already compiled"
      end
      def inspect; "<compiled>#{@desc}"; end
    end

    class Hash < self
      def initialize(hash, exact)
        @pat = hash
        @exact = exact
        @non_opt_count = @pat.values.count{|v| !v.opt? }
      end
      def execute(match, obj)
        return false unless obj.is_a?(::Hash)
        obj.size >= @non_opt_count &&
          (!@exact || obj.keys.all?{|k| @pat.has_key?(k) }) &&
          @pat.all? {|k, pat|
            if obj.has_key?(k)
              pat.execute(match, obj[k])
            else
              pat.opt?
            end
          }
      end
      def inspect; @pat.inspect; end
      def compile_internal(free_index, target_name = "_obj")
        super # TODO
      end
    end

    class Opt < self
      def initialize(pat)
        @pat = pat
      end
      def opt?
        true
      end
      def execute(match, obj)
        @pat.execute(match, obj)
      end
      def inspect; "?#{@pat.inspect}"; end
      def compile_internal(free_index, target_name = "_obj")
        super # TODO
      end
    end

    class Arr < self
      def initialize(head, rest = nil, tail = [])
        @head = head
        @rest = rest
        @tail = tail
      end

      def execute(mmatch, obj)
        size_min = @head.size + @tail.size
        return false unless obj.is_a?(Array)
        return false unless @rest ? (obj.size >= size_min) :  (obj.size == size_min)
        @head.zip(obj[0..(@head.size - 1)]).all? {|pat, o|
          pat.execute(mmatch, o)
        } &&
        @tail.zip(obj[(-@tail.size)..-1]).all? {|pat, o|
          pat.execute(mmatch, o)
        } &&
        (!@rest || @rest.execute(mmatch, obj[@head.size..-(@tail.size+1)]))
      end

      def inspect
        if @rest
          (@head + [@rest] + @tail).inspect
        else
          (@head + @tail).inspect
        end
      end

      def compile_internal(free_index, target_name = "_obj")
        i = free_index
        srcs = []
        ctxs = []

        srcs << "#{target_name}.is_a?(::Array)"

        size_min = @head.size + @tail.size
        if @rest
          srcs << "#{target_name}.size >= #{size_min}"
        else
          srcs << "#{target_name}.size == #{size_min}"
        end

        elm_target_name = "#{target_name}_elm"
        @head.each_with_index do|h, hi|
          s, c, i = h.compile_internal(i, elm_target_name)
          srcs << "(#{elm_target_name} = #{target_name}[#{hi}]; #{s})" if s
          ctxs << c
        end

        unless @tail.empty?
          srcs << "(#{target_name}_t = #{target_name}[(-#{@tail.size})..-1]; true)"
          @tail.each_with_index do|t, ti|
            s, c, i = t.compile_internal(i, elm_target_name)
            srcs << "(#{elm_target_name} = #{target_name}_t[#{ti}]; #{s})" if s
            ctxs << c
          end
        end

        if @rest
          tname = "#{target_name}_r"
          s, c, i = @rest.compile_internal(i, tname)
          srcs << "(#{tname} = #{target_name}[#{@head.size}..-(#{@tail.size+1})];#{s})" if s
          ctxs << c
        end

        [
          srcs.compact.map{|s| "(#{s})"}.join(" &&\n"),
          ctxs.flatten(1),
          i
        ]
      end
    end

    class ArrRest < self
      def execute(mmatch, obj)
        true
      end
      def rest?
        true
      end
      def inspect; "..."; end
      def compile_internal(free_index, target_name = "_obj")
        [
          nil,
          [],
          free_index
        ]
      end
    end

    class Obj < self
      def initialize(obj)
        @obj = obj
      end

      def execute(mmatch, obj)
        @obj === obj
      end

      def inspect
        "OBJ(#{@obj.inspect})"
      end

      def compile_internal(free_index, target_name = "_obj")
        [
          "_ctx[#{free_index}] === #{target_name}",
          [@obj],
          free_index + 1,
        ]
      end
    end

    class Any < self
      def execute(match, obj); true; end
      def inspect; 'ANY'; end
      def compile_internal(free_index, target_name = "_obj")
        [
          nil,
          [],
          free_index
        ]
      end
    end

    class Named < self
      def initialize(name)
        raise ::ArgumentError unless name.is_a?(Symbol) || name.is_a?(Numeric)
        @name = name
      end
      attr_reader :name
      alias index name # compatibility
      def execute(match, obj)
        match[@name] = obj
        true
      end
      def inspect; "NAMED(#{@name})"; end
      def compile_internal(free_index, target_name = "_obj")
        [
          "_match[#{@name.inspect}] = #{target_name}; true",
          [],
          free_index
        ]
      end
    end

    class LogicalOp < self
      def initialize(pats, op_str)
        @pats = pats
        @op_str = op_str
      end
      def compile_internal(free_index, target_name = "_obj")
        srcs = []
        i = free_index
        ctxs = []
        @pats.each do|pat|
          s, c, i = pat.compile_internal(i, target_name)
          srcs << s
          ctxs << c
        end

        [
          srcs.compact.map{|s| "(#{s})" }.join(" #{@op_str}\n"),
          ctxs.flatten(1),
          i
        ]
      end
      def rest?
        @pats.any?(&:rest?)
      end
      def opt?
        @pats.any?(&:opt?)
      end
    end

    class Or < LogicalOp
      def initialize(pats)
        super(pats, '||')
      end
      def execute(mmatch, obj)
        @pats.any? do|pat|
          pat.execute(mmatch, obj)
        end
      end
      def inspect
        "OR(#{@pats.map(&:inspect).join(',')})"
      end
    end

    class And < LogicalOp
      def initialize(pats)
        super(pats, '&&')
      end
      def execute(mmatch, obj)
        @pats.all? do|pat|
          pat.execute(mmatch, obj)
        end
      end
      def inspect
        "AND(#{@pats.map(&:inspect).join(',')})"
      end
    end
  end

  def self.or(*pats)
    Pattern::Or.new(pats.map{|p| Pattern.build_from(p) })
  end

  def self._any
    @any ||= Pattern::Any.new
  end

  def self._xs
    @xs = Pattern::ArrRest.new
  end

  EXACT = Object.new
  def EXACT.inspect
    "EXACT"
  end
  # Use in Hash pattern.
  # Specify exact match or not.
  def self.exact
    EXACT
  end

  PREDEF_GROUP_SIZE = 100

  class <<self
    PREDEF_GROUP_SIZE.times do|i|
      define_method "_#{i}" do
        Pattern::Named.new(i)
      end
    end
  end

  def self.match(plain_pat)
    CaseBinder.new Pattern.build_from(plain_pat)
  end

  class Rule
    def initialize(compile = true, &block)
      @compile = compile
      # { Pattern => Proc }
      @rules = []
      @else = ->(obj){nil}
      block[self]
    end

    def on(pat, &block)
      if @compile
        @rules << [Pattern.build_from(pat).compile, block]
      else
        @rules << [Pattern.build_from(pat), block]
      end
    end

    def else(&block)
      @else = block
    end

    def apply(obj, _self = nil)
      match = Match.new
      @rules.each do|(pat, block)|
        if pat.execute(match, obj)
          return block.call(match, _self)
        end
      end
      @else[obj, _self]
    end
  end

  class RuleCache
    def initialize(compile = true)
      @compile = compile
      @rules = {}
    end
    def match(rule_name, obj, _self = nil, &rule)
      (@rules[rule_name] ||= ::Patm::Rule.new(@compile, &rule)).apply(obj, _self)
    end
  end

  class Match
    def initialize
      @group = {}
    end

    def [](i)
      @group[i]
    end

    def []=(i, val)
      @group[i] = val
    end

    PREDEF_GROUP_SIZE.times.each do|i|
      define_method "_#{i}" do
        self[i]
      end
    end
  end

  class CaseBinder
    def initialize(pat)
      @pat = pat
      @match = Match.new
    end

    def ===(obj)
      @pat.execute(@match, obj)
    end

    def [](i); @match[i]; end
    PREDEF_GROUP_SIZE.times do|i|
      define_method "_#{i}" do
        @match[i]
      end
    end
  end

  module DSL
    def define_matcher(name, &rule)
      @patm_rules ||= RuleCache.new
      rules = @patm_rules
      define_method name do|obj|
        rules.match(name, obj, self, &rule)
      end
    end
  end
end

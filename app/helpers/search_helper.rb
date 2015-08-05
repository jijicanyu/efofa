class String
  def and(a)
    #"( #{self} && #{a} )"
    "( #{self} && #{a} )"
  end

  def or(a)
    "( #{self} || #{a} )"
  end

  def query_escape
    v = self
    tr = %w'\\ + - = & | > < ! ( ) { } [ ] ^ " ~ * ? : /'
    tr.each{|t|
      v = v.gsub(t, "\\#{t}")
    }
    v
  end
end

module SearchHelper

  require 'parslet'

  class QueryParser < Parslet::Parser
    rule(:space) { match('\s').repeat(1) }
    rule(:space?) { space.maybe }
    rule(:left_parenthesis) { str('(') }
    rule(:right_parenthesis) { str(')') }

    # Comparisons
    rule(:eq) { str('=') }
    rule(:not_eq) { str('!=') }
    rule(:matches) { str('~=') }
    rule(:lt) { str('<') }
    rule(:lteq) { str('<=') }
    rule(:gt) { str('>') }
    rule(:gteq) { str('>=') }

    # Operators
    rule(:and_operator) { str('&&') }
    rule(:or_operator) { str('||') }

    # Operand
    rule(:null) { str("null").as(:nil) }
    rule(:boolean) { str("true").as(:boolean) | str("false").as(:boolean) }
    rule(:number) { match('[-+]?([0-9]*\.)?[0-9]').repeat(1).as(:number) }
    rule(:double_quote_string) do
      str('"') >>
          (
          (str('\\') >> any) |
              (str('"').absent? >> any)
          ).repeat.as(:string) >>
          str('"')
    end
    rule(:literal) { match('[a-zA-Z0-9\-_]').repeat(1) }
    rule(:identifier) { null | boolean | number | double_quote_string | literal.as(:string) }

    # Grammar
    rule(:compare_eq) { (literal.as(:left) >> space? >> eq >> space? >> identifier.as(:right)).as(:eq) }
    rule(:compare_not_eq) { (literal.as(:left) >> space? >> not_eq >> space? >> identifier.as(:right)).as(:not_eq) }
    rule(:compare_matches) { (literal.as(:left) >> space? >> matches >> space? >> identifier.as(:right)).as(:matches) }
    rule(:compare_lt) { (literal.as(:left) >> space? >> lt >> space? >> identifier.as(:right)).as(:lt) }
    rule(:compare_lteq) { (literal.as(:left) >> space? >> lteq >> space? >> identifier.as(:right)).as(:lteq) }
    rule(:compare_gt) { (literal.as(:left) >> space? >> gt >> space? >> identifier.as(:right)).as(:gt) }
    rule(:compare_gteq) { (literal.as(:left) >> space? >> gteq >> space? >> identifier.as(:right)).as(:gteq) }

    rule(:compare) { compare_eq | compare_not_eq | compare_matches | compare_lteq | compare_lt | compare_gteq | compare_gt }

    rule(:primary) { left_parenthesis >> space? >> or_operation >> space? >> right_parenthesis | compare }
    rule(:and_operation) { (primary.as(:left) >> space? >> and_operator >> space? >> and_operation.as(:right)).as(:and) | primary }
    rule(:or_operation) { (and_operation.as(:left) >> space? >> or_operator >> space? >> or_operation.as(:right)).as(:or) | and_operation }

    root :or_operation
  end

  class ElasticProcessor
    def self.parse(query)
      instance = self.new()
      instance.parse(query)
    end

    def parse(query)
      begin
        ast = QueryParser.new.parse(query)
        process(ast)
      rescue Parslet::ParseFailed => error
        raise Parslet::ParseFailed, error
        #pp "ParseError" + error.inspect
      end
    end

    def process(ast)
      operation = ast.keys.first
      self.send("process_#{operation}".to_sym, ast[operation]) if self.respond_to?("process_#{operation}".to_sym, true)
    end

    protected

    def check_column!(value)
      indexed = %w|title header body host ip domain lastupdatetime|
      unless indexed.include?(value)
        source = Parslet::Source.new(value.to_s)
        cause = Parslet::Cause.new('Column not found', source, value.offset, [])
        raise Parslet::ParseFailed.new('Column not found', cause)
      end
    end
    def process_and(ast)
      process(ast[:left]).and(process(ast[:right]))
    end

    def process_or(ast)
      process(ast[:left]).or(process(ast[:right]))
    end

    def process_eq(ast)
      check_column!(ast[:left])
      "#{ast[:left]}:(*#{parse_value(ast[:right]).query_escape}*)"
      #table[ast[:left].to_sym].eq(parse_value(ast[:right]))
    end

    def process_not_eq(ast)
      check_column!(ast[:left])
      "-#{ast[:left]}:(*#{parse_value(ast[:right]).query_escape}*)"
      #table[ast[:left].to_sym].not_eq(parse_value(ast[:right]))
    end

    def process_matches(ast)
      check_column!(ast[:left])
      table[ast[:left].to_sym].matches(parse_value(ast[:right]))
    end

    def process_lt(ast)
      check_column!(ast[:left])
      table[ast[:left].to_sym].lt(parse_value(ast[:right]))
    end

    def process_lteq(ast)
      check_column!(ast[:left])
      table[ast[:left].to_sym].lteq(parse_value(ast[:right]))
    end

    def process_gt(ast)
      check_column!(ast[:left])
      "#{ast[:left]}:([\"#{parse_value(ast[:right]).query_escape}\" TO *])"
    end

    def process_gteq(ast)
      check_column!(ast[:left])
      table[ast[:left].to_sym].gteq(parse_value(ast[:right]))
    end

    def parse_value(value)
      type = value.keys.first
      case type
        when :nil
          return nil
        when :boolean
          return value[:boolean] == "true"
        else
          return value[type].to_s
      end
    end
  end
end

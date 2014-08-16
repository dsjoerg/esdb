# Load our fancy ApiFields grammar from lib/api_fields.treetop
Treetop.load('lib/api_fields')

# And monkey patch SyntaxNode, making Baby Jesus cry.
class Treetop::Runtime::SyntaxNode
  def to_ah
    if elements && elements.any?
      if elements.any?
        er = elements.collect{|e|
          e.respond_to?(:to_ah) ? e.to_ah : nil
        }
        # comma, skip
        if er[0].nil?
          er[1]
        else
          _er = {}
          er.each{|k| _er.merge!(k)}
          _er
        end        
      end
    end
  end
end

# ApiFields is defined by the treetop grammar and we'll gather our support
# classes within it.
#
# This is supposed to take care of all our "partial response"; inclusion/
# exclusion needs, within the API.
#
# Note: I originally designed this to intersect against the response, but had
# to modify the approach as mentioned below.
#
# Key points about our API implementation here:
# * We do not want to generate the full object tree and run exclusion/inclusion
#   against generation at runtime.
# * We default to include a key, which is why I've added the minus prefix to
#   exclude within the tree.
# * Because we're not intersecting, we have one global syntax that orients on
#   the object. So wherever there's a match in the structure, it will use what
#   has been defined in root(match) because we check fields.match.* directly in
#   Match#to_builder
#
#   You can not yet exclude e.g. Identity globally and re-include it elsewhere
#   like so:
#   fields=-identity,match(entities(+identity))
#
#   But that can be added, if necessary.
#
# Examples:
#
# fields=entity(-summary)
# Will not include summary within entities. Note that this will not work:
# fields=match(entities(-summary))
# because the check is within Entity#to_builder, checking for entity.summary?
#
# Important:
# There is at least one "special" fields used in the models currently, this
# should be consolidated and named appropriately (TODO, HAX): "graphs"
# which will be checked for all graph related keys (armygraph, data, etc.)
# (grep away for fields\.graphs)
#
# It can also still be used in it's original purpose, intersecting the tree:
# hash = (hash.stringify_keys & ApiFields::Parser.parse(params[:fields]).tree)

module ApiFields
  class Parser
    def self.parse(str)
      str = "root(#{str})"
      parser = ApiFieldsParser.new
      tree = parser.parse(str)

      return Matcher.new(tree.to_ah['root'])
    end
  end
  
  # Returns a blank object so we can safely chain up on non-existing keys
  # in the Matcher below, not requiring us to check for nil each step, like so:
  #
  # This defaults to true, because we include everything by default.
  #
  # af = ApiFields::Parser.parse('wtf(rofl(copter))')
  # af.this.obviously.does.not.exist?
  # => true
  class Blank
    def method_missing(method, *args)
      if method.to_s =~ /\?$/
        return true
      else
        return Matcher.new({})
      end
    end
  end

  # Matcher takes a tree from the parser and gives us an object to check for
  # matches within it, taking care of all the checks so we don't have to.
  class Matcher
    attr_accessor :tree

    @@blanker = Blank.new
    def blank
      @@blanker
    end

    def initialize(tree)
      @tree = tree
    end
    
    def method_missing(method, *args)
      # This allows us to traverse the matched tree like so:
      #
      # af = ApiFields::Parser.parse('wtf(rofl(copter))')
      # af.wtf.rofl.copter?
      return Matcher.new(tree[method.to_s]) if tree.respond_to?(:[]) && tree[method.to_s]
      
      if method.to_s =~ /\?$/
        method_clean = method.to_s.scan(/^(.*?)\?$/).flatten.join.to_s
        return (tree === false || tree[method_clean] == false) ? false : true
      end

      blank
    end
  end
end
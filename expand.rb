#!/usr/bin/env ruby

# Formal language expansion script.
#
# Pipe input to it, or pass it a list of files with rules and it will
# produce a single result. To achieve multiple results (as is
# typically desired), pass a switch with a number. e.g.:
# % cat spark.txt | ./expand -100
# or
# % ./expand -100 male-name.txt alphabet.txt
#
# Mar 2002  Greg McIntyre  <greg@puyo.cjb.net>
#   * Initial version.
#
# Aug 2002  Gavin Sinclair  <gsinclair@soyabean.com.au>
#   * Refactored and simplified many overly verbose bits.
#
# Aug 2002  Greg McIntyre  <greg@puyo.cjb.net>
#   * Simplified a little more.
#   * Made to_s versions of Rule and RuleSet look nicer.
#   * Put classes in a module.

# --------------------------------------------------------------------

module Expander
  # A set of formal language rules.
  class RuleSet
    # Used to identify keywords in sentences for expansion.
    KEYWORD_RE = /\{(\w+)\}/

    # Make an empty rule set or read definitions from the
    # specified file.
    def initialize(file = nil)
      @rules = {}
      parse(file) if file
    end

    # Evaluate sentence using ruleset, to the exhaustion of all
    # rules.
    def evaluate(sentence)
      result = sentence.dup
      result = apply(result) until complete(result)
      result[0, 1].capitalize + result[1, result.size]
    end

    # Add a replacement for the given keyword.
    def add_replacement(keyword, replacement)
      @rules[keyword] ||= Rule.new(keyword)
      @rules[keyword] << replacement
    end

    # Load rules from input.
    def parse(file)
      file.each_line do |line|
        keyword, replacement = line.strip.split(/\s*-->\s*/)
        if keyword && replacement
          add_replacement(keyword, replacement)
        end
      end
    end

    # Print internal representation.
    def to_s
      @rules.values.join("\n")
    end

    private # ---------------------------

    # Replace all occurances of keywords in string using appropriate
    # rules.
    def apply(string)
      # Replace {...} using appropriate rule.  Leave any unknown
      # keywords as they are.
      string.gsub(KEYWORD_RE).each do
        keyword = Regexp.last_match[1]
        if @rules[keyword]
          @rules[keyword].random_replacement
        else
          '[ ' + keyword + ' ]'
        end
      end
    end

    # True iff a string has any more keywords.
    def complete(sentence)
      sentence !~ KEYWORD_RE
    end
  end # class RuleSet

  # --------------------------------------------------------------------

  # A formal language rule, mapping a keyword to something else. Has
  # a set of possible replacements for keyword.
  # keyword --> replacement 1
  # keyword --> replacement 2
  # ...
  # keyword --> replacement n
  class Rule
    def initialize(keyword)
      @keyword = keyword
      @replacements = []
    end

    # Add a possible replacement for this rule's keyword.
    def <<(replacement)
      @replacements << replacement
    end

    def random_replacement
      @replacements[rand(@replacements.size)] ||
        raise("Rule has no replacement: #{@keyword}")
    end

    def to_s
      result = "#{@keyword} --> "
      result << @replacements.map(&:to_s).join("\n#{' ' * result.size}")
      result
    end
  end # class Rule
end

# --------------------------------------------------------------------
# Main

# Read arguments.
iterations = 1
if ARGV[0].match(/^-\d+$/)
  # Beware possible octal/hex conversion!
  iterations = -ARGV.shift.to_i
  iterations = 1 if iterations < 1
end

# Spit out sentences.
ruleset = Expander::RuleSet.new(ARGF)

iterations.times do
  puts ruleset.evaluate('{SENTENCE}')
end

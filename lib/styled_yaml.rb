# The MIT License
# 
# Copyright 2012 Mislav Marohnić <mislav.marohnic@gmail.com>.
# Copyright 2014 Jakub Jirutka <jakub@jirutka.cz>.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'psych'
require 'stringio'

# A Psych extension to enable choosing output styles for specific objects.
#
# Thanks to Tenderlove for help in <http://stackoverflow.com/q/9640277/11687>.
#
# Example:
#
#   data = {
#     response: { body: StyledYAML.literal(json_string), status: 200 },
#     person: StyledYAML.inline({ 'name' => 'Stevie', 'age' => 12 }),
#     array: StyledYAML.inline(%w[ apples bananas oranges ])
#   }
#
#   StyledYAML.dump(data, $stdout)
#

module StyledYAML

  # http://www.yaml.org/spec/1.2/spec.html#id2795688
  module LiteralScalar
    def yaml_style
      Psych::Nodes::Scalar::LITERAL
    end
  end

  # http://www.yaml.org/spec/1.2/spec.html#id2796251
  module FoldedScalar
    def yaml_style
      Psych::Nodes::Scalar::FOLDED
    end
  end

  # http://www.yaml.org/spec/1.2/spec.html#id2790832
  module FlowMapping
    def yaml_style
      Psych::Nodes::Mapping::FLOW
    end
  end

  # http://www.yaml.org/spec/1.2/spec.html#id2790320
  module FlowSequence
    def yaml_style
      Psych::Nodes::Sequence::FLOW
    end
  end


  # Custom tree builder class to recognize scalars tagged with `yaml_style`
  class TreeBuilder < Psych::TreeBuilder

    attr_writer :next_seq_or_map_style

    def next_seq_or_map_style(default_style)
      style = @next_seq_or_map_style || default_style
      @next_seq_or_map_style = nil
      style
    end

    def scalar(value, anchor, tag, plain, quoted, style)
      if style_any?(style) && value.respond_to?(:yaml_style)
        if style_literal_or_folded? value.yaml_style
          plain = false
          quoted = true
        end
        style = value.yaml_style
      end
      super
    end

    def style_any?(style)
      Psych::Nodes::Scalar::ANY == style
    end

    def style_literal_or_folded?(style)
      [Psych::Nodes::Scalar::LITERAL, Psych::Nodes::Scalar::FOLDED].include?(style)
    end

    [:sequence, :mapping].each do |type|
      class_eval <<-RUBY
        def start_#{type}(anchor, tag, implicit, style)
          style = next_seq_or_map_style(style)
          super
        end
      RUBY
    end
  end

  # Custom tree class to handle Hashes and Arrays tagged with `yaml_style`.
  class YAMLTree < Psych::Visitors::YAMLTree
    [:Hash, :Array, :Psych_Set, :Psych_Omap].each do |klass|
      class_eval <<-RUBY
        def visit_#{klass}(o)
          if o.respond_to? :yaml_style
            @emitter.next_seq_or_map_style = o.yaml_style
          end
          super
        end
      RUBY
    end
  end


  # Tag string to be output using literal style.
  def self.literal(str)
    str.extend(LiteralScalar)
    str
  end

  # Tag string to be output using folded style.
  def self.folded(str)
    str.extend(FoldedScalar)
    str
  end

  # Tag Hashe or Array to be output all on one line.
  def self.inline(obj)
    case obj
    when Hash
      obj.extend(FlowMapping)
    when Array
      obj.extend(FlowSequence)
    else
      warn "#{self}: unrecognized type to inline (#{obj.class.name})"
    end
    obj
  end

  # A Psych.dump alternative that uses the custom TreeBuilder
  def self.dump(obj, io = nil, options = {})
    real_io = io || StringIO.new(''.encode('utf-8'))
    visitor = YAMLTree.new(options, TreeBuilder.new)

    visitor << obj
    ast = visitor.tree

    begin
      ast.yaml(real_io)
    rescue
      # The `yaml` method was introduced in later versions, so fall back to
      # constructing a visitor
      Psych::Visitors::Emitter.new(real_io).accept(ast)
    end

    io || real_io.string
  end
end

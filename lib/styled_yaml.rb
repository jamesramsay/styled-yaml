# frozen_string_literal: true

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

  # https://yaml.org/spec/1.2/spec.html#id2788097
  module SingleQuotedScalar
    def yaml_style
      Psych::Nodes::Scalar::SINGLE_QUOTED
    end
  end

  # https://yaml.org/spec/1.2/spec.html#id2787109
  module DoubleQuotedScalar
    def yaml_style
      Psych::Nodes::Scalar::DOUBLE_QUOTED
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
      if value.respond_to?(:yaml_style)
        if style_literal_or_folded? value.yaml_style
          plain = false
          quoted = true
        end
        style = value.yaml_style
      end
      super
    end

    def style_literal_or_folded?(style)
      [Psych::Nodes::Scalar::LITERAL, Psych::Nodes::Scalar::FOLDED].include?(style)
    end

    %I[sequence mapping].each do |type|
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
    %I[Hash Array Psych_Set Psych_Omap].each do |klass|
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

  # Tag string to be output using single quoted style.
  def self.single_quoted(str)
    str.extend(SingleQuotedScalar)
    str
  end

  # Tag string to be output using double quoted style.
  def self.double_quoted(str)
    str.extend(DoubleQuotedScalar)
    str
  end

  # Tag Hash or Array to be output all on one line.
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
    visitor = YAMLTree.create(options, TreeBuilder.new)

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

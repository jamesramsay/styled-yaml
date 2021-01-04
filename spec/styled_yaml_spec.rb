# frozen_string_literal: true

require_relative '../lib/styled_yaml'

RSpec.describe StyledYAML do
  jabberwocky = 'Beware the Jabberwock, my son!'

  walrus = [
    'The sun was shining on the sea,',
    'Shining with all his might:',
    'He did his very best to make',
    'The billows smooth and bright--',
    'And this was odd, because it was',
    'The middle of the night.'
  ].join("\n") + "\n"

  pigs = [
    '\"The time has come,\" the Walrus said,',
    'To talk of many things:',
    'Of shoes--and ships--and sealing-wax--',
    'Of cabbages--and kings--',
    'And why the sea is boiling hot--',
    'And whether pigs have wings.\"'
  ].join("\n") + "\n"

  describe '#literal' do
    it 'dump returns Literal Scalar' do
      data = { 'walrus' => StyledYAML.literal(+walrus) }
      expected_output = <<~YAML
        ---
        walrus: |
          The sun was shining on the sea,
          Shining with all his might:
          He did his very best to make
          The billows smooth and bright--
          And this was odd, because it was
          The middle of the night.
      YAML
      expect(StyledYAML.dump(data)).to eq(expected_output)
    end
  end

  describe '#folded' do
    it 'dump returns Folded Scalar' do
      data = { 'walrus' => StyledYAML.folded(+walrus) }
      expected_output = <<~YAML
        ---
        walrus: >
          The sun was shining on the sea,

          Shining with all his might:

          He did his very best to make

          The billows smooth and bright--

          And this was odd, because it was

          The middle of the night.
      YAML
      expect(StyledYAML.dump(data)).to eq(expected_output)
    end
  end

  describe '#double_quoted' do
    it 'dump returns Double Quoted Scalar' do
      data = { 'jabberwocky' => StyledYAML.double_quoted(+jabberwocky) }
      expected_output = <<~YAML
        ---
        jabberwocky: "Beware the Jabberwock, my son!"
      YAML
      expect(StyledYAML.dump(data)).to eq(expected_output)
    end
  end

  describe '#single_quoted' do
    it 'dump returns Single Quoted Scalar' do
      expected_output = <<~YAML
        ---
        jabberwocky: 'Beware the Jabberwock, my son!'
      YAML
      data = { 'jabberwocky' => StyledYAML.single_quoted(+jabberwocky) }
      expect(StyledYAML.dump(data)).to eq(expected_output)
    end
  end

  describe '#inline' do
    it 'dump returns Flow Mapping for Hash' do
      data = { 'example': StyledYAML.inline('name' => 'Steve', 'age' => 24) }
      expect(StyledYAML.dump(data)).to eq("---\n:example: {name: Steve, age: 24}\n")
    end

    it 'dump returns Flow Sequence for Array' do
      data = { 'example': StyledYAML.inline(%w[apples bananas oranges]) }
      expect(StyledYAML.dump(data)).to eq("---\n:example: [apples, bananas, oranges]\n")
    end
  end
end

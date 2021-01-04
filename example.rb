# frozen_string_literal: true

require 'styled-yaml'
require 'yaml'

recipe = {
  'name' => StyledYAML.double_quoted(+'Fruit Salad'),
  'link' => StyledYAML.single_quoted(+'http://bad.recipes/salad'),
  'ingredients' => StyledYAML.inline(%w[apple pear orange]),
  'steps' => StyledYAML.literal(+<<~STEPS
    1. Dice the fruit into bit size pieces.
    1. Combine the fruit in a bowl.
    1. Enjoy!
  STEPS
  )
}

puts YAML.dump(recipe)
puts StyledYAML.dump(recipe)

# 💄 styled-yaml

A Psych extension to enable choosing output styles for specific objects.

## Usage

```ruby
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
```

```yaml
---
name: Fruit Salad
link: http://bad.recipes/salad
ingredients:
- apple
- pear
- orange
steps: |
  1. Dice the fruit into bit size pieces.
  1. Combine the fruit in a bowl.
  1. Enjoy!
---
name: "Fruit Salad"
link: 'http://bad.recipes/salad'
ingredients: [apple, pear, orange]
steps: |
  1. Dice the fruit into bit size pieces.
  1. Combine the fruit in a bowl.
  1. Enjoy!
```

## Acknowledgments

- [@mislav](https://github.com/mislav) for the [original implementation](https://gist.github.com/mislav/2023978)
  and [@tenderlove](https://github.com/tenderlove) for the [help](http://stackoverflow.com/q/9640277/11687)
- [@jirkuta](https://gist.github.com/jirutka) for [improvements](https://gist.github.com/jirutka/31b1a61162e41d5064fc)

{Vec2d} = require('./vec2d')

exports.Spritesheet = class Spritesheet
  # a list of objects that have a .size and a .filename
  constructor: (@image_list) ->

  # figure out where to place each image in the sprite sheet
  # sets the .pos such that they are in a spritesheet
  calculatePositions: ->
    # reverse sort by height, filename
    @image_list.sort (a, b) ->
      diff = b.size.y - a.size.y
      if diff is 0
        if b.filename > a.filename then 1 else -1
      else
        diff

    @size = new Vec2d()
    positions = []

    for image, image_i in @image_list
      image.pos = do =>
        for pos, pos_i in positions
          intersects = do =>
            return true if pos.x + image.size.x >= @size.x
            return true if pos.y + image.size.y >= @size.y
            for i in [0...image_i]
              placed = @image_list[i]
              unless placed.pos.x + placed.size.x <= pos.x or \
                     placed.pos.x >= pos.x + image.size.x or \
                     placed.pos.y + placed.size.y <= pos.y or \
                     placed.pos.y >= pos.y + image.size.y
                return true
            return false
          if not intersects
            positions.splice pos_i, 1
            return pos
        # expand right
        return new Vec2d(@size.x, 0)

      if (y = image.pos.y + image.size.y) < @size.y
        positions.push new Vec2d(image.pos.x, y)
        # keep positions sorted by x
        positions.sort (a, b) -> a.x - b.x

      @size.boundMin(image.pos.plus(image.size))

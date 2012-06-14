class Vec2d
  constructor: (@x=0, @y=0) ->
  offset: (dx, dy) -> new Vec2d(@x + dx, @y + dy)
  plus: (other) -> @offset(other.x, other.y)
  minus: (other) -> @offset(-other.x, -other.y)
  scale: (scalar) ->
    @x *= scalar
    @y *= scalar
    this
  scaled: (scalar) -> @clone().scale(scalar)
  clone: -> new Vec2d(@x, @y)
  apply: (func) ->
    @x = func(@x)
    @y = func(@y)
    this
  applied: (func) -> @clone().apply(func)
  distanceTo: (other) ->
    dx = other.x - @x
    dy = other.y - @y
    Math.sqrt(dx * dx + dy * dy)
  equals: (other) -> @x is other.x and @y is other.y
  toString: -> "(#{@x}, #{@y})"
  lengthSqrd: -> @x * @x + @y * @y
  length: -> Math.sqrt(@lengthSqrd())
  angle: -> if @lengthSqrd is 0 then 0 else Math.atan2(@y, @x)
  normalize: ->
    length = @length()
    if length is 0
      this
    else
      @scale 1 / length
  normalized: -> @clone().normalize()
  boundMin: (other) ->
    if @x < other.x then @x = other.x
    if @y < other.y then @y = other.y
  boundMax: (other) ->
    if @x > other.x then @x = other.x
    if @y > other.y then @y = other.y

exports?.Vec2d = Vec2d

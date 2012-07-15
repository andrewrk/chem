#depend "chem"

{Vec2d, Engine, Sprite, Batch, Button} = Chem

randInt = (min, max) -> Math.floor(min + Math.random() * (max - min + 1))

Control =
  MoveLeft: 0
  MoveRight: 1
  MoveUp: 2
  MoveDown: 3

class Thing
  constructor: (@x, @y, @dx, @dy, @sprite) ->
    @gone = false

  delete: ->
    @gone = true
    if @sprite?
      @sprite.delete()
      @sprite = null

class Game
  constructor: (@engine) ->
    @hadGameOver = false
    @stars = []
    @meteors = []
    @batch = new Batch()
    @img_star = [
      'star'
      'star2'
    ]
    @img_meteor = [
      'meteor'
      'meteor2'
    ]
    @sprite_ship = new Sprite('ship', batch:@batch)

    @nextMeteorInterval = 0.3
    @nextMeteor = @nextMeteorInterval

    @controls = {}
    @controls[Control.MoveLeft] = Button.Key_Left
    @controls[Control.MoveRight] = Button.Key_Right
    @controls[Control.MoveUp] = Button.Key_Up
    @controls[Control.MoveDown] = Button.Key_Down

    @ship_x = 0
    @ship_y = @engine.size.y / 2
    @ship_dx = 0
    @ship_dy = 0

    @score = 0


  garbage: =>
    @stars = (star for star in @stars when not star.gone)

  createStar: =>
    @stars.push(new Thing(@engine.size.x, randInt(0, @engine.size.y),
      -400 + Math.random() * 200, 0,
      new Sprite(@img_star[randInt(0,1)], batch:@batch)))

  createMeteor: ->
    @meteors.push(new Thing(@engine.size.x, randInt(0, @engine.size.y),
      -600 + Math.random() * 400, -200 + Math.random() * 400,
      new Sprite(@img_meteor[randInt(0,1)], batch:@batch)))

  start: ->
    @engine.on('draw', @draw)
    @engine.on('update', @update)
    setInterval(@createStar, 0.1 * 1000)
    setInterval(@garbage, 10 * 1000)
    @engine.start()

  update: (dt) =>
    if @hadGameOver
      if @engine.buttonJustPressed(Button.Key_Space)
        location.href = location.href
      return
    score_per_sec = 60
    @score += score_per_sec * dt

    @nextMeteor -= dt
    if @nextMeteor <= 0
      @nextMeteor = @nextMeteorInterval
      @createMeteor()

    @nextMeteorInterval -= dt * 0.01

    for things in [@stars, @meteors]
      for thing in things
        if not thing.gone
          thing.x += thing.dx * dt
          thing.y += thing.dy * dt
          thing.sprite.pos.x = thing.x
          thing.sprite.pos.y = @engine.size.y - thing.y
          if thing.x < 0
            thing.delete()

    ship_accel = 600
    if @engine.buttonState(@controls[Control.MoveLeft])
      @ship_dx -= ship_accel * dt
    if @engine.buttonState(@controls[Control.MoveRight])
      @ship_dx += ship_accel * dt
    if @engine.buttonState(@controls[Control.MoveUp])
      @ship_dy += ship_accel * dt
    if @engine.buttonState(@controls[Control.MoveDown])
      @ship_dy -= ship_accel * dt

    @ship_x += @ship_dx * dt
    @ship_y += @ship_dy * dt

    if @ship_x < 0
      @ship_x = 0
      @ship_dx = 0
    if @ship_y < 0
      @ship_y = 0
      @ship_dy = 0
    if @ship_x + @sprite_ship.size.x > @engine.size.x
      @ship_x = @engine.size.x - @sprite_ship.size.x
      @ship_dx = 0
    if @ship_y + @sprite_ship.size.y > @engine.size.y
      @ship_y = @engine.size.y - @sprite_ship.size.y
      @ship_dy = 0

    @sprite_ship.pos.x = @ship_x
    @sprite_ship.pos.y = @engine.size.y - @ship_y

    for meteor in @meteors
      if meteor.gone
        continue
      not_colliding = @ship_x > meteor.x + meteor.sprite.size.x or \
        @ship_y > meteor.y + meteor.sprite.size.y or \
        @ship_x + @sprite_ship.size.x < meteor.x or  \
        @ship_y + @sprite_ship.size.y < meteor.y
      if not not_colliding
        @gameOver()
        break

    return
  gameOver: ->
    if @hadGameOver
      return
    @hadGameOver = true

  draw: (context) =>
    context.fillStyle = '#000000'
    context.fillRect 0, 0, @engine.size.x, @engine.size.y
    @engine.draw @batch
    context.fillStyle = "#ffffff"
    context.font = "30px Arial"
    context.fillText "Score: #{Math.floor(@score)}", 0, 30
    if @hadGameOver
      context.fillText "GAME OVER", @engine.size.x / 2, @engine.size.y / 2
      context.font = "18px Arial"
      context.fillText "space to restart", \
        @engine.size.x / 2, \
        @engine.size.y / 2 + 70

    context.font = "12px Arial"
    context.fillStyle = '#ffffff'
    @engine.drawFps()


canvas = document.getElementById("game")
Chem.onReady ->
  engine = new Engine(canvas)
  canvas.focus()
  game = new Game(engine)
  game.start()


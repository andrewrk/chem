#depend "chem"

{Vec2d, Engine, Sprite, Batch, Button} = Chem

randInt = (min, max) -> Math.floor(min + Math.random() * (max - min + 1))

class PhysicsObject
  constructor: (@sprite, @vel) ->
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
      'star_small'
      'star_big'
    ]
    @img_meteor = [
      'meteor_small'
      'meteor_big'
    ]
    @ship = new Sprite 'ship',
      batch: @batch
      pos: new Vec2d(0, @engine.size.y / 2)
    @ship_vel = new Vec2d()

    @nextMeteorInterval = 0.3
    @nextMeteor = @nextMeteorInterval

    @score = 0

  garbage: =>
    @stars = (star for star in @stars when not star.gone)

  createStar: =>
    sprite = new Sprite @img_star[randInt(0, 1)],
      batch: @batch
      pos: new Vec2d(@engine.size.x, randInt(0, @engine.size.y))
    obj = new PhysicsObject(sprite, new Vec2d(-400 + Math.random() * 200, 0))
    @stars.push(obj)

  createMeteor: ->
    sprite = new Sprite @img_meteor[randInt(0, 1)],
      batch: @batch
      pos: new Vec2d(@engine.size.x, randInt(0, @engine.size.y))
    obj = new PhysicsObject(sprite, new Vec2d(-600 + Math.random() * 400, -200 + Math.random() * 400))
    @meteors.push(obj)

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

    for obj_list in [@stars, @meteors]
      for obj in obj_list
        if not obj.gone
          obj.sprite.pos.add(obj.vel.scaled(dt))
          if obj.sprite.getRight() < 0
            obj.delete()

    ship_accel = 600

    if @engine.buttonState(Button.Key_Left)
      @ship_vel.x -= ship_accel * dt
    if @engine.buttonState(Button.Key_Right)
      @ship_vel.x += ship_accel * dt
    if @engine.buttonState(Button.Key_Up)
      @ship_vel.y -= ship_accel * dt
    if @engine.buttonState(Button.Key_Down)
      @ship_vel.y += ship_accel * dt

    @ship.pos.add(@ship_vel.scaled(dt))

    corner = @ship.getTopLeft()
    if corner.x < 0
      @ship.setLeft(0)
      @ship_vel.x = 0
    if corner.y < 0
      @ship.setTop(0)
      @ship_vel.y = 0
    corner = @ship.getBottomRight()
    if corner.x > @engine.size.x
      @ship.setRight(@engine.size.x)
      @ship_vel.x = 0
    if corner.y > @engine.size.y
      @ship.setBottom(@engine.size.y)
      @ship_vel.y = 0

    for meteor in @meteors
      if meteor.gone
        continue
      if @ship.isTouching(meteor.sprite)
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


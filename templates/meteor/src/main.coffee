#depend "chem"

{Vec2d, Engine, Sprite, Batch, Button} = Chem

randInt = (min, max) -> Math.floor(min + Math.random() * (max - min + 1))

class MovingSprite
  constructor: (@sprite, @vel) ->
    @gone = false

  delete: ->
    @gone = true
    @sprite?.delete()
    @sprite = null

class Game
  constructor: (@engine) ->
    @had_game_over = false
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
      zorder: 1
    @ship_vel = new Vec2d()

    @meteor_interval = 0.3
    @next_meteor_at = @meteor_interval

    @star_interval = 0.1
    @next_star_at = @star_interval

    @garbage_interval = 10
    @next_garbage_at = @garbage_interval

    @score = 0

  start: ->
    @engine.on('draw', @draw)
    @engine.on('update', @update)
    @engine.start()

  garbageCollect: ->
    @stars = (star for star in @stars when not star.gone)
    @meteors = (meteor for meteor in @meteors when not meteor.gone)

  createStar: ->
    sprite = new Sprite @img_star[randInt(0, 1)],
      batch: @batch
      pos: new Vec2d(@engine.size.x, randInt(0, @engine.size.y))
      zorder: 0
    obj = new MovingSprite(sprite, new Vec2d(-400 + Math.random() * 200, 0))
    @stars.push(obj)

  createMeteor: ->
    sprite = new Sprite @img_meteor[randInt(0, 1)],
      batch: @batch
      pos: new Vec2d(@engine.size.x, randInt(0, @engine.size.y))
      zorder: 1
    obj = new MovingSprite(sprite, new Vec2d(-600 + Math.random() * 400, -200 + Math.random() * 400))
    @meteors.push(obj)

  update: (dt) =>
    if @had_game_over
      if @engine.buttonJustPressed(Button.Key_Space)
        location.href = location.href
        return
    else
      score_per_sec = 60
      @score += score_per_sec * dt

    @next_meteor_at -= dt
    if @next_meteor_at <= 0
      @next_meteor_at = @meteor_interval
      @createMeteor()

    if not @had_game_over
      @meteor_interval -= dt * 0.01

    @next_star_at -= dt
    if @next_star_at <= 0
      @next_star_at = @star_interval
      @createStar()

    @next_garbage_at -= dt
    if @next_garbage_at <= 0
      @next_garbage_at = @garbage_interval
      @garbageCollect()

    for obj_list in [@stars, @meteors]
      for obj in obj_list
        if not obj.gone
          obj.sprite.pos.add(obj.vel.scaled(dt))
          if obj.sprite.getRight() < 0
            obj.delete()

    if not @had_game_over
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

    if not @had_game_over
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
    if @had_game_over
      return
    @had_game_over = true
    @ship.setAnimationName('explosion')
    @ship.setFrameIndex(0)
    @ship.on 'animation_end', => @ship.delete()

  draw: (context) =>
    context.fillStyle = '#000000'
    context.fillRect 0, 0, @engine.size.x, @engine.size.y
    @engine.draw @batch
    context.fillStyle = "#ffffff"
    context.font = "30px Arial"
    context.fillText "Score: #{Math.floor(@score)}", 0, 30
    if @had_game_over
      context.fillText "GAME OVER", @engine.size.x / 2, @engine.size.y / 2
      context.font = "18px Arial"
      context.fillText "space to restart", \
        @engine.size.x / 2, \
        @engine.size.y / 2 + 70

    context.font = "12px Arial"
    context.fillStyle = '#ffffff'
    @engine.drawFps()


Chem.onReady ->
  canvas = document.getElementById("game")
  engine = new Engine(canvas)
  canvas.focus()
  game = new Game(engine)
  game.start()


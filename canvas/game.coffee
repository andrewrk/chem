canvas = document.getElementById("game")
engine = new Engine(canvas)
batch = new Engine.Batch()
sprite = new Engine.Sprite("victory", batch: batch, pos: new Vec2d(200, 200))
engine.on 'update', (dt, dx) ->
  if engine.buttonState(Engine.Button.Mouse_Left)
    sprite.pos = engine.mousePos()
  if engine.buttonState(Engine.Button.Mouse_Right)
    sprite.rotation += 3.14 / 16
engine.on 'draw', (context) ->
  context.clearRect 0, 0, engine.size.x, engine.size.y
  engine.draw batch
  context.fillText "#{engine.fps} fps", 0, engine.size.y
engine.start()

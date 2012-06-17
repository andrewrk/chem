canvas = document.getElementById("game")
engine = new Engine(canvas)
batch = new Engine.Batch()
sprite = new Engine.Sprite("still", batch: batch, pos: new Vec2d(200, 200))
engine.on 'update', (dt, dx) ->
engine.on 'draw', (context) ->
  context.clearRect 0, 0, engine.size.x, engine.size.y
  engine.draw batch
  context.fillText "#{engine.fps} fps", 0, engine.size.y
engine.on 'mousedown', (event) ->
  console.log event.button
  if event.button is 1
    sprite.pos = event.pos
  else if event.button is 3
    sprite.rotation += 3.14 / 4
engine.start()

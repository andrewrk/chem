canvas = document.getElementById("game")
engine = new Engine(canvas)
engine.on 'update', (dt, dx) ->
engine.on 'draw', (context) ->
  context.clearRect 0, 0, engine.size.x, engine.size.y
  context.fillText "#{engine.fps} fps", 0, engine.size.y
engine.on 'mousedown', (pos) -> console.log pos.x, pos.y
engine.start()

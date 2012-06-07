canvas = document.getElementById("game")
engine = new Engine(canvas)
engine.on 'update', (dt) ->
engine.start()

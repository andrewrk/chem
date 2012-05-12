app = require('express').createServer()
io = require('socket.io').listen(app)
fs = require('fs')

app.listen(9000)

app.get '/', (req, res) ->
  res.send 'sup'


sessions = []



io.sockets.on 'connection', (socket) ->

  sesh = {
    nick: "Guest User " + Math.floor( Math.random() * 1000 )
  }

  sessions.push(sesh)
  socket.emit('LobbyList', sessions)


  socket.on 'UpdateNick', (data) ->
    sesh.nick = data
    socket.emit('LobbyList', sessions)

  socket.on 'StateUpdate', (data) ->
    sesh.state = data
    # send my state to the other player if I'm in a game
    socket.broadcast.emit 'StateUpdate', sesh

  socket.on 'disconnect', ->
    console.log "End my session", sesh


app = require('express').createServer()
io = require('socket.io').listen(app)
fs = require('fs')
_ = require('underscore')
Backbone = require('backbone')

app.listen(9000)

app.get '/', (req, res) ->
  res.send 'sup'



class User extends Backbone.Model


class UserCollection extends Backbone.Collection
  model: User

users = new UserCollection()




io.sockets.on 'connection', (socket) ->

  user = new User
    nick: "Guest User " + Math.floor( Math.random() * 1000 )

  user.socket = socket

  # Add to the list of sessions
  users.push(user)

  # Send the lobby list to the user
  socket.emit('LobbyList', users.toJSON())


  # Look for another user who is not playing
  # Create a game if there are two users free
  users.forEach (u) ->
    if u != user and !u.playing
      u.playing = user
      user.playing = u

      user.socket.emit('StartGame', {playing: u})
      u.socket.emit('StartGame', {playing: user})




  socket.on 'UpdateNick', (data) ->
    user.set('nick', data)
    socket.emit('LobbyList', users.toJSON())

  socket.on 'StateUpdate', (data) ->
    user.set('state', data)
    # send my state to the other player if I'm in a game
    socket.broadcast.emit 'StateUpdate', user.toJSON()

  socket.on 'disconnect', ->
    console.log "End my session", sesh


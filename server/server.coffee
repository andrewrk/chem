app = require('express').createServer()
io = require('socket.io').listen(app)
io.set 'log level', 2
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

  me = new User
    nick: "Guest User " + Math.floor( Math.random() * 1000 )

  me.socket = socket

  # Add to the list of sessions
  users.push(me)

  # Send the lobby list to the user
  socket.emit('LobbyList', users.toJSON())


  # Look for another user who is not playing
  # Create a game if there are two users free
  users.forEach (u) ->
    if u != me and !u.opponent
      u.opponent = me
      me.opponent = u

      me.socket.emit('StartGame', {opponent: u})
      u.socket.emit('StartGame', {opponent: me})




  socket.on 'UpdateNick', (data) ->
    me.set('nick', data)
    socket.emit('LobbyList', users.toJSON())

  socket.on 'StateUpdate', (data) ->
    me.set('state', data)
    if me.opponent
      me.opponent.socket.emit 'StateUpdate', me.toJSON().state

    # send my state to the other player if I'm in a game
    #socket.broadcast.emit 'StateUpdate', user.toJSON()

  socket.on 'disconnect', ->
    if me.opponent
      me.opponent.playing = false
      me.opponent.socket.emit 'YourOpponentLeftSorryBro', me.toJSON()

    users.remove(me)
    socket.broadcast.emit 'LobbyList', users.toJSON()

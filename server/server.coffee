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
    nick: "Guest User " + Math.floor( Math.random() * 10000 )
    playing: null
    want_to_play: {}

  me.socket = socket

  # Add to the list of sessions
  users.push(me)

  # Send the lobby list to all users
  socket.broadcast.emit('LobbyList', users.toJSON())
  socket.emit('LobbyList', users.toJSON())

  socket.on 'PlayRequest', (nick) ->
    console.log(users)
    h = me.get("want_to_play")
    h[nick] = true
    me.set("want_to_play", h)
    socket.broadcast.emit('LobbyList', users.toJSON())
    socket.emit('LobbyList', users.toJSON())

  socket.on 'AcceptPlayRequest', (nick) ->
    # now kiss! http://markwatches.net/reviews/wp-content/uploads/2012/03/fap-now-kiss-l.png
    results = users.where nick: nick
    if results.length > 0
      u = results[0]
      if u != me and !u.opponent

        u.opponent = me
        me.opponent = u
        u.set('playing', me.get('nick'))
        me.set('playing', u.get('nick'))

        me.socket.emit('StartGame', {opponent: u})
        u.socket.emit('StartGame', {opponent: me})

        socket.broadcast.emit('LobbyList', users.toJSON())


  socket.on 'UpdateNick', (data) ->
    me.set('nick', data)
    socket.broadcast.emit('LobbyList', users.toJSON())
    socket.emit('LobbyList', users.toJSON())

  socket.on 'StateUpdate', (data) ->
    me.state = data
    if me.opponent
      me.opponent.socket.emit 'StateUpdate', me.state


  socket.on 'disconnect', ->
    if me.opponent
      u = me.opponent
      u.set('playing', false)
      u.opponent = undefined
      me.opponent.socket.emit 'YourOpponentLeftSorryBro', {really: 'sorry'}

    users.remove(me)
    socket.broadcast.emit 'LobbyList', users.toJSON()

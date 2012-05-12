io = require('socket.io-client')

class ChemPlayer

  constructor: ->
    @socket = io.connect('http://localhost:9000')

    @socket.on 'LobbyList', (data) =>
      @debug data

  updateNick: (nick) ->
    @nick = nick
    @socket.emit 'UpdateNick', nick



  debug: (msg) ->
    console.log "#{@nick}: #{msg}"


andrew = new ChemPlayer
steve = new ChemPlayer

andrew.updateNick('superjoe30')
steve.updateNick('stereosteve')




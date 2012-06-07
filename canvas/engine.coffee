class Vec2d
  constructor: (@x, @y) ->

class EventEmitter
  extend = (obj, args...) ->
    for arg in args
      obj[prop] = val for prop, val of arg
    obj

  constructor: ->
    @event_handlers = {}

  on: (event_name, handler) ->
    @handlers(event_name).push handler

  removeEventListeners: (event_name) =>
    @handlers(event_name).length = 0
    
  removeListener: (event_name, handler) =>
    handlers = @handlers(event_name)
    for h, i in handlers
      if h is handler
        handlers.splice i, 1
        return

  # protected
  emit: (event_name, args...) =>
    # create copy so handlers can remove themselves
    handlers_list = extend [], @handlers(event_name)
    handler(args...) for handler in handlers_list

  # private
  handlers: (event_name) -> @event_handlers[event_name] ?= []


class Engine extends EventEmitter
  target_fps = 60
  target_delta = 1 / target_fps

  constructor: (@canvas) ->
    super
    @context = @canvas.getContext("2d")
    @size = new Vec2d(@canvas.width, @canvas.height)

  setSize: (@size) ->
    @canvas.width = @size.x
    @canvas.height = @size.y

  start: ->
    previous_update = null
    main_loop = =>
      now = new Date()
      delta = if previous_update? then (now - previous_update) / 1000 else target_delta
      @emit 'update', delta
      previous_update = now

    @interval = setInterval main_loop, target_delta

  stop: ->
    clearInterval @interval


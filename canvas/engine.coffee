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
  min_fps = 20
  target_spf = 1 / target_fps

  schedule = (sec, cb) -> setInterval(cb, sec * 1000)
  unschedule = clearInterval

  constructor: (@canvas) ->
    super
    @context = @canvas.getContext("2d")
    @size = new Vec2d(@canvas.width, @canvas.height)

  setSize: (@size) ->
    @canvas.width = @size.x
    @canvas.height = @size.y

  start: ->
    previous_update = new Date()
    max_frame_skips = target_fps - min_fps
    fps_time_passed = 0
    fps_refresh_rate = 1
    fps_count = 0
    @interval = schedule target_spf, =>
      now = new Date()
      delta = (now - previous_update) / 1000
      previous_update = now

      fps_time_passed += delta

      skip_count = 0
      while delta > target_spf and skip_count < max_frame_skips
        @emit 'update', target_spf, 1
        skip_count += 1
        delta -= target_spf

      multiplier = delta / target_spf
      @emit 'update', delta, multiplier
      @emit 'draw', @context
      fps_count += 1

      if fps_time_passed >= fps_refresh_rate
        fps_time_passed = 0
        @fps = fps_count / fps_refresh_rate
        fps_count = 0

  stop: ->
    unschedule @interval


Vec2d = Chem.Vec2d
_exports = window.Chem ||= {}

extend = (obj, args...) ->
  for arg in args
    obj[prop] = val for prop, val of arg
  obj

class EventEmitter
  constructor: ->
    @event_handlers = {}

  on: (event_name, handler) ->
    @handlers(event_name).push handler
    return

  removeEventListeners: (event_name) =>
    @handlers(event_name).length = 0
    return
    
  removeListener: (event_name, handler) =>
    handlers = @handlers(event_name)
    for h, i in handlers
      if h is handler
        handlers.splice i, 1
        return
    return

  # protected
  emit: (event_name, args...) =>
    # create copy so handlers can remove themselves
    handlers_list = extend [], @handlers(event_name)
    handler(args...) for handler in handlers_list
    return

  # private
  handlers: (event_name) -> @event_handlers[event_name] ?= []

Key =
  Shift: 16
  Ctrl: 17
  Alt: 18
  Space: 32
  Left: 37
  Up: 38
  Right: 39
  Down: 40
  1: 49
  2: 50
  3: 51
  4: 52
  A: 65
  D: 68
  E: 69
  O: 79
  R: 82
  S: 83
  W: 87
  MetaLeft: 91
  MetaRight: 92
  Comma: 188

Mouse =
  Left: 1
  Middle: 2
  Right: 3

# map both Key and Mouse into Button
_exports.Button = Button = {}
key_offset = 0
for name, val of Key
  Button["Key_#{name}"] = key_offset + val
mouse_offset = 256
for name, val of Mouse
  Button["Mouse_#{name}"] = mouse_offset + val

class Indexable
  @id_count = 0

  constructor: ->
    @id = Indexable.id_count++

_exports.Batch = class Batch
  constructor: ->
    # indexed by zorder
    @sprites = []
  add: (sprite) ->
    sprite.batch?.remove sprite
    sprite.batch = this
    (@sprites[sprite.zorder] ?= {})[sprite.id] = sprite
  remove: (sprite) ->
    delete (@sprites[sprite.zorder] ?= {})[sprite.id]

_exports.Sprite = class Sprite extends Indexable
  constructor: (animation, params) ->
    super
    o =
      pos: new Vec2d(0, 0)
      scale: new Vec2d(1, 1)
      zorder: 0
      batch: null
      rotation: 0
      visible: true
    extend o, params

    @pos = o.pos
    @zorder = o.zorder
    @rotation = o.rotation
    @batch = o.batch
    @scale = o.scale

    @setAnimation animation
    @setVisible o.visible

    # size of current frame, which does not take scale into account
    @size = new Vec2d(animations[@animation].frames[0].size)

  setAnimation: (@animation) ->
    throw "bad sprite name" unless @animation

  setVisible: (@visible) ->
    return unless @batch?
    if @visible
      @batch.add this
    else
      @batch.remove this

  delete: ->
    @batch.remove this

_exports.Engine = class Engine extends EventEmitter
  target_fps = 60
  min_fps = 20
  target_spf = 1 / target_fps

  schedule = (sec, cb) -> setInterval(cb, sec * 1000)
  unschedule = clearInterval

  constructor: (@canvas) ->
    super
    # add tabindex property to canvas so that it can receive keyboard input
    @canvas.tabIndex = 0
    
    @context = @canvas.getContext("2d")
    @size = new Vec2d(@canvas.width, @canvas.height)

  setSize: (@size) ->
    @canvas.width = @size.x
    @canvas.height = @size.y

  start: ->
    @attachListeners()
    @startMainLoop()

  stop: ->
    @stopMainLoop()
    @removeListeners()

  buttonState: (button) -> !!@button_states[button]
  buttonJustPressed: (button) -> !!@btn_just_pressed[button]
  mousePos: -> @mouse_pos

  clear: ->
    @context.clearRect 0, 0, @size.x, @size.y

  draw: (batch) ->
    now = new Date()
    total_time = (now - @main_loop_start_date) / 1000

    for sprites in batch.sprites
      for id, sprite of sprites
        animation = animations[sprite.animation]
        anim_duration = animation.delay * animation.frames.length
        frame_index = Math.floor((total_time % anim_duration) / animation.delay)
        frame = animation.frames[frame_index]
        @context.save()
        @context.translate sprite.pos.x, sprite.pos.y
        @context.scale sprite.scale.x, sprite.scale.y
        @context.rotate sprite.rotation
        @context.drawImage spritesheet, frame.pos.x, frame.pos.y, \
          frame.size.x, frame.size.y, \
          -animation.anchor.x, -animation.anchor.y, \
          frame.size.x, frame.size.y
        @context.restore()
    return

  drawFps: ->
    return unless @fps?
    @context.fillText "#{@fps} fps", 0, @size.y


  # private
  startMainLoop: ->
    @main_loop_start_date = previous_update = new Date()
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
        @callUpdate target_spf, 1
        skip_count += 1
        delta -= target_spf

      multiplier = delta / target_spf
      @callUpdate delta, multiplier
      @emit 'draw', @context
      fps_count += 1

      if fps_time_passed >= fps_refresh_rate
        fps_time_passed = 0
        @fps = fps_count / fps_refresh_rate
        fps_count = 0
      return

  callUpdate: (dt, dx) ->
    @emit 'update', dt, dx
    @btn_just_pressed = {}
    return

  attachListeners: ->
    @button_states = {}
    window._debug_button_state = this.button_states
    @btn_just_pressed = {}

    # disable right click context menu
    @canvas.addEventListener 'contextmenu', (event) ->
      event.preventDefault()

    # mouse input
    @mouse_pos = new Vec2d(0, 0)
    forwardMouseEvent = (name, event) =>
      @mouse_pos = new Vec2d(event.offsetX, event.offsetY)
      @emit name, @mouse_pos, mouse_offset + event.which
      return
    @canvas.addEventListener 'mousemove', (event) ->
      forwardMouseEvent 'mousemove', event
    @canvas.addEventListener 'mousedown', (event) =>
      button_id = mouse_offset + event.which
      @button_states[button_id] = true
      @btn_just_pressed[button_id] = true

      forwardMouseEvent 'mousedown', event
    @canvas.addEventListener 'mouseup', (event) =>
      @button_states[mouse_offset + event.which] = false

      forwardMouseEvent 'mouseup', event

    # keyboard input
    @canvas.addEventListener 'keydown', (event) =>
      button_id = key_offset + event.which
      @button_states[button_id] = true
      @btn_just_pressed[button_id] = true

      @emit 'keydown', button_id
      event.preventDefault()
      false
    @canvas.addEventListener 'keyup', (event) =>
      button_id = key_offset + event.which
      @button_states[button_id] = false

      @emit 'keyup', button_id
      event.preventDefault()
      false

  removeListeners: ->
    # TODO

  stopMainLoop: ->
    unschedule @interval

# load assets
spritesheet = null
animations = null
do ->
  on_ready_queue = []
  _exports.onReady = (cb) ->
    if assets_loaded
      cb()
    else
      on_ready_queue.push cb
    return

  # set assets_loaded after all assets are done loading
  assets_loaded = false
  spritesheet_done = false
  animations_json_done = false
  checkDoneLoading = ->
    if spritesheet_done and animations_json_done
      assets_loaded = true
      cb() for cb in on_ready_queue
    return

  # get the spritesheet
  spritesheet = new Image()
  spritesheet.src = "spritesheet.png"
  spritesheet.onload = ->
    spritesheet_done = true
    checkDoneLoading()

  # get the animations.json file
  request = new XMLHttpRequest()
  request.onreadystatechange = ->
    return unless request.readyState is 4 and request.status is 200
    animations = JSON.parse(request.responseText)
    animations_json_done = true
    checkDoneLoading()
  request.open("GET", "animations.json", true)
  request.send()

  return


//depend "chem/vec2d"
//depend "chem/event_emitter"
//depend "private/button_offset"

var ref$, Vec2d, EventEmitter, Button, MOUSE_OFFSET, KEY_OFFSET, _exports, _private, Engine;
ref$ = window.Chem || (window.Chem = {}), Vec2d = ref$.Vec2d, EventEmitter = ref$.EventEmitter, Button = ref$.Button;
ref$ = (ref$ = window.Chem || (window.Chem = {})).Private || (ref$.Private = {}), MOUSE_OFFSET = ref$.MOUSE_OFFSET, KEY_OFFSET = ref$.KEY_OFFSET;
_exports = window.Chem || (window.Chem = {});
_private = (ref$ = window.Chem || (window.Chem = {})).Private || (ref$.Private = {});
_exports.getImage = function(name, frameIndex){
  var anim, buffer, frame, context;
  frameIndex == null && (frameIndex = 0);
  anim = _private.animations[name];
  buffer = document.createElement('canvas');
  frame = anim.frames[frameIndex];
  buffer.width = frame.size.x;
  buffer.height = frame.size.y;
  context = buffer.getContext('2d');
  context.drawImage(_private.spritesheet, frame.pos.x, frame.pos.y, frame.size.x, frame.size.y, 0, 0, frame.size.x, frame.size.y);
  return buffer;
};
_exports.Engine = Engine = (function(superclass){
  Engine.displayName = 'Engine';
  var target_fps, target_spf, fps_smoothness, fps_one_frame_weight, requestAnimationFrame, prototype = extend$(Engine, superclass).prototype, constructor = Engine;
  target_fps = 60;
  target_spf = 1 / target_fps;
  fps_smoothness = 0.9;
  fps_one_frame_weight = 1.0 - fps_smoothness;
  requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(cb){
    window.setTimeout(cb, target_spf * 1000);
  };
  function Engine(canvas){
    var this$ = this instanceof ctor$ ? this : new ctor$;
    this$.canvas = canvas;
    superclass.call(this$);
    this$.listeners = [];
    // add tabindex property to canvas so that it can receive keyboard input
    this$.canvas.tabIndex = 0;
    this$.context = this$.canvas.getContext("2d");
    this$.size = Vec2d(this$.canvas.width, this$.canvas.height);
    this$.fps = target_fps;
    this$.setMinFps(20);
    return this$;
  } function ctor$(){} ctor$.prototype = prototype;
  prototype.setSize = function(size){
    this.size = size;
    this.canvas.width = this.size.x;
    this.canvas.height = this.size.y;
  };
  prototype.setMinFps = function(it){
    this.max_spf = 1 / it;
  };
  prototype.start = function(){
    this.attachListeners();
    this.startMainLoop();
  };
  prototype.stop = function(){
    this.stopMainLoop();
    this.removeListeners();
  };
  prototype.buttonState = function(button){
    return !!this.button_states[button];
  };
  prototype.buttonJustPressed = function(button){
    return !!this.btn_just_pressed[button];
  };
  prototype.draw = function(batch){
    var i$, ref$, len$, sprites, id, sprite, frame;
    for (i$ = 0, len$ = (ref$ = batch.sprites).length; i$ < len$; ++i$) {
      sprites = ref$[i$];
      for (id in sprites) {
        sprite = sprites[id];
        frame = sprite.animation.frames[sprite.getFrameIndex()];
        this.context.save();
        this.context.translate(sprite.pos.x, sprite.pos.y);
        this.context.scale(sprite.scale.x, sprite.scale.y);
        this.context.rotate(sprite.rotation);
        this.context.globalAlpha = sprite.alpha;
        this.context.drawImage(_private.spritesheet, frame.pos.x, frame.pos.y, frame.size.x, frame.size.y, -sprite.animation.anchor.x, -sprite.animation.anchor.y, frame.size.x, frame.size.y);
        this.context.restore();
      }
    }
  };
  prototype.drawFps = function(){
    this.context.textAlign = 'left';
    this.context.fillText(Math.round(this.fps) + " fps", 0, this.size.y);
  };
  // private
  prototype.startMainLoop = function(){
    var previous_update, mainLoop, this$ = this;
    previous_update = new Date();
    this.main_loop_on = true;
    mainLoop = function(){
      var now, delta, ref$, ref1$, dt, multiplier, fps;
      now = new Date();
      delta = (now - previous_update) / 1000;
      previous_update = now;
      // make sure dt is never zero
      // if FPS is too low, lag instead of causing physics glitches
      dt = (ref$ = 0.00000001 > delta ? 0.00000001 : delta) < (ref1$ = this$.max_spf) ? ref$ : ref1$;
      multiplier = dt / target_spf;
      this$.emit('update', dt, multiplier);
      this$.btn_just_pressed = {};
      this$.emit('draw', this$.context);
      fps = (ref$ = 1 / delta) < 90000 ? ref$ : 90000;
      this$.fps = this$.fps * fps_smoothness + fps * fps_one_frame_weight;
      if (this$.main_loop_on) {
        requestAnimationFrame(mainLoop, this$.canvas);
      }
    };
    requestAnimationFrame(mainLoop, this.canvas);
  };
  prototype.attachListeners = function(){
    var addListener, forwardMouseEvent, this$ = this;
    this.button_states = {};
    this.btn_just_pressed = {};
    addListener = function(element, event_name, listener){
      this$.listeners.push([element, event_name, listener]);
      element.addEventListener(event_name, listener, false);
    };
    // disable right click context menu
    addListener(this.canvas, 'contextmenu', function(event){
      event.preventDefault();
    });
    // mouse input
    this.mouse_pos = Vec2d();
    forwardMouseEvent = function(name, event){};
    addListener(this.canvas, 'mousemove', function(event){
      var ref$;
      this$.mouse_pos = Vec2d((ref$ = event.offsetX) != null
        ? ref$
        : event.pageX - event.target.offsetLeft, (ref$ = event.offsetY) != null
        ? ref$
        : event.pageY - event.target.offsetTop);
      this$.emit('mousemove', this$.mouse_pos, MOUSE_OFFSET + event.which);
    });
    addListener(this.canvas, 'mousedown', function(event){
      var button_id;
      button_id = MOUSE_OFFSET + event.which;
      this$.button_states[button_id] = true;
      this$.btn_just_pressed[button_id] = true;
      this$.emit('buttondown', button_id);
    });
    addListener(this.canvas, 'mouseup', function(event){
      var button_id;
      button_id = MOUSE_OFFSET + event.which;
      this$.button_states[button_id] = false;
      this$.emit('buttonup', button_id);
    });
    // keyboard input
    addListener(this.canvas, 'keydown', function(event){
      var button_id;
      button_id = KEY_OFFSET + event.which;
      this$.btn_just_pressed[button_id] = !this$.button_states[button_id];
      this$.button_states[button_id] = true;
      this$.emit('buttondown', button_id);
      event.preventDefault();
      return false;
    });
    addListener(this.canvas, 'keyup', function(event){
      var button_id;
      button_id = KEY_OFFSET + event.which;
      this$.button_states[button_id] = false;
      this$.emit('buttonup', button_id);
      event.preventDefault();
      return false;
    });
  };
  prototype.removeListeners = function(){
    var i$, ref$, len$, ref1$, element, event_name, listener;
    for (i$ = 0, len$ = (ref$ = this.listeners).length; i$ < len$; ++i$) {
      ref1$ = ref$[i$], element = ref1$[0], event_name = ref1$[1], listener = ref1$[2];
      element.removeEventListener(event_name, listener, false);
    }
    this.listeners = [];
  };
  prototype.stopMainLoop = function(){
    this.main_loop_on = false;
  };
  return Engine;
}(EventEmitter));
function extend$(sub, sup){
  function fun(){} fun.prototype = (sub.superclass = sup).prototype;
  (sub.prototype = new fun).constructor = sub;
  if (typeof sup.extended == 'function') sup.extended(sub);
  return sub;
}

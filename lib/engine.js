var vec2d = require('vec2d');
var resources = require('./resources');
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var button = require('./button');
var MOUSE_OFFSET = button.MOUSE_OFFSET;
var KEY_OFFSET = button.KEY_OFFSET;
var EPSILON = 0.00000001;
var MAX_DISPLAY_FPS = 90000;

module.exports = Engine;

var targetFps = 60;
var targetSpf = 1 / targetFps;
var fpsSmoothness = 0.9;
var fpsOneFrameWeight = 1.0 - fpsSmoothness;
var requestAnimationFrame = window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.oRequestAnimationFrame ||
  window.msRequestAnimationFrame ||
  fallbackRequestAnimationFrame;

util.inherits(Engine, EventEmitter);
function Engine(canvas) {
  EventEmitter.call(this);
  this.canvas = canvas;
  this.listeners = [];
  // add tabindex property to canvas so that it can receive keyboard input
  this.canvas.tabIndex = 0;
  this.context = this.canvas.getContext("2d");
  this.size = vec2d(this.canvas.width, this.canvas.height);
  this.fps = targetFps;
  this.setMinFps(20);
}

Engine.prototype.setSize = function(size) {
  this.size = size;
  this.canvas.width = this.size.x;
  this.canvas.height = this.size.y;
};

Engine.prototype.setMinFps = function(it){
  this.maxSpf = 1 / it;
};
Engine.prototype.start = function(){
  this.attachListeners();
  this.startMainLoop();
};
Engine.prototype.stop = function(){
  this.stopMainLoop();
  this.removeListeners();
};
Engine.prototype.buttonState = function(button){
  return !!this.buttonStates[button];
};
Engine.prototype.buttonJustPressed = function(button){
  return !!this.btnJustPressed[button];
};
Engine.prototype.draw = function(batch){
  for (var i = 0; i < batch.sprites.length; ++i) {
    var sprites = batch.sprites[i];
    for (var id in sprites) {
      var sprite = sprites[id];
      var frame = sprite.animation.frames[sprite.getFrameIndex()];
      this.context.save();
      this.context.translate(sprite.pos.x, sprite.pos.y);
      this.context.scale(sprite.scale.x, sprite.scale.y);
      this.context.rotate(sprite.rotation);
      this.context.globalAlpha = sprite.alpha;
      this.context.drawImage(resources.spritesheet,
          frame.pos.x, frame.pos.y,
          frame.size.x, frame.size.y,
          -sprite.animation.anchor.x, -sprite.animation.anchor.y,
          frame.size.x, frame.size.y);
      this.context.restore();
    }
  }
};
Engine.prototype.drawFps = function(){
  this.context.textAlign = 'left';
  this.context.fillText(Math.round(this.fps) + " fps", 0, this.size.y);
};
// private
Engine.prototype.startMainLoop = function(){
  var self = this;
  var previousUpdate = new Date();
  this.mainLoopOn = true;
  requestAnimationFrame(mainLoop, this.canvas);

  function mainLoop(){
    var now = new Date();
    var delta = (now - previousUpdate) / 1000;
    previousUpdate = now;
    // make sure dt is never zero
    // if FPS is too low, lag instead of causing physics glitches
    var dt = delta;
    if (dt < EPSILON) dt = EPSILON;
    if (dt > self.maxSpf) dt = self.maxSpf;
    var multiplier = dt / targetSpf;
    self.emit('update', dt, multiplier);
    self.btnJustPressed = {};
    self.emit('draw', self.context);
    var fps = 1 / delta;
    fps = fps < MAX_DISPLAY_FPS ? fps : MAX_DISPLAY_FPS;
    self.fps = self.fps * fpsSmoothness + fps * fpsOneFrameWeight;
    if (self.mainLoopOn) {
      requestAnimationFrame(mainLoop, self.canvas);
    }
  }
};
Engine.prototype.attachListeners = function(){
  var self = this;
  this.buttonStates = {};
  this.btnJustPressed = {};
  // disable right click context menu
  addListener(this.canvas, 'contextmenu', function(event){
    event.preventDefault();
  });
  // mouse input
  this.mousePos = vec2d();
  addListener(this.canvas, 'mousemove', function(event){
    self.mousePos = vec2d(
      (event.offsetX) != null ? event.offsetX : event.pageX - event.target.offsetLeft,
      (event.offsetY) != null ? event.offsetY : event.pageY - event.target.offsetTop);
    self.emit('mousemove', self.mousePos, MOUSE_OFFSET + event.which);
  });
  addListener(this.canvas, 'mousedown', function(event){
    var buttonId;
    buttonId = MOUSE_OFFSET + event.which;
    self.buttonStates[buttonId] = true;
    self.btnJustPressed[buttonId] = true;
    self.emit('buttondown', buttonId);
  });
  addListener(this.canvas, 'mouseup', function(event){
    var buttonId;
    buttonId = MOUSE_OFFSET + event.which;
    self.buttonStates[buttonId] = false;
    self.emit('buttonup', buttonId);
  });
  // keyboard input
  addListener(this.canvas, 'keydown', function(event){
    var buttonId;
    buttonId = KEY_OFFSET + event.which;
    self.btnJustPressed[buttonId] = !self.buttonStates[buttonId];
    self.buttonStates[buttonId] = true;
    self.emit('buttondown', buttonId);
    event.preventDefault();
    return false;
  });
  addListener(this.canvas, 'keyup', function(event){
    var buttonId;
    buttonId = KEY_OFFSET + event.which;
    self.buttonStates[buttonId] = false;
    self.emit('buttonup', buttonId);
    event.preventDefault();
    return false;
  });
  function addListener(element, eventName, listener){
    self.listeners.push([element, eventName, listener]);
    element.addEventListener(eventName, listener, false);
  }
};
Engine.prototype.removeListeners = function(){
  this.listeners.forEach(function(listener) {
    var element = listener[0];
    var eventName = listener[1];
    var fn = listener[2];
    element.removeEventListener(eventName, fn, false);
  });
  this.listeners = [];
};
Engine.prototype.stopMainLoop = function(){
  this.mainLoopOn = false;
};

function fallbackRequestAnimationFrame(cb){
  window.setTimeout(cb, targetSpf * 1000);
}


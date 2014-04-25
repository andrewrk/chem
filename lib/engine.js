var Vec2d = require('vec2d').Vec2d;
var resources = require('./resources');
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var button = require('./button');
var Label = require('./label');
var MOUSE_OFFSET = button.MOUSE_OFFSET;
var KEY_OFFSET = button.KEY_OFFSET;
var EPSILON = 0.00000001;
var MAX_DISPLAY_FPS = 90000;

module.exports = Engine;

var targetFps = 60;
var targetSpf = 1 / targetFps;
var fpsSmoothness = 0.9;
var fpsOneFrameWeight = 1.0 - fpsSmoothness;
var requestAnimationFrame = global.requestAnimationFrame ||
  global.webkitRequestAnimationFrame ||
  global.mozRequestAnimationFrame ||
  global.oRequestAnimationFrame ||
  global.msRequestAnimationFrame ||
  fallbackRequestAnimationFrame;
var cancelAnimationFrame = global.cancelAnimationFrame ||
  global.webkitCancelAnimationFrame ||
  global.mozCancelAnimationFrame ||
  global.oCancelAnimationFrame ||
  global.msCancelAnimationFrame ||
  clearTimeout;

util.inherits(Engine, EventEmitter);
function Engine(canvas) {
  EventEmitter.call(this);
  this.canvas = canvas;
  this.listeners = [];
  // add tabindex property to canvas so that it can receive keyboard input
  this.canvas.tabIndex = 0;
  this.context = this.canvas.getContext("2d");
  this.size = new Vec2d(this.canvas.width, this.canvas.height);
  this.fps = targetFps;
  this.setMinFps(20);
  this.buttonCaptureExceptions = {};
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
  attachListeners(this);
  startMainLoop(this);
};

Engine.prototype.stop = function(){
  stopMainLoop(this);
  removeListeners(this);
};

Engine.prototype.buttonState = function(button){
  return !!this.buttonStates[button];
};

Engine.prototype.buttonJustPressed = function(button){
  return !!this.btnJustPressed[button];
};

Engine.prototype.buttonJustReleased = function(button){
  return !!this.btnJustReleased[button];
};

Engine.prototype.showLoadProgressBar = function() {
  showLoadProgressBar(this);
};

Engine.prototype.createFpsLabel = function() {
  var label = new Label(this.fps, {
    font: "14px sans-serif",
    fillStyle: "#ffffff",
    textAlign: 'left',
    pos: new Vec2d(0, this.size.y),
  });
  this.on('update', function() {
    label.text = Math.round(this.fps);
  });
  return label;
};

function startMainLoop(self) {
  var previousUpdate = (new Date()).getTime();
  var previousDraw = (new Date()).getTime();
  doUpdate();

  function doUpdate() {
    var timestamp = new Date().getTime();
    var delta = (timestamp - previousUpdate) / 1000;
    previousUpdate = timestamp;
    // make sure dt is never zero
    // if FPS is too low, lag instead of causing physics glitches
    var dt = delta;
    if (dt < EPSILON) dt = EPSILON;
    if (dt > self.maxSpf) dt = self.maxSpf;
    var multiplier = dt / targetSpf;
    self.emit('update', dt, multiplier);
    self.btnJustPressed = {};
    self.btnJustReleased = {};
    self.animationFrameId = requestAnimationFrame(doDraw, self.canvas);
  }

  function doDraw(timestamp) {
    var delta = (timestamp - previousDraw) / 1000;
    previousDraw = timestamp;
    self.emit('draw', self.context);
    var fps = 1 / delta;
    fps = fps < MAX_DISPLAY_FPS ? fps : MAX_DISPLAY_FPS;
    self.fps = self.fps * fpsSmoothness + fps * fpsOneFrameWeight;
    self.timeoutId = setTimeout(doUpdate, 0);
  }
}

function attachListeners(self) {
  self.buttonStates = {};
  self.btnJustPressed = {};
  self.btnJustReleased = {};
  // disable right click context menu
  addListener(self.canvas, 'contextmenu', function(event){
    if (self.buttonCaptureExceptions[button.MouseRight]) return true;
    event.preventDefault();
  });
  // mouse input
  self.mousePos = new Vec2d(0, 0);
  addListener(self.canvas, 'mousemove', onMouseMove);
  addListener(self.canvas, 'mousedown', function(event){
    var buttonId = MOUSE_OFFSET + event.which;
    self.buttonStates[buttonId] = true;
    self.btnJustPressed[buttonId] = true;
    self.emit('buttondown', buttonId);
    self.canvas.focus();

    window.addEventListener('mouseup', onMouseUp, false);
    window.addEventListener('mousemove', onMouseMove, false);

    return bubbleEvent(self, event);

  });
  function onMouseUp(event) {
    var buttonId = MOUSE_OFFSET + event.which;
    self.buttonStates[buttonId] = false;
    self.btnJustReleased[buttonId] = true;
    self.emit('buttonup', buttonId);

    window.removeEventListener('mouseup', onMouseUp, false);
    window.removeEventListener('mousemove', onMouseMove, false);
    return bubbleEvent(self, event);
  }
  function onMouseMove(event) {
    self.mousePos = new Vec2d(
      event.pageX - self.canvas.offsetLeft,
      event.pageY - self.canvas.offsetTop);
    self.emit('mousemove', self.mousePos, MOUSE_OFFSET + event.which);
  }
  // keyboard input
  addListener(self.canvas, 'keydown', function(event){
    var buttonId = KEY_OFFSET + event.which;
    self.btnJustPressed[buttonId] = !self.buttonStates[buttonId];
    self.buttonStates[buttonId] = true;
    self.emit('buttondown', buttonId);
    return bubbleEvent(self, event);
  });
  addListener(window, 'keyup', function(event){
    var buttonId = KEY_OFFSET + event.which;
    self.btnJustReleased[buttonId] = self.buttonStates[buttonId];
    self.buttonStates[buttonId] = false;
    self.emit('buttonup', buttonId);
    return bubbleEvent(self, event);
  });
  function addListener(element, eventName, listener){
    self.listeners.push([element, eventName, listener]);
    element.addEventListener(eventName, listener, false);
  }
}

function bubbleEvent(self, event) {
  // we need to figure out whether to bubble this key event up.
  // if the button is an exception, bubble it up.
  // also if any other exceptions are pressed, bubble it up.
  // this allows ctrl+(anything) to work.
  var buttonId = KEY_OFFSET + event.which;
  if (self.buttonCaptureExceptions[buttonId] ||
    (event.ctrlKey && self.buttonCaptureExceptions[button.KeyCtrl]) ||
    (event.altKey && self.buttonCaptureExceptions[button.KeyAlt]) ||
    (event.shiftKey && self.buttonCaptureExceptions[button.KeyShift]))
  {
    return true;
  } else {
    event.preventDefault();
    return false;
  }
}

function removeListeners(self) {
  self.listeners.forEach(function(listener) {
    var element = listener[0];
    var eventName = listener[1];
    var fn = listener[2];
    element.removeEventListener(eventName, fn, false);
  });
  self.listeners = [];
}

function stopMainLoop(self) {
  cancelAnimationFrame(self.animationFrameId);
  clearTimeout(self.timeoutId);
}

function fallbackRequestAnimationFrame(cb) {
  return setTimeout(function() {
    var timestamp = (new Date()).getTime();
    cb(timestamp);
  }, targetSpf * 1000);
}

function showLoadProgressBar(self) {
  resources.on('progress', onProgress);
  resources.on('ready', onReady);
  self.on('draw', onDraw);
  var percent = 0;

  function onProgress(complete, total) {
    percent = total === 0 ? 1 : complete / total;
  }
  function onReady() {
    resources.removeListener('progress', onProgress);
    resources.removeListener('ready', onReady);
    self.removeListener('draw', onDraw);
  }
  function onDraw(context) {
    context.save();
    context.setTransform(1, 0, 0, 1, 0, 0); // identity

    // clear to black
    context.fillStyle = "#000000";
    context.fillRect(0, 0, self.size.x, self.size.y);
    // draw a progress bar
    var barRadius = Math.floor(self.size.y / 20);
    var centerY = Math.floor(self.size.y / 2);
    var margin = 5;
    // outline
    context.strokeStyle = "#ffffff";
    context.lineWidth = 2;
    context.strokeRect(margin, centerY - barRadius,
        self.size.x - margin * 2, barRadius * 2);
    // inside
    context.fillStyle = "#ffffff";
    var width = percent * (self.size.x - margin * 4);
    context.fillRect(margin * 2, centerY - barRadius + margin,
        width, barRadius * 2 - margin * 2);
    // text
    context.font = "18px sans-serif";
    context.fillStyle = "#000000";
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText("Loading... " + Math.floor(percent * 100) + "%",
        margin * 2 + Math.floor(width / 2), centerY);

    context.restore();
  }
}

var vec2d = require('vec2d');
var Batch = require('batch2');
var util = require('util');
var EventEmitter = require('events').EventEmitter;

// exports at bottom because we need to set up this class before
// creating an instance

util.inherits(ResourceLoader, EventEmitter);
function ResourceLoader() {
  EventEmitter.call(this);

  this.ready = false;
  this.text = {};
  this.animations = null;
  this.spritesheet = null;
  this.useSpritesheet = true;
}

ResourceLoader.prototype.bootstrap = function() {
  bootstrap(this);
};

ResourceLoader.prototype.getTextFile = getTextFile;

// extract an image from the spritesheet
ResourceLoader.prototype.getImage = function(name, frameIndex) {
  if (frameIndex == null) frameIndex = 0;
  var anim = this.animations[name];
  var buffer = document.createElement('canvas');
  var frame = anim.frames[frameIndex];
  buffer.width = frame.size.x;
  buffer.height = frame.size.y;
  var context = buffer.getContext('2d');
  context.drawImage(this.spritesheet,
      frame.pos.x, frame.pos.y,
      frame.size.x, frame.size.y,
      0, 0,
      frame.size.x, frame.size.y);
  return buffer;
};

function bootstrap(self) {
  var batch = new Batch();
  if (self.useSpritesheet) {
    batch.push(loadSpritesheet);
    batch.push(loadAnimationsJson);
  }
  for (var path in self.text) {
    batch.push(generateLoadText(path));
  }

  batch.on('progress', function(e) {
    self.emit('progress', e);
  });

  // allow the event loop to process one time
  // so that the user can get their on('ready') hook in
  setTimeout(executeBatch);

  function executeBatch() {
    batch.end(function(err) {
      if (err) {
        self.emit('error', err);
        return;
      }
      self.ready = true;
      self.emit('ready');
    });
  }

  function loadAnimationsJson(cb) {
    self.spritesheet = new Image();
    self.spritesheet.src = "spritesheet.png";
    self.spritesheet.onload = function(){
      cb();
    };
  }

  function loadSpritesheet(cb) {
    getTextFile("animations.json", function(err, text) {
      if (err) return cb(err);

      self.animations = JSON.parse(text);
      // cache some values so don't have to compute them all the time
      for (var name in self.animations) {
        var anim = self.animations[name];
        anim.duration = anim.delay * anim.frames.length;
        anim.name = name;
        anim.anchor = vec2d(anim.anchor);
        for (var i = 0; i < anim.frames.length; ++i) {
          var frame = anim.frames[i];
          frame.pos = vec2d(frame.pos);
          frame.size = vec2d(frame.size);
        }
      }
      cb();
    });
  }

  function generateLoadText(path) {
    return function(cb) {
      getTextFile(path, cb);
    };
  }
}

function getTextFile(path, cb) {
  var request = new XMLHttpRequest();
  request.onreadystatechange = onReadyStateChange;
  request.open("GET", path, true);
  try {
    request.send();
  } catch (err) {
    cb(err);
  }
  function onReadyStateChange() {
    if (request.readyState !== 4) return;
    if (Math.floor(request.status / 100) === 2) {
      cb(null, request.responseText);
      return;
    }
    cb(new Error(request.status + ": " + request.statusText));
  }
}

module.exports = new ResourceLoader();

var vec2d = require('vec2d');

module.exports = Animation;

function Animation() {
  this.delay = 0.1;
  this.loop = true;
  this.spritesheet = null;
  this.duration = 0;
  this.anchor = vec2d(0, 0);
  this.frames = [];
}

Animation.fromImage = function(image, o) {
  o = o || {};
  var anim = new Animation();
  anim.spritesheet = image;
  anim.anchor = vec2d(o.anchor);
  anim.loop = false;
  anim.addFrame(vec2d(0, 0), vec2d(image.width, image.height));
  return anim;
};

Animation.fromJson = function(o) {
  var anim = new Animation();
  anim.delay = o.delay;
  anim.spritesheet = o.spritesheet;
  anim.anchor = vec2d(o.anchor);
  anim.loop = !!o.loop;
  anim.frames = [];

  var frames = o.frames || [];
  for (var i = 0; i < frames.length; ++i) {
    var frame = frames[i];
    anim.addFrame(vec2d(frame.pos), vec2d(frame.size));
  }
  return anim;
};

Animation.prototype.addFrame = function(pos, size) {
  this.frames.push(new Frame(pos, size));
  this.calcDuration();
};

Animation.prototype.removeFrame = function(index) {
  this.frames.splice(index, 1);
  this.calcDuration();
};

Animation.prototype.clearFrames = function() {
  this.frames = [];
  this.calcDuration();
};

Animation.prototype.calcDuration = function() {
  this.duration = this.delay * this.frames.length;
}

Animation.prototype.setDelay = function(delay) {
  this.delay = delay;
  this.calcDuration();
};

// extract an image from the spritesheet
Animation.prototype.getImage = function(frameIndex) {
  if (frameIndex == null) frameIndex = 0;
  var buffer = document.createElement('canvas');
  var frame = this.frames[frameIndex];
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

function Frame(pos, size) {
  this.pos = pos;
  this.size = size;
}

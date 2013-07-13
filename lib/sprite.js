var Vec2d = require('vec2d').Vec2d;
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var resources = require('./resources');

module.exports = Sprite;

Sprite.idCount = 0;

util.inherits(Sprite, EventEmitter);
function Sprite(animationName, params) {
  EventEmitter.call(this);
  params = params || {};

  // defaults
  this.pos         = params.pos == null ? new Vec2d(0, 0) : params.pos;
  this.scale       = params.scale == null ? new Vec2d(1, 1) : params.scale;
  this.zOrder      = params.zOrder == null ? 0 : params.zOrder;
  this.batch       = params.batch;
  this.rotation    = params.rotation == null ? 0 : params.rotation;
  this.alpha       = params.alpha == null ? 1 : params.alpha;

  this.id = Sprite.idCount++;
  this.setAnimationName(animationName);
  this.setLoop(params.loop);
  this.setVisible(params.visible == null ? true : params.visible);
  this.setFrameIndex(params.frameIndex == null ? 0 : params.frameIndex);
  if (resources.animations == null) {
    throw new Error("You may not create Sprites until the onReady event has been fired from Chem.");
  }
}

Sprite.prototype.setAnimationName = function(animationName){
  var anim = resources.animations[animationName];
  if (anim == null) {
    throw new Error("name not found in animation list: " + animationName);
  }
  this.setAnimation(resources.animations[animationName]);
};

Sprite.prototype.setAnimation = function(animation){
  this.animation = animation;
  this.animationName = this.animation.name;
  this._loop = this.loop == null ? this.animation.loop : this.loop;
  // size of first frame, which does not take scale into account
  this.size = this.animation.frames[0].size;
};

// takes scale and current frame into account
Sprite.prototype.getSize = function(){
  return this.animation.frames[this.getFrameIndex()].size.times(this.scale.applied(Math.abs));
};

// convenience
Sprite.prototype.getAnchor = function(){
  return this.animation.anchor.times(this.scale.applied(Math.abs));
};
Sprite.prototype.getTopLeft = function(){
  return this.pos.minus(this.getAnchor());
};
Sprite.prototype.getBottomRight = function(){
  return this.getTopLeft().plus(this.getSize());
};
Sprite.prototype.getTop = function(){
  return this.getTopLeft().y;
};
Sprite.prototype.getLeft = function(){
  return this.getTopLeft().x;
};
Sprite.prototype.getBottom = function(){
  return this.getBottomRight().y;
};
Sprite.prototype.getRight = function(){
  return this.getBottomRight().x;
};
Sprite.prototype.setLeft = function(x){
  this.pos.x = x + this.animation.anchor.x;
};
Sprite.prototype.setRight = function(x){
  this.pos.x = x - this.animation.anchor.x;
};
Sprite.prototype.setTop = function(y){
  this.pos.y = y + this.animation.anchor.y;
};
Sprite.prototype.setBottom = function(y){
  this.pos.y = y - this.animation.anchor.y;
};
Sprite.prototype.isTouching = function(sprite){
  var a_tl = this.getTopLeft();
  var a_br = this.getBottomRight();
  var b_tl = sprite.getTopLeft();
  var b_br = sprite.getBottomRight();
  var notTouching = a_tl.x >= b_br.x || a_br.x <= b_tl.x || a_tl.y >= b_br.y || a_br.y <= b_tl.y;
  return !notTouching;
};
Sprite.prototype.hitTest = function(pt) {
  var tl = this.getTopLeft();
  var br = this.getBottomRight();
  return pt.x >= tl.x && pt.y >= tl.y && pt.x < br.x && pt.y < br.y;
};
Sprite.prototype.setVisible = function(visible){
  this.visible = visible;
  if (this.batch == null) {
    return;
  }
  if (this.visible) {
    this.batch.add(this);
  } else {
    this.batch.remove(this);
  }
};
Sprite.prototype.setZOrder = function(zOrder){
  if (this.batch != null) {
    this.batch.remove(this);
    this.zOrder = zOrder;
    this.batch.add(this);
  } else {
    this.zOrder = zOrder;
  }
};
Sprite.prototype.setFrameIndex = function(frameIndex){
  var secondsPassed = frameIndex * this.animation.delay;
  var date = new Date();
  date.setMilliseconds(date.getMilliseconds() - secondsPassed * 1000);
  this.setAnimationStartDate(date);
};
Sprite.prototype.setLoop = function(loop){
  // this is the actual value we'll use to check if we're going to loop.
  this.loop = !!loop;
  this._loop = this.loop == null ? this.animation.loop : this.loop;
  this.setUpInterval();
};
Sprite.prototype.setAnimationStartDate = function(animationStartDate){
  this.animationStartDate = animationStartDate;
  this.setUpInterval();
};
Sprite.prototype.getFrameIndex = function(){
  var ref$, ref1$;
  var now = new Date();
  var totalTime = (now - this.animationStartDate) / 1000;
  if (this._loop) {
    return Math.floor((totalTime % this.animation.duration) / this.animation.delay);
  } else {
    return (ref$ = Math.floor(totalTime / this.animation.delay)) < (ref1$ = this.animation.frames.length - 1) ? ref$ : ref1$;
  }
};
Sprite.prototype['delete'] = function(){
  if (this.batch) this.batch.remove(this);
  this.batch = null;
};
// private
Sprite.prototype.setUpInterval = function(){
  var self = this;
  if (this.interval) this.interval.cancel();
  var _schedule = this._loop ? schedule : wait;
  var now = new Date();
  var timeSinceStart = (now - this.animationStartDate) / 1000;
  var duration = this.animation.duration - timeSinceStart;
  this.interval = _schedule(duration, function(){
    return self.emit('animationend');
  });
};

function wait(sec, cb) {
  var interval = setTimeout(cb, sec * 1000);
  return {
    cancel: function(){
      if (interval != null) {
        clearTimeout(interval);
        interval = null;
      }
    }
  };
}

function schedule(sec, cb) {
  var interval = setInterval(cb, sec * 1000);
  return {
    cancel: function(){
      if (interval != null) {
        clearInterval(interval);
        interval = null;
      }
    }
  };
}

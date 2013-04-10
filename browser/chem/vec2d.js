var _exports = window.Chem || (window.Chem = {});
_exports.Vec2d = v;
v.Vec2d = Vec2d;

var re = /\((-?[.\d]+), (-?[.\d]+)\)/;

function Vec2d(x, y) {
  this.x = x;
  this.y = y;
}

function v(xOrPair, y){
  if (xOrPair == null) {
    return new Vec2d(0, 0, 0);
  } else if (Array.isArray(xOrPair)) {
    return new Vec2d(parseFloat(xOrPair[0], 10), parseFloat(xOrPair[1], 10));
  } else if (typeof xOrPair === 'object') {
    return new Vec2d(parseFloat(xOrPair.x, 10), parseFloat(xOrPair.y, 10));
  } else if (typeof xOrPair === 'string' && y == null) {
    var match = xOrPair.match(re);
    if (match) {
      return new Vec2d(parseFloat(match[1], 10), parseFloat(match[2], 10));
    } else {
      throw new Error("Vec2d: cannot parse: " + xOrPair);
    }
  } else {
    return new Vec2d(parseFloat(xOrPair, 10), parseFloat(y, 10));
  }
}

Vec2d.prototype.offset = function(dx, dy){
  return new Vec2d(this.x + dx, this.y + dy);
};
Vec2d.prototype.add = function(other){
  this.x += other.x;
  this.y += other.y;
  return this;
};
Vec2d.prototype.sub = function(other){
  this.x -= other.x;
  this.y -= other.y;
  return this;
};
Vec2d.prototype.plus = function(other){
  return this.clone().add(other);
};
Vec2d.prototype.minus = function(other){
  return this.clone().sub(other);
};
Vec2d.prototype.neg = function(){
  this.x = -this.x;
  this.y = -this.y;
  return this;
};
Vec2d.prototype.mult = function(other){
  this.x *= other.x;
  this.y *= other.y;
  return this;
};
Vec2d.prototype.times = function(other){
  return this.clone().mult(other);
};
Vec2d.prototype.div = function(other){
  this.x /= other.x;
  this.y /= other.y;
  return this;
};
Vec2d.prototype.divBy = function(other){
  return this.clone().div(other);
};
Vec2d.prototype.scale = function(scalar){
  this.x *= scalar;
  this.y *= scalar;
  return this;
};
Vec2d.prototype.scaled = function(scalar){
  return this.clone().scale(scalar);
};
Vec2d.prototype.clone = function(){
  return new Vec2d(this.x, this.y);
};
Vec2d.prototype.apply = function(func){
  this.x = func(this.x);
  this.y = func(this.y);
  return this;
};
Vec2d.prototype.applied = function(func){
  return this.clone().apply(func);
};
Vec2d.prototype.distanceSqrd = function(other){
  var dx = other.x - this.x;
  var dy = other.y - this.y;
  return dx * dx + dy * dy;
};
Vec2d.prototype.distance = function(other){
  return Math.sqrt(this.distanceSqrd(other));
};
Vec2d.prototype.equals = function(other){
  return this.x === other.x && this.y === other.y;
};
Vec2d.prototype.toString = function(){
  return "(" + this.x + ", " + this.y + ")";
};
Vec2d.prototype.lengthSqrd = function(){
  return this.x * this.x + this.y * this.y;
};
Vec2d.prototype.length = function(){
  return Math.sqrt(this.lengthSqrd());
};
Vec2d.prototype.angle = function(){
  if (this.lengthSqrd() === 0) {
    return 0;
  } else {
    return Math.atan2(this.y, this.x);
  }
};
Vec2d.prototype.normalize = function(){
  var length;
  length = this.length();
  if (length === 0) {
    return this;
  } else {
    return this.scale(1 / length);
  }
};
Vec2d.prototype.normalized = function(){
  return this.clone().normalize();
};
Vec2d.prototype.boundMin = function(other){
  if (this.x < other.x) {
    this.x = other.x;
  }
  if (this.y < other.y) {
    return this.y = other.y;
  }
};
Vec2d.prototype.boundMax = function(other){
  if (this.x > other.x) {
    this.x = other.x;
  }
  if (this.y > other.y) {
    return this.y = other.y;
  }
};
Vec2d.prototype.floor = function(){
  return this.apply(Math.floor);
};
Vec2d.prototype.floored = function(){
  return this.applied(Math.floor);
};
Vec2d.prototype.ceil = function(){
  return this.apply(Math.ceil);
};
Vec2d.prototype.ceiled = function(){
  return this.applied(Math.ceil);
};
Vec2d.prototype.project = function(other){
  this.scale(this.dot(other) / other.lengthSqrd());
  return this;
};
Vec2d.prototype.dot = function(other){
  return this.x * other.x + this.y * other.y;
};
Vec2d.prototype.rotate = function(other){
  this.x = this.x * other.x - this.y * other.y;
  this.y = this.x * other.y + this.y * other.x;
  return this;
};

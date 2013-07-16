var Vec2d = require('vec2d').Vec2d;

module.exports = Label;

Label.idCount = 0;

function Label(text, params) {
  this.text        = text;

  params = params || {};
  this.pos         = params.pos == null ? new Vec2d(0, 0) : params.pos;
  this.scale       = params.scale == null ? new Vec2d(1, 1) : params.scale;
  this.zOrder      = params.zOrder == null ? 0 : params.zOrder;
  this.batch       = params.batch;
  this.rotation    = params.rotation == null ? 0 : params.rotation;
  this.alpha       = params.alpha == null ? 1 : params.alpha;

  this.font        = params.font == null ? "10px sans-serif" : params.font;
  this.textAlign   = params.textAlign == null ? "start" : params.textAlign;
  this.textBaseline= params.textBaseline == null ? "alphabetic" : params.textBaseline;

  this.fill        = params.fill == null ? true : params.fill;
  this.fillStyle   = params.fillStyle == null ? "#000000" : params.fillStyle;

  this.stroke      = !!params.stroke;
  this.lineWidth   = params.lineWidth == null ? 1 : params.lineWidth;
  this.strokeStyle = params.strokeStyle == null ? "#000000" : params.strokeStyle;

  this.id = Label.idCount++;
  this.setVisible(params.visible == null ? true : params.visible);
}

Label.prototype.draw = function(context) {
  context.save();
  context.font = this.font;
  context.textAlign = this.textAlign;
  context.textBaseline = this.textBaseline;
  context.translate(this.pos.x, this.pos.y);
  context.scale(this.scale.x, this.scale.y);
  context.rotate(this.rotation);
  context.globalAlpha = this.alpha;
  if (this.fill) {
    context.fillStyle = this.fillStyle;
    context.fillText(this.text, 0, 0);
  }
  if (this.stroke) {
    context.strokeStyle = this.strokeStyle;
    context.lineWidth = this.lineWidth;
    context.strokeText(this.text, 0, 0);
  }
  context.restore();
};

Label.prototype.setVisible = function(visible){
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

Label.prototype.setZOrder = function(zOrder){
  if (this.batch != null) {
    this.batch.remove(this);
    this.zOrder = zOrder;
    this.batch.add(this);
  } else {
    this.zOrder = zOrder;
  }
};

Label.prototype.delete = function() {
  if (this.batch) this.batch.remove(this);
  this.batch = null;
};

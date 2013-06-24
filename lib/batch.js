module.exports = Batch;

function Batch() {
  // indexed by zOrder
  this.sprites = [];
}

Batch.prototype.add = function(sprite) {
  if (sprite.batch) sprite.batch.remove(sprite);
  sprite.batch = this;
  if (sprite.visible) {
    var o = this.sprites[sprite.zOrder];
    if (! o) o = this.sprites[sprite.zOrder] = {};
    o[sprite.id] = sprite;
  }
};

Batch.prototype.remove = function(sprite) {
  var o = this.sprites[sprite.zOrder];
  if (o) delete o[sprite.id];
};

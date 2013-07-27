module.exports = Batch;

function Batch() {
  // indexed by zOrder
  this.layers = [];
}

Batch.prototype.add = function(item) {
  if (item.batch) item.batch.remove(item);
  item.batch = this;
  if (item.visible) {
    var o = this.layers[item.zOrder];
    if (! o) o = this.layers[item.zOrder] = [];
    o.push(item);
  }
};

Batch.prototype.remove = function(item) {
  var o = this.layers[item.zOrder];
  if (!o) return;
  for (var i = 0; i < o.length; i += 1) {
    if (o[i] === item) {
      o.splice(i, 1);
      return;
    }
  }
};

Batch.prototype.draw = function(context) {
  for (var i = 0; i < this.layers.length; ++i) {
    var layer = this.layers[i];
    for (var spriteIndex = 0; spriteIndex < layer.length; spriteIndex += 1) {
      layer[spriteIndex].draw(context);
    }
  }
};

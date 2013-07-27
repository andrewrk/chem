module.exports = Batch;

function Batch() {
  // indexed by zOrder
  this.layers = [];
}

Batch.prototype.add = function(item) {
  if (item.batch) item.batch.remove(item);
  item.batch = this;
  if (item.visible) {
    var layer = this.layers[item.zOrder];
    if (! layer) layer = this.layers[item.zOrder] = [];
    layer.push(item);
  }
};

Batch.prototype.remove = function(item) {
  var layer = this.layers[item.zOrder];
  if (!layer) return;
  var index = layer.indexOf(item);
  if (index >= 0) layer.splice(index, 1);
};

Batch.prototype.draw = function(context) {
  for (var i = 0; i < this.layers.length; ++i) {
    var layer = this.layers[i];
    if (!layer) continue;
    for (var spriteIndex = 0; spriteIndex < layer.length; spriteIndex += 1) {
      layer[spriteIndex].draw(context);
    }
  }
};

Batch.prototype.clear = function(context) {
  for (var i = 0; i < this.layers.length; ++i) {
    var layer = this.layers[i];
    if (!layer) continue;
    for (var spriteIndex = 0; spriteIndex < layer.length; spriteIndex += 1) {
      var sprite = layer[spriteIndex];
      sprite.batch = null;
      sprite['delete']();
    }
  }
  this.layers = [];
};

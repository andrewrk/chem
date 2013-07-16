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
    if (! o) o = this.layers[item.zOrder] = {};
    o[item.id] = item;
  }
};

Batch.prototype.remove = function(item) {
  var o = this.layers[item.zOrder];
  if (o) delete o[item.id];
};

Batch.prototype.draw = function(context) {
  for (var i = 0; i < this.layers.length; ++i) {
    var layer = this.layers[i];
    for (var id in layer) {
      var item = layer[id];
      item.draw(context);
    }
  }
};

(function(){
  var _exports = window.Chem || (window.Chem = {});
  _exports.Batch = Batch;

  function Batch() {
    // indexed by z_order
    this.sprites = [];
  }

  Batch.prototype.add = function(sprite) {
    if (sprite.batch) sprite.batch.remove(sprite);
    sprite.batch = this;
    if (sprite.visible) {
      var o = this.sprites[sprite.z_order];
      if (! o) o = this.sprites[sprite.z_order] = {};
      o[sprite.id] = sprite;
    }
  };

  Batch.prototype.remove = function(sprite) {
    var o = this.sprites[sprite.z_order];
    if (o) delete o[sprite.id];
  };
}).call(this);

var resources = require('./lib/resources');

module.exports = {
  vec2d: require('vec2d'),
  button: require('./lib/button'),
  resources: resources,

  Engine: require('./lib/engine'),
  Sound: require('./lib/sound'),
  Sprite: require('./lib/sprite'),
  Label: require('./lib/label'),
  Batch: require('./lib/batch'),
};

var resources = require('./lib/resources');

module.exports = {
  vec2d: require('vec2d'),
  Engine: require('./lib/engine'),
  button: require('./lib/button'),
  Sound: require('./lib/sound'),
  Sprite: require('./lib/sprite'),
  Label: require('./lib/label'),
  Batch: require('./lib/batch'),
  resources: resources,
  onReady: resources.onReady,
};

resources.bootstrap();

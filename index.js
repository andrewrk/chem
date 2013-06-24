var resources = require('./lib/resources');

module.exports = {
  vec2d: require('vec2d'),
  Engine: require('./lib/engine'),
  button: require('./lib/button'),
  Sound: require('./lib/sound'),
  Sprite: require('./lib/sprite'),
  Batch: require('./lib/batch'),
  onReady: resources.onReady,
  animations: resources.animations,
  spritesheet: resources.spritesheet,
};

resources.bootstrap();

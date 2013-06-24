var vec2d = require('vec2d');

var onReadyQueue = [];

// set assetsLoaded after all assets are done loading
var assetsLoaded = false;
var spritesheetDone = false;
var animationsJsonDone = false;
var alreadyStarted = false;

exports.bootstrap = bootstrap;
exports.onReady = onReady;
exports.animations = null;
exports.spritesheet = null;
exports.useSpritesheet = true;
exports.getImage = getImage;

function onReady(cb) {
  if (assetsLoaded) {
    cb();
  } else {
    onReadyQueue.push(cb);
  }
}

function bootstrap(){
  // don't bootstrap twice
  if (alreadyStarted) return;
  alreadyStarted = true;

  // give the app a chance to skip spritesheet loading
  setTimeout(loadSpritesheet);

  function checkDoneLoading(){
    if (spritesheetDone && animationsJsonDone) {
      assetsLoaded = true;
      onReadyQueue.forEach(function(cb) {
        cb();
      });
    }
  }

  function loadSpritesheet() {
    if (!exports.useSpritesheet) {
      spritesheetDone = true;
      animationsJsonDone = true;
      return checkDoneLoading();
    }
    // get the spritesheet
    exports.spritesheet = new Image();
    exports.spritesheet.src = "spritesheet.png";
    exports.spritesheet.onload = function(){
      spritesheetDone = true;
      checkDoneLoading();
    };
    // get the animations.json file
    var request = new XMLHttpRequest();
    request.onreadystatechange = function(){
      if (!(request.readyState === 4 && request.status === 200)) {
        return;
      }
      exports.animations = JSON.parse(request.responseText);
      // cache some values so don't have to compute them all the time
      for (var name in exports.animations) {
        var anim = exports.animations[name];
        anim.duration = anim.delay * anim.frames.length;
        anim.name = name;
        anim.anchor = vec2d(anim.anchor);
        for (var i = 0; i < anim.frames.length; ++i) {
          var frame = anim.frames[i];
          frame.pos = vec2d(frame.pos);
          frame.size = vec2d(frame.size);
        }
      }
      animationsJsonDone = true;
      checkDoneLoading();
    };
    request.open("GET", "animations.json", true);
    request.send();
  }
}

function getImage(name, frameIndex){
  if (frameIndex == null) frameIndex = 0;
  var anim = exports.animations[name];
  var buffer = document.createElement('canvas');
  var frame = anim.frames[frameIndex];
  buffer.width = frame.size.x;
  buffer.height = frame.size.y;
  var context = buffer.getContext('2d');
  context.drawImage(exports.spritesheet,
      frame.pos.x, frame.pos.y,
      frame.size.x, frame.size.y,
      0, 0,
      frame.size.x, frame.size.y);
  return buffer;
}


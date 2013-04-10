//depend "chem/vec2d"
var Vec2d, _exports, ref$, _private;
Vec2d = (window.Chem || (window.Chem = {})).Vec2d;
_exports = window.Chem || (window.Chem = {});
_private = (ref$ = window.Chem || (window.Chem = {})).Private || (ref$.Private = {});
_exports.bootstrap = function(){
  var on_ready_queue, assets_loaded, spritesheet_done, animations_json_done, checkDoneLoading;
  // load assets
  on_ready_queue = [];
  _exports.onReady = function(cb){
    if (assets_loaded) {
      cb();
    } else {
      on_ready_queue.push(cb);
    }
  };

  // set assets_loaded after all assets are done loading
  assets_loaded = false;
  spritesheet_done = false;
  animations_json_done = false;
  checkDoneLoading = function(){
    var i$, ref$, len$, cb;
    if (spritesheet_done && animations_json_done) {
      assets_loaded = true;
      _exports.animations = _private.animations;
      _exports.spritesheet = _private.spritesheet;
      for (i$ = 0, len$ = (ref$ = on_ready_queue).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        cb();
      }
    }
  };

  // give the app a chance to skip spritesheet loading
  _exports.use_spritesheet = true;
  setTimeout(function(){
    var request;
    if (!_exports.use_spritesheet) {
      spritesheet_done = true;
      animations_json_done = true;
      return checkDoneLoading();
    }
    // get the spritesheet
    _private.spritesheet = new Image();
    _private.spritesheet.src = "spritesheet.png";
    _private.spritesheet.onload = function(){
      spritesheet_done = true;
      checkDoneLoading();
    };
    // get the animations.json file
    request = new XMLHttpRequest();
    request.onreadystatechange = function(){
      var name, ref$, anim, i$, ref1$, len$, frame;
      if (!(request.readyState === 4 && request.status === 200)) {
        return;
      }
      _private.animations = JSON.parse(request.responseText);
      // cache some values so don't have to compute them all the time
      for (name in ref$ = _private.animations) {
        anim = ref$[name];
        anim.duration = anim.delay * anim.frames.length;
        anim.name = name;
        anim.anchor = Vec2d(anim.anchor);
        for (i$ = 0, len$ = (ref1$ = anim.frames).length; i$ < len$; ++i$) {
          frame = ref1$[i$];
          frame.pos = Vec2d(frame.pos);
          frame.size = Vec2d(frame.size);
        }
      }
      animations_json_done = true;
      checkDoneLoading();
    };
    request.open("GET", "animations.json", true);
    request.send();
  });
};

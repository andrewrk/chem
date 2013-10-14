var vec2d = require('vec2d');
var Pend = require('pend');
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var Animation = require('./animation');

// exports at bottom because we need to set up this class before
// creating an instance

util.inherits(ResourceLoader, EventEmitter);
function ResourceLoader() {
  EventEmitter.call(this);

  this.ready = false;
  this.text = {};
  this.images = {};
  this.animations = {};
  this.spritesheet = null;
  this.useSpritesheet = true;
  this.prefix = "";
}

ResourceLoader.prototype.bootstrap = function() {
  bootstrap(this);
};

ResourceLoader.prototype.url = function(relativeUrl) {
  if (this.prefix) {
    var lastChar = this.prefix[this.prefix.length - 1];
    if (lastChar === '/') {
      return this.prefix + relativeUrl;
    } else {
      return this.prefix + '/' + relativeUrl;
    }
  } else {
    return relativeUrl;
  }
};

ResourceLoader.prototype.fetchTextFile = function(path, cb) {
  var request = new XMLHttpRequest();
  request.onreadystatechange = onReadyStateChange;
  request.open("GET", this.url(path), true);
  try {
    request.send();
  } catch (err) {
    cb(err);
  }
  function onReadyStateChange() {
    if (request.readyState !== 4) return;
    if (Math.floor(request.status / 100) === 2) {
      cb(null, request.responseText);
      return;
    }
    cb(new Error(request.status + ": " + request.statusText));
  }
}

ResourceLoader.prototype.fetchImage = function (path, cb) {
  var img = new Image();
  img.src = this.url(path);
  img.onload = function(){
    cb(null, img);
  };
}

function bootstrap(self) {
  var pend = new Pend();
  var total = 0;
  var complete = 0;
  if (self.useSpritesheet) {
    addLoader(loadSpritesheet);
    addLoader(loadAnimationsJson);
  }
  var name;
  for (name in self.text) {
    addLoader(generateLoadText(name));
  }
  for (name in self.images) {
    addLoader(generateLoadImage(name));
  }

  // allow the event loop to process one time
  // so that the user can get their on('ready') hook in
  setTimeout(executeBatch, 0);

  function executeBatch() {
    pend.wait(function(err) {
      if (err) {
        self.emit('error', err);
        return;
      }
      for (var name in self.animations) {
        self.animations[name].spritesheet = self.spritesheet;
      }
      self.ready = true;
      self.emit('ready');
    });
  }

  function addLoader(load) {
    total += 1;
    pend.go(function(cb) {
      load(function(err) {
        complete += 1;
        self.emit('progress', complete, total);
        cb(err);
      });
    });
  }

  function loadAnimationsJson(cb) {
    self.fetchImage("spritesheet.png", function(err, img) {
      if (err) return cb(err);
      self.spritesheet = img;
      cb();
    });
  }

  function loadSpritesheet(cb) {
    self.fetchTextFile("animations.json", function(err, text) {
      if (err) return cb(err);

      var animationsJson = JSON.parse(text);
      for (var name in animationsJson) {
        self.animations[name] = Animation.fromJson(animationsJson[name]);
      }
      cb();
    });
  }

  function generateLoadText(name) {
    var path = self.text[name];
    return function(cb) {
      self.fetchTextFile(path, function(err, contents) {
        if (err) return cb(err);
        self.text[name] = contents;
        cb();
      });
    };
  }

  function generateLoadImage(name) {
    var path = self.images[name];
    return function(cb) {
      self.fetchImage(path, function(err, img) {
        if (err) return cb(err);
        self.images[name] = img;
        cb();
      });
    };
  }
}


module.exports = new ResourceLoader();

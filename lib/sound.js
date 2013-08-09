var EventEmitter = require('events').EventEmitter;
var util = require('util');

module.exports = Sound;

function Sound(src) {
  EventEmitter.call(this);

  this.currentSrc = src;
  this.audioPool = [new Audio(src)];
  this.maxPoolSize = 10;
  this.volume = 1;
  this.preload = "auto";
  this.playbackRate = 1;
  this.buffered = 0;
  this.duration = null;

  applySettings(this);
  progressHooks(this);
}
util.inherits(Sound, EventEmitter);

Sound.prototype.play = function() {
  var oldest = null;
  var oldestCurrentTime = -1;
  // play a ready one
  for (var i = 0; i < this.audioPool.length; ++i) {
    var audio = this.audioPool[i];
    if (audioReadyToPlay(audio)) {
      audio.play();
      return audio;
    } else if (audio.currentTime > oldestCurrentTime) {
      oldestCurrentTime = audio.currentTime;
      oldest = audio;
    }
  }
  // add a new one to the pool and play that one
  if (this.audioPool.length < this.maxPoolSize) {
    var newAudio = new Audio(this.currentSrc);
    applySettingsToAudio(this, newAudio);
    newAudio.play();
    this.audioPool.push(newAudio);
    return newAudio;
  }
  // recycle the oldest one
  oldest.currentTime = 0;
  oldest.play();
  return oldest;
};

Sound.prototype.stop = function() {
  for (var i = 0; i < this.audioPool.length; ++i) {
    var audio = this.audioPool[i];
    audio.pause();
    audio.currentTime = 0;
  }
};

Sound.prototype.setVolume = function(vol) {
  this.volume = vol;
  applySettings(this);
};

Sound.prototype.setPreload = function(preload) {
  this.preload = preload;
  applySettings(this);
};

Sound.prototype.setPlaybackRate = function(rate) {
  this.playbackRate = rate;
  applySettings(this);
};

function applySettings(self) {
  for (var i = 0; i < self.audioPool.length; ++i) {
    applySettingsToAudio(self, self.audioPool[i]);
  }
}

function applySettingsToAudio(self, audio) {
  audio.volume = self.volume;
  audio.preload = self.preload;
  audio.playbackRate = self.playbackRate;
  audio.defaultPlaybackRate = self.playbackRate;
}

function progressHooks(self) {
  var audio = self.audioPool[0];
  audio.addEventListener("progress", onProgress, false);
  audio.load();

  var complete = false;
  function onProgress() {
    try {
      // sometimes I get Index Size Error: DOM Exception 1
      self.buffered = audio.buffered.end(audio.buffered.length - 1);
    } catch (err) {
      return;
    }
    self.duration = audio.duration;
    self.emit('progress');
    if (! complete && self.buffered >= self.duration) {
      complete = true;
      self.emit('ready');
    }
  }
}

function audioReadyToPlay(audio) {
  return audio.currentTime === 0 || audio.currentTime === audio.duration;
}

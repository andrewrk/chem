module.exports = Sound;

function Sound(src) {
  this.currentSrc = src;
  this.audioPool = [new Audio(src)];
  this.maxPoolSize = 1000;
  this.volume = 1;
  this.preload = "auto";
  this.playbackRate = 1;

  this.applySettings();
}

function audioReadyToPlay(audio) {
  return audio.currentTime === 0 || audio.currentTime === audio.duration;
}

Sound.prototype.play = function() {
  for (var i = 0; i < this.audioPool.length; ++i) {
    var audio = this.audioPool[i];
    if (audioReadyToPlay(audio)) {
      audio.play();
      return audio;
    }
  }
  if (this.audioPool.length < this.maxPoolSize) {
    var newAudio = new Audio(this.currentSrc);
    this.applySettingsToAudio(newAudio);
    newAudio.play();
    this.audioPool.push(newAudio);
  }
};

Sound.prototype.setVolume = function(vol) {
  this.volume = vol;
  this.applySettings();
};

Sound.prototype.setPreload = function(preload) {
  this.preload = preload;
  this.applySettings();
};

Sound.prototype.setPlaybackRate = function(rate) {
  this.playbackRate = rate;
  this.applySettings();
};

Sound.prototype.applySettings = function() {
  for (var i = 0; i < this.audioPool.length; ++i) {
    this.applySettingsToAudio(this.audioPool[i]);
  }
}

Sound.prototype.applySettingsToAudio = function(audio) {
  audio.volume = this.volume;
  audio.preload = this.preload;
  audio.playbackRate = this.playbackRate;
  audio.defaultPlaybackRate = this.playbackRate;
}

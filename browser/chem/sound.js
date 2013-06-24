var _exports = window.Chem || (window.Chem = {});
_exports.Sound = Sound;

function Sound(url) {
  this.audio_pool = [new Audio(url)];
}

function audioReadyToPlay(audio) {
  return audio.currentTime === 0 || audio.currentTime === audio.duration;
}

Sound.prototype.play = function() {
  for (var i = 0; i < this.audio_pool.length; ++i) {
    if (audioReadyToPlay(audio)) {
      audio.play();
      return audio;
    }
  }
  var new_audio = new Audio(this.audio_pool[0].currentSrc);
  new_audio.play();
  this.audio_pool.push(new_audio);
};

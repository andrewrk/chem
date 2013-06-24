module.exports = Sound;

function Sound(url) {
  this.audioPool = [new Audio(url)];
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
  var newAudio = new Audio(this.audioPool[0].currentSrc);
  newAudio.play();
  this.audioPool.push(newAudio);
};

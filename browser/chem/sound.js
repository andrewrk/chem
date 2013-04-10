(function(){
  var _exports, Sound;
  _exports = window.Chem || (window.Chem = {});
  _exports.Sound = Sound = (function(){
    Sound.displayName = 'Sound';
    var audioReadyToPlay, prototype = Sound.prototype, constructor = Sound;
    audioReadyToPlay = function(it){
      return it.currentTime === 0 || it.currentTime === it.duration;
    };
    function Sound(url){
      var this$ = this instanceof ctor$ ? this : new ctor$;
      this$.audio_pool = [new Audio(url)];
      return this$;
    } function ctor$(){} ctor$.prototype = prototype;
    prototype.play = function(){
      var i$, ref$, len$, audio, new_audio;
      for (i$ = 0, len$ = (ref$ = this.audio_pool).length; i$ < len$; ++i$) {
        audio = ref$[i$];
        if (audioReadyToPlay(audio)) {
          audio.play();
          return audio;
        }
      }
      new_audio = new Audio(this.audio_pool[0].currentSrc);
      new_audio.play();
      this.audio_pool.push(new_audio);
      return new_audio;
    };
    return Sound;
  }());
}).call(this);

(function(){
  var _exports = window.Chem || (window.Chem = {});
  _exports.wait = function(sec, cb){
    var interval = setTimeout(cb, sec * 1000);
    return {
      cancel: function(){
        if (interval != null) {
          clearTimeout(interval);
          this.interval = null;
        }
      }
    };
  };
  _exports.schedule = function(sec, cb){
    var interval = setInterval(cb, sec * 1000);
    return {
      cancel: function(){
        clearInterval(interval);
      }
    };
  };
}).call(this);

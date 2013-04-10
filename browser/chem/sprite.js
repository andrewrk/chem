//depend "chem/vec2d"
//depend "chem/helpers"
//depend "chem/event_emitter"
(function(){
  var ref$, Vec2d, EventEmitter, schedule, wait, _exports, _private, Sprite;
  ref$ = window.Chem || (window.Chem = {}), Vec2d = ref$.Vec2d, EventEmitter = ref$.EventEmitter, schedule = ref$.schedule, wait = ref$.wait;
  _exports = window.Chem || (window.Chem = {});
  _private = (ref$ = window.Chem || (window.Chem = {})).Private || (ref$.Private = {});
  _exports.Sprite = Sprite = (function(superclass){
    Sprite.displayName = 'Sprite';
    var prototype = extend$(Sprite, superclass).prototype, constructor = Sprite;
    Sprite.id_count = 0;
    function Sprite(animation_name, params){
      var o, ref$, this$ = this instanceof ctor$ ? this : new ctor$;
      params == null && (params = {});
      superclass.call(this$);
      ref$ = o = import$({
        pos: Vec2d(0, 0),
        scale: Vec2d(1, 1),
        z_order: 0,
        batch: null,
        rotation: 0,
        alpha: 1,
        visible: true,
        frame_index: 0,
        loop: null
      }, params), this$.pos = ref$.pos, this$.scale = ref$.scale, this$.z_order = ref$.z_order, this$.batch = ref$.batch, this$.rotation = ref$.rotation, this$.alpha = ref$.alpha;
      this$.id = Sprite.id_count++;
      this$.setAnimationName(animation_name);
      this$.setLoop(o.loop);
      this$.setVisible(o.visible);
      this$.setFrameIndex(0);
      if (_private.animations == null) {
        throw new Error("You may not create Sprites until the onReady event has been fired from Chem.");
      }
      return this$;
    } function ctor$(){} ctor$.prototype = prototype;
    prototype.setAnimationName = function(animation_name){
      var anim;
      anim = _private.animations[animation_name];
      if (anim == null) {
        throw new Error("name not found in animation list: " + animation_name);
      }
      this.setAnimation(_private.animations[animation_name]);
    };
    prototype.setAnimation = function(animation){
      var ref$;
      this.animation = animation;
      this.animation_name = this.animation.name;
      this._loop = (ref$ = this.loop) != null
        ? ref$
        : this.animation.loop;
      // size of first frame, which does not take scale into account
      this.size = this.animation.frames[0].size;
    };
    // takes scale and current frame into account
    prototype.getSize = function(){
      return this.animation.frames[this.getFrameIndex()].size.times(this.scale.applied(Math.abs));
    };

    // convenience
    prototype.getAnchor = function(){
      return this.animation.anchor.times(this.scale.applied(Math.abs));
    };
    prototype.getTopLeft = function(){
      return this.pos.minus(this.getAnchor());
    };
    prototype.getBottomRight = function(){
      return this.getTopLeft().plus(this.getSize());
    };
    prototype.getTop = function(){
      return this.getTopLeft().y;
    };
    prototype.getLeft = function(){
      return this.getTopLeft().x;
    };
    prototype.getBottom = function(){
      return this.getBottomRight().y;
    };
    prototype.getRight = function(){
      return this.getBottomRight().x;
    };
    prototype.setLeft = function(x){
      this.pos.x = x + this.animation.anchor.x;
    };
    prototype.setRight = function(x){
      this.pos.x = x - this.animation.anchor.x;
    };
    prototype.setTop = function(y){
      this.pos.y = y + this.animation.anchor.y;
    };
    prototype.setBottom = function(y){
      this.pos.y = y - this.animation.anchor.y;
    };
    prototype.isTouching = function(sprite){
      var a_tl, a_br, b_tl, b_br, not_touching;
      a_tl = this.getTopLeft();
      a_br = this.getBottomRight();
      b_tl = sprite.getTopLeft();
      b_br = sprite.getBottomRight();
      not_touching = a_tl.x >= b_br.x || a_br.x <= b_tl.x || a_tl.y >= b_br.y || a_br.y <= b_tl.y;
      return !not_touching;
    };
    prototype.setVisible = function(visible){
      this.visible = visible;
      if (this.batch == null) {
        return;
      }
      if (this.visible) {
        this.batch.add(this);
      } else {
        this.batch.remove(this);
      }
    };
    prototype.setZOrder = function(z_order){
      if (this.batch != null) {
        this.batch.remove(this);
        this.z_order = z_order;
        this.batch.add(this);
      } else {
        this.z_order = z_order;
      }
    };
    prototype.setFrameIndex = function(frame_index){
      var seconds_passed, date;
      seconds_passed = frame_index * this.animation.delay;
      date = new Date();
      date.setMilliseconds(date.getMilliseconds() - seconds_passed * 1000);
      this.setAnimationStartDate(date);
    };
    prototype.setLoop = function(loop){
      // this is the actual value we'll use to check if we're going to loop.
      var ref$;
      this.loop = loop;
      this._loop = (ref$ = this.loop) != null
        ? ref$
        : this.animation.loop;
      this.setUpInterval();
    };
    prototype.setAnimationStartDate = function(animation_start_date){
      this.animation_start_date = animation_start_date;
      this.setUpInterval();
    };
    prototype.getFrameIndex = function(){
      var now, total_time, ref$, ref1$;
      now = new Date();
      total_time = (now - this.animation_start_date) / 1000;
      if (this._loop) {
        return Math.floor((total_time % this.animation.duration) / this.animation.delay);
      } else {
        return (ref$ = Math.floor(total_time / this.animation.delay)) < (ref1$ = this.animation.frames.length - 1) ? ref$ : ref1$;
      }
    };
    prototype['delete'] = function(){
      var ref$;
      if ((ref$ = this.batch) != null) {
        ref$.remove(this);
      }
      this.batch = null;
    };
    // private
    prototype.setUpInterval = function(){
      var ref$, _schedule, now, time_since_start, duration, this$ = this;
      if ((ref$ = this.interval) != null) {
        ref$.cancel();
      }
      _schedule = this._loop ? schedule : wait;
      now = new Date();
      time_since_start = (now - this.animation_start_date) / 1000;
      duration = this.animation.duration - time_since_start;
      this.interval = _schedule(duration, function(){
        return this$.emit('animation_end');
      });
    };
    return Sprite;
  }(EventEmitter));
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);

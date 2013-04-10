var _exports, EventEmitter, slice$ = [].slice;
_exports = window.Chem || (window.Chem = {});
_exports.EventEmitter = EventEmitter = (function(){
  EventEmitter.displayName = 'EventEmitter';
  var prototype = EventEmitter.prototype, constructor = EventEmitter;
  constructor.count = 0;
  function EventEmitter(){
    var this$ = this instanceof ctor$ ? this : new ctor$;
    this$.event_handlers = {};
    this$.next_id = 0;
    this$.prop = "__EventEmitter_" + constructor.count++ + "_id";
    return this$;
  } function ctor$(){} ctor$.prototype = prototype;
  prototype.on = function(event_name, handler){
    var ref$;
    handler[this.prop] = this.next_id;
    ((ref$ = this.event_handlers)[event_name] || (ref$[event_name] = {}))[this.next_id] = handler;
    this.next_id += 1;
  };
  prototype.removeListener = function(event_name, handler){
    var ref$;
    delete ((ref$ = this.event_handlers)[event_name] || (ref$[event_name] = {}))[handler[this.prop]];
  };
  // protected
  prototype.emit = function(event_name){
    var args, id, ref$, ref1$, h;
    args = slice$.call(arguments, 1);
    for (id in ref$ = (ref1$ = this.event_handlers)[event_name] || (ref1$[event_name] = {})) {
      h = ref$[id];
      h.apply(null, args);
    }
  };
  return EventEmitter;
}());

chem - html5 game engine optimized for rapid development
========================================================

## Usage

    # install chem
    sudo apt-get install libcairo2-dev
    sudo npm install -g chem

    # create a new project
    chem init <your_project_name>

    # run a development server which will automatically recompile your code,
    # generate your spritesheets, and serve your assets
    chem dev

    # see more commands
    chem
    
## Synopsis

[See the demo in action.](http://www.superjoesoftware.com/temp/chem-readme-demo/public/index.html)

### Layout

#### Source files

    ./chemfile.js
    ./src/main.js
    ./public/index.html
    ./assets/img/ship.png
    ./assets/img/explosion/01.png
    ...
    ./assets/img/explosion/12.png

#### Generated files

    ./public/main.js
    ./public/spritesheet.png
    ./public/animations.json

#### Note

You *do not* have to use JavaScript. A mixture of any of these languages
is supported and will be *automatically compiled* into your final script
package. JavaScript files get a top-level closure inserted around them.

 * JavaScript
 * coco
 * coffee-script
 * LiveScript
 * iced-coffee-script

### ./src/main.js
```js
//depend "chem"

var Vec2d = Chem.Vec2d;

Chem.onReady(function () {
    var canvas = document.getElementById("game");
    var engine = new Chem.Engine(canvas);
    var batch = new Chem.Batch();
    var boom = new Chem.Sound('sfx/boom.ogg');
    var ship = new Chem.Sprite('ship', {
        batch: batch,
        pos: new Vec2d(200, 200),
        rotation: Math.PI / 2
    });
    var ship_vel = new Vec2d();
    var rotation_speed = Math.PI * 0.04;
    var thrust_amt = 0.1;
    engine.on('update', function (dt, dx) {
        ship.pos.add(ship_vel);

        // rotate the ship with left and right arrow keys
        if (engine.buttonState(Chem.Button.Key_Left)) {
            ship.rotation -= rotation_speed * dx;
        }
        if (engine.buttonState(Chem.Button.Key_Right)) {
            ship.rotation += rotation_speed * dx;
        }

        // apply forward and backward thrust with up and down arrow keys
        var thrust = new Vec2d(Math.cos(ship.rotation), Math.sin(ship.rotation));
        if (engine.buttonState(Chem.Button.Key_Up)) {
            ship_vel.add(thrust.scaled(thrust_amt * dx));
        }
        if (engine.buttonState(Chem.Button.Key_Down)) {
            ship_vel.sub(thrust.scaled(thrust_amt * dx));
        }

        // press space to blow yourself up
        if (engine.buttonJustPressed(Chem.Button.Key_Space)) {
            boom.play();
            ship.setAnimationName('boom');
            ship.setFrameIndex(0);
            ship.on('animation_end', function() {
                ship.delete();
            });
        }
    });
    engine.on('draw', function (context) {
        // clear canvas to black
        context.fillStyle = '#000000'
        context.fillRect(0, 0, engine.size.x, engine.size.y);

        // draw all sprites in batch
        engine.draw(batch);

        // draw a little fps counter in the corner
        context.fillStyle = '#ffffff'
        engine.drawFps();
    });
    engine.start();
    canvas.focus();
});

```
### ./chemfile.js
```js
// extra folders to look for source files
// you can use //depend statements to include any source files in these folders.
exports.libs = [];

// the main source file which depends on the rest of your source files.
exports.main = 'src/main';

exports.spritesheet = {
  // you can override any of these in individual animation declarations
  defaults: {
    delay: 0.05,
    loop: false,
    // possible values: a Vec2d instance, or one of:
    // ["center", "topleft", "topright", "bottomleft", "bottomright",
    //  "top", "right", "bottom", "left"]
    anchor: "center"
  },
  animations: {
    boom: {
      // frames can be a list of filenames or a string to match the beginning
      // of files with. If you leave it out entirely, it defaults to the
      // animation name.
      frames: "explosion"
    },
    ship: {}
  }
};
```
### ./public/index.html
```html
<!doctype html>
<html>
  <head>
    <title>Chem Example</title>
  </head>
  <body style="text-align: center">
    <canvas id="game" width="853" height="480"></canvas>
    <p>Use the arrow keys to move around and space to destroy yourself.</p>
    <script type="text/javascript" src="main.js"></script>
  </body>
</html>
```

[See the demo in action.](http://www.superjoesoftware.com/temp/chem-readme-demo/public/index.html)

See also [Meteor Attack demo](http://www.superjoesoftware.com/temp/chem-meteor-demo/public/index.html)

## Documentation

### Developing With Chem

#### Chemfile

Start by looking at your `chemfile`. This file contains all the instructions
on how to build your game.

This file, like every other source file in your game, can be in any compile-
to-JavaScript language (including JavaScript itself) that you choose.

 * `main` - this is the entry point into your game. Chem will use
   [jspackage](https://github.com/superjoe30/jspackage/) with this as the
   input file. Often this is set to `src/main`.

 * `libs` - additional search paths for source code. Often this is used for
   a `./public/vendor/` directory so you can depend on third party packages.

   Within your code, you can use these directives:
   
    * `#depend "path/to/source"` - declares that the file must be included *before*
      the current file in the final package.
    * `#depend "some_other_file" bare` - does not include a top-level function
      wrapper in the included file.
    * `//depend "../another"` - you can do this in JavaScript too. Just use
      whatever one-line commenting syntax your language supports.
   
    See [jspackage](https://github.com/superjoe30/jspackage/) for additional
    information.

 * `spritesheet`
   - `defaults` - for each animation, these are the default values that will
     be used if you do not specify one.
   - `animations` - these will be available when you create a sprite.
     * `anchor` - the "center of gravity" point. `pos` is centered here, and
       a sprite's `rotation` rotates around this point. Use a Vec2d instance
       for this value.
     * `frames` - frames can be a list of filenames or a string to match the
       beginning of files with. if you leave it out entirely, it defaults to
       the animation name.
     * `delay` - number of seconds between frames.
     * `loop` - whether an animation should start over when it ends. You can
       override this in individual sprites.

#### Bootstrapping

The simplest way to bootstrap is to depend on "chem":

```js
//depend "chem"

Chem.onReady(function() {
    // Now you can go for it. All asssets are loaded.
});
```

However, you can choose to `depend` only on the parts of chem that you need,
which will prevent unnecessary components from being included in your package.

For example, this would only include the `Vecd2` class in your source package:

```js
//depend "chem/vec2d"

console.log((new Chem.Vec2d()).toString());
// prints "(0, 0)"
```

However, if you don't `depend` on "chem", you will need to call bootstrap
manually, otherwise the `onReady` event will never be fired:

```js
//depend "chem/bootstrap"

Chem.bootstrap();
Chem.onReady(function() {
    // ok go for it
});
```

#### Vec2d Convention

As a convention, any `Vec2d` instances you get from Chem are not clones. That
is, pay careful attention not to perform destructive behavior on the `Vec2d`
instances returned from the API.

#### Not Using a Spritesheet

If you omit the spritesheet object in your chemfile, no spritesheet files will
be generated. Be sure to set `Chem.use_spritesheet = false` in your app code to
avoiding attempting to load the missing resources.

### Reference

#### Batch

 > `//depend "chem/batch"`

A `Batch` is a set of sprites which you can conveniently draw using the
`Engine::draw(batch)` method.

`Batch::add(sprite)`:

    Adds a sprite to the batch. If called multiple times for the same sprite,
    the sprite is only added once.

`Batch::remove(sprite)`:

    Removes a sprite from the batch. OK to call multiple times.

#### Button

 > `//depend "chem/button"`

Enumeration to get the button that a person is activating. Keyboard buttons
start with `Key_` and mouse buttons start with `Mouse_`.

For example, the left mouse button is `Chem.Button.Mouse_Left` and the
right arrow key is `Chem.Button.Key_Right`.

See also:
 * `Engine::buttonState`
 * `Engine::buttonJustPressed`
 * `Engine:: 'buttondown' event (button)`
 * `Engine:: 'buttonup' event (button)`

See `src/client/chem/button.co` for the full listing.

#### Engine

 > `//depend "chem/engine"`

##### methods

`Engine::new(canvas)`

    Create an instance of the engine and bind it to a canvas:

    var engine = new Chem.Engine(document.getElementById("the-canvas"));

`Engine::setSize(size)`

    Resize the game.

`Engine::start()`

    Call this to start the main loop and start listening to events.
    
`Engine::setMinFps(min_fps)`

    If the FPS drops below this value, your engine will lag instead of trying
    to compensate with a larger dt/dx sent to `update`
    Defaults to 20.

    See also `Engine:: 'update' event(dt, dx)`
    
`Engine::stop()`

    Call this to stop the main loop and stop listening to events.

`Engine::buttonState(button)`

    Check if `button` is currently pressed. See also `Button`.

`Engine::buttonJustPressed(button)`

    Call from the `update` event. It returns true if `button` is pressed,
    but then returns false for subsequent calls until `button` is released
    and pressed again.

    See also `Button`.

`Engine::draw(batch)`

    Call from the `draw` event and pass in the `Batch` that you want to draw.
    All of the sprites will be drawn with the correct rotations, offsets,
    scaling, `z_order`, and animation applied.

`Engine::drawFps()`

    Draws the current frames per second in the corner of your game with
    whatever fillColor and font are currently set.

##### properties

`Engine::size`

    Read only. `Vec2d` instance. Use `Engine::setSize` if you want to update
    the size.

`Engine::fps`

    Read only. Contains an up to date value for the current frames per second.
    
`Engine::canvas`

    Read only. The canvas element that the engine is using.

`Engine::mouse_pos`

    Read only. `Vec2d` instance representing the current mouse position
    relative to the canvas.


##### events

These are events that you can subscribe to. See `EventEmitter` on how to
subscribe to events.

`Engine:: 'update' event (dt, dx)`
    
    Fired as often as possible, capping at about 60 FPS. Use it to compute
    the next frame in your game.

    `dt` is the "delta time" - the amount of time in seconds that has passed 
    since `update` was last fired.

    `dx` is a multiplier intended to adjust your physics. If your game is
    running perfectly smoothly at 60 FPS, `dx` will be exactly 1. If your game
    is running half as fast as it should, at 30 FPS, `dx` will be 2. `dx` is
    equal to `dt` * 60.

`Engine:: 'draw' event (context)`

    You should perform all canvas drawing based on your game state in response
    to this event.

    See also:
     * `Engine::draw`

`Engine:: 'mousemove' event (pos, button)`

    Fired when the mouse moves.
    `pos`: a `Vec2d` instance.
    `button`: an enum from `Button`.

    See also:
     * `Engine::mousePos()`

`Engine:: 'buttondown' event (button)`
`Engine:: 'buttonup' event (button)`

    Fired when the player presses a button down or up, respectively.
    `button`: an enum from `Button`.

#### EventEmitter

 > `//depend "chem/event_emitter"`

##### public

`EventEmitter::on(event_name, handler)`:

    `handler` will now be called when `event_name` is fired. 

`EventEmitter::removeListener(event_name, handler)`:

    `handler` is the one you registered with `on`. It will no longer be called
    when `event_name` is fired.

##### protected

`EventEmitter::emit(event_name, ...args)`

    Fires an `event_name` event with `args`. Listeners will be notified.

#### Sound

> `//depend "chem/sound"`

`Sound::new(url)`

    Example:

    var sound = new Chem.Sound('url/to/sound.ogg');

`Sound::play()`

    Plays the sound. If the sound is already playing, it will play another
    instance at the same time.

    Returns the HTML5 Audio object that is generating the sound, which has these
    methods: pause(), play()

    And these properties: currentTime, duration

#### Sprite

 > `//depend "chem/sprite"`

##### methods

`Sprite::new(animation_name, params)`

    Example:

    var sprite = new Chem.Sprite('some_animation_name', {
      pos: new Vec2d(0, 0),
      scale: new Vec2d(1, 1),
      z_order: 0,
      batch: some_batch,
      rotation: 0,
      visible: true,
      frame_index: 0,
      loop: true
    });
    
    All the params are optional.

`Sprite::setAnimationName(animation_name)`

    Changes the sprite's animation to the one indexed by `animation_name`.

    Note that you probably also want to call `setFrameIndex(0)` if you want
    the new animation to start from the beginning.

`Sprite::setAnimation(animation)`

    Changes the sprite's animation to `animation`.

    Note that you probably also want to call `setFrameIndex(0)` if you want
    the new animation to start from the beginning.

`Sprite::getSize()`

    Like `Sprite::size` but takes scale and current frame into account.

`Sprite::getAnchor()`

    Convenience method to get a `Vec2d` representing the anchor position.
    Takes into account scale.
    Does not take into account rotation.

`Sprite::getTopLeft()`
`Sprite::getBottomRight()`

    Convenience methods returning a `Vec2d` instance of corners of the sprite.
    Takes into account scale and current frame.
    Does not take into account rotation.

`Sprite::getTop()`
`Sprite::getLeft()`
`Sprite::getBottom()`
`Sprite::getRight()`

    Convenience methods returning the location of edges of the sprite.
    Takes into account scale and current frame.
    Does not take into account rotation.

`Sprite::setLeft(x)`
`Sprite::setRight(x)`
`Sprite::setTop(y)`
`Sprite::setBottom(y)`

    Convenience methods to set the location of edges of the sprite.
    Takes into account scale and current frame.
    Does not take into account rotation.

`Sprite::isTouching(sprite)`

    Returns boolean of whether the sprite is colliding with another.
    Takes into account scale and current frame.
    Does not take into account rotation.

`Sprite::setVisible(visible)`

    Hides the sprite but keeps it ready to display again.
    See also `Sprite::delete()`.

`Sprite::setZOrder(z_order)`

    Use to layer sprites the way you want to. Start with 0 as the bottom layer.
    When you want to put something on top, use 1 for the z_order, 2 for
    something on top of that, and so on.
    See also `Sprite::z_order`
    
`Sprite::setFrameIndex(frame_index)`

    Set the frame to show when the sprite is rendered. Animation will continue
    from this frame as usual. To find out the frame count, use
    `sprite.animation.frames.length`.

`Sprite::setLoop(loop)`

    This value overrides the animation's loop property. If set to `null`,
    it will fall back to the animation's loop property.
    See also `Sprite::loop`.

`Sprite::setAnimationStartDate(animation_start_date)`

    Does the same thing as `Sprite::setFrameIndex(frame_index)` except you
    specify a date instead of a frame index.

`Sprite::getFrameIndex()`

    Returns the index of the current frame. See also
    `Sprite::setFrameIndex(frame_index)`

`Sprite::delete()`

    Indicates that the sprite should release all resources and no longer
    display on the canvas.
    See also `Sprite::setVisible(visible)`.

##### properties

`Sprite::pos`

    `Vec2d`. Get or set the position in the canvas this sprite is drawn.

`Sprite::size`

    Read only. `Vec2d` width and height of the first frame, not taking into
    account `scale` or current frame.

`Sprite::scale`

    `Vec2d`. Get or set the scale with which the sprite is drawn.

`Sprite::z_order`

    Read only. Use `Sprite::setZOrder` to change the `z_order` of a sprite.
    
`Sprite::batch`

    Read only. Use `Batch::add(sprite)` and `Batch::remove(sprite)` to
    change this value.

`Sprite::rotation`

    Get or set the angle of the sprite, in radians. Going over 2 * pi is OK.

`Sprite::loop`

    Read only. Use `Sprite::setLoop(loop)` to set this value.

`Sprite::id`

    Read only. Uniquely identifies this `Sprite` among others.

`Sprite::animation`

    Read only. The current animation of the sprite. Properties of `animation`
    are:

     * `anchor` - `Vec2d` instance
     * `delay` - seconds
     * `loop` - boolean
     * `frames` - `[{size, pos}]` - both `size` and `pos` here are `Vec2d`s.

`Sprite::animation_name`

    Read only.

##### events

These are events that you can subscribe to. See `EventEmitter` on how to
subscribe to events.

`Sprite:: 'animation_end' event`

    Fired when the animation completes. If `loop` is true, this will be at a
    regular interval. If `loop` is false, this will fire only once, until you
    reset the frame index.

    See also:
     * `Sprite::setFrameIndex(frame_index)`

#### Vec2d

 > `//depend "chem/vec2d"`

See [node-vec2d](https://github.com/superjoe30/node-vec2d)

## Developing chem

    # set up dev environment for chem itself:
    sudo apt-get install libcairo2-dev
    sudo npm link

## History

### 0.3.0

 * rewrite chem to be faster and less error prone
 * support node.js v0.10

### 0.2.7

 * update jspackage - fixes dependencies rendered out of order sometimes

### 0.2.6

 * add sprite.alpha property

### 0.2.5

 * add `div` and `divBy` to `Vec2d`

### 0.2.4

 * correctly expose animations and spritesheet

### 0.2.3

(recalled)

### 0.2.2

 * expose animations, spritesheet, and getImage
 * throw error objects, not strings

### 0.2.1

 * add top, bottom, left, right anchor shortcuts
 * Vec2d: add ceil and ceiled
 * drawFps: text align left

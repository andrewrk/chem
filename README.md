# chem

canvas-based game engine and toolchain optimized for rapid development.

## Features

 * Automatically creates a spritesheet for your assets and then
   loads the assets at runtime.
 * Provides convenient API for drawing animated sprites in a canvas
   - Supports anchor points and rotation
 * Write code in JavaScript or other compile-to-javascript
   languages such as Coffee-Script.
 * Uses [browserify](https://github.com/substack/node-browserify) to compile
   your code which allows you to harness the power of code on [npm](https://npmjs.org/).
   - For example, [A* search](https://github.com/superjoe30/node-astar)
   - Allows you to organize code modules using `require` and `module.exports` syntax.
 * Everything from code to spritesheet is compiled automatically
   when you save.
 * Handles main loop and frame skipping.
 * Convenient API for keyboard and mouse input.

## Usage

    # install dependencies in ubuntu
    sudo apt-get install libcairo2-dev

    # start with a nearly-empty project,
    # such as a freshly created project from github with only a .git/ and README.md.
    cd my-project

    # init the project with chem-cli
    npm install chem-cli
    ./node_modules/.bin/chem init

    # the `dev` command will run a development server which will automatically recompile your code,
    # generate your spritesheets, and serve your assets.
    # after running `init` above, simply:
    npm run dev

    # see more commands
    ./node_modules/.bin/chem

See [chem-cli](http://github.com/superjoe30/chem-cli) for more information.
    
## Synopsis

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

### ./src/main.js
```js
var chem = require('chem');
var Vec2d = chem.vec2d;

chem.onReady(function () {
    var canvas = document.getElementById("game");
    var engine = new chem.Engine(canvas);
    var batch = new chem.Batch();
    var boom = new chem.Sound('sfx/boom.ogg');
    var ship = new chem.Sprite('ship', {
        batch: batch,
        pos: new Vec2d(200, 200),
        rotation: Math.PI / 2
    });
    var shipVel = new Vec2d();
    var rotationSpeed = Math.PI * 0.04;
    var thrustAmt = 0.1;
    engine.on('update', function (dt, dx) {
        ship.pos.add(shipVel);

        // rotate the ship with left and right arrow keys
        if (engine.buttonState(chem.button.KeyLeft)) {
            ship.rotation -= rotationSpeed * dx;
        }
        if (engine.buttonState(chem.button.KeyRight)) {
            ship.rotation += rotationSpeed * dx;
        }

        // apply forward and backward thrust with up and down arrow keys
        var thrust = new Vec2d(Math.cos(ship.rotation), Math.sin(ship.rotation));
        if (engine.buttonState(chem.button.KeyUp)) {
            shipVel.add(thrust.scaled(thrustAmt * dx));
        }
        if (engine.buttonState(chem.button.KeyDown)) {
            shipVel.sub(thrust.scaled(thrustAmt * dx));
        }

        // press space to blow yourself up
        if (engine.buttonJustPressed(chem.button.KeySpace)) {
            boom.play();
            ship.setAnimationName('boom');
            ship.setFrameIndex(0);
            ship.on('animationend', function() {
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

## Demo Projects Using Chem

 * [Meteor Attack](https://github.com/superjoe30/meteor-attack) - dodge meteors in space
 * [holocaust](https://github.com/superjoe30/holocaust/) -
   rebuild society after a nuclear holocaust ravages the world
 * [Dr. Chemical's Lab](https://github.com/superjoe30/dr-chemicals-lab/tree/master/javascript) -
   PyWeek #14 entry, ported to chem
 * [vapor](https://github.com/thejoshwolfe/vapor) - vaporware game. Not cool yet.

## Documentation

### Developing With Chem

#### Chemfile

Start by looking at your `chemfile`. This file contains all the instructions
on how to build your game.

This file, like every other source file in your game, can be in any compile-
to-JavaScript language (including JavaScript itself) that you choose.

 * `main` - this is the entry point into your game. Chem will use
   [browserify](https://github.com/substack/browserify/) with this as the
   input file. Often this is set to `src/main.js`.

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

#### Use any "compile to JS" language

Supported languages:

 * JavaScript (obviously)
 * [Coffee-Script](http://coffeescript.org/)
 * [LiveScript](http://livescript.net/)
 * [Coco](https://github.com/satyr/coco)

#### Getting Started

The first step is to require "chem":

```js
var chem = require('chem');

chem.onReady(function() {
    // Now you can go for it. All asssets are loaded.
});
```

#### Vec2d Convention

As a convention, any `Vec2d` instances you get from Chem are not clones. That
is, pay careful attention not to perform destructive behavior on the `Vec2d`
instances returned from the API.

#### Not Using a Spritesheet

If you omit the spritesheet object in your chemfile, no spritesheet files will
be generated. Be sure to set `chem.useSpritesheet = false` in your app code to
avoiding attempting to load the missing resources.

### Reference

#### Batch

```js
var Batch = require('chem').Batch;
```

A `Batch` is a set of sprites which you can conveniently draw using the
`Engine::draw(batch)` method.

`Batch::add(sprite)`:

    Adds a sprite to the batch. If called multiple times for the same sprite,
    the sprite is only added once.

`Batch::remove(sprite)`:

    Removes a sprite from the batch. OK to call multiple times.

#### button

```js
var button = require('chem').button;
```

Enumeration to get the button that a person is activating. Keyboard buttons
start with `Key` and mouse buttons start with `Mouse`.

For example, the left mouse button is `chem.button.MouseLeft` and the
right arrow key is `chem.button.KeyRight`.

See also:
 * `Engine::buttonState`
 * `Engine::buttonJustPressed`
 * `Engine::buttonJustReleased`
 * `Engine:: 'buttondown' event (button)`
 * `Engine:: 'buttonup' event (button)`

See `lib/button.js` for the full listing.

#### Engine

```js
var Engine = require('chem').Engine;
```

##### methods

`Engine::new(canvas)`

    Create an instance of the engine and bind it to a canvas:

    var engine = new chem.Engine(document.getElementById("the-canvas"));

`Engine::setSize(size)`

    Resize the game.

`Engine::start()`

    Call this to start the main loop and start listening to events.
    
`Engine::setMinFps(minFps)`

    If the FPS drops below this value, your engine will lag instead of trying
    to compensate with a larger dt/dx sent to `update`
    Defaults to 20.

    See also `Engine:: 'update' event(dt, dx)`
    
`Engine::stop()`

    Call this to stop the main loop and stop listening to events.

`Engine::buttonState(button)`

    Check if `button` is currently pressed. See also `button`.

`Engine::buttonJustPressed(button)`

    Call from the `update` event. It returns `true` for the 1 frame
    after the button was pressed.

    See also `button`.

`Engine::buttonJustReleased(button)`

    Call from the `update` event. It returns `true` for the 1 frame
    after the button was released.

    See also `button`.

`Engine::draw(batch)`

    Call from the `draw` event and pass in the `Batch` that you want to draw.
    All of the sprites will be drawn with the correct rotations, offsets,
    scaling, `zOrder`, and animation applied.

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

`Engine::mousePos`

    Read only. `Vec2d` instance representing the current mouse position
    relative to the canvas.

`Engine::buttonCaptureExceptions`

    Read/write. This is an object which is initially empty and contains
    buttons which the game should bubble up instead of capturing.

    Example:

    ```js
    // now you can press Ctrl+R, etc
    engine.buttonCaptureExceptions[chem.button.KeyCtrl] = true;
    ```

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
    `button`: an enum from `button`.

    See also:
     * `Engine::mousePos`

`Engine:: 'buttondown' event (button)`
`Engine:: 'buttonup' event (button)`

    Fired when the player presses a button down or up, respectively.
    `button`: an enum from `button`.

#### Sound

```js
var Sound = require('chem').Sound;
```

`new Sound(url)`

    Example:

    var sound = new chem.Sound('url/to/sound.ogg');

`sound.play()`

    Plays the sound. If the sound is already playing, it will play another
    instance at the same time.

    Returns the HTML5 Audio object that is generating the sound, which has these
    methods: `pause()`, `play()`

    And these properties: `currentTime`, `duration`

#### Sprite

```js
var Sprite = require('chem').Sprite;
```

##### methods

`Sprite::new(animationName, params)`

    Example:

    var sprite = new chem.Sprite('some_animation_name', {
      pos: new Vec2d(0, 0),
      scale: new Vec2d(1, 1),
      zOrder: 0,
      batch: some_batch,
      rotation: 0,
      visible: true,
      frameIndex: 0,
      loop: true
    });
    
    All the params are optional.

`Sprite::setAnimationName(animationName)`

    Changes the sprite's animation to the one indexed by `animationName`.

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

`Sprite::hitTest(vec2d)`

    Returns boolean of whether the point is inside the bounding box
    of the sprite.
    Takes into account scale and current frame.
    Does not take into account rotation.

`Sprite::setVisible(visible)`

    Hides the sprite but keeps it ready to display again.
    See also `Sprite::delete()`.

`Sprite::setZOrder(zOrder)`

    Use to layer sprites the way you want to. Start with 0 as the bottom layer.
    When you want to put something on top, use 1 for the zOrder, 2 for
    something on top of that, and so on.
    See also `Sprite::zOrder`
    
`Sprite::setFrameIndex(frameIndex)`

    Set the frame to show when the sprite is rendered. Animation will continue
    from this frame as usual. To find out the frame count, use
    `sprite.animation.frames.length`.

`Sprite::setLoop(loop)`

    This value overrides the animation's loop property. If set to `null`,
    it will fall back to the animation's loop property.
    See also `Sprite::loop`.

`Sprite::setAnimationStartDate(animationStartDate)`

    Does the same thing as `Sprite::setFrameIndex(frameIndex)` except you
    specify a date instead of a frame index.

`Sprite::getFrameIndex()`

    Returns the index of the current frame. See also
    `Sprite::setFrameIndex(frameIndex)`

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

`Sprite::zOrder`

    Read only. Use `Sprite::setZOrder` to change the `zOrder` of a sprite.
    
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

`Sprite::animationName`

    Read only.

##### events

These are events that you can subscribe to. See `EventEmitter` on how to
subscribe to events.

`Sprite:: 'animationend' event`

    Fired when the animation completes. If `loop` is true, this will be at a
    regular interval. If `loop` is false, this will fire only once, until you
    reset the frame index.

    See also:
     * `Sprite::setFrameIndex(frameIndex)`

#### vec2d

```js
var vec2d = require('chem').vec2d;
```

See [node-vec2d](https://github.com/superjoe30/node-vec2d)

## Developing chem

See also [chem-cli](http://github.com/superjoe30/chem-cli)

    # set up dev environment for chem itself:
    sudo apt-get install libcairo2-dev
    sudo npm link

## History

### 0.4.3

 * proper bubbling of events for mouse events. (fixes hiding the cursor
   when mouse down if you have `canvas.style.cursor = 'none'`)
   

### 0.4.2

 * support `buttonJustReleased`
 * ability to add button capture exceptions

### 0.4.1

 * `chem.getImage` moved to `chem.resources.getImage`
 * `chem.animations` moved to `chem.resources.animations`
 * `chem.spritesheet` moved to `chem.resources.spritesheet`
 * fix double bootstrap bug

### 0.4.0

 * use browserify for packaging instead of jspackage
 * `snake_case` api changed to `camelCase`
 * `chem.Button` changed to `chem.button`
 * `chem.Vec2d` changed to `chem.vec2d`
 * `"animation_end"` changed to `"animationend"`

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

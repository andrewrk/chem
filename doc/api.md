**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [button](#button)
- [resources](#resources)
	- [properties](#properties)
		- [animations](#animations)
		- [spritesheet](#spritesheet)
		- [images](#images)
		- [text](#text)
		- [prefix](#prefix)
	- [methods](#methods)
		- [url(relativePath)](#urlrelativepath)
		- [fetchTextFile(relativePath, callback)](#fetchtextfilerelativepath-callback)
		- [fetchImage(relativePath, callback)](#fetchimagerelativepath-callback)
	- [events](#events)
		- ['ready'](#'ready')
		- ['progress' (complete, total)](#'progress'-complete-total)
- [vec2d](#vec2d)
- [Animation](#animation)
	- [constructors](#constructors)
		- [new Animation()](#new-animation)
		- [Animation.fromJson(json)](#animationfromjsonjson)
		- [Animation.fromImage(image, options)](#animationfromimageimage-options)
	- [methods](#methods-1)
		- [addFrame(pos, size)](#addframepos-size)
		- [removeFrame(index)](#removeframeindex)
		- [clearFrames()](#clearframes)
		- [setDelay(delay)](#setdelaydelay)
		- [getImage(frameIndex)](#getimageframeindex)
	- [properties](#properties-1)
		- [delay](#delay)
		- [spritesheet](#spritesheet-1)
		- [duration](#duration)
		- [anchor](#anchor)
		- [frames](#frames)
- [Batch](#batch)
	- [methods](#methods-2)
		- [new Batch()](#new-batch)
		- [add(item)](#additem)
		- [remove(item)](#removeitem)
		- [draw(context)](#drawcontext)
		- [clear()](#clear)
- [Engine](#engine)
	- [methods](#methods-3)
		- [new Engine(canvas)](#new-enginecanvas)
		- [setSize(size)](#setsizesize)
		- [start()](#start)
		- [setMinFps(minFps)](#setminfpsminfps)
		- [stop()](#stop)
		- [buttonState(button)](#buttonstatebutton)
		- [buttonJustPressed(button)](#buttonjustpressedbutton)
		- [buttonJustReleased(button)](#buttonjustreleasedbutton)
		- [createFpsLabel()](#createfpslabel)
	- [properties](#properties-2)
		- [size](#size)
		- [fps](#fps)
		- [canvas](#canvas)
		- [mousePos](#mousepos)
		- [buttonCaptureExceptions](#buttoncaptureexceptions)
	- [events](#events-1)
		- ['update' (dt, dx)](#'update'-dt-dx)
		- ['draw' (context)](#'draw'-context)
		- ['mousemove' (pos, button)](#'mousemove'-pos-button)
		- ['buttondown' (button)](#'buttondown'-button)
		- ['buttonup' (button)](#'buttonup'-button)
- [Label](#label)
	- [methods](#methods-4)
		- [new Label(text, params)](#new-labeltext-params)
		- [draw(context)](#drawcontext-1)
		- [setVisible(visible)](#setvisiblevisible)
		- [setZOrder(zOrder)](#setzorderzorder)
		- [delete()](#delete)
	- [properties](#properties-3)
		- [pos](#pos)
		- [size](#size-1)
		- [scale](#scale)
		- [zOrder](#zorder)
		- [batch](#batch)
		- [rotation](#rotation)
		- [alpha](#alpha)
		- [font](#font)
		- [textAlign](#textalign)
		- [textBaseline](#textbaseline)
		- [fill](#fill)
		- [fillStyle](#fillstyle)
		- [stroke](#stroke)
		- [strokeStyle](#strokestyle)
		- [lineWidth](#linewidth)
- [Sound](#sound)
	- [methods](#methods-5)
		- [new Sound(url)](#new-soundurl)
		- [play()](#play)
		- [stop()](#stop-1)
		- [setVolume(value)](#setvolumevalue)
		- [setPreload(value)](#setpreloadvalue)
		- [setPlaybackRate(value)](#setplaybackratevalue)
	- [properties](#properties-4)
		- [currentSrc](#currentsrc)
		- [volume](#volume)
		- [preload](#preload)
		- [playbackRate](#playbackrate)
		- [maxPoolSize](#maxpoolsize)
		- [duration](#duration-1)
		- [buffered](#buffered)
	- [events](#events-2)
		- ["progress"](#progress)
		- ["ready"](#ready)
- [Sprite](#sprite)
	- [methods](#methods-6)
		- [new Sprite(animation, params)](#new-spriteanimation-params)
		- [setAnimation(animation)](#setanimationanimation)
		- [draw(context)](#drawcontext-2)
		- [getSize()](#getsize)
		- [getAnchor()](#getanchor)
		- [getTopLeft()](#gettopleft)
		- [getBottomRight()](#getbottomright)
		- [getTop()](#gettop)
		- [getLeft()](#getleft)
		- [getBottom()](#getbottom)
		- [getRight()](#getright)
		- [setLeft(x)](#setleftx)
		- [setRight(x)](#setrightx)
		- [setTop(y)](#settopy)
		- [setBottom(y)](#setbottomy)
		- [isTouching(sprite)](#istouchingsprite)
		- [hitTest(vec2d)](#hittestvec2d)
		- [setVisible(visible)](#setvisiblevisible-1)
		- [setZOrder(zOrder)](#setzorderzorder-1)
		- [setFrameIndex(frameIndex)](#setframeindexframeindex)
		- [setLoop(loop)](#setlooploop)
		- [setAnimationStartDate(animationStartDate)](#setanimationstartdateanimationstartdate)
		- [getFrameIndex()](#getframeindex)
		- [delete()](#delete-1)
	- [properties](#properties-5)
		- [pos](#pos-1)
		- [size](#size-2)
		- [scale](#scale-1)
		- [zOrder](#zorder-1)
		- [batch](#batch-1)
		- [rotation](#rotation-1)
		- [loop](#loop)
		- [alpha](#alpha-1)
		- [animation](#animation)
	- [events](#events-3)
		- ['animationend'](#'animationend')

## button

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

## resources

var resources = require('chem').resources;

### properties

#### animations

Object containing all the animation metadata, indexed by name.

#### spritesheet

Spritesheet Image.

#### images

Contains a map of your static image resources. These are in public/img.

#### text

Contains a map of your text resources. These are in public/text.

#### prefix

Path to prefix asset urls with.

### methods

#### url(relativePath)

Returns the correct resource url, taking into account prefix, based on a
relative asset path.

#### fetchTextFile(relativePath, callback)

`callback(err, textFileContents)`

#### fetchImage(relativePath, callback)

`callback(err, image)`

### events

These are events that you can subscribe to:

```js
resources.on('eventName', function() {
  // your code here
});
```

For more information see [EventEmitter](http://nodejs.org/docs/latest/api/events.html#events_class_events_eventemitter)

#### 'ready'

Emitted when all resources are loaded and you may begin utilizing them.

#### 'progress' (complete, total)

 * `complete` - how many resources have been fetched
 * `total` - total number of resources to fetch

## vec2d

```js
var vec2d = require('chem').vec2d;
```

See [node-vec2d](https://github.com/andrewrk/node-vec2d)

## Animation

```js
var Animation = require('chem').Animation;
```

An animation is a list of frames backed by a spritesheet from which to draw them.

### constructors

#### new Animation()

Creates a new animation with no frames.

#### Animation.fromJson(json)

`json` has these properties:

 * `delay` - how many seconds between each frame
 * `spritesheet` - the Image from which to draw frames when using this animation
 * `anchor` - vec2d instance representing the center point of rotation,
   scaling, and positioning.
 * `loop`
 * `frames` - an array of `{pos, size}` objects which are the locations in the spritesheet
   of each of the frames. `pos` and `size` are vec2d instances.

#### Animation.fromImage(image, options)

 * `image` - the image which this animation will draw
 * `options` - optional. can contain:
   `anchor` - see `anchor` property

### methods

#### addFrame(pos, size)

 * `pos` - vec2d instance representing the upper left corner of the image in the spritesheet
 * `size` - vec2d instance containing the width and height of the image in the spritesheet

#### removeFrame(index)

Deletes the frame at `index`.

#### clearFrames()

Turns this animation into an empty animation with no frames.

#### setDelay(delay)

`delay` is the amount of seconds you want in between each frame.

#### getImage(frameIndex)

Extracts the image at `frameIndex` from the spritesheet and returns it.

### properties

#### delay

Read-only. Number of seconds between each frame.

#### spritesheet

Read/write. The Image from which to draw frames when using this animation.

#### duration

Read-only. Total length in seconds of this animation.

#### anchor

Read/write. vec2d instance representing the center point of rotation,
scaling, and positioning.

#### frames

Read-only. An array of `{pos, size}` objects which specify where in the
spritesheet the frame draws from.

## Batch

```js
var Batch = require('chem').Batch;
```

A `Batch` is a set of sprites and/or labels which you can draw together.

### methods

#### new Batch()

#### add(item)

Adds a sprite or label to the batch. If called multiple times for
the same item, the item is only added once.

 * `item` - `sprite` or `label` to add

#### remove(item)

Removes an item from the batch. OK to call multiple times.

 * `item` - `sprite` or `label` to remove

#### draw(context)

Draw all the sprites and labels in the batch.
All of the sprites and labels will be drawn with the correct
rotations, offsets, scaling, `zOrder`, and animation applied.

 * `context` - 2D canvas drawing context.

#### clear()

Deletes all sprites in the batch.

See also Sprite::delete()

## Engine

```js
var Engine = require('chem').Engine;
```

### methods

#### new Engine(canvas)

Create an instance of the engine and bind it to a canvas:

```js
var engine = new chem.Engine(document.getElementById("the-canvas"));
```

#### setSize(size)

Resize the game.

#### start()

Call this to start the main loop and start listening to events.

#### setMinFps(minFps)

If the FPS drops below this value, your engine will lag instead of
trying to compensate with a larger dt/dx sent to `update`
Defaults to `20`.

See also `Engine:: 'update' event (dt, dx)`
    
#### stop()

Call this to stop the main loop and stop listening to events.

#### buttonState(button)

Return true if and only if `button` is currently pressed. See also `button`.

#### buttonJustPressed(button)

Call from the `update` event. It returns `true` for the 1 frame
after the button was pressed.

See also `button`.

#### buttonJustReleased(button)

Call from the `update` event. It returns `true` for the 1 frame
after the button was released.

See also `button`.

#### createFpsLabel()

Creates a `Label` which is a frames per second display. Draw it with
`Label::draw(context)`.

See also `Label`.

### properties

#### size

Read only. `Vec2d` instance. Use `Engine::setSize` if you want to update
the size.

#### fps

Read only. Contains an up to date value for the current frames per second.
    
#### canvas

Read only. The canvas element that the engine is using.

#### mousePos

Read only. `Vec2d` instance representing the current mouse position
relative to the canvas.

#### buttonCaptureExceptions

Read/write. This is an object which is initially empty and contains
buttons which the game should bubble up instead of capturing.

Example:

```js
// now you can press Ctrl+R, etc
engine.buttonCaptureExceptions[chem.button.KeyCtrl] = true;
```

### events

These are events that you can subscribe to:

```js
engine.on('eventName', function() {
  // your code here
});
```

For more information see [EventEmitter](http://nodejs.org/docs/latest/api/events.html#events_class_events_eventemitter)

#### 'update' (dt, dx)
    
Fired as often as possible, capping at about 60 FPS. Use it to compute
the next frame in your game.

For some games it makes sense to ignore `dt` and `dx` and compute the
next frame in a fixed timestep.

 * `dt` - "delta time" - the amount of time in seconds that has passed 
   since `update` was last fired.
 * `dx` - a multiplier intended to adjust your physics. If your game is
   running perfectly smoothly at 60 FPS, `dx` will be exactly 1. If your game
   is running half as fast as it should, at 30 FPS, `dx` will be 2. `dx` is
   equal to `dt` * 60.

See also `setMinFps(fps)`.

#### 'draw' (context)

You should perform all canvas drawing based on your game state in response
to this event.

See also `Batch::draw`.

#### 'mousemove' (pos, button)

Fired when the mouse moves.

 * `pos` - a `Vec2d` instance.
 * `button` - an enum from `button`.

See also `Engine::mousePos`.

#### 'buttondown' (button)

Fired when the player presses a button down.

 * `button`: an enum from `button`.

#### 'buttonup' (button)

Fired when the player releases a button.

 * `button`: an enum from `button`.

## Label

```js
var Label = require('chem').Label;
```

A Label is a piece of text that you want to display somewhere on the screen.

### methods

#### new Label(text, params)

Example:

```js
var label = new chem.Label("hello world", {
  pos: new Vec2d(0, 0),
  scale: new Vec2d(1, 1),
  zOrder: 0,
  batch: some_batch,
  rotation: 0,
  visible: true,
  alpha: 1,

  font: "10px sans-serif",
  textAlign: "start",
  textBaseline: "alphabetic",

  fill: true,
  fillStyle: "#000000",

  stroke: false,
  lineWidth: 1,
  strokeStyle: "#000000",
});
```

All the parameters are optional.

#### draw(context)

Draws the label onto the context. Most of the time you will not
do this directly; instead you will add the label to a batch
and call `batch.draw(context)`.

See `Batch`.

#### setVisible(visible)

Hides the label but keeps it ready to display again.
See also `delete()`.

#### setZOrder(zOrder)

Use to layer labels and sprites the way you want to.
Start with 0 as the bottom layer.
When you want to put something on top, use 1 for the zOrder, 2 for
something on top of that, and so on.

See also `Label::zOrder`

#### delete()

Indicates that the label should release all resources and no longer
display on the canvas.

See also `setVisible(visible)`.


### properties

#### pos

`Vec2d`. Get or set the position in the canvas this label is drawn.

#### size

Read only. `Vec2d` width and height of the first frame, not taking into
account `scale` or current frame.

#### scale

`Vec2d`. Get or set the scale with which the label is drawn.

#### zOrder

Read only. Use `Label::setZOrder` to change the `zOrder` of a label.
      
#### batch

Read only. Use `Batch::add(label)` and `Batch::remove(label)` to
change this value.

#### rotation

Get or set the angle of the label, in radians. Going over 2 * pi is OK.

#### alpha

Get or set the opacity on a scale of 0 to 1.

#### font

Get or set the font used to render.

Examples:

 * "10px Arial"
 * "12pt sans-serif"

#### textAlign

Get or set the alignment value. Possible values: 

 * `left` - The text is left-aligned.
 * `right` - The text is right-aligned.
 * `center` - The text is centered.
 * `start` - The text is aligned at the normal start of the line
   (left-aligned for left-to-right locales, right-aligned for right-to-left
   locales).
 * `end` - The text is aligned at the normal end of the line (right-aligned
   for left-to-right locales, left-aligned for right-to-left locales).

Default is `start`.

#### textBaseline

Get or set the text baseline being used when drawing text.  Possible values:

 * `top` - The text baseline is the top of the em square.
 * `middle` - The text baseline is the middle of the em square.
 * `alphabetic` - The text baseline is the normal alphabetic baseline.
 * `ideographic` - The text baseline is the ideographic baseline; this is
   the bottom of the body of the characters, if the main body of characters
   protrudes beneath the alphabetic baseline.  Currently unsupported; this
   will act like alphabetic.
 * `bottom` - The text baseline is the bottom of the bounding box.
   This differs from the ideographic baseline in that the ideographic baseline
   doesn't consider descenders.

Default is `alphabetic`.

#### fill

Get or set boolean whether to fill the text. Default `true`.

#### fillStyle

Get or set the color used to fill. Default `"#000000"`.

#### stroke

Get or set boolean whether to stroke the text. Default `false`.

#### strokeStyle

Get or set the color used to stroke. Default `"#000000"`.

#### lineWidth

Get or set the width of the stroke. Default `1`.

## Sound

```js
var Sound = require('chem').Sound;
```

A `Sound` is a pool of HTML5 `Audio` objects. It abstracts away dealing
with a pool so that you can fire off the same sound effect while it is
already playing.

If you want to create looping background music, you should use `Audio`
directly.

### methods

#### new Sound(url)

Create a sound pool based on its URL:

```js
var sound = new chem.Sound('url/to/sound.ogg');
```

#### play()

Plays the sound. If the sound is already playing, it will play another
instance at the same time. If the number of instances in the pool is
greater than `maxPoolSize`, it will find the least recently played audio
in the pool and restart it.

Returns the HTML5 Audio object that is generating the sound, which has these
methods:

 * `pause()`
 * `play()`

And these properties:

 * `currentTime`
 * `duration`

#### stop()

Stops all the Audio instances in the pool.

#### setVolume(value)

Sets the `volume` property. Same as HTML5 Audio object.

#### setPreload(value)

Sets the `preload` property. Same as HTML5 Audio object.

#### setPlaybackRate(value)

Sets the `playbackRate` property. Same as HTML5 Audio object.

### properties

#### currentSrc

Read-only. URL of the playing sound.

#### volume

Read-only.

#### preload

Read-only.

#### playbackRate

Read-only.

#### maxPoolSize

Read/write. Defaults to 10.

#### duration

Read only. Only valid after the 'ready' event has fired.

#### buffered

Read only. How much audio has been loaded in seconds.

### events

#### "progress"

Fired when some more audio has been buffered.

#### "ready"

Fired when the sound is done loading.

## Sprite

```js
var Sprite = require('chem').Sprite;
```

A `Sprite` is a graphic that you might want to move around on the screen.

### methods

#### new Sprite(animation, params)

Example:

```js
var sprite = new chem.Sprite(chem.resources.animations.some_animation_name, {
  pos: new Vec2d(0, 0),
  scale: new Vec2d(1, 1),
  zOrder: 0,
  batch: some_batch,
  rotation: 0,
  visible: true,
  frameIndex: 0,
  loop: true,
  alpha: 1,
});
```

All the parameters are optional.

#### setAnimation(animation)

Changes the sprite's animation to `animation`.

Note that you probably also want to call `setFrameIndex(0)` if you want
the new animation to start from the beginning.

You can get an `animation` from `chem.resources.animations`. It is recommended
to use `var ani = chem.resources.animations` as an import declaration so
that it is easy to access animations.

See also `Animation`.

#### draw(context)

Draws the sprite onto the context. Most of the time you will not
do this directly; instead you will add the sprite to a batch
and call `batch.draw(context)`.

See `Batch`.

#### getSize()

Like `Sprite::size` but takes scale and current frame into account.

#### getAnchor()

Convenience method to get a `Vec2d` representing the anchor position.
Takes into account scale.
Does not take into account rotation.

#### getTopLeft()

Convenience method returning a `Vec2d` instance of the corner of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### getBottomRight()

Convenience method returning a `Vec2d` instance of the corner of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### getTop()

Convenience method returning the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### getLeft()

Convenience method returning the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### getBottom()

Convenience method returning the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### getRight()

Convenience method returning the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### setLeft(x)

Convenience method to set the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### setRight(x)

Convenience method to set the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### setTop(y)

Convenience method to set the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### setBottom(y)

Convenience method to set the location of the edge of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### isTouching(sprite)

Returns boolean of whether the sprite is colliding with another.
Takes into account scale and current frame.
Does not take into account rotation.

#### hitTest(vec2d)

Returns boolean of whether the point is inside the bounding box
of the sprite.
Takes into account scale and current frame.
Does not take into account rotation.

#### setVisible(visible)

Hides the sprite but keeps it ready to display again.
See also `delete()`.

#### setZOrder(zOrder)

Use to layer labels and sprites the way you want to.
Start with 0 as the bottom layer.
When you want to put something on top, use 1 for the zOrder, 2 for
something on top of that, and so on.

See also `Sprite::zOrder`
    
#### setFrameIndex(frameIndex)

Set the frame to show when the sprite is rendered. Animation will continue
from this frame as usual. To find out the frame count, use
`sprite.animation.frames.length`.

#### setLoop(loop)

This value overrides the animation's loop property. If set to `null`,
it will fall back to the animation's loop property.

See also `Sprite::loop`.

#### setAnimationStartDate(animationStartDate)

Does the same thing as `Sprite::setFrameIndex(frameIndex)` except you
specify a date instead of a frame index.

#### getFrameIndex()

Returns the index of the current frame. See also
`setFrameIndex(frameIndex)`

#### delete()

Indicates that the sprite should release all resources and no longer
display on the canvas.

See also `setVisible(visible)`.

### properties

#### pos

`Vec2d`. Get or set the position in the canvas this sprite is drawn.

#### size

Read only. `Vec2d` width and height of the first frame, not taking into
account `scale` or current frame.

#### scale

`Vec2d`. Get or set the scale with which the sprite is drawn.

#### zOrder

Read only. Use `Sprite::setZOrder` to change the `zOrder` of a sprite.
      
#### batch

Read only. Use `Batch::add(sprite)` and `Batch::remove(sprite)` to
change this value.

#### rotation

Get or set the angle of the sprite, in radians. Going over 2 * pi is OK.

#### loop

Read only. Use `Sprite::setLoop(loop)` to set this value.

#### alpha

Get or set the opacity on a scale of 0 to 1.

#### animation

Read only. The current `Animation` of the sprite. Set it with `setAnimation`.

### events

These are events that you can subscribe to.

See [EventEmitter](http://nodejs.org/docs/latest/api/events.html#events_class_events_eventemitter).

#### 'animationend'

Fired when the animation completes. If `loop` is true, this will be at a
regular interval. If `loop` is false, this will fire only once, until you
reset the frame index.

See also `setFrameIndex(frameIndex)`.


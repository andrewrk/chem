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

    # remove all generated files
    chem clean
    
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

#### Note

You *do not* have to use JavaScript. A mixture of any of these languages
is supported and will be *automatically compiled* into your final script
package. JavaScript files get a top-level closure inserted around them.

 * JavaScript
 * coco
 * coffee-script
 * LiveScript

### ./src/main.js
```js
//depend "chem"

var Vec2d = Chem.Vec2d;

Chem.onReady(function () {
    var canvas = document.getElementById("game");
    var engine = new Chem.Engine(canvas);
    var batch = new Chem.Batch();
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
var Vec2d = require("chem").Vec2d;

// extra folders to look for source files
// you can use #depend statements to include any source files in these folders.
exports.libs = [];

// the main source file which depends on the rest of your source files.
exports.main = 'src/main';

exports.spritesheet = {
  defaults: {
    delay: 0.05,
    loop: false,
    // possible values: a Vec2d instance, or one of:
    // ["center", "topleft", "topright", "bottomleft", "bottomright"]
    anchor: "center"
  },
  animations: {
    boom: {
      // frames can be a list of filenames or a string to match the beginning
      // of files with. if you leave it out entirely, it defaults to the
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
    <script type="text/javascript" src="main.js"></script>
  </body>
</html>
```

[See the demo in action.](http://www.superjoesoftware.com/temp/chem-readme-demo/public/index.html)

## Developing chem

    # set up dev environment for chem itself:
    sudo apt-get install libcairo2-dev
    sudo npm link
    
    # while developing:
    npm run-script dev


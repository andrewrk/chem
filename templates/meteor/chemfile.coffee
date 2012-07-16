{Vec2d} = require("chem")
v = (x, y) -> new Vec2d(x, y)

# extra folders to look for source files
# you can use #depend statements to include any source files in these folders.
exports.libs = []

# the main source file which depends on the rest of your source files.
exports.main = 'src/main'

exports.spritesheet =
  defaults:
    delay: 1
    loop: true
    # possible values: a Vec2d instance, or "center"
    anchor: "center"
  animations:
    meteor_big:
      # frames can be a list of filenames or a string to match the beginning
      # of files with. if you leave it out entirely, it defaults to the
      # animation name.
      frames: "meteor_big"
    meteor_small: {}
    ship: {}
    star_small: {}
    star_big: {}

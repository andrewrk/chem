{Vec2d} = require("chem")
v = (x, y) -> new Vec2d(x, y)

# extra folders to look for source files
# you can use #depend statements to include any source files in these folders.
exports.libs = []

# the main source file which depends on the rest of your source files.
exports.main = 'src/main'

exports._default =
  delay: 1
  loop: true
  offset: v(0, 0)
  # possible values: a Vec2d instance, or "center"
  anchor: "center"

exports.animations =
  meteor2:
    # frames can be a list of filenames or a string to match the beginning
    # of files with. if you leave it out entirely, it defaults to the
    # animation name.
    frames: ["meteor2.png"]
    anchor: v(0, 48)
  meteor:
    frames: ["meteor.png"]
    anchor: v(0, 24)
  ship:
    frames: "ship"
    anchor: v(0, 24)
  star:
    frames: ["star.png"]
  star2:
    frames: ["star2.png"]

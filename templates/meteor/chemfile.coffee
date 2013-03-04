# extra folders to look for source files
# you can use #depend statements to include any source files in these folders.
exports.libs = []

# the main source file which depends on the rest of your source files.
exports.main = 'src/main'

v = (x, y) -> {x, y}
exports.spritesheet =
  defaults:
    delay: 1
    loop: true
    # possible values: a Vec2d instance, or one of:
    # ["center", "topleft", "topright", "bottomleft", "bottomright",
    #  "top", "right", "bottom", "left"]
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
    explosion:
      loop: false
      delay: 0.05

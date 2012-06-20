{Vec2d} = require("chem")

# sources are compiled and joined into one game.js file in this order
exports.sources = [
  'game.coffee'
]

exports._default =
  delay: 1
  loop: true
  offset: new Vec2d(0, 0)
  # possible values: a Vec2d instance, or "center"
  anchor: "center"

exports.animations =
  meteor2:
    frames: ["meteor2.png"]
    anchor: new Vec2d(0, 48)
  meteor:
    frames: ["meteor.png"]
    anchor: new Vec2d(0, 24)
  ship:
    frames: ["ship.png"]
    anchor: new Vec2d(0, 24)
  star:
    frames: ["star.png"]
  star2:
    frames: ["star2.png"]

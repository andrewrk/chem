{Vec2d} = require("chem")

exports._default =
  delay: 1
  loop: true
  offset: new Vec2d(0, 0)
  # possible values: a Vec2d instance, or "center"
  anchor: "center"

exports.animations =
  meteor2:
    frames: ["meteor2.png"]
  meteor:
    frames: ["meteor.png"]
  ship:
    frames: ["ship.png"]
  star:
    frames: ["star.png"]
  star2:
    frames: ["star2.png"]

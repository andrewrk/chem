{Vec2d} = require("./vec2d")

exports._default =
  delay: 1
  loop: true
  offset: new Vec2d(0, 0)
  anchor: new Vec2d(0, 0)

exports.animations =
  arm:
    anchor: new Vec2d(5, 11)
    frames: ["arm.png"]
  arm_flung:
    anchor: new Vec2d(5, 11)
    frames: ["arm-flung.png"]
  claw:
    anchor: new Vec2d(16, 16)
    frames: ["claw.png"]
  still:
    anchor: new Vec2d(16, 32)
    frames: ["man.png"]
  jump:
    anchor: new Vec2d(23, 32)
    delay: 0.1
    loop: false
    frames: ["jump-0.png", "jump-1.png", "jump-2.png", "jump-3.png"]
  walk:
    anchor: new Vec2d(23, 32)
    delay: 0.05
    frames: ("walk-#{i}.png" for i in [0..5])
  asplosion:
    delay: 0.1
    loop: false
    anchor: new Vec2d(16, 16)
    frames: ("asplosion-#{i}.png" for i in [0..5])
  atomfail:
    delay: 0.2
    loop: false
    anchor: new Vec2d(16, 16)
    frames: [
      "atomfail-00.png"
      "atomfail-01.png"
      "atomfail-02.png"
      "atomfail-03.png"
      "atomfail-04.png"
      "atomfail-05.png"
      "atomfail-06.png"
      "atomfail-07.png"
      "atomfail-08.png"
      "atomfail-09.png"
      "atomfail-10.png"
      "atomfail-11.png"
    ]
  tank0:
    delay: 0.1
    anchor: new Vec2d(192, 256)
    frames: [
      "tankleft0001.png"
      "tankleft0002.png"
      "tankleft0003.png"
      "tankleft0004.png"
      "tankleft0005.png"
      "tankleft0006.png"
      "tankleft0007.png"
      "tankleft0008.png"
      "tankleft0009.png"
      "tankleft0010.png"
    ]

#  name     :delay:loop:off_x:off_y:size_x:size_y:anchor_x:anchor_y = file1, file2, etc
#
#lazergun   :1    :1   :0    :0    :55    :23    :5       :11       = lazergun.png
#raygun     :1    :1   :0    :0    :55    :23    :5       :11       = raygun.png
#
#atom0      :1    :1   :0    :0    :32    :32    :16      :16       = atom-0.png
#atom1      :1    :1   :0    :0    :32    :32    :16      :16       = atom-1.png
#atom2      :1    :1   :0    :0    :32    :32    :16      :16       = atom-2.png
#atom3      :1    :1   :0    :0    :32    :32    :16      :16       = atom-3.png
#atom4      :1    :1   :0    :0    :32    :32    :16      :16       = atom-4.png
#atom5      :1    :1   :0    :0    :32    :32    :16      :16       = atom-5.png
#
#rock       :1    :1   :0    :0    :34    :34    :17      :17       = rock.png
#bomb       :0.1  :1   :0    :0    :34    :34    :17      :17       = bomb-0.png,bomb-1.png,bomb-2.png
#
#bombsplode :0.1  :0   :0    :0    :150   :150   :75      :75       = bigbadaboom0001.png,bigbadaboom0002.png,bigbadaboom0003.png,bigbadaboom0004.png,bigbadaboom0005.png,bigbadaboom0006.png,bigbadaboom0007.png,bigbadaboom0010.png,bigbadaboom0011.png,bigbadaboom0012.png,bigbadaboom0013.png
#
#tank1      :0.1  :1   :0    :0    :384   :512   :192     :256      = tankright0001.png,tankright0002.png,tankright0003.png,tankright0004.png,tankright0005.png,tankright0006.png,tankright0007.png,tankright0008.png,tankright0009.png,tankright0010.png
#
#
#defeat     :0.1  :1   :0    :0    :32    :64    :23      :32       = defeat-0.png,defeat-1.png,defeat-2.png,defeat-3.png,defeat-4.png
#victory    :0.1  :1   :0    :0    :32    :64    :23      :32       = victorydance0001.png,victorydance0002.png,victorydance0003.png,victorydance0004.png,victorydance0005.png,victorydance0006.png

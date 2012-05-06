from __future__ import division, print_function, unicode_literals; range = xrange

import pyglet
from pygame.locals import *

import sys
from collections import namedtuple

Point = namedtuple('Point', ['x', 'y'])
Size = namedtuple('Size', ['w', 'h'])

game_title = "Dr. Chemical's Lab"
game_fps = 60
game_size = Size(1024, 600)

class Control:
    MoveLeft = 0
    MoveRight = 1
    MoveUp = 2
    MoveDown = 3
    PullAtom = 4
    ShootAtom = 5
    ShootRope = 6

class Game(object):
    def __init__(self, window):
        self.batch_bg = pyglet.graphics.Batch()

        self.img_bg = pyglet.resource.image("data/bg.png")
        self.sprite_bg_left = pyglet.sprite.Sprite(self.img_bg, batch=self.batch_bg)

        self.window = window
        self.window.set_handler('on_draw', self.on_draw)
        self.window.set_handler('on_key_press', self.on_key_press)
        self.window.set_handler('on_key_release', self.on_key_release)

        pyglet.clock.schedule_interval(self.update, 1/game_fps)
        self.fps_display = pyglet.clock.ClockDisplay()

        # init variables
        self.controls = {
            pyglet.window.key.A: Control.MoveLeft,
            pyglet.window.key.E: Control.MoveRight,
            pyglet.window.key.COMMA: Control.MoveUp,
            pyglet.window.key.S: Control.MoveDown,
        }
        self.control_state = [False] * (len(dir(Control)) - 2)

        tank_loc = [Point(108, 54), Point(531, 55)]
        tank_dims = Size(22, 16)
        block_size = Size(24, 24)
        atom_colors = [
            (70, 83, 255),
            (357, 82, 86),
            (139, 67, 55),
            (36, 89, 100),
        ]
        man_dims = Size(1, 2)
        man_size = Size(man_dims.w*block_size.w, man_dims.h*block_size.h)

    def update(self, dt):
        pass

    def on_draw(self):
        self.window.clear()
        self.batch_bg.draw()
        self.fps_display.draw()

    def start(self):
        pass

    def on_key_press(self, symbol, modifiers):
        try:
            control = self.controls[symbol]
            self.control_state[control] = True
        except KeyError:
            return

    def on_key_release(self, symbol, modifiers):
        try:
            control = self.controls[symbol]
            self.control_state[control] = False
        except KeyError:
            return

window = pyglet.window.Window(width=game_size.w, height=game_size.h, caption=game_title)
game = Game(window)
pyglet.app.run()

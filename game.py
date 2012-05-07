from __future__ import division, print_function, unicode_literals; range = xrange

import pyglet
from pygame.locals import *

import sys
import random
from collections import namedtuple

Point = namedtuple('Point', ['x', 'y'])
Size = namedtuple('Size', ['w', 'h'])

game_title = "Dr. Chemical's Lab"
game_fps = 60
game_size = Size(1024, 600)


block_size = Size(24, 24)

class Control:
    MoveLeft = 0
    MoveRight = 1
    MoveUp = 2
    MoveDown = 3
    PullAtom = 4
    ShootAtom = 5
    ShootRope = 6

class Atom:
    flavors = [
        (70, 83, 255),
        (357, 82, 86),
        (139, 67, 55),
        (36, 89, 100),
    ]

    def __init__(self, pos, flavor_index, sprite):
        self.pos = pos
        self.flavor_index = flavor_index
        self.sprite = sprite

class Tank:
    def __init__(self, dims):
        self.dims = dims
        self.atoms = []

class Game(object):
    def __init__(self, window):
        self.batch = pyglet.graphics.Batch()
        self.group_bg = pyglet.graphics.OrderedGroup(0)
        self.group_main = pyglet.graphics.OrderedGroup(1)

        img_bg = pyglet.resource.image("data/bg.png")
        self.sprite_bg = pyglet.sprite.Sprite(img_bg, batch=self.batch, group=self.group_bg)

        self.atom_imgs = [pyglet.resource.image("data/atom-%i.png" % i) for i in range(len(Atom.flavors))]

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

        self.tank_dims = Size(16, 22)
        self.tank_pos = Point(108, 18)
        self.man_dims = Size(1, 2)
        self.man_size = Size(self.man_dims.w*block_size.w, self.man_dims.h*block_size.h)

        self.time_between_drops = 3
        self.time_until_next_drop = self.time_between_drops

        self.tank = Tank(self.tank_dims)

    def update(self, dt):
        self.time_until_next_drop -= dt
        if self.time_until_next_drop <= 0:
            self.time_until_next_drop += self.time_between_drops
            # drop a random atom
            flavor_index = random.randint(0, len(Atom.flavors)-1)
            pos = Point(
                block_size.w*random.randint(0, self.tank.dims.w-1),
                block_size.h*(self.tank.dims.h-1),
            )
            atom = Atom(pos, flavor_index, pyglet.sprite.Sprite(self.atom_imgs[flavor_index], batch=self.batch, group=self.group_main))
            self.tank.atoms.append(atom)

    def on_draw(self):
        self.window.clear()

        for atom in self.tank.atoms:
            atom.sprite.set_position(atom.pos.x + self.tank_pos.x, atom.pos.y + self.tank_pos.y)

        self.batch.draw()
        self.fps_display.draw()

    def start(self):
        pyglet.app.run()

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
game.start()

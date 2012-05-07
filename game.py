from __future__ import division, print_function, unicode_literals; range = xrange

import pyglet
from pygame.locals import *

import sys
import random
import math
from collections import namedtuple

import pymunk
from pymunk import Vec2d

game_title = "Dr. Chemical's Lab"
game_fps = 60
game_size = Vec2d(1024, 600)


atom_size = Vec2d(24, 24)
atom_collide_size = Vec2d(20, 20)

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

    def __init__(self, pos, flavor_index, sprite, space):
        self.flavor_index = flavor_index
        self.sprite = sprite

        body = pymunk.Body(10, 100)
        body.position = pos
        self.shape = pymunk.Circle(body, 12)
        self.shape.friction = 0.5
        space.add(body, self.shape)

class Tank:
    def __init__(self, dims):
        self.dims = dims
        self.size = dims * atom_size
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

        self.tank_dims = Vec2d(16, 22)
        self.tank_pos = Vec2d(108, 18)
        self.man_dims = Vec2d(1, 2)
        self.man_size = Vec2d(self.man_dims * atom_size)

        self.time_between_drops = 1
        self.time_until_next_drop = 0

        self.tank = Tank(self.tank_dims)

        self.space = pymunk.Space()
        self.space.gravity = Vec2d(0, -200)

    def update(self, dt):
        self.time_until_next_drop -= dt
        if self.time_until_next_drop <= 0:
            self.time_until_next_drop += self.time_between_drops
            # drop a random atom
            flavor_index = random.randint(0, len(Atom.flavors)-1)
            pos = Vec2d(
                atom_size.x*random.randint(0, self.tank.dims.x-1),
                atom_size.y*(self.tank.dims.y-1),
            )
            atom = Atom(pos, flavor_index, pyglet.sprite.Sprite(self.atom_imgs[flavor_index], batch=self.batch, group=self.group_main), self.space)
            self.tank.atoms.append(atom)

        # update physics
        self.space.step(dt)

    def on_draw(self):
        self.window.clear()

        for atom in self.tank.atoms:
            atom.sprite.set_position(*(atom.shape.body.position + self.tank_pos))
            atom.sprite.rotation = atom.shape.body.rotation_vector.get_angle_degrees()

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

window = pyglet.window.Window(width=int(game_size.x), height=int(game_size.y), caption=game_title)
game = Game(window)
game.start()

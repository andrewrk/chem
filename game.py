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

        body = pymunk.Body(10, 100000)
        body.position = pos
        self.shape = pymunk.Circle(body, 12)
        self.shape.friction = 0.5
        self.shape.elasticity = 0.05
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

        img_arm = pyglet.resource.image("data/arm.png")
        img_arm.anchor_x = 2
        img_arm.anchor_y = 11
        self.sprite_arm = pyglet.sprite.Sprite(img_arm, batch=self.batch, group=self.group_main)

        img_man = pyglet.resource.image("data/man.png")
        img_man.anchor_x = img_man.width / 2
        img_man.anchor_y = img_man.height / 2
        self.sprite_man = pyglet.sprite.Sprite(img_man, batch=self.batch, group=self.group_main)

        self.atom_imgs = []
        for i in range(len(Atom.flavors)):
            img = pyglet.resource.image("data/atom-%i.png" % i)
            img.anchor_x = img.width / 2
            img.anchor_y = img.height / 2
            self.atom_imgs.append(img)

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
        self.let_go_of_jump = True

        self.tank_dims = Vec2d(16, 22)
        self.tank_pos = Vec2d(108, 18)
        self.man_dims = Vec2d(1, 2)
        self.man_size = Vec2d(self.man_dims * atom_size)

        self.time_between_drops = 0.5
        self.time_until_next_drop = 0

        self.tank = Tank(self.tank_dims)

        self.space = pymunk.Space()
        self.space.gravity = Vec2d(0, -200)
        self.space.damping = 0.99

        # add the walls of the tank to space
        r = 25
        borders = [
            # top wall
            (Vec2d(0, self.tank.size.y + r), Vec2d(self.tank.size.x, self.tank.size.y + r)),
            # right wall
            (Vec2d(self.tank.size.x + r, self.tank.size.y), Vec2d(self.tank.size.x + r, 0)),
            # bottom wall
            (Vec2d(self.tank.size.x, -r), Vec2d(0, -r)),
            # left wall
            (Vec2d(-r, 0), Vec2d(-r, self.tank.size.y)),
        ]
        for p1, p2 in borders:
            shape = pymunk.Segment(pymunk.Body(), p1, p2, r)
            shape.friction = 0.99
            shape.elasticity = 0.0
            self.space.add(shape)

        shape = pymunk.Poly.create_box(pymunk.Body(100, 10000000), self.man_size)
        shape.body.position = Vec2d(self.tank.size.x / 2, self.man_size.y / 2)
        shape.body.angular_velocity_limit = 0
        shape.body.velocity_limit = 300
        self.man_angle = shape.body.angle
        shape.elasticity = 0
        shape.friction = 3.0
        self.space.add(shape.body, shape)
        self.man = shape

    def update(self, dt):
        self.time_until_next_drop -= dt
        if self.time_until_next_drop <= 0:
            self.time_until_next_drop += self.time_between_drops
            # drop a random atom
            flavor_index = random.randint(0, len(Atom.flavors)-1)
            pos = Vec2d(
                random.random() * (self.tank.size.x - atom_size.x) + atom_size.x / 2,
                self.tank.size.y - atom_size.y / 2,
            )
            atom = Atom(pos, flavor_index, pyglet.sprite.Sprite(self.atom_imgs[flavor_index], batch=self.batch, group=self.group_main), self.space)
            self.tank.atoms.append(atom)

        # input
        grounded = abs(self.man.body.velocity.y) < 10.0
        grounded_move_force = 2700
        not_moving_x = abs(self.man.body.velocity.x) < 5.0
        air_move_force = 600
        move_force = grounded_move_force if grounded else air_move_force
        if self.control_state[Control.MoveLeft] and not self.control_state[Control.MoveRight]:
            self.man.body.apply_impulse(Vec2d(-move_force, 0), Vec2d(0, 0))
            if not_moving_x:
                self.man.body.velocity.x = -40
        if self.control_state[Control.MoveRight] and not self.control_state[Control.MoveLeft]:
            self.man.body.apply_impulse(Vec2d(move_force, 0), Vec2d(0, 0))
            if not_moving_x:
                self.man.body.velocity.x = 40

        if not self.control_state[Control.MoveUp]:
            self.let_go_of_jump = True
        if self.control_state[Control.MoveUp] and grounded and self.let_go_of_jump:
            self.man.body.velocity.y = 100
            self.man.body.apply_impulse(Vec2d(0, 8000), Vec2d(0, 0))
            self.let_go_of_jump = False

        # update physics
        self.space.step(dt)

        # apply our constraints
        # man can't rotate
        self.man.body.angle = self.man_angle

    def on_draw(self):
        self.window.clear()

        for atom in self.tank.atoms:
            atom.sprite.set_position(*(atom.shape.body.position + self.tank_pos))
            atom.sprite.rotation = -atom.shape.body.rotation_vector.get_angle_degrees()

        self.sprite_man.set_position(*(self.man.body.position + self.tank_pos))
        self.sprite_man.rotation = -self.man.body.rotation_vector.get_angle_degrees()

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

from __future__ import division, print_function, unicode_literals; range = xrange

import pyglet
from pygame.locals import *

import sys
import random
import math

import pymunk
from pymunk import Vec2d

game_title = "Dr. Chemical's Lab"
game_fps = 60
game_size = Vec2d(1024, 600)


atom_size = Vec2d(24, 24)
atom_collide_size = Vec2d(20, 20)

class Control:
    MOUSE_OFFSET = 255

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

class Animations:
    def __init__(self):
        pass

    def get(self, name):
        return self.animations[name]

    def offset(self, animation):
        return self.animation_offset[animation]

    def load(self):
        with pyglet.resource.file('data/animations.txt') as fd:
            animations_txt = fd.read()
        lines = animations_txt.split('\n')
        self.animations = {}
        self.animation_offset = {}
        for full_line in lines:
            line = full_line.strip()
            if line.startswith('#') or len(line) == 0:
                continue
            props, frames_txt = line.split('=')

            name, delay, loop, off_x, off_y, size_x, size_y, anchor_x, anchor_y = [s.strip() for s in props.strip().split(':')]
            delay = float(delay)
            loop = bool(int(loop))
            anchor_x = int(anchor_x)
            anchor_y = int(anchor_y)

            frame_files = frames_txt.strip().split(',')
            def get_img(x):
                img = pyglet.resource.image('data/' + x.strip())
                img.anchor_x = anchor_x
                img.anchor_y = anchor_y
                return img
            frame_list = [pyglet.image.AnimationFrame(get_img(x), delay) for x in frame_files]
            rev_frame_list = [pyglet.image.AnimationFrame(pyglet.resource.image('data/' + x.strip(), flip_x=True), delay) for x in frame_files]
            if not loop:
                frame_list[-1].duration = None
                rev_frame_list[-1].duration = None

            animation = pyglet.image.Animation(frame_list)
            rev_animation = pyglet.image.Animation(rev_frame_list)
            self.animations[name] = animation
            self.animations['-' + name] = rev_animation

            self.animation_offset[animation] = Vec2d(-int(off_x), -int(off_y))
            self.animation_offset[rev_animation] = Vec2d(int(off_x) + int(size_x), -int(off_y))

class Game(object):
    def __init__(self, window):
        self.animations = Animations()
        self.animations.load()

        self.batch = pyglet.graphics.Batch()
        self.group_bg = pyglet.graphics.OrderedGroup(0)
        self.group_main = pyglet.graphics.OrderedGroup(1)
        self.group_fg = pyglet.graphics.OrderedGroup(2)

        img_bg = pyglet.resource.image("data/bg.png")
        self.sprite_bg = pyglet.sprite.Sprite(img_bg, batch=self.batch, group=self.group_bg)

        self.sprite_arm = pyglet.sprite.Sprite(self.animations.get("arm"), batch=self.batch, group=self.group_fg)

        self.sprite_man = pyglet.sprite.Sprite(self.animations.get("man"), batch=self.batch, group=self.group_main)

        self.atom_imgs = [self.animations.get("atom%i" % i) for i in range(len(Atom.flavors))]

        self.window = window
        self.window.set_handler('on_draw', self.on_draw)
        self.window.set_handler('on_mouse_motion', self.on_mouse_motion)
        self.window.set_handler('on_mouse_press', self.on_mouse_press)
        self.window.set_handler('on_mouse_release', self.on_mouse_release)
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

            Control.MOUSE_OFFSET+pyglet.window.mouse.LEFT: Control.ShootAtom,
            Control.MOUSE_OFFSET+pyglet.window.mouse.RIGHT: Control.ShootRope,
        }
        self.control_state = [False] * (len(dir(Control)) - 2)
        self.let_go_of_jump = True
        self.crosshair = window.get_system_mouse_cursor(window.CURSOR_CROSSHAIR)
        self.default_cursor = window.get_system_mouse_cursor(window.CURSOR_DEFAULT)
        self.mouse_pos = Vec2d(0, 0)

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

        negate = self.mouse_pos.x < self.man.body.position.x
        animation = self.animations.get("-man" if negate else "man")
        if self.sprite_man.image != animation:
            self.sprite_man.image = animation
        if self.control_state[Control.ShootRope]:
            print("shoot rope at %i, %i" % (self.mouse_pos.x, self.mouse_pos.y))

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

        self.sprite_arm.set_position(*(self.man.body.position + self.tank_pos))
        self.sprite_arm.rotation = -(self.mouse_pos - self.man.body.position).get_angle_degrees()

        self.batch.draw()
        self.fps_display.draw()

    def on_mouse_motion(self, x, y, dx, dy):
        self.mouse_pos = Vec2d(x, y) - self.tank_pos

        use_crosshair = self.mouse_pos.x >= 0 and \
                        self.mouse_pos.y >= 0 and \
                        self.mouse_pos.x <= self.tank.size.x and \
                        self.mouse_pos.y <= self.tank.size.y
        cursor = self.crosshair if use_crosshair else self.default_cursor
        self.window.set_mouse_cursor(cursor)

    def on_mouse_press(self, x, y, button, modifiers):
        try:
            control = self.controls[Control.MOUSE_OFFSET+button]
            self.control_state[control] = True
        except KeyError:
            return

    def on_mouse_release(self, x, y, button, modifiers):
        try:
            control = self.controls[Control.MOUSE_OFFSET+button]
            self.control_state[control] = False
        except KeyError:
            return

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

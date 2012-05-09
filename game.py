from __future__ import division, print_function, unicode_literals; range = xrange

import pyglet

import sys
import random
import math

import pymunk
from pymunk import Vec2d

game_title = "Dr. Chemical's Lab"
game_fps = 60
game_size = Vec2d(1024, 600)


atom_size = Vec2d(32, 32)
atom_radius = atom_size.x / 2

def sign(x):
    if x > 0:
        return 1
    elif x < 0:
        return -1
    else:
        return 0

class Collision:
    Default = 0
    Claw = 1
    Atom = 2

class Control:
    MOUSE_OFFSET = 255

    MoveLeft = 0
    MoveRight = 1
    MoveUp = 2
    MoveDown = 3
    FireMain = 4
    FireAlt = 5

class Atom:
    flavors = [
        (70, 83, 255),
        (357, 82, 86),
        (139, 67, 55),
        (36, 89, 100),
    ]

    atom_for_shape = {}
    max_bonds = 2

    def __init__(self, pos, flavor_index, sprite, space):
        self.flavor_index = flavor_index
        self.sprite = sprite

        body = pymunk.Body(10, 100000)
        body.position = pos
        self.shape = pymunk.Circle(body, atom_radius)
        self.shape.friction = 0.5
        self.shape.elasticity = 0.05
        self.shape.collision_type = Collision.Atom
        self.space = space
        self.space.add(body, self.shape)

        Atom.atom_for_shape[self.shape] = self
        # atom => joint
        self.bonds = {}

    def bond_to(self, other):
        # already bonded
        if other in self.bonds:
            return
        # too many bonds already
        if len(self.bonds) >= Atom.max_bonds or len(other.bonds) >= Atom.max_bonds:
            return
        # wrong color
        if self.flavor_index != other.flavor_index:
            return


        joint = pymunk.PinJoint(self.shape.body, other.shape.body)
        joint.distance = atom_radius * 2.5
        self.bonds[other] = joint
        other.bonds[self] = joint
        self.space.add(joint)


    def clean_up(self):
        for atom, joint in self.bonds.iteritems():
            del atom.bonds[self]
            self.space.remove(joint)
        self.space.remove(self.shape, self.body)
        del Atom.atom_for_shape[self.shape]

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

        self.sprite_man = pyglet.sprite.Sprite(self.animations.get("still"), batch=self.batch, group=self.group_main)

        self.atom_imgs = [self.animations.get("atom%i" % i) for i in range(len(Atom.flavors))]

        self.sprite_claw = pyglet.sprite.Sprite(self.animations.get("claw"), batch=self.batch, group=self.group_main)

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

            Control.MOUSE_OFFSET+pyglet.window.mouse.LEFT: Control.FireMain,
            Control.MOUSE_OFFSET+pyglet.window.mouse.RIGHT: Control.FireAlt,
        }
        self.control_state = [False] * (len(dir(Control)) - 2)
        self.let_go_of_fire_main = True
        self.let_go_of_fire_alt = True
        self.crosshair = window.get_system_mouse_cursor(window.CURSOR_CROSSHAIR)
        self.default_cursor = window.get_system_mouse_cursor(window.CURSOR_DEFAULT)
        self.mouse_pos = Vec2d(0, 0)

        self.tank_dims = Vec2d(12, 16)
        self.tank_pos = Vec2d(109, 41)
        self.man_dims = Vec2d(1, 2)
        self.man_size = Vec2d(self.man_dims * atom_size)

        self.time_between_drops = 1
        self.time_until_next_drop = 0

        self.tank = Tank(self.tank_dims)

        self.space = pymunk.Space()
        self.space.gravity = Vec2d(0, -400)
        self.space.damping = 0.99
        self.space.add_collision_handler(Collision.Claw, Collision.Default, post_solve=self.claw_hit_something)
        self.space.add_collision_handler(Collision.Claw, Collision.Atom, post_solve=self.claw_hit_something)
        self.space.add_collision_handler(Collision.Atom, Collision.Atom, post_solve=self.atom_hit_atom)

        # add the walls of the tank to space
        r = 50
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
            shape.collision_type = Collision.Default
            self.space.add(shape)

        shape = pymunk.Poly.create_box(pymunk.Body(20, 10000000), self.man_size)
        shape.body.position = Vec2d(self.tank.size.x / 2, self.man_size.y / 2)
        shape.body.angular_velocity_limit = 0
        self.man_angle = shape.body.angle
        shape.elasticity = 0
        shape.friction = 3.0
        shape.collision_type = Collision.Default
        self.space.add(shape.body, shape)
        self.man = shape

        self.claw_in_motion = False
        self.sprite_claw.visible = False
        self.claw_radius = 8
        self.claw_shoot_speed = 1200
        self.min_claw_dist = 60
        self.claw_pin_to_add = None
        self.claw_pin = None
        self.claw_attached = False
        self.want_to_remove_claw_pin = False
        self.want_to_retract_claw = False

        self.arm_offset = Vec2d(13, 43)
        self.arm_len = 24
        self.compute_arm_pos()

        self.bond_queue = []

        # opengl
        pyglet.gl.glEnable(pyglet.gl.GL_BLEND)
        pyglet.gl.glBlendFunc(pyglet.gl.GL_SRC_ALPHA, pyglet.gl.GL_ONE_MINUS_SRC_ALPHA)

    def claw_hit_something(self, space, arbiter):
        if self.claw_attached:
            return
        # bolt these bodies together
        claw, shape = arbiter.shapes
        pos = arbiter.contacts[0].position
        self.claw_pin_to_add = pymunk.PinJoint(claw.body, shape.body, pos - claw.body.position, pos - shape.body.position)
        self.claw_attached = True

    def atom_hit_atom(self, space, arbiter):
        atom1, atom2 = [Atom.atom_for_shape[shape] for shape in arbiter.shapes]
        # bond the atoms together
        self.bond_queue.append((atom1, atom2))

    def compute_arm_pos(self):
        self.arm_pos = self.man.body.position - self.man_size / 2 + self.arm_offset
        self.point_vector = (self.mouse_pos - self.arm_pos).normalized()
        self.point_start = self.arm_pos + self.point_vector * self.arm_len


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
        feet_start = self.man.body.position - self.man_size / 2 + Vec2d(1, -1)
        feet_end = Vec2d(feet_start.x + self.man_size.x - 2, feet_start.y - 2)
        bb = pymunk.BB(feet_start.x, feet_end.y, feet_end.x, feet_start.y)
        ground_shapes = self.space.bb_query(bb)
        grounded = len(ground_shapes) > 0

        grounded_move_force = 1000
        not_moving_x = abs(self.man.body.velocity.x) < 5.0
        air_move_force = 200
        grounded_move_boost = 30
        air_move_boost = 0
        move_force = grounded_move_force if grounded else air_move_force
        move_boost = grounded_move_boost if grounded else air_move_boost
        max_speed = 200
        move_left = self.control_state[Control.MoveLeft] and not self.control_state[Control.MoveRight]
        move_right = self.control_state[Control.MoveRight] and not self.control_state[Control.MoveLeft]
        if move_left:
            if self.man.body.velocity.x >= -max_speed and self.man.body.position.x - self.man_size.x / 2 - 2 > 0:
                self.man.body.apply_impulse(Vec2d(-move_force, 0), Vec2d(0, 0))
                if self.man.body.velocity.x > -move_boost and self.man.body.velocity.x < 0:
                    self.man.body.velocity.x = -move_boost
        elif move_right:
            if self.man.body.velocity.x <= max_speed and self.man.body.position.x + self.man_size.x / 2 + 3 < self.tank.size.x:
                self.man.body.apply_impulse(Vec2d(move_force, 0), Vec2d(0, 0))
                if self.man.body.velocity.x < move_boost and self.man.body.velocity.x > 0:
                    self.man.body.velocity.x = move_boost

        # jumping
        if grounded:
            if move_left or move_right:
                animation_name = "walk"
            else:
                animation_name = "still"
        else:
            animation_name = "jump"

        if self.control_state[Control.MoveUp] and grounded:
            animation_name = "jump"
            self.man.body.velocity.y = 100
            self.man.body.apply_impulse(Vec2d(0, 2000), Vec2d(0, 0))
            # apply a reverse force upon the atom we jumped from
            power = 1000 / len(ground_shapes)
            for shape in ground_shapes:
                shape.body.apply_impulse(Vec2d(0, -power), Vec2d(0, 0))

        # point the man+arm in direction of mouse
        negate = "-" if self.mouse_pos.x < self.man.body.position.x else ""
        animation = self.animations.get(negate + animation_name)
        if self.sprite_man.image != animation:
            self.sprite_man.image = animation
        if self.control_state[Control.FireMain] and not self.claw_in_motion:
            self.let_go_of_fire_main = False
            self.claw_in_motion = True
            self.sprite_claw.visible = True
            self.sprite_arm.image = self.animations.get("arm-flung")
            body = pymunk.Body(mass=5, moment=1000000)
            body.position = Vec2d(self.point_start)
            body.angle = self.point_vector.get_angle()
            body.velocity = self.point_vector * self.claw_shoot_speed
            self.claw = pymunk.Circle(body, self.claw_radius)
            self.claw.friction = 1
            self.claw.elasticity = 0
            self.claw.collision_type = Collision.Claw
            self.claw_joint = pymunk.SlideJoint(self.claw.body, self.man.body, Vec2d(0, 0), Vec2d(0, 0), 0, self.tank.size.get_length())
            self.space.add(body, self.claw, self.claw_joint)

        if self.sprite_claw.visible:
            claw_dist = (self.claw.body.position - self.point_start).get_length()

        claw_reel_in_speed = 400
        claw_reel_out_speed = 200
        if self.control_state[Control.FireAlt] and self.claw_in_motion:
            if claw_dist < self.min_claw_dist:
                if self.claw_pin is not None:
                    self.want_to_retract_claw = True
                    self.let_go_of_fire_alt = False
                else:
                    self.retract_claw()
            else:
                # prevent the claw from going back out once it goes in
                if self.claw_attached and self.claw_joint.max > claw_dist:
                    self.claw_joint.max = claw_dist
                else:
                    self.claw_joint.max -= claw_reel_in_speed * dt
                    if self.claw_joint.max < self.min_claw_dist:
                        self.claw_joint.max = self.min_claw_dist
        if self.let_go_of_fire_main and self.control_state[Control.FireMain] and self.claw_attached:
            self.unattach_claw()
        if not self.control_state[Control.FireMain]:
            self.let_go_of_fire_main = True
        if not self.control_state[Control.FireAlt] and not self.let_go_of_fire_alt:
            self.let_go_of_fire_alt = True
            if self.want_to_retract_claw:
                self.want_to_retract_claw = False
                self.retract_claw()


        # queued actions
        if self.claw_pin_to_add is not None:
            self.claw_pin = self.claw_pin_to_add
            self.claw_pin_to_add = None
            self.space.add(self.claw_pin)

        for atom1, atom2 in self.bond_queue:
            atom1.bond_to(atom2)
        self.bond_queue = []


        self.compute_atom_pointed_at()

        # update physics
        self.space.step(dt)

        if self.want_to_remove_claw_pin:
            self.space.remove(self.claw_pin)
            self.claw_pin = None
            self.want_to_remove_claw_pin = False

        self.compute_arm_pos()

        # apply our constraints
        # man can't rotate
        self.man.body.angle = self.man_angle

    def retract_claw(self):
        if not self.sprite_claw.visible:
            return
        self.claw_in_motion = False
        self.sprite_claw.visible = False
        self.sprite_arm.image = self.animations.get("arm")
        self.claw_attached = False
        self.space.remove(self.claw.body, self.claw, self.claw_joint)
        self.unattach_claw()

    def in_tank(self, pt):
        return pt.x >= 0 and pt.y >= 0 and pt.x < self.tank.size.x and pt.y < self.tank.size.y

    def unattach_claw(self):
        if self.claw_pin is not None:
            #self.claw.body.reset_forces()
            self.want_to_remove_claw_pin = True

    def compute_atom_pointed_at(self):
        # iterate over each atom. check if intersects with line.
        closest_atom = None
        closest_dist = None
        for atom in self.tank.atoms:
            # http://stackoverflow.com/questions/1073336/circle-line-collision-detection
            f = atom.shape.body.position - self.point_start
            if sign(f.x) != sign(self.point_vector.x) or sign(f.y) != sign(self.point_vector.y):
                continue
            a = self.point_vector.dot(self.point_vector)
            b = 2 * f.dot(self.point_vector)
            c = f.dot(f) - atom_radius*atom_radius
            discriminant = b*b - 4*a*c
            if discriminant < 0:
                continue

            dist = atom.shape.body.position.get_dist_sqrd(self.point_start)
            if closest_atom is None or dist < closest_dist:
                closest_atom = atom
                closest_dist = dist

        if closest_atom is not None:
            # intersection
            # use the coords of the closest atom
            self.point_end = closest_atom.shape.body.position
        else:
            # no intersection
            # find the coords at the wall
            slope = self.point_vector.y / self.point_vector.x
            y_intercept = self.point_start.y - slope * self.point_start.x
            self.point_end = self.point_start + self.tank.size.get_length() * self.point_vector
            if self.point_end.x > self.tank.size.x:
                self.point_end.x = self.tank.size.x
                self.point_end.y = slope * self.point_end.x + y_intercept
            if self.point_end.x < 0:
                self.point_end.x = 0
                self.point_end.y = slope * self.point_end.x + y_intercept
            if self.point_end.y > self.tank.size.y:
                self.point_end.y = self.tank.size.y
                self.point_end.x = (self.point_end.y - y_intercept) / slope
            if self.point_end.y < 0:
                self.point_end.y = 0
                self.point_end.x = (self.point_end.y - y_intercept) / slope


    def on_draw(self):
        self.window.clear()

        for atom in self.tank.atoms:
            atom.sprite.set_position(*(atom.shape.body.position + self.tank_pos))
            atom.sprite.rotation = -atom.shape.body.rotation_vector.get_angle_degrees()

        self.sprite_man.set_position(*(self.man.body.position + self.tank_pos))
        self.sprite_man.rotation = -self.man.body.rotation_vector.get_angle_degrees()

        self.sprite_arm.set_position(*(self.arm_pos + self.tank_pos))
        self.sprite_arm.rotation = -(self.mouse_pos - self.man.body.position).get_angle_degrees()

        if self.sprite_claw.visible:
            self.sprite_claw.set_position(*(self.claw.body.position + self.tank_pos))
            self.sprite_claw.rotation = -self.claw.body.rotation_vector.get_angle_degrees()

        self.batch.draw()

        # draw a line from gun hand to self.point_end
        self.draw_line(self.point_start + self.tank_pos, self.point_end + self.tank_pos, (0, 0, 0, 0.23))

        # draw a line from gun to claw if it's out
        if self.sprite_claw.visible:
            self.draw_line(self.point_start + self.tank_pos, self.sprite_claw.position, (1, 1, 0, 1))

        # draw lines for bonded atoms
        for atom in self.tank.atoms:
            for other, joint in atom.bonds.iteritems():
                self.draw_line(self.tank_pos + atom.shape.body.position, self.tank_pos + other.shape.body.position, (0, 0, 1, 1))

        self.fps_display.draw()

    def draw_line(self, p1, p2, color):
        pyglet.gl.glColor4f(color[0], color[1], color[2], color[3])
        pyglet.graphics.draw(2, pyglet.gl.GL_LINES,
            ('v2f', (p1[0], p1[1], p2[0], p2[1]))
        )

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

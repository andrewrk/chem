from __future__ import division, print_function, unicode_literals; range = xrange

import pyglet

import sys
import random
import math
import itertools

import pymunk
from pymunk import Vec2d
import json

import websocket

game_title = "Dr. Chemical's Lab"
game_fps = 60
game_size = Vec2d(1024, 600)


atom_size = Vec2d(32, 32)
atom_radius = atom_size.x / 2

max_bias = 400


def serialize_shape(shape):
    return {
        'body': {
            'position': list(shape.body.position),
            'velocity': list(shape.body.velocity),
        },
    }
        

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
    SwitchToGrapple = 6
    SwitchToRay = 7
    SwitchToLazer = 8

class Atom:
    flavor_count = 6

    atom_for_shape = {}
    max_bonds = 2

    id_count = 0

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
        self.marked_for_deletion = False
        self.rogue = False

        self.id = Atom.id_count
        Atom.id_count += 1

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
        joint.max_bias = max_bias
        self.bonds[other] = joint
        other.bonds[self] = joint
        self.space.add(joint)

    def bond_loop(self):
        "returns None or a list of atoms in the bond loop which includes itself"
        if len(self.bonds) != 2:
            return None
        seen = {self: True}
        atom, dest = self.bonds.keys()
        while True:
            seen[atom] = True
            if atom is dest:
                return seen.keys()
            found = False
            for next_atom, joint in atom.bonds.iteritems():
                if next_atom not in seen:
                    atom = next_atom
                    found = True
                    break
            if not found:
                return None
    def unbond(self):
        for atom, joint in self.bonds.iteritems():
            del atom.bonds[self]
            self.space.remove(joint)
        self.bonds = {}

    def clean_up(self):
        self.unbond()
        self.space.remove(self.shape)
        if not self.rogue:
            self.space.remove(self.shape.body)
        del Atom.atom_for_shape[self.shape]
        self.sprite.delete()
        self.sprite = None

    def serialize(self):
        if self.marked_for_deletion:
            return None

        return {
            'type': "Atom",
            'id': self.id,
            'shape': serialize_shape(self.shape),
            'flavor': self.flavor_index,
            'bonds': [b.id for b in self.bonds],
            'rogue': self.rogue,
        }

class Bomb:
    radius = 16
    size = Vec2d(radius*2, radius*2)
    def __init__(self, pos, sprite, space, timeout):
        self.sprite = sprite

        body = pymunk.Body(50, 10)
        body.position = pos
        self.shape = pymunk.Circle(body, Bomb.radius)
        self.shape.friction = 0.7
        self.shape.elasticity = 0.02
        self.shape.collision_type = Collision.Default
        self.space = space
        self.space.add(body, self.shape)

        self.timeout = timeout

    def tick(self, dt):
        self.timeout -= dt

    def clean_up(self):
        self.space.remove(self.shape, self.shape.body)
        self.sprite.delete()
        self.sprite = None

    def serialize(self):
        return {
            'type': "Bomb",
            'shape': serialize_shape(self.shape),
        }

class Rock:
    radius = 16
    size = Vec2d(radius*2, radius*2)

    def __init__(self, pos, sprite, space):
        self.sprite = sprite

        body = pymunk.Body(70, 100000)
        body.position = pos
        self.shape = pymunk.Circle(body, Rock.radius)
        self.shape.friction = 0.9
        self.shape.elasticity = 0.01
        self.shape.collision_type = Collision.Default
        self.space = space
        self.space.add(body, self.shape)

    def tick(self, dt):
        pass

    def clean_up(self):
        self.space.remove(self.shape, self.shape.body)
        self.sprite.delete()
        self.sprite = None

    def serialize(self):
        return {
            'type': "Rock",
            'shape': serialize_shape(self.shape),
        }


class Tank:
    def __init__(self, pos, dims, game, tank_index=None):
        self.pos = pos
        self.dims = dims
        self.size = dims * atom_size
        self.game = game
        self.other_tank = None
        self.atoms = set()
        self.bombs = set()
        self.rocks = set()


        self.sprite_arm = pyglet.sprite.Sprite(self.game.animations.get("arm"), batch=self.game.batch, group=self.game.group_fg)
        self.sprite_man = pyglet.sprite.Sprite(self.game.animations.get("still"), batch=self.game.batch, group=self.game.group_main)
        self.sprite_claw = pyglet.sprite.Sprite(self.game.animations.get("claw"), batch=self.game.batch, group=self.game.group_main)


        self.space = pymunk.Space()
        self.space.gravity = Vec2d(0, -400)
        self.space.damping = 0.99
        self.space.add_collision_handler(Collision.Claw, Collision.Default, post_solve=self.claw_hit_something)
        self.space.add_collision_handler(Collision.Claw, Collision.Atom, post_solve=self.claw_hit_something)
        self.space.add_collision_handler(Collision.Atom, Collision.Atom, post_solve=self.atom_hit_atom)


        self.init_controls()
        self.mouse_pos = Vec2d(0, 0)
        self.man_dims = Vec2d(1, 2)
        self.man_size = Vec2d(self.man_dims * atom_size)

        self.time_between_drops = 0.2 if "--fastatoms" in sys.argv else 1
        self.time_until_next_drop = 0

        self.init_walls()
        self.init_ceiling()

        self.init_man()

        self.init_guns()
        self.arm_offset = Vec2d(13, 43)
        self.arm_len = 24
        self.compute_arm_pos()

        self.closest_atom = None

        self.equipped_gun = Control.SwitchToGrapple
        self.gun_animations = {
            Control.SwitchToGrapple: "arm",
            Control.SwitchToRay: "raygun",
            Control.SwitchToLazer: "lazergun",
        }

        self.bond_queue = []

        self.points = 0
        self.survival_points = 0
        self.points_to_crush = 50
        self.survival_point_timeout = 1 if "--hard" in sys.argv else 10
        self.next_survival_point = self.survival_point_timeout
        self.weapon_drop_interval = 3 if "--bomb" in sys.argv else 10

        self.point_end = Vec2d(0.000001, 0.000001)
        
        # if you have this many atoms per tank y or more, you lose
        self.lose_ratio = 95 / 300

        if tank_index is None:
            tank_index = random.randint(0, 1)
        tank_name = "tank%i" % tank_index
        self.sprite_tank = pyglet.sprite.Sprite(self.game.animations.get(tank_name), batch=self.game.batch, group=self.game.group_main)

        self.game_over = False

    def init_guns(self):
        self.claw_in_motion = False
        self.sprite_claw.visible = False
        self.claw_radius = 8
        self.claw_shoot_speed = 1200
        self.min_claw_dist = 60
        self.claw_pins_to_add = None
        self.claw_pins = None
        self.claw_attached = False
        self.want_to_remove_claw_pin = False
        self.want_to_retract_claw = False

        self.lazer_timeout = 0.5
        self.lazer_recharge = 0
        self.lazer_line = None
        self.lazer_line_timeout = 0
        self.lazer_line_timeout_start = 0.2

        self.ray_atom = None
        self.ray_shoot_speed = 900

    def init_controls(self):
        self.controls = {
            pyglet.window.key.A: Control.MoveLeft,
            pyglet.window.key.D: Control.MoveRight,
            pyglet.window.key.W: Control.MoveUp,
            pyglet.window.key.S: Control.MoveDown,

            pyglet.window.key._1: Control.SwitchToGrapple,
            pyglet.window.key._2: Control.SwitchToRay,
            pyglet.window.key._3: Control.SwitchToLazer,

            Control.MOUSE_OFFSET+pyglet.window.mouse.LEFT: Control.FireMain,
            Control.MOUSE_OFFSET+pyglet.window.mouse.RIGHT: Control.FireAlt,
        }
        if '--dvorak' in sys.argv:
            self.controls[pyglet.window.key.A] = Control.MoveLeft
            self.controls[pyglet.window.key.E] = Control.MoveRight
            self.controls[pyglet.window.key.COMMA] = Control.MoveUp
            self.controls[pyglet.window.key.S] = Control.MoveDown
        elif '--colemak' in sys.argv:
            self.controls[pyglet.window.key.A] = Control.MoveLeft
            self.controls[pyglet.window.key.S] = Control.MoveRight
            self.controls[pyglet.window.key.W] = Control.MoveUp
            self.controls[pyglet.window.key.R] = Control.MoveDown

        self.control_state = [False] * len(dir(Control))
        self.let_go_of_fire_main = True
        self.let_go_of_fire_alt = True


    def update(self, dt):
        self.adjust_ceiling(dt)
        self.compute_drops(dt)

        # check if we died
        ratio = len(self.atoms) / (self.ceiling.body.position.y - self.size.y / 2)
        if ratio > self.lose_ratio or self.ceiling.body.position.y < self.man_size.y:
            self.lose()

        # process bombs
        for bomb in list(self.bombs):
            bomb.tick(dt)
            if bomb.timeout <= 0:
                # physics explosion
                # loop over every object in the space and apply an impulse
                for shape in self.space.shapes:
                    vector = shape.body.position - bomb.shape.body.position
                    dist = vector.get_length()
                    direction = vector.normalized()
                    power = 6000
                    damp = 1 - dist / 800
                    shape.body.apply_impulse(direction * power * damp)

                # explosion animation
                sprite = pyglet.sprite.Sprite(self.game.animations.get("bombsplode"), batch=self.game.batch, group=self.game.group_fg)
                sprite.set_position(*(self.pos + bomb.shape.body.position))
                def remove_bomb_sprite(sprite=sprite):
                    sprite.delete()
                sprite.set_handler("on_animation_end", remove_bomb_sprite)
                self.remove_bomb(bomb)

        self.process_input(dt)


        # queued actions
        self.process_queued_actions()

        self.compute_atom_pointed_at()

        # update physics
        step_count = int(dt / (1 / game_fps))
        if step_count < 1:
            step_count = 1
        delta = dt / step_count
        for i in range(step_count):
            self.space.step(delta)

        if self.want_to_remove_claw_pin:
            self.space.remove(*self.claw_pins)
            self.claw_pins = None
            self.want_to_remove_claw_pin = False

        self.compute_arm_pos()

        # apply our constraints
        # man can't rotate
        self.man.body.angle = self.man_angle


    def remove_atom(self, atom):
        atom.clean_up()
        self.atoms.remove(atom)

    def remove_atoms(self, atoms):
        for atom in atoms:
            self.remove_atom(atom)

    def remove_bomb(self, bomb):
        bomb.clean_up()
        self.bombs.remove(bomb)

    def init_walls(self):
        # add the walls of the tank to space
        r = 50
        borders = [
            # right wall
            (Vec2d(self.size.x + r, self.size.y), Vec2d(self.size.x + r, 0)),
            # bottom wall
            (Vec2d(self.size.x, -r), Vec2d(0, -r)),
            # left wall
            (Vec2d(-r, 0), Vec2d(-r, self.size.y)),
        ]
        for p1, p2 in borders:
            shape = pymunk.Segment(pymunk.Body(), p1, p2, r)
            shape.friction = 0.99
            shape.elasticity = 0.0
            shape.collision_type = Collision.Default
            self.space.add(shape)

    def init_ceiling(self):
        # physics for ceiling
        body = pymunk.Body(10000, 100000)
        body.position = Vec2d(self.size.x / 2, self.size.y * 1.5)
        self.ceiling = pymunk.Poly.create_box(body, self.size)
        self.ceiling.collision_type = Collision.Default
        self.space.add(self.ceiling)
        # per second
        self.max_ceiling_delta = 200

    def adjust_ceiling(self, dt):
        # adjust the descending ceiling as necessary
        adjust = (self.points - self.other_tank.points) / self.points_to_crush * self.size.y
        if adjust > 0:
            adjust = 0
        if self.game_over:
            adjust = 0
        target_y = self.size.y * 1.5 + adjust

        direction = sign(target_y - self.ceiling.body.position.y)
        amount = self.max_ceiling_delta * dt
        new_y = self.ceiling.body.position.y + amount * direction
        new_sign = sign(target_y - new_y)
        if direction is -new_sign:
            # close enough to just set
            self.ceiling.body.position.y = target_y
        else:
            self.ceiling.body.position.y = new_y

    def init_man(self):
        # physics for man
        shape = pymunk.Poly.create_box(pymunk.Body(20, 10000000), self.man_size)
        shape.body.position = Vec2d(self.size.x / 2, self.man_size.y / 2)
        shape.body.angular_velocity_limit = 0
        self.man_angle = shape.body.angle
        shape.elasticity = 0
        shape.friction = 3.0
        shape.collision_type = Collision.Default
        self.space.add(shape.body, shape)
        self.man = shape


    def compute_arm_pos(self):
        self.arm_pos = self.man.body.position - self.man_size / 2 + self.arm_offset
        self.point_vector = (self.mouse_pos - self.arm_pos).normalized()
        self.point_start = self.arm_pos + self.point_vector * self.arm_len

    def get_drop_pos(self, size):
        return Vec2d(
            random.random() * (self.size.x - size.x) + size.x / 2,
            self.ceiling.body.position.y - self.size.y / 2 - size.y / 2,
        )


    def drop_bomb(self):
        # drop a bomb
        pos = self.get_drop_pos(Bomb.size)
        sprite = pyglet.sprite.Sprite(self.game.animations.get("bomb"), batch=self.game.batch, group=self.game.group_main)
        timeout = random.randint(1, 5)
        bomb = Bomb(pos, sprite, self.space, timeout)
        self.bombs.add(bomb)

    def drop_rock(self):
        # drop a rock
        pos = self.get_drop_pos(Rock.size)
        sprite = pyglet.sprite.Sprite(self.game.animations.get("rock"), batch=self.game.batch, group=self.game.group_main)
        rock = Rock(pos, sprite, self.space)
        self.rocks.add(rock)

    def compute_drops(self, dt):
        if self.game_over:
            return
        self.time_until_next_drop -= dt
        if self.time_until_next_drop <= 0:
            self.time_until_next_drop += self.time_between_drops
            # drop a random atom
            flavor_index = random.randint(0, Atom.flavor_count-1)
            pos = self.get_drop_pos(atom_size)
            atom = Atom(pos, flavor_index, pyglet.sprite.Sprite(self.game.atom_imgs[flavor_index], batch=self.game.batch, group=self.game.group_main), self.space)
            self.atoms.add(atom)


    def lose(self):
        if self.game_over:
            return
        self.game_over = True
        self.explode_atoms(list(self.atoms))

        self.sprite_man.image = self.game.animations.get("defeat")
        self.sprite_arm.visible = False

        self.retract_claw()

    def explode_atom(self, atom, animation_name="asplosion"):
        if atom is self.ray_atom:
            self.ray_atom = None
        if self.claw_pins is not None and self.claw_pins[0].b is atom.shape.body:
            self.unattach_claw()
        atom.marked_for_deletion = True
        def clear_sprite():
            self.remove_atom(atom)
        atom.sprite.image = self.game.animations.get(animation_name)
        atom.sprite.set_handler("on_animation_end", clear_sprite)


    def explode_atoms(self, atoms):
        for atom in atoms:
            self.explode_atom(atom)

    def process_input(self, dt):
        if self.game_over:
            return

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
            if self.man.body.velocity.x >= -max_speed and self.man.body.position.x - self.man_size.x / 2 - 5 > 0:
                self.man.body.apply_impulse(Vec2d(-move_force, 0), Vec2d(0, 0))
                if self.man.body.velocity.x > -move_boost and self.man.body.velocity.x < 0:
                    self.man.body.velocity.x = -move_boost
        elif move_right:
            if self.man.body.velocity.x <= max_speed and self.man.body.position.x + self.man_size.x / 2 + 3 < self.size.x:
                self.man.body.apply_impulse(Vec2d(move_force, 0), Vec2d(0, 0))
                if self.man.body.velocity.x < move_boost and self.man.body.velocity.x > 0:
                    self.man.body.velocity.x = move_boost

        negate = "-" if self.mouse_pos.x < self.man.body.position.x else ""
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
            self.sprite_man.image = self.game.animations.get(negate + animation_name)
            self.man.body.velocity.y = 100
            self.man.body.apply_impulse(Vec2d(0, 2000), Vec2d(0, 0))
            # apply a reverse force upon the atom we jumped from
            power = 1000 / len(ground_shapes)
            for shape in ground_shapes:
                shape.body.apply_impulse(Vec2d(0, -power), Vec2d(0, 0))

        # point the man+arm in direction of mouse
        animation = self.game.animations.get(negate + animation_name)
        if self.sprite_man.image != animation:
            self.sprite_man.image = animation

        # selecting a different gun
        if self.control_state[Control.SwitchToGrapple]:
            self.equipped_gun = Control.SwitchToGrapple
        elif self.control_state[Control.SwitchToRay]:
            self.equipped_gun = Control.SwitchToRay
        elif self.control_state[Control.SwitchToLazer]:
            self.equipped_gun = Control.SwitchToLazer

        if self.equipped_gun is Control.SwitchToGrapple:
            if self.claw_in_motion:
                ani_name = "arm-flung"
            else:
                ani_name = "arm"
            arm_animation = self.game.animations.get(negate + ani_name)
        else:
            arm_animation = self.game.animations.get(negate + self.gun_animations[self.equipped_gun])

        if self.sprite_arm.image != arm_animation:
            self.sprite_arm.image = arm_animation

        if self.equipped_gun is Control.SwitchToGrapple:
            claw_reel_in_speed = 400
            claw_reel_out_speed = 200
            if not self.want_to_remove_claw_pin and not self.want_to_retract_claw and self.let_go_of_fire_main and self.control_state[Control.FireMain] and not self.claw_in_motion:
                self.let_go_of_fire_main = False
                self.claw_in_motion = True
                self.sprite_claw.visible = True
                body = pymunk.Body(mass=5, moment=1000000)
                body.position = Vec2d(self.point_start)
                body.angle = self.point_vector.get_angle()
                body.velocity = self.man.body.velocity + self.point_vector * self.claw_shoot_speed
                self.claw = pymunk.Circle(body, self.claw_radius)
                self.claw.friction = 1
                self.claw.elasticity = 0
                self.claw.collision_type = Collision.Claw
                self.claw_joint = pymunk.SlideJoint(self.claw.body, self.man.body, Vec2d(0, 0), Vec2d(0, 0), 0, self.size.get_length())
                self.claw_joint.max_bias = max_bias
                self.space.add(body, self.claw, self.claw_joint)

            if self.sprite_claw.visible:
                claw_dist = (self.claw.body.position - self.man.body.position).get_length()

            if self.control_state[Control.FireMain] and self.claw_in_motion:
                if claw_dist < self.min_claw_dist + 8:
                    if self.claw_pins is not None:
                        self.want_to_retract_claw = True
                        self.let_go_of_fire_main = False
                    elif self.claw_attached and self.let_go_of_fire_main:
                        self.retract_claw()
                        self.let_go_of_fire_main = False
                elif claw_dist > self.min_claw_dist:
                    # prevent the claw from going back out once it goes in
                    if self.claw_attached and self.claw_joint.max > claw_dist:
                        self.claw_joint.max = claw_dist
                    else:
                        self.claw_joint.max -= claw_reel_in_speed * dt
                        if self.claw_joint.max < self.min_claw_dist:
                            self.claw_joint.max = self.min_claw_dist
            if self.control_state[Control.FireAlt] and self.claw_attached:
                self.unattach_claw()

        self.lazer_recharge -= dt
        if self.equipped_gun is Control.SwitchToLazer:
            if self.lazer_line is not None:
                self.lazer_line[0] = self.point_start
            if self.control_state[Control.FireMain] and self.lazer_recharge <= 0:
                # IMA FIRIN MAH LAZERZ
                self.lazer_recharge = self.lazer_timeout
                self.lazer_line = [self.point_start, self.point_end]
                self.lazer_line_timeout = self.lazer_line_timeout_start

                if self.closest_atom is not None:
                    self.explode_atom(self.closest_atom, "atomfail")
                    self.closest_atom = None
        self.lazer_line_timeout -= dt
        if self.lazer_line_timeout <= 0:
            self.lazer_line = None

        if self.ray_atom is not None:
            # move the atom closer to the ray gun
            vector = self.point_start - self.ray_atom.shape.body.position
            delta = vector.normalized() * 1000 * dt
            if delta.get_length() > vector.get_length():
                # just move the atom to final location
                self.ray_atom.shape.body.position = self.point_start
            else:
                self.ray_atom.shape.body.position += delta

        if self.equipped_gun is Control.SwitchToRay:
            if (self.control_state[Control.FireMain] and self.let_go_of_fire_main) and self.closest_atom is not None and self.ray_atom is None and not self.closest_atom.marked_for_deletion:
                # remove the atom from physics
                self.ray_atom = self.closest_atom
                self.ray_atom.rogue = True
                self.closest_atom = None
                self.space.remove(self.ray_atom.shape.body)
                self.let_go_of_fire_main = False
                self.ray_atom.unbond()
            elif ((self.control_state[Control.FireMain] and self.let_go_of_fire_main) or self.control_state[Control.FireAlt]) and self.ray_atom is not None:
                self.space.add(self.ray_atom.shape.body)
                self.ray_atom.rogue = False
                if self.control_state[Control.FireMain]:
                    # shoot it!!
                    self.ray_atom.shape.body.velocity = self.man.body.velocity + self.point_vector * self.ray_shoot_speed
                else:
                    self.ray_atom.shape.body.velocity = Vec2d(self.man.body.velocity)
                self.ray_atom = None
                self.let_go_of_fire_main = False

        if not self.control_state[Control.FireMain]:
            self.let_go_of_fire_main = True

            if self.want_to_retract_claw:
                self.want_to_retract_claw = False
                self.retract_claw()
        if not self.control_state[Control.FireAlt] and not self.let_go_of_fire_alt:
            self.let_go_of_fire_alt = True

    def process_queued_actions(self):
        if self.claw_pins_to_add is not None:
            self.claw_pins = self.claw_pins_to_add
            self.claw_pins_to_add = None
            self.space.add(*self.claw_pins)

        for atom1, atom2 in self.bond_queue:
            if atom1.marked_for_deletion or atom2.marked_for_deletion:
                continue
            if atom1 is self.ray_atom or atom2 is self.ray_atom:
                continue
            if atom1.bonds is None or atom2.bonds is None:
                print("Warning: trying to bond with an atom that doesn't exist anymore")
                continue
            atom1.bond_to(atom2)
            bond_loop = atom1.bond_loop()
            if bond_loop is not None:
                # make all the atoms in this loop disappear
                self.points += len(bond_loop)
                self.explode_atoms(bond_loop)

        self.bond_queue = []

    def claw_hit_something(self, space, arbiter):
        if self.claw_attached:
            return
        # bolt these bodies together
        claw, shape = arbiter.shapes
        pos = arbiter.contacts[0].position
        shape_anchor = pos - shape.body.position
        claw_anchor = pos - claw.body.position
        claw_delta = claw_anchor.normalized() * -(self.claw_radius + 8)
        self.claw.body.position += claw_delta
        self.claw_pins_to_add = [
            pymunk.PinJoint(claw.body, shape.body, claw_anchor, shape_anchor),
            pymunk.PinJoint(claw.body, shape.body, Vec2d(0, 0), Vec2d(0, 0)),
        ]
        for claw_pin in self.claw_pins_to_add:
            claw_pin.max_bias = max_bias
        self.claw_attached = True

    def atom_hit_atom(self, space, arbiter):
        atom1, atom2 = [Atom.atom_for_shape[shape] for shape in arbiter.shapes]
        # bond the atoms together
        self.bond_queue.append((atom1, atom2))

    def restore_state(self, data):
        pass

    def retract_claw(self):
        if not self.sprite_claw.visible:
            return
        self.claw_in_motion = False
        self.sprite_claw.visible = False
        self.sprite_arm.image = self.game.animations.get("arm")
        self.claw_attached = False
        self.space.remove(self.claw.body, self.claw, self.claw_joint)
        self.unattach_claw()

    def unattach_claw(self):
        if self.claw_pins is not None:
            #self.claw.body.reset_forces()
            self.want_to_remove_claw_pin = True

    def compute_atom_pointed_at(self):
        if self.equipped_gun is Control.SwitchToGrapple:
            self.closest_atom = None
        else:
            # iterate over each atom. check if intersects with line.
            self.closest_atom = None
            closest_dist = None
            for atom in self.atoms:
                if atom.marked_for_deletion:
                    continue
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
                if self.closest_atom is None or dist < closest_dist:
                    self.closest_atom = atom
                    closest_dist = dist

        if self.closest_atom is not None:
            # intersection
            # use the coords of the closest atom
            self.point_end = self.closest_atom.shape.body.position
        else:
            # no intersection
            # find the coords at the wall
            slope = self.point_vector.y / (self.point_vector.x+0.00000001)
            y_intercept = self.point_start.y - slope * self.point_start.x
            self.point_end = self.point_start + self.size.get_length() * self.point_vector
            if self.point_end.x > self.size.x:
                self.point_end.x = self.size.x
                self.point_end.y = slope * self.point_end.x + y_intercept
            if self.point_end.x < 0:
                self.point_end.x = 0
                self.point_end.y = slope * self.point_end.x + y_intercept
            if self.point_end.y > self.ceiling.body.position.y - self.size.y / 2:
                self.point_end.y = self.ceiling.body.position.y - self.size.y / 2
                self.point_end.x = (self.point_end.y - y_intercept) / slope
            if self.point_end.y < 0:
                self.point_end.y = 0
                self.point_end.x = (self.point_end.y - y_intercept) / slope


    def serialize_state(self):
        state = {
            'objects': [thing.serialize() for thing in itertools.chain(self.atoms, self.bombs, self.rocks)],
            'man': {
                'shape': serialize_shape(self.man),
            },
        }
        return state

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

    def move_mouse(self, x, y):
        self.mouse_pos = Vec2d(x, y) - self.pos

        use_crosshair = self.mouse_pos.x >= 0 and \
                        self.mouse_pos.y >= 0 and \
                        self.mouse_pos.x <= self.size.x and \
                        self.mouse_pos.y <= self.size.y
        cursor = self.game.crosshair if use_crosshair else self.game.default_cursor
        self.game.window.set_mouse_cursor(cursor)

    def on_mouse_motion(self, x, y, dx, dy):
        self.move_mouse(x, y)

    def on_mouse_drag(self, x, y, dx, dy, buttons, modifiers):
        self.move_mouse(x, y)

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

    def move_sprites(self):
        # drawable things
        for drawable in itertools.chain(self.atoms, self.bombs, self.rocks):
            drawable.sprite.set_position(*(drawable.shape.body.position + self.pos))
            drawable.sprite.rotation = -drawable.shape.body.rotation_vector.get_angle_degrees()

        self.sprite_man.set_position(*(self.man.body.position + self.pos))
        self.sprite_man.rotation = -self.man.body.rotation_vector.get_angle_degrees()

        self.sprite_arm.set_position(*(self.arm_pos + self.pos))
        self.sprite_arm.rotation = -(self.mouse_pos - self.man.body.position).get_angle_degrees()
        if self.mouse_pos.x < self.man.body.position.x:
            self.sprite_arm.rotation += 180

        self.sprite_tank.set_position(*(self.pos + self.ceiling.body.position))

        if self.sprite_claw.visible:
            self.sprite_claw.set_position(*(self.claw.body.position + self.pos))
            self.sprite_claw.rotation = -self.claw.body.rotation_vector.get_angle_degrees()

    def draw_primitives(self):
        # draw a line from gun hand to self.point_end
        if not self.game_over:
            self.draw_line(self.point_start + self.pos, self.point_end + self.pos, (0, 0, 0, 0.23))

            # draw a line from gun to claw if it's out
            if self.sprite_claw.visible:
                self.draw_line(self.point_start + self.pos, self.sprite_claw.position, (1, 1, 0, 1))

            # draw lines for bonded atoms
            for atom in self.atoms:
                if atom.marked_for_deletion:
                    continue
                for other, joint in atom.bonds.iteritems():
                    self.draw_line(self.pos + atom.shape.body.position, self.pos + other.shape.body.position, (0, 0, 1, 1))

            if self.game.debug:
                if self.claw_pins:
                    for claw_pin in self.claw_pins:
                        self.draw_line(self.pos + claw_pin.a.position + claw_pin.anchr1, self.pos + claw_pin.b.position + claw_pin.anchr2, (1, 0, 1, 1))

            # lazer
            if self.lazer_line is not None:
                start, end = self.lazer_line
                self.draw_line(start + self.pos, end + self.pos, (1, 0, 0, 1))

    def draw_line(self, p1, p2, color):
        pyglet.gl.glColor4f(color[0], color[1], color[2], color[3])
        pyglet.graphics.draw(2, pyglet.gl.GL_LINES,
            ('v2f', (p1[0], p1[1], p2[0], p2[1]))
        )

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

dummy_state = """{"objects": [{"bonds": [], "shape": {"body": {"position": [201.1620302617581, 15.899907160551637], "velocity": [0.0, 4.440892098500626e-16]}}, "rogue": false, "flavor": 4, "type": "Atom", "id": 3}, {"bonds": [], "shape": {"body": {"position": [296.4885716930263, 15.899999805000231], "velocity": [0.0, 4.440892098500626e-16]}}, "rogue": false, "flavor": 1, "type": "Atom", "id": 2}, {"bonds": [], "shape": {"body": {"position": [106.09483697541798, 74.90244777819458], "velocity": [0.7970640523466013, -65.38298539603122]}}, "rogue": false, "flavor": 4, "type": "Atom", "id": 4}, {"bonds": [], "shape": {"body": {"position": [199.73446520455178, 495.77808866792657], "velocity": [0.0, -19.972573828109734]}}, "rogue": false, "flavor": 0, "type": "Atom", "id": 6}, {"bonds": [], "shape": {"body": {"position": [365.02667895189603, 15.899999998509555], "velocity": [0.0, 4.440892098500626e-16]}}, "rogue": false, "flavor": 4, "type": "Atom", "id": 0}, {"bonds": [], "shape": {"body": {"position": [42.39048079530272, 15.899999995404194], "velocity": [0.0, 4.440892098500626e-16]}}, "rogue": false, "flavor": 4, "type": "Atom", "id": 1}, {"bonds": [], "shape": {"body": {"position": [300.4244308544384, 281.2751674010951], "velocity": [0.0, -417.93498837612646]}}, "rogue": false, "flavor": 4, "type": "Atom", "id": 5}], "man": {"shape": {"body": {"position": [148.36946327657165, 31.93161481123989], "velocity": [199.3770075475592, 0.02096626808907933]}}}}"""

class Server:
    def __init__(self):
        pass

    def get_messages(self):
        return [
            ('UpdateState', json.loads(dummy_state)),
        ]

    def send(self, string):
        print("<out>")
        print(string)
        print("</out>")

    def send_msg(self, name, obj):
        self.send("%s:\n%s" % (name, json.dumps(obj)))


class Game(object):
    def __init__(self, window):
        self.debug = "--debug" in sys.argv

        self.animations = Animations()
        self.animations.load()

        self.batch = pyglet.graphics.Batch()
        self.group_bg = pyglet.graphics.OrderedGroup(0)
        self.group_main = pyglet.graphics.OrderedGroup(1)
        self.group_fg = pyglet.graphics.OrderedGroup(2)

        img_bg = pyglet.resource.image("data/bg.png")
        img_bg_top = pyglet.resource.image("data/bg-top.png")
        self.sprite_bg = pyglet.sprite.Sprite(img_bg, batch=self.batch, group=self.group_bg)
        self.sprite_bg_top = pyglet.sprite.Sprite(img_bg_top, batch=self.batch, group=self.group_fg, y=img_bg.height-img_bg_top.height)

        self.atom_imgs = [self.animations.get("atom%i" % i) for i in range(Atom.flavor_count)]

        pyglet.clock.schedule_interval(self.update, 1/game_fps)
        if "--fps" in sys.argv:
            self.fps_display = pyglet.clock.ClockDisplay()
        else:
            self.fps_display = None

        self.crosshair = window.get_system_mouse_cursor(window.CURSOR_CROSSHAIR)
        self.default_cursor = window.get_system_mouse_cursor(window.CURSOR_DEFAULT)

        tank_dims = Vec2d(12, 16)
        tank_pos = [
            Vec2d(109, 41),
            Vec2d(531, 41),
        ]

        self.tanks = [Tank(pos, tank_dims, self, tank_index=i) for i, pos in enumerate(tank_pos)]

        self.control_tank = self.tanks[0]
        self.enemy_tank = self.tanks[1]

        self.control_tank.other_tank = self.enemy_tank
        self.enemy_tank.other_tank = self.control_tank

        self.window = window
        self.window.set_handler('on_draw', self.on_draw)
        self.window.set_handler('on_mouse_motion', self.control_tank.on_mouse_motion)
        self.window.set_handler('on_mouse_drag', self.control_tank.on_mouse_drag)
        self.window.set_handler('on_mouse_press', self.control_tank.on_mouse_press)
        self.window.set_handler('on_mouse_release', self.control_tank.on_mouse_release)
        self.window.set_handler('on_key_press', self.control_tank.on_key_press)
        self.window.set_handler('on_key_release', self.control_tank.on_key_release)


        pyglet.gl.glEnable(pyglet.gl.GL_BLEND)
        pyglet.gl.glBlendFunc(pyglet.gl.GL_SRC_ALPHA, pyglet.gl.GL_ONE_MINUS_SRC_ALPHA)


        self.server = Server()
        self.state_render_timeout = 2
        self.next_state_render = self.state_render_timeout



    def update(self, dt):
        for tank in self.tanks:
            tank.update(dt)

        if self.server is None:
            # give enemy points
            self.next_survival_point -= dt
            if self.next_survival_point <= 0:
                self.next_survival_point += self.survival_point_timeout
                old_number = self.survival_points // self.weapon_drop_interval
                self.survival_points += random.randint(3, 6)
                new_number = self.survival_points // self.weapon_drop_interval

                if new_number > old_number:
                    n = random.randint(1, 2)
                    if n == 1:
                        self.control_tank.drop_bomb()
                    else:
                        self.control_tank.drop_rock()

        # send state to network
        if self.server is not None:
            self.next_state_render -= dt
            if self.next_state_render <= 0:
                self.next_state_render = self.state_render_timeout

                self.server.send_msg("StateUpdate", self.control_tank.serialize_state())

                # get all server messages
                for msg_name, data in self.server.get_messages():
                    if msg_name is 'UpdateState':
                        self.enemy_tank.restore_state(data)


    def on_draw(self):
        self.window.clear()

        for tank in self.tanks:
            tank.move_sprites()

        self.batch.draw()

        for tank in self.tanks:
            tank.draw_primitives()
        

        if self.fps_display is not None:
            self.fps_display.draw()


    def start(self):
        pyglet.app.run()

#import threading
#import asyncore
#
#def run_network():
#    def onmessage():
#        print("got message")
#    def onerror(msg):
#        print("got error: %s" % msg)
#    def onopen():
#        print("on open")
#    def onclose():
#        print("on close")
#    socket = websocket.WebSocket("ws://superjoe.zapto.org/dr-chemicals-lab", onmessage=onmessage, onopen=onopen, onerror=onerror, onclose=onclose)
#
#    asyncore.loop()
#net_thread = threading.Thread(target=run_network)
#net_thread.start()

window = pyglet.window.Window(width=int(game_size.x), height=int(game_size.y), caption=game_title)
game = Game(window)
game.start()

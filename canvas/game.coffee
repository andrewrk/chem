do ->
  atom_size = new Vec2d(32, 32)
  atom_radius = atom_size.x / 2

  max_bias = 400

  sign = (x) ->
    if x > 0
      1
    else if x < 0
      -1
    else
      0

  randInt = (min, max) -> Math.floor(min + Math.random() * (max - min + 1))

  Collision =
    Default: 0
    Claw: 1
    Atom: 2

  Control =
    MoveLeft: 0
    MoveRight: 1
    MoveUp: 2
    MoveDown: 3
    FireMain: 4
    FireAlt: 5
    SwitchToGrapple: 6
    SwitchToRay: 7
    SwitchToLazer: 8
    COUNT: 9
    MOUSE_OFFSET: 255

  class Set
    @assertItemHasId: (item) ->
      throw "item missing id" unless item.id?

    constructor: ->
      # id to item
      @items = {}
      @length = 0

    add: (item) ->
      Set.assertItemHasId item
      unless @items[item.id]?
        @length += 1
      @items[item.id] = item

    remove: (item) ->
      Set.assertItemHasId item
      if @items[item.id]?
        @length -= 1
        delete @items[item.id]

    each: (cb) ->
      for id, item of @items
        if not cb(item)
          break

    clone: ->
      set = new Set()
      @each (item) ->
        set.add item
        true
      set

  class Map
    @assertItemHasId: (item) ->
      throw "item missing id" unless item.id?
    
    constructor: ->
      @pairs = {}
      @length = 0

    set: (key, value) ->
      Map.assertItemHasId key
      unless @pairs[key.id]?
        @length += 1
      @pairs[item.id] = [key, value]

    remove: (key) ->
      Map.assertItemHasId key
      if @pairs[key.id]?
        @length -= 1
        delete @pairs[key.id]

    each: (cb) ->
      for id, pair of @pairs
        if not cb.call(pair)
          break

    clone: ->
      map = new Map()
      @each (key, value) ->
        map.set key, value
        true
      map

    contains: (key) -> @pairs[key.id]?

    keys: -> (key for id, [key, value] of @pairs)

  class Indexable
    @id_count = 0

    constructor: ->
      @id = Indexable.id_count++

  class Atom extends Indexable
    @flavor_count = 6

    @atom_for_shape = {}
    @max_bonds = 2

    constructor: (pos, @flavor_index, @sprite, @space) ->
      super
      body = new cp.Body(10, 100000)
      body.position = pos
      @shape = new cp.Circle(body, atom_radius)
      @shape.friction = 0.5
      @shape.elasticity = 0.05
      @shape.collision_type = Collision.Atom
      @space.add(body, @shape)

      Atom.atom_for_shape[@shape] = this
      # atom => joint
      @bonds = new Map()
      @marked_for_deletion = false
      @rogue = false

    bondTo: (other) ->
      # already bonded
      if @bonds.contains(other)
        return false
      # too many bonds already
      if @bonds.length >= Atom.max_bonds or other.bonds.length >= Atom.max_bonds
        return false
      # wrong color
      if @flavor_index isnt other.flavor_index
        return false

      joint = new cp.PinJoint(@shape.body, other.shape.body)
      joint.distance = atom_radius * 2.5
      joint.max_bias = max_bias
      @bonds.set other, joint
      other.bonds.set this, joint
      @space.add(joint)

      return true

    bondLoop: ->
      # returns null or a list of atoms in the bond loop which includes itself
      if @bonds.length isnt 2
        return null
      seen = new Map()
      seen.set this, true
      [atom, dest] = @bonds.keys()
      loop
        seen.set atom, true
        if atom is dest
          return seen.keys()
        found = false
        atom.bonds.each (next_atom, joint) ->
          if not seen.contains(next_atom)
            atom = next_atom
            found = true
            return false
          return true
        if not found
          return null

    unbond: ->
      @bonds.each (atom, joint) ->
        atom.bonds.remove this
        @space.remove(joint)
        true
      @bonds = new Map()

    cleanUp: ->
      @unbond()
      @space.remove(@shape)
      if not @rogue
        @space.remove(@shape.body)
      delete Atom.atom_for_shape[@shape]
      @sprite.delete()
      @sprite = null

  class Bomb extends Indexable
    @radius = 16
    @size = new Vec2d(@radius*2, @radius*2)

    constructor: (pos, @sprite, @space, @timeout) ->
      super
      body = new cp.Body(50, 10)
      body.position = pos
      @shape = new cp.Circle(body, Bomb.radius)
      @shape.friction = 0.7
      @shape.elasticity = 0.02
      @shape.collision_type = Collision.Default
      @space.add(body, @shape)

    tick: (dt) ->
      @timeout -= dt

    cleanUp: ->
      @space.remove(@shape, @shape.body)
      @sprite.delete()
      @sprite = null

  class Rock extends Indexable
    @radius = 16
    @size = new Vec2d(@radius*2, @radius*2)

    constructor: (pos, @sprite, @space) ->
      super
      body = new cp.Body(70, 100000)
      body.position = pos
      @shape = new cp.Circle(body, Rock.radius)
      @shape.friction = 0.9
      @shape.elasticity = 0.01
      @shape.collision_type = Collision.Default
      @space.add(body, @shape)

    tick: (dt) ->

    cleanUp: ->
      @space.remove(@shape, @shape.body)
      @sprite.delete()
      @sprite = null

  class Tank
    constructor: (@pos, @dims, @game, @tank_index) ->
      @size = @dims * atom_size
      @other_tank = null
      @atoms = new Set()
      @bombs = new Set()
      @rocks = new Set()

      @queued_asplosions = []

      @min_power = params.power or 3

      @sprite_arm = new Engine.Sprite('arm', batch: @game.batch, group: @game.group_fg)
      @sprite_man = new Engine.Sprite('still', batch: @game.batch, group: @game.group_main)
      @sprite_claw = new Engine.Sprite('claw', batch: @game.batch, group: @game.group_main)

      @space = new cp.Space()
      @space.gravity = new Vec2d(0, -400)
      @space.damping = 0.99
      @space.add_collision_handler(Collision.Claw, Collision.Default, post_solve=@clawHitSomething)
      @space.add_collision_handler(Collision.Claw, Collision.Atom, post_solve=@clawHitSomething)
      @space.add_collision_handler(Collision.Atom, Collision.Atom, post_solve=@atomHitAtom)

      @initControls()
      @mouse_pos = new Vec2d(0, 0)
      @man_dims = new Vec2d(1, 2)
      @man_size = new Vec2d(@man_dims.mult(atom_size))

      @time_between_drops = params.fastatoms or 1
      @time_until_next_drop = 0

      @initWalls()
      @initCeiling()

      @initMan()

      @initGuns()
      @arm_offset = new Vec2d(13, 43)
      @arm_len = 24
      @computeArmPos()

      @closest_atom = null

      @equipped_gun = Control.SwitchToGrapple
      @gun_animations = {}
      @gun_animations[Control.SwitchToGrapple] = "arm"
      @gun_animations[Control.SwitchToRay] = "raygun"
      @gun_animations[Control.SwitchToLazer] = "lazergun"

      @bond_queue = []

      @points = 0
      @points_to_crush = 50

      @point_end = new Vec2d(0.000001, 0.000001)
      
      # if you have this many atoms per tank y or more, you lose
      @lose_ratio = 95 / 300

      @tank_index ?= randInt(0, 1)
      @sprite_tank = new Engine.Sprite("tank#{tank_index}", batch=@game.batch, group=@game.group_main)

      @game_over = false
      @winner = null

      @atom_drop_enabled = true
      @enable_point_calculation = true
      @sfx_enabled = true

    initGuns: ->
      @claw_in_motion = false
      @sprite_claw.visible = false
      @claw_radius = 8
      @claw_shoot_speed = 1200
      @min_claw_dist = 60
      @claw_pins_to_add = null
      @claw_pins = null
      @claw_attached = false
      @want_to_remove_claw_pin = false
      @want_to_retract_claw = false

      @lazer_timeout = 0.5
      @lazer_recharge = 0
      @lazer_line = null
      @lazer_line_timeout = 0
      @lazer_line_timeout_start = 0.2

      @ray_atom = null
      @ray_shoot_speed = 900

    initControls: ->
      @controls = {}
      @controls[Engine.Key.A] = Control.MoveLeft
      @controls[Engine.Key.D] = Control.MoveRight
      @controls[Engine.Key.W] = Control.MoveUp
      @controls[Engine.Key.S] = Control.MoveDown

      @controls[Engine.Key._1] = Control.SwitchToGrapple
      @controls[Engine.Key._2] = Control.SwitchToRay
      @controls[Engine.Key._3] = Control.SwitchToLazer

      @controls[Control.MOUSE_OFFSET+Engine.Mouse.Left] = Control.FireMain
      @controls[Control.MOUSE_OFFSET+Engine.Mouse.Right] = Control.FireAlt

      if params.keyboard is 'dvorak'
        @controls[Engine.Key.A] = Control.MoveLeft
        @controls[Engine.Key.E] = Control.MoveRight
        @controls[Engine.Key.Comma] = Control.MoveUp
        @controls[Engine.Key.S] = Control.MoveDown
      else if params.keyboard is 'colemak'
        @controls[Engine.Key.A] = Control.MoveLeft
        @controls[Engine.Key.S] = Control.MoveRight
        @controls[Engine.Key.W] = Control.MoveUp
        @controls[Engine.Key.R] = Control.MoveDown

      @control_state = (false for x in [0...Control.COUNT])
      @let_go_of_fire_main = true
      @let_go_of_fire_alt = true


    update: (dt) ->
      @adjustCeiling(dt)
      if @atom_drop_enabled
        @computeDrops(dt)

      # check if we died
      ratio = @atoms.length / (@ceiling.body.position.y - @size.y / 2)
      if ratio > @lose_ratio or @ceiling.body.position.y < @man_size.y
        @lose()

      # process bombs
      @bombs.clone().each (bomb) ->
        bomb.tick(dt)
        if bomb.timeout <= 0
          # physics explosion
          # loop over every object in the space and apply an impulse
          for shape in @space.shapes
            vector = shape.body.position - bomb.shape.body.position
            dist = vector.get_length()
            direction = vector.normalized()
            power = 6000
            damp = 1 - dist / 800
            shape.body.apply_impulse(direction * power * damp)

          # explosion animation
          sprite = new Engine.Sprite("bombsplode", batch=@game.batch, group=@game.group_fg)
          sprite.setPosition(@pos.plus(bomb.shape.body.position))
          do (sprite) ->
            removeBombSprite = -> sprite.delete()
          sprite.on("animation_end", removeBombSprite)
          @removeBomb(bomb)

          @playSfx("explode")

        return true

      @processInput(dt)


      # queued actions
      @processQueuedActions()

      @computeAtomPointedAt()

      # update physics
      step_count = Math.floor(dt / (1 / game_fps))
      if step_count < 1
        step_count = 1
      delta = dt / step_count
      for i in [0...step_count]
        @space.step(delta)

      if @want_to_remove_claw_pin
        @space.remove(@claw_pins)
        @claw_pins = null
        @want_to_remove_claw_pin = false

      @computeArmPos()

      # apply our constraints
      # man can't rotate
      @man.body.angle = @man_angle


    removeAtom: (atom) ->
      atom.cleanUp()
      @atoms.remove(atom)

    removeBomb: (bomb) ->
      bomb.cleanUp()
      @bombs.remove(bomb)

    initWalls: ->
      # add the walls of the tank to space
      r = 50
      borders = [
        # right wall
        [new Vec2d(@size.x + r, @size.y), new Vec2d(@size.x + r, 0)],
        # bottom wall
        [new Vec2d(@size.x, -r), new Vec2d(0, -r)],
        # left wall
        [new Vec2d(-r, 0), new Vec2d(-r, @size.y)],
      ]
      for [p1, p2] in borders
        shape = new cp.Segment(new cp.Body(), p1, p2, r)
        shape.friction = 0.99
        shape.elasticity = 0.0
        shape.collision_type = Collision.Default
        @space.add(shape)

    initCeiling: ->
      # physics for ceiling
      body = new cp.Body(10000, 100000)
      body.position = new Vec2d(@size.x / 2, @size.y * 1.5)
      @ceiling = new cp.Poly.create_box(body, @size)
      @ceiling.collision_type = Collision.Default
      @space.add(@ceiling)
      # per second
      @max_ceiling_delta = 200

    adjustCeiling: (dt) ->
      # adjust the descending ceiling as necessary
      if @game.server?
        other_points = @other_tank.points
      else
        other_points = @game.survival_points
      adjust = (@points - other_points) / @points_to_crush * @size.y
      if adjust > 0
        adjust = 0
      if @game_over
        adjust = 0
      target_y = @size.y * 1.5 + adjust

      direction = sign(target_y - @ceiling.body.position.y)
      amount = @max_ceiling_delta * dt
      new_y = @ceiling.body.position.y + amount * direction
      new_sign = sign(target_y - new_y)
      if direction is -new_sign
        # close enough to just set
        @ceiling.body.position.y = target_y
      else
        @ceiling.body.position.y = new_y

    initMan: (pos, vel) ->
      if not pos?
        pos = new Vec2d(@size.x / 2, @man_size.y / 2)
      if not vel?
        vel = new Vec2d(0, 0)
      # physics for man
      shape = new cp.Poly.create_box(new cp.Body(20, 10000000), @man_size)
      shape.body.position = pos
      shape.body.velocity = vel
      shape.body.angular_velocity_limit = 0
      @man_angle = shape.body.angle
      shape.elasticity = 0
      shape.friction = 3.0
      shape.collision_type = Collision.Default
      @space.add(shape.body, shape)
      @man = shape


    computeArmPos: ->
      @arm_pos = @man.body.position - @man_size / 2 + @arm_offset
      @point_vector = (@mouse_pos.minus(@arm_pos)).normalized()
      @point_start = @arm_pos.plus(@point_vector.scale(@arm_len))

    get_drop_pos: (size) ->
      return new Vec2d(
        random.random() * (@size.x - size.x) + size.x / 2,
        @ceiling.body.position.y - @size.y / 2 - size.y / 2,
      )


    drop_bomb: ->
      # drop a bomb
      pos = @get_drop_pos(Bomb.size)
      sprite = new Engine.Sprite('bomb', batch: @game.batch, group: @game.group_main)
      timeout = randInt(1, 5)
      bomb = new Bomb(pos, sprite, @space, timeout)
      @bombs.add(bomb)

    drop_rock: ->
      # drop a rock
      pos = @get_drop_pos(Rock.size)
      sprite = new Engine.Sprite('rock', batch: @game.batch, group: @game.group_main)
      rock = new Rock(pos, sprite, @space)
      @rocks.add(rock)

    computeDrops: (dt) ->
      if @game_over
        return
      @time_until_next_drop -= dt
      if @time_until_next_drop <= 0
        @time_until_next_drop += @time_between_drops
        # drop a random atom
        flavor_index = randInt(0, Atom.flavor_count-1)
        pos = @get_drop_pos(atom_size)
        atom = new Atom(pos, flavor_index, new Engine.Sprite(@game.atom_imgs[flavor_index], batch: @game.batch, group: @game.group_main), @space)
        @atoms.add(atom)


    lose: ->
      if @game_over
        return
      @game_over = true
      @winner = false
      @explode_atoms(@atoms.clone(), "atomfail")

      @sprite_man.image = @game.animations.get("defeat")
      @sprite_arm.visible = false

      @retract_claw()

      if @other_tank?
        @other_tank.win()
      @playSfx("defeat")

    win: ->
      if @game_over
        return

      @game_over = true
      @winner = true
      @explode_atoms(@atoms.clone())

      @sprite_man.image = @game.animations.get("victory")
      @sprite_arm.visible = false

      @retract_claw()

      if @other_tank?
        @other_tank.lose()

      @playSfx("victory")

    explodeAtom: (atom, animation_name="asplosion") ->
      if atom is @ray_atom
        @ray_atom = null
      if @claw_pins? and @claw_pins[0].b is atom.shape.body
        @unattachClaw()
      atom.marked_for_deletion = true
      clearSprite = ->
        @removeAtom(atom)
      atom.sprite.image = @game.animations.get(animation_name)
      atom.sprite.set_handler("on_animation_end", clear_sprite)


    explodeAtoms: (atoms, animation_name="asplosion") ->
      for atom in atoms
        @explodeAtom(atom, animation_name)

    processInput: (dt) ->
      if @game_over
        return

      feet_start = @man.body.position - @man_size / 2 + new Vec2d(1, -1)
      feet_end = new Vec2d(feet_start.x + @man_size.x - 2, feet_start.y - 2)
      bb = new cp.BB(feet_start.x, feet_end.y, feet_end.x, feet_start.y)
      ground_shapes = @space.bb_query(bb)
      grounded = ground_shapes.length > 0

      grounded_move_force = 1000
      not_moving_x = abs(@man.body.velocity.x) < 5.0
      air_move_force = 200
      grounded_move_boost = 30
      air_move_boost = 0
      move_force = if grounded then grounded_move_force else air_move_force
      move_boost = if grounded then grounded_move_boost else air_move_boost
      max_speed = 200
      move_left = @control_state[Control.MoveLeft] and not @control_state[Control.MoveRight]
      move_right = @control_state[Control.MoveRight] and not @control_state[Control.MoveLeft]
      if move_left
        if @man.body.velocity.x >= -max_speed and @man.body.position.x - @man_size.x / 2 - 5 > 0
          @man.body.apply_impulse(new Vec2d(-move_force, 0), new Vec2d(0, 0))
          if @man.body.velocity.x > -move_boost and @man.body.velocity.x < 0
            @man.body.velocity.x = -move_boost
      else if move_right
        if @man.body.velocity.x <= max_speed and @man.body.position.x + @man_size.x / 2 + 3 < @size.x
          @man.body.apply_impulse(new Vec2d(move_force, 0), new Vec2d(0, 0))
          if @man.body.velocity.x < move_boost and @man.body.velocity.x > 0
            @man.body.velocity.x = move_boost

      negate = if @mouse_pos.x < @man.body.position.x then "-" else ""
      # jumping
      if grounded
        if move_left or move_right
          animation_name = "walk"
        else
          animation_name = "still"
      else
        animation_name = "jump"

      if @control_state[Control.MoveUp] and grounded
        animation_name = "jump"
        @sprite_man.image = @game.animations.get(negate + animation_name)
        @man.body.velocity.y = 100
        @man.body.apply_impulse(new Vec2d(0, 2000), new Vec2d(0, 0))
        # apply a reverse force upon the atom we jumped from
        power = 1000 / ground_shapes.length
        for shape in ground_shapes
          shape.body.apply_impulse(new Vec2d(0, -power), new Vec2d(0, 0))
        @playSfx('jump')

      # point the man+arm in direction of mouse
      animation = @game.animations.get(negate + animation_name)
      if @sprite_man.image isnt animation
        @sprite_man.image = animation

      # selecting a different gun
      if @control_state[Control.SwitchToGrapple] and @equipped_gun isnt Control.SwitchToGrapple
        @equipped_gun = Control.SwitchToGrapple
        @playSfx('switch_weapon')
      else if @control_state[Control.SwitchToRay] and @equipped_gun isnt Control.SwitchToRay
        @equipped_gun = Control.SwitchToRay
        @playSfx('switch_weapon')
      else if @control_state[Control.SwitchToLazer] and @equipped_gun isnt Control.SwitchToLazer
        @equipped_gun = Control.SwitchToLazer
        @playSfx('switch_weapon')

      if @equipped_gun is Control.SwitchToGrapple
        if @claw_in_motion
          ani_name = "arm-flung"
        else
          ani_name = "arm"
        arm_animation = @game.animations.get(negate + ani_name)
      else
        arm_animation = @game.animations.get(negate + @gun_animations[@equipped_gun])

      if @sprite_arm.image isnt arm_animation
        @sprite_arm.image = arm_animation

      if @equipped_gun is Control.SwitchToGrapple
        claw_reel_in_speed = 400
        claw_reel_out_speed = 200
        if not @want_to_remove_claw_pin and not @want_to_retract_claw and @let_go_of_fire_main and @control_state[Control.FireMain] and not @claw_in_motion
          @let_go_of_fire_main = false
          @claw_in_motion = true
          @sprite_claw.visible = true
          body = new cp.Body(mass=5, moment=1000000)
          body.position = new Vec2d(@point_start)
          body.angle = @point_vector.get_angle()
          body.velocity = @man.body.velocity + @point_vector * @claw_shoot_speed
          @claw = new cp.Circle(body, @claw_radius)
          @claw.friction = 1
          @claw.elasticity = 0
          @claw.collision_type = Collision.Claw
          @claw_joint = new cp.SlideJoint(@claw.body, @man.body, new Vec2d(0, 0), new Vec2d(0, 0), 0, @size.get_length())
          @claw_joint.max_bias = max_bias
          @space.add(body, @claw, @claw_joint)

          @playSfx('shoot_claw')

        if @sprite_claw.visible
          claw_dist = (@claw.body.position - @man.body.position).get_length()

        if @control_state[Control.FireMain] and @claw_in_motion
          if claw_dist < @min_claw_dist + 8
            if @claw_pins?
              @want_to_retract_claw = true
              @let_go_of_fire_main = false
            else if @claw_attached and @let_go_of_fire_main
              @retract_claw()
              @let_go_of_fire_main = false
          else if claw_dist > @min_claw_dist
            # prevent the claw from going back out once it goes in
            if @claw_attached and @claw_joint.max > claw_dist
              @claw_joint.max = claw_dist
            else
              @claw_joint.max -= claw_reel_in_speed * dt
              if @claw_joint.max < @min_claw_dist
                @claw_joint.max = @min_claw_dist
        if @control_state[Control.FireAlt] and @claw_attached
          @unattachClaw()

      @lazer_recharge -= dt
      if @equipped_gun is Control.SwitchToLazer
        if @lazer_line?
          @lazer_line[0] = @point_start
        if @control_state[Control.FireMain] and @lazer_recharge <= 0
          # IMA FIRIN MAH LAZERZ
          @lazer_recharge = @lazer_timeout
          @lazer_line = [@point_start, @point_end]
          @lazer_line_timeout = @lazer_line_timeout_start

          if @closest_atom?
            @explodeAtom(@closest_atom, "atomfail")
            @closest_atom = null

          @playSfx('lazer')
      @lazer_line_timeout -= dt
      if @lazer_line_timeout <= 0
        @lazer_line = null

      if @ray_atom?
        # move the atom closer to the ray gun
        vector = @point_start - @ray_atom.shape.body.position
        delta = vector.normalized() * 1000 * dt
        if delta.get_length() > vector.get_length()
          # just move the atom to final location
          @ray_atom.shape.body.position = @point_start
        else
          @ray_atom.shape.body.position += delta

      if @equipped_gun is Control.SwitchToRay
        if (@control_state[Control.FireMain] and @let_go_of_fire_main) and @closest_atom? and not @ray_atom? and not @closest_atom.marked_for_deletion
          # remove the atom from physics
          @ray_atom = @closest_atom
          @ray_atom.rogue = true
          @closest_atom = null
          @space.remove(@ray_atom.shape.body)
          @let_go_of_fire_main = false
          @ray_atom.unbond()

          @playSfx('ray')
        else if ((@control_state[Control.FireMain] and @let_go_of_fire_main) or @control_state[Control.FireAlt]) and @ray_atom?
          @space.add(@ray_atom.shape.body)
          @ray_atom.rogue = false
          if @control_state[Control.FireMain]
            # shoot it!!
            @ray_atom.shape.body.velocity = @man.body.velocity + @point_vector * @ray_shoot_speed
            @playSfx('lazer')
          else
            @ray_atom.shape.body.velocity = new Vec2d(@man.body.velocity)
          @ray_atom = null
          @let_go_of_fire_main = false

      if not @control_state[Control.FireMain]
        @let_go_of_fire_main = true

        if @want_to_retract_claw
          @want_to_retract_claw = false
          @retract_claw()
      if not @control_state[Control.FireAlt] and not @let_go_of_fire_alt
        @let_go_of_fire_alt = true

    processQueuedActions: ->
      if @claw_pins_to_add?
        @claw_pins = @claw_pins_to_add
        @claw_pins_to_add = null
        @space.add(@claw_pins)

      for [atom1, atom2] in @bond_queue
        if atom1.marked_for_deletion or atom2.marked_for_deletion
          continue
        if atom1 is @ray_atom or atom2 is @ray_atom
          continue
        if not atom1.bonds? or not atom2.bonds?
          print("Warning: trying to bond with an atom that doesn't exist anymore")
          continue
        if atom1.bondTo(atom2)
          bond_loop = atom1.bondLoop()
          if bond_loop?
            len_bond_loop = bond_loop.length
            # make all the atoms in this loop disappear
            if @enable_point_calculation
              @points += len_bond_loop
            @explode_atoms(bond_loop)
            @queued_asplosions.append([atom1.flavor_index, len_bond_loop])

            @playSfx("merge")
          else
            @playSfx("bond")

      @bond_queue = []

    clawHitSomething: (space, arbiter) ->
      if @claw_attached
        return
      # bolt these bodies together
      [claw, shape] = arbiter.shapes
      pos = arbiter.contacts[0].position
      shape_anchor = pos - shape.body.position
      claw_anchor = pos - claw.body.position
      claw_delta = claw_anchor.normalized() * -(@claw_radius + 8)
      @claw.body.position += claw_delta
      @claw_pins_to_add = [
        new cp.PinJoint(claw.body, shape.body, claw_anchor, shape_anchor),
        new cp.PinJoint(claw.body, shape.body, new Vec2d(0, 0), new Vec2d(0, 0)),
      ]
      for claw_pin in @claw_pins_to_add
        claw_pin.max_bias = max_bias
      @claw_attached = true

      @playSfx("claw_hit")

    atomHitAtom: (space, arbiter) ->
      [atom1, atom2] = [Atom.atom_for_shape[shape] for shape in arbiter.shapes]
      # bond the atoms together
      if atom1.flavor_index is atom2.flavor_index
        @bond_queue.append([atom1, atom2])

    playSfx: (name) ->
      if @sfx_enabled and @game.sfx?
        @game.sfx[name].play()

    retract_claw: ->
      if not @sprite_claw.visible
        return
      @claw_in_motion = false
      @sprite_claw.visible = false
      @sprite_arm.image = @game.animations.get("arm")
      @claw_attached = false
      @space.remove(@claw.body, @claw, @claw_joint)
      @claw = null
      @unattachClaw()
      @playSfx("retract")

    unattachClaw: ->
      if @claw_pins?
        #@claw.body.reset_forces()
        @want_to_remove_claw_pin = true

    computeAtomPointedAt: ->
      if @equipped_gun is Control.SwitchToGrapple
        @closest_atom = null
      else
        # iterate over each atom. check if intersects with line.
        @closest_atom = null
        closest_dist = null
        @atoms.each (atom) ->
          if atom.marked_for_deletion
            return
          # http://stackoverflow.com/questions/1073336/circle-line-collision-detection
          f = atom.shape.body.position - @point_start
          if sign(f.x) isnt sign(@point_vector.x) or sign(f.y) isnt sign(@point_vector.y)
            return
          a = @point_vector.dot(@point_vector)
          b = 2 * f.dot(@point_vector)
          c = f.dot(f) - atom_radius*atom_radius
          discriminant = b*b - 4*a*c
          if discriminant < 0
            return

          dist = atom.shape.body.position.get_dist_sqrd(@point_start)
          if not @closest_atom? or dist < closest_dist
            @closest_atom = atom
            closest_dist = dist

          true

      if @closest_atom?
        # intersection
        # use the coords of the closest atom
        @point_end = @closest_atom.shape.body.position
      else
        # no intersection
        # find the coords at the wall
        slope = @point_vector.y / (@point_vector.x+0.00000001)
        y_intercept = @point_start.y - slope * @point_start.x
        @point_end = @point_start + @size.get_length() * @point_vector
        if @point_end.x > @size.x
          @point_end.x = @size.x
          @point_end.y = slope * @point_end.x + y_intercept
        if @point_end.x < 0
          @point_end.x = 0
          @point_end.y = slope * @point_end.x + y_intercept
        if @point_end.y > @ceiling.body.position.y - @size.y / 2
          @point_end.y = @ceiling.body.position.y - @size.y / 2
          @point_end.x = (@point_end.y - y_intercept) / slope
        if @point_end.y < 0
          @point_end.y = 0
          @point_end.x = (@point_end.y - y_intercept) / slope

    respond_to_asplosion: (asplosion) ->
      [flavor, quantity] = asplosion

      power = quantity - @min_power
      if power <= 0
        return

      if flavor <= 3
        # bombs
        for i in [0...power]
          @drop_bomb()
      else
        # rocks
        for i in [0...power]
          @drop_rock()

    on_key_press: (symbol, modifiers) ->
      control = @controls[symbol]
      if control?
        @control_state[control] = true

    on_key_release: (symbol, modifiers) ->
      control = @controls[symbol]
      if control?
        @control_state[control] = false

    moveMouse: (x, y) ->
      @mouse_pos = (new Vec2d(x, y)).minus(@pos)

      use_crosshair = @mouse_pos.x >= 0 and \
              @mouse_pos.y >= 0 and \
              @mouse_pos.x <= @size.x and \
              @mouse_pos.y <= @size.y
      cursor = if use_crosshair then @game.crosshair else @game.default_cursor
      @game.window.set_mouse_cursor(cursor)

    on_mouse_motion: (x, y, dx, dy) ->
      @moveMouse(x, y)

    on_mouse_drag: (x, y, dx, dy, buttons, modifiers) ->
      @moveMouse(x, y)

    on_mouse_press: (x, y, button, modifiers) ->
      control = @controls[Control.MOUSE_OFFSET+button]
      if control?
        @control_state[control] = true

    on_mouse_release: (x, y, button, modifiers) ->
      control = @controls[Control.MOUSE_OFFSET+button]
      if control?
        @control_state[control] = false

    moveSprites: ->
      # drawable things
      drawDrawable = ->
        drawable.sprite.setPosition(drawable.shape.body.position.plus(@pos))
        drawable.sprite.rotation = -drawable.shape.body.rotation_vector.get_angle_degrees()
        true
      @atoms.each drawDrawable
      @bombs.each drawDrawable
      @rocks.each drawDrawable

      @sprite_man.setPosition(@man.body.position.plus(@pos))
      @sprite_man.rotation = -@man.body.rotation_vector.get_angle_degrees()

      @sprite_arm.setPosition(@arm_pos.plus(@pos))
      @sprite_arm.rotation = -(@mouse_pos - @man.body.position).get_angle_degrees()
      if @mouse_pos.x < @man.body.position.x
        @sprite_arm.rotation += 180

      @sprite_tank.setPosition(@pos.plus(@ceiling.body.position))

      if @sprite_claw.visible
        @sprite_claw.setPosition(@claw.body.position.plus(@pos))
        @sprite_claw.rotation = -@claw.body.rotation_vector.get_angle_degrees()

    drawPrimitives: ->
      # draw a line from gun hand to @point_end
      if not @game_over
        @drawLine(@point_start + @pos, @point_end + @pos, [0, 0, 0, 0.23])

        # draw a line from gun to claw if it's out
        if @sprite_claw.visible
          @drawLine(@point_start + @pos, @sprite_claw.position, [1, 1, 0, 1])

        # draw lines for bonded atoms
        @atoms.each (atom) ->
          if atom.marked_for_deletion
            return
          atom.bonds.each (other, joint) ->
            @drawLine(@pos + atom.shape.body.position, @pos + other.shape.body.position, [0, 0, 1, 1])
            true
          true

        if @game.debug
          if @claw_pins
            for claw_pin in @claw_pins
              @drawLine(@pos + claw_pin.a.position + claw_pin.anchr1, @pos + claw_pin.b.position + claw_pin.anchr2, [1, 0, 1, 1])

        # lazer
        if @lazer_line?
          [start, end] = @lazer_line
          @drawLine(start + @pos, end + @pos, [1, 0, 0, 1])

    drawLine: (p1, p2, color) ->
      pyglet.gl.glColor4f(color[0], color[1], color[2], color[3])
      pyglet.graphics.draw(2, pyglet.gl.GL_LINES, ['v2f', [p1[0], p1[1], p2[0], p2[1]]])

  class Game
    constructor: (@gw, @window, @server) ->
      @debug = params.debug?

      @animations = new Animations()
      @animations.load()

      @batch = engine.createBatch()
      @group_bg = engine.createOrderedGroup(0)
      @group_main = engine.createOrderedGroup(1)
      @group_fg = engine.createOrderedGroup(2)

      @sprite_bg = new Engine.Sprite("bg.png", batch: @batch, group: @group_bg)
      @sprite_bg_top = new Engine.Sprite("bg-top.png", batch: @batch, group: @group_fg, pos: new Vec2d(0, img_bg.height-img_bg_top.height))

      @atom_imgs = ("atom#{i}" for i in [0...Atom.flavor_count])


      unless params.nofx?
        @sfx = {
          'jump': pyglet.resource.media('data/sfx/jump__dave-des__fast-simple-chop-5.ogg', streaming=false),
          'atom_hit_atom': pyglet.resource.media('data/sfx/atomscolide__batchku__colide-18-005.ogg', streaming=false),
          'ray': pyglet.resource.media('data/sfx/raygun__owyheesound__decelerate-discharge.ogg', streaming=false),
          'lazer': pyglet.resource.media('data/sfx/lazer__supraliminal__laser-short.ogg', streaming=false),
          'merge': pyglet.resource.media('data/sfx/atomsmerge__tigersound__disappear.ogg', streaming=false),
          'bond': pyglet.resource.media('data/sfx/bond.ogg', streaming=false),
          'victory': pyglet.resource.media('data/sfx/victory__iut-paris8__labbefabrice-2011-01.ogg', streaming=false),
          'defeat': pyglet.resource.media('data/sfx/defeat__freqman__lostspace.ogg', streaming=false),
          'switch_weapon': pyglet.resource.media('data/sfx/switchweapons__erdie__metallic-weapon-low.ogg', streaming=false),
          'explode': pyglet.resource.media('data/sfx/atomsexplode3-1.ogg', streaming=false),
          'claw_hit': pyglet.resource.media('data/sfx/shootingtheclaw__smcameron__rocks2.ogg', streaming=false),
          'shoot_claw': pyglet.resource.media('data/sfx/landonsurface__juskiddink__thud-dry.ogg', streaming=false),
          'retract': pyglet.resource.media('data/sfx/clawcomesback__simon-rue__studs-moln-v4.ogg', streaming=false),
        }
      else
        @sfx = null

      pyglet.clock.schedule_interval(@update, 1/game_fps)
      if params.fps?
        @fps_display = pyglet.clock.ClockDisplay()
      else
        @fps_display = null

      @crosshair = @window.get_system_mouse_cursor(@window.CURSOR_CROSSHAIR)
      @default_cursor = @window.get_system_mouse_cursor(@window.CURSOR_DEFAULT)

      tank_dims = new Vec2d(12, 16)
      tank_pos = [
        new Vec2d(109, 41),
        new Vec2d(531, 41),
      ]

      if not @server?
        @tanks = [new Tank(tank_pos[0], tank_dims, self)]
        @control_tank = @tanks[0]

        @survival_points = 0
        @survival_point_timeout = params.hard or 10
        @next_survival_point = @survival_point_timeout
        @weapon_drop_interval = params.bomb or 10

        tank_index = int(not @control_tank.tank_index)
        tank_name = "tank%i" % tank_index
        @sprite_other_tank = new Engine.Sprite(tank_name, batch: @batch, group: @group_main, pos: new Vec2d(tank_pos[1].x + @control_tank.size.x / 2, tank_pos[1].y + @control_tank.size.y / 2))
      else
        @tanks = [new Tank(pos, tank_dims, self, tank_index=i) for pos, i in enumerate(tank_pos)]

        @control_tank = @tanks[0]
        @enemy_tank = @tanks[1]

        @control_tank.other_tank = @enemy_tank
        @enemy_tank.other_tank = @control_tank

        @enemy_tank.atom_drop_enabled = false
        @enemy_tank.enable_point_calculation = false
        @enemy_tank.sfx_enabled = false



      @window.set_handler('on_draw', @on_draw)
      @window.set_handler('on_mouse_motion', @control_tank.on_mouse_motion)
      @window.set_handler('on_mouse_drag', @control_tank.on_mouse_drag)
      @window.set_handler('on_mouse_press', @control_tank.on_mouse_press)
      @window.set_handler('on_mouse_release', @control_tank.on_mouse_release)
      @window.set_handler('on_key_press', @control_tank.on_key_press)
      @window.set_handler('on_key_release', @control_tank.on_key_release)


      pyglet.gl.glEnable(pyglet.gl.GL_BLEND)
      pyglet.gl.glBlendFunc(pyglet.gl.GL_SRC_ALPHA, pyglet.gl.GL_ONE_MINUS_SRC_ALPHA)


      @state_render_timeout = 0.3
      @next_state_render = @state_render_timeout



    update: (dt) ->
      for tank in @tanks
        tank.update(dt)

      if not @server?
        # give enemy points
        @next_survival_point -= dt
        if @next_survival_point <= 0
          @next_survival_point += @survival_point_timeout
          old_number = Math.floor(@survival_points / @weapon_drop_interval)
          @survival_points += randInt(3, 6)
          new_number = Math.floor(@survival_points / @weapon_drop_interval)

          if new_number > old_number
            n = randInt(1, 2)
            if n is 1
              @control_tank.drop_bomb()
            else
              @control_tank.drop_rock()

      # send state to network
      if @server?
        @next_state_render -= dt
        if @next_state_render <= 0
          @next_state_render = @state_render_timeout

          @server.send_msg("StateUpdate", @control_tank.serialize_state())

          # get all server messages
          for [msg_name, data] in @server.get_messages()
            if msg_name is 'StateUpdate'
              @enemy_tank.restore_state(data)
            else if msg_name is 'YourOpponentLeftSorryBro'
              print("you win - your opponent disconnected.")
              @control_tank.win()


    on_draw: ->
      @window.clear()

      for tank in @tanks
        tank.moveSprites()

      @batch.draw()

      for tank in @tanks
        tank.drawPrimitives()
      

      if @fps_display?
        @fps_display.draw()

  class GameWindow
    constructor: (@engine, @server) ->
      @current = null

    endCurrent: ->
      if @current?
        @current.end()
      @current = null

    title: ->
      @endCurrent()
      @current = new Title(this, @engine, @server)

    play: (server_on=true) ->
      server = if server_on then @server else null
      @endCurrent()
      @current = new Game(this, @engine, server)

    credits: ->
      @endCurrent()
      @current = new Credits(this, @engine)

    controls: ->
      @endCurrent()
      @current = new ControlsScene(this, @engine)

  class ControlsScene
    constructor: (@gw, @window) ->
      @img = pyglet.resource.image("data/howtoplay.png")
      @window.set_handler('on_draw', @on_draw)
      @window.set_handler('on_mouse_press', @on_mouse_press)
      pyglet.clock.schedule_interval(@update, 1/game_fps)

    update: (dt) ->

    on_draw: ->
      @window.clear()
      @img.blit(0, 0)

    end: ->
      @window.remove_handler('on_draw', @on_draw)
      @window.remove_handler('on_mouse_press', @on_mouse_press)
      pyglet.clock.unschedule(@update)

    on_mouse_press: (x, y, button, modifiers) ->
      @gw.title()


  class Credits
    constructor: (@gw, @window) ->
      @img = pyglet.resource.image("data/credits.png")
      @window.set_handler('on_draw', @on_draw)
      @window.set_handler('on_mouse_press', @on_mouse_press)
      pyglet.clock.schedule_interval(@update, 1/game_fps)

    update: (dt) ->

    on_draw: ->
      @window.clear()
      @img.blit(0, 0)

    end: ->
      @window.remove_handler('on_draw', @on_draw)
      @window.remove_handler('on_mouse_press', @on_mouse_press)
      pyglet.clock.unschedule(@update)

    on_mouse_press: (x, y, button, modifiers) ->
      @gw.title()


  class Title
    constructor: (@gw, @engine, @server) ->
      @engine.on 'mousedown', @onMouseDown
      @engine.on 'draw', @draw
      @engine.on 'update', @update

      @batch = new Engine.Batch()
      @img = new Engine.Sprite("title", batch: @batch)

      @start_pos = new Vec2d(409, 305)
      @credits_pos = new Vec2d(360, 229)
      @controls_pos = new Vec2d(525, 242)
      @click_radius = 50

      @lobby_pos = new Vec2d(746, 203)
      @lobby_size = new Vec2d(993.0 - @lobby_pos.x, 522.0 - @lobby_pos.y)

      if @server?
        @labels = []
        @users = []

        @nick_label = {}
        @nick_user = {}

        # guess a good nick
        @nick = "Guest %i" % randInt(1, 99999)
        @server.send_msg("UpdateNick", @nick)
        @my_nick_label = pyglet.text.Label(@nick, font_size=16, x=748, y=137)

        @challenged = {}

    createLabels: ->
      @labels = []
      @nick_label = {}
      @nick_user = {}
      h = 18
      next_pos = @lobby_pos + new Vec2d(0, @lobby_size.y - h)
      for user in @users
        nick = user['nick']
        if nick is @nick
          continue
        text = nick
        if user['playing']?
          text += " (playing vs %s)" % user['playing']
        else if @nick in user['want_to_play']
          text += " (click to accept challenge)"
        else if nick in @challenged
          text += " (challenge sent)"
        else
          text += " (click to challenge)"
        label = pyglet.text.Label(text, font_size=13, x=next_pos.x, y=next_pos.y)
        @nick_label[nick] = label
        @nick_user[nick] = user
        next_pos.y -= h
        @labels.append(label)

    update: (dt) =>
      if @server?
        for [name, payload] in server.get_messages()
          if name is 'LobbyList'
            @users = payload
            @createLabels()
          else if name is 'StartGame'
            @gw.play()
            return

    draw: =>
      @engine.clear()
      @engine.draw @batch
      if @server?
        for label in @labels
          label.draw()
        @my_nick_label.draw()

    end: ->
      @engine.removeListener 'draw', @onDraw
      @engine.removeListener 'mousedown', @onMouseDown
      @engine.removeListener 'update', @update

    onMouseDown: (x, y, button, modifiers) =>
      click_pos = new Vec2d(x, y)
      if click_pos.get_distance(@start_pos) < @click_radius
        @gw.play(server_on=false)
        return
      else if click_pos.get_distance(@credits_pos) < @click_radius
        @gw.credits()
        return
      else if click_pos.get_distance(@controls_pos) < @click_radius
        @gw.controls()
        return

      if @server?
        for nick, label of @nick_label
          label_pos = new Vec2d(label.x, label.y)
          label_size = new Vec2d(200, 18)
          if click_pos.x > label_pos.x and click_pos.y > label_pos.y and click_pos.x < label_pos.x + label_size.x and click_pos.y < label_pos.y + label_size.y
            user = @nick_user[nick]
            if not user?
              print("warn missing nick" + nick)
              return

            if not user['playing']
              if @nick in user['want_to_play']
                @server.send_msg("AcceptPlayRequest", nick)
              else
                @server.send_msg("PlayRequest", nick)
                @challenged[nick] = true
                @createLabels()
            return

  params = do ->
    obj = {}
    obj[key] = val for [key, val] in location.search.substring(1).split("&")
    obj


  canvas = document.getElementById("game")
  engine = new Engine(canvas)
  w = new GameWindow(engine, null)
  w.title()
  engine.start()

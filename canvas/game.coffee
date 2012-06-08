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

  Collision =
    Default: 0
    Claw: 1
    Atom: 2

  Control =
    MOUSE_OFFSET: 255

    MoveLeft: 0
    MoveRight: 1
    MoveUp: 2
    MoveDown: 3
    FireMain: 4
    FireAlt: 5
    SwitchToGrapple: 6
    SwitchToRay: 7
    SwitchToLazer: 8

  class Atom
    @flavor_count: 6

    @atom_for_shape: {}
    @max_bonds: 2

    @id_count: 0

    constructor: (pos, @flavor_index, @sprite, @space) ->
      body = pymunk.Body(10, 100000)
      body.position = pos
      @shape = pymunk.Circle(body, atom_radius)
      @shape.friction = 0.5
      @shape.elasticity = 0.05
      @shape.collision_type = Collision.Atom
      @space.add(body, @shape)

      Atom.atom_for_shape[@shape] = this
      # atom => joint
      @bonds = {}
      @marked_for_deletion = false
      @rogue = false

      @id = Atom.id_count
      Atom.id_count += 1

    bondTo: (other) ->
      # already bonded
      if @bonds[other]?
        return false
      # too many bonds already
      if len(@bonds) >= Atom.max_bonds or len(other.bonds) >= Atom.max_bonds
        return false
      # wrong color
      if @flavor_index isnt other.flavor_index
        return false

      joint = pymunk.PinJoint(@shape.body, other.shape.body)
      joint.distance = atom_radius * 2.5
      joint.max_bias = max_bias
      @bonds[other] = joint
      other.bonds[this] = joint
      @space.add(joint)

      return true

    bondLoop: ->
      # returns null or a list of atoms in the bond loop which includes itself
      if len(@bonds) != 2
        return null
      seen = {this: true}
      atom, dest = @bonds.keys()
      loop
        seen[atom] = true
        if atom is dest
          return seen.keys()
        found = false
        for next_atom, joint of atom.bonds
          if not seen[next_atom]?
            atom = next_atom
            found = true
            break
        if not found
          return null

    unbond: ->
      for atom, joint of @bonds
        delete atom.bonds[this]
        @space.remove(joint)
      @bonds = {}

    cleanUp: ->
      @unbond()
      @space.remove(@shape)
      if not @rogue
        @space.remove(@shape.body)
      delete Atom.atom_for_shape[@shape]
      @sprite.delete()
      @sprite = None

  canvas = document.getElementById("game")
  engine = new Engine(canvas)
  engine.on 'update', (dt, dx) ->
  engine.on 'draw', (context) ->
    context.clearRect 0, 0, engine.size.x, engine.size.y
    context.fillText "#{engine.fps} fps", 0, engine.size.y
  engine.on 'mousedown', (pos) -> console.log pos.x, pos.y
  engine.start()

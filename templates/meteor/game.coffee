canvas = document.getElementById("game")
engine = new Chem(canvas)
batch = new Chem.Batch()
sprite = new Chem.Sprite('meteor', batch: batch, pos: new Vec2d(200, 200))
engine.on 'update', ->
  if engine.buttonJustPressed Chem.Button.Key_1
    console.log "press 1"
    sprite.scale.x = -1
  else if engine.buttonJustPressed Chem.Button.Key_2
    console.log "press 2"
    sprite.scale.x = 1
  else if engine.buttonJustPressed Chem.Button.Key_3
    sprite.scale.x = -2
  else if engine.buttonJustPressed Chem.Button.Key_4
    sprite.scale.x = 2
  else if engine.buttonJustPressed Chem.Button.Key_Space
    sprite.setVisible(not sprite.visible)

  if engine.buttonState(Chem.Button.Mouse_Left)
    sprite.pos = engine.mousePos()
  if engine.buttonState(Chem.Button.Mouse_Right)
    sprite.rotation += 3.14 / 20

engine.on 'draw', (context) ->
  engine.clear()
  engine.draw(batch)
  engine.drawFps()
engine.start()
###
class Control:
    MoveLeft = 0
    MoveRight = 1
    MoveUp = 2
    MoveDown = 3

class Thing(object):
    def __init__(self, x, y, dx, dy, sprite):
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.gone = False
        self.sprite = sprite

    def delete(self):
        self.gone = True
        if self.sprite is not None:
            self.sprite.delete()
            self.sprite = None

class Game(object):
    def __init__(self, window):

        self.hadGameOver = False
        self.stars = []
        self.meteors = []
        self.batch = pyglet.graphics.Batch()
        self.group = pyglet.graphics.OrderedGroup(0)
        self.img_ship = pyglet.resource.image('ship.png')
        self.img_star = [
            pyglet.resource.image('star.png'),
            pyglet.resource.image('star2.png'),
        ]
        self.img_meteor = [
            pyglet.resource.image('meteor.png'),
            pyglet.resource.image('meteor2.png'),
        ]
        self.mwidth = self.img_meteor[0].width
        self.mheight = self.img_meteor[0].height
        self.sprite_ship = pyglet.sprite.Sprite(self.img_ship, group=self.group, batch=self.batch)

        self.window = window
        self.window.set_handler('on_draw', self.on_draw)
        self.window.set_handler('on_key_press', self.on_key_press)
        self.window.set_handler('on_key_release', self.on_key_release)
        pyglet.clock.schedule_interval(self.update, 1/60)
        pyglet.clock.schedule_interval(self.createStar, 0.1)
        pyglet.clock.schedule_interval(self.garbage, 10)
        self.nextMeteorInterval = 0.3
        self.nextMeteor = self.nextMeteorInterval

        self.fps_display = pyglet.clock.ClockDisplay()

        self.controls = {
            pyglet.window.key.LEFT: Control.MoveLeft,
            pyglet.window.key.RIGHT: Control.MoveRight,
            pyglet.window.key.UP: Control.MoveUp,
            pyglet.window.key.DOWN: Control.MoveDown,
        }
        self.control_state = [False] * (len(dir(Control)) - 2)

        self.ship_x = 0
        self.ship_y = self.window.height / 2
        self.ship_dx = 0
        self.ship_dy = 0

        self.label_score = pyglet.text.Label('Score', font_name="Arial", font_size=18, x=0, y=self.window.height - 30, batch=self.batch, group=self.group, color=(255, 255, 255, 255), multiline=False, anchor_x="left", anchor_y='bottom')
        self.score = 0


    def garbage(self, dt):
        self.stars = filter(lambda star: not star.gone, self.stars)

    def createStar(self, dt):
        self.stars.append(Thing(self.window.width, random.randint(0, self.window.height), -400 + random.random() * 200, 0,
            pyglet.sprite.Sprite(self.img_star[random.randint(0,1)], group=self.group, batch=self.batch)))

    def createMeteor(self):
        self.meteors.append(Thing(self.window.width, random.randint(0, self.window.height), -600 + random.random() * 400, -200 + random.random() * 400,
            pyglet.sprite.Sprite(self.img_meteor[random.randint(0,1)], group=self.group, batch=self.batch)))

    def start(self):
        pass

    def update(self, dt):
        if self.hadGameOver:
            return
        self.label_score.text = str(int(self.score))
        score_per_sec = 60
        self.score += score_per_sec * dt

        self.nextMeteor -= dt
        if self.nextMeteor <= 0:
            self.nextMeteor = self.nextMeteorInterval
            self.createMeteor()

        self.nextMeteorInterval -= dt * 0.01

        for thing in itertools.chain(self.stars, self.meteors):
            if not thing.gone:
                thing.x += thing.dx * dt
                thing.y += thing.dy * dt
                thing.sprite.x = thing.x
                thing.sprite.y = thing.y
                if thing.x < 0:
                    thing.delete()

        ship_accel = 600
        if self.control_state[Control.MoveLeft]:
            self.ship_dx -= ship_accel * dt
        if self.control_state[Control.MoveRight]:
            self.ship_dx += ship_accel * dt
        if self.control_state[Control.MoveUp]:
            self.ship_dy += ship_accel * dt
        if self.control_state[Control.MoveDown]:
            self.ship_dy -= ship_accel * dt

        self.ship_x += self.ship_dx * dt
        self.ship_y += self.ship_dy * dt

        if self.ship_x < 0:
            self.ship_x = 0
            self.ship_dx = 0
        if self.ship_y < 0:
            self.ship_y = 0
            self.ship_dy = 0
        if self.ship_x + self.img_ship.width > self.window.width:
            self.ship_x = self.window.width - self.img_ship.width
            self.ship_dx = 0
        if self.ship_y + self.img_ship.height > self.window.height:
            self.ship_y = self.window.height - self.img_ship.height
            self.ship_dy = 0

        self.sprite_ship.x = self.ship_x
        self.sprite_ship.y = self.ship_y

        for meteor in self.meteors:
            if meteor.gone:
                continue
            not_colliding = self.ship_x > meteor.x + self.mwidth or \
                self.ship_y > meteor.y + self.mheight or \
                self.ship_x + self.img_ship.width < meteor.x or  \
                self.ship_y + self.img_ship.height < meteor.y
            if not not_colliding:
                self.gameOver()
                break
    def gameOver(self):
        if self.hadGameOver:
            return
        self.hadGameOver = True
        self.label_gameover = pyglet.text.Label('GAME OVER', font_name="Arial", font_size=25, x=0, y=self.window.height / 2, batch=self.batch, group=self.group, color=(255, 255, 255, 255), multiline=False, anchor_x="left", anchor_y='bottom')

    def on_draw(self):
        self.window.clear()

        self.batch.draw()

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
        


window = pyglet.window.Window(width=853, height=480)
game = Game(window)
game.start()
pyglet.app.run()

###

from __future__ import division, print_function, unicode_literals; range = xrange
import pyglet
from pygame.locals import *
import sys

game_title = "Dr. Chemical's Lab"
game_fps = 60
game_size = (1024, 600)

tank_loc = [(108, 54), (531, 55)]

window = pyglet.window.Window(width=game_size[0], height=game_size[1], caption=game_title)
fps_display = pyglet.clock.ClockDisplay()
bg = pyglet.resource.image("data/bg.png")

@window.event
def on_draw():
    window.clear()
    bg.blit(0, 0)
    fps_display.draw()

def update(dt):
    pass

pyglet.clock.schedule_interval(update, 1/game_fps)

pyglet.app.run()

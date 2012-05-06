import pygame
from pygame.locals import *
import sys

game_title = "Dr. Chemical's Lab"
game_fps = 60

pygame.init()
fps_clock = pygame.time.Clock()

window = pygame.display.set_mode((800, 600))
pygame.display.set_caption(game_title)

color_black = pygame.Color(0, 0, 0)

while True:
    window.fill(color_black)

    for event in pygame.event.get():
        if event.type is QUIT:
            pygame.quit()
            sys.exit()
        elif event.type is KEYDOWN:
            if event.key is K_ESCAPE:
                pygame.event.post(pygame.event.Event(QUIT))
    pygame.display.update()
    fps_clock.tick(game_fps)

#!/usr/bin/env python3

from __future__ import division
import argparse
import sys
from random import randint, choice
from pyfiglet import Figlet

from asciimatics.effects import Scroll, Mirage, Wipe, Cycle, Matrix, \
    BannerText, Stars, Print
from asciimatics.particles import RingFirework, SerpentFirework, StarFirework, \
    PalmFirework
from asciimatics.particles import DropScreen
from asciimatics.renderers import FigletText, Rainbow, Fire
from asciimatics.scene import Scene
from asciimatics.screen import Screen
from asciimatics.exceptions import ResizeScreenError


def _credits(screen):
    scenes = []

    text = Figlet(font="banner", width=200).renderText("MusicPlayer")
    width = max([len(x) for x in text.split("\n")])

    effects = [
        Print(screen,
              Fire(screen.height, 80, text, 0.4, 40, screen.colours),
              0,
              speed=1,
              transparent=False),
        Print(screen,
              FigletText("MusicPlayer", "banner"),
              screen.height - 9, x=(screen.width - width) // 2 + 1,
              colour=Screen.COLOUR_BLACK,
              bg=Screen.COLOUR_BLACK,
              speed=1),
        Print(screen,
              FigletText("MusicPlayer", "banner"),
              screen.height - 9,
              colour=Screen.COLOUR_WHITE,
              bg=Screen.COLOUR_WHITE,
              speed=1),
    ]
    scenes.append(Scene(effects, 100))

    text = Figlet(font="banner", width=200).renderText("Plus!")
    width = max([len(x) for x in text.split("\n")])

    effects = [
        Print(screen,
              Fire(screen.height, 80, text, 0.4, 60, screen.colours),
              0,
              speed=1,
              transparent=False),
        Print(screen,
              FigletText("Plus!", "banner"),
              screen.height - 9, x=(screen.width - width) // 2 + 1,
              colour=Screen.COLOUR_BLACK,
              bg=Screen.COLOUR_BLACK,
              speed=1),
        Print(screen,
              FigletText("Plus!", "banner"),
              screen.height - 9,
              colour=Screen.COLOUR_WHITE,
              bg=Screen.COLOUR_WHITE,
              speed=1),
    ]
    scenes.append(Scene(effects, 100))

    effects = [
        Matrix(screen, stop_frame=200),
        Mirage(
            screen,
            FigletText("MusicPlayerPlus"),
            screen.height // 2 - 3,
            Screen.COLOUR_GREEN,
            start_frame=100,
            stop_frame=200),
        Wipe(screen, start_frame=150),
        Cycle(
            screen,
            FigletText("MusicPlayerPlus"),
            screen.height // 2 - 3,
            start_frame=200)
    ]
    scenes.append(Scene(effects, 250, clear=False))

    effects = [
        BannerText(
            screen,
            Rainbow(screen, FigletText(
                "Reliving the 80s in glorious ASCII text...", font='slant')),
            screen.height // 2 - 3,
            Screen.COLOUR_GREEN)
    ]
    scenes.append(Scene(effects))

    effects = [
        Scroll(screen, 3),
        Mirage(
            screen,
            FigletText("Conceived and"),
            screen.height,
            Screen.COLOUR_GREEN),
        Mirage(
            screen,
            FigletText("written by:"),
            screen.height + 8,
            Screen.COLOUR_GREEN),
        Mirage(
            screen,
            FigletText("Ronald Joe Record"),
            screen.height + 16,
            Screen.COLOUR_GREEN)
    ]
    scenes.append(Scene(effects, (screen.height + 24) * 3))

    effects = [
        BannerText(
            screen,
            Rainbow(screen, FigletText(
                "MusicPlayerPlus", font='banner3-D')),
            screen.height // 2 - 3,
            Screen.COLOUR_CYAN)
    ]
    scenes.append(Scene(effects))

    effects = [
        BannerText(
            screen,
            Rainbow(screen, FigletText(
                "ASCII MPD Client", font='banner3-D')),
            screen.height // 2 - 3,
            Screen.COLOUR_CYAN)
    ]
    scenes.append(Scene(effects))

    effects = [
        BannerText(
            screen,
            Rainbow(screen, FigletText(
                "Album Cover Art", font='banner3-D')),
            screen.height // 2 - 3,
            Screen.COLOUR_CYAN)
    ]
    scenes.append(Scene(effects))

    effects = [
        BannerText(
            screen,
            Rainbow(screen, FigletText(
                "Spectrum Visualizer", font='banner3-D')),
            screen.height // 2 - 3,
            Screen.COLOUR_CYAN)
    ]
    scenes.append(Scene(effects))

    effects = [
        Cycle(
            screen,
            FigletText("MUSIC PLAYER PLUS", font='big'),
            screen.height // 2 - 8,
            stop_frame=100),
        Cycle(
            screen,
            FigletText("ROCKS!", font='big'),
            screen.height // 2 + 3,
            stop_frame=100),
        Stars(screen, (screen.width + screen.height) // 2, stop_frame=100),
        DropScreen(screen, 200, start_frame=100)
    ]
    scenes.append(Scene(effects, 200))

    effects = [
        Stars(screen, screen.width),
    ]
    for _ in range(20):
        fireworks = [
            (PalmFirework, 25, 30),
            (PalmFirework, 25, 30),
            (StarFirework, 25, 35),
            (StarFirework, 25, 35),
            (StarFirework, 25, 35),
            (RingFirework, 20, 30),
            (SerpentFirework, 30, 35),
        ]
        firework, start, stop = choice(fireworks)
        effects.insert(
            1,
            firework(screen,
                     randint(0, screen.width),
                     randint(screen.height // 8, screen.height * 3 // 4),
                     randint(start, stop),
                     start_frame=randint(0, 250)))

    effects.append(Print(screen,
                         Rainbow(screen, FigletText("MUSIC")),
                         screen.height // 2 - 6,
                         speed=1,
                         start_frame=100))
    effects.append(Print(screen,
                         Rainbow(screen, FigletText("PLAYER PLUS!")),
                         screen.height // 2 + 1,
                         speed=1,
                         start_frame=100))
    scenes.append(Scene(effects, 300))

    if numcycles is None:
        screen.play(scenes, stop_on_resize=True)
    else:
        screen.play(scenes, stop_on_resize=True, repeat=False)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--cycle", help="number of times to cycle back through effects")
    args = parser.parse_args()

    if args.cycle:
        numcycles = args.cycle
    else:
        numcycles = None

    while True:
        try:
            Screen.wrapper(_credits)
            sys.exit(0)
        except ResizeScreenError:
            pass
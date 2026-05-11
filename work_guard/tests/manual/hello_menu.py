#!/usr/bin/env python3
import rumps

class HelloApp(rumps.App):
    def __init__(self):
        super().__init__("HI", quit_button="Выйти")

if __name__ == "__main__":
    HelloApp().run()

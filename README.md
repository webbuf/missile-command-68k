Missile Command written entirely in 68K Assembly with no external engine or libraries.

# How to run:
Download [Easy68K](http://www.easy68k.com/). Open game.x68 within Easy68K and run. 

# How to play:
Arrow keys move reticle. Z, X, and C fire missiles from the left, center, and right silos, respectively.

# Features:
## Bitmap and Vector Renderers:
Bitmap files can be loaded and drawn as either a square or line, depending on the renderer. Both renderers are highly optimized, including how the data is stored in memory compared to how it's stored in a .bmp. Line renderer is an implementation of Bresenham's algorithm, and can draw either a solid color or pull colors from a bitmap image.
Works directly with system calls to draw pixels to the screen. Uses double buffering to aboid scrolling images as they're drawn.

## Object Oriented Logic:
Uses data labels and subroutines to define a piece of memory as an object that "object subroutines" know how to act on, making it far easier to create game objects. 

## Memory Management:
Heap manager system tracks and can free memory allocations. Works with bitmap renderes and "objects" to handle memory for all game systems.

## Other nifty things!
Fixed point physics, seven segment displays for score tracking, and pseudo random number generation have been implemented as well. 

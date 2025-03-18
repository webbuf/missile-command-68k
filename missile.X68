*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

M_MAX_SPAWN_X EQU 520
M_MIN_SPAWN_X EQU 120
*borders for where to spawn missiles

M_MIN_SPEED_X       EQU -2
M_MAX_SPEED_X       EQU 3 *exclusive, so this is always less than y
M_CONST_SPEED_Y     EQU 4

M_COLOR_TASK   EQU 80
M_PIXEL_TASK   EQU 82
M_LINE_TASK    EQU 84

M_RED               EQU $000000FF
M_WHITE             EQU $00FFFFFF
M_FLASH_BITMASK     EQU $00FF0000

M_KILL_Y       EQU  400 *when the missile goes below this, it despawns

***Missile Struct***
M_ORIGINAL_Y  EQU 0
M_ORIGINAL_X  EQU 2
M_CURRENT_Y   EQU 4
M_CURRENT_X   EQU 6
M_SPEED_Y     EQU 8
M_SPEED_X     EQU 10
M_COLOR       EQU 12
M_STRUCT_SIZE EQU 16

***
*
* a0.out - address of missile
*
***
missile_Init:
    move.l #M_STRUCT_SIZE, d1
    bsr mem_Alloc *allocate space for missile
    
    move.w #0, M_ORIGINAL_Y(a0) *missiles spawn at the top of the screen
    move.w #0, M_CURRENT_Y(a0) *when they spawn, their current = their original
    move.w #M_MAX_SPAWN_X, d0
    move.w #M_MIN_SPAWN_X, d1
    bsr rand_getVal
    move.w d0, M_ORIGINAL_X(a0) *get a random spawn position, not spawning on the borders of the screen
    move.w d0, M_CURRENT_X(a0)     
    
    move.w #M_CONST_SPEED_Y, M_SPEED_Y(a0) *i don't think we need to save this because it's constant but it feels good and we can change it
    move.w #M_MAX_SPEED_X, d0
    move.w #M_MIN_SPEED_X, d1
    bsr rand_getVal
    move.w d0, M_SPEED_X(a0)
    *init speed, similar logic to getting the spawn position
    
    move.l #M_WHITE, M_COLOR(a0) *init color
    
    rts *return value already set in a0, so just peace out
    
***
*
* a1 - address of missile in memory
*
* d0.b out - 0 all good, 1 missile despawns
*
***
missile_Update
.LOAD_REG REG d2-d4/a2
    movem.l .LOAD_REG, -(sp)
    
    move.w M_CURRENT_X(a1), d1
    move.w d1, d2
    add.w M_SPEED_X(a1), d2
    move.w d2, M_CURRENT_X(a1)
    *load the current x, add the speed, and save it
    
    swap d1
    swap d2
    
    move.w M_CURRENT_Y(a1), d1
    move.w d1, d2
    add.w #M_CONST_SPEED_Y, d2
    move.w d2, M_CURRENT_Y(a1)
    *do the same for the y
    
    *we do this business with putting it in two places and swapping due to how the drawline expects parameters
    
    move.l #M_RED, d0
    bsr drawLineColor
    *draw the line just from where we were to where we are. rest of the line is static
    
    move.w d1, d3 *save this off because we have to draw again!!! wahey!!!
    *what fucking numbskull made save color AND x of the position to draw d1
    
    move.l M_COLOR(a1), d1
    eor.l #M_FLASH_BITMASK, d1 
    move.l d1, M_COLOR(a1)
    *get the color, use the bitmask to flash it, and store it
    
    move.b #M_COLOR_TASK, d0
    trap #15
    *draw out current color (still in d1) for the missile
    
    move.w M_CURRENT_X(a1), d1
    move.w M_CURRENT_Y(a1), d2
    move.b #M_PIXEL_TASK, d0
    trap #15
    *get the missile's position so we can draw the white pixel for it
    
    cmp #M_KILl_Y, d2 *if we're below our missile kill plane, we're going to explode it
    blt .done
    
    clr.l d1
    clr.l d2
    
    move.w M_CURRENT_X(a1), d1
    move.w M_CURRENT_Y(a1), d2
    
    bsr explosion_Init *spawn explosion
    bsr missile_Erase *erase missile - subroutine to call from elsewhere
    
    movem.l (sp)+, .LOAD_REG
    move.b #1, d0
    rts
    
.done
    movem.l (sp)+, .LOAD_REG
    move.b #0, d0
    rts

missile_Erase:
    movem.l a1, -(sp)
    move.w M_ORIGINAL_X(a1), d1
    move.w M_CURRENT_X(a1), d2

    swap d1
    swap d2

    or.w M_ORIGINAL_Y(a1), d1
    or.w M_CURRENT_Y(a1), d2 
    
    move.l (BG_Address), a1 *2 way dependency because this is in the game file. but who cares
    
    bsr drawLineBMP
    *load up our coordinates and draw the line from the start to the end of our trail, with the background. 
    movem.l (sp)+, a1
    rts
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

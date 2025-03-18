M_MAX_SPAWN_X EQU 520
M_MIN_SPAWN_X EQU 120
*borders for where to spawn missiles

M_COLOR_TASK   EQU 80
M_PIXEL_TASK   EQU 82
M_LINE_TASK    EQU 84

M_RED               EQU $000000FF
M_WHITE             EQU $00FFFFFF
M_FLASH_BITMASK     EQU $00FF0000

M_STEP_COUNT   EQU  3 *however many steps per frame it takes in its steeper direction
M_KILL_Y       EQU  400 *when the missile goes below this, it despawns

M_REDRAW_TIMER EQU 7

***Missile Struct***
M_ORIGINAL_Y  EQU 0
M_ORIGINAL_X  EQU 2
M_CURRENT_Y   EQU 4
M_CURRENT_X   EQU 6
M_TARGET_Y    EQU 8
M_TARGET_X    EQU 10
M_DY          EQU 12
M_DX          EQU 14
M_X_DIR       EQU 16
M_Y_DIR       EQU 18
M_SPEED       EQU 20
M_TOTAL_STEPS EQU 22
M_ERROR       EQU 24
M_COLOR       EQU 28
M_REDRAW      EQU 32
M_STRUCT_SIZE EQU 34

***
*
* d0.w - spawn X
* d1.w - spawn Y
* d2.w - target X
* d3.w - target Y
* d4.w - speed
*
* a0.out - address of missile
*
***
missileB_Init:
.LOAD_REGS REG d4-d7
    movem.l .LOAD_REGS, -(sp)
    
    move.w d1, d5
    move.w d0, d6
    
    move.l #M_STRUCT_SIZE, d1
    bsr mem_Alloc *allocate space for missile
    
    move.w d6, d0
    move.w d5, d1
    
    move.w d0, M_ORIGINAL_X(a0)
    move.w d1, M_ORIGINAL_Y(a0)
    move.w d0, M_CURRENT_X(a0)
    move.w d1, M_CURRENT_Y(a0)
    move.w d2, M_TARGET_X(a0)
    move.w d3, M_TARGET_Y(a0)
    *set up our spawn and target positions. at init time, current = original
    
    move.w d4, M_SPEED(a0)
    
    move.w #1, d5
    move.w #1, d6 *for movement directions
    
    sub.w d0, d2 *target - spawn = dx
    tst d2       *check if d2 negative
    bgt .dontNegDX
    neg.w d2
    neg.w d5 *bresenham only likes positive numbers, so make it go like that. 
    *we can still do slope calcs moving in the right dir by keeping these separate dir values to actually modify our vals
    
.dontNegDX
    move.w d2, M_DX(a0)
    move.w d5, M_X_DIR(a0)
    
    sub.w d1, d3 *target - spawn = dy
    tst d3       *check if d2 negative
    bgt .dontNegDY
    neg.w d3
    neg.w d6
.dontNegDY
    move.w d3, M_DY(a0)
    move.w d6, M_Y_DIR(a0)
    
    move.w M_DX(a0), d3
    move.w M_DY(a0), d4
        
    clr.l d7
    
    cmp.w d3, d4
    bgt .initY
    move.w d4, d7
    muls #2, d7
    sub.l d3, d7
    move.l d7, M_ERROR(a0)
    bra .finalize
.initY
    move.w d3, d7
    muls #2, d7
    sub.l d4, d7
    move.l d7, M_ERROR(a0)

.finalize  
    move.l #M_WHITE, M_COLOR(a0) *init color
    move.w #0, M_TOTAL_STEPS(a0)
    move.w #M_REDRAW_TIMER, M_REDRAW(a0)
    
    movem.l (sp)+, .LOAD_REGS
    rts *return value already set in a0, so just peace out
    
    
***
*
* a1 - address of missile in memory
*
* d0.b out - 0 all good, 1 missile despawns
*
***
missileB_Update:
.LOAD_REG REG d2-d7/a2
    movem.l .LOAD_REG, -(sp)
    
    move.w M_REDRAW(a1), d1
    sub.w #1, d1
    move.w d1, M_REDRAW(a1)
    tst d1
    bne .dontRedraw *timer to redraw the missile's trail. fixes itself every 7 frames or so
    move.w #M_REDRAW_TIMER, M_REDRAW(a1) *reset timer
    
    move.w M_ORIGINAL_X(a1), d1
    move.w M_CURRENT_X(a1), d2
    swap d1
    swap d2
    move.w M_ORIGINAL_Y(a1), d1
    move.w M_CURRENT_Y(a1), d2
    move.l #M_RED, d0
    bsr drawLineColor
.dontRedraw
    move.l M_COLOR(a1), d1
    eor.l #M_FLASH_BITMASK, d1 
    move.l d1, M_COLOR(a1)
    
    move.b #M_COLOR_TASK, d0
    move.l #M_RED, d1
    trap #15
    *set draws as red for the trail
    
    move.w M_CURRENT_X(a1), d1
    move.w M_CURRENT_Y(a1), d2
    *load our current position, so we can move
    
    move.b #M_PIXEL_TASK, d0
    trap #15
    
    move.w M_DX(a1), d3
    move.w M_DY(a1), d4
    *load up dy and dx for move, and to figure out which to call
    
    cmp.w d3, d4
    
    bgt .callY
    bsr missileB_MoveX
    bra .finalize
.callY
    bsr missileB_MoveY
.finalize

    move.w d1, M_CURRENT_X(a1)
    move.w d2, M_CURRENT_Y(a1)
    *modify where our current position is
    
    move.l M_COLOR(a1), d1
    move.b #M_COLOR_TASK, d0
    trap #15
    
    move.w M_CURRENT_X(a1), d1
    move.b #M_PIXEL_TASK, d0
    trap #15
    
    move.w M_SPEED(a1), d6
    add.w #1, d6
    add.w d6, M_TOTAL_STEPS(a1)
    
    cmp.w d3, d4
    bge .checkY
    
    cmp.w M_TOTAL_STEPS(a1), d3
    bge .done
    
    clr.l d1
    clr.l d2
    
    move.w M_CURRENT_X(a1), d1
    move.w M_CURRENT_Y(a1), d2
    
    bsr missileB_Erase *erase missile - subroutine to call from elsewhere
    
    move.w M_CURRENT_X(a1), d1
    move.w M_CURRENT_Y(a1), d2
    
    bsr explosion_Init *spawn explosion


    bra .died
.checkY
    cmp.w M_TOTAL_STEPS(a1), d4
    bge .done
    
    clr.l d1
    clr.l d2
    
    move.w M_CURRENT_X(a1), d1
    move.w M_CURRENT_Y(a1), d2
    
    bsr missileB_Erase *erase missile - subroutine to call from elsewhere
    
    move.w M_CURRENT_X(a1), d1
    move.w M_CURRENT_Y(a1), d2
    
    bsr explosion_Init *spawn explosion

    
.died
    move.b #1, d0
    movem.l (sp)+, .LOAD_REG
    rts
    
.done
    move.b #0, d0
    movem.l (sp)+, .LOAD_REG
    rts
    

missileB_MoveX:
    clr.l d7
    move.l M_ERROR(a1), d5
    *get starting error
        
    move.w M_SPEED(a1), d6 *set up loop counter
    
.moveLoop
    add.w M_X_DIR(a1), d1
    trap #15
    tst.l d5
    blt .dontModifyY
    
    add.w M_Y_DIR(a1), d2
    move.w d4, d7
    sub.l d3, d7
    muls #2, d7
    add.l d7, d5
    dbf d6, .moveLoop
    bra .done
    
.dontModifyY
    move.l d4, d7
    muls #2, d7
    add.l d7, d5
    dbf d6, .moveLoop

.done
    move.l d5, M_ERROR(a1)
    rts
    
    
missileB_MoveY:
    clr.l d7
    move.l M_ERROR(a1), d5
    *get starting error
        
    move.w M_SPEED(a1), d6 *set up loop counter
    
.moveLoop
    add.w M_Y_DIR(a1), d2
    trap #15
    tst.l d5
    blt .dontModifyX
    
    add.w M_X_DIR(a1), d1
    move.w d3, d7
    sub.l d4, d7
    muls #2, d7
    add.l d7, d5
    dbf d6, .moveLoop
    bra .done
    
.dontModifyX
    move.l d3, d7
    muls #2, d7
    add.l d7, d5
    dbf d6, .moveLoop

.done
    move.l d5, M_ERROR(a1)
    rts
    
    
missileB_Erase: **BITMAP**
.LOAD_REG REG d2-d4/a1-a4
    movem.l .LOAD_REG, -(sp)
    
    move.l a1, a4
    
    move.w M_ORIGINAL_X(a4), d1
    move.w M_CURRENT_X(a4), d2
    
    move.w M_DX(a4), d3
    move.w M_DY(a4), d4
    
    swap d1
    swap d2

    move.w M_ORIGINAL_Y(a4), d1
    move.w M_CURRENT_Y(a4), d2 
    
    move.l (BG_Address), a1 *2 way dependency because this is in the game file. but who cares
    
    bsr drawLineBMP
           
    move.w M_ORIGINAL_X(a4), d1
    move.w M_CURRENT_X(a4), d2
    
    cmp.w d3, d4
    blt .dontFuzzX1
    add.w #1, d1
    add.w #1, d2
.dontFuzzX1
    swap d1
    swap d2

    move.w M_ORIGINAL_Y(a4), d1
    move.w M_CURRENT_Y(a4), d2 
    
    cmp.w d3, d4
    bgt .dontFuzzY1
    add.w #1, d1
    add.w #1, d2
.dontFuzzY1
    
    move.l (BG_Address), a1 *2 way dependency because this is in the game file. but who cares
    
    bsr drawLineBMP
    
    move.w M_ORIGINAL_X(a4), d1
    move.w M_CURRENT_X(a4), d2
    
    cmp.w d3, d4
    blt .dontFuzzX2
    add.w #-1, d1
    add.w #-1, d2
.dontFuzzX2
    
    swap d1
    swap d2

    move.w M_ORIGINAL_Y(a4), d1
    move.w M_CURRENT_Y(a4), d2 
    
    cmp.w d3, d4
    bgt .dontFuzzY2
    add.w #-1, d1
    add.w #-1, d2
.dontFuzzY2
    
    move.l (BG_Address), a1 *2 way dependency because this is in the game file. but who cares
    
    bsr drawLineBMP
           
    *load up our coordinates and draw the line from the start to the end of our trail, with the background. 
    movem.l (sp)+, .LOAD_REG
    rts





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

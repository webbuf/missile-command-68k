PLANE_HEAD_OFF       EQU -12
PLANE_BACK_OFF       EQU 55
PLANE_WING_OFF_X     EQU 45
PLANE_WING_OFF_YUP   EQU -10
PLANE_WING_OFF_YDOWN EQU 8
PLANE_TAIL_OFF_X     EQU 12
PLANE_TAIL_OFF_Y     EQU -14

PLANE_X              EQU 0
PLANE_Y              EQU 2
PLANE_SIZE           EQU 4

PLANE_SPAWN_X        EQU 572

PLANE_MAX_HEIGHT     EQU 300
PLANE_MIN_HEIGHT     EQU 100

PLANE_SPEED          EQU -7

PLANE_KILL_X         EQU 12

PLANE_BOMB_CHANCE    EQU 45

TASK_SET_PEN         EQU 80
TASK_DRAW_LINE       EQU 84

WHITE                EQU $00FFFFFF


plane_Init:
    move.l (PlaneContainer), d1
    tst.l d1 *if there's already an active plane, don't spawn another one
    bne .done
    move.w #PLANE_SIZE, d1
    bsr mem_Alloc
    move.l a0, (PlaneContainer) *save address in container, so we can access it later
    move.w #PLANE_SPAWN_X, PLANE_X(a0) *always spawns on the right side of the screen
    move.w #PLANE_MAX_HEIGHT, d0
    move.w #PLANE_MIN_HEIGHT, d1
    bsr rand_getVal          *get random point in the sky to spawn at
    move.w d0, PLANE_Y(a0)
.done
    rts 

plane_Update
    move.l (PlaneContainer), d1
    tst.l d1
    beq .done
    move.l d1, a0
    
    clr.l d1
    
    move.w PLANE_X(a0), d1
    move.w PLANE_Y(a0), d2
    bsr plane_Erase
    
    move.l (PlaneContainer), a0
    
    move.w PLANE_X(a0), d1
    move.w PLANE_Y(a0), d2
    add.w #PLANE_SPEED, d1
    move.w d1, PLANE_X(a0)
    
    move.w #PLANE_BOMB_CHANCE, d0
    move.w #0, d1
    bsr rand_getVal
    tst.w d0
    bne .checkDie
    move.l (PlaneContainer), a0
    move.w PLANE_X(a0), d1
    move.w PLANE_Y(a0), d2 *have to reload params i love non volatile regs!
    bsr bomb_Init 
.checkDie
    move.l (PlaneContainer), a0
    move.w PLANE_X(a0), d1
    cmp #PLANE_KILL_X, d1
    bgt .draw
    move.l a0, a1
    bsr mem_Free
    move.l #0, (PlaneContainer)
    bra .done
.draw
    bsr plane_Draw    
    
.done
    rts

***
*
* d1.w - x
* d2.w - y
*
***

plane_Draw:
.LOAD_REG REG d2-d4
    movem.l .LOAD_REG, -(sp)
    
    move.w d1, d4 *save d1
    
    move.b #TASK_SET_PEN, d0
    move.l #WHITE, d1 *set pen color
    trap #15
    
    move.b #TASK_DRAW_LINE, d0 *set line trap
    
    move.w d4, d1 *restore d1
    
    move.w d1, d3
    move.w d2, d4
    
    add.w #PLANE_HEAD_OFF, d3
    trap #15 *draw line segment for front of plane
    
    add.w #(PLANE_BACK_OFF-PLANE_HEAD_OFF), d3
    *move point back to center, and then back enough to draw back of plane
    trap #15
    
    add.w #PLANE_BACK_OFF, d1
    add.w #PLANE_TAIL_OFF_X, d3
    add.w #PLANE_TAIL_OFF_Y, d4
    trap #15
    *draw tail
    
    sub.w #PLANE_BACK_OFF, d1
    sub.w #(PLANE_BACK_OFF+PLANE_TAIL_OFF_X), d3
    sub.w #PLANE_TAIL_OFF_Y, d4
    *reset to center
    
    add.w #PLANE_WING_OFF_X, d3
    add.w #PLANE_WING_OFF_YUP, d4
    trap #15
    *first wing
    
    add.w #(PLANE_WING_OFF_YDOWN-PLANE_WING_OFF_YUP), d4
    trap #15
    
    movem.l (sp)+, .LOAD_REG
    rts

***
*
* same params as draw
*
***
plane_Erase:
.LOAD_REG REG d2-d6
    movem.l .LOAD_REG, -(sp)
    move.w d1, d3
    move.w d1, d5
    move.w d2, d4
    move.w d2, d6
    
    move.l (BG_Address), a1
    
    add.w #PLANE_HEAD_OFF, d5
    move.w d3, d1
    move.w d5, d2
    swap d1
    swap d2
    move.w d4, d1
    move.w d6, d2
    bsr drawLineBMP
    
    add.w #(PLANE_BACK_OFF-PLANE_HEAD_OFF), d5
    move.w d3, d1
    move.w d5, d2
    swap d1
    swap d2
    move.w d4, d1
    move.w d6, d2
    move.l (BG_Address), a1
    bsr drawLineBMP
    *move point back to center, and then back enough to draw back of plane
    
    add.w #PLANE_BACK_OFF, d3
    add.w #PLANE_TAIL_OFF_X, d5
    add.w #PLANE_TAIL_OFF_Y, d6
    
    move.w d3, d1
    move.w d5, d2
    swap d1
    swap d2
    move.w d4, d1
    move.w d6, d2
    
    move.l (BG_Address), a1
    bsr drawLineBMP
    *draw tail
    
    sub.w #PLANE_BACK_OFF, d3
    sub.w #(PLANE_BACK_OFF+PLANE_TAIL_OFF_X), d5
    sub.w #PLANE_TAIL_OFF_Y, d6
    *reset to center
    
    add.w #PLANE_WING_OFF_X, d5
    add.w #PLANE_WING_OFF_YUP, d6
    
    move.w d3, d1
    move.w d5, d2
    swap d1
    swap d2
    move.w d4, d1
    move.w d6, d2
    move.l (BG_Address), a1
    bsr drawLineBMP
    *first wing
    
    add.w #(PLANE_WING_OFF_YDOWN-PLANE_WING_OFF_YUP), d6
    move.w d3, d1
    move.w d5, d2
    swap d1
    swap d2
    move.w d4, d1
    move.w d6, d2
    move.l (BG_Address), a1
    bsr drawLineBMP
    
    movem.l (sp)+, .LOAD_REG
    rts
    
plane_Clean:
    move.l (PlaneContainer), d1
    tst d1
    beq .done
    move.l d1, a1
    bsr mem_Free
    move.l #0, (PlaneContainer)
.done
    rts
    
    
PlaneContainer dcb.l 1,0
 




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

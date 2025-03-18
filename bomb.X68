***bombs work in fixed point 10.6***

GRAVITY EQU $001A *00101010, .5 and change

BOMB_RADIUS     EQU 7
BOMB_V0_X       EQU $0120 *5 pixels
BOMB_V0_Y       EQU $00A0 *idk i'm just playing with it

BOMB_POS_X      EQU 0
BOMB_POS_Y      EQU 2 
BOMB_VELOCITY_X EQU 4
BOMB_VELOCITY_Y EQU 6
BOMB_SIZE       EQU 8
*all member variabes in FP 10.6

BOMB_COUNT      EQU 2

BLACK           EQU $004F4F4F

BOMB_KILL_Y     EQU $5F00 *in FP because we compare it when it's like that, 380 px

***
*
* d1.w - x (in just an integer)
* d2.w - y (in a normal int)
*
***
bomb_Init:
.LOAD_REG REG d2-d5/a2
    movem.l .LOAD_REG, -(sp)
    lea BombContainer, a1
    move.w #BOMB_COUNT, d3 *prepare for looping through container to find place to spawn
    
.findLoop
    move.l (a1)+, d4
    tst d4
    beq .spawn
    dbf d3, .findLoop
    bra .done
    
.spawn
    move.w d1, d5
    move.l a1, d4
    clr.l d1
    move.w #BOMB_SIZE, d1
    bsr mem_Alloc
    move.l d4, a1
    move.l a0, -4(a1) *used postinc to move through find loop, so we have to backtrack when we spawn
    lsl.w #6, d5
    lsl.w #6, d2 *shift the initial pos over to account for FP
    move.w d5, BOMB_POS_X(a0)
    move.w d2, BOMB_POS_Y(a0) *use params to choose spawn position
    move.w #BOMB_V0_Y, d4 *initial y velocity always the same
    neg.w d4
    move.w d4, BOMB_VELOCITY_Y(a0) *don't feel like figuring out negating the initial y velocity myself
    move.w #BOMB_V0_X, d4 *store this to maybe neg it later
    move.w #2, d0
    move.w #0, d1
    bsr rand_getVal *get a random value of 0 or 1 to determine the direction of the velocity
    tst.w d0
    beq .dontNeg
    neg.w d4
.dontNeg
    move.w d4, BOMB_VELOCITY_X(a0)
.done
    movem.l (sp)+, .LOAD_REG
    rts 
    
bomb_Update:
.LOAD_REG REG d2-d6/a2
    movem.l .LOAD_REG, -(sp)
    lea BombContainer, a2
    move.w #BOMB_COUNT, d6
    
.updateLoop
    move.l (a2)+, d5
    tst.l d5
    beq .increment
    move.l d5, a1
    bsr eraseBomb
    
    move.l d5, a1
    move.w BOMB_POS_X(a1), d1
    move.w BOMB_POS_Y(a1), d2
    move.w BOMB_VELOCITY_X(a1), d3
    move.w BOMB_VELOCITY_Y(a1), d4
    
    **PHYSICS** 
    add.w d3, d1
    move.w d1, BOMB_POS_X(a1) *increment our x position by constant velocity
    
    add.w #GRAVITY, d4
    move.w d4, BOMB_VELOCITY_Y(a1) *increment y velocity by constant acceleration
    
    add.w d4, d2
    move.w d2, BOMB_POS_Y(a1) *increment y position by acceleration
    
    cmp #BOMB_KILL_Y, d2
    blt .draw
    move.l #$00000000, -4(a2)
    move.w d1, d3 *save d1
    bsr mem_Free *free the bomb
    
    move.w d3, d1
    
    lsr #5, d1
    add.w #1, d1
    lsr #1, d1

    lsr #5, d2
    add.w #1, d2
    lsr #1, d2
    *get FP into screen position for explosion
    
    bsr explosion_Init
    bra .increment
    
.draw
    bsr drawBomb

.increment
    dbf d6, .updateLoop
    
    movem.l (sp)+, .LOAD_REG
    rts

***
*
* a1 - bomb address
*
***
drawBomb:
.LOAD_REG REG d2-d4
    movem.l .LOAD_REG, -(sp)
    move.b #TASK_SET_PEN, d0
    move.l #BLACK, d1
    trap #15
    
    move.b #TASK_SET_FILL, d0
    trap #15
    *set pen and fill colors to black for bomb
    
    move.b #TASK_DRAW_CIRCLE, d0
    
    move.w BOMB_POS_X(a1), d1
    move.w BOMB_POS_Y(a1), d2
    
    lsr #5, d1
    add.w #1, d1
    lsr #1, d1
    *shift it over 5, add 1, then shift again
    *this way, if we have a .5 in FP, we round up, otherwise we round down
    
    lsr #5, d2
    add.w #1, d2
    lsr #1, d2
    
    move.w d1, d3
    move.w d2, d4
    
    sub.w #BOMB_RADIUS, d1
    sub.w #BOMB_RADIUS, d2
    add.w #BOMB_RADIUS, d3
    add.w #BOMB_RADIUS, d4
    
    trap #15
    movem.l (sp)+, .LOAD_REG
    rts

***
*
* a1 - bomb address
*
***
eraseBomb:
.LOAD_REG REG d2-d4/a1
    movem.l .LOAD_REG, -(sp)
    
    move.w BOMB_POS_X(a1), d2
    move.w BOMB_POS_Y(a1), d3
    
    lsr #5, d2
    add.w #1, d2
    lsr #1, d2
    
    lsr #5, d3
    add.w #1, d3
    lsr #1, d3
    *same rounding as in draw
    
    move.w d2, d0
    move.w d0, d1
    sub.w #BOMB_RADIUS+1, d0
    add.w #BOMB_RADIUS+1, d1
    
    swap d0
    swap d1
    
    move.w d3, d0
    move.w d0, d1
    sub.w #BOMB_RADIUS+1, d0
    add.w #BOMB_RADIUS+1, d1
    
    move.l d0, d2
    
    move.l (BG_Address), a1
    bsr bmp_Draw
    
    movem.l (sp)+, .LOAD_REG
    rts

bomb_Clean:
    lea BombContainer, a2
    move.w #BOMB_COUNT, d3
.cleanLoop
    move.l (a2)+, d1
    tst.l d1
    beq .increment
    move.l d1, a1
    bsr mem_Free
    move.l #0, -4(a2)
.increment
    dbf d3, .cleanLoop

    rts 


BombContainer dcb.l 3,0

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

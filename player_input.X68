IN_BLUE        EQU $00FFFF00
TASK_SET_PEN   EQU 80
TASK_SET_FILL  EQU 81
TASK_DRAW_RECT EQU 87
TASK_GET_TIME  EQU 8

RETICLE_GAP    EQU 2
RETICLE_WIDTH  EQU 3
RETICLE_LENGTH EQU 9

RETICLE_START_X   EQU $0140
RETICLE_START_Y   EQU $00F0

RETICLE_SPEED     EQU 8

RETICLE_POS_X     EQU 0
RETICLE_POS_Y     EQU 2
RETICLE_SIZE      EQU 4

MISSILE_SPAWN_X_Z      EQU 30
MISSILE_SPAWN_X_X      EQU 320
MISSILE_SPAWN_X_C      EQU 600
MISSILE_SPAWN_Y      EQU 380
PLAYER_MISSILE_SPEED EQU 9

ARROW_KEYS    EQU $25262728
SPACE         EQU $00000020
ZXC           EQU $005A5843
TASK_KEYDOWN  EQU 19
FIRE_COOLDOWN EQU 30
*since the reticle works more with primitives, which expect x and y like this, store it like this

***
*
*
* out a0 - address of reticle
*
***
input_Init **INPUT** *this whole file is input stuff*
    move.l #RETICLE_SIZE, d1
    bsr mem_Alloc *allocate space for reticle
    move.w #RETICLE_START_X, RETICLE_POS_X(a0) *give it the start position
    move.w #RETICLE_START_Y, RETICLE_POS_Y(a0) *give it the start position
    move.l a0, (Reticle)
    
    move.l #FIRE_COOLDOWN, (FireCooldownZ)
    move.l #FIRE_COOLDOWN, (FireCooldownX)
    move.l #FIRE_COOLDOWN, (FireCooldownC)
    *set the cooldown in all three, so they can all always fire
    rts


debug_DrawLine:
.LOAD_REGS REG d2-d4/a2
    movem.l .LOAD_REGS, -(sp)
  
    move.w #84, d0
   ; move.w #MISSILE_SPAWN_X, d1
    move.w #MISSILE_SPAWN_Y, d2
    move.w RETICLE_POS_X(a1), d3
    move.w RETICLE_POS_Y(a1), d4
    trap #15
    
  ;  move.w #MISSILE_SPAWN_X, d1
    move.w RETICLE_POS_X(a1), d2
    
    swap d1
    swap d2
    
    move.w #MISSILE_SPAWN_Y, d1
    move.w RETICLE_POS_Y(a1), d2
    
    move.l #$00FFFFFF, d0
    bsr drawLineColor
    
    movem.l (sp)+, .LOAD_REGS
    rts

***
*
* a1 - bitmap
*
***
input_Update
.LOAD_REGS REG d2-d4/a2
    movem.l .LOAD_REGS, -(sp)
    bsr input_EraseReticle
    
    sub.w #1, (FireCooldownZ) *decrease our countdown by 1
    sub.w #1, (FireCooldownX) *decrease our countdown by 1
    sub.w #1, (FireCooldownC) *decrease our countdown by 1
    
    move.l (Reticle), a1
    move.b #TASK_KEYDOWN, d0
    move.l #ARROW_KEYS, d1
    trap #15
    *get booleans for arrow keys down
    
    clr d2
    clr d3
    
.checkDown
    btst #0, d1
    beq .checkRight
    add.w #1, d3
.checkRight
    btst #8, d1
    beq .checkUp
    add.w #1, d2
.checkUp
    btst #16, d1
    beq .checkLeft
    sub.w #1, d3
.checkLeft
    btst #24, d1
    beq .moveReticle
    sub.w #1, d2
*check each of the return booleans, if they're pressed, increment or decrement our move directions

.moveReticle
    mulu #RETICLE_SPEED, d2
    mulu #RETICLE_SPEED, d3
    
    add.w d2, RETICLE_POS_X(a1)
    add.w d3, RETICLE_POS_Y(a1)
    
    bsr input_DrawReticle
   * bsr debug_DrawLine
    
    move.b #TASK_KEYDOWN, d0
    move.l #ZXC, d1
    trap #15
    
    move.l d1, d3
    
    btst #16, d3 *X silo
    beq .checkX
    tst.w (FireCooldownZ) *check our cooldown
    bgt .checkX *don't shoot if we just did
    move.w #FIRE_COOLDOWN, FireCooldownZ
    move.w #MISSILE_SPAWN_X_Z, d0
    bra .spawnMissile

.checkX
    btst #8, d3 *X silo
    beq .checkC
    tst.w (FireCooldownX) *check our cooldown
    bgt .checkC *don't shoot if we just did
    move.w #FIRE_COOLDOWN, FireCooldownX
    move.w #MISSILE_SPAWN_X_X, d0
    bra .spawnMissile
    
.checkC
    btst #0, d3 *C silo
    beq .done
    tst.w (FireCooldownC) *check our cooldown
    bgt .done *don't shoot if we just did
    move.w #FIRE_COOLDOWN, FireCooldownC
    move.w #MISSILE_SPAWN_X_C, d0
    
.spawnMissile
    lea Missile_Container, a2
    move.w #MISSILE_COUNT, d2
    
.updateLoop
    move.l (a2)+, d1
    tst.l d1
    bne .incrementLoop *opposite of update loop, looking for a 0

    clr.l d1
    clr.l d2
    clr.l d3
    
    move.w #MISSILE_SPAWN_Y, d1
    move.w RETICLE_POS_X(a1), d2
    move.w RETICLE_POS_Y(a1), d3
    move.w #PLAYER_MISSILE_SPEED, d4
    bsr missileB_Init *temp, need to shoot missile at this position
    
    move.l a0, -4(a2) *save the missile address 
    *we have to index by -4 here and in update because we move through it with post increment. 
    *the changes to the list happen less than moving through it, so I think design wise this is a good choice
    
    bsr audio_PlayShoot
    
    lea Missile_Container, a0 *we only call spawn from update, so reset it to what we want for update
    bra .done
.incrementLoop
    dbf d2, .updateLoop
    
.done
    movem.l (sp)+, .LOAD_REGS
    rts
    
***
*
* a6 - bitmap
*
***
input_EraseReticle
.LOAD_REG REG d2-d6/a2-a3
    *storing x and y in d3-d6 and plugging them into d1d2 for draw
    movem.l .LOAD_REG, -(sp)
    
    move.l a6, a2
    move.l (Reticle), a3 *load our reticle
    
    move.w RETICLE_POS_X(a3), d3
    move.w RETICLE_POS_Y(a3), d4
    *get the center of the reticle
    
    sub.w #RETICLE_GAP, d3
    add.w #RETICLE_GAP, d4
    *offset for the  gap in the middle
    
    move.w d3, d5
    move.w d4, d6
    *duplicate for the other corner
    
    add.w #RETICLE_WIDTH, d5
    add.w #RETICLE_LENGTH, d6
    *move to set up bottom bar
    
    move.w d3, d0
    move.w d5, d1
    
    add.w #1, d1
    *need padding of 1 in each direction to draw over reticle. unsure why
    
    swap d0
    swap d1
    
    move.w d4, d0
    move.w d6, d1
    
    add.w #1, d1
    
    move.l d0, d2
    move.l a2, a1
    bsr bmp_Draw
        
    sub.w #(2*(RETICLE_LENGTH+RETICLE_GAP)), d6
    sub.w #(2*RETICLE_GAP), d4
    move.w d3, d0
    move.w d5, d1
    
    add.w #1, d1
    *need padding of 1 in each direction to draw over reticle. unsure why
    
    swap d0
    swap d1
    
    move.w d4, d1
    move.w d6, d0
    
    add.w #1, d1
    
    move.l d0, d2
    move.l a2, a1
    bsr bmp_Draw
    *draw top bar
    
    move.w RETICLE_POS_X(a3), d3
    move.w RETICLE_POS_Y(a3), d4
    add.w #RETICLE_GAP, d3
    sub.w #RETICLE_GAP, d4
    move.w d3, d5
    move.w d4, d6
    *probably not necessary but for my mental I need to reset these before drawing the horizontal
    
    add.w #RETICLE_LENGTH, d5
    add.w #RETICLE_WIDTH, d6
    move.w d3, d0
    move.w d5, d1
    
    add.w #1, d1
    *need padding of 1 in each direction to draw over reticle. unsure why
    
    swap d0
    swap d1
    
    move.w d4, d0
    move.w d6, d1
    
    add.w #1, d1
    
    move.l d0, d2
    
    move.l a2, a1
    bsr bmp_Draw

    sub.w #(2*RETICLE_GAP), d3
    sub.w #(2*(RETICLE_LENGTH+RETICLE_GAP)), d5
    move.w d3, d1
    move.w d5, d0
    
    add.w #1, d1
    *need padding of 1 in each direction to draw over reticle. unsure why
    
    swap d0
    swap d1
    
    move.w d4, d0
    move.w d6, d1
    
    add.w #1, d1
    
    move.l d0, d2
    move.l a2, a1
    bsr bmp_Draw

    *same logic as the verty but flipped for horizontal
    movem.l (sp)+, .LOAD_REG
    rts
    
input_DrawReticle
.LOAD_REG REG d2-d4
    movem.l .LOAD_REG, -(sp)
    move.l #IN_BLUE, d1
    move.b #TASK_SET_PEN, d0 *set fill color for the reticle
    trap #15
    
    move.b #TASK_SET_FILL, d0
    trap #15 *we want the same color, so just trap again
    
    move.b #TASK_DRAW_RECT, d0
    *from now on we just need to draw rectangles
    
    move.l (Reticle), a0 *load our reticle
    
    move.w RETICLE_POS_X(a0), d1
    move.w RETICLE_POS_Y(a0), d2
    *get the center of the reticle
    
    sub.w #RETICLE_GAP, d1
    add.w #RETICLE_GAP, d2
    *offset for the  gap in the middle
    
    move.w d1, d3
    move.w d2, d4
    *duplicate for the other corner
    
    add.w #RETICLE_WIDTH, d3
    add.w #RETICLE_LENGTH, d4
    *move to set up bottom bar
    
    trap #15 *draw bottom bar
    
    sub.w #(2*(RETICLE_LENGTH+RETICLE_GAP)), d4
    sub.w #(2*RETICLE_GAP), d2
    trap #15
    *draw top bar
    
    move.w RETICLE_POS_X(a0), d1
    move.w RETICLE_POS_Y(a0), d2
    add.w #RETICLE_GAP, d1
    sub.w #RETICLE_GAP, d2
    move.w d1, d3
    move.w d2, d4
    *probably not necessary but for my mental I need to reset these before drawing the horizontal
    
    add.w #RETICLE_LENGTH, d3
    add.w #RETICLE_WIDTH, d4
    trap #15
    
    sub.w #(2*RETICLE_GAP), d1
    sub.w #(2*(RETICLE_LENGTH+RETICLE_GAP)), d3
    trap #15
    *same logic as the verty but flipped for horizontal
    movem.l (sp)+, .LOAD_REG
    rts
    
input_Clean:
    move.l (Reticle), a1
    bsr mem_Free
    move.l #0 ,(Reticle)
    rts

Reticle ds.l 1 *since it's just the one guy, safely store it in here
FireCooldownZ dcb.l 1,0
FireCooldownX dcb.l 1,0
FireCooldownC dcb.l 1,0
*thinking about it, I guess I could just store everything in their files









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

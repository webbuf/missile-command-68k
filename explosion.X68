EXPLOSION_X_POS    EQU 0
EXPLOSION_Y_POS    EQU 2
EXPLOSION_RADIUS   EQU 4
EXPLOSION_DISSOLVE EQU 6
EXPLOSION_SCORE    EQU 8
EXPLOSION_SIZE     EQU 10

EXPLOSION_INITIAL_RADIUS EQU 9
EXPLOSION_MAX_RADIUS     EQU 48
EXPLOSION_RADIUS_GROWTH  EQU 3
EXPLOSION_COUNT          EQU 3

EXPLOSION_ERASE_RADIUS   EQU 34
* sqrt( (radius^2)/2 ) /2
* drawing a box of this size is half of
* the area than if we erased it all at once
* have to then draw 4 boxes next frame to cover the rest 

COLOR_WHITE       EQU $00FFFFFF
TASK_SET_PEN      EQU 80
TASK_SET_FILL     EQU 81
TASK_DRAW_CIRCLE  EQU 88

***
*
* d1.w - initial x position
* d2.w - initial y position
*
* d0.b - 0 for success
*
***
explosion_Init:
.LOAD_REGS REG d2-d4/a2-a3
    movem.l .LOAD_REGS, -(sp)
    lea Explosion_Container, a2
    move.b #EXPLOSION_COUNT, d4
    move.w d1, d3 *store d1
.findLoop
    move.l (a2)+, d1
    tst.l d1
    beq .init
    dbf d4, .findLoop
**didn't find case
    move.b #1, d0
    rts
.init    
    move.l #EXPLOSION_SIZE, d1
    bsr mem_Alloc
    move.l a0, -4(a2) *we postincremented a1 so we gotta turn it back
    move.w d3, EXPLOSION_X_POS(a0)
    move.w d2, EXPLOSION_Y_POS(a0)
    move.w #EXPLOSION_INITIAL_RADIUS, EXPLOSION_RADIUS(a0)
    move.w #$0000, EXPLOSION_DISSOLVE(a0) *set bool to false
    move.w #$0000, EXPLOSION_SCORE(a0) *initial score from explosions is 0
    bsr audio_PlayExplode
    *set position and initial radius
    movem.l (sp)+, .LOAD_REGS
    rts


explosion_Update:
.LOAD_REGS REG d2-d7/a2-a5
    movem.l .LOAD_REGS, -(sp)
    
    lea Explosion_Container, a2
    move.l #EXPLOSION_COUNT, d6
.findLoop
    move.l (a2)+, d1
    tst.l d1
    bne .update
.increment
    dbf d6, .findLoop
    movem.l (sp)+, .LOAD_REGS
    rts
    
.update
    move.l d1, a3
    
    btst #0, EXPLOSION_DISSOLVE(a3)
    bne .killExplosion *check if we need to wipe from memory/finish erase
    *we do this first since here we'll ALSO have our radius be too big
    
    move.w EXPLOSION_RADIUS(a3), d5
    cmp.w #EXPLOSION_MAX_RADIUS, d5
    bge .startWipe  *check if we're too big

    add.w #EXPLOSION_RADIUS_GROWTH, d5
    move.w d5, EXPLOSION_RADIUS(a3)
    *increment radius
    
    move.l #COLOR_WHITE, d1
    move.b #TASK_SET_PEN, d0
    trap #15 
    
    move.l #COLOR_WHITE, d1
    move.b #TASK_SET_FILL, d0
    trap #15 
    *set color now in case another explosion is getting erased
    
    move.w EXPLOSION_X_POS(a3), d1
    move.w EXPLOSION_Y_POS(a3), d2
    
    move.w d1, d3 *need two corners for draw, so duplicate our x and y
    move.w d2, d4
    
    sub.w d5, d1
    sub.w d5, d2 
    add.w d5, d3
    add.w d5, d4
    *go from center to top left and bottom right of square that encircles the explosion
    
    move.b #TASK_DRAW_CIRCLE, d0
    trap #15
    
    
    move.l #MISSILE_COUNT, d7
    move.w EXPLOSION_X_POS(a3), d4
    move.w EXPLOSION_Y_POS(a3), d5
    move.w EXPLOSION_RADIUS(a3), d3
    muls.w d3, d3 *distance^2 as our target distance means distance formula doesn't need to care about sqrt
    lea Missile_Container, a1
    
.checkMissiles *don't touch d6 or a2-3 in here **COLLISION**
    move.l (a1)+, d1
    tst.l d1
    beq .MLoopIncrement *0, so no missile here
    move.l d1, a4
    
    clr.l d0
    move.w M_CURRENT_X(a4), d0
    sub.w d4, d0
    muls d0, d0 *(x0 - x1)^2
    
    clr.l d1
    move.w M_CURRENT_Y(a4), d1
    sub.w d5, d1
    muls d1, d1 *(y0-y1)^2
    
    add.l d0, d1 *add
    cmp.l d1, d3   *if the distance (squared) is less than the radius (sqaured), missile should get exploded
    ble .MLoopIncrement
    
    *if here, missile needs to get exploded
    clr.l d1
    add.w #1, EXPLOSION_SCORE(a3) *increment the score per missile contained by 1
    move.w EXPLOSION_SCORE(a3), d1 *add to score. This way, shooting down 2 missiles with 1 gets you 3 points, not 2
    bsr score_Increment
    move.l #$00000000, -4(a1) *wipe missile out of containter
    
    move.l a1, a5 *preserve missile container adress
    move.l a4, a1 *put missile address in a1 for erase and free
    bsr missileB_Erase *erase missile
    bsr mem_Free *free missile memory
    move.l a5, a1 *restore container
    
.MLoopIncrement
    dbf d7, .checkMissiles
    
    move.l #BOMB_COUNT, d7
    move.w EXPLOSION_X_POS(a3), d4
    move.w EXPLOSION_Y_POS(a3), d5
    move.w EXPLOSION_RADIUS(a3), d3
    add.w #BOMB_RADIUS, d3
    muls.w d3, d3 *distance^2 as our target distance means distance formula doesn't need to care about sqrt
    lea BombContainer, a1
    
.checkBombs *don't touch d6 or a2-3 in here **COLLISION**
    move.l (a1)+, d1
    tst.l d1
    beq .BLoopIncrement *0, so no missile here
    move.l d1, a4
    
    clr.l d0
    move.w BOMB_POS_X(a4), d0
    lsr #5, d0
    add.w #1, d0
    lsr #1, d0 *defixedpointify
    sub.w d4, d0
    
    muls d0, d0 *(x0 - x1)^2
    
    clr.l d1
    move.w BOMB_POS_Y(a4), d1
    lsr #5, d1
    add.w #1, d1
    lsr #1, d1 
    sub.w d5, d1
    muls d1, d1 *(y0-y1)^2
    
    add.l d0, d1 *add
    cmp.l d1, d3   *if the distance (squared) is less than the radius (sqaured), missile should get exploded
    ble .BLoopIncrement
    
    *if here, missile needs to get exploded
    clr.l d1
    add.w #1, EXPLOSION_SCORE(a3)
    move.w EXPLOSION_SCORE(a3), d1 
    add.w #1, d1 *bombs give 2 points, but we don't want to increment the bonus by 2
    bsr score_Increment
    move.l #$00000000, -4(a1) *wipe bomb out of containter
    
    move.l a1, a5 *preserve missile container adress
    move.l a4, a1 *put missile address in a1 for erase and free
    bsr eraseBomb *erase bomb - this is supposed to be private but oh well
    bsr mem_Free *free bomb memory
    move.l a5, a1 *restore container
    
.BLoopIncrement
    dbf d7, .checkBombs

    
    lea CityLocations, a1 *load city container
    move.w (CityMask), d2
    move.w #CITY_LOOP_COUNTER, d3 *prepare checks for loop
    clr.l d7 
    move.w EXPLOSION_RADIUS(a3), d7
    add.w #CITY_RADIUS, d7
    mulu d7, d7   *distance from center of city to center of explosion (squared)
    
    move.w #CITY_Y, d1
    sub.w d5, d1
    muls d1, d1 (y0 - y1)^2 *this is consistent across all cities since they share a y
    
.cityLoop **COLLISION**
    btst d3, d2
    beq .cLoopIncrement *if the bit for this city is turned off, it's dead. move on
    
    lsl #1, d3
    clr.l d0 *after multiplying this is a LW so we gotta clear it
    move.w (a1, d3), d0 
    lsr #1, d3 *shift over to work as a word index, get the value, shift back
    
    sub.w d4, d0
    muls d0, d0 * (x0 - x1)^2
    
    add.l d1, d0 *add to d0 to preserve d1
    
    cmp.l d0, d7 *compare distance to the collide distance
    ble .cLoopIncrement *if it's less no collision, check the next one
    
    *if here, we're colliding
    *don't need d0 anymore
    
    clr.l d0
    move.w #1, d0
    lsl d3, d0 *shift over by loop counter
    
    eor.w #$000F, d0 *this will turn off the one bit we shifted over, leave rest of the lower bits 1
    *the rest of the upper bits 0
    
    and.w d0, d2 *and the mask with the one we just made to turn this city off
    move.w d2, (CityMask) *store the mask
    
.cLoopIncrement
    dbf d3, .cityLoop
    
    bra .increment
    
    
.startWipe **BITMAP**
    move.w #$FFFF, EXPLOSION_DISSOLVE(a3) *mark this as needing to be erased
    
    move.w EXPLOSION_X_POS(a3), d0
    move.w d0, d1
    
    sub.w #EXPLOSION_ERASE_RADIUS, d0
    add.w #EXPLOSION_ERASE_RADIUS, d1 *load x, move by erase radius
    
    swap d0
    swap d1 *swap to get y
    
    move.w EXPLOSION_Y_POS(a3), d0
    move.w d0, d1
    
    sub.w #EXPLOSION_ERASE_RADIUS, d0
    add.w #EXPLOSION_ERASE_RADIUS, d1 *load y, move by erase radius
    
    move.l d0, d2 *position to draw
    
    move.l a6, a1 *load bitmap
    
    bsr bmp_Draw *erase middle of explosion
    bra .increment
    
.killExplosion **BITMAP**
    *here we erase the 4 rectangles extruded from the sides of the dissolve square
    move.l #$00000000, -4(a2) *remove explosion from list
    
    move.w EXPLOSION_X_POS(a3), d0
    move.w d0, d1
    move.w d0, d4 *store inital x so we don't have to keep going to mem to get it
    
    sub.w #EXPLOSION_ERASE_RADIUS, d0
    add.w #EXPLOSION_ERASE_RADIUS, d1
    
    swap d0
    swap d1 *x of first rectangle to erase
    
    move.w EXPLOSION_Y_POS(a3), d0
    move.w d0, d1 *get initial y
    move.w d0, d5 *storing y too
    
    sub.w #EXPLOSION_MAX_RADIUS, d0
    sub.w #EXPLOSION_ERASE_RADIUS, d1
    
    move.l d0, d2 *top left = place to pull pixels from
    move.l d1, d3 *bottom right of this rectangle is top left of the next, so keep it
    move.l a6, a1
    bsr bmp_Draw
    
    move.l d3, d0
    move.l d0, d2 *get top left from bottom right of last

    move.w d4, d1
    add.w #EXPLOSION_MAX_RADIUS+1, d1 *juuust doesn't fit. idk why. add one to fix
    
    swap d1
    
    move.w d5, d1
    add.w #EXPLOSION_ERASE_RADIUS, d1
    
    move.l a6, a1
    bsr bmp_Draw
    
    move.w d4, d0 *no shared here. have to start over
    move.w d4, d1
    
    sub.w #EXPLOSION_MAX_RADIUS, d0     
    sub.w #EXPLOSION_ERASE_RADIUS, d1
    
    swap d0
    swap d1
    
    move.w d5, d0
    move.w d5, d1
    
    sub.w #EXPLOSION_ERASE_RADIUS, d0
    add.w #EXPLOSION_ERASE_RADIUS, d1
    
    move.l d0, d2
    move.l d1, d3 *save bottom right again
    move.l a6, a1
    bsr bmp_Draw *just kinda gotta write this all out unfortunately
    
    move.l d3, d0
    move.l d0, d2 *restore bottom right to top left
    
    move.w d4, d1
    add.w #EXPLOSION_ERASE_RADIUS+1, d1 *similar bump to this one. idk
    swap d1
    
    move.w d5, d1
    add.w #EXPLOSION_MAX_RADIUS+1, d1
    
    move.l a6, a1
    bsr bmp_Draw
    
    move.l a3, a1
    bsr mem_Free *free memory from the explosion
    
    bra .increment
    
explosion_Clean:
    lea Explosion_Container, a2
    move.w #EXPLOSION_COUNT, d3
.cleanLoop
    move.l (a2)+, d1
    tst d1
    beq .increment
    move.l d1, a1
    bsr mem_Free
    move.l #0, -4(a2)
.increment
    dbf d3, .cleanLoop
    
    rts
    
Explosion_Container dcb.l 4,0











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

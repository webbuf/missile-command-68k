*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
    
    include "file.x68"
    include "memory.x68"
    include "bitmap.x68"
    include "line_renderer.x68"
    include "random.x68"
    include "missile_bresenham.x68"
    include "player_input.x68"
    include "explosion.x68"
    include "score.x68"

MISSILE_COUNT      EQU 7
MISSILE_DELAY      EQU 20
DELAY_FUZZ         EQU 5  
HEAP_SIZE          EQU 3000000

FRAME_DELAY_TIME        EQU     5

CLEAR_SCREEN_COMMAND    equ     11
CLEAR_SCREEN_MAGIC_VAL  equ     $FF00
DRAWING_MODE_TRAP_CODE	equ	92
DOUBLE_BUFFERED_MODE	equ	17
DELAY_FRAME	        equ	23
REPAINT_SCREEN_TRAP_CODE	equ	94

    
START:                  ; first instruction of program

    move.l #HEAP_SIZE, d1
    lea Heap, a1
    bsr mem_InitHeap
    
    lea BG_Filename, a0
    bsr bmp_Load
    move.l a1, (BG_Address) *save the location of the background off so we can keep it
    move.l (BG_Address), a6 *permanently store it here
    
    move.l #$00000000, d0
    move.l #$FFFFFFFF, d1
    move.l #$00000000, d2

    *bsr bmp_Draw

    bsr input_Init *turn on input

    move.b #M_COLOR_TASK, d0
    move.l #M_RED, d1
    trap #15
    
    move.w #320, d1
    move.w #240, d2
    move.b #M_PIXEL_TASK, d0
    trap #15

    move.w #640, d0
    move.w #480, d1
    move.w #320, d2
    move.w #240, d3
    bsr missileB_Init
    
    move.l a0, a1
    
.missileLoop
    bsr clearScreen
    bsr updateMissiles
    bsr input_Update
    bsr delayFrame
    bra .missileLoop
    
* Put program code here

    SIMHALT             ; halt simulator
    
updateMissiles:
    lea Missile_Container, a2 *get the missile entity list
    clr.l d0
    move.b (Missile_Timer), d0
    sub.b #1, d0
    move.b d0, (Missile_Timer)
    *load our missile timer, check if it's ticked down to 0, and save it off for next frame
    *feels like this is redundant but it's probably fine. it happens once per frame
    tst d0
    bne .dontSpawn
   * bsr spawnMissile
.dontSpawn
    move.w #MISSILE_COUNT, d2
    
.updateLoop
    move.l (a2)+, d1 *load the possible address in
    tst.l d1 *check if the address is 0 or real data. using tst is why we have to load it into a data register and not an address
    beq .incrementLoop *if it is 0, go to the next thing
    move.l d1, a1 *load into what missile update wants. (TODO: make this align by default? saves no cycles, but clean code is good too)
    bsr missileB_Update
    tst.b d0 *check missile return value to see if it died
    beq .incrementLoop
    move.l -4(a2), a1
    bsr mem_Free *free the memory of the missile
    move.l #$00000000, -4(a2) *wipe out missile address if we delete it
    
.incrementLoop
    dbf d2, .updateLoop *dbf <3 could use a sentinel value instead of a loop counter, but for game flow logic registers are surprsingly free
    rts
    
spawnMissile:
.SPAWN_REGS REG d0-d4
    move.l #MISSILE_DELAY-DELAY_FUZZ, d1
    move.l #MISSILE_DELAY+DELAY_FUZZ, d0
    bsr rand_getVal
    move.b d0, (Missile_Timer) *reset spawn timer
    move.l a2, a3 *preserve this for the update loop
    move.w #MISSILE_COUNT, d2
    
.updateLoop
    move.l (a3)+, d1
    tst.l d1
    bne .incrementLoop *opposite of update loop, looking for a 0
    movem.l .SPAWN_REGS, -(sp) *keep d0-d4 for this. gotta do it outside cause shooting is gonna do this too
    
    *this is where i'll target a specific city
    
    move.w #541, d0
    move.w #100, d1
    bsr rand_getVal
    
    move.w d0, d2 *keep that value. endpoint, don't want to be on edges
    
    move.w #641, d0
    move.w #0, d1
    bsr rand_getVal *we want this in d0 anyway, so just chill
    
    move.w #0, d1 *spawn at top of screen
    move.w #400, d3 *go to bottom
    
    bsr missileB_Init
    movem.l (sp)+, .SPAWN_REGS
    move.l a0, -4(a3) *save the missile address 
    *we have to index by -4 here and in update because we move through it with post increment. 
    *the changes to the list happen less than moving through it, so I think design wise this is a good choice
    
    lea Missile_Container, a0 *we only call spawn from update, so reset it to what we want for update
    rts
.incrementLoop
    dbf d2, .updateLoop
    rts

    
delayFrame
        move.l  #DELAY_FRAME, d0
        move.l  #FRAME_DELAY_TIME, d1
        TRAP    #15
        rts
        
clearScreen
        move.b  #CLEAR_SCREEN_COMMAND,d0
       	move.l  #CLEAR_SCREEN_MAGIC_VAL,d1
       	TRAP    #15
	    rts

* Put variables and constants here
BG_Filename        dc.b 'testbg2.bmp',0 
BG_Address         ds.l 1  *one LW to store the address the bg gets loaded to
Missile_Container  dcb.l 8,0
Missile_Timer      dc.b 1

    dc.w 0
Heap

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

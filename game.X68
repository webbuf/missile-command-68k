*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
    
    include "file.x68"
    include "memory.x68"
    include "bitmap.x68"   **BITMAP**
    include "line_renderer.x68"
    include "random.x68"    **RANDOM**
    include "missile_bresenham.x68"
    include "player_input.x68"   **INPUT**
    include "explosion.x68"      **COLLISION**
    include "score.x68"          **7SEG**
    include "city.x68"
    include "plane.x68"
    include "bomb.x68"   **PHYSICS**
    include "audio.x68"
    include "logo.x68"

DRAWING_MODE_TRAP_CODE	    EQU	92
DOUBLE_BUFFERED_MODE	    EQU	17
DELAY_FRAME	                EQU	23
REPAINT_SCREEN_TRAP_CODE	EQU	94  
FRAME_DELAY_TIME            EQU 5
GET_TIME                    EQU 8
TERMINATE                   EQU 9

CLEAR_SCREEN_COMMAND    equ     11
CLEAR_SCREEN_MAGIC_VAL  equ     $FF00

MISSILE_COUNT       EQU 11
MISSILE_INIT_DELAY  EQU 55
MISSILE_SPEED       EQU 1
DELAY_FUZZ          EQU 8
MIN_DELAY           EQU 25

HEAP_SIZE           EQU 3500000

LOAD_POS           EQU $0000019F
GAME_OVER_POS      EQU $00BD00BD
R_ESC              EQU $00001B52
TASK_GET_KEY       EQU 19

PLANE_SPAWN_CHANCE EQU 130
    
    
START:        
OnceInit: *probably never need to call this, but it'll be nice for organizational purposes
    
    *set double buffered mode                   
    move.b	#DRAWING_MODE_TRAP_CODE,d0          
    move.b	#DOUBLE_BUFFERED_MODE,d1
    trap	#15

    move.l #HEAP_SIZE, d1
    lea Heap, a1
    bsr mem_InitHeap
    *load heap
    
    bsr logo_Draw
    
    bsr audio_Init
    
    bsr audio_PlayJingle
    
    lea BG_Filename, a0
    bsr bmp_Load
    move.l a1, (BG_Address) *save the location of the background off so we can keep it
    move.l (BG_Address), a6 *permanently store it here
    
    lea GO_Filename, a0
    bsr bmp_Load
    move.l a1, (GO_Address)
    
    lea Load_Filename, a0
    bsr bmp_Load
    move.l a1, (Load_Address)

Init:
    move.l (Load_Address), a1
    move.l #$00000000, d0
    move.l #$FFFFFFFF, d1
    move.l #LOAD_POS, d2
    bsr bmp_Draw
    bsr swapBuffers

    move.l (BG_Address), a1
    move.l #$00000000, d0
    move.l #$FFFFFFFF, d1
    move.l #$00000000, d2

    bsr bmp_Draw
    bsr swapBuffers *load the full bg
    
    bsr rand_Init *turn on our rng
    
    bsr input_Init *turn on input
    
    bsr score_Init *you're not gonna believe what this does
        
    bsr city_Init  *spawn cities
    *these inits go after the bg is drawn because they draw things too
    
    move.b #1, (Missile_Timer)
    
    move.b #MISSILE_INIT_DELAY, (Missile_Base_Delay)
    
    move.b #GET_TIME, d0
    trap #15
    move.l d1, d7
    *get the time since midnight, store it in d7
    
GameLoop:
    bsr city_Draw *draw before explosions so they can get exploded
    bsr explosion_Update
    bsr updateMissiles
    bsr spawnPlane
    bsr plane_Update
    bsr bomb_Update
    bsr score_Draw
    bsr input_Update *draw last so we can always see it

    bsr delayFrame
    bsr swapBuffers
    
    move.w (CityMask), d2
    tst.w d2
    bne GameLoop *at some point i'll probably have some logic instead of a while true loop

    move.l #$00000000, d0
    move.l #$FFFFFFFF, d1 *draw whole image
    move.l #GAME_OVER_POS, d2
    move.l (GO_Address), a1
    bsr bmp_Draw
    
    bsr swapBuffers
   
    bsr audio_PlayGameOver
   
    bsr explosion_Clean
    bsr input_Clean
    bsr plane_Clean
    bsr bomb_Clean
    bsr CleanMissiles
    
    move.b #TASK_GET_KEY, d0
    
.GameOverLoop
    move.l #R_ESC, d1
    trap #15
    btst #0, d1
    beq .CheckQuit
    bra Init
.CheckQuit
    btst #8, d1
    beq .GameOverLoop
    
    move.l (BG_Address), a1
    bsr bmp_Unload
    
    move.l (GO_Address), a1
    bsr bmp_Unload
    
    move.l (Load_Address), a1
    bsr bmp_Unload
  
    move.b  #CLEAR_SCREEN_COMMAND,d0
    move.l  #CLEAR_SCREEN_MAGIC_VAL,d1
    trap    #15
    
    bsr swapBuffers
  
    move.b #TERMINATE, d0
    trap #15
    

  
    SIMHALT

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
    bsr spawnMissile
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
.SPAWN_REGS REG d0-d5
    clr.l d0
    clr.l d1
    
    move.b (Missile_Base_Delay), d0
    cmp.b #MIN_DELAY, d0
    blt .dontDecrease
    sub.b #1, d0
    move.b d0, (Missile_Base_Delay) *the base delay decreases by 1 each missile, but it's capped at 20
.dontDecrease
    move.b d0, d1
    sub.l #DELAY_FUZZ, d1
    add.l #DELAY_FUZZ, d0
    bsr rand_getVal **RANDOM**
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
    
    move.w #MISSILE_SPEED, d4
    
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

CleanMissiles:
    lea Missile_Container, a2
    move.w #MISSILE_COUNT, d3
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

spawnPlane:
    move.w #PLANE_SPAWN_CHANCE, d0
    move.w #0, d1
    bsr rand_getVal
    tst.w d0
    bne .done
    bsr plane_Init
.done
    rts 

swapBuffers
	move.b  #REPAINT_SCREEN_TRAP_CODE,d0
    TRAP    #15
	rts      
	
delayFrame
    move.b #GET_TIME, d0
    trap #15
    
    move.l d1, d6 *get the time since last frame
    move.l d7, d5 *store the time of last frame elsewhere to modify
    add.l #FRAME_DELAY_TIME, d5 *last frame + 5
    cmp.w d6, d5
    blt .dontWait *if it's already been more than we want to wait, don't wait
    *(last frame + 5) - new frame = time to wait
    
    move.l d5, d7 *save last + 5 as new frame time
    sub.l d6, d5 *subtract new frame time, leftover is time to wait
    move.l  #DELAY_FRAME, d0
    move.l  d5, d1
    TRAP    #15
    rts *don't go into old wait
.dontWait
    move.l d6, d7 *save new frame time, which in this case is whatever we got
    rts
    
*graciously looted from ball demo

BG_Filename         dc.b 'finalbg.bmp',0 
GO_Filename         dc.b 'gameOver.bmp',0
Load_Filename       dc.b 'load.bmp',0
BG_Address          ds.l 1  *one LW to store the address the bg gets loaded to
GO_Address          ds.l 1
Load_Address        ds.l 1
Missile_Timer       dc.b 1
Missile_Container   dcb.l 12,0
Missile_Base_Delay  dc.b 1

        dc.w 0
Heap
        dc.w 0
    END    START        ; last line of source























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

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
        
CLEAR_SCREEN_COMMAND    equ     11
CLEAR_SCREEN_MAGIC_VAL  equ     $FF00
DRAWING_MODE_TRAP_CODE	equ	92
DOUBLE_BUFFERED_MODE	equ	17
DELAY_FRAME	        equ	23
REPAINT_SCREEN_TRAP_CODE	equ	94  
FRAME_DELAY_TIME        EQU     1
    
START:                  ; first instruction of program

* Put program code here

    *STARTING Y (ALWAYS) : $20
    *ENDING Y (ALWAYS) :   $1C8
    *STARTING X (ALWAYS) : F0
    *END X goes from $F0 to $298
    
    lea Heap, a1
    move.l #3000000, d1
    bsr mem_InitHeap
    
    lea TestFilename, a0
    bsr bmp_Load
    
    move.l a1, a2
  
    move.l #$00000000, d0
    move.l #$FFFFFFFF, d1
    move.l #$00000000, d2
    bsr bmp_draw
    
    move.w #$1CC, d3
    move.w #$00, d4
    
    move.l #80, d0
    move.l #$00FFFF00, d1
    trap #15
    
   * move.b	#DRAWING_MODE_TRAP_CODE,d0          
   * move.b	#DOUBLE_BUFFERED_MODE,d1
   * trap	#15
    
.testLoop
    move.l #80, d0
    move.l #$00FFFF00, d1
    trap #15

    add.w #1, d4
    move.l #84, d0
    move.w #$0020, d1
    move.w #$00F0, d2

    trap #15
    *jsr swapBuffers
        
    move.l #$000000FF, d0
    move.l #$002000F0, d1
    clr.l d2
    move.w d4, d2
    swap d2
    or.l d3, d2
    swap d2    
    
    move.l a2, a1
    bsr drawLineBMP
   * jsr swapBuffers
    jsr delayFrame
    bra .testLoop
    
    SIMHALT             ; halt simulator

clearScreen
        move.b  #CLEAR_SCREEN_COMMAND,d0
       	move.l  #CLEAR_SCREEN_MAGIC_VAL,d1
       	TRAP    #15
	rts
	
swapBuffers
	move.b  #REPAINT_SCREEN_TRAP_CODE,d0
      	TRAP    #15
	rts      
	
delayFrame
        move.l  #DELAY_FRAME, d0
        move.l  #FRAME_DELAY_TIME, d1
       * TRAP    #15
        rts


* Put variables and constants here

TestFilename dc.b 'testbg.bmp',0
            dc.w 0
Heap

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

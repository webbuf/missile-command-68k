*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
    include "memory.x68"
    include "file.x68"
    include "bitmap.x68"
    include "line_renderer.x68"
    include "score.x68"
    
DRAWING_MODE_TRAP_CODE	    EQU	92
DOUBLE_BUFFERED_MODE	    EQU	17
DELAY_FRAME	                EQU	23
REPAINT_SCREEN_TRAP_CODE	EQU	94  
FRAME_DELAY_TIME            EQU 5
GET_TIME                    EQU 8
HEAP_SIZE          EQU 3000000
    
START:                  ; first instruction of program
    move.l #HEAP_SIZE, d1
    lea Heap, a1
    bsr mem_InitHeap
    *load heap
    
    lea BG_Filename, a0
    bsr bmp_Load
    move.l a1, (BG_Address) *save the location of the background off so we can keep it
    move.l (BG_Address), a6 *permanently store it here
    
    move.l #$00000000, d0
    move.l #$FFFFFFFF, d1
    move.l #$00000000, d2

    bsr bmp_Draw
    
    bsr score_Init
    
.increment
    bsr score_Increment
    bra .increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    bsr score_Increment
    
    SIMHALT             ; halt simulator

* Put variables and constants here
BG_Filename        dc.b 'testbg2.bmp',0 
BG_Address         ds.l 1  *one LW to store the address the bg gets loaded to

    dc.w 0
Heap
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

**7SEG** *whole file*
SCORE_SEG_LENGTH EQU 24
SCORE_SEG_HEIGHT EQU 18
SCORE_SEG_GAP    EQU 4
SCORE_DIG_GAP    EQU 1

SCORE_HUNDREDS_START  EQU 273
SCORE_TENS_START      EQU 307
SCORE_ONES_START      EQU 341
SCORE_HEIGHT          EQU 420

SCORE_MAX        EQU 999

TASK_DRAW_LINE   EQU 84
TASK_SET_PEN     EQU 80
COLOR_WHITE      EQU $00FFFFFF

A_SEG EQU 1
B_SEG EQU 2
C_SEG EQU 4
D_SEG EQU 8
E_SEG EQU 16
F_SEG EQU 32
G_SEG EQU 64

SegmentArray:
SCORE_ZERO  dc.b A_SEG|B_SEG|C_SEG|D_SEG|E_SEG|F_SEG
SCORE_ONE   dc.b B_SEG|C_SEG
SCORE_TWO   dc.b A_SEG|B_SEG|D_SEG|E_SEG|G_SEG
SCORE_THREE dc.b A_SEG|B_SEG|C_SEG|D_SEG|G_SEG
SCORE_FOUR  dc.b B_SEG|C_SEG|F_SEG|G_SEG
SCORE_FIVE  dc.b A_SEG|C_SEG|D_SEG|F_SEG|G_SEG
SCORE_SIX   dc.b A_SEG|C_SEG|D_SEG|E_SEG|F_SEG|G_SEG
SCORE_SEVEN dc.b A_SEG|B_SEG|C_SEG
SCORE_EIGHT dc.b A_SEG|B_SEG|C_SEG|D_SEG|E_SEG|F_SEG|G_SEG
SCORE_NINE  dc.b A_SEG|B_SEG|C_SEG|D_SEG|F_SEG|G_SEG

DrawSegments
    dc.l drawA
    dc.l drawB
    dc.l drawC
    dc.l drawD
    dc.l drawE
    dc.l drawF
    dc.l drawG
    
EraseSegments
    dc.l eraseA
    dc.l eraseB
    dc.l eraseC
    dc.l eraseD
    dc.l eraseE
    dc.l eraseF
    dc.l eraseG

*** FOR ALL DRAWS 
*
* d1 - x offset
* d2 - y offset
*
*** 
*Offsets are from where the number starts, not the segment
*I know these are weird but these are helper functions for a larger thing
*color will also be set elsewhere
    
drawA:
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d3
    add.w #SCORE_SEG_LENGTH, d3 *a goes from offset to offset + length in x
    
    move.w d2, d4 *y is just on the offset
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    rts

drawB:
    add.w #(2*SCORE_DIG_GAP+SCORE_SEG_LENGTH), d1
    move.w d1, d3 *x is fixed on offset + 2 * gap + length
    
    add.w #SCORE_DIG_GAP, d2
    move.w d2, d4 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d4
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    rts
    
drawC:
    add.w #(2*SCORE_DIG_GAP+SCORE_SEG_LENGTH), d1
    move.w d1, d3 *x is fixed on offset + 2 * gap + length
    
    add.w #(3*SCORE_DIG_GAP+SCORE_SEG_HEIGHT), d2
    move.w d2, d4 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d4
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    rts
    
drawD:
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d3
    add.w #SCORE_SEG_LENGTH, d3 *a goes from offset to offset + length in x
    
    add.w #(4*SCORE_DIG_GAP+2*SCORE_SEG_HEIGHT), d2
    move.w d2, d4 *y is just on the offset
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    rts

    
drawE:
    move.w d1, d3 *x is just offset here
    
    add.w #(3*SCORE_DIG_GAP+SCORE_SEG_HEIGHT), d2
    move.w d2, d4 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d4
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    rts
    
drawF:
    move.w d1, d3 *x is fixed on offset
    
    add.w #SCORE_DIG_GAP, d2
    move.w d2, d4 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d4
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    rts
    
drawG:
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d3
    add.w #SCORE_SEG_LENGTH, d3 *a goes from offset to offset + length in x
    
    add.w #(2*SCORE_DIG_GAP+SCORE_SEG_HEIGHT), d2
    move.w d2, d4 *y is just on the offset
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    rts

eraseA:
    swap d2
    
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d2
    add.w #SCORE_SEG_LENGTH, d2 *a goes from offset to offset + length in x
    
    swap d1
    swap d2
    
    move.w d2, d1 *y is just on the offset
    
    bsr drawLineBMP
    rts

eraseB:
    swap d2
    
    add.w #(2*SCORE_DIG_GAP+SCORE_SEG_LENGTH), d1
    move.w d1, d2 *x is fixed on offset + 2 * gap + length
    
    swap d1
    swap d2
    move.w d2, d1
    
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d2 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d2
    
    bsr drawLineBMP
    rts
    
eraseC:
    swap d2
    
    add.w #(2*SCORE_DIG_GAP+SCORE_SEG_LENGTH), d1
    move.w d1, d2 *x is fixed on offset + 2 * gap + length
    
    swap d1
    swap d2
    move.w d2, d1
    
    add.w #(3*SCORE_DIG_GAP+SCORE_SEG_HEIGHT), d1
    move.w d1, d2 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d2
    
    bsr drawLineBMP
    rts
    
eraseD:
    swap d2
    
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d2
    add.w #SCORE_SEG_LENGTH, d2 *a goes from offset to offset + length in x
    
    swap d1
    swap d2
    move.w d2, d1
    
    add.w #(4*SCORE_DIG_GAP+2*SCORE_SEG_HEIGHT), d1
    move.w d1, d2 *y is just on the offset
    
    bsr drawLineBMP
    rts
    
eraseE:
    swap d2
    
    move.w d1, d2 *x is just offset here
    
    swap d1
    swap d2
    move.w d2, d1
    
    add.w #(3*SCORE_DIG_GAP+SCORE_SEG_HEIGHT), d1
    move.w d1, d2 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d2

    bsr drawLineBMP
    rts
    
eraseF:
    swap d2
    
    move.w d1, d2 *x is fixed on offset
    
    swap d1
    swap d2
    move.w d2, d1
    
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d2 *y is just on the offset
    add.w #SCORE_SEG_HEIGHT, d2
    
    bsr drawLineBMP
    rts
    
eraseG:
    swap d2
    
    add.w #SCORE_DIG_GAP, d1
    move.w d1, d2
    add.w #SCORE_SEG_LENGTH, d2 *a goes from offset to offset + length in x
    
    swap d1
    swap d2
    move.w d2, d1
    
    add.w #(2*SCORE_DIG_GAP+SCORE_SEG_HEIGHT), d1
    move.w d1, d2 *y is just on the offset
    
    bsr drawLineBMP
    rts


***
*
* d0.b - digit to draw
* d1.w - x offset
* d2.w - y offset
*
***

drawDigit:
.LOAD_REGS REG d2-d7/a2
.DIG_REGS  REG d1-d4

    movem.l .LOAD_REGS, -(sp)
    lea SegmentArray, a1
    lea DrawSegments, a2
    add.l d0, a1 *offset to which digit we want in the segment array
    move.b (a1), d3 *get the bitmask for that segment
    move.w d1, d4 *save d1 for before trap trasl

    move.l #COLOR_WHITE, d1
    move.b #TASK_SET_PEN, d0
    trap #15 *set the color for the score
    
    move.w d4, d1
    move.w #6, d4 *since there are seven segments, to loop through them with dbf we start at 6
    
.digitLoop
    btst d4, d3
    beq .increment
    movem.l .DIG_REGS, -(sp) *have to preserve d1 and d2 for next segment
    move.w d4, d5
    mulu #4, d5 *convert d4 to byte offset
    move.l (a2, d5), a3
    jsr (a3)
    movem.l (sp)+, .DIG_REGS
    
.increment
    dbf d4, .digitLoop
    
    movem.l (sp)+, .LOAD_REGS
    rts
    
***
*
* d0.b - digit to draw
* d1.w - x offset
* d2.w - y offset
*
***
eraseDigit:
.LOAD_REGS REG d2-d7/a2
.DIG_REGS  REG d1-d4/a1

    movem.l .LOAD_REGS, -(sp)
    lea SegmentArray, a1
    lea EraseSegments, a2
    add.l d0, a1 *offset to which digit we want in the segment array
    move.b (a1), d3 *get the bitmask for that segment
    move.w d1, d4 *save d1 for before trap trasl
    
    move.w d4, d1
    move.w #6, d4 *since there are seven segments, to loop through them with dbf we start at 6
    
.digitLoop
    btst d4, d3
    beq .increment
    movem.l .DIG_REGS, -(sp) *have to preserve d1 and d2 for next segment
    move.l (BG_Address), a1
    move.w d4, d5
    mulu #4, d5 *convert d4 to byte offset
    move.l (a2, d5), a3
    jsr (a3)
    movem.l (sp)+, .DIG_REGS
    
.increment
    dbf d4, .digitLoop
    
    movem.l (sp)+, .LOAD_REGS
    rts

score_Init:
    move.w #SCORE_HEIGHT, d2
    move.w #SCORE_HUNDREDS_START, d1
    move.w #0, d0
    bsr drawDigit
    
    move.w #SCORE_HEIGHT, d2
    move.w #SCORE_TENS_START, d1
    move.w #0, d0
    bsr drawDigit
    
    move.w #SCORE_HEIGHT, d2
    move.w #SCORE_ONES_START, d1
    move.w #0, d0
    bsr drawDigit
    
    move.w #0, (Score)
    move.w #0, (ScoreOnes)
    move.w #0, (ScoreTens)
    move.w #0, (ScoreHundreds)
    rts
    
***
*
* d1.w - amount to increase by
*
*** 
score_Increment:
.LOAD_REGS REG d0-d3/a1-a3 *idk. with where it is making volatile things non volatile works in our favor here
    movem.l .LOAD_REGS, -(sp)
    clr.l d3
    move.w (Score), d3 *loading into d3 so it's not volatile
    cmp.w #SCORE_MAX, d3 *if we're at 999 stay there
    beq .done
    add.w d1, d3 *otherwise, increment by 1. storing now allows us to modify
    move.w d3, (Score)
    
    divu #100, d3
    cmp.w (ScoreHundreds), d3
    beq .checkTens
    
    move.w (ScoreHundreds), d0
    move.w #SCORE_HUNDREDS_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr eraseDigit
    *erase the old digit
    
    move.w d3, (ScoreHundreds)
    move.w d3, d0
    move.w #SCORE_HUNDREDS_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr drawDigit 
    *draw the new one
.checkTens
    move.w #0, d3 *clear the bottom word pre swap for divide
    swap d3 *get remainder for 10s calc
    divu #10, d3
    cmp.w (ScoreTens), d3
    beq .checkOnes
    
    move.w (ScoreTens), d0
    move.w #SCORE_TENS_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr eraseDigit
    *erase the old digit
    
    move.w d3, (ScoreTens)
    move.w d3, d0
    move.w #SCORE_TENS_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr drawDigit 
.checkOnes *misnomer because it always changes but it's chill
    swap d3 
    *remainder is just the new digit
    move.w (ScoreOnes), d0
    move.w #SCORE_ONES_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr eraseDigit
    *erase the old digit
    
    move.w d3, (ScoreOnes)
    move.w d3, d0
    move.w #SCORE_ONES_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr drawDigit 

.done
    movem.l (sp)+, .LOAD_REGS
    rts    
    
score_Draw:
.LOAD_REG REG d2
    movem.l .LOAD_REG, -(sp)
    move.w (ScoreHundreds), d0
    move.w #SCORE_HUNDREDS_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr drawDigit 
    
    move.w (ScoreTens), d0
    move.w #SCORE_TENS_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr drawDigit 
    
    move.w (ScoreOnes), d0
    move.w #SCORE_ONES_START, d1
    move.w #SCORE_HEIGHT, d2
    bsr drawDigit 
    movem.l (sp)+, .LOAD_REG
    
    rts
    
Score         dcb.w 1,0
ScoreOnes     dcb.w 1,0
ScoreTens     dcb.w 1,0
ScoreHundreds dcb.w 1,0




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

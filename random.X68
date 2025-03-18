MODULUS    EQU 641
INCREMENT  EQU 365
MULTIPLIER EQU 211
*mostly totally arbitrary, maybe they suck. chosen to definitely work within a word

RAND_TASK_GET_TIME EQU 8

rand_Init
    move.b #RAND_TASK_GET_TIME, d0
    trap #15
    move.w d1, (rand_currentVal)
    bsr rand_getVal
    rts
***
*
* d0.w - maximum value, exclusive
* d1.w - minimum value, inclusive
*
* out d0.w - random value
*
* Linear congruential generator. X_(n + 1) = (MULT * X_n + INCREMENT) % MODULUS
*
*** 
rand_getVal
.LOAD_REGS REG d2
    movem.l .LOAD_REGS, -(sp)
    sub.w d1, d0  *our range is really from (0, max - min) not (min, max) when we generate
    move.w (rand_currentVal), d2 *get the last value in the sequence
    mulu #MULTIPLIER, d2
    add.l #INCREMENT, d2
    divu #MODULUS, d2 *divide
    clr.w d2
    swap d2 *modulus is remainder, stored in upper word, so get it
    move.w d2, (rand_currentVal) *the real last value in the sequence shouldn't be affected by the min and max we want, so store it here
    divu.w d0, d2
    swap d2  *mod to trim to max exclusive
    add.w d1, d2 *add our min
    move.w d2, d0 *move to return
    movem.l (sp)+, .LOAD_REGS
    rts
    
rand_currentVal ds.w 1


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

LINE_PEN_COLOR_TASK EQU 80
LINE_DRAW_TASK      EQU 82

LINE_ROW_SIZE       EQU $A00 *since we're assuming always 640 by 480, we know how much to jump forward to get a certain pixel
LINE_BG_WIDTH       EQU 640
LINE_BG_HEIGHT      EQU 480

***
*
* d0.l - color to draw 
* d1.l - x (high) and y (low) of start point
* d2.l - x (high) and y (low) of end point (d2 volatile)
*
* out d0.b - error code. you know the deal
*
***

**this is going to have a lot of duplicate code for speed reasons
drawLineColor:
.LOAD_REG REG d3-d7
    movem.l .LOAD_REG, -(sp)
    clr d3
    move.w d2, d3
    sub.w d1, d3   *change in y (total)
    
    tst d3
    bgt .noABSY
    neg d3
.noABSY
    
    move.w d2, d6 *store end y off for loop counter
    
    swap d1
    swap d2 *get x values
    
    clr d4
    move.w d2, d4
    sub.w d1, d4   *change in x (total)
    
    swap d1
    swap d2
    
    tst d4
    bgt .noABSX
    neg d4
.noABSX
    
    cmp d3, d4
    blt .drawY
    bsr drawLineXColor
    bra .done
.drawY
    bsr drawLineYColor
    
.done
    movem.l (sp)+, .LOAD_REG
    rts

drawLineXColor:
    *d0 -- draw task
    *d1 (in loop) -- X to draw
    *d2 (in loop) -- Y to draw
    *d3 -- dy
    *d4 -- dx
    *d5 -- current error
    *d6 -- loop counter
    *d7 -- arithmetic / x value placeholder location, flag for choosing loop
    *color stored on stack. hooray!
    
    move.l d1, d7 *store this off for trap
    move.l d0, d1
    move.l #LINE_PEN_COLOR_TASK, d0
    trap #15 *set pen color
    
    move.l d7, d1 *get coords back
    
    swap d1
    swap d2
    
    move.w d2, d6 *store end x off for loop counter
    
    cmp.w d1, d2
    bgt .noSwap
    move.l d1, d7
    move.l d2, d1
    move.l d7, d2 *swap so algorithm always draws "down"
    
.noSwap
    swap d1
    swap d2
    
    clr d3
    move.w d2, d3
    sub.w d1, d3   *change in y (total)
    
    swap d1
    swap d2 *get x values
    
    clr d4
    move.w d2, d4
    sub.w d1, d4   *change in x (total)
        
    clr.l d7
    
    tst d3
    bgt .markLoop
    move.b #1, d7 *flag that we're negative
    neg.w d3
.markLoop
    
    move.l d3, d5
    asl #1, d5
    sub.l d4, d5
    *get the starting error
    
    clr d2 *don't need input endpoint anymore
    swap d1
    move.w d1, d2 *put the starting y in d2
    swap d1 *get starting x back
    
    move.l #LINE_DRAW_TASK, d0
    
    sub.w #1, d1 *prepare for loop
    tst d7 *check our flag
    beq .PositiveYLoop
    
.NegativeYLoop *if we're in here, the lines moves left
    add.w #1, d1
    cmp.w d1, d6
    beq  .done
    trap #15
    tst.l d5
    blt .dontDecrement
    
    add.w #-1, d2
    move.l d3, d7
    sub.l d4, d7
    asl #1, d7
    add.l d7, d5
    bra .NegativeYLoop
    
.dontDecrement
    move.l d3, d7
    asl #1, d7
    add.l d7, d5
    bra .NegativeYLoop

    
.PositiveYLoop *in here it moves right
    add.w #1, d1
    cmp.w d1, d6
    beq  .done
    trap #15
    tst.l d5
    blt .dontIncrement
    
    add.w #1, d2
    move.l d3, d7
    sub.l d4, d7
    asl #1, d7
    add.l d7, d5
    bra .PositiveYLoop
    
.dontIncrement
    move.l d3, d7
    asl #1, d7
    add.l d7, d5
    bra .PositiveYLoop
    
.done
    rts

***
*
* d0.l - color to draw 
* d1.l - x (high) and y (low) of start point
* d2.l - x (high) and y (low) of end point (d2 volatile)
*
* out d0.b - error code. you know the deal
*
***

drawLineYColor:
    *d0 -- draw task
    *d1 (in loop) -- X to draw
    *d2 (in loop) -- Y to draw
    *d3 -- dy
    *d4 -- dx
    *d5 -- current error
    *d6 -- loop counter
    *d7 -- arithmetic / x value placeholder location, flag for choosing loop
    *color stored on stack. hooray!
    
    move.l d1, d7 *store this off for trap
    move.l d0, d1
    move.l #LINE_PEN_COLOR_TASK, d0
    trap #15 *set pen color
    
    move.l d7, d1 *get coords back
    
    cmp.w d1, d2
    bgt .noSwap
    move.l d1, d7
    move.l d2, d1
    move.l d7, d2 *swap so algorithm always draws "down"
.noSwap
    
    clr d3
    move.w d2, d3
    sub.w d1, d3   *change in y (total)
    
    move.w d2, d6 *store end y off for loop counter
    add.w #1, d6 *with how the loop works it needs to be one higher
    
    swap d1
    swap d2 *get x values
    
    clr d4
    move.w d2, d4
    sub.w d1, d4   *change in x (total)
        
    clr.l d7
    
    tst d4
    bgt .markLoop
    move.b #1, d7 *flag that we're negative
    neg.w d4
.markLoop
    
    move.w d4, d5
    asl #1, d5
    sub.w d3, d5
    *get the starting error
    
    clr d2 *don't need input endpoint anymore
    swap d1
    move.w d1, d2 *put the starting y in d2
    swap d1 *get starting x back
    
    move.l #LINE_DRAW_TASK, d0
    
    tst d7 *check our flag
    beq .PositiveXLoop
    
.NegativeXLoop *if we're in here, the lines moves left

    trap #15
    tst.w d5 *check if our error is positive or negative
    blt .dontDecrement
    
    add.w #-1, d1 *a positive error means we've moved enough to be in a new x coordinate
    move.w d4, d7
    sub.w d3, d7
    asl.w #1, d7    *calculate our new error
    add.w d7, d5
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .NegativeXLoop
    bra .done
    
.dontDecrement
    move.w d4, d7 *just calculate the error accumulating
    asl.w #1, d7
    add.w d7, d5
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .NegativeXLoop
    bra .done
    
    
.PositiveXLoop *in here it moves right
    trap #15
    tst.w d5
    blt .dontIncrement
    
    add.w #1, d1
    move.w d4, d7
    sub.w d3, d7
    asl.w #1, d7
    add.w d7, d5
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .PositiveXLoop
    bra .done
    
.dontIncrement
    move.w d4, d7
    asl.w #1, d7
    add.w d7, d5
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .PositiveXLoop
    bra .done
    
.done
    rts
    
 
***
*
* d1.l - x (high) and y (low) of start point
* d2.l - x (high) and y (low) of end point (d2 volatile)
* a1 - address of bmp to pull color from (assumes full bg)
*
* out d0.b - error code. you know the deal
*
***


**this is going to have a lot of duplicate code for speed reasons
drawLineBMP:
.LOAD_REG REG d3-d7
    movem.l .LOAD_REG, -(sp)
    clr d3
    move.w d2, d3
    sub.w d1, d3   *change in y (total)
    
    tst d3
    bgt .noABSY
    neg d3
.noABSY
    
    move.w d2, d6 *store end y off for loop counter
    
    swap d1
    swap d2 *get x values
    
    clr d4
    move.w d2, d4
    sub.w d1, d4   *change in x (total)
    
    swap d1
    swap d2
    
    tst d4
    bgt .noABSX
    neg d4
.noABSX
    
    cmp d3, d4
    blt .drawY
    bsr drawLineXBMP
    bra .done
.drawY
    bsr drawLineYBMP
    
.done
    movem.l (sp)+, .LOAD_REG
    rts

drawLineXBMP:
    *d0 -- draw task
    *d1 (in loop) -- X to draw
    *d2 (in loop) -- Y to draw
    *d3 -- dy
    *d4 -- dx
    *d5 -- current error
    *d6 -- loop counter
    *d7 -- arithmetic / x value placeholder location, flag for choosing loop
    *color stored on stack. hooray!
    
    swap d1
    swap d2
    
    
    cmp.w d1, d2
    bgt .noSwap
    move.l d1, d7
    move.l d2, d1
    move.l d7, d2 *swap so algorithm always draws "down"
    
.noSwap
    move.w d2, d6 *store end x off for loop counter
    add.w #1, d6

    swap d1
    swap d2
    
    move.l BMP_OFFSET(a1), d4 *getting the beginning of the pixel array
    ror.w #8, d4
    swap d4
    ror.w #8, d4
    add.l d4, a1 *we do this right at the beginning so we don't need to dedicate any reg space to offsetting it
    
    move.w d1, d3
    neg.w d3
    add.w #LINE_BG_HEIGHT, d3
    sub.w #1, d3
    mulu #LINE_ROW_SIZE, d3
    add.l d3, a1
    *get initial offset from y coordinate
    
    clr.l d3
    swap d1
    move.w d1, d3
    asl.l #2, d3
    add.l d3, a1
    *get initial offset from x coordinate
    
    swap d1
    
    *do this after checking the swap because we don't know what "initial" is otherwise
    
    clr d3
    move.w d2, d3
    sub.w d1, d3   *change in y (total)
    
    swap d1
    swap d2 *get x values
    
    clr d4
    move.w d2, d4
    sub.w d1, d4   *change in x (total)
        
    clr.l d7
    
    tst d3
    bgt .markLoop
    move.b #1, d7 *flag that we're negative
    neg.w d3
.markLoop
    
    move.l d3, d5
    asl #1, d5
    sub.l d4, d5
    *get the starting error
    
    clr d2 *don't need input endpoint anymore
    swap d1
    move.w d1, d2 *put the starting y in d2
    swap d1 *get starting x back
    
    move.l #LINE_DRAW_TASK, d0
    
    tst d7 *check our flag
    beq .PositiveYLoop
    
.NegativeYLoop *if we're in here, the lines moves left
    move.w d1, d7 *store d7
    move.l (a1)+, d1 *load in the color, since we always increment X can postincrement
    move.b #80, d0
    trap #15 *set pen color
    
    move.l d7, d1
    move.b #82, d0
    trap #15
    tst.l d5
    blt .dontDecrement
    
    add.l #LINE_ROW_SIZE, a1
    add.w #-1, d2
    move.l d3, d7
    sub.l d4, d7
    asl #1, d7
    add.l d7, d5
    add.w #1, d1
    cmp.w d1, d6
    bne  .NegativeYLoop
    bra .done
    
.dontDecrement
    move.l d3, d7
    asl #1, d7
    add.l d7, d5
    add.w #1, d1
    cmp.w d1, d6
    bne  .NegativeYLoop
    bra .done

    
.PositiveYLoop *in here it moves right
    move.w d1, d7 *store d7
    move.l (a1)+, d1 *load in the color, since we always increment X can postincrement
    move.b #80, d0
    trap #15 *set pen color
    
    move.l d7, d1
    move.b #82, d0
    trap #15
    tst.l d5
    blt .dontIncrement
    
    sub.l #LINE_ROW_SIZE, a1
    add.w #1, d2
    move.l d3, d7
    sub.l d4, d7
    asl #1, d7
    add.l d7, d5
    add.w #1, d1
    cmp.w d1, d6
    bne  .PositiveYLoop
    bra .done
    
.dontIncrement
    move.l d3, d7
    asl #1, d7
    add.l d7, d5
    add.w #1, d1
    cmp.w d1, d6
    bne  .PositiveYLoop
    bra .done
    
.done
    rts


drawLineYBMP:
    *d0 -- draw task
    *d1 (in loop) -- X to draw
    *d2 (in loop) -- Y to draw
    *d3 -- dy
    *d4 -- dx
    *d5 -- current error
    *d6 -- loop counter
    *d7 -- arithmetic / x value placeholder location, flag for choosing loop
    *color stored on stack. hooray!
    
    
    cmp.w d1, d2
    bgt .noSwap
    move.l d1, d7
    move.l d2, d1
    move.l d7, d2 *swap so algorithm always draws "down"
.noSwap
    
    move.l BMP_OFFSET(a1), d4 *getting the beginning of the pixel array
    ror.w #8, d4
    swap d4
    ror.w #8, d4
    add.l d4, a1 *we do this right at the beginning so we don't need to dedicate any reg space to offsetting it
    clr d4
    
    move.w d1, d3
    neg.w d3
    add.w #LINE_BG_HEIGHT, d3
    sub.w #1, d3
    mulu #LINE_ROW_SIZE, d3
    add.l d3, a1
    *get initial offset from y coordinate
    
    clr.l d3
    swap d1
    move.w d1, d3
    asl.l #2, d3
    add.l d3, a1
    *get initial offset from x coordinate
    
    swap d1
    
    clr d3
    move.w d2, d3
    sub.w d1, d3   *change in y (total)
    
    move.w d2, d6 *store end y off for loop counter
    add.w #1, d6 *with how the loop works it needs to be one higher
    
    swap d1
    swap d2 *get x values
    
    clr d4
    move.w d2, d4
    sub.w d1, d4   *change in x (total)
        
    clr.l d7
    
    tst d4
    bgt .markLoop
    move.b #1, d7 *flag that we're negative
    neg.w d4
.markLoop
    
    move.w d4, d5
    asl #1, d5
    sub.w d3, d5
    *get the starting error
    
    clr d2 *don't need input endpoint anymore
    swap d1
    move.w d1, d2 *put the starting y in d2
    swap d1 *get starting x back
    
    move.l #LINE_DRAW_TASK, d0
    
    tst d7 *check our flag
    beq .PositiveXLoop
    
.NegativeXLoop *if we're in here, the lines moves left
    move.w d1, d7 *store d7
    move.l (a1), d1 *load in the color, since we don't always increment X can't postincrement
    move.b #80, d0
    trap #15 *set pen color
    
    move.l d7, d1
    move.b #82, d0
    trap #15
    tst.w d5 *check if our error is positive or negative
    blt .dontDecrement
    
    add.w #-1, d1 *a positive error means we've moved enough to be in a new x coordinate
    sub.l #4, a1
    move.w d4, d7
    sub.w d3, d7
    asl.w #1, d7    *calculate our new error
    add.w d7, d5
    sub.w #LINE_ROW_SIZE, a1
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .NegativeXLoop
    bra .done
    
.dontDecrement
    move.w d4, d7 *just calculate the error accumulating
    asl.w #1, d7
    add.w d7, d5
    sub.w #LINE_ROW_SIZE, a1
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .NegativeXLoop
    bra .done
    
.PositiveXLoop *in here it moves right
    move.w d1, d7 *store d7
    move.l (a1), d1 *load in the color, since we don't always increment X can't postincrement
    move.b #80, d0
    trap #15 *set pen color
    
    move.l d7, d1
    move.b #82, d0
    trap #15
    tst.w d5
    blt .dontIncrement
    
    add.w #1, d1
    add.w #4, a1
    move.w d4, d7
    sub.w d3, d7
    asl.w #1, d7
    add.w d7, d5
    sub.w #LINE_ROW_SIZE, a1
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .PositiveXLoop
    bra .done
    
.dontIncrement
    move.w d4, d7
    asl.w #1, d7
    add.w d7, d5
    sub.w #LINE_ROW_SIZE, a1
    add.w #1, d2
    cmp.w d2, d6 *increment y by 1. Since this line is steep, there's only ever 1 pixel per y coord
    bne  .PositiveXLoop
    bra .done
    
.done
    rts






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

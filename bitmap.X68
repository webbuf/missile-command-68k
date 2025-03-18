*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

BMP_HEADER_SIZE     EQU  14
BMP_TOTAL_SIZE      EQU  2 *offset to access the total size of the file from the header
BMP_SIGNATURE       EQU  $424D
BMP_OFFSET          EQU  10
BMP_WIDTH           EQU  18
BMP_HEIGHT          EQU  22
BMP_BITS_PER_PIXEL  EQU  28
BMP_MAX_SIZE        EQU  1024

TASK_SET_PEN_COLOR  EQU 80
TASK_DRAW_PIXEL     EQU 82

*---
*
* a0 - name of file to load
*
* out a1   - address of file
* out d0.b - 0 for success, other for failure
*
*---

bmp_Load
.LOAD_REGS REG d2-d5/a2-a3
    movem.l .LOAD_REGS, -(sp)
    move.l a0, a3 *preserve our filename
    
    move.l #BMP_HEADER_SIZE, d1
    bsr mem_Alloc
    tst.b d0
    bne .error
    *allocate JUST the bmp header first
    *this approach allows us to avoid allocating an arbitrary amount of memory
    *it might be slightly slower, but it feels more robust
    
    move.l a0, a2 *move our address into a2 for read
    move.l a3, a1 *move filename into a1 for write
    *size to read still in the right place
    
    bsr file_Read
    tst.b d0
    bne .error
    
    cmp.w #BMP_SIGNATURE, (a2) *compares the first two bytes of what we read to the bmp signature
    bne .errorFree *if it's not exactly right, this is a corrupt bmp, so exit
    
    move.l BMP_TOTAL_SIZE(a2), d2 *read the size of the total file
    *put it in d2 so it'll be preserved
    
    ror.w #8, d2
    swap d2
    ror.w #8, d2
    *this code swaps the endianness
    *for legibility it could be a subroutine
    *but for cycle reasons. fuck that. 
    
    move.l BMP_OFFSET(a2), d3
    ror.w #8, d3
    swap d3
    ror.w #8, d3
    *also get the offset to the actual data
    *which, helpfully, is the total size of both headers
    *we want to read the headers in first because of a crazy offset trick for 32 bit bmps
    *to remove the shifting in the draw loop. don't want to do it for 24 bit, so do it here.
    
    add.w #2, d2 *alloc 2 more bytes than we need for said crazy offset trick
    
    move.l a0, a1
    bsr mem_Free
    tst.b d0
    bne .error
    *now that we have the size, free the old just header alloc. that + verification is all we needed from it
    
    move.l d2, d1
    bsr mem_Alloc *now allocate the amount of memory we actually need
    tst.b d0
    bne .error
    
    move.l a3, a1 *get filename back
    move.l a0, a2 *get the start address into the proper position to read
    move.l d3, d1 *d1 is volatile so we can't assume the size is still there! wahoo!! (i could look to see if it's there but i don't wanna)
    bsr file_Read *read in our headers
    tst.b d0
    bne .errorFree
    
    move.l BMP_HEIGHT(a2), d5
    ror.w #8, d5
    swap d5
    ror.w #8, d5
    cmp.w #BMP_MAX_SIZE, d5
    bhi .errorFree
    
    move.l BMP_WIDTH(a2), d5
    ror.w #8, d5
    swap d5
    ror.w #8, d5
    cmp.w #BMP_MAX_SIZE, d5
    bhi .errorFree
    *ensure the height and width of our file are within our bounds (1024 x 1024)
    *unsigned comps to be safe. otherwise due to our bounds signed comps are fine
    
    move.l BMP_BITS_PER_PIXEL(a2), d4
    ror.w #8, d4
    swap d4
    ror.w #8, d4 *get the bits per pixel
    
    cmp #32, d4 *check if we're working in a 32 bit file
    bne .noOffset
    add.l #1, a2 *increment where we're reading by one if it's 32 bit
    *this will have our line data offset all by one byte. therefore, we don't need to offset the data after we read it
    *saving a ton of cycles in the draw loop
.noOffset
    add.l d3, a2 *move where to read by the amount we already read
    sub.l d3, d2 *we already read some of the file, we don't want to read it again
    move.l d3, d0 *move offset for read into parameters as well
    move.l a3, a1 *filename rescue
    move.l d2, d1 *get size ready
    *a2 already good to go
    
    bsr file_Read_Offset *different read that can read from later
    move.l a0, a1 *a0 has original file location after read with offset
    movem.l (sp)+, .LOAD_REGS
    move.b #0, d0
    rts
    
.errorFree
    bsr mem_Free *if we encounter an error after allocating memory, free it 
.error
    move.b #1, d0 *otherwise just return
    movem.l (sp)+, .LOAD_REGS
    rts
    
*---
*
* a1 - pointer to bmp to unload
*
* out d0.b - 0/1 error code typicalness
*
*---   
    
bmp_Unload:
    bsr mem_Free
    rts
    *wow! parameters match free, so just a wrapper for it
    
*---
*
* a1 - pointer to bitmap in memory
* d0 - x (upper word) and y (lower word) of top left of image to draw
* d1 - x (upper word) and y (lower word) of bottom right of image to draw
* d2 - x (upper word) and y (lower word) of top left of point to draw to
*
* out d0.b - byte error code
*
*---
    
bmp_Draw 
.LOAD_REGS REG d2-d7
    movem.l .LOAD_REGS, -(sp)
    
    sub.w #1, d2
    
    cmp.w #BMP_SIGNATURE, (a1) *check if we're pointing to a valid bitmap but checking signature
    bne .error
    
    cmp.w d0, d1
    bcs .error *if our end pixel is bigger than our start, error
    
    swap d0
    swap d1 *swap to get x coords
    
    cmp.w d0, d1
    bcs .error *same as above, with x coordinates
    
    move.l BMP_WIDTH(a1), d4
    move.l BMP_HEIGHT(a1), d3
    
    ror.w #8, d4
    swap d4
    ror.w #8, d4 *width
    
    ror.w #8, d3
    swap d3
    ror.w #8, d3 *height
    *get width and height for further error checking
    
    cmp.w d0, d4
    bls .error *if our starting x is outside of image bounds, error
    
    cmp.w d1, d4
    bhi .dontClampX
    move.w d4, d1 *if our endpoint is outside of the image, clamp it instead of erroring out
    
.dontClampX
    swap d0
    swap d1 *Y time
    
    cmp.w d0, d3
    bls .error *if our starting y is outside of image bounds, error
    
    cmp.w d1, d3
    bhi .dontClampY
    move.w d3, d1 *if our endpoint is outside of the image, clamp it instead of erroring out
    
    *these comparisons use unsigned comparisons, but nothing else does
    *once we're past here, we know we're constrained by 1024 x 1024, so this is fine
    
.dontClampY  
    move.l BMP_BITS_PER_PIXEL(a1), d3
    ror.w #8, d3
    swap d3
    ror.w #8, d3 *get the total number of bits per pixel, which we use to determine draw behavior
    *TOTAL duplication like this is probably unnecessary, but it's fast and takes no registers
    
    cmp #32, d3
    beq .32BitDraw
    
.24BitDraw
    move.l BMP_OFFSET(a1), d4 *getting the beginning of the pixel array
    ror.w #8, d4
    swap d4
    ror.w #8, d4
    move.l a1, a0 *separate from a1 so we can keep the header pointer 
    add.l d4, a0 *we do this right at the beginning so we don't need to dedicate any reg space to offsetting it
    
    move.l BMP_WIDTH(a1), d4
    move.l BMP_HEIGHT(a1), d3
    
    ror.w #8, d4
    swap d4
    ror.w #8, d4 *width
    
    ror.w #8, d3
    swap d3
    ror.w #8, d3 *height
    *load the width and the height (constant distance away) in from the header and endianify them
    
    move.w d4, d7 *get width and height elsewhere so we can modify it and have it later
    move.w d3, d5 *keep our height elsewhere 
    
    mulu #3, d7 *(this assumes 24 bit) get the amount of bytes in 1 row
    sub.w d1, d5 *bottom right y - height reverses it, since the image is stored bottom up but we're indexing not like that
    mulu d5, d7 *this makes d6 the amount of bytes we need to skip to start drawing from where we want to
    add.l d7, a0
    
    move.w d2, d6 *store top of draw space (height limit/end of loop) off elsewhere
    add.w d3, d2 *add the offset for draw height to d2
    sub.w d5, d2 *now move it up to account for bottom right
    sub.w d0, d2 *move our starting height up by however much we're removing from the top
    *this separates the place to draw from from where in the image we're drawing, which is how it should be
    *good contender for going on the stack, since we only access it in the outer loop
    
    swap d0
    swap d1 *x time
    swap d2
    
    move.w d0, d5 *don't need d5 anymore, can use it for this now
    mulu.w #3, d5 *convert pixel offset to bytes
    add.l d5, a0  *shift our address over more
    
    move.w d1, d5
    sub.w d0, d5
    *end pixel - start pixel is the width of what we want to draw, basically our loop counter
    
    clr d7 *had a multiply so it could be a lw: clear it
    move.w d4, d7 *store width elsewhere
    sub.w d5, d7 *therefore total width - draw width is everything we don't draw
    mulu #3, d7 *which we can use to offset back to where we need to draw from next
    
    mulu.w #3, d4 *turn width to total number of bytes in row (we don't need it now, can overwrite
    divu #4, d4 *divide it by 4
    lsr.l #8, d4
    lsr.l #8, d4
    *get the remainder in the low byte. Swap would be faster, but want to clear top bit anyway
    tst.w d4
    beq .noPadding *if it's 0, don't pad it
    neg d4
    add.w #4, d4 *otherwise get however many bytes we would need to pad to move along
    add.l d4, d7 *add it to our existing address skip offset
    
.noPadding
    move.w d5, d4 *don't need total width anymore, can make it the target for our loop counter
    add.w d2, d4 *add x offset to the loop counter, it goes from offset to offset + width
    swap d2 *unnecessary here, but needed to make loop work
    
    *this looks kind of weird, but it's because it was added to existing code, I think
    *that was optimized pretty well, so I wanted to preserve it as well as I could, and
    *this was the best way to do it. So in one case we bring our offset to the measurement,
    *and in the other we bring the measurement to the offset
    
    clr d0
    move.b #TASK_DRAW_PIXEL, d0
    swap d0
    move.b #TASK_SET_PEN_COLOR, d0 
    *wipe out d0, then put the two tasks we need in there
    *it's kinda gross(?), but swapping between them like this is faster than repeatedly loading them

.drawLoopTop24 
    swap d2 *swap d2 to get the x position
    move.w d2, d5 *reset x
    swap d2 *get y counter back
.drawInnerLoop24
    clr d1
    move.b (a0)+, d1 *get the first byte of color into our register, shift
    lsl.l #8, d1
    move.b (a0)+, d1 *second byte
    lsl.l #8, d1
    move.b (a0)+, d1
    *lsr.l #8, d1 *(assuming 32 bit) shift out A, rest already in desired BGR form
    *society if bmps stored it ABGR instead of BGRA (beautiful utopia)
    *BOOM get outta here!!! keeping it commented out as a testament to the fact that I got around it
    *avoiding this shift saved 4 million cycles on a 400 x 400. 10 mil to 6 mil. like almost double efficency
    trap #15 *set the pen to the color we found
    
    swap d0 *switch d0 to draw task
    move.l d5, d1 *prepare X. Y already ready
    *we only need the word but apparently move l and w between regs take the same time
    trap #15 *draw pen color at current pixel
    
    swap d0 *switch to set pen color task
    add.w #1, d5 *increment X/loop counter
    cmp.w d5, d4 *compare x to our max. 
    bne .drawInnerLoop24 *if it hasn't hit 0, go back to the top
    *otherwise, fall into our increment for the height loop
    *doing the bne and collapse otherwise into the other saved a bunch of time
    *I think i've been doing it not like the for a while, too
    *I guess it didn't really occur to me? Thinking too higher level about loops, I guess
    
.heightLoopIncrement24
    sub.l #1, d2 *decrement height counter/Y
    add.l d7, a0 *offset where we're reading from by unused space
    cmp.w d2, d6 *check if we've hit our height limit
    bne .drawLoopTop24 *similar to other loop. go back if we can, otherwise fall into done
    bra .done
    
.32BitDraw
    move.l BMP_OFFSET(a1), d4 *getting the beginning of the pixel array
    ror.w #8, d4
    swap d4
    ror.w #8, d4
    move.l a1, a0 *separate from a1 so we can keep the header pointer 
    add.l d4, a0 *we do this right at the beginning so we don't need to dedicate any reg space to offsetting it
    
    move.l BMP_WIDTH(a1), d4
    move.l BMP_HEIGHT(a1), d3
    
    ror.w #8, d4
    swap d4
    ror.w #8, d4 *width
    
    ror.w #8, d3
    swap d3
    ror.w #8, d3 *height
    *load the width and the height (constant distance away) in from the header and endianify them
    
    move.w d4, d7 *get width and height elsewhere so we can modify it and have it later
    move.w d3, d5 *keep our height elsewhere 
    
    mulu #4, d7 *(this assumes 32 bit) get the amount of bytes in 1 row
    sub.w d1, d5 *bottom right y - height reverses it, since the image is stored bottom up but we're indexing not like that
    mulu d5, d7 *this makes d6 the amount of bytes we need to skip to start drawing from where we want to
    add.l d7, a0
    
    move.w d2, d6 *store top of draw space (height limit/end of loop) off elsewhere
    add.w d3, d2 *add the offset for draw height to d2
    sub.w d5, d2 *now move it up to account for bottom right
    sub.w d0, d2 *move our starting height up by however much we're removing from the top
    *this separates the place to draw from from where in the image we're drawing, which is how it should be
    *good contender for going on the stack, since we only access it in the outer loop
    
    swap d0
    swap d1 *x time
    swap d2
    
    move.w d0, d5 *don't need d5 anymore, can use it for this now
    mulu.w #4, d5 *convert pixel offset to bytes
    add.l d5, a0  *shift our address over more
    
    move.w d1, d5
    sub.w d0, d5
    *end pixel - start pixel is the width of what we want to draw, basically our loop counter
    
    clr d7 *had a multiply so it could be a lw: clear it
    move.w d4, d7 *store width elsewhere
    sub.w d5, d7 *therefore total width - draw width is everything we don't draw
    mulu #4, d7 *which we can use to offset back to where we need to draw from next
    
    move.w d5, d4 *don't need total width anymore, can make it the target for our loop counter
    add.w d2, d4 *add x offset to the loop counter, it goes from offset to offset + width
    swap d2 *unnecessary here, but needed to make loop work
    
    *this looks kind of weird, but it's because it was added to existing code, I think
    *that was optimized pretty well, so I wanted to preserve it as well as I could, and
    *this was the best way to do it. So in one case we bring our offset to the measurement,
    *and in the other we bring the measurement to the offset
    
    *code assumed 32 bits
    *IDEA: 24 bit bmps should be handled by a totally separate subroutine (or just loop i guess)
    *we would have to have some kind of logic to check which load we do EVERY PIXEL if we didn't do it that way
    *there will be a lot of duplicate code, but honestly the draw loop is pretry small anyway
    *instead of check logic we could do a bunch of branches I guess, but two totally separate loops is both readable
    *and fast. Should be the last thing i do, though, since any fixes I make in one I'll need to also make in the other
    *^ did this ^ *
    
    clr d0
    move.b #TASK_DRAW_PIXEL, d0
    swap d0
    move.b #TASK_SET_PEN_COLOR, d0 
    *wipe out d0, then put the two tasks we need in there
    *it's kinda gross(?), but swapping between them like this is faster than repeatedly loading them

.drawLoopTop32 
    swap d2 *swap d2 to get the x position
    move.w d2, d5 *reset x
    swap d2 *get y counter back
.drawInnerLoop32
    move.l (a0)+, d1 *get the color into the register, increment to next color
    *lsr.l #8, d1 *(assuming 32 bit) shift out A, rest already in desired BGR form
    *society if bmps stored it ABGR instead of BGRA (beautiful utopia)
    *BOOM get outta here!!! keeping it commented out as a testament to the fact that I got around it
    *avoiding this shift saved 4 million cycles on a 400 x 400. 10 mil to 6 mil. like almost double efficency
    trap #15 *set the pen to the color we found
    
    swap d0 *switch d0 to draw task
    move.l d5, d1 *prepare X. Y already ready
    *we only need the word but apparently move l and w between regs take the same time
    trap #15 *draw pen color at current pixel
    
    swap d0 *switch to set pen color task
    add.w #1, d5 *increment X/loop counter
    cmp.w d5, d4 *compare x to our max. 
    bne .drawInnerLoop32 *if it hasn't hit 0, go back to the top
    *otherwise, fall into our increment for the height loop
    *doing the bne and collapse otherwise into the other saved a bunch of time
    *I think i've been doing it not like the for a while, too
    *I guess it didn't really occur to me? Thinking too higher level about loops, I guess
    
.heightLoopIncrement32
    sub.l #1, d2 *decrement height counter/Y
    add.l d7, a0 *offset where we're reading from by unused space
    cmp.w d2, d6 *check if we've hit our height limit
    bne .drawLoopTop32 *similar to other loop. go back if we can, otherwise fall into done

.done
    movem.l (sp)+, .LOAD_REGS
    moveq #0, d0 *all good boss
    rts    

.error
    movem.l (sp)+, .LOAD_REGS
    moveq #1, d0 *all bad boss
    rts   
    
    
    
    







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

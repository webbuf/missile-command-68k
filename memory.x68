*-----------------------------------------------------------
* Title      : Memory management module
* Written by : 
* Date       : 
* Description: 
*-----------------------------------------------------------

* constants for callers of mem_Audit
MEM_AUDIT_OFFS_FREE_CNT     EQU 0
MEM_AUDIT_OFFS_USED_CNT     EQU 4
MEM_AUDIT_OFFS_FREE_MEM     EQU 8
MEM_AUDIT_OFFS_USED_MEM     EQU 12
MEM_AUDIT_RETURN_SIZE       EQU 16

* constants for header struct (internal)
MEM_SIZE        EQU 0 *also represents free/filled. see below
MEM_NEXT        EQU 4 
MEM_HEADER_SIZE EQU 8

*size of memory has to be positive
*so what if we made negative sizes represent a hole
*we would treat it as a positive size, because it's gotta be
*but we know it's a whole if it's negative
*credit to jeremy

*all over this code i use MEM_OFFSET_SIZE as an index so I can actually read my code
*this might be slightly slower than it could be since the indexing doesn't move the address at all
*perhaps if I need to use this in another assignment I'll go back and remove them to optimize it 
*but for now I'll take the hit to make the code not nonsense

MEM_RETURN_OKAY     EQU 0
MEM_RETURN_ERROR    EQU 1
*return types

*---
* Initializes the start of the heap
* 
* a1 - start address of heap
* d1.l - size of heap
*
* out d0.b - 0 = success, non-zero = failure
*---
mem_InitHeap:
    move.l a1, mem_StartOfHeap
    sub.l #MEM_HEADER_SIZE, d1 *we don't have header size bytes free, since we need them for the header
    cmp.l #MEM_HEADER_SIZE, d1
    ble .error *if we aren't initializing enough space to make a header, we can't make the heap
    neg.l d1 *make it free
    move.l d1, MEM_SIZE(a1) *put d1 at offset 0 from a1
    move.l #0, MEM_NEXT(a1) *put a null at a1 since there's no next
    move.b #MEM_RETURN_OKAY, d0
    rts
.error
    move.b #MEM_RETURN_ERROR, d0

*---
* Accumulates some statistics for memory usage
*
* out d0.b - 0 = success, non-zero = error
* out (sp) - count of free blocks
* out (sp+4) - count of used blocks
* out (sp+8) - total remaining free memory
* out (sp+12) - total allocated memory

*storing regs on the stack and then also using it for returns scares me
*so i am simply going to only use volatile registers

mem_Audit:
.MEM_FREE_COUNT EQU 4
.MEM_USED_COUNT EQU 8
.MEM_FREE_SIZE  EQU 12
.MEM_USED_SIZE  EQU 16
*four more than return positions, since we have the return address on the stack as well

    move.l (mem_StartOfHeap), a0 *load beginning of heap to a0
    clr.l .MEM_FREE_COUNT(sp)
    clr.l .MEM_USED_COUNT(sp)
    clr.l .MEM_FREE_SIZE(sp)
    clr.l .MEM_USED_SIZE(sp)
    *zero out the portion of the stack we need to use to store these counts
    *so the loop can just worry about adding

.auditLoop
    move.l MEM_SIZE(a0), d0
    tst.l d0 *check if the size is positive or negative, to see if we have a hole or not
    blt .addHole
    add.l #1, .MEM_USED_COUNT(sp) *add one used block
    add.l d0, .MEM_USED_SIZE(sp) *add used memory
    bra .incrementLoop
.addHole    
    neg.l d0
    add.l #1, .MEM_FREE_COUNT(sp)
    add.l d0, .MEM_FREE_SIZE(sp) *add hole count and free memory
.incrementLoop
    tst.l MEM_NEXT(a0)
    beq .done
    move.l MEM_NEXT(a0), a0
    bra .auditLoop
    *seeing if next is null, ending if it is, and then restarting the loop
    *this looks inefficient, but I couldn't seem to test is a0 was 0 directly
    *so this is the way to go
    
.done
    move.b #MEM_RETURN_OKAY, d0
    rts
          
*---
* Allocates a chunk of memory from the heap
*
* d1.l - size
*
* out a0 - start address of allocation
* out d0.b - 0 = success, non-zero = failure
*---

mem_Alloc:
.ALLOC_REGS REG d2-d3/a2
    
    movem.l .ALLOC_REGS, -(sp)
    move.l (mem_StartOfHeap), a0 *load the beginning of our heap
    move.l d1, d3
    add.l #MEM_HEADER_SIZE, d3 *load our size in another register and add the header size
    *so we can tell if the hole has enough for our data + another header
    
.checkLoop
    tst.l MEM_SIZE(a0) *see if our current hole is positive size (real) or negative (hole)
    bgt .incrementLoop *if it's real increment it
    move.l MEM_SIZE(a0), d2 *store size of current hole in d2
    neg.l d2 *if we're a hole, see how big the hole is
    cmp.l d1, d2 *compare size we want to fill to size we have
    beq .fillHole *if it's exactly big enough, we can fill it and don't need another header
    cmp.l d3, d2
    bge .fillHole *if it's bigger than size + header, we can fill and add new header
    *these comparisons seem redundant but we can either be EXACTLY the size we need to fill or
    *larger enough to put another header in there. so this is the best way to do it
    
.incrementLoop
    tst.l MEM_NEXT(a0) *check address of next block
    beq .error *if there's no next, we can't fill. error
    move.l MEM_NEXT(a0), a0 *load up next address
    bra .checkLoop
    
.fillHole
    move.l MEM_NEXT(a0), a2 *save off our current next address
    move.l d1, MEM_SIZE(a0) *put our size in there
    add.l a0, d3 *this is the last time we need for header + size so we can overwrite it
    btst.l #00, d3 *test the one bit to see if this is an odd address
    beq .dontAlterNext     
    add.l #1, d3 *if it is, change it so we word align
.dontAlterNext
    move.l d3, MEM_NEXT(a0) *put our address for the next block in the header
    cmp d1, d2
    beq .done *if we're filling this hole exactly, don't make the new header
    
    sub.l d1, d2 *subtract how much space we're allocating from the size of the hole
    move.l MEM_NEXT(a0), a1 *load the address of where our new block is
    sub.l #MEM_HEADER_SIZE, d2 *remove header size from free mem
    neg.l d2 *this is a hole, so negate our size
    move.l d2, MEM_SIZE(a1) *put our size in the new header
    move.l a2, MEM_NEXT(a1) *we saved the old next off earlier, put it back here (accounts for an actual block or null term)
    *this next was already good, so we don't need to check if it's odd or even. cause that bad boy will be even
    
.done
    add.l #MEM_HEADER_SIZE, a0 *move our address past the header
    *we don't touch a0 making the new hole, so this works for either
    move.b #MEM_RETURN_OKAY, d0 *return no error 
    movem.l (sp)+, .ALLOC_REGS
    rts
    
.error *after .done so fillHole can just go into done
    move.b #MEM_RETURN_ERROR, d0
    movem.l (sp)+, .ALLOC_REGS
    rts
*---
* Frees a chunk of memory from the heap
*
* a1 - start address of allocation
*
* out d0.b - 0 = success, non-zero = failure
*---
mem_Free:
    *don't use any other regs, no need to push anything to the stack
    sub.l #MEM_HEADER_SIZE, a1 *move back by header size so their start is now our start
    move.l (mem_StartOfHeap), a0 *load the start of our heap into a0
.findLoop
    cmp.l a0, a1
    beq .free *if they're equal, this is the one to free
    tst.l MEM_NEXT(a0)
    beq .error *if next is 0, then the thing we want to free doesn't exist. error
    move.l MEM_NEXT(a0), a0 *else it exists. go to it
    bra .findLoop
    
.free
    tst.l MEM_SIZE(a0)
    blt .done *if it's already free just say we're done boss and move on
    *this could be an error? freeing free memory? but I mean, it /is/ free. so it's fine i guess
    neg.l MEM_SIZE(a0) *otherwise, make the size negative, marking it as free
    
.done
    move.l (mem_StartOfHeap), a1 *we want to check whole heap for coalesce, so get the start
    bsr mem_Coalesce

    move.b #MEM_RETURN_OKAY, d0
    rts
    
.error *after .done so fillHole can just go into done
    move.b #MEM_RETURN_ERROR, d0
    rts
    
*---
* Reduces a current memory allocation to a smaller number of bytes
*
* a1 - start address of allocation
* d1.l - new size
* 
* out d0.b - 0 = success, non-zero = failure
mem_Shrink:
.SHRINK_REGS REG d2-d3/a2
    movem.l .SHRINK_REGS, -(sp)
    move.l (mem_StartOfHeap), a0
    sub.l #MEM_HEADER_SIZE, a1 *push a1 back to where we know the block really starts
    
.findLoop
    cmp.l a0, a1
    beq .shrink *if addresses are equal, this is what we want to shrink
    tst.l MEM_NEXT(a0)
    beq .error *if next is 0, we're at the end. nothing to shrink.
    move.l MEM_NEXT(a0), a0
    bra .findLoop
    
.shrink
    tst.l MEM_SIZE(a0)
    blt .error *if it's a hole, can't shrink
    move.l d1, d2
    add.l #MEM_HEADER_SIZE, d2 *we need to hold a new header, too
    cmp.l d2, d1
    bgt .error *if we're shrinking to bigger than we have, error
    move.l MEM_SIZE(a0), d3 *keep old size for later
    move.l d1, MEM_SIZE(a0) *get the new size
    move.l MEM_NEXT(a0), a2 *keep the old next
    move.l a0, MEM_NEXT(a0)
    add.l d2, MEM_NEXT(a0) *get the next address of the new block
    
    move.l MEM_NEXT(a0), a0 *go to where our new block should be
    sub.l d2, d3 *subtract the new size from the old size - remaining is the size of the hole we're making
    neg.l d3 *it's a hole, so negative
    move.l d3, MEM_SIZE(a0)
    move.l a2, MEM_NEXT(a0) *put the next we kept in the new hole

    bsr mem_Coalesce *we're just coalescing from where we started, which is already in a1

    move.b #MEM_RETURN_OKAY, d0
    movem.l (sp)+, .SHRINK_REGS
    rts
    
.error *after .done so fillHole can just go into done
    move.b #MEM_RETURN_ERROR, d0
    movem.l (sp)+, .SHRINK_REGS
    rts
    
*---
* Combines adjacent holes into one larger hole
*
* a1 - start address to consider
*
* out d0.b - 0 = success, non-zero = failure (for convention, not sure this can fail?)
*--- 
mem_Coalesce:
.findLoop *i think i could just branch back to coalesce, but that's confusing
*extra label for clarity
    tst.l MEM_NEXT(a1)
    beq .done *if the next is null terminator, we're done
    tst.l MEM_SIZE(a1) *check if we're positive or negative
    bgt .incrementAddress
    move.l MEM_NEXT(a1), a0 *get the next address into a0
    tst.l MEM_SIZE(a0)
    blt .combineHole *if it's also a hole, branch to combine
    *otherwise, we just naturally fall into increment, which is what we need to do
    *theoretically, we could move two over, since here we know next isn't a hole
    *but i'll take the elegance over the hassle of having two separate increment cases
    
.incrementAddress
    move.l MEM_NEXT(a1), a1 *we already know this isn't null, so move it
    bra .findLoop
    
.combineHole *here we know we have two holes
    move.l MEM_SIZE(a1), d1 *move size into register
    add.l MEM_SIZE(a0), d1 *add other size, since both negative will add as we want still
    sub.l #MEM_HEADER_SIZE, d1 *losing a header, so add that size to the hole as well
    move.l d1, MEM_SIZE(a1) *get our new size
    move.l MEM_NEXT(a0), MEM_NEXT(a1) *move the second blocks next into the first's spot 
    bra .findLoop *want to keep same address, since now we have a new next at the same a1
    
.done
    move.b #MEM_RETURN_OKAY, d0 *no need for any non-volatile restore, since this doens't use any
    rts
    
        ds.w 0
    
mem_StartOfHeap ds.l 1





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

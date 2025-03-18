*-----------------------------------------------------------
* Title      : File IO module
* Written by : 
* Date       : 
* Description: 
*-----------------------------------------------------------

FILE_TASK_FOPEN        EQU     51
FILE_TASK_FCREATE      EQU     52
FILE_TASK_FREAD        EQU     53
FILE_TASK_FWRITE       EQU     54
FILE_TASK_POSITION     EQU     55
FILE_TASK_FCLOSE       EQU     56
FILE_NON_VOLATILE_REGS REG     d2-d3/a2
FILE_OFFSET_REGS       REG     d2-d4/a2 *inconsistent naming for size purposes (consistent too long)

*---
* Write a buffer to a file
*
* a1 - start address of filename
* a2 - start address of buffer to write
* d1.l - size of buffer to write
*
* out d0.b - 0 for success, non-zero for failure
*---
file_Write:
        movem.l FILE_NON_VOLATILE_REGS, -(sp)
        move.l d1, d2 *we need to move this now, since the next call will overwrite it
        * open the file
        *filename already in a1
        move.b  #FILE_TASK_FCREATE, d0
        trap    #15
        tst.w   d0
        bne     .error
        * d1 contains file handle
        
        * write the words
        move.b  #FILE_TASK_FWRITE, d0
        move.l  a2, a1
        trap    #15
        tst.w   d0
        bne     .error
        
        * close the file
        move.l  #FILE_TASK_FCLOSE, d0
        trap    #15
        tst.w   d0
        beq     .done

.error
        movem.l (sp)+, FILE_NON_VOLATILE_REGS
        rts
              
.done
        movem.l (sp)+, FILE_NON_VOLATILE_REGS
        rts

*---
* Read a buffer from a file
*
* a1 - start address of filename
* a2 - start address of buffer to read
* d1.l - size of buffer to read
*
* out d1.l - number of bytes read
* out d0.b - 0 for success, non-zero for failure
*---
file_Read:
        movem.l FILE_NON_VOLATILE_REGS, -(sp)
        move.l d1, d2 *the file open will overwrite this, and we need it in d2 later anyway
        move.l d1, d3 *keep number of bytes to read for after the read too, so we can compare
        move.b #FILE_TASK_FOPEN, d0 *we don't want to use create (don't read non existing file)
        trap #15
        tst.w d0
        bne .done *nonzero d0 will be our error code anyway, so exit
        *if we got an error here, the number of bytes read is pretty vacuous

        move.l a2, a1 *put buffer to read to in right place
        move.b #FILE_TASK_FREAD, d0
        trap #15
        cmp.w #1, d0 *check for eof
        bne .dontCheckEOF *if it's not EOF just return whatever error we got
        cmp.l d2, d3 *this EOF thing seems to not be happening when i test, but i might just not understand it
        bne .done *if they weren't equal, EOF was a genuine error
        move.w #0, d0 *if they are equal, it's not an error
        
.dontCheckEOF
        move.l  #FILE_TASK_FCLOSE, d0 * close the file
        trap    #15
        move.l d2, d1 *get our return right
        
.done
        movem.l (sp)+, FILE_NON_VOLATILE_REGS
        rts

*---
* Read a buffer from a file
*
* a1 - start address of filename
* a2 - start address of buffer to read
* d1.l - size of buffer to read
* d0.l - offset for where to read
*
* out d1.l - number of bytes read
* out d0.b - 0 for success, non-zero for failure
*---
file_Read_Offset:
        movem.l FILE_OFFSET_REGS, -(sp)
        move.l d1, d2 *the file open will overwrite this, and we need it in d2 later anyway
        move.l d1, d3 *keep number of bytes to read for after the read too, so we can compare
        move.l d0, d4 *keep offset
        move.b #FILE_TASK_FOPEN, d0 *we don't want to use create (don't read non existing file)
        trap #15
        tst.w d0
        bne .done *nonzero d0 will be our error code anyway, so exit
        *if we got an error here, the number of bytes read is pretty vacuous

        move.l d4, d2 *get offset in the right place
        move.b #FILE_TASK_POSITION, d0
        trap #15 *offset where we begin our read from
        tst.w d0
        bne .done
        
        move.l a2, a1 *put buffer to read to in right place
        move.l d3, d2 *get number of bytes to read back in the right place
        move.b #FILE_TASK_FREAD, d0
        trap #15
        cmp.w #1, d0 *check for eof
        bne .dontCheckEOF *if it's not EOF just return whatever error we got
        cmp.l d2, d3 *this EOF thing seems to not be happening when i test, but i might just not understand it
        bne .done *if they weren't equal, EOF was a genuine error
        move.w #0, d0 *if they are equal, it's not an error
.dontCheckEOF
        move.l  #FILE_TASK_FCLOSE, d0 * close the file
        trap    #15
        move.l d2, d1 *get our return right
        
        * close the file

.done
        movem.l (sp)+, FILE_OFFSET_REGS
        rts
    








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

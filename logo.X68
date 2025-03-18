LOGO_INIT_OFF_X    EQU 250
LOGO_INIT_OFF_Y    EQU 270

LOGO_GRID_OFF         EQU 30

TASK_SET_PEN          EQU 80
TASK_DRAW_PIXEL       EQU 82
TASK_DRAW_LINE        EQU 84

RED                   EQU $000000FF
WHITE                 EQU $00FFFFFF

logo_Draw:
    move.b #TASK_SET_PEN, d0
    move.l #RED, d1 
    trap #15
    
    move.w #LOGO_INIT_OFF_X, d1
    move.w #LOGO_INIT_OFF_Y, d2
    move.w d1, d3
    move.w d2, d4
    *initial point setup
    
    add.w #(3*LOGO_GRID_OFF), d3
    sub.w #(9*LOGO_GRID_OFF), d4
    *big red line
    
    move.b #TASK_DRAW_LINE, d0
    trap #15
    *draw missile trail
    
    move.b #TASK_SET_PEN, d0
    move.l #WHITE, d1
    trap #15 *set to white
    
    move.b #TASK_DRAW_PIXEL, d0
    move.w #LOGO_INIT_OFF_X, d1
    trap #15 *y already in d2
    
    move.b #TASK_DRAW_LINE, d0 *rest of logo is vector
    
    add.w #LOGO_GRID_OFF+1, d1
    sub.w #(3*LOGO_GRID_OFF+1), d2
    *top of first line for the M, not the trail
    
    move.w d1, d3
    move.w d2, d4 *reset pixel positions
    
    add.w #(LOGO_GRID_OFF/2), d3
    add.w #LOGO_GRID_OFF*2, d4
    *the main pattern from here is drawing a line, moving one endpoint to the other, then moving that other point
    trap #15
    
    move.w d3, d1
    move.w d4, d2
    
    add.w #(LOGO_GRID_OFF/2), d1
    sub.w #(LOGO_GRID_OFF*2), d2
    
    trap #15
    
    move.w d1, d3
    move.w d2, d4
    
    add.w #LOGO_GRID_OFF, d3
    add.w #(3*LOGO_GRID_OFF), d4
    
    trap #15
    
    move.w #LOGO_INIT_OFF_X, d1
    move.w #LOGO_INIT_OFF_Y, d2
    
    add.w #(2*LOGO_GRID_OFF), d1
    
    move.w d1, d3
    move.w d2, d4 *initial position for the C
    
    sub.w #LOGO_GRID_OFF, d4
    
    trap #15
    
    move.w d4, d2 *d3 and d1 already the same
    
    add.w #LOGO_GRID_OFF, d1
    sub.w #LOGO_GRID_OFF, d2
    
    trap #15
    
    move.w d1, d3
    move.w d2, d4
    
    add.w #LOGO_GRID_OFF, d3
    
    trap #15
    
    move.w #LOGO_INIT_OFF_X, d1 *have to rest because of where we start the C can't do it in 1
    move.w #LOGO_INIT_OFF_Y, d2
    
    add.w #(2*LOGO_GRID_OFF), d1
    
    move.w d1, d3
    move.w d2, d4 *initial position for the C
    
    *add.w #LOGO_GRID_OFF, d4
    
    move.w d4, d2
    
    add.w #LOGO_GRID_OFF, d3
    add.w #LOGO_GRID_OFF, d4
    
    trap #15
    
    move.w d3, d1
    move.w d4, d2
    
    add.w #LOGO_GRID_OFF, d1
    
    trap #15
    
    bsr swapBuffers
    
    rts
    

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

CITY_Y   EQU 386

CityLocations
CITY_A_X dc.w 107
CITY_B_X dc.w 200
CITY_C_X dc.w 436
CITY_D_X dc.w 535

CITY_RADIUS EQU 22 *storing it like this for circular collision checking
*makes drawing them a little more involved, but oh well

CITY_GRAY EQU $006F6F6F

CITY_ALIVE_MASK EQU $000F *1 bit set in the lower 4 values - all 4 cities alive

TASK_PEN_COLOR  EQU 80
TASK_FILL_COLOR EQU 81
TASK_DRAW_RECT  EQU 87

CITY_LOOP_COUNTER EQU 3 *if there are 4 cities, with dbf loop counter should be 3

city_Init:
    bsr city_Draw
    move.w #CITY_ALIVE_MASK, CityMask
    rts
    
city_Draw
.LOAD_REGS REG d2-d6/a2
    movem.l .LOAD_REGS, -(sp)
    
    move.b #TASK_PEN_COLOR, d0
    move.l #CITY_GRAY, d1
    trap #15
    
    move.b #TASK_FILL_COLOR, d0
    trap #15
    *set up the color to draw the cities
    
    move.b #TASK_DRAW_RECT, d0
    
    move.w #CITY_Y, d2
    move.w d2, d4
    sub.w #CITY_RADIUS, d2
    add.w #CITY_RADIUS, d4
    *Y values are constant, so set it up once at the beginning
    
    move.w #CITY_LOOP_COUNTER, d5 *loop counter
    move.w (CityMask), d6 *get the mask for living cities
    lea CityLocations, a2 *get the location array
    
.drawLoop
    btst d5, d6
    beq .increment *if the bit is 0, don't draw the city
    lsl #1, d5 *multiply by 2 to use as a word index
    move.w (a2, d5), d1 
    lsr #1, d5 *restore d5 
    move.w d1, d3
    sub.w #CITY_RADIUS, d1
    add.w #CITY_RADIUS, d3 *move x positions
    trap #15    
.increment
    dbf d5, .drawLoop
    
    movem.l (sp)+, .LOAD_REGS
    rts
    
    
CityMask dcb.w 1,$000F *at the beginning, all cities are alive, so all 4 live bits are set
*word for alignment reasons


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

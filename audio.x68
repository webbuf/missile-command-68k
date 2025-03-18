DIRECT_X_LOAD EQU 74
DIRECT_X_PLAY EQU 75

AUDIO_GAME_OVER EQU 1
AUDIO_EXPLODE   EQU 2
AUDIO_NO_AMMO   EQU 3
AUDIO_JINGLE    EQU 4
AUDIO_SHOOT     EQU 5

audio_Init:
    move.b #DIRECT_X_LOAD, d0
    move.b #AUDIO_GAME_OVER, d1
    lea GameOverWAV, a1
    trap #15
    
    move.b #DIRECT_X_LOAD, d0
    move.b #AUDIO_EXPLODE, d1
    lea ExplodeWAV, a1
    trap #15
    
    move.b #DIRECT_X_LOAD, d0
    move.b #AUDIO_NO_AMMO, d1
    lea NoAmmoWAV, a1
    trap #15
    
    move.b #DIRECT_X_LOAD, d0
    move.b #AUDIO_JINGLE, d1
    lea JingleWAV, a1
    trap #15
    
    move.b #DIRECT_X_LOAD, d0
    move.b #AUDIO_SHOOT, d1
    lea ShootWAV, a1
    trap #15
    
    rts *just loading each audio file into diret X memory
audio_PlayGameOver:
    move.b #DIRECT_X_PLAY, d0
    move.b #AUDIO_GAME_OVER, d1
    trap #15
    rts
    
audio_PlayExplode:
    move.b #DIRECT_X_PLAY, d0
    move.b #AUDIO_EXPLODE, d1
    trap #15
    rts
    
audio_PlayNoAmmo:
    move.b #DIRECT_X_PLAY, d0
    move.b #AUDIO_NO_AMMO, d1
    trap #15
    rts   
 
audio_PlayJingle:
    move.b #DIRECT_X_PLAY, d0
    move.b #AUDIO_JINGLE, d1
    trap #15
    rts
    
audio_PlayShoot:
    move.b #DIRECT_X_PLAY, d0
    move.b #AUDIO_SHOOT, d1
    trap #15
    rts
    
*doing a separate subroutine for each audio call is messy, but I only have 5 sounds and this is way easier for me to read than juggling around registers even more

GameOverWAV     dc.b 'Audio/gameOver.wav',0
ExplodeWAV      dc.b 'Audio/kablooey.wav',0
NoAmmoWAV       dc.b 'Audio/noAmmo.wav',0
JingleWAV       dc.b 'Audio/openJingle.wav',0
ShootWAV        dc.b 'Audio/pew.wav',0
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

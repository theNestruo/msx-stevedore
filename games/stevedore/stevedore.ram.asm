
;
; =============================================================================
;	Game vars (user vars)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Global vars (i.e.: initialized only once)
globals:

.chapters:
	rb	1 ; 000s0nnn: secret chapter and number of chapters unlocked
.flags:
	rb	1 ; if the star was picked in chapter 00054321 (bitmap)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game vars (i.e.: vars from start to game over)
game:

.lives:
	rb	1
.chapter:
	rb	1 ; convenience variable to store the current chapter
.stage:
	rb	1
.stage_bcd:
	rb	1 ; (2 BCD digits)
.item_counter:
	rb	1 ; 000s0fff: star and fruits picked up during the chapter
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stage vars (i.e.: vars inside the main game loop)
stage:

; The flags the define the state of the stage
.flags:
	rb	1
; Number of consecutive frames the player has been pushing an object
player.pushing:
	rb	1
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Main menu vars
menu:

; NAMTBL buffer pointer to start printing stage select options
.namtbl_buffer_origin:
	rw	1
; Coordinates of the sprite depending on the selected stage
.player_0_table:
	rb	2 ; Warehouse (tutorial)
	rb	2 ; Lighthouse
	rb	2 ; Ship
	rb	2 ; Jungle
	rb	2 ; Volcano
	rb	2 ; Temple
; The actual selection
.selected_chapter:
	rb	1
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Other vars
input.trigger_b_framecounter:
	rb	1
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Physical edition extras vars
jukebox.current_song:
	rb	1
jukebox.loop_counter:
	rb	1
; -----------------------------------------------------------------------------

; EOF

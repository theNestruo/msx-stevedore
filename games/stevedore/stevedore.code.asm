
; -----------------------------------------------------------------------------
; Initial number of lives
	LIVES_0:		equ 5

; Number of frames required to actually push an object
	FRAMES_TO_PUSH:		equ 16

; Number of frames to detect trigger B hold
	FRAMES_TO_TRIGGER_B:	equ 150 ; (~3 seconds)

; Number of stages per chapter
	CHAPTERS:		equ 6
	STAGES_PER_CHAPTER:	equ 6
	SECRET_CHAPTER:		equ CHAPTERS

; Tutorial stages
	FIRST_TUTORIAL_STAGE:	equ CHAPTERS * STAGES_PER_CHAPTER
	LAST_TUTORIAL_STAGE:	equ FIRST_TUTORIAL_STAGE + 6

; The flags the define the state of the stage
	BIT_STAGE_KEY:		equ 0 ; Key picked up
	BIT_STAGE_STAR:		equ 1 ; Star picked up
	BIT_STAGE_FRUIT:	equ 2 ; Fruit picked up

; The flags the define the state of the chapter
	BIT_CHAPTER_STAR:	equ 4 ; Star picked up
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	Game code and data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Cartridge entry point
INIT:
; Initializes global vars
	IFDEF DEBUG_CHAPTER
		ld	a, DEBUG_CHAPTER
		ld	[globals.chapters], a
	ELSE
		ld	a, $01
		ld	[globals.chapters], a
	ENDIF ; IFDEF DEBUG_CHAPTER
	; xor	a
	; ld	[globals.flags], a ; zero-ed by initialization

; Sprite pattern table (SPRTBL)
	ld	hl, SPRTBL_PACKED
	ld	de, SPRTBL
	ld	b, SPRTBL_SIZE >> 8 ; (c already 0 because of previous ldir)
	call	UNPACK_LDIRVM

; Initializes charsets
	call	SET_DEFAULT_CHARSET
	call	INIT_DYNAMIC_CHARSET

	IFDEF DEBUG_ENDING
		IF DEBUG_ENDING = 1
			jp	STAGE_OVER.DEBUG_TUTORIAL_OVER
		ENDIF
		IF DEBUG_ENDING = 2
			ld	hl, game.chapter
			ld	[hl], SECRET_CHAPTER -1
			call	SET_DOORS_CHARSET.CLOSED
			jp	CHAPTER_OVER
		ENDIF
		IF DEBUG_ENDING = 3
			ld	hl, globals.flags
			ld	[hl], $1f ; (all stars)
			ld	hl, game.chapter
			ld	[hl], SECRET_CHAPTER -1
			inc	hl ; game.stage
			ld	[hl], 30
			inc	hl ; game.stage_bcd
			ld	[hl], $30
			call	SET_DOORS_CHARSET.CLOSED
			jp	CHAPTER_OVER
		ENDIF
		IF DEBUG_ENDING = 4
			jp	GOOD_ENDING
		ENDIF
	ENDIF ; IFDEF DEBUG_ENDING

	IFDEF DEBUG_CHAPTER
	IFDEF DEBUG_STAGE
	; Loads debug stage
		ld	hl, game.chapter
		ld	[hl], DEBUG_CHAPTER
		inc	hl ; hl = game.stage
		ld	[hl], (DEBUG_CHAPTER -1) *STAGES_PER_CHAPTER + (DEBUG_STAGE -1)
	; Chapter
		jp	NEW_CHAPTER
	ENDIF ; IFDEF DEBUG_STAGE
	ENDIF ; IFDEF DEBUG_CHAPTER

	IFDEF DEBUG_NO_INTRO
		jp	MAIN_MENU
	ENDIF ; IFDEF DEBUG_NO_INTRO

; Intro sequence
	call	INTRO
	jp	z, GAME_LOOP ; play tutorial
; Skip tutorial: go to main menu
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Main menu
MAIN_MENU:
; Fade out
	call	DISSCR_FADE_OUT
.FADE_OUT_OK:

; Prepares default charset for stage select screen and loads the title charset at bank #0
	call	SET_DEFAULT_CHARSET
	call	INIT_DYNAMIC_CHARSET
	call	SET_TITLE_CHARSET
; Plays main theme
	ld	a, CFG_SONG_MAIN_THEME
	call	PLAY_SONG
.CHARSET_AND_THEME_OK:

; Shows the title screen
	call	CLS_NAMTBL
	call	CLS_SPRATR
	call	PRINT_TITLE_BLOCK

; Fade in and "push space key"
	call	ENASCR_FADE_IN
	call	PUSH_SPACE_KEY
	jp	nz, INPUT_PASSWORD ; SELECT key or trigger B

	IFDEF DEBUG_JUKEBOX
		jp	JUKEBOX_SCREEN
	ENDIF ; IFDEF DEBUG_JUKEBOX

; Checks "W" (for Wonder) key
	ld	a, $05 ; a = $05 ; Z Y X W V U T S
	call	SNSMAT
	bit	4, a
	jp	z, JUKEBOX_SCREEN ; yes
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; "STAGE SELECT" screen
STAGE_SELECT:
	call	DISSCR_FADE_OUT
; Shows the "stage select" screen
	call	STAGE_SELECT_SCREEN
	call	ENASCR_FADE_IN
	call	STAGE_SELECT_LOOP
	jp	z, INPUT_PASSWORD ; Shows the "input password" screen
; Accepts selection
	call	PLAYER_DISAPPEARING.ANIMATION
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New game entry point
NEW_GAME:
	call	REPLAYER.STOP ; (required to unpack default charset)
	call	DISSCR_FADE_OUT

; Restores default charset
	call	SET_DEFAULT_CHARSET
	call	INIT_DYNAMIC_CHARSET

; Initializes game vars
	ld	de, game.lives
	ld	a, LIVES_0
	ld	[de], a
	inc	de

; Initializes chapter, stage and stage_bcd
	ld	hl, menu.selected_chapter
	ld	a, [hl] ; a = 0..5 or 6 (secret chapter)
	ldi	; .chapter
	ld	hl, NEW_CHAPTER_STAGE_TABLE
	call	ADD_HL_2A
	ldi	; .stage
	ldi	; .stage_bcd
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New chapter
NEW_CHAPTER:
; Plays chapter song, looped
	call	PLAY_CHAPTER_SONG

.SONG_OK:
; Resets the item counter of the chapter
	xor	a
	ld	[game.item_counter], a
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; New stage / new life entry point
NEW_STAGE:
; Is a tutorial stage
	ld	a, [game.stage]
	cp	FIRST_TUTORIAL_STAGE
	call	c, STAGE_NN_SCREEN ; no: prints "STAGE NN" screen

; Loads and initializes the current stage
	call	LOAD_AND_INIT_CURRENT_STAGE
	call	ENASCR_FADE_IN
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop
GAME_LOOP:
; Executes one in-game frame
	call	IN_GAME_FRAME

IFDEF DEBUG_TRAINER_SKIP
; Checks SELECT key
	ld	a, [input.edge]
	bit	BIT_BUTTON_SELECT, a
	jp	nz, STAGE_OVER
ENDIF ; IFDEF DEBUG_TRAINER_SKIP

; Checks exit condition
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	jr	z, GAME_LOOP ; no
; yes: checks if the player is dead
	and	$ff XOR FLAGS_STATE ; (removes state modifiers)
	cp	PLAYER_STATE_FINISH
	jp	z, STAGE_OVER ; no
	; jr	PLAYER_OVER ; yes; (falls through)
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Ends the in-game loop with the life loss logic
PLAYER_OVER:
; Keeps the action for two seconds
	ld	a, [frame_rate]
	add	a
	ld	b, a
.LOOP:
	push	bc ; preserves frame counter
	call	IN_GAME_FRAME
	pop	bc ; restores frame counter
	djnz	.LOOP
; Fade out
	call	DISSCR_FADE_OUT

; Is START button or B trigger key still pressed?
	ld	a, [input.level]
	and	((1 << BIT_BUTTON_START) OR (1 << BIT_TRIGGER_B))
	jp	nz, GAME_OVER ; yes: go to main menu

; Is it a tutorial stage?
	ld	a, [game.stage]
	cp	FIRST_TUTORIAL_STAGE
	jp	nc, NEW_STAGE ; yes: re-enter current stage, no life lost

; Life loss logic
	ld	hl, game.lives
	xor	a
	cp	[hl]
	jp	z, GAME_OVER ; no lives left
IFDEF DEBUG_TRAINER_LIVES
ELSE
	dec	[hl]
ENDIF ; IFDEF DEBUG_TRAINER_LIVES

; Re-enter current stage
	jp	NEW_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; New chapter data
NEW_CHAPTER_STAGE_TABLE:
	;	.stage,	.stage_bcd
	db	FIRST_TUTORIAL_STAGE, $00 ; Warehouse (tutorial)
	db	 0, $01 ; Lighthouse
	db	 6, $07 ; Ship
	db	12, $13 ; Jungle
	db	18, $19 ; Volcano
	db	24, $25 ; Temple
	db	30, $31 ; Secret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Replayer-related custom routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Plays the current chapter song
PLAY_CHAPTER_SONG:
	ld	a, [game.chapter]
	; jr	PLAY_SONG ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------

; Starts the replayer
; param a: liiiiiii, where l (MSB) is the loop flag (0 = loop),
;	and iiiiiii is the 0-based song index (0, 1, 2...)
PLAY_SONG:
; Default routine (unpack then replay)
	cp	5
	jp	nz, REPLAYER.PLAY
; Special case: temple song does not fit into unpack buffer
	ld	hl, .TEMPLE_UNPACKED
	jp	REPLAYER.PLAY_UNPACKED

.TEMPLE_UNPACKED:
	incbin	"games/stevedore/sfx/05-chapter-temple.pt3.hl"
; -----------------------------------------------------------------------------


;
; =============================================================================
;	Intro sequence
; =============================================================================
;

; -----------------------------------------------------------------------------
; Intro sequence
; ret z: SPACE key or trigger A (play tutorial)
; ret nz: SELECT key or trigger B (skip tutorial)
INTRO:
; Loads intro screen into NAMTBL buffer
	ld	hl, INTRO_NAMTBL_PACKED
	ld	de, namtbl_buffer
	call	UNPACK
; Mimics in-game loop preamble and initialization
	call	INIT_STAGE
	call	PUT_PLAYER_SPRITE
; Fade in
	call	ENASCR_FADE_IN
	call	LDIRVM_SPRATR

; Intro sequence #0: courtesy pause
	ld	a, [frame_rate] ; four seconds
	add	a
	add	a
	ld	b, a
.TRIGGER_LOOP:
	halt
	ld	a, [input.edge]
	bit	BIT_TRIGGER_A, a
	jp	nz, .CONTINUE_INTRO ; SPACE key or trigger A: play tutorial
	and	$60 ; (BIT_TRIGGER_B OR BIT_BUTTON_SELECT)
	ret	nz ; SELECT key or trigger B: skip tutorial
	djnz	.TRIGGER_LOOP

; Intro sequence #1: "Push space key"

	call	PUSH_SPACE_KEY
	ret	nz ; SELECT key or trigger B: skip tutorial
.CONTINUE_INTRO:
; SPACE key or trigger A: play tutorial

; Intro sequence #2: the fall

; Plays "crash" sound
	ld	a, CFG_SOUND_INTRO_CRASH
	ld	c, 7 ; default priority
	call	ayFX_INIT

; Updates screen 1/2: broken bridge
	ld	hl, .BROKEN_BRIDGE_CHARS
	ld	de, namtbl_buffer + 3 * SCR_WIDTH + 15
	ldi	; 3 bytes
	ldi
	ldi
; Updates screen 2/2: floor
	ld	hl, .FLOOR_CHARS
	ld	de, namtbl_buffer + 22 * SCR_WIDTH + 12
	ld	bc, 9 ; 9 bytes
	ldir
; Sets the player falling
	call	SET_PLAYER_FALLING
	call	PUT_PLAYER_SPRITE
; Synchronization (halt) and blit buffers to VRAM
	halt
	call	LDIRVM_NAMTBL
	call	LDIRVM_SPRATR

.FALL_LOOP:
; Mimics game logic, synchronization (halt) and blit buffer to VRAM
	xor	a ; (prevents user control)
	ld	[input.level], a
	call	UPDATE_PLAYER
	call	PUT_PLAYER_SPRITE
	halt
	call	LDIRVM_SPRATR
; Checks exit condition
	ld	a, [player.state]
	and	$ff XOR FLAGS_STATE
	cp	PLAYER_STATE_AIR
	jr	z, .FALL_LOOP ; no

; Intro sequence #3: the darkness

; Plays "land" sound
	ld	a, CFG_SOUND_INTRO_LAND
	ld	c, 7 ; default priority
	call	ayFX_INIT

; Sets the player crashed (sprite only)
	ld	a, PLAYER_SPRITE_KO_PATTERN
	call	PUT_PLAYER_SPRITE.PATTERN
	call	LDIRVM_SPRATR

; Slow fade out
	ld	hl, NAMTBL
	ld	b, 16 ; 16 lines
.LOOP_2:
	push	bc ; preserves counter
; Synchronization (halt)
	halt	; (slowly: 3 frames)
	halt
	halt
; Erases one line in VRAM
	ld	bc, SCR_WIDTH
	push	bc ; preserves SCR_WIDTH
	push	hl ; preserves line
	ld	a, CHAR_EMPTY
	call	FILVRM
	pop	hl ; restores line
	pop	bc ; restores SCR_WIDTH
; Moves one line down
	add	hl, bc
	pop	bc ; restores counter
	djnz	.LOOP_2

; Intro sequence #4: the awakening

; Loads first tutorial stage screen
	ld	a, FIRST_TUTORIAL_STAGE
	ld	[game.stage], a
	call	LOAD_AND_INIT_CURRENT_STAGE

; Pauses until trigger
	call	WAIT_TRIGGER

; Plays song #0 (warehouse), looped
	xor	a
	call	PLAY_SONG

; Awakens the player, synchronization (halt) and blit buffer to VRAM
	call	PUT_PLAYER_SPRITE
	halt
	call	LDIRVM_SPRATR
; Fade in-out with the playable intro screen and enter the game
	call	LDIRVM_NAMTBL_FADE_INOUT.KEEP_SPRITES
; ret z
	xor	a
	ret

; Intro sequence data
.BROKEN_BRIDGE_CHARS:
	db	$ca, CHAR_EMPTY, $c8 ; 3 bytes
.FLOOR_CHARS:
	db	$25, $24, $25, $5c, $84, $85, $11, $24, $25 ; 9 bytes
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Tutorial over and title screen
; =============================================================================
;

; -----------------------------------------------------------------------------
; Tutorial over intermission screens
TUTORIAL_OVER_SCREEN:
; Loads the title charset at bank #0
	call	SET_TITLE_CHARSET
; Plays main theme
	ld	a, CFG_SONG_CHAPTER_OVER
	call	PLAY_SONG

; Prepares the "tutorial over" screen
	ld	hl, .PLAYER_0
	call	INIT_CHAPTER_OVER_SCREEN
; Prints floor
	ld	hl, STAGE_SELECT_SCREEN.FLOOR_CHARS
	ld	de, namtbl_buffer + 16 * SCR_WIDTH + 12
	ld	bc, 8 ; 8 bytes
	ldir
; Fade in, waits, fade out
	call	CHAPTER_OVER_APPEARING_ANIMATION
	call	WAIT_FOUR_SECONDS_ANIMATION
	call	PLAYER_DISAPPEARING.ANIMATION
	call	WAIT_TWO_SECONDS

; Plays main theme
	ld	a, CFG_SONG_MAIN_THEME
	call	PLAY_SONG
	call	WAIT_TWO_SECONDS

; "AND SO THE ADVENTURE BEGINS..."
	ld	hl, .TXT
	ld	de, namtbl_buffer + 21 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT
; Fade in, waits
	call	LDIRVM_NAMTBL_FADE_INOUT
	call	WAIT_TWO_SECONDS

; Clears the "tutorial over" screen, keeps "AND SO THE ADVENTURE BEGINS..."
	ld	hl, namtbl_buffer + 2 *SCR_WIDTH
	ld	de, namtbl_buffer + 2 *SCR_WIDTH + 1
	ld	bc, 18 * SCR_WIDTH
	ld	[hl], $20 ; " " ASCII
	ldir
; Fade in, waits
	call	LDIRVM_NAMTBL_FADE_INOUT
	call	WAIT_TWO_SECONDS
	call	DISSCR_FADE_OUT
	call	WAIT_FOUR_SECONDS

; Shows the title screen, fade in
	call	CLS_NAMTBL
	call	PRINT_TITLE_BLOCK
	jp	ENASCR_FADE_IN

; Initial player vars
.PLAYER_0:
	db	128, 128		; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index

; Literals
.TXT:
	db	"AND SO THE ADVENTURE BEGINS", CHAR_DOT, CHAR_DOT, CHAR_DOT, $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the title screen
PRINT_TITLE_BLOCK:
; Is a japanese computer?
	ld	hl, [MSXID1]
	ld	a, l	; MSXID1: 0 = 60Hz, 0 = Y-M-D, 0 = Japanese character set
	or	h	; MSXID2: 0 = Japanese basic version, 0 = Japanese keyboard type
; Points to the proper NAMTBL source
	ld	hl, .JP_NAMTBL
	jr	z, .HL_OK
	ld	hl, .EN_NAMTBL
.HL_OK:
; Prints the title
	ld	de, namtbl_buffer + 3 *SCR_WIDTH + .NAMTBL_CENTER
	ld	bc, .NAMTBL_HEIGHT << 8 + .NAMTBL_WIDTH
	call	PRINT_BLOCK
; Prints the copyright
	ld	hl, .COPY_NAMTBL
	ld	de, namtbl_buffer + 7 *SCR_WIDTH + .NAMTBL_CENTER
	ld	bc, 1 << 8 + .NAMTBL_WIDTH
	jp	PRINT_BLOCK

.NAMTBL:
	incbin	"games/stevedore/gfx/title.png.nam"
	.NAMTBL_WIDTH:	equ 20
	.NAMTBL_HEIGHT:	equ 3
	.NAMTBL_SIZE:	equ .NAMTBL_WIDTH * .NAMTBL_HEIGHT
	.EN_NAMTBL:	equ .NAMTBL + (0 *.NAMTBL_SIZE)
	.JP_NAMTBL:	equ .NAMTBL + (1 *.NAMTBL_SIZE)
	.COPY_NAMTBL:	equ .NAMTBL + (2 *.NAMTBL_SIZE)
	.NAMTBL_CENTER:	equ (SCR_WIDTH - .NAMTBL_WIDTH) /2
; -----------------------------------------------------------------------------

;
; =============================================================================
;	"STAGE SELECT" screen
; =============================================================================
;

; -----------------------------------------------------------------------------
; "STAGE SELECT" screen initialization
STAGE_SELECT_SCREEN:
; Prepares the "STAGE SELECT" screen
	call	CLS_NAMTBL
	call	CLS_SPRATR

; Initializes the selection with the latest chapter
	ld	a, [globals.chapters]
	and	$07 ; 000s0nnn: secret chapter and number of chapters unlocked
	ld	[menu.selected_chapter], a

; Initializes the menu values from the look-up-table
	ld	hl, .MENU_0
	ld	bc, .MENU_0_SIZE
	ld	a, [globals.chapters]
	and	$07 ; 000s0nnn: secret chapter and number of chapters unlocked
.LOCATE_TABLE_LOOP:
; Is the right table entry?
	dec	a
	jr	z, .HL_OK ; yes
; no: skips to the next table entry
	add	hl, bc
	jr	.LOCATE_TABLE_LOOP
.HL_OK:
	ld	de, menu
	ldir

; Prints "STAGE SELECT"
	ld	hl, .TXT
	ld	de, namtbl_buffer + 3 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT

; Prints the blocks depending on globals.chapters
	ld	hl, .NAMTBL
	ld	de, [menu.namtbl_buffer_origin]
	ld	a, [globals.chapters]
	and	$07 ; 000s0nnn: secret chapter and number of chapters unlocked
	ld	b, a
.PRINT_BLOCK_LOOP:
	push	bc ; preserves counter
	push	de ; preserves coordinates
; Prints the block
	ld	bc, .HEIGHT << 8 + .WIDTH
	call	PRINT_BLOCK
; Advances to the next block
	pop	de ; restores coordinates
	ex	de, hl ; coordinates += (6,0)
	ld	bc, 6
	add	hl, bc
	ex	de, hl
	pop	bc ; restores counter
	djnz	.PRINT_BLOCK_LOOP

; Prints the tutorial "block"
	ld	hl, .FLOOR_CHARS
	ld	de, namtbl_buffer + 20 * SCR_WIDTH + 12
	ld	bc, 8 ; 8 bytes
	ldir

; Initializes the sprite attribute table (SPRATR) and the player
	ld	hl, .PLAYER_0
	ld	de, player
	ld	bc, .PLAYER_0_SIZE
	ldir
	ret

; Data
.MENU_0:
; 1st chapter open
; .namtbl_buffer_origin
	dw	namtbl_buffer + 9 * SCR_WIDTH + 14
; .player_0_table
	db	160, 128 ; Warehouse (tutorial)
	db	112, 128 ; Lighthouse
	db	0, 0
	db	0, 0
	db	0, 0
	db	0, 0
	.MENU_0_SIZE:	equ $ - .MENU_0
; 2nd chapter open
	dw	namtbl_buffer + 9 * SCR_WIDTH + 11
	db	160, 128 ; Warehouse (tutorial)
	db	112, 104 ; Lighthouse
	db	112, 152 ; Ship
	db	0, 0
	db	0, 0
	db	0, 0
; 3rd chapter open
	dw	namtbl_buffer + 9 * SCR_WIDTH + 8
	db	160, 128 ; Warehouse (tutorial)
	db	112,  80 ; Lighthouse
	db	112, 128 ; Ship
	db	112, 176 ; Jungle
	db	0, 0
	db	0, 0
; 4th chapter open
	dw	namtbl_buffer + 9 * SCR_WIDTH + 5
	db	160, 128 ; Warehouse (tutorial)
	db	112,  56 ; Lighthouse
	db	112, 104 ; Ship
	db	112, 152 ; Jungle
	db	112, 200 ; Volcano
	db	0, 0
; All chapters open
	dw	namtbl_buffer + 9 * SCR_WIDTH + 2
	db	160, 128 ; Warehouse (tutorial)
	db	112,  32 ; Lighthouse
	db	112,  80 ; Ship
	db	112, 128 ; Jungle
	db	112, 176 ; Volcano
	db	112, 224 ; Temple

.TXT:
	db	"STAGE SELECT", $00

.NAMTBL:
	incbin	"games/stevedore/maps/stage_select.tmx.bin"
	.WIDTH:		equ 4
	.HEIGHT:	equ 8

.FLOOR_CHARS:
	db	$25, $24, $25, $84, $85, $11, $24, $25 ; 8 bytes

.PLAYER_0:
	db	SPAT_OB, 0		; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
	.PLAYER_0_SIZE:	equ $ - .PLAYER_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "STAGE SELECT" screen routine
; ret z: Switch to "INPUT PASSWORD" screen
; ret nz: Accept selection
STAGE_SELECT_LOOP:
; Player appearing
	call	UPDATE_MENU_PLAYER
	call	PLAYER_APPEARING.ANIMATION

; Prints "LIGHTHOUSE" and similar texts
.PRINT_SELECTED_CHAPTER_NAME:
	ld	hl, .TXT
	ld	a, [menu.selected_chapter]
; "LIGHTHOUSE" and similar texts
	call	GET_TEXT
	ld	de, namtbl_buffer + 5 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT
	call	LDIRVM_NAMTBL

.LOOP:
; Synchronization (halt), charset and player animations
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
	call	UPDATE_PLAYER_ANIMATION_CONDITIONAL

; Checks trigger
	ld	a, [input.edge]
	bit	BIT_TRIGGER_A, a
	ret	nz ; yes: accepts selection
; No: checks password key
	ld	a, [input.edge]
	cpl
	bit	BIT_BUTTON_SELECT, a
	ret	z ; yes: switches to "INPUT PASSWORD" screen
	bit	BIT_TRIGGER_B, a ; also checks trigger B
	ret	z ; yes: switches to "INPUT PASSWORD" screen
; No: checks other input

; Is the cursor at the tutorial?
	ld	a, [menu.selected_chapter]
	or	a ; (for the jr z)
	ld	a, [input.edge]
	jr	nz, .NO_TUTORIAL ; no
; yes: checks up only
	bit	BIT_STICK_UP, a
	jr	z, .LOOP ; no
; yes: sets the cursor at the leftmost position
	ld	a, 1
	jr	.MOVE_TO_A
.NO_TUTORIAL:

; Checks stick down
	bit	BIT_STICK_DOWN, a
	jr	z, .NO_DOWN ; no
; yes: sets the cursor at the tutorial
	xor	a
	jr	.MOVE_TO_A
.NO_DOWN:

; Checks stick left
	bit	BIT_STICK_LEFT, a
	jr	z, .NO_LEFT ; no
; yes: checks leftmost position
	ld	a, [menu.selected_chapter]
	dec	a
	jr	z, .LOOP ; yes: do nothing
; no: Moves the selection to the left
.MOVE_TO_A:
	ld	[menu.selected_chapter], a
	jr	.MOVED
.NO_LEFT:

; Checks stick right
	bit	BIT_STICK_RIGHT, a
	jr	z, .LOOP ; no
; yes: checks rightmost position
	ld	a, [globals.chapters]
	and	$07 ; 000s0nnn: secret chapter and number of chapters unlocked
	ld	hl, menu.selected_chapter
	cp	[hl]
	jr	z, .LOOP ; yes: do nothing
; no: Moves the selection to the right
	inc	[hl]

.MOVED:
; Removes the name of the selected chapter
	ld	hl, namtbl_buffer + 5 * SCR_WIDTH
	call	CLEAR_LINE
	halt
	call	LDIRVM_NAMTBL
; Out animation
	call	PLAYER_DISAPPEARING.ANIMATION
; In animation
	jr	STAGE_SELECT_LOOP

; "STAGE SELECT" screen routine data
.TXT:
	db	"TUTORIAL: WAREHOUSE",		$00
	db	"LIGHTHOUSE",			$00
	db	"ABANDONED SHIP",		$00
	db	"SHIPWRECK ISLAND",		$00 ; (jungle)
	db	"UNCANNY CAVE",			$00 ; (volcano)
	db	"ANCIENT TEMPLE RUINS",		$00 ; (temple)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the cursor (the player) in the stage select screen
UPDATE_MENU_PLAYER:
; Initializes the player sprite
	ld	hl, INIT_STAGE.SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
; Uses the table to convert index into coordinates
	ld	hl, menu.player_0_table
	ld	a, [menu.selected_chapter] ; a = 0..5
	call	ADD_HL_2A
; Sets the player coordinates
	ld	de, player
	ldi
	ldi
; Updates the player sprite
	call	.GET_PATTERN
	call	PUT_PLAYER_SPRITE.PATTERN
; Prepares the mask for appearing animation
	jp	PREPARE_MASK.APPEARING

.GET_PATTERN:
	ld	a, [menu.selected_chapter] ; a = 0..5
	ld	b, a ; preserves selected_chapter in b
; Is "tutorial: warehouse" selected?
	or	a
	ld	a, PLAYER_SPRITE_KO_PATTERN
	ret	z ; yes: player crashed
; no: Is the star picked in the selected chapter?
	ld	a, [globals.flags]
.LOOP:
	rrca	; extract bit to carry
	djnz	.LOOP
	ld	a, PLAYER_SPRITE_HAPPY_PATTERN
	ret	c ; yes: player happy
; no: default pattern ($00)
	xor	a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	"INPUT PASSWORD" screen
; =============================================================================
;

; -----------------------------------------------------------------------------
INPUT_PASSWORD:
; Shows the "input password" screen
	call	INPUT_PASSWORD_SCREEN
	call	ENASCR_FADE_IN
	call	RESET_KEYBOARD
	call	INPUT_PASSWORD_LOOP
	or	a
	jp	z, MAIN_MENU.CHARSET_AND_THEME_OK ; Invalid password: Shows the title screen
; Valid password
	and	$10 ; 000s0nnn: secret chapter and number of chapters unlocked
	jp	z, STAGE_SELECT ; Shows the "STAGE SELECT" screen
; Enters the secret chapter
	ld	a, SECRET_CHAPTER
	ld	[menu.selected_chapter], a
	jp	NEW_GAME
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "INPUT PASSWORD" screen initialization
INPUT_PASSWORD_SCREEN:
; Prepares the "INPUT PASSWORD" screen
	call	CLS_NAMTBL
	call	CLS_SPRATR

; Prints "INPUT PASSWORD:"
	ld	hl, TXT_INPUT_PASSWORD
	ld	de, namtbl_buffer + 10 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT

; Resets the password and prints the default password
	call	RESET_PASSWORD
	; jp	PRINT_PASSWORD ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the password in the NAMTBL buffer
PRINT_PASSWORD:
	ld	hl, password
	ld	de, namtbl_buffer + 12 * SCR_WIDTH + (SCR_WIDTH - PASSWORD_SIZE)/2
	ld	bc, PASSWORD_SIZE
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "INPUT PASSWORD" screen routine
; ret z: Invalid password. Switch to "TITLE SELECT" screen.
; ret nz: Valid password. Check bit 5 of a (=globals.chapters) for the secret chapter
INPUT_PASSWORD_LOOP:
; Initializes the cursor sprite
	ld	hl, .SPRATR_0
	ld	de, spratr_buffer
	ld	bc, .SPRATR_0_SIZE
	ldir

; Asks for the password
	call	ENTER_PASSWORD
; Is the password valid?
	jr	z, .VALID_PASSWORD ; yes
; no: plays "invalid password" sound
	ld	a, CFG_SOUND_PASSWORD_INVALID
	ld	c, 7 ; default priority
	call	ayFX_INIT
; ret z
	xor	a
	ret

.VALID_PASSWORD:
; Plays "valid password" sound
	ld	a, CFG_SOUND_PASSWORD_VALID
	ld	c, 7 ; default priority
	call	ayFX_INIT
; ret nz, and globals.chapters in a for the secret chapter
	ld	a, [globals.chapters]
	or	a
	ret

.SPRATR_0:
	db	12 *8 -4 -1, (SCR_WIDTH - PASSWORD_SIZE)/2 *8 -4, CURSOR_SPRITE_PATTERN, CURSOR_SPRITE_COLOR
	db	SPAT_END
	.SPRATR_0_SIZE:	equ	 $ - .SPRATR_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret z/nz: if the password is valid (z) or invalid (nz)
ENTER_PASSWORD:
; Starts with the first digit of the password
	ld	hl, password
.DIGIT_LOOP:
; Prints the cursor sprite
	push	hl ; preserves pointer
	call	LDIRVM_SPRATR
	pop	hl ; restores pointer
.DIGIT_INPUT_LOOP:
; Handles both direct (keyboard) and indirect (cursor/joystick) input
	halt
; Direct read from the keyboard matrix
	call	INPUT_HEXADECIMAL_DIGIT
	jr	nz, .ACCEPT_DIGIT ; yes
; no: Cursor/joystick indirect input
	ld	a, [input.edge]
; Checks stick up and down and trigger
	bit	BIT_STICK_UP, a
	jp	z, .NO_DIGIT_UP
; yes: up
	call	INC_HEXADECIMAL_DIGIT
	jr	.UPDATE_PASSWORD
.NO_DIGIT_UP:

	bit	BIT_STICK_DOWN, a
	jp	z, .NO_DIGIT_DOWN
; yes: down
	call	DEC_HEXADECIMAL_DIGIT
	jr	.UPDATE_PASSWORD
.NO_DIGIT_DOWN:

	bit	BIT_TRIGGER_A, a
	jr	z, .DIGIT_INPUT_LOOP ; no input
; yes: trigger
	; jr	.ACCEPT_DIGIT ; falls through
.ACCEPT_DIGIT:
	inc	hl
; Moves the cursor sprite
	ld	de, spratr_buffer + 1
	ld	a, [de]
	add	8
	ld	[de], a

.UPDATE_PASSWORD:
; Prints the updated password
	push	hl ; preserves pointer
	call	PRINT_PASSWORD
	call	LDIRVM_NAMTBL
	pop	hl ; restores pointer

; Is the password completed?
	ld	de, password + PASSWORD_SIZE
	call	DCOMPR
	jr	nz, .DIGIT_LOOP ; no
; yes: Is the password valid?
	call	DECODE_PASSWORD
	ret	nz

; Is the password forged?
	ld	hl, password_value ; (eqv. to globals.chapters)
	ld	a, [hl]
	and	$e8
	ret	nz ; yes: globals.chapters unused bits are set
	ld	a, [hl]
	and	$07
	cp	CHAPTERS
	jp	nc, RET_NOT_ZERO ; yes: globals.chapters > 5
	inc	hl ; (eqv. to globals.flags)
	ld	a, $e0
	and	[hl]
	ret	nz ; yes: globals.flags unused bits are set

; no: Applies the decoded password
	ld	hl, password_value
	ld	de, globals
	ld	bc, CFG_PASSWORD_DATA_SIZE
	ldir
; ret z
	xor	a
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	"NOW PLAYING" screen (jukebox)
; =============================================================================
;

; -----------------------------------------------------------------------------
; Jukebox screen
JUKEBOX_SCREEN:
; Prepares the jukebox screen
	ld	hl, .TXT
	ld	de, namtbl_buffer + 14 *SCR_WIDTH
	call	PRINT_CENTERED_TEXT
	inc	hl
	ld	de, namtbl_buffer + 19 *SCR_WIDTH
	call	PRINT_CENTERED_TEXT

.NEW_SONG:
; Clears the previous song title
	ld	hl, namtbl_buffer + 17 *SCR_WIDTH
	push	hl ; (preserves NAMTBL buffer pointer)
	call	CLEAR_LINE
; Locates the song data
	ld	hl, .DATA
	ld	a, [jukebox.current_song]
	or	a
	jr	z, .HL_OK
	inc	hl ; (skips the initial 0)
	call	GET_TEXT
.HL_OK:
; Plays the song
	push	hl ; (preserves data pointer)
	ld	a, [hl]
	call	PLAY_SONG
	ld	a, 2 ; (two loops)
	ld	[jukebox.loop_counter], a
	pop	hl ; (restores data pointer)
; Prints the song title
	inc	hl
	pop	de ; (restores NAMTBL buffer pointer)
	call	PRINT_CENTERED_TEXT
; Shows the jukebox screen
	call	ENASCR_FADE_IN

.LOOP:
	halt
	ld	a, [input.edge]
; Checks stick left and right
	bit	BIT_STICK_LEFT, a
	jr	nz, .PREVIOUS_SONG
	bit	BIT_STICK_RIGHT, a
	jr	nz, .NEXT_SONG
; Checks end of the song
	ld	hl, PT3_SETUP
	bit	7, [hl]
	jr	z, .LOOP ; still playing
	bit	0, [hl]
	jr	nz, .NEXT_SONG ; jingle ended
; loop ended
	ld	hl, jukebox.loop_counter
	dec	[hl]
	jr	z, .NEXT_SONG ; desired loop count reached
	jr	.LOOP

.PREVIOUS_SONG:
	ld	hl, jukebox.current_song
	dec	[hl]
; Checks overflow
	ld	a, [hl]
	inc	a
	jr	nz, .NEW_SONG ; no
; yes
	ld	[hl], .MAX_SONG
	jr	.NEW_SONG

.NEXT_SONG:
	ld	hl, jukebox.current_song
	inc	[hl]
; Checks overflow
	ld	a, [hl]
	sub	.MAX_SONG + 1
	jr	nz, .NEW_SONG ; no
; yes
	ld	[hl], a ; a = 0
	jr	.NEW_SONG

.TXT:
	db	"NOW PLAYING:", $00
	db	"BY WONDER", $00

.DATA: ; (see SONG_TABLE)
	db	0,			"1", CHAR_DOT, " INTRO", CHAR_DOT, " WAREHOUSE THEME", $00
	db	CFG_SONG_MAIN_THEME,	"2", CHAR_DOT, " MAIN THEME FROM STEVEDORE", $00
	db	1,			"3", CHAR_DOT, " LIGHTHOUSE THEME", $00
	db	CFG_SONG_CHAPTER_OVER,	"4", CHAR_DOT, " SORRY", CHAR_COMMA, " STEVEDORE BUT", CHAR_DOT, CHAR_DOT, CHAR_DOT, $00
	db	2,			"5", CHAR_DOT, " HAUNTED PIRATE SHIP THEME", $00
	db	3,			"6", CHAR_DOT, " JUNGLE THEME", $00
	db	4,			"7", CHAR_DOT, " VOLCANO THEME", $00
	db	5,			"8", CHAR_DOT, " TEMPLE THEME", $00
	db	CFG_SONG_BAD_ENDING,	"9", CHAR_DOT, " SHE IS THE CAPTAIN PIRATE", CHAR_EXCLAMATION, $00
	db	CFG_SONG_GAME_OVER,	"10", CHAR_DOT, " GAME OVER", $00
	db	6,			"11", CHAR_DOT, " A SECRET TO EVERYBODY", $00
	db	CFG_SONG_GOOD_ENDING,	"12", CHAR_DOT, " THE TRUE ENDING", $00

	.MAX_SONG:	equ 12 -1
; -----------------------------------------------------------------------------

;
; =============================================================================
;	"STAGE NN" screen
; =============================================================================
;

; -----------------------------------------------------------------------------
; "STAGE NN" screen initialization
STAGE_NN_SCREEN:
; Prepares the "STAGE NN" screen
	call	CLS_NAMTBL

; "STAGE"
	ld	hl, .TXT_STAGE_NN
	ld	de, namtbl_buffer + 10 * SCR_WIDTH + .TXT_STAGE_NN_CENTER
	call	PRINT_TEXT
; " NN"
	inc	de ; " "
	ld	hl, game.stage_bcd
	call	PRINT_BCD

; "N"
	ld	de, namtbl_buffer + 12 * SCR_WIDTH + .TXT_LIVES_LEFT_CENTER
	ld	a, [game.lives]
	add	$30 ; "0"
	ld	[de], a
	inc	de
	inc	de ; " "
; "LIVES LEFT" / "LIFE LEFT"
	cp	$31 ; "1"
	jr	z, .LIFE
	ld	hl, .TXT_LIVES_LEFT
	jr	.HL_OK
.LIFE:
	ld	hl, .TXT_LIFE_LEFT
.HL_OK:
	call	PRINT_TEXT

; Fade in
	call	ENASCR_FADE_IN
	jp	WAIT_TWO_SECONDS

; Literals
.TXT_STAGE_NN:
	db	"STAGE"
	.TXT_STAGE_NN_SIZE:	equ ($ + 3) - .TXT_STAGE_NN ; "... 00"
	db	$00
	.TXT_STAGE_NN_CENTER:	equ (SCR_WIDTH - .TXT_STAGE_NN_SIZE) /2

.TXT_LIVES_LEFT:
	db	"LIVES LEFT"
	.TXT_LIVES_LEFT_SIZE: 	equ $ - .TXT_LIVES_LEFT
	db	$00
	.TXT_LIVES_LEFT_CENTER:	equ (SCR_WIDTH - .TXT_LIVES_LEFT_SIZE - 2) /2 ; "0 ..."

.TXT_LIFE_LEFT:
	db	"LIFE LEFT", $00
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Stage loading routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Screens binary data (NAMTBL)
NAMTBL_PACKED_TABLE:
; Stages
	dw	.LIGHTHOUSE_1,	.LIGHTHOUSE_2,	.LIGHTHOUSE_3,	.LIGHTHOUSE_4,	.LIGHTHOUSE_5,	.LIGHTHOUSE_6
	dw	.SHIP_1,	.SHIP_2, 	.SHIP_3,	.SHIP_4,	.SHIP_5,	.SHIP_6
	dw	.JUNGLE_1,	.JUNGLE_2,	.JUNGLE_3,	.JUNGLE_4,	.JUNGLE_5,	.JUNGLE_6
	dw	.VOLCANO_1,	.VOLCANO_2, 	.VOLCANO_3,	.VOLCANO_4,	.VOLCANO_5,	.VOLCANO_6
	dw	.TEMPLE_1,	.TEMPLE_2,	.TEMPLE_3,	.TEMPLE_4,	.TEMPLE_5,	.TEMPLE_6
	dw	.SECRET_1,	.SECRET_2, 	.SECRET_3,	.SECRET_4,	.SECRET_5,	.SECRET_6
; Intro screen
	dw	.INTRO_STAGE
; Warehouse (tutorial)
	dw	.WAREHOUSE_1,	.WAREHOUSE_2,	.WAREHOUSE_3,	.WAREHOUSE_4,	.WAREHOUSE_5

; Intro
.INTRO_STAGE:	incbin	"games/stevedore/maps/intro_stage.tmx.bin.zx0"

; Warehouse (tutorial)
.WAREHOUSE_1:	incbin	"games/stevedore/maps/0-1-warehouse.tmx.bin.zx0"
.WAREHOUSE_2:	incbin	"games/stevedore/maps/0-2-warehouse.tmx.bin.zx0"
.WAREHOUSE_3:	incbin	"games/stevedore/maps/0-3-warehouse.tmx.bin.zx0"
.WAREHOUSE_4:	incbin	"games/stevedore/maps/0-4-warehouse.tmx.bin.zx0"
.WAREHOUSE_5:	incbin	"games/stevedore/maps/0-5-warehouse.tmx.bin.zx0"

; Lighthouse
.LIGHTHOUSE_1:	incbin	"games/stevedore/maps/1-1-lighthouse.tmx.bin.zx0"
.LIGHTHOUSE_2:	incbin	"games/stevedore/maps/1-2-lighthouse.tmx.bin.zx0"
.LIGHTHOUSE_3:	incbin	"games/stevedore/maps/1-3-lighthouse.tmx.bin.zx0"
.LIGHTHOUSE_4:	incbin	"games/stevedore/maps/1-4-lighthouse.tmx.bin.zx0"
.LIGHTHOUSE_5:	incbin	"games/stevedore/maps/1-5-lighthouse.tmx.bin.zx0"
.LIGHTHOUSE_6:	incbin	"games/stevedore/maps/1-6-lighthouse.tmx.bin.zx0"

; Ship
.SHIP_1:	incbin	"games/stevedore/maps/2-1-ship.tmx.bin.zx0"
.SHIP_2:	incbin	"games/stevedore/maps/2-2-ship.tmx.bin.zx0"
.SHIP_3:	incbin	"games/stevedore/maps/2-3-ship.tmx.bin.zx0"
.SHIP_4:	incbin	"games/stevedore/maps/2-4-ship.tmx.bin.zx0"
.SHIP_5:	incbin	"games/stevedore/maps/2-5-ship.tmx.bin.zx0"
.SHIP_6:	incbin	"games/stevedore/maps/2-6-ship.tmx.bin.zx0"

; Jungle
.JUNGLE_1:	incbin	"games/stevedore/maps/3-1-jungle.tmx.bin.zx0"
.JUNGLE_2:	incbin	"games/stevedore/maps/3-2-jungle.tmx.bin.zx0"
.JUNGLE_3:	incbin	"games/stevedore/maps/3-3-jungle.tmx.bin.zx0"
.JUNGLE_4:	incbin	"games/stevedore/maps/3-4-jungle.tmx.bin.zx0"
.JUNGLE_5:	incbin	"games/stevedore/maps/3-5-jungle.tmx.bin.zx0"
.JUNGLE_6:	incbin	"games/stevedore/maps/3-6-jungle.tmx.bin.zx0"

; Volcano
.VOLCANO_1:	incbin	"games/stevedore/maps/4-1-volcano.tmx.bin.zx0"
.VOLCANO_2:	incbin	"games/stevedore/maps/4-2-volcano.tmx.bin.zx0"
.VOLCANO_3:	incbin	"games/stevedore/maps/4-3-volcano.tmx.bin.zx0"
.VOLCANO_4:	incbin	"games/stevedore/maps/4-4-volcano.tmx.bin.zx0"
.VOLCANO_5:	incbin	"games/stevedore/maps/4-5-volcano.tmx.bin.zx0"
.VOLCANO_6:	incbin	"games/stevedore/maps/4-6-volcano.tmx.bin.zx0"

; Temple
.TEMPLE_1:	incbin	"games/stevedore/maps/5-1-temple.tmx.bin.zx0"
.TEMPLE_2:	incbin	"games/stevedore/maps/5-2-temple.tmx.bin.zx0"
.TEMPLE_3:	incbin	"games/stevedore/maps/5-3-temple.tmx.bin.zx0"
.TEMPLE_4:	incbin	"games/stevedore/maps/5-4-temple.tmx.bin.zx0"
.TEMPLE_5:	incbin	"games/stevedore/maps/5-5-temple.tmx.bin.zx0"
.TEMPLE_6:	incbin	"games/stevedore/maps/5-6-temple.tmx.bin.zx0"

; Secret
.SECRET_1:	incbin	"games/stevedore/maps/6-1-secret.tmx.bin.zx0"
.SECRET_2:	incbin	"games/stevedore/maps/6-2-secret.tmx.bin.zx0"
.SECRET_3:	incbin	"games/stevedore/maps/6-3-secret.tmx.bin.zx0"
.SECRET_4:	incbin	"games/stevedore/maps/6-4-secret.tmx.bin.zx0"
.SECRET_5:	incbin	"games/stevedore/maps/6-5-secret.tmx.bin.zx0"
.SECRET_6:	incbin	"games/stevedore/maps/6-6-secret.tmx.bin.zx0"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Loads and initializes the current stage
LOAD_AND_INIT_CURRENT_STAGE:
; Loads current stage into NAMTBL buffer
	ld	hl, NAMTBL_PACKED_TABLE
	ld	a, [game.stage]
	add	a ; a *= 2
	call	GET_HL_A_WORD
	ld	de, namtbl_buffer
	call	UNPACK
; In-game loop preamble and initialization
	; jp	INIT_STAGE ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; In-game loop preamble and initialization:
; Initializes stage vars, player vars and SPRATR,
; sprites, enemies, vpokes, spriteables,
; and post-processes the stage loaded in NATMBL buffer
INIT_STAGE:
; Initializes stage vars
	ld	hl, $0000 ; zeroes both stage.flags and player.pushing
	ld	[stage], hl

; Initializes player vars
	ld	hl, .PLAYER_0
	ld	de, player
	ld	bc, .PLAYER_0_SIZE
	ldir

; Initializes sprite attribute table (SPRATR)
	ld	hl, .SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir

; Other initialization
	call	RESET_SPRITES
	call	RESET_ENEMIES
	call	RESET_BULLETS
	call	RESET_VPOKES
	call	RESET_SPRITEABLES
	call	SET_DOORS_CHARSET.CLOSED

; Post-processes the stage loaded in NATMBL buffer
	ld	hl, namtbl_buffer
	ld	bc, NAMTBL_SIZE
.LOOP:
	push	bc ; preserves counter
	push	hl ; preserves pointer
	call	.INIT_ELEMENT
	pop	hl ; restores pointer
	pop	bc ; restores counter
	cpi	; inc hl, dec bc
	jp	pe, .LOOP
	ret

; Initial (per stage) player vars
.PLAYER_0:
	db	SPAT_OB, 0		; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
	.PLAYER_0_SIZE:	equ $ - .PLAYER_0

; Initial (per stage) sprite attributes table
.SPRATR_0:
; Reserved sprites before player sprites (see CFG_PLAYER_SPRITES_INDEX)
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
	db	SPAT_OB, 0, 0, 0
; Player sprites
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_1
	db	SPAT_OB, 0, 0, PLAYER_SPRITE_COLOR_2
; SPAT end marker (No "volatile" sprites)
	db	SPAT_END

; Post-processes one char of the loaded stage
; param hl: NAMTBL buffer pointer
.INIT_ELEMENT:
	ld	a, [hl]
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Is it a box?
	cp	CHAR_FIRST_BOX
	jr	nz, .NOT_A_BOX ; no

; Initializes a box spriteable
	ld	a, CHAR_EMPTY
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], BOX_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], BOX_SPRITE_COLOR
	ret
; -----------------------------------------------------------------------------
.NOT_A_BOX:

; -----------------------------------------------------------------------------
; Is it a boulder?
	cp	CHAR_FIRST_BULDER
	jr	nz, .NOT_A_BOULDER ; no

; Initializes a boulder spriteable
	ld	a, CHAR_EMPTY
	call	INIT_SPRITEABLE
	ld	[ix + _SPRITEABLE_PATTERN], BOULDER_SPRITE_PATTERN
	ld	[ix + _SPRITEABLE_COLOR], BOULDER_SPRITE_COLOR
	ret
; -----------------------------------------------------------------------------
.NOT_A_BOULDER:

; -----------------------------------------------------------------------------
; Is it a skeleton?
	cp	SKELETON_FIRST_CHAR +1
	jr	nz, .NOT_A_SKELETON ; no

; Initializes a new skeleton
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SKELETON_DATA
	jp	INIT_ENEMY

; Skeleton: the skeleton is slept until the star is picked up,
; then, it becomes of type walker (follower with pause)
.SKELETON_DATA:
	db	SKELETON_SPRITE_PATTERN OR FLAG_ENEMY_PATTERN_LEFT
	db	SKELETON_SPRITE_COLOR
	db	$00 ; (not lethal nor solid in the initial state)
	dw	.ENEMY_TYPE_SKELETON

.ENEMY_TYPE_SKELETON:
; Waits until the key been picked up
	ld	hl, stage.flags
	bit	BIT_STAGE_KEY, [hl]
	ret	z
; Reads the characters from the NAMTBL buffer
	ld	e, [ix + enemy.y]
	ld	d, [ix + enemy.x]
	call	COORDS_TO_OFFSET ; hl = NAMTBL offset
	ld	de, namtbl_buffer -SCR_WIDTH -1 ; (-1,-1)
	add	hl, de ; hl = NAMTBL buffer pointer
; Checks the skeleton characters
	ld	a, SKELETON_FIRST_CHAR ; left char
	cp	[hl]
	ret	nz ; no
	inc	a ; right char
	inc	hl
	cp	[hl]
	ret	nz ; no
; yes: Removes the characters in the next frame
	push	ix ; preserves ix
	ld	a, CHAR_EMPTY
	ld	[hl], a ; right char (buffer only)
	dec	hl
	call	UPDATE_NAMTBL_BUFFER_AND_VPOKE ; left char (buffer and VRAM)
	inc	hl
	call	VPOKE_NAMTBL_ADDRESS ; right char (VRAM only)
	pop	ix ; restores ix
; Wakes up the enemy
	ld	a, FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	or	[ix + enemy.flags]
	ld	[ix + enemy.flags], a
; Shows the sprite
	call	PUT_ENEMY_SPRITE
; Then becomes of type walker (follower with pause)
	ld	hl, ENEMY_TYPE_WALKER.FOLLOWER
	jp	SET_ENEMY_STATE.AND_SAVE_RESPAWN
; -----------------------------------------------------------------------------
.NOT_A_SKELETON:

; -----------------------------------------------------------------------------
; Is it a left trap?
	cp	TRAP_LOWER_LEFT_CHAR
	jr	nz, .NOT_A_LEFT_TRAP ; no

; Initializes a new left trap
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .LEFT_TRAP_DATA
	jp	INIT_ENEMY

; Trap (pointing left): shoots when the player is in front of it
.LEFT_TRAP_DATA:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	.ENEMY_TYPE_LEFT_TRAP

.ENEMY_TYPE_LEFT_TRAP:
; Waits until the enemy can shoot again
	call	TRIGGER_ENEMY_HANDLER
	ret	nz
; Waits until the player is left of the enemy
	ld	h, PLAYER_BULLET_Y_SIZE
	call	WAIT_ENEMY_HANDLER.PLAYER_LEFT
	ret	nz
; Shoots
	ld	hl, ARROW_DATA.L
	ld	b, -1 ; (ensures the bullets start outside the tile)
	ld	c, -7 ; (simply because looks better than -8)
	call	INIT_BULLET_FROM_ENEMY
; Plays "shoot" sound
	ld	a, CFG_SOUND_ENEMY_SHOOT
	ld	c, 5 ; high priority
	call	ayFX_INIT
; Resets the trigger frame counter
	ld	a, CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	jp	TRIGGER_ENEMY_HANDLER.RESET
; -----------------------------------------------------------------------------
.NOT_A_LEFT_TRAP:

; -----------------------------------------------------------------------------
; Is it a right trap?
	cp	TRAP_LOWER_RIGHT_CHAR
	jr	nz, .NOT_A_RIGHT_TRAP ; no

; Initializes a new right trap
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .RIGHT_TRAP_DATA
	jp	INIT_ENEMY

; Trap (pointing right): shoots when the player is in front of it
.RIGHT_TRAP_DATA:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	$00 ; (not lethal)
	dw	.ENEMY_TYPE_RIGHT_TRAP

.ENEMY_TYPE_RIGHT_TRAP:
; Waits until the enemy can shoot again
	call	TRIGGER_ENEMY_HANDLER
	ret	nz
; Waits until the player is left of the enemy
	ld	h, PLAYER_BULLET_Y_SIZE
	call	WAIT_ENEMY_HANDLER.PLAYER_RIGHT
	ret	nz
; Shoots
	ld	hl, ARROW_DATA.R
	ld	b, 0
	ld	c, -7 ; (simply because looks better than -8)
	call	INIT_BULLET_FROM_ENEMY
; Plays "shoot" sound
	ld	a, CFG_SOUND_ENEMY_SHOOT
	ld	c, 5 ; high priority
	call	ayFX_INIT
; Resets the trigger frame counter
	ld	a, CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	jp	TRIGGER_ENEMY_HANDLER.RESET
; -----------------------------------------------------------------------------
.NOT_A_RIGHT_TRAP:

; -----------------------------------------------------------------------------
; Is it the start point or an enemy?
	sub	'0'
	cp	.JUMP_TABLE_SIZE
	ret	nc ; no

; Initializes the start point or an enemy
	push	hl ; preseves pointer
	ld	hl, .JUMP_TABLE ; computes target routine address as [hl + 2*a]
	add	a
	call	GET_HL_A_WORD
	ex	[sp], hl ; restores pointer and puts target address in stack
	ret	; invokes target routine (address in stack)

.JUMP_TABLE:
	dw	SET_START_POINT			; '0'
	dw	NEW_BAT_1.R,	NEW_BAT_1.L	; '1', '2'
	dw	NEW_BAT_2.R,	NEW_BAT_2.L	; '3', '4'
	dw	NEW_SNAKE_1.R,	NEW_SNAKE_1.L	; '5', '6'
	dw	NEW_SNAKE_2.R,	NEW_SNAKE_2.L	; '7', '8'
	dw	NEW_MONKEY.R,	NEW_MONKEY.L	; '9', ':'
	dw	NEW_PANTOJO.R,	NEW_PANTOJO.L	; ';', '<'
	dw	NEW_SPIDER			; '='
	dw	NEW_JELLYFISH.R,NEW_JELLYFISH.L	; '>', '?'
	dw	NEW_URCHIN_1			; '@'
	dw	NEW_URCHIN_2			; 'A'
	.JUMP_TABLE_SIZE:	equ ($ - .JUMP_TABLE) /2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes player coordinates
SET_START_POINT:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, player.y
	ld	[hl], e
	inc	hl ; hl = player.x
	ld	[hl], d
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new bat (1)
NEW_BAT_1:
.L:
	call	.R
	jp	TURN_ENEMY.RESPAWN_AWARE
.R:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .BAT_1_DATA
	jp	INIT_ENEMY

; The bat (1) flies, then turns around and continues
.BAT_1_DATA:
	db	BAT_SPRITE_PATTERN
	db	BAT_SPRITE_COLOR_1
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	ENEMY_TYPE_FLYER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new bat (2)
NEW_BAT_2:
.L:
	call	.R
	jp	TURN_ENEMY.RESPAWN_AWARE
.R:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .BAT_2_DATA
	jp	INIT_ENEMY

; Bat: the bat flies, the turns around and continues
.BAT_2_DATA:
	db	BAT_SPRITE_PATTERN
	db	BAT_SPRITE_COLOR_2
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	.ENEMY_TYPE_BAT_2

.ENEMY_TYPE_BAT_2:
; The enemy flies then turns around and continues
	call	ENEMY_TYPE_FLYER ; (includes put sprite)
; Waits until the player is below the enemy
	call	WAIT_ENEMY_HANDLER.PLAYER_BELOW_DEFAULT
	ret	nz ; (end)
; Then
	call	SET_ENEMY_STATE.NEXT
; The enemy flies, falling onto the ground
	call	PUT_ENEMY_SPRITE_ANIM
	call	ENEMY_TYPE_FLYER.HANDLER
	call	ENEMY_TYPE_FALLER.SOLID_HANDLER
	ret	z ; (end)
; Then
	call	SET_ENEMY_STATE.NEXT
; The enemy flies, rising back up
	call	ENEMY_TYPE_FLYER ; (includes put sprite)
	call	ENEMY_TYPE_RISER.SOLID_HANDLER
	ret	z ; (end)
; Then continues
	ld	hl, .ENEMY_TYPE_BAT_2 ; (restart)
	jp	SET_ENEMY_STATE ; (end)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new snake (1)
NEW_SNAKE_1:
.L:
	call	.R
	jp	TURN_ENEMY.RESPAWN_AWARE
.R:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SNAKE_1_DATA
	jp	INIT_ENEMY

; Snake (1): the snake walks, the pauses, turning around, and continues
.SNAKE_1_DATA:
	db	SNAKE_SPRITE_PATTERN
	db	SNAKE_SPRITE_COLOR_1
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	ENEMY_TYPE_PACER.PAUSED
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new snake (2)
NEW_SNAKE_2:
.L:
	call	.R
	jp	TURN_ENEMY.RESPAWN_AWARE
.R:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SNAKE_2_DATA
	jp	INIT_ENEMY

; Snake (1): the snake walks, the pauses, turning around, and continues
.SNAKE_2_DATA:
	db	SNAKE_SPRITE_PATTERN
	db	SNAKE_SPRITE_COLOR_2
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	ENEMY_TYPE_WALKER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new monkey
NEW_MONKEY:
.L:
	call	.R
	jp	TURN_ENEMY.RESPAWN_AWARE
.R:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .MONKEY_DATA
	jp	INIT_ENEMY

; Monkey: the monkey walks turning around, shooting down to the player
.MONKEY_DATA:
	db	MONKEY_SPRITE_PATTERN
	db	MONKEY_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	.ENEMY_TYPE_MONKEY

.ENEMY_TYPE_MONKEY:
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Walks along the ground
	call	PUT_ENEMY_SPRITE_ANIMATE
	call	.ENEMY_TYPE_MONKEY_SUB
	call	ENEMY_TYPE_PACER.HANDLER
	ret	nz
; Then
	call	SET_ENEMY_STATE.NEXT
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Pauses, turning around
	call	PUT_ENEMY_SPRITE
	call	.ENEMY_TYPE_MONKEY_SUB
	ld	b, (2 << 6) OR CFG_ENEMY_PAUSE_S ; 3 (even) times, short pause
	call	WAIT_ENEMY_HANDLER.TURNING
	ret	nz
; Then continues
	ld	hl, .ENEMY_TYPE_MONKEY ; (restart)
	jp	SET_ENEMY_STATE

.ENEMY_TYPE_MONKEY_SUB:
; Waits until the enemy can shoot again
	call	TRIGGER_ENEMY_HANDLER
	ret	nz
; Waits until the player is below the enemy
	ld	l, PLAYER_BULLET_X_SIZE
	call	WAIT_ENEMY_HANDLER.PLAYER_BELOW
	ret	nz
; Shoots
	ld	hl, .COCONUT_DATA
	ld	bc, $00
	call	INIT_BULLET_FROM_ENEMY
; Plays "shoot" sound
	ld	a, CFG_SOUND_ENEMY_SHOOT
	ld	c, 5 ; high priority
	call	ayFX_INIT
; Resets the trigger frame counter
	ld	a, CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	jp	TRIGGER_ENEMY_HANDLER.RESET

.COCONUT_DATA:
	db	COCONUT_SPRITE_PATTERN
	db	COCONUT_SPRITE_COLOR
	db	(BULLET_DIR_UD OR (4 << 2)) ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new pantojo
NEW_PANTOJO:
.L:
	call	.R
	jp	TURN_ENEMY.RESPAWN_AWARE
.R:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .PANTOJO_DATA
	jp	INIT_ENEMY

; Pantojo: the pantojo walks towards the player, pausing briefly
.PANTOJO_DATA:
	db	PANTOJO_SPRITE_PATTERN
	db	PANTOJO_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	.ENEMY_TYPE_PANTOJO

.ENEMY_TYPE_PANTOJO:
; Shoots
	call	.ENEMY_TYPE_PANTOJO_SUB
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Walks along the ground
	call	PUT_ENEMY_SPRITE_ANIMATE
	call	ENEMY_TYPE_PACER.HANDLER
	ret	nz
; Then
	call	SET_ENEMY_STATE.NEXT ; (end)
; Shoots
	call	.ENEMY_TYPE_PANTOJO_SUB
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Pauses, turns around
	call	PUT_ENEMY_SPRITE
	ld	b, (0 << 6) OR CFG_ENEMY_PAUSE_M ; 1 time, medium pause
	call	WAIT_ENEMY_HANDLER.TURNING
	ret	nz
; Then continues
	ld	hl, .ENEMY_TYPE_PANTOJO ; .PAUSED ; (restart)
	jp	SET_ENEMY_STATE

.ENEMY_TYPE_PANTOJO_SUB:
; Waits until the enemy can shoot again
	call	TRIGGER_ENEMY_HANDLER
	ret	nz
; Waits until the player is ahead the enemy
	ld	h, PLAYER_BULLET_Y_SIZE
	call	WAIT_ENEMY_HANDLER.PLAYER_AHEAD
	ret	nz
; Is the enemy looking to the left?
	bit	BIT_ENEMY_PATTERN_LEFT, [ix + enemy.pattern]
	jr	z, .SHOOT_RIGHT ; no
; yes: Shoots to the left
	ld	hl, ARROW_DATA.L
	jr	.SHOOT
; Shoots to the right
.SHOOT_RIGHT:
	ld	hl, ARROW_DATA.R
	; jr	.SHOOT ; falls through
; Initializes the bullet
.SHOOT:
	ld	b, 0
	ld	c, -5 ; (simply because looks better than -8)
	call	INIT_BULLET_FROM_ENEMY
; Plays "shoot" sound
	ld	a, CFG_SOUND_ENEMY_SHOOT
	ld	c, 5 ; high priority
	call	ayFX_INIT
; Resets the trigger frame counter
	ld	a, CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	jp	TRIGGER_ENEMY_HANDLER.RESET
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new spider
NEW_SPIDER:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .SPIDER_DATA
	jp	INIT_ENEMY

; Spider: the spider falls onto the ground the the player is near
.SPIDER_DATA:
	db	SPIDER_SPRITE_PATTERN
	db	SPIDER_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	.ENEMY_TYPE_SPIDER

.ENEMY_TYPE_SPIDER:
; Waits until the player is below the enemy
	call	PUT_ENEMY_SPRITE
	call	WAIT_ENEMY_HANDLER.PLAYER_BELOW_DEFAULT
	ret	nz
; Then, the enemy falls onto the ground
	call	SET_ENEMY_STATE.NEXT
	call	PUT_ENEMY_SPRITE_ANIM
	call	ENEMY_TYPE_FALLER.SOLID_HANDLER
	ret	z
; Then, the enemy flies, rising back up
	call	SET_ENEMY_STATE.NEXT
	call	ENEMY_TYPE_RISER ; (includes put sprite)
	ret	z
; Then restarts
	ld	hl, .ENEMY_TYPE_SPIDER
	jp	SET_ENEMY_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new jellyfish
NEW_JELLYFISH:
.L:
	call	.R
	jp	TURN_ENEMY.RESPAWN_AWARE
.R:
	ld	[hl], CHAR_WATER
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .JELLYFISH_DATA
	jp	INIT_ENEMY

; Jellyfish: the jellyfish floats in a sine wave pattern, shooting up
.JELLYFISH_DATA:
	db	JELLYFISH_SPRITE_PATTERN
	db	JELLYFISH_SPRITE_COLOR
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID
	dw	.ENEMY_TYPE_JELLYFISH

.ENEMY_TYPE_JELLYFISH:
; The enemy floats in a sine wave pattern
	call	ENEMY_TYPE_FLYER.HANDLER
	call	ENEMY_TYPE_WAVER.HANDLER
; Is the wave pattern ascending?
	ld	c, JELLYFISH_SPRITE_PATTERN
	ld	a, [ix + enemy.dy_index]
	bit	5, a
	jp	nz, .PATTERN_OK ; no
; yes
	ld	c, JELLYFISH_SPRITE_PATTERN OR FLAG_ENEMY_PATTERN_ANIM
.PATTERN_OK:
	call	PUT_ENEMY_SPRITE_PATTERN ; (avoids flag left)
; Waits until the enemy can shoot again
	call	TRIGGER_ENEMY_HANDLER
	ret	nz
; Waits until the player is above the enemy
	ld	l, PLAYER_BULLET_X_SIZE
	call	WAIT_ENEMY_HANDLER.PLAYER_ABOVE
	ret	nz
; Shoots
	ld	hl, .SPARK_DATA
	ld	b, 0
	ld	c, -12
	call	INIT_BULLET_FROM_ENEMY
; Plays "shoot" sound
	ld	a, CFG_SOUND_ENEMY_SHOOT
	ld	c, 5 ; high priority
	call	ayFX_INIT
; Resets the trigger frame counter
	ld	a, CFG_ENEMY_PAUSE_M ; medium pause until next shoot
	jp	TRIGGER_ENEMY_HANDLER.RESET

.SPARK_DATA:
	db	SPARK_SPRITE_PATTERN
	db	SPARK_SPRITE_COLOR
	db	(BULLET_DIR_UD OR (-4 << 2)) ; (4 pixels / frame)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new urchin (1)
NEW_URCHIN_1:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .URCHIN_1_DATA
	jp	INIT_ENEMY

; Urchin:
.URCHIN_1_DATA:
	db	URCHIN_SPRITE_PATTERN
	db	URCHIN_SPRITE_COLOR_1
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	.ENEMY_TYPE_URCHIN_1

.ENEMY_TYPE_URCHIN_1:
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Waits until the player is above the enemy
	call	PUT_ENEMY_SPRITE
	call	WAIT_ENEMY_HANDLER.PLAYER_ABOVE_DEFAULT
	ret	nz
; Then, the enemy bounces or jumps
	call	SET_ENEMY_STATE.NEXT
	call	ENEMY_TYPE_JUMPER
	ret	nz
; Then restart
	ld	hl, .ENEMY_TYPE_URCHIN_1
	jp	SET_ENEMY_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new urchin (2)
NEW_URCHIN_2:
	ld	[hl], CHAR_EMPTY
	call	NAMTBL_POINTER_TO_LOGICAL_COORDS
	ld	hl, .URCHIN_2_DATA
	jp	INIT_ENEMY

; Urchin:
.URCHIN_2_DATA:
	db	URCHIN_SPRITE_PATTERN
	db	URCHIN_SPRITE_COLOR_2
	db	FLAG_ENEMY_LETHAL OR FLAG_ENEMY_SOLID OR FLAG_ENEMY_DEATH
	dw	.ENEMY_TYPE_URCHIN_2

.ENEMY_TYPE_URCHIN_2:
; (falls if not on the floor)
	call	ENEMY_TYPE_FALLER.FLOOR_HANDLER
	jp	z, PUT_ENEMY_SPRITE_ANIM
; Waits until the player is below the enemy
	call	PUT_ENEMY_SPRITE
	call	WAIT_ENEMY_HANDLER.PLAYER_BELOW_DEFAULT
	jr	nz, .URCHIN_2_NOT_FALLING
; Then, the enemy falls onto the ground
	call	SET_ENEMY_STATE.NEXT
	call	PUT_ENEMY_SPRITE_ANIM
	call	ENEMY_TYPE_FALLER.SOLID_HANDLER
	ret	z
; Then restart
	ld	hl, .ENEMY_TYPE_URCHIN_2
	jp	SET_ENEMY_STATE

.URCHIN_2_NOT_FALLING:
; Waits until the player is above the enemy
	call	WAIT_ENEMY_HANDLER.PLAYER_ABOVE_DEFAULT
	ret	nz
; Then, the enemy bounces or jumps
	call	SET_ENEMY_STATE.NEXT
	call	ENEMY_TYPE_JUMPER
	ret	nz
; Then restart
	ld	hl, .ENEMY_TYPE_URCHIN_2
	jp	SET_ENEMY_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
ARROW_DATA:
.L:
	db	ARROW_LEFT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	(BULLET_DIR_LR OR (-4 << 2)) ; (4 pixels / frame)
.R:
	db	ARROW_RIGHT_SPRITE_PATTERN
	db	ARROW_SPRITE_COLOR
	db	(BULLET_DIR_LR OR (4 << 2)) ; (4 pixels / frame)
; -----------------------------------------------------------------------------

;
; =============================================================================
;	In-game routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Executes one in-game frame
IN_GAME_FRAME:
; Prepare next frame
	call	PUT_PLAYER_SPRITE

; Synchronization (halt)
	halt

; Blit buffers to VRAM
	call	EXECUTE_VPOKES
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET

; Game logic (1/2)
	call	RESET_SPRITES
	call	UPDATE_PLAYER
	call	UPDATE_FRAMES_PUSHING
	call	UPDATE_ENEMIES
	call	UPDATE_BULLETS
	call	UPDATE_SPRITEABLES	; (spriteables after enemies
	call	UPDATE_PUSHABLES	; for the splash to show in foreground)
	call	DRAW_SPRITEABLES

; Has the player already finished?
	ld	a, [player.state]
	bit	BIT_STATE_FINISH, a
	ret	nz ; yes

; Game logic (2/2)
	call	CHECK_PLAYER_ENEMIES_COLLISIONS
	call	CHECK_PLAYER_BULLETS_COLLISIONS

; Checks restart key
	call	CHECK_RESTART_KEY
	ret	nz
	jp	SET_PLAYER_DYING ; yes
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Tile collision (single char): Items
ON_PLAYER_WALK_ON:
; Reads the tile index and NAMTBL offset and buffer pointer
	call	GET_PLAYER_TILE_VALUE
	push	af ; preserves tile index
; Removes the item in the NAMTBL buffer and VRAM
	ld	a, CHAR_EMPTY
	call	UPDATE_NAMTBL_BUFFER_AND_VPOKE
; Executes item action
	ld	hl, stage.flags
	pop	af ; restores tile index

; Is it the key?
	sub	CHAR_FIRST_ITEM
	jr	nz, .NO_KEY ; no
; yes: open the doors
	set	BIT_STAGE_KEY, [hl]
	call	SET_DOORS_CHARSET.OPEN
; Plays "key" sound
	ld	a, CFG_SOUND_ITEM_KEY
	ld	c, 5 ; high priority
	jp	ayFX_INIT
.NO_KEY:

; Is it the star?
	dec	a
	jr	nz, .NO_STAR ; no
; yes
	set	BIT_STAGE_STAR, [hl]
; Plays "star" sound
	ld	a, CFG_SOUND_ITEM_STAR
	ld	c, 5 ; high priority
	jp	ayFX_INIT
.NO_STAR:

; It is a fruit
	set	BIT_STAGE_FRUIT, [hl]
; Plays "fruit" sound
	ld	a, CFG_SOUND_ITEM_FRUIT
	ld	c, 5 ; high priority
	jp	ayFX_INIT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Wide tile collision (player width): Doors
ON_PLAYER_WIDE_ON:
; Cursor up or down?
	ld	a, [input.edge]
	and	(1 << BIT_STICK_UP) OR (1 << BIT_STICK_DOWN)
	ret	z ; no
; Key picked up?
	ld	hl, stage.flags
	bit	BIT_STAGE_KEY, [hl]
	ret	z ; no
; Player on floor?
	ld	a, [player.state]
	and	$ff - FLAGS_STATE
	; cp	PLAYER_STATE_FLOOR
	or	a ; (optimization; assumes PLAYER_STATE_FLOOR = 0)
	ret	nz ; no
; yes: set "stage finish" state
	ld	a, PLAYER_STATE_FINISH
	jp	SET_PLAYER_STATE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Walking over tiles (player width): Fragile floor
ON_PLAYER_WALK_OVER:
; Reads the tile index and NAMTBL offset and buffer pointer
	ld	de, [player.xy]
	call	GET_TILE_VALUE
	push	hl ; preserves NAMTBL buffer pointer
	push	af ; preserves actual character
; Checks if the tile is fragile
; (avoids touching the wrong character because of player width)
	call	GET_FLAGS_OF_TILE
	bit	BIT_WORLD_WALK_OVER, a
	pop	bc ; restores actual character in b
	pop	hl ; restores NAMTBL buffer pointer
	ret	z ; no
; yes: Is the most fragile character?
	ld	a, b
	cp	CHAR_FIRST_FRAGILE
	jr	z, .REMOVE ; yes
; no: Increases the fragility of the character in the NAMTBL buffer and VRAM
	dec	a
	jp	UPDATE_NAMTBL_BUFFER_AND_VPOKE
.REMOVE:
; Removes the fragile character in the NAMTBL buffer and VRAM
	ld	a, CHAR_EMPTY
	jp	UPDATE_NAMTBL_BUFFER_AND_VPOKE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pushable tiles (player height)
; ret z: was pushing
; ret nz: was not pushing (CHECK does not touch b)
ON_PLAYER_PUSH:

.RIGHT:
; Checks lower tile being pushed
	ld	a, PLAYER_BOX_X_OFFSET +CFG_PLAYER_WIDTH ; x += offset + width
	call	.GET_PUSHED_TILE
; Is lower left tile of a pushable object?
	and	(CHAR_FIRST_BOX AND CHAR_FIRST_BULDER OR $03)
	cp	(CHAR_FIRST_BOX AND CHAR_FIRST_BULDER OR $02)
	ret	nz ; no
; yes: changes the state
	ld	a, PLAYER_STATE_PUSH
	ld	[player.state], a
; Enough room for pushing?
	ld	a, PLAYER_BOX_X_OFFSET +CFG_PLAYER_WIDTH +16
	call	GET_PLAYER_V_TILE_FLAGS
	bit	BIT_WORLD_SOLID, a
	ret	nz ; no
; yes: pushing for enough frames?
	call	.CHECK_FRAMES_PUSHING
	ret	nz ; no
; yes: locates the pushable object and starts its movement
	ld	a, PLAYER_BOX_X_OFFSET +CFG_PLAYER_WIDTH +8
	call	.LOCATE_PUSHABLE
IFEXIST CFG_SOUND_PLAYER_PUSH
	call	MOVE_SPRITEABLE_RIGHT
	ld	a, CFG_SOUND_PLAYER_PUSH
	ld	c, 11 ; low priority
	jp	ayFX_INIT
ELSE
	jp	MOVE_SPRITEABLE_RIGHT
ENDIF

.LEFT:
; Checks lower tile being pushed
	ld	a, PLAYER_BOX_X_OFFSET -1 ; x += offset -1
	call	.GET_PUSHED_TILE
; Is lower right tile of a pushable object?
	and	(CHAR_FIRST_BOX AND CHAR_FIRST_BULDER OR $03)
	cp	(CHAR_FIRST_BOX AND CHAR_FIRST_BULDER OR $03)
	ret	nz ; no
; yes: changes the state
	ld	a, PLAYER_STATE_PUSH OR FLAG_STATE_LEFT
	ld	[player.state], a
; Enough room for pushing?
	ld	a, PLAYER_BOX_X_OFFSET -1 -16
	call	GET_PLAYER_V_TILE_FLAGS
	bit	BIT_WORLD_SOLID, a
	ret	nz ; no
; yes: pushing for enough frames?
	call	.CHECK_FRAMES_PUSHING
	ret	nz ; no
; yes: locates the pushable object and starts its movement
	ld	a, PLAYER_BOX_X_OFFSET -8
	call	.LOCATE_PUSHABLE
IFEXIST CFG_SOUND_PLAYER_PUSH
	call	MOVE_SPRITEABLE_LEFT
	ld	a, CFG_SOUND_PLAYER_PUSH
	ld	c, 11 ; low priority
	jp	ayFX_INIT
ELSE
	jp	MOVE_SPRITEABLE_LEFT
ENDIF

; Lee el tile (parte baja) que se está empujando
; param a: dx
.GET_PUSHED_TILE:
	ld	de, [player.xy]
	add	d ; x += dx
	ld	d, a
	dec	e ; y -= 1
	jp	GET_TILE_VALUE

; Actualiza y comprueba el contador de frames que lleva empujando el jugador
; ret nz: insuficientes
; ret z: suficientes
.CHECK_FRAMES_PUSHING:
	ld	hl, player.pushing
	inc	[hl]
	ld	a, [hl]
	cp	FRAMES_TO_PUSH
	ret

; Localiza el elemento que se está empujando y lo activa
; param a: dx
; return ix: puntero al tile convertible
.LOCATE_PUSHABLE:
; Calcula las coordenadas que tiene que buscar
	ld	de, [player.xy]
	add	d ; x += dx
	ld	d, a
	jp	GET_SPRITEABLE_COORDS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; If the player is not puhsing, resets the pushing frames counter
UPDATE_FRAMES_PUSHING:
; Is the player pushing?
	ld	a, [player.state]
	and	$ff - FLAGS_STATE
	cp	PLAYER_STATE_PUSH
	ret	z ; yes
 ; no: resets the frame counter
	xor	a
	ld	[player.pushing], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Automatic update of the spriteables/pushables movement
; (i.e.: start falling, stop at water, etc.)
UPDATE_PUSHABLES:
; For each spriteable
	ld	ix, spriteables.count
	ld	c, SPRITEABLE_SIZE
	ld	hl, .ROUTINE
	jp	FOR_EACH_ARRAY_IX

; param ix: pointer to the current spriteable
.ROUTINE:
	ld	a, [ix +_SPRITEABLE_STATUS]
; Is the spriteable disabled?
	bit	BIT_SPRITEABLE_DISABLED, a
	ret	nz ; yes: do nothing
; no: Is the spriteable already moving?
	and	MASK_SPRITEABLE_PENDING
	ret	nz ; yes: do nothing

.CHECK_FALLING:
; Reads the characters under the spriteable
	ld	e, [ix +_SPRITEABLE_OFFSET_L]
	ld	d, [ix +_SPRITEABLE_OFFSET_H]
	call	OFFSET_TO_COORDS
; Translates into actual coordinates (also reverses (y,x) order)
	ex	de, hl
	ld	d, l ; (x as is)
	ld	a, h ; (y += 16, two tiles down)
	add	16
	ld	e, a
; Reads two characters
	ld	b, 16
	call	GET_H_TILE_FLAGS
; Is it solid?
	bit	BIT_WORLD_SOLID, a
	ret	nz ; yes
	cp	1 << BIT_WORLD_FLOOR OR 1 << BIT_WORLD_STAIRS ; (top of stairs)
	ret	z ; yes (top of stairs considered solid)

; no: Starts moving the spriteable down
	call	MOVE_SPRITEABLE_DOWN

; Is the lower half of the spriteable in water or lava?
	ld	a, [ix +_SPRITEABLE_BACKGROUND +2] ; (+0,+1)
	ld	b, a ; preserves value in b
	and	$f8 ; (discards lower bits)
	cp	CHAR_WATER_SURFACE
	ret	nz ; no

; Is the lower half of the spriteable the surface?
	bit	1, b
	call	z, NEW_SPLASH ; yes: splashes

; Yes: is the spriteable a box?
	ld	a, [ix +_SPRITEABLE_PATTERN]
	cp	BOX_SPRITE_PATTERN
	jr	z, .BOX ; yes
; no: it is a boulder

.BOULDER:
; Calculate new lower characters
	ld	a, b ; restores background value
	and	$06 ; (discards lower bit)
	add	a
	add	$a2
; Sets the new lower characters
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
; Is the upper half of the boulder in water or lava?
	ld	a, [ix +_SPRITEABLE_BACKGROUND]
	ld	b, a ; preserves value in b
	and	$f8 ; (discards lower bits)
	cp	CHAR_WATER_SURFACE
	ret	nz ; no
; Yes: calculate new upper characters
	ld	a, b ; restores background value
	and	$06 ; (discards lower bit)
	add	a
	add	$a0
; Sets the new upper character
	ld	[ix + _SPRITEABLE_FOREGROUND], a
	inc	a
	ld	[ix + _SPRITEABLE_FOREGROUND +1], a
; Is the upper half of the boulder in deep water or lava?
	bit	1, b
	ret	z ; no
; yes: change the sprite color
	bit	2, b
	ld	a, BOULDER_SPRITE_COLOR_WATER
	jr	z, .A_OK
	ld	a, BOULDER_SPRITE_COLOR_LAVA
.A_OK:
	ld	[ix + _SPRITEABLE_COLOR], a
	ret

.BOX:
; Checks if it is water or lava
	bit	2, b
	jr	nz, .BOX_IN_LAVA ; lava

; Water: Is the upper half of the box in water?
	bit	1, b
	jr	nz, .FLOAT_BOX ; yes
; No: prepares the new lower characters
	ld	[ix + _SPRITEABLE_FOREGROUND +2], $9c ; lower box in water surface
	ld	[ix + _SPRITEABLE_FOREGROUND +3], $9c +1
	ret
.FLOAT_BOX:
; Sets the new characters
	ld	[ix + _SPRITEABLE_FOREGROUND   ], $9a ; upper box in water surface
	ld	[ix + _SPRITEABLE_FOREGROUND +1], $9a +1
	ld	[ix + _SPRITEABLE_FOREGROUND +2], $9e ; lower box in deep water
	ld	[ix + _SPRITEABLE_FOREGROUND +3], $9e +1
; Stops the spriteable (after this movement)
	set	BIT_SPRITEABLE_DISABLED, [ix + _SPRITEABLE_STATUS]
	ret

.BOX_IN_LAVA:
; Recovers the background immediately
	call	NAMTBL_BUFFER_SPRITEABLE_BACKGROUND
; Prevents printing the foreground again after this movement
	ld	a, [ix + _SPRITEABLE_BACKGROUND]
	ld	[ix + _SPRITEABLE_FOREGROUND], a
	ld	a, [ix + _SPRITEABLE_BACKGROUND +1]
	ld	[ix + _SPRITEABLE_FOREGROUND +1], a
	ld	a, [ix + _SPRITEABLE_BACKGROUND +2]
	ld	[ix + _SPRITEABLE_FOREGROUND +2], a
	ld	a, [ix + _SPRITEABLE_BACKGROUND +3]
	ld	[ix + _SPRITEABLE_FOREGROUND +3], a
; Changes the sprite color
	ld	[ix + _SPRITEABLE_COLOR], BOULDER_SPRITE_COLOR_LAVA
; Stops the spriteable (after this movement)
	set	BIT_SPRITEABLE_DISABLED, [ix + _SPRITEABLE_STATUS]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Splash water or lava
NEW_SPLASH:
; Calculates the coordinates of the splash
	ld	e, [ix +_SPRITEABLE_OFFSET_L]
	ld	d, [ix +_SPRITEABLE_OFFSET_H]
	call	OFFSET_TO_COORDS
; Translates into actual coordinates (also reverses (y,x) order)
	ld	hl, $1508 ; (+8, +21)
	add	hl, de
	ld	d, l
	ld	e, h
; Checks if it is water or lava
	bit	2, b ; checks againts background value
	jr	nz, .LAVA

; Splash water
.WATER:
	ld	hl, .WATER_DATA
	jr	.INIT_SPLASH
.WATER_DATA:
	db	SPLASH_SPRITE_PATTERN_FIRST
	db	SPLASH_SPRITE_COLOR_WATER
	db	$00 ; no enemy flags
	dw	.ENEMY_TYPE_SPLASH

; Splash lava
.LAVA:
	ld	hl, .LAVA_DATA
	; jr	.INIT_SPLASH ; falls through
.INIT_SPLASH:
	push	ix ; preserves spriteable index
	push	bc ; preserves background value (b)
	call	INIT_ENEMY
IFEXIST CFG_SOUND_SPLASH
; Plays "splash" sound
	ld	a, CFG_SOUND_SPLASH
	ld	c, 9 ; default-low priority
	call	ayFX_INIT
ENDIF
	pop	bc ; restores background value (b)
	pop	ix ; retores spriteable index
	ret
.LAVA_DATA:
	db	SPLASH_SPRITE_PATTERN_FIRST
	db	SPLASH_SPRITE_COLOR_LAVA
	db	$00 ; (lava splashes should be lethal, but it is unexpected)
	dw	.ENEMY_TYPE_SPLASH

.ENEMY_TYPE_SPLASH:
; (Initial delay before the actual animation)
	ld	b, 10
	call	WAIT_ENEMY_HANDLER
	ret	nz
	call	SET_ENEMY_STATE.NEXT
; Put the sprite an small amount of frames
	call	PUT_ENEMY_SPRITE
	ld	b, 10
	call	WAIT_ENEMY_HANDLER
	ret	nz
; Is the current pattern the last pattern?
	ld	a, [ix + enemy.pattern]
	cp	SPLASH_SPRITE_PATTERN_LAST
	jp	z, REMOVE_ENEMY ; yes: removes the enemy
; no: updates the pattern and resets frame counter
	add	4
	ld	[ix + enemy.pattern], a
	xor	a
	ld	[ix + enemy.frame_counter], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; On player-bullet collision, checks if the enemy is letal to kill the player
ON_PLAYER_ENEMY_COLLISION:
	bit	BIT_ENEMY_LETHAL, [ix + enemy.flags]
	ret	z
	jp	SET_PLAYER_DYING
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; On player-bullet collision, kills the player
ON_PLAYER_BULLET_COLLISION:
	bit	BIT_BULLET_DYING, [ix + bullet.type]
	ret	nz
	jp	SET_PLAYER_DYING
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Chapter over intermission screens
; =============================================================================
;

; -----------------------------------------------------------------------------
; Chapter over intermission screen
; ret nz: continue to the next chapter/stage
; ret z: the player has reached the bad ending
CHAPTER_OVER_SCREEN:
; Prepares the "chapter over" screen
	ld	hl, .PLAYER_0
	call	INIT_CHAPTER_OVER_SCREEN
	call	PRINT_CHAPTER_OVER_BLOCKS

; Fade in, waits
	call	CHAPTER_OVER_APPEARING_ANIMATION
	call	WAIT_THREE_SECONDS_ANIMATION

; Saves the star and unlocks the next chapter in the global flags
; (this should be done before encoding password)
	call	SAVE_STAR
	call	UNLOCK_NEXT_CHAPTER ; (game.chapter increased)
; If the player picked up the five fruits, gives the player a password
	call	GIVE_PASSWORD
; and changes the player sprite
	call	PUT_PLAYER_SPRITE.PATTERN

; Shows the password or message and the sprite
	halt
	call	LDIRVM_NAMTBL
	call	LDIRVM_SPRATR

; Waits for the trigger
	call	WAIT_TRIGGER_ANIMATION

; Is the last chapter?
	ld	a, [game.chapter]
	cp	5 +1 ; (because it's increased already)
	jr	nz, .ANIMATION_LOOP ; no
; yes: Is the secret chapter unlocked?
	ld	a, [globals.chapters]
	and	$10 ; 000s0nnn: secret chapter and number of chapters unlocked
	ret	z ; no
; yes: Plays secret chapter song, looped
	call	PLAY_CHAPTER_SONG
; Slowly opens the rock door
	call	WAIT_TWO_SECONDS_ANIMATION
	call	SET_DOORS_CHARSET.OPEN_ANIMATED

.ANIMATION_LOOP:
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
; Moves the player right
	call	MOVE_PLAYER_RIGHT
	call	UPDATE_PLAYER_ANIMATION
	call	PUT_PLAYER_SPRITE
; Has the player reached the target coordinate?
	ld	a, [player.x]
	cp	128 +32
	jr	nz, .ANIMATION_LOOP ; no
; yes: Finishes animation
	call	WAIT_TWO_SECONDS_ANIMATION
	call	PLAYER_DISAPPEARING.ANIMATION
	call	WAIT_ONE_SECOND_ANIMATION
; Is the last chapter?
	ld	a, [game.chapter]
	cp	5 +1 ; (because it's already increased)
	ret	nz ; no
; yes: Closes the door
	call	SET_DOORS_CHARSET.CLOSED
	call	WAIT_ONE_SECOND_ANIMATION
; ret nz
	or	-1
	ret

; Initial player vars
.PLAYER_0:
	db	112, 128 -32		; .y, .x
	db	0			; .animation_delay
	db	PLAYER_STATE_FLOOR	; .state
	db	0			; .dy_index
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Clears the screen and the sprites,
; and prints the chapter over text ("SORRY, STEVEDORE", etc.)
; param hl: player source data
INIT_CHAPTER_OVER_SCREEN:
	push	hl ; preserves player source data
; Prepares the "chapter over" screen
	call	CLS_NAMTBL
	call	RESET_SPRITES

; "SORRY, STEVEDORE"
	ld	hl, .TXT
	ld	de, namtbl_buffer + 2 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT_LF_LF
; "BUT THE LIGHTHOUSE KEEPER"
	call	PRINT_CENTERED_TEXT_LF_LF
; Searchs for the correct text
	ld	a, [game.chapter]
	call	GET_TEXT
; "IS IN ANOTHER BUILDING!" and similar texts
	ld	de, namtbl_buffer + 6 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT

; Re-initializes the sprite attribute table (SPRATR) and initializes the player
	ld	hl, INIT_STAGE.SPRATR_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_SIZE
	ldir
	pop	hl ; restores player source data
	ld	de, player
	ld	bc, INIT_STAGE.PLAYER_0_SIZE
	ldir
	jp	PUT_PLAYER_SPRITE

; Literals
.TXT:
	db	"SORRY", CHAR_COMMA, " STEVEDORE", $00
	db	"BUT THE LIGHTHOUSE KEEPER", $00
	db	"IS IN ANOTHER BUILDING", CHAR_EXCLAMATION, $00
	db	"WAS KIDNAPPED BY PIRATES", CHAR_EXCLAMATION, $00
	db	"SHIPWRECKED", CHAR_EXCLAMATION, $00
	db	"FELL INTO A CAVE", CHAR_EXCLAMATION, $00
	db	"WAS CAPTURED BY PANTOJOS", CHAR_EXCLAMATION, $00
	db	"IS BEHIND THAT DOOR", CHAR_EXCLAMATION, $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the two chapter blocks of the currently finished chapter
PRINT_CHAPTER_OVER_BLOCKS:
; Selects the blocks to print
	ld	hl, STAGE_SELECT_SCREEN.NAMTBL
	ld	bc, STAGE_SELECT_SCREEN.HEIGHT * STAGE_SELECT_SCREEN.WIDTH
	ld	a, [game.chapter]
.SELECT_BLOCK_LOOP:
	dec	a
	jr	z, .SELECT_BLOCK_OK ; element reached
; Skips one element
	add	hl, bc
	jr	.SELECT_BLOCK_LOOP
.SELECT_BLOCK_OK:
; Prints the left block
	ld	de, namtbl_buffer + 9 * SCR_WIDTH + 10
	call	.PRINT_BLOCK
; Prints the right block
	ld	de, namtbl_buffer + 9 * SCR_WIDTH + 18
.PRINT_BLOCK:
	ld	bc, STAGE_SELECT_SCREEN.HEIGHT << 8 + STAGE_SELECT_SCREEN.WIDTH
	jp	PRINT_BLOCK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience routine to reuse in tutorial and chapter over intermission screens
CHAPTER_OVER_APPEARING_ANIMATION:
	call	ENASCR_FADE_IN
	call	PREPARE_MASK.APPEARING
	jp	PLAYER_APPEARING.ANIMATION
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; If the player has picked the star, saves it in the global flags
SAVE_STAR:
; Has the player picked up the star?
	ld	a, [game.item_counter]
	bit	BIT_CHAPTER_STAR, a
	ret	z ; no

; yes: Saves the star in the global flags
	ld	a, [game.chapter]
	ld	b, a
; Computes the bit as: 1 << b
	ld	a, 1
.LOOP:
	add	a, a
	djnz	.LOOP
	srl	a ; so chapter 1 has bit 0, chapter 2 bit 1, etc.
; Saves the bit in the global flags
	ld	hl, globals.flags
	or	[hl]
	ld	[hl], a

; "YOU FOUND A STAR!"
	ld	hl, .TXT
	ld	de, namtbl_buffer + 19 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT
; Plays "star" sound
	ld	a, CFG_SOUND_ITEM_STAR
	ld	c, 5 ; high priority
	jp	ayFX_INIT

.TXT:
	db	"YOU FOUND A STAR", CHAR_EXCLAMATION, $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the chapter and unlocks the next chapter in the menu screen
UNLOCK_NEXT_CHAPTER:
	ld	hl, game.chapter
	inc	[hl]
	ld	a, [hl]
; Gives secret chapter password only after last chapter
	ld	hl, globals.chapters
	res	4, [hl] ; 000s0nnn: secret chapter and number of chapters unlocked
; Is the next chapter the secret chapter?
	cp	5 +1 ; (because it's increased already)
	jr	nz, .NO_SECRET_CHAPTER ; no
; yes: Does the player have all the stars?
	inc	hl ; globals.flags
	ld	a, [hl] ; if the star was picked in chapter 00054321 (bitmap)
	cp	$1f
	ret	nz ; no
; yes: unlocks the secret chapter
	dec	hl ; globals.chapters
	set	4, [hl] ; 000s0nnn: secret chapter and number of chapters unlocked
	ret
.NO_SECRET_CHAPTER:
; Is the next chapter greater than the currently unlocked chapter?
	cp	[hl]
	ret	c ; no
; yes: unlocks the chapter
	ld	[hl], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; If the player picked up the five fruits, gives the player a password
; ret a: player sprite pattern to use
GIVE_PASSWORD:
; Has the player picked up the five fruits?
	ld	a, [game.item_counter]
	and	$0f
	cp	STAGES_PER_CHAPTER
	ld	a, PLAYER_SPRITE_KO_PATTERN ; Sets the player KO (sprite only) if ret nz
	ret	nz ; no

; yes: gives the player a password
	ld	hl, globals
	call	ENCODE_PASSWORD
; "PASSWORD:"
	ld	hl, TXT_PASSWORD
	ld	de, namtbl_buffer + 21 * SCR_WIDTH + TXT_PASSWORD.CENTER
	call	PRINT_TEXT
; " password"
	inc	de ; " "
	ld	hl, password
	ld	bc, PASSWORD_SIZE
	ldir
; Did the player also picked up the star?
	ld	a, [game.item_counter]
	bit	BIT_CHAPTER_STAR, a
	and	1 << BIT_CHAPTER_STAR
	ret	z ; no (a = 0, no special animation)
; yes: Sets the player happy (sprite only)
	ld	a, PLAYER_SPRITE_HAPPY_PATTERN
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Password literals
TXT_INPUT_PASSWORD:
	db	"INPUT "
TXT_PASSWORD:
	db	"PASSWORD:" ;  + " " + PASSWORD_SIZE
	.SIZE:		equ ($ + 1 + PASSWORD_SIZE) - TXT_PASSWORD ; "... password"
	db	$00
	.CENTER:	equ (SCR_WIDTH - .SIZE) /2
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Stage over, chapter over, and "GAME OVER" screens
; =============================================================================
;

; -----------------------------------------------------------------------------
; Ends the in-game loop with the stage over logic
STAGE_OVER:
; Plays "stage over" sound
	ld	a, CFG_SOUND_PLAYER_STAGE_OVER
	ld	c, 0 ; highest priority
	call	ayFX_INIT

; Is a tutorial stage
	ld	a, [game.stage]
	cp	FIRST_TUTORIAL_STAGE
	jp	nc, .UNCEREMONIOUSLY ; yes: player disappearing, etc.
; no: sets the player happy, kills the enemies, then player disappearing, etc.

; Sets the player happy (sprite only)
	ld	a, PLAYER_SPRITE_HAPPY_PATTERN
	call	PUT_PLAYER_SPRITE.PATTERN

; Keeps the action for a while
	call	WAIT_ONE_SECOND_FULL_ANIMATION

; For each enemy in the array
	ld	ix, enemies
	ld	b, CFG_ENEMY_COUNT
	ld	de, enemy.SIZE
.KILL_ENEMIES_LOOP:
; Is the enemy slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + enemy.y]
	jp	z, .KILL_ENEMIES_SKIP ; yes
; no: Is the enemy solid?
	bit	BIT_ENEMY_SOLID, [ix + enemy.flags]
	call	nz, KILL_ENEMY.NO_SOUND ; yes: Kills the enemy
; Continues with the next enemy
.KILL_ENEMIES_SKIP:
	add	ix, de
	djnz	.KILL_ENEMIES_LOOP

; Resets the player sprite
	call	PUT_PLAYER_SPRITE

; Enemies disappearing
	ld	b, CFG_ENEMY_PAUSE_M ; medium pause by default
	call	WAIT_FRAMES_FULL_ANIMATION

.UNCEREMONIOUSLY:
; Player disappearing, door cloding, and fade out
	call	PREPARE_MASK.DISAPPEARING
	call	PLAYER_DISAPPEARING
	call	WAIT_ONE_SECOND_ANIMATION
	call	SET_DOORS_CHARSET.CLOSED
	call	WAIT_ONE_SECOND_ANIMATION
	call	DISSCR_FADE_OUT

; Next stage
	ld	hl, game.stage_bcd ; (stage_bcd++)
	ld	a, [hl]
	inc	a
	daa
	ld	[hl], a
	dec	hl ; game.stage
	inc	[hl] ; (stage++)

; Is a tutorial stage?
	ld	a, [hl] ; game.stage
	cp	LAST_TUTORIAL_STAGE
	jp	nz, .TUTORIAL_NOT_OVER
; yes: shows the tutorial over intermission screen
.DEBUG_TUTORIAL_OVER:
	call	REPLAYER.STOP ; (required to unpack default charset)
	call	TUTORIAL_OVER_SCREEN
	call	WAIT_TRIGGER_FOUR_SECONDS
	call	z, PUSH_SPACE_KEY
; Goes directly to the first stage
	ld	a, 1 ; first chapter
	ld	[menu.selected_chapter], a
	jp	NEW_GAME
.TUTORIAL_NOT_OVER:
	cp	FIRST_TUTORIAL_STAGE +1
	jp	nc, NEW_STAGE ; yes: go to next tutorial stage
; no

; Stores the items picked in the current stage
	ld	hl, game.item_counter
; Is the fruit picked?
	ld	a, [stage.flags]
	bit	BIT_STAGE_FRUIT, a
	jr	z, .NO_FRUIT ; no
; yes: counts the fruit
	inc	[hl]
.NO_FRUIT:
; Is the star picked?
	bit	BIT_STAGE_STAR, a
	jr	z, .NO_STAR ; no
; yes: marks the star as picked up
	set	BIT_CHAPTER_STAR, [hl]
.NO_STAR:

; Is the end of a chapter?
	ld	a, [game.stage]
.LOOP:
	sub	STAGES_PER_CHAPTER
	jp	c, NEW_STAGE ; no: go to next stage
	jr	nz, .LOOP
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Chapter over logic
CHAPTER_OVER:
; yes: is the secret chapter?
	ld	a, [game.chapter]
	cp	SECRET_CHAPTER
	jp	z, GOOD_ENDING ; yes: shows the good ending

; no: plays chapter over jingle
	ld	a, CFG_SONG_CHAPTER_OVER
	call	PLAY_SONG

; Shows the chapter over intermission screen
	call	CHAPTER_OVER_SCREEN
	jp	z, BAD_ENDING ; shows the bad ending

; Goes to the next chapter
	call	DISSCR_FADE_OUT
; Checks for the secret chapter (because music will be already on)
	ld	a, [game.chapter]
	cp	SECRET_CHAPTER
	jp	z, NEW_CHAPTER.SONG_OK
	jp	NEW_CHAPTER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game over
GAME_OVER:
; Prepares game over screen
	call	CLS_NAMTBL
; "GAME OVER"
	ld	hl, .TXT
	ld	de, namtbl_buffer + 10 * SCR_WIDTH
	call	PRINT_CENTERED_TEXT

; Plays game over jingle
	ld	a, CFG_SONG_GAME_OVER
	call	PLAY_SONG
; Shows game over screen
	call	ENASCR_FADE_IN
	call	WAIT_FOUR_SECONDS

; Continues with the main menu
	call	REPLAYER.STOP
	jp	MAIN_MENU

; Literals
.TXT:
	db	"GAME OVER", $00
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Bad and good ending screens and routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bad ending logic
BAD_ENDING:
; Prepares ending screen
	call	CLS_NAMTBL
	call	CLS_SPRATR ; Removes the intermission screen sprite
	halt
	call	ENASCR_NO_FADE

; Plays bad ending song
	ld	a, CFG_SONG_BAD_ENDING
	call	PLAY_SONG

; Shows the bad ending screen
	call	BAD_ENDING_SEQUENCE
	call	WAIT_TRIGGER
	call	DISSCR_FADE_OUT

; Prepares for the credits screen
	call	CLS_NAMTBL
	halt
	call	ENASCR_NO_FADE
; Shows the credits
	ld	hl, GOOD_ENDING.TXT_CREDITS
	call	ATTRACT_PRINT_SEQUENCE
	call	WAIT_TRIGGER
	call	DISSCR_FADE_OUT

; Continues with the game over screen
	jp	GAME_OVER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Bad ending screen
BAD_ENDING_SEQUENCE:
; "SORRY, STEVEDORE"
	ld	hl, INIT_CHAPTER_OVER_SCREEN.TXT
	ld	de, namtbl_buffer + 4 * SCR_WIDTH
	call	INIT_ATTRACT_PRINT
	call	.PRINT_LINE_LF_LF
; "BUT THE LIGHTHOUSE KEEPER"
	call	.PRINT_NEXT_LINE_LF_LF
; "WASN'T KIDNAPPED AT ALL."
	ld	hl, .TXT
	call	INIT_ATTRACT_PRINT.TARGET_OK
	call	.PRINT_LINE_LF_LF

; (pause and extra space line)
	call	WAIT_TWO_SECONDS
	call	ATTRACT_PRINT_MOVE_LF

; "SHE IS THE CAPTAIN PIRATE,"
	call	.PRINT_NEXT_LINE_LF_LF
; "LOOKING FOR PANTOJOS' GOLD!"
	call	.PRINT_NEXT_LINE_LF_LF

; (pause and extra space line)
	call	WAIT_TWO_SECONDS
	call	ATTRACT_PRINT_MOVE_LF

; "SHE WON'T DANCE WITH YOU"
	call	.PRINT_NEXT_LINE_LF_LF
; "AFTER ALL..."
	; jr	.PRINT_NEXT_LINE_LF_LF ; falls through

.PRINT_NEXT_LINE_LF_LF:
	call	INIT_ATTRACT_PRINT.NEXT_LINE
.PRINT_LINE_LF_LF:
	call	ATTRACT_PRINT_LINE
	call	ATTRACT_PRINT_MOVE_LF
	jp	ATTRACT_PRINT_MOVE_LF

; Literals
.TXT:
	db	"WASN", CHAR_APOSTROPHE, "T KIDNAPPED AT ALL", CHAR_DOT, $00
	db	"SHE IS THE PIRATE CAPTAIN", CHAR_COMMA, $00
	db	"LOOKING FOR PANTOJOS", CHAR_APOSTROPHE, " GOLD", CHAR_EXCLAMATION, $00
	db	"SHE WON", CHAR_APOSTROPHE, "T DANCE WITH YOU", $00
	db	"AFTER ALL", CHAR_DOT, CHAR_DOT, CHAR_DOT, $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Good ending logic
GOOD_ENDING:
; Prepares an empty screen with the ending charset at bank #1
	call	CLS_NAMTBL
	call	CLS_SPRATR
	call	SET_ENDING_CHARSET
	halt
	call	ENASCR_NO_FADE

; Plays the good ending song
	ld	a, CFG_SONG_GOOD_ENDING
	call	PLAY_SONG
	call	WAIT_TWO_SECONDS

; Shows the first ending image and text
	ld	hl, .NAMTBL
	call	.PRINT_BLOCK
	push	hl ; preserves next image pointer
	ld	hl, .TXT_1
	call	.ATTRACT_PRINT_SEQUENCE

; Shows the second ending image and text
	pop	hl ; restores image pointer
	call	.PRINT_BLOCK
	push	hl ; preserves next image pointer
	ld	hl, .TXT_2
	call	.ATTRACT_PRINT_SEQUENCE

; Shows the third ending image and text
	pop	hl ; restores image pointer
	call	.PRINT_BLOCK
	; push	hl ; preserves next image pointer
	ld	hl, .TXT_3
	call	.ATTRACT_PRINT_SEQUENCE

; ; Shows the fourth ending image and text
; 	pop	hl ; restores image pointer
; 	call	.PRINT_BLOCK

; Shows the credits
	call	ATTRACT_PRINT_CLS
	call	LDIRVM_NAMTBL_FADE_INOUT
	call	WAIT_TWO_SECONDS
	ld	hl, .TXT_CREDITS
	call	ATTRACT_PRINT_SEQUENCE
	call	WAIT_TRIGGER

; Stops the music, fade out, and restores default charset
	call	REPLAYER.STOP
	call	DISSCR_FADE_OUT
	call	SET_DEFAULT_CHARSET

; Continues with the main menu
	jp	MAIN_MENU.FADE_OUT_OK

; Prints one of the ending images
.PRINT_BLOCK:
	ld	de, namtbl_buffer + 8 *SCR_WIDTH + .CENTER
	ld	bc, .HEIGHT << 8 + .WIDTH
	jp	PRINT_BLOCK

.ATTRACT_PRINT_SEQUENCE:
; Fade in
	push	hl ; preserves text pointer
	call	ATTRACT_PRINT_CLS
	call	ENASCR_FADE_IN
	call	WAIT_FOUR_SECONDS
	pop	hl ; restores text pointer
; "CONGRATULATIONS, STEVEDORE", etc.
	call	ATTRACT_PRINT_SEQUENCE
	jp	WAIT_FOUR_SECONDS

; Good ending slides' NAMTBL
.NAMTBL:
	incbin	"games/stevedore/gfx/ending.png.nam"
; Ending charset-related symbolic constants
	.WIDTH:		equ 16
	.HEIGHT:	equ 8
	.SIZE:		equ .WIDTH * .HEIGHT
	.CENTER:	equ (SCR_WIDTH - .WIDTH) /2

; Literals
.TXT_1:
	db	"CONGRATULATIONS", CHAR_COMMA, " STEVEDORE", CHAR_DOT, $00
	db	"YOU FOUND THE LIGHTHOUSE KEEPER", $00
	db	CHAR_DOT, CHAR_DOT, CHAR_DOT, "AND PANTOJOS", CHAR_APOSTROPHE, " GOLD", CHAR_EXCLAMATION, $00
	db	$00
.TXT_2:
	db	"NOW IT", CHAR_APOSTROPHE, "S TIME", $00
	db	"TO GO BACK HOME", $00
	db	$00
.TXT_3:
	db	"LOOK AT THOSE FIREWORKS", CHAR_EXCLAMATION, $00
	db	"IT SEEMS THAT YOU ARE ON TIME", $00
	db	"FOR THE SUMMER PARTY DANCE", CHAR_EXCLAMATION, $00
	db	$00
.TXT_CREDITS:
	db	"STEVEDORE", $00
	db	"@ THENESTRUO ", CHAR_AMPERSAND, " WONDER 2020", $00
	db	ASCII_DEL
	db	"CONCEPT", CHAR_COMMA, " CODE ", CHAR_AMPERSAND, " GFX:", $00
	db	"THENESTRUO", $00
	db	ASCII_DEL
	db	"MUSIC ", CHAR_AMPERSAND, " SFX:", $00
	db	"WONDER", $00
	db	ASCII_DEL
	db	"SPECIAL THANKS TO:", $00
	db	"CARNIVIUS", $00, ASCII_BS
	db	"JOS TESSMSX", $00, ASCII_BS
	db	"MANUEL PAZOS", $00, ASCII_BS
	db	"PEPE VILA", $00, ASCII_BS
	db	"SAPPHIRE", $00
	db	ASCII_DEL
	db	"GREETINGS TO:", $00
	db	"ANTXIKO GORJON", $00, ASCII_BS
	db	"GARAMITO", $00, ASCII_BS
	db	"IBAN NIETO", $00, ASCII_BS
	db	"ISHWIN MSX", $00, ASCII_BS
	db	"JAIME KALEIDO", $00, ASCII_BS
	db	"JAVIER PE", CHAR_N_TILDE, "A", $00, ASCII_BS
	db	"JIMMY", $00, ASCII_BS
	db	"JON CORTAZAR", $00, ASCII_BS
	db	"KONAMITO", $00, ASCII_BS
	db	"PIPO", $00, ASCII_BS
	db	"REIDRAC", $00, ASCII_BS
	db	"ROBSY", $00, ASCII_BS
	db	"SANTI ONTA", CHAR_N_TILDE, "ON", $00, ASCII_BS
	db	"SIRELION", $00, ASCII_BS
	db	"TAKAMICHI", $00, ASCII_BS
	db	"UNEPIC FRAN", $00, ASCII_BS
	db	"VEB XENON", $00
	db	ASCII_DEL
	db	"AND THANK YOU FOR PLAYING", $00
	db	ASCII_DEL
	db	"YOU ARE GREAT", CHAR_EXCLAMATION, $00
	db	$00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints an entire sequence in attract-mode print
ATTRACT_PRINT_SEQUENCE:
	ld	de, namtbl_buffer + 17 * SCR_WIDTH
	call	INIT_ATTRACT_PRINT
.LOOP_1:
	call	ATTRACT_PRINT_LINE
; Reads the next character
	ld	hl, [attract_print.source]
	ld	a, [hl]
; Is the end marker?
	or	a ; $00
	ret	z ; yes: exits the routine
; no: Is the CLS marker?
	cp	ASCII_DEL
	jr	z, .CLS ; yes: clears the entire text
; no: Is the BS marker?
	cp	ASCII_BS
	jr	z, .BS ; yes: clears the current line
; no: The next line will be print below
	call	ATTRACT_PRINT_MOVE_LF
	call	ATTRACT_PRINT_MOVE_LF
	call	INIT_ATTRACT_PRINT.NEXT_LINE
	jr	.LOOP_1

; Clears the text
.CLS:
	call	WAIT_TWO_SECONDS
	call	ATTRACT_PRINT_CLS
; Continues with the next line
	ld	hl, [attract_print.source]
	inc	hl
	jr	ATTRACT_PRINT_SEQUENCE

; Clears the current line
.BS:
	call	WAIT_ONE_SECOND
	ld	hl, [attract_print.target_line]
	call	CLEAR_LINE
; Continues with the next line
	ld	hl, [attract_print.source]
	inc	hl
	call	INIT_ATTRACT_PRINT.TARGET_OK
	jr	.LOOP_1
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints one line in attract-mode print
ATTRACT_PRINT_LINE:
; Prints one character
	call	ATTRACT_PRINT_CHAR
	jr	z, .END ; The end of the string has been reached
; Blits the NAMTBL buffer and continues
	halt
	call	LDIRVM_NAMTBL
	jr	ATTRACT_PRINT_LINE
.END:
; Skips the terminator character
	inc	hl
	ld	[attract_print.source], hl
; Blits the NAMTBL buffer
	halt
	jp	LDIRVM_NAMTBL
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fills the NAMTBL buffer with the blank space character ($20, " " ASCII)
; but only the attract mode-used lines (lines 17 to 21)
ATTRACT_PRINT_CLS:
	ld	hl, namtbl_buffer + 17 * SCR_WIDTH
	ld	de, namtbl_buffer + 17 * SCR_WIDTH + 1
	ld	bc, 5 * SCR_WIDTH - 1
	ld	[hl], $20 ; " " ASCII
	ldir
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Charset-related custom routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Sets the default charset in all banks
SET_DEFAULT_CHARSET:
; Charset (1/2: CHRTBL)
	ld	hl, DEFAULT_CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL
; Charset (2/2: CLRTBL)
	ld	hl, DEFAULT_CLRTBL_PACKED
	jp	UNPACK_LDIRVM_CLRTBL
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Overwrites the charset with the title charset at bank #0
SET_TITLE_CHARSET:
; Title charset (1/2: CHRTBL)
	ld	hl, TITLE_CHRTBL_PACKED
	ld	de, CHRTBL + TITLE_CHAR_FIRST *8
	call	.UNPACK_LDIRVM
; Title charset (2/2: CLRTBL)
	ld	hl, TITLE_CLRTBL_PACKED
	ld	de, CLRTBL + TITLE_CHAR_FIRST *8
.UNPACK_LDIRVM:
	ld	bc, TITLE_CXRTBL_SIZE
	jp	UNPACK_LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Overwrites the charset with the ending charset at bank #1
SET_ENDING_CHARSET:
; Ending charset (1/2: CHRTBL)
	ld	hl, ENDING_CHRTBL_PACKED
	ld	de, CHRTBL + CHRTBL_SIZE
	call	.UNPACK_LDIRVM
; Ending charset (2/2: CLRTBL)
	ld	hl, ENDING_CLRTBL_PACKED
	ld	de, CLRTBL + CLRTBL_SIZE
.UNPACK_LDIRVM:
	ld	bc, ENDING_CXRTBL_SIZE
	jp	UNPACK_LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sets the doors charset to either the closed or the open doors
SET_DOORS_CHARSET:

.CLOSED:
; Chooses the closed doors from the dynamic charset
	ld	hl, DYNAMIC_CHARSET.CHRTBL_CLOSED_DOOR
	jr	.HL_OK

.OPEN:
; Chooses the open doors from the dynamic charset
	ld	hl, DYNAMIC_CHARSET.CHRTBL_OPEN_DOOR
	; jr	.HL_OK ; falls through

.HL_OK:
; LDIRVMs CHRTBL
	ld	de, CHRTBL + CHAR_FIRST_DOOR * 8
	call	.ONE_BANK
	call	.ONE_BANK
	call	.ONE_BANK
; Moves source to CLRTBL
	ld	bc, DYNAMIC_CHARSET.SIZE
	add	hl, bc
; LDIRVMs CLRTBL
	ld	de, CLRTBL + CHAR_FIRST_DOOR * 8
	call	.ONE_BANK
	call	.ONE_BANK
	; jr	.ONE_BANK ; falls through

; Replaces door characters in one bank
.ONE_BANK:
	push	de ; preserves destination
	push	hl ; preserves source
	ld	bc, DYNAMIC_CHARSET.DOOR_SIZE
	call	LDIRVM
	pop	de ; restores source in de
	pop	hl ; restores destination in hl
	ld	bc, CHRTBL_SIZE
	add	hl, bc ; moves destination to next bank
	ex	de, hl ; source and destination in proper registers
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Slowly opens the rock door in bank 1, with background animation
SET_DOORS_CHARSET.OPEN_ANIMATED:
; Initializes pointer for both CHRTBL and CLRTBL (lower part of the door)
	ld	de, DYNAMIC_CHARSET.CHRTBL_OPEN_DOOR + DYNAMIC_CHARSET.DOOR_SIZE -1
	ld	hl, CHRTBL + 1*CHRTBL_SIZE + (CHAR_SECOND_DOOR +4) *8 -1
	exx
	ld	de, DYNAMIC_CHARSET.CHRTBL_OPEN_DOOR + DYNAMIC_CHARSET.SIZE + DYNAMIC_CHARSET.DOOR_SIZE -1
	ld	hl, CLRTBL + 1*CHRTBL_SIZE + (CHAR_SECOND_DOOR +4) *8 -1
; Blits the lower part of the door
	call	.BLIT_CHARS
; Initializes pointer for both CHRTBL and CLRTBL (lower part of the door)
	ld	de, DYNAMIC_CHARSET.CHRTBL_OPEN_DOOR + DYNAMIC_CHARSET.DOOR_SIZE -17
	ld	hl, CHRTBL + 1*CHRTBL_SIZE + (CHAR_SECOND_DOOR +2) *8 -1
	exx
	ld	de, DYNAMIC_CHARSET.CHRTBL_OPEN_DOOR + DYNAMIC_CHARSET.SIZE + DYNAMIC_CHARSET.DOOR_SIZE -17
	ld	hl, CLRTBL + 1*CHRTBL_SIZE + (CHAR_SECOND_DOOR +2) *8 -1
; Blits the upper part of the door
	; jr	.BLIT_CHARS ; (falls through)

; Blits the chars of a door (both chars) line by line
.BLIT_CHARS:
	ld	b, 8
.LINE_LOOP:
	push	bc ; preserves lines counter
	push	de ; preserves RAM source address
	push	hl ; preserves VRAM target address
; Very slowly (6 frames per line)
	ld	b, 6
.WAIT_LOOP:
; Synchronization (halt), charset and player animations
	push	bc ; preserves frames counter
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
	call	UPDATE_PLAYER_ANIMATION_CONDITIONAL
	pop	bc ; restores frames counter
	djnz	.WAIT_LOOP
; Blits a line of the door (both chars, both CHRTBL and CLRTBL)
	pop	hl ; restores VRAM target address
	pop	de ; restores RAM source address
	exx	; swaps to CHRTBL pointers
	call	.BLIT_CXRTBL_LINE
	exx	; swaps to CLRTBL pointers
	call	.BLIT_CXRTBL_LINE
; Next line
	pop	bc ; restores lines counter
	djnz	.LINE_LOOP
	ret

; Blits a line of the door (both chars, either CHRTBL or CLRTBL)
.BLIT_CXRTBL_LINE:
	ld	bc, -8 ; will move to the left char
	call	.BLIT_CHAR_LINE
	ld	bc, 7 ; will move to the previous line of the right char
	; jr	.BLIT_CHAR_LINE ; falls through

; Blits a line of a char of a door, either CHRTBL or CLRTBL
.BLIT_CHAR_LINE:
	push	hl ; preserves VRAM target address
	push	de ; preserves RAM source address
; Copies the byte to VRAM
	ld	a, [de]
	call	WRTVRM
; Applies displacement
	pop	hl ; restores RAM source
	add	hl, bc
	ex	de, hl ; updated RAM source in de
	pop	hl ; restores VRAM target
	add	hl, bc ; updated VRAM target in hl
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes the dynamic charset
INIT_DYNAMIC_CHARSET:
; Initializes all the dynamic charset in all three banks
	call	UPDATE_DYNAMIC_CHARSET.BANK_1_1
	call	UPDATE_DYNAMIC_CHARSET.BANK_1_2
	call	UPDATE_DYNAMIC_CHARSET.BANK_1_3
	call	UPDATE_DYNAMIC_CHARSET.BANK_1_4
	call	UPDATE_DYNAMIC_CHARSET.BANK_2_1
	call	UPDATE_DYNAMIC_CHARSET.BANK_2_2
	call	UPDATE_DYNAMIC_CHARSET.BANK_2_3
	jp	UPDATE_DYNAMIC_CHARSET.BANK_2_4
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the water and lava surfaces
UPDATE_DYNAMIC_CHARSET:
; Should the charset be updated in this frame?
	ld	hl, JIFFY
	ld	a, [hl]
	and	$07 ; (once each 8 frames)

; Partial updates of one bank each frame
	ld	hl, .JUMP_TABLE
	jp	JP_TABLE
.JUMP_TABLE:
	dw	.BANK_1_2 ; The order is 2, 1, 4, 3
	dw	.BANK_1_1 ; to keep partial water animations
	dw	.BANK_1_4 ; and partial lava animations
	dw	.BANK_1_3 ; as close as possible
	dw	.BANK_2_2 ; for aesthetic reasons
	dw	.BANK_2_1
	dw	.BANK_2_4
	dw	.BANK_2_3

.BANK_1_1: ; 4 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED
	ld	de, CHRTBL + CHRTBL_SIZE + $9a * 8
	jp	.UPDATE_CXRTBL

.BANK_1_2: ; 4 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 4 *8
	ld	de, CHRTBL + CHRTBL_SIZE + $a0 * 8
	jp	.UPDATE_CXRTBL

.BANK_1_3: ; 4 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 8 *8
	ld	de, CHRTBL + CHRTBL_SIZE + $a8 * 8
	jp	.UPDATE_CXRTBL

.BANK_1_4: ; 3 + 3 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 12 *8
	ld	de, CHRTBL + CHRTBL_SIZE + CHAR_WATER_SURFACE * 8
	ld	bc, 3 *8
	call	.UPDATE_CXRTBL_BC_OK
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 15 *8
	ld	de, CHRTBL + CHRTBL_SIZE + CHAR_LAVA_SURFACE * 8
	ld	bc, 3 *8
	jp	.UPDATE_CXRTBL_BC_OK

.BANK_2_1: ; 4 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED
	ld	de, CHRTBL + CHRTBL_SIZE * 2 + $9a * 8
	jp	.UPDATE_CXRTBL

.BANK_2_2: ; 4 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 4 *8
	ld	de, CHRTBL + CHRTBL_SIZE * 2 + $a0 * 8
	jp	.UPDATE_CXRTBL

.BANK_2_3: ; 4 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 8 *8
	ld	de, CHRTBL + CHRTBL_SIZE * 2 + $a8 * 8
	jp	.UPDATE_CXRTBL

.BANK_2_4: ; 3 + 3 characters
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 12 *8
	ld	de, CHRTBL + CHRTBL_SIZE * 2 + CHAR_WATER_SURFACE * 8
	ld	bc, 3 *8
	call	.UPDATE_CXRTBL_BC_OK
	ld	hl, DYNAMIC_CHARSET.CHRTBL_ANIMATED + 15 *8
	ld	de, CHRTBL + CHRTBL_SIZE * 2 + CHAR_LAVA_SURFACE * 8
	ld	bc, 3 *8
	jp	.UPDATE_CXRTBL_BC_OK

.UPDATE_CXRTBL:
	ld	bc, 4 *8 ; 4 characters by default
.UPDATE_CXRTBL_BC_OK:
; Locates proper source (based on JIFFY)
	ld	a, [JIFFY]
	and	$18
; Moves to the proper source
	jp	z, .HL_BC_OK ; source is already ok
	push	bc ; preserves size
	ld	bc, DYNAMIC_CHARSET.ANIMATED_SIZE
.LOOP:
	add	hl, bc
	sub	$08
	jp	nz, .LOOP
.HL_OK:
	pop	bc ; restores size
.HL_BC_OK:
; LDIRVMs CHRTBL
	push	bc ; preserves size
	push	de ; preserves destination
	push	hl ; preserves source
	call	LDIRVM
; Moves source to CLRTBL
	pop	hl ; restores source
	ld	bc, DYNAMIC_CHARSET.SIZE
	add	hl, bc
; Moves destination to CLRTBL
	pop	de ; restores destination
	ld	a, d
	xor	$20 ; ((CHRTBL >> 8) ^ (CLRTBL >> 8))
	ld	d, a
; LDIRVMs CLRTBL
	pop	bc ; restores size
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Dynamic charset binary data
DYNAMIC_CHARSET:
	incbin	"games/stevedore/gfx/charset_dynamic.png.chr"
	.CHRTBL_CLOSED_DOOR:	equ DYNAMIC_CHARSET
	.DOOR_SIZE:		equ 8 *8 ; 8 chars
	.CHRTBL_OPEN_DOOR:	equ DYNAMIC_CHARSET + .DOOR_SIZE
	.CHRTBL_ANIMATED:	equ DYNAMIC_CHARSET + .DOOR_SIZE * 2
	.ANIMATED_SIZE:		equ 18 *8 ; 18 chars
	.SIZE:			equ $ - DYNAMIC_CHARSET

	incbin	"games/stevedore/gfx/charset_dynamic.png.clr"
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Player animation and dynamic charset animation custom routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Waits three, two, or one second(s), with enemies and dynamic charset animation
; (no player)
WAIT_ONE_SECOND_FULL_ANIMATION:
	ld	hl, frame_rate
	ld	b, [hl]
	; jp	WAIT_FRAMES_ANIMATION ; falls through

WAIT_FRAMES_FULL_ANIMATION:
	push	bc ; preserves counter

; Synchronization (halt)
	halt

; Blit buffers to VRAM
	call	EXECUTE_VPOKES
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET

; Mimics game logic
	call	RESET_SPRITES
	call	UPDATE_ENEMIES
	call	UPDATE_BULLETS
	call	UPDATE_SPRITEABLES	; (spriteables after enemies
	call	UPDATE_PUSHABLES	; for the splash to show in foreground)
	call	DRAW_SPRITEABLES

	pop	bc ; restores counter
	djnz	WAIT_FRAMES_FULL_ANIMATION
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waits three, two, or one second(s), with player and dynamic charset animation
; (no enemies, no pushables, no spriteables)
WAIT_FOUR_SECONDS_ANIMATION:
	call	WAIT_ONE_SECOND_ANIMATION
	; jp	WAIT_THREE_SECONDS_ANIMATION ; falls through

WAIT_THREE_SECONDS_ANIMATION:
	call	WAIT_ONE_SECOND_ANIMATION
	; jp	WAIT_TWO_SECONDS_ANIMATION ; falls through

WAIT_TWO_SECONDS_ANIMATION:
	call	WAIT_ONE_SECOND_ANIMATION
	; jp	WAIT_ONE_SECOND_ANIMATION ; falls through

WAIT_ONE_SECOND_ANIMATION:
	ld	hl, frame_rate
	ld	b, [hl]
	; jp	WAIT_FRAMES_ANIMATION ; falls through

WAIT_FRAMES_ANIMATION:
	push	bc ; preserves counter
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
	call	UPDATE_PLAYER_ANIMATION
	call	PUT_PLAYER_SPRITE
	pop	bc ; restores counter
	djnz	WAIT_FRAMES_ANIMATION
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Waits for the trigger, with dynamic charset animation
WAIT_TRIGGER_ANIMATION:
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
; Checks trigger
	ld	a, [input.edge]
	bit	BIT_TRIGGER_A, a
	jr	z, WAIT_TRIGGER_ANIMATION
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prepares the SPRATR buffer for the player appearing/disappearing animations
PREPARE_MASK:
.APPEARING:
	ld	b, SPRITE_HEIGHT / 2
	jr	.B_OK
.DISAPPEARING:
	ld	b, SPRITE_HEIGHT
.B_OK:
	ld	a, [player.y]
	add	CFG_SPRITES_Y_OFFSET
	sub	b
	ld	[spratr_buffer], a
	ld	[spratr_buffer +4], a
	add	b
	ld	[spratr_buffer +8], a
	ld	[spratr_buffer +12], a
	add	b
	ld	[spratr_buffer +16], a
	ld	[spratr_buffer +20], a
; Resets the volatile sprites
	ld	hl, volatile_sprites
	ld	[hl], SPAT_END
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Animation of player appearing
PLAYER_APPEARING:
.ANIMATION:
	ld	ix, UPDATE_PLAYER_ANIMATION_CONDITIONAL
.IX_OK:
	ld	b, SPRITE_HEIGHT / 2
.LOOP:
	push	bc ; (preserves counter)
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
; Player appears
	ld	hl, spratr_buffer
	dec	[hl]
	ld	hl, spratr_buffer +4
	dec	[hl]
	ld	hl, spratr_buffer +16
	inc	[hl]
	ld	hl, spratr_buffer +20
	inc	[hl]
	call	JP_IX
; Loop condition
	pop	bc ; (restores counter)
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Animation of player disappearing
PLAYER_DISAPPEARING:
	ld	ix, PUT_PLAYER_SPRITE.ONLY_MOVE
	jr	.IX_OK
.ANIMATION:
	ld	ix, UPDATE_PLAYER_ANIMATION_CONDITIONAL
	; jp	.IX_OK ; (falls through)
.IX_OK:
	ld	b, SPRITE_HEIGHT / 2 +1
.LOOP:
	push	bc ; (preserves counter and animation flag)
	halt
	call	LDIRVM_SPRATR
	call	UPDATE_DYNAMIC_CHARSET
; Player disappears
	ld	hl, spratr_buffer
	inc	[hl]
	ld	hl, spratr_buffer +4
	inc	[hl]
	ld	hl, spratr_buffer +16
	dec	[hl]
	ld	hl, spratr_buffer +20
	dec	[hl]
	call	JP_IX
; Loop condition
	pop	bc ; (restores counter and animation flag)
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates player animation if its not an special pattern,
; and puts the player sprite
UPDATE_PLAYER_ANIMATION_CONDITIONAL:
; Is the pattern special?
	ld	a, [player_spratr.pattern]
	cp	PLAYER_SPRITE_KO_PATTERN
	jp	nc, PUT_PLAYER_SPRITE.ONLY_MOVE ; yes: puts the sprite without touching the pattern
; no: animates the player and puts the sprite
	call	UPDATE_PLAYER_ANIMATION
	jp	PUT_PLAYER_SPRITE
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Input-related custom routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; "Push space key" routine
; ret z: SPACE key or trigger A
; ret nz: SELECT key or trigger B
PUSH_SPACE_KEY:
; Prints "push space key" text and blit
	call	.PRINT_AND_BLIT

; Pauses until trigger
.TRIGGER_LOOP:
	halt
	ld	a, [input.edge]
	bit	BIT_TRIGGER_A, a
	jr	nz, .BLINK ; trigger
	and	$60 ; ((1 << BIT_BUTTON_SELECT) OR (1 << BIT_TRIGGER_B))
	ret	nz
	jr	.TRIGGER_LOOP

.BLINK:
; Makes "push space key" text blink
	ld	b, 10 ; times to blink
.BLINK_LOOP:
	push	bc ; preserves counter
; Removes the "push space key" text, blit, and pause
	call	.CLEAR_AND_BLIT
	halt
	halt
	halt
; Prints "push space key" text, blit and pause
	call	.PRINT_AND_BLIT
	halt
	halt
	halt
	pop	bc ; restores counter
	djnz	.BLINK_LOOP
; Removes the "push space key" text, and blit
	call	.CLEAR_AND_BLIT
; ret z
	xor	a
	ret

; Prints "push space key" text and blit
.PRINT_AND_BLIT:
	ld	hl, .TXT
	ld	de, namtbl_buffer + 19 *SCR_WIDTH
	call	PRINT_CENTERED_TEXT
	jp	LDIRVM_NAMTBL

; Removes the "push space key" text and blit
.CLEAR_AND_BLIT:
	ld	hl, namtbl_buffer + 19 *SCR_WIDTH
	call	CLEAR_LINE
	jp	LDIRVM_NAMTBL

; Literals
.TXT:
	db	"PUSH SPACE KEY", $00
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Checks START button level, or if trigger B has been held
; ret z: yes
; ret nz: no
CHECK_RESTART_KEY:
; Is START button pushed?
	ld	a, [input.edge]
	cpl
	bit	BIT_BUTTON_START, a
	ret	z ; yes: ret z
; no: also checks trigger B hold
	; jp	CHECK_TRIGGER_B_HELD ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Checks if the trigger B has been held for enough frames
; ret z: yes
; ret nz: no
CHECK_TRIGGER_B_HELD:
; Is trigger B held?
	ld	a, [input.level]
	bit	BIT_TRIGGER_B, a
	ld	hl, input.trigger_b_framecounter
	jr	nz, .COUNT ; yes
; no: resets the framecounter
	ld	[hl], 0
; ret nz
	or	$ff
	ret

.COUNT:
; Has been held for enough frames??
	ld	a, [hl]
	sub	FRAMES_TO_TRIGGER_B
	jr	nz, .INC ; no
; yes: resets the framecounter
	ld	[hl], a
; ret z
	ret

.INC:
; no: increases the framecounter
	inc	[hl]
; ret nz
	or	$ff
	ret
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Text-related custom routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Writes a 0-terminated string centered in the NAMTBL buffer
; and moves the NAMTBL buffer pointer two lines down
; param hl: source string
; param de: NAMTBL buffer pointer (beginning of the line)
; ret hl: next source string
; ret de: next NAMTBL buffer pointer
PRINT_CENTERED_TEXT_LF_LF:
	push	de ; preserves destination
	call	PRINT_CENTERED_TEXT
	ex	de, hl ; preserves source in de
	pop	hl ; restores destination
	ld	a, 2 * SCR_WIDTH
	call	ADD_HL_A
	ex	de, hl ; restores source in hl, destination in de
	inc	hl ; (skips the \0)
	ret
; -----------------------------------------------------------------------------

; EOF

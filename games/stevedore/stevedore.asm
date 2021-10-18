
; -----------------------------------------------------------------------------
; MSX symbolic constants
	include	"lib/msx/symbols.asm"
; -----------------------------------------------------------------------------

;
; =============================================================================
;	ROM
; =============================================================================
;

; =============================================================================
; 	Game data in page 0
; =============================================================================

; -----------------------------------------------------------------------------
	include "lib/page0.asm"

	db	"Stevedore - MSX ROM cartridge image", ASCII_CR, ASCII_LF
	db	"(c) theNestruo & Wonder 2020", ASCII_CR, ASCII_LF
	db	"Version 1.2 (2020-10-18)", ASCII_CR, ASCII_LF
	db	ASCII_EOF

; Game data in page 0
	include "games/stevedore/stevedore.data.asm"

	db	"Thank you for taking a look inside!", $00
	db	"Long live MSX retrodevs and gamers!", $00

	include "lib/page0_end.asm"
; -----------------------------------------------------------------------------

; =============================================================================
;	MSXlib core configuration, routines and initialization
; =============================================================================

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization

; Define the ROM size in kB (8kB, 16kB, 24kB, 32kB, or 48kB)
; Includes search for page 2 slot/subslot at start
; and declares routines to set the page 0 cartridge's slot/subslot
; and to restore the BIOS at page 0
	CFG_INIT_ROM_SIZE: equ 48

; Define if the game needs 16kB instead of 8kB
; RAM will start at the beginning of the page 2 instead of $e000
; and availability will be checked at start
	; CFG_INIT_16KB_RAM:

	include "lib/msx/cartridge.asm"

; Splash screens
SPLASH_SCREENS_PACKED_TABLE:
	db	1
	dw	.MSXLIB
.MSXLIB:
	incbin	"splash/msxlib.bin.zx0"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Interrupt routine (hook)

; Define to disable automatic input read in the hook
	; CFG_HOOK_DISABLE_AUTO_INPUT:

; Define to keep BIOS' KEYINT to skip keyboard scan, TRGFLG, OLDKEY/NEWKEY, etc.
	; CFG_HOOK_KEEP_BIOS_KEYINT:

	include "lib/msx/hook.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Input routines (BIOS-based)
	include "lib/msx/io/input.asm"

; Keyboard input routines
; (note: these routines change OLDKEY/NEWKEY semantics!)
	include "lib/msx/io/keyboard.asm"

; Timing and wait routines
	include "lib/msx/io/timing.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Replayer routines (PT3-based implementation)

; Define to enable packed songs when using the PT3-based implementation
	CFG_PT3_PACKED:

; Define to use headerless PT3 files (without first 100 bytes)
	CFG_PT3_HEADERLESS:

; PT3Player data
SONG_TABLE:
	dw	SONG_PACKED.WAREHOUSE		; 0: Warehouse
	dw	SONG_PACKED.LIGHTHOUSE		; 1: Lighthouse
	dw	SONG_PACKED.SHIP		; 2: Ship
	dw	SONG_PACKED.JUNGLE		; 3: Jungle
	dw	SONG_PACKED.VOLCANO		; 4: Volcano
	dw	SONG_PACKED.TEMPLE		; 5: Temple
	dw	SONG_PACKED.SECRET		; 6: Secret

	dw	SONG_PACKED.MAIN_THEME		; 7
	dw	SONG_PACKED.CHAPTER_OVER	; 8
	dw	SONG_PACKED.GAME_OVER		; 9
	dw	SONG_PACKED.BAD_ENDING		; 10
	dw	SONG_PACKED.GOOD_ENDING		; 11

	CFG_SONG_MAIN_THEME:	equ	7
	CFG_SONG_CHAPTER_OVER:	equ	8 + $80 ; (not looped: short jingle)
	CFG_SONG_GAME_OVER:	equ	9 + $80 ; (not looped: short jingle)
	CFG_SONG_BAD_ENDING:	equ	10
	CFG_SONG_GOOD_ENDING:	equ	11

	include	"lib/msx/io/replayer_pt3.asm"

; Define to use relative volume version (the default is fixed volume)
	; CFG_AYFX_RELATIVE:

; ayFX sound bank
SOUND_BANK:
	incbin	"games/stevedore/sfx/sound_bank.afb"

	; CFG_SOUND_PLAYER_JUMP:	equ  1 -1
	; CFG_SOUND_PLAYER_LAND:	equ  2 -1
	; CFG_SOUND_PLAYER_PUSH:	equ  4 -1
	CFG_SOUND_INTRO_CRASH:		equ  4 -1
	CFG_SOUND_INTRO_LAND:		equ  2 -1
	CFG_SOUND_PLAYER_KILLED:	equ 13 -1
	CFG_SOUND_PLAYER_STAGE_OVER:	equ 14 -1
	CFG_SOUND_ITEM_FRUIT:		equ  5 -1
	CFG_SOUND_ITEM_KEY:		equ 11 -1
	CFG_SOUND_ITEM_STAR:		equ  6 -1
	CFG_SOUND_ENEMY_KILLED:		equ 12 -1
	; CFG_SOUND_ENEMY_RESPAWN:	equ  3 -1
	CFG_SOUND_ENEMY_SHOOT:		equ  7 -1
	CFG_SOUND_SPLASH:		equ  8 -1
	CFG_SOUND_PASSWORD_VALID:	equ  9 -1
	CFG_SOUND_PASSWORD_INVALID:	equ 10 -1

; ayFX REPLAYER v1.31
	include	"libext/ayFX-replayer/ayFX-ROM.tniasm.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VRAM routines (BIOS-based)
; NAMBTL and SPRATR buffer routines (BIOS-based)

; Enable for faster LDIRVM_NAMTBL routine (for NAMTBL-blitting intensive games)
	; CFG_LDIRVM_NAMTBL_FAST:

; Define if the LDIRVM the SPRATR buffer should use flickering
	CFG_SPRITES_FLICKER:

; Number of sprites that won't enter the flickering loop
; (i.e.: number of sprites that will use the most priority planes)
	CFG_SPRITES_NO_FLICKER:	equ CFG_PLAYER_SPRITES_INDEX + 1 ; 7

	include "lib/msx/io/vram.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; NAMTBL buffer text and block routines
	include "lib/msx/io/print.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Logical coordinates sprite routines

; Logical-to-physical sprite coordinates offsets (pixels)
	CFG_SPRITES_X_OFFSET:	equ -8
	CFG_SPRITES_Y_OFFSET:	equ -17

; Number of sprites reserved at the beginning of the SPRATR buffer
; (i.e.: first sprite number for the "volatile" sprites)
	CFG_SPRITES_RESERVED:	equ CFG_PLAYER_SPRITES_INDEX + CFG_PLAYER_SPRITES ; 8

	include "lib/msx/io/sprites.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Additional NAMBTL and SPRATR buffer based routines

; Define to use a double fade in/out effect
	CFG_FADE_TYPE_DOUBLE:

	include "lib/msx/etc/fade.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine (ZX0 v2.0 decoder-based implementation)
	include	"lib/unpack/unpack_zx0.asm"

; Buffer size to check it actually fits before system variables
;	CFG_RAM_RESERVE_BUFFER:	equ 2048 ; (a CXRTBL bank)
	CFG_RAM_RESERVE_BUFFER:	equ 2545 ; (PT3 are larger than a CXRTBL bank)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Attract-mode text-printing routines

; Delay (in frames) for the attract-mode text-printing routine
	CFG_ATTRACT_PRINT_DELAY:	equ 4
; Pause (frames) for the attract-mode text-printing routine
	CFG_ATTRACT_PRINT_PAUSE:	equ 100 ; about two seconds

	include "lib/msx/etc/attract_print.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Palette routines for MSX2 VDP

; Custom initial palette in $0GRB format (with R, G, B in 0..7).
CFG_CUSTOM_PALETTE:
	dw	$0000, $0000, $0522, $0623, $0105, $0347, $0150, $0637
	dw	$0272, $0373, $0561, $0674, $0200, $0222, $0444, $0777

	include "lib/msx/etc/msx2_palette.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Spriteables routines (2x2 chars that eventually become a sprite)

; Maximum number of simultaneous spriteables
	CFG_SPRITEABLES:	equ 8

	include "lib/msx/etc/spriteables.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; "vpoke" routines (deferred WRTVRMs routines)

; Maximum number of "vpokes" per frame
	CFG_VPOKES: 		equ CFG_SPRITEABLES *4

	include "lib/msx/etc/vpokes.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Generic Z80 assembly convenience routines
	include "lib/asm/asm.asm"
; -----------------------------------------------------------------------------


; =============================================================================
;	MSXlib game-related configuration and routines
; =============================================================================

; -----------------------------------------------------------------------------
; Sprite-tile helper routines

; Tile indexes (values) to be returned by GET_TILE_VALUE
; when the coordinates are screen borders, or over and under visible screen
	CFG_TILES_VALUE_BORDER:	equ $30 ; tile with BIT_WORLD_FLOOR | BIT_WORLD_SOLID flags
	CFG_TILES_VALUE_OVER:	equ $00 ; tile with no flags
	CFG_TILES_VALUE_UNDER:	equ $30 ; tile with BIT_WORLD_FLOOR | BIT_WORLD_SOLID flags

; Table of tile flags in pairs (up to index, tile flags)
TILE_FLAGS_TABLE:
	db	$2f, $00 ; [$00..$2f] : 0
	db	$af, $03 ; [$30..$af] : BIT_WORLD_SOLID | BIT_WORLD_FLOOR
	db	$bf, $06 ; [$b0..$bf] : BIT_WORLD_STAIRS | BIT_WORLD_FLOOR
	db	$c7, $04 ; [$c0..$c7] : BIT_WORLD_STAIRS
	db	$cf, $02 ; [$c8..$cf] : BIT_WORLD_FLOOR
	db	$d7, $73 ; [$d0..$d7] : BIT_WORLD_SOLID | BIT_WORLD_FLOOR | BIT_WORLD_WALK_OVER
	db	$df, $83 ; [$d8..$df] : BIT_WORLD_SOLID | BIT_WORLD_FLOOR | BIT_WORLD_PUSH
	db	$e7, $10 ; [$e0..$e7] : BIT_WORLD_WALK_ON (items)
	db	$f7, $08 ; [$e8..$f7] : BIT_WORLD_DEATH
	db	$ff, $20 ; [$f8..$ff] : BIT_WORLD_WIDE_ON (doors)

	include	"lib/game/tiles.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Player related routines (generic)
; Player-tile helper routines

; Logical sprite sizes (bounding box size) (pixels)
	CFG_PLAYER_WIDTH:		equ 8
	CFG_PLAYER_HEIGHT:		equ 16

; Number of sprites reserved before the player sprites
; (i.e.: first sprite number for the player sprites)
	CFG_PLAYER_SPRITES_INDEX:	equ 6

; Number of player sprites (i.e.: number of colors)
	CFG_PLAYER_SPRITES:		equ 2

; Player animation delay (frames)
	CFG_PLAYER_ANIMATION_DELAY:	equ 6

; Custom player states (starting from 4 << 2)
	PLAYER_STATE_PUSH:	equ (4 << 2) ; $10
	;	...

; Maps player states to sprite patterns
PLAYER_SPRATR_TABLE:
	;	0	ANIM	LEFT	LEFT|ANIM
	db	$00,	$08,	$10,	$18	; PLAYER_STATE_FLOOR
	db	$20,	$28,	$20,	$28	; PLAYER_STATE_STAIRS
	db	$08,	$08,	$18,	$18	; PLAYER_STATE_AIR
	db	$30,	$38,	$30,	$38	; PLAYER_STATE_DYING
	db	$40,	$40,	$48,	$48	; PLAYER_STATE_PUSH
	;	...

; Maps player states to assembly routines
PLAYER_UPDATE_TABLE:
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_FLOOR
	dw	UPDATE_PLAYER_STAIRS	; PLAYER_STATE_STAIRS
	dw	UPDATE_PLAYER_AIR	; PLAYER_STATE_AIR
	dw	UPDATE_PLAYER_DYING	; PLAYER_STATE_DYING
	dw	UPDATE_PLAYER_FLOOR	; PLAYER_STATE_PUSH
	;	...

	include	"lib/game/player.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Default player control routines (platformer game)

; Controls if the player jumps with BIT_STICK_UP or with BIT_TRIGGER_A/B
	CFG_PLAYER_JUMP_INPUT:	equ BIT_TRIGGER_A

; Delta-Y (dY) table for jumping and falling
PLAYER_DY_TABLE:
	db	-4, -4			; (2,-8)
	db	-2, -2, -2		; (5,-14)
	db	-1, -1, -1, -1, -1, -1	; (11,-20)
	.TOP_OFFSET:	equ $ - PLAYER_DY_TABLE
	db	 0,  0,  0,  0,  0,  0	; (17,-20)
	.FALL_OFFSET:	equ $ - PLAYER_DY_TABLE
	db	1, 1, 1, 1, 1, 1	; (23,-14) / (6,6)
	db	2, 2, 2			; (26,-8) / (9,12)
	db	4
	.SIZE:		equ $ - PLAYER_DY_TABLE

; Terminal falling speed (pixels/frame)
	CFG_PLAYER_GRAVITY:		equ 4

	include	"lib/game/platformer/platformer_player.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemies related routines (generic)
; Generic enemy state handlers (generic)
; Enemy-tile helper routines

; Maximum simultaneous number of enemies
	CFG_ENEMY_COUNT:		equ 10

; Logical enemy sprite sizes (bounding box size) (pixels)
	CFG_ENEMY_WIDTH:		equ 8
	CFG_ENEMY_HEIGHT:		equ 16

; Enemies animation delay (frames)
	CFG_ENEMY_ANIMATION_DELAY:	equ 10

	include	"lib/game/enemy.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience enemy state handlers (generic)

; Triggers will fire <n> pixels before the actual collision occurs
	CFG_ENEMY_ADVANCE_COLLISION:	equ 3

	include	"lib/game/enemy_default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemy type: killed (generic)

; Killed/respawning patterns
	CFG_ENEMY_DYING_PATTERN:	equ ENEMY_DYING_PATTERN ; $c8
	CFG_ENEMY_RESPAWN_PATTERN:	equ ENEMY_RESPAWN_PATTERN ; $f8

	include	"lib/game/enemy_type_killed.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Convenience enemy helper routines (platform games)

; Enemies delta-Y (dY) table for jumping and falling
ENEMY_DY_TABLE:			equ PLAYER_DY_TABLE
ENEMY_DY_TABLE.TOP_OFFSET:			equ PLAYER_DY_TABLE.TOP_OFFSET
ENEMY_DY_TABLE.FALL_OFFSET:			equ PLAYER_DY_TABLE.FALL_OFFSET
ENEMY_DY_TABLE.SIZE:				equ PLAYER_DY_TABLE.SIZE

; Enemies terminal falling speed (pixels/frame)
	CFG_ENEMY_GRAVITY:		equ CFG_PLAYER_GRAVITY

	include	"lib/game/platformer/platformer_enemy.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Default enemy types (platformer game)
; Convenience enemy state handlers (platformer game)
; Specific enemy helper routines (platform games)

; Pauses (frames) for the default enemy routines
	CFG_ENEMY_PAUSE_S:	equ 24 ; short pause (~16 frames)
	CFG_ENEMY_PAUSE_M:	equ 40 ; medium pause (~32 frames, < 64 frames)
	CFG_ENEMY_PAUSE_L:	equ 96 ; long pause (~64 frames, < 256 frames)

	include	"lib/game/platformer/platformer_enemy_default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Bullet related routines (generic)
; Bullet-tile helper routines

; Maximum simultaneous number of bullets
	CFG_BULLET_COUNT:		equ 10

; Logical bullet sprite sizes (bounding box size) (pixels)
	CFG_BULLET_WIDTH:		equ 4
	CFG_BULLET_HEIGHT:		equ 4

; Additional pattern for the last frame of the bullet
	CFG_BULLET_DYING_PATTERN:	equ ENEMY_DYING_PATTERN
	CFG_BULLET_DYING_PAUSE:		equ 6

	include	"lib/game/bullet.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Player-enemy-bullet helper routines
	include	"lib/game/collision.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Password encoding/decoding routines

; Size (in bytes) of the data to be encoded in the password
	CFG_PASSWORD_DATA_SIZE:		equ 2

	include "lib/game/etc/password.asm"
; -----------------------------------------------------------------------------


; =============================================================================
; 	Game code and data
; =============================================================================

; -----------------------------------------------------------------------------
; Conditional assembly flags
	; DEBUG_NO_INTRO:	equ 1 ; Disables the intro sequence and tutorial
	; DEBUG_TRAINER_LIVES:	equ 1 ; Enables infinite lives
	; DEBUG_TRAINER_SKIP:	equ 1 ; Enables SELECT to skip stage
	; DEBUG_ENDING:		equ 3 ; 1 = Tutorial over, 2 = Bad ending, 3 = Secret stage, 4 = Good Ending
	; DEBUG_JUKEBOX:	equ 1 ; Forces the jukebox

	; DEBUG_CHAPTER:	equ 2 ; Tests stage DEBUG_CHAPTER-DEBUG_STAGE
	; DEBUG_STAGE:		equ 1 ; Tests stage DEBUG_CHAPTER-DEBUG_STAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game code and data
	include "games/stevedore/stevedore.code.asm"

	include "lib/rom_end.asm"
; -----------------------------------------------------------------------------


;
; =============================================================================
;	RAM
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; Game vars
	include "games/stevedore/stevedore.ram.asm"

	include "lib/ram_end.asm"
; -----------------------------------------------------------------------------

; EOF

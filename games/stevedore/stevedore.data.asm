
;
; =============================================================================
;	Game data in page 0
; =============================================================================
;

; -----------------------------------------------------------------------------
; Charset binary data (CHRTBL and CLRTBL)
DEFAULT_CHRTBL_PACKED:
	incbin	"games/stevedore/gfx/charset.png.chr.zx0"
DEFAULT_CLRTBL_PACKED:
	incbin	"games/stevedore/gfx/charset.png.clr.zx0"

; Charset-related symbolic constants
	CHAR_EMPTY:		equ $20
	SKELETON_FIRST_CHAR:	equ $28
	CHAR_EXCLAMATION:	equ $3b
	CHAR_AMPERSAND:		equ $3c
	CHAR_APOSTROPHE:	equ $3d
	CHAR_COMMA:		equ $3e
	CHAR_DOT:		equ $3f
	CHAR_N_TILDE:		equ $5b
	TRAP_UPPER_RIGHT_CHAR:	equ $6e
	TRAP_UPPER_LEFT_CHAR:	equ $6f
	TRAP_LOWER_RIGHT_CHAR:	equ $7e
	TRAP_LOWER_LEFT_CHAR:	equ $7f
	CHAR_FIRST_FRAGILE:	equ $d0
	CHAR_FIRST_BOX:		equ $d8
	CHAR_FIRST_BULDER:	equ $dc
	CHAR_FIRST_ITEM:	equ $e0
	CHAR_STAR:		equ $e1
	CHAR_WATER_SURFACE:	equ $f0
	CHAR_WATER:		equ $f3
	CHAR_LAVA_SURFACE:	equ $f4
	CHAR_FIRST_DOOR:	equ $f8
	CHAR_SECOND_DOOR:	equ $fc
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Title charset binary data (CHRTBL and CLRTBL)
TITLE_CHRTBL_PACKED:
	incbin	"games/stevedore/gfx/title.png.chr.zx0"
TITLE_CLRTBL_PACKED:
	incbin	"games/stevedore/gfx/title.png.clr.zx0"

; Title charset-related symbolic constants
	TITLE_CHAR_FIRST:	equ 96
	TITLE_CXRTBL_SIZE:	equ 808 ; Adjust to actual value!
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Ending charset binary data (CHRTBL and CLRTBL)
ENDING_CHRTBL_PACKED:
	incbin	"games/stevedore/gfx/ending.png.chr.zx0"
ENDING_CLRTBL_PACKED:
	incbin	"games/stevedore/gfx/ending.png.clr.zx0"

	ENDING_CXRTBL_SIZE:	equ CHRTBL_SIZE ; TODO: Adjust to actual value! 1216? 1224?
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Sprites binary data (SPRTBL)
SPRTBL_PACKED:
	incbin	"games/stevedore/gfx/sprites.png.spr.zx0"

; Sprite-related symbolic constants (SPRATR)
	PLAYER_SPRITE_COLOR_1:		equ 15
	PLAYER_SPRITE_COLOR_2:		equ 9

	PLAYER_SPRITE_KO_PATTERN:	equ $50
	PLAYER_SPRITE_HAPPY_PATTERN:	equ $58

	ENEMY_DYING_PATTERN:		equ $f8
	ENEMY_RESPAWN_PATTERN:		equ $c8

	BAT_SPRITE_PATTERN:		equ $60
	BAT_SPRITE_COLOR_1:		equ 4
	BAT_SPRITE_COLOR_2:		equ 6

	SNAKE_SPRITE_PATTERN:		equ $70
	SNAKE_SPRITE_COLOR_1:		equ 2
	SNAKE_SPRITE_COLOR_2:		equ 11

	MONKEY_SPRITE_PATTERN:		equ $80
	MONKEY_SPRITE_COLOR:		equ 9

	PANTOJO_SPRITE_PATTERN:		equ $90
	PANTOJO_SPRITE_COLOR:		equ 8

	SKELETON_SPRITE_PATTERN:	equ $a0
	SKELETON_SPRITE_COLOR:		equ 15

	SPIDER_SPRITE_PATTERN:		equ $b0
	SPIDER_SPRITE_COLOR:		equ 13

	JELLYFISH_SPRITE_PATTERN:	equ $b8
	JELLYFISH_SPRITE_COLOR:		equ 15

	URCHIN_SPRITE_PATTERN:		equ $c0
	URCHIN_SPRITE_COLOR_1:		equ 14
	URCHIN_SPRITE_COLOR_2:		equ 15

	ARROW_RIGHT_SPRITE_PATTERN:	equ $d0
	ARROW_LEFT_SPRITE_PATTERN:	equ $d4
	ARROW_SPRITE_COLOR:		equ 14

	COCONUT_SPRITE_PATTERN:		equ $d8
	COCONUT_SPRITE_COLOR:		equ 8

	SPARK_SPRITE_PATTERN:		equ $dc
	SPARK_SPRITE_COLOR:		equ 10

	SPLASH_SPRITE_PATTERN_FIRST:	equ $e0
	SPLASH_SPRITE_PATTERN_LAST:	equ $ec
	SPLASH_SPRITE_COLOR_WATER:	equ 7
	SPLASH_SPRITE_COLOR_LAVA:	equ 10

	BOX_SPRITE_PATTERN:		equ $f0
	BOX_SPRITE_COLOR:		equ 9

	BOULDER_SPRITE_PATTERN:		equ $f4
	BOULDER_SPRITE_COLOR:		equ 14
	BOULDER_SPRITE_COLOR_WATER:	equ 5
	BOULDER_SPRITE_COLOR_LAVA:	equ 9

	CURSOR_SPRITE_PATTERN:		equ $fc
	CURSOR_SPRITE_COLOR:		equ 4
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Intro sequence data
INTRO_NAMTBL_PACKED:
	incbin	"games/stevedore/maps/intro_screen.tmx.bin.zx0"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Packed PT3 songs
SONG_PACKED:								; packd	unpacked (bytes)

.WAREHOUSE:
	incbin	"games/stevedore/sfx/00-chapter-warehouse.pt3.hl.zx0"	; 565	1833
.LIGHTHOUSE:
	incbin	"games/stevedore/sfx/01-chapter-lighthouse.pt3.hl.zx0"	; 569	1877
.SHIP:
	incbin	"games/stevedore/sfx/02-chapter-ship.pt3.hl.zx0"	; 653	1350
.JUNGLE:
	incbin	"games/stevedore/sfx/03-chapter-jungle.pt3.hl.zx0"	; 485	1443
.VOLCANO:
	incbin	"games/stevedore/sfx/04-chapter-volcano.pt3.hl.zx0"	; 800	2545 !
.TEMPLE:
	incbin	"games/stevedore/sfx/05-chapter-temple.pt3.hl.zx0"	; 1039	3947 !!
.SECRET:
	incbin	"games/stevedore/sfx/06-chapter-secret.pt3.hl.zx0"	; 699	2150

.MAIN_THEME:
	incbin	"games/stevedore/sfx/07-main-theme.pt3.hl.zx0"		; 281	885

.CHAPTER_OVER:
	incbin	"games/stevedore/sfx/08-chapter-over-jingle.pt3.hl.zx0"	; 159	354
.GAME_OVER:
	incbin	"games/stevedore/sfx/09-game-over-jingle.pt3.hl.zx0"	; 184	393

.BAD_ENDING:
	incbin	"games/stevedore/sfx/10-bad-ending.pt3.hl.zx0"		; 230	656
.GOOD_ENDING:
	incbin	"games/stevedore/sfx/11-good-ending.pt3.hl.zx0"		; 252	669
; -----------------------------------------------------------------------------

; EOF

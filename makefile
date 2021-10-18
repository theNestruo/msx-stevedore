
#
# current game name, paths, sources and assets
#

GAME=stevedore

GAME_PATH=\
	games\$(GAME)

SRCS=\
	$(GAME_PATH)\$(GAME).asm \
	$(GAME_PATH)\$(GAME).code.asm \
	$(GAME_PATH)\$(GAME).data.asm \
	$(GAME_PATH)\$(GAME).ram.asm \
	$(GAME_PATH)\sfx\sound_bank.afb \
	splash\msxlib.bin.$(PACK_EXTENSION)

DATAS=\
	$(GAME_PATH)\gfx\charset.png.chr.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\charset.png.clr.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\charset_dynamic.png.chr \
	$(GAME_PATH)\gfx\charset_dynamic.png.clr \
	$(GAME_PATH)\gfx\ending.png.chr.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\ending.png.clr.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\ending.png.nam.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\title.png.chr.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\title.png.clr.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\title.png.nam.$(PACK_EXTENSION) \
	$(GAME_PATH)\gfx\sprites.png.spr.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\stage_select.tmx.bin \
	$(GAME_PATH)\maps\intro_screen.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\intro_stage.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\0-1-warehouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\0-2-warehouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\0-3-warehouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\0-4-warehouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\0-5-warehouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\1-1-lighthouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\1-2-lighthouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\1-3-lighthouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\1-4-lighthouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\1-5-lighthouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\1-6-lighthouse.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\2-1-ship.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\2-2-ship.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\2-3-ship.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\2-4-ship.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\2-5-ship.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\2-6-ship.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\3-1-jungle.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\3-2-jungle.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\3-3-jungle.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\3-4-jungle.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\3-5-jungle.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\3-6-jungle.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\4-1-volcano.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\4-2-volcano.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\4-3-volcano.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\4-4-volcano.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\4-5-volcano.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\4-6-volcano.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\5-1-temple.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\5-2-temple.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\5-3-temple.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\5-4-temple.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\5-5-temple.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\5-6-temple.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\6-1-secret.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\6-2-secret.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\6-3-secret.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\6-4-secret.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\6-5-secret.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\maps\6-6-secret.tmx.bin.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\00-chapter-warehouse.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\01-chapter-lighthouse.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\02-chapter-ship.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\03-chapter-jungle.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\04-chapter-volcano.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\05-chapter-temple.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\06-chapter-secret.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\07-main-theme.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\08-chapter-over-jingle.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\09-game-over-jingle.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\10-bad-ending.pt3.hl.$(PACK_EXTENSION) \
	$(GAME_PATH)\sfx\11-good-ending.pt3.hl.$(PACK_EXTENSION)


DATAS_INTERMEDIATE=\
	$(GAME_PATH)\gfx\charset.png.chr \
	$(GAME_PATH)\gfx\charset.png.clr \
	$(GAME_PATH)\gfx\ending.png.chr \
	$(GAME_PATH)\gfx\ending.png.clr \
	$(GAME_PATH)\gfx\ending.png.nam \
	$(GAME_PATH)\gfx\title.png.chr \
	$(GAME_PATH)\gfx\title.png.clr \
	$(GAME_PATH)\gfx\title.png.nam \
	$(GAME_PATH)\gfx\sprites.png.spr \
	$(GAME_PATH)\maps\intro_screen.tmx.bin \
	$(GAME_PATH)\maps\intro_stage.tmx.bin \
	$(GAME_PATH)\maps\0-1-warehouse.tmx.bin \
	$(GAME_PATH)\maps\0-2-warehouse.tmx.bin \
	$(GAME_PATH)\maps\0-3-warehouse.tmx.bin \
	$(GAME_PATH)\maps\0-4-warehouse.tmx.bin \
	$(GAME_PATH)\maps\0-5-warehouse.tmx.bin \
	$(GAME_PATH)\maps\1-1-lighthouse.tmx.bin \
	$(GAME_PATH)\maps\1-2-lighthouse.tmx.bin \
	$(GAME_PATH)\maps\1-3-lighthouse.tmx.bin \
	$(GAME_PATH)\maps\1-4-lighthouse.tmx.bin \
	$(GAME_PATH)\maps\1-5-lighthouse.tmx.bin \
	$(GAME_PATH)\maps\1-6-lighthouse.tmx.bin \
	$(GAME_PATH)\maps\2-1-ship.tmx.bin \
	$(GAME_PATH)\maps\2-2-ship.tmx.bin \
	$(GAME_PATH)\maps\2-3-ship.tmx.bin \
	$(GAME_PATH)\maps\2-4-ship.tmx.bin \
	$(GAME_PATH)\maps\2-5-ship.tmx.bin \
	$(GAME_PATH)\maps\2-6-ship.tmx.bin \
	$(GAME_PATH)\maps\3-1-jungle.tmx.bin \
	$(GAME_PATH)\maps\3-2-jungle.tmx.bin \
	$(GAME_PATH)\maps\3-3-jungle.tmx.bin \
	$(GAME_PATH)\maps\3-4-jungle.tmx.bin \
	$(GAME_PATH)\maps\3-5-jungle.tmx.bin \
	$(GAME_PATH)\maps\3-6-jungle.tmx.bin \
	$(GAME_PATH)\maps\4-1-volcano.tmx.bin \
	$(GAME_PATH)\maps\4-2-volcano.tmx.bin \
	$(GAME_PATH)\maps\4-3-volcano.tmx.bin \
	$(GAME_PATH)\maps\4-4-volcano.tmx.bin \
	$(GAME_PATH)\maps\4-5-volcano.tmx.bin \
	$(GAME_PATH)\maps\4-6-volcano.tmx.bin \
	$(GAME_PATH)\maps\5-1-temple.tmx.bin \
	$(GAME_PATH)\maps\5-2-temple.tmx.bin \
	$(GAME_PATH)\maps\5-3-temple.tmx.bin \
	$(GAME_PATH)\maps\5-4-temple.tmx.bin \
	$(GAME_PATH)\maps\5-5-temple.tmx.bin \
	$(GAME_PATH)\maps\5-6-temple.tmx.bin \
	$(GAME_PATH)\maps\6-1-secret.tmx.bin \
	$(GAME_PATH)\maps\6-2-secret.tmx.bin \
	$(GAME_PATH)\maps\6-3-secret.tmx.bin \
	$(GAME_PATH)\maps\6-4-secret.tmx.bin \
	$(GAME_PATH)\maps\6-5-secret.tmx.bin \
	$(GAME_PATH)\maps\6-6-secret.tmx.bin \
	$(GAME_PATH)\sfx\00-chapter-warehouse.pt3.hl \
	$(GAME_PATH)\sfx\01-chapter-lighthouse.pt3.hl \
	$(GAME_PATH)\sfx\02-chapter-ship.pt3.hl \
	$(GAME_PATH)\sfx\03-chapter-jungle.pt3.hl \
	$(GAME_PATH)\sfx\04-chapter-volcano.pt3.hl \
	$(GAME_PATH)\sfx\05-chapter-temple.pt3.hl \
	$(GAME_PATH)\sfx\06-chapter-secret.pt3.hl \
	$(GAME_PATH)\sfx\07-main-theme.pt3.hl \
	$(GAME_PATH)\sfx\08-chapter-over-jingle.pt3.hl \
	$(GAME_PATH)\sfx\09-game-over-jingle.pt3.hl \
	$(GAME_PATH)\sfx\10-bad-ending.pt3.hl \
	$(GAME_PATH)\sfx\11-good-ending.pt3.hl


#
# tools
#

ASM=tniasm
EMULATOR=cmd /c start
PCX2MSX=pcx2msx+
PCX2SPR=pcx2spr
PNG2MSX=png2msx
PNG2SPR=png2spr
TMX2BIN=tmx2bin

# ZX0 v2.0
# (please note that ZX0 does not overwrite output)
PACK=zx0.exe
PACK_EXTENSION=zx0

#
# commands
#

COPY=cmd /c copy
MKDIR=cmd /c mkdir
MOVE=cmd /c move
REMOVE=cmd /c del
RENAME=cmd /c ren

#
# paths and file lists
#

ROM=\
	$(GAME_PATH)\$(GAME).rom

SRCS_MSXLIB=\
	lib\page0.asm \
	lib\page0_end.asm \
	lib\rom-default.asm \
	lib\rom_end.asm \
	lib\ram.asm \
	lib\ram_end.asm \
	lib\msx\symbols.asm \
	lib\msx\cartridge.asm \
	lib\msx\hook.asm \
	lib\msx\ram.asm \
	lib\msx\io\input.asm \
	lib\msx\io\keyboard.asm \
	lib\msx\io\print.asm \
	lib\msx\io\sprites.asm \
	lib\msx\io\timing.asm \
	lib\msx\io\vram.asm \
	lib\msx\io\replayer_pt3.asm \
	lib\msx\etc\fade.asm \
	lib\msx\etc\msx2_palette.asm \
	lib\msx\etc\vpokes.asm \
	lib\msx\etc\spriteables.asm \
	lib\msx\etc\attract_print.asm \
	lib\msx\etc\ram.asm \
	lib\asm\asm.asm \
	lib\game\tiles.asm \
	lib\game\player.asm \
	lib\game\enemy.asm \
	lib\game\enemy_default.asm \
	lib\game\bullet.asm \
	lib\game\collision.asm \
	lib\game\ram.asm \
	lib\game\platformer\platformer_player.asm \
	lib\game\platformer\platformer_enemy.asm \
	lib\game\platformer\platformer_enemy_default.asm \
	lib\game\etc\password.asm \
	lib\game\etc\ram.asm \
	lib\unpack\unpack_zx0.asm \
	lib\unpack\unpack_zx7.asm \
	lib\unpack\ram.asm

SRCS_LIBEXT=\
	libext\ayFX-replayer\ayFX-ROM.tniasm.ASM \
	libext\ayFX-replayer\ayFX-RAM.tniasm.ASM \
	libext\pt3\PT3-ROM.tniasm.ASM \
	libext\pt3\PT3-RAM.tniasm.ASM \
	libext\zx0\dzx0_standard.asm \
	libext\zx7\dzx7_standard.tniasm.asm

#
# phony targets
#

# default target
default: compile

clean:
	$(REMOVE) $(ROM) tniasm.sym tniasm.tmp

cleandata:
	$(REMOVE) $(DATAS) $(DATAS_INTERMEDIATE)

cleanall: clean cleandata

compile: $(ROM)

run: $(ROM)
	$(EMULATOR) $<

# secondary targets
.secondary: $(DATAS_INTERMEDIATE)

#
# main targets
#

$(ROM): $(SRCS) $(SRCS_MSXLIB) $(SRCS_LIBEXT) $(GFXS) $(SPRS) $(DATAS)
	$(ASM) $< $@

#
# GFXs targets
#

%.png.chr.$(PACK_EXTENSION): %.png.chr
	$(REMOVE) $@
	$(PACK) $< $@

%.png.clr.$(PACK_EXTENSION): %.png.clr
	$(REMOVE) $@
	$(PACK) $< $@

%.png.nam.$(PACK_EXTENSION): %.png.nam
	$(REMOVE) $@
	$(PACK) $< $@

$(GAME_PATH)\gfx\charset_dynamic.png.chr $(GAME_PATH)\gfx\charset_dynamic.png.clr: $(GAME_PATH)\gfx\charset_dynamic.png
	$(PNG2MSX) -rm0 $<

$(GAME_PATH)\gfx\ending.png.chr \
$(GAME_PATH)\gfx\ending.png.clr \
$(GAME_PATH)\gfx\ending.png.nam: $(GAME_PATH)\gfx\ending.png
	$(PNG2MSX) -lh -bb20 -rr -rm1 $< -n

$(GAME_PATH)\gfx\title.png.chr \
$(GAME_PATH)\gfx\title.png.clr \
$(GAME_PATH)\gfx\title.png.nam: $(GAME_PATH)\gfx\title.png
	$(PNG2MSX) -lh -bb20 -rr -rm1 $< -n60

# -lh by default because packing usally produces smaller binaries
%.png.chr %.png.clr: %.png
	$(PNG2MSX) -lh $<

#
# SPRs targets
#

%.png.spr.$(PACK_EXTENSION): %.png.spr
	$(REMOVE) $@
	$(PACK) $< $@

%.png.spr: %.png
	$(PNG2SPR) -hl $<

#
# BINs targets
#

%.bin.$(PACK_EXTENSION): %.bin
	$(REMOVE) $@
	$(PACK) $< $@

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@

#
# SFXs targets
#

%.pt3.hl.$(PACK_EXTENSION): %.pt3.hl
	$(REMOVE) $@
	$(PACK) $< $@

$(GAME_PATH)\sfx\00-chapter-warehouse.pt3.hl \
$(GAME_PATH)\sfx\01-chapter-lighthouse.pt3.hl \
$(GAME_PATH)\sfx\02-chapter-ship.pt3.hl \
$(GAME_PATH)\sfx\03-chapter-jungle.pt3.hl \
$(GAME_PATH)\sfx\04-chapter-volcano.pt3.hl \
$(GAME_PATH)\sfx\05-chapter-temple.pt3.hl \
$(GAME_PATH)\sfx\06-chapter-secret.pt3.hl \
$(GAME_PATH)\sfx\07-main-theme.pt3.hl \
$(GAME_PATH)\sfx\08-chapter-over-jingle.pt3.hl \
$(GAME_PATH)\sfx\09-game-over-jingle.pt3.hl \
$(GAME_PATH)\sfx\10-bad-ending.pt3.hl \
$(GAME_PATH)\sfx\11-good-ending.pt3.hl: \
$(GAME_PATH)\sfx\headerless.asm \
$(GAME_PATH)\sfx\00-chapter-warehouse.pt3 \
$(GAME_PATH)\sfx\01-chapter-lighthouse.pt3 \
$(GAME_PATH)\sfx\02-chapter-ship.pt3 \
$(GAME_PATH)\sfx\03-chapter-jungle.pt3 \
$(GAME_PATH)\sfx\04-chapter-volcano.pt3 \
$(GAME_PATH)\sfx\06-chapter-secret.pt3 \
$(GAME_PATH)\sfx\07-main-theme.pt3 \
$(GAME_PATH)\sfx\08-chapter-over-jingle.pt3 \
$(GAME_PATH)\sfx\09-game-over-jingle.pt3 \
$(GAME_PATH)\sfx\10-bad-ending.pt3 \
$(GAME_PATH)\sfx\11-good-ending.pt3
	$(ASM) $<

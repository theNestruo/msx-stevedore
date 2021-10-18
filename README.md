# Stevedore (MSX, 2020)

Stevedore is an MSX videogame.

This game is to be played on an MSX computer. If you want to play it elsewhere you'll need to use an MSX emulator.

Physical cartridges are available at <a href="https://msxcartridgeshop.com/"><b>MSX Cartridge Shop</b></a>.

The digital edition can be played online (and downloaded) for free at <a href="https://thenestruo.itch.io/stevedore"><b>thenestruo.itch.io/stevedore</b></a>.

---

## Source code

Stevedore is written in Z80 assembly, and assembles to a 48KB ROM MSX videogame cartridge.

The full source code is available at <a href="https://github.com/thenestruo/msx-stevedore">github.com/thenestruo/msx-stevedore</a>.

This source code is provided for reference, archiving purposes, and educational uses.


### Stevedore and <a href="https://github.com/thenestruo/msx-msxlib">MSXlib</a>

The game is <em>powered by MSXlib</em> and, therefore, contains a snapshot of MSXlib.

Stevedore can be seen as the first full example of using (and extending) MSXlib.

But, if you want to use MSXlib yourself, please <strong>do not use the version in this repository</strong>. Instead, go to the <a href="https://github.com/thenestruo/msx-msxlib">MSXlib repository</a> to get a more complete, up-to-date, and better documented version.


### Toolchain

To assemble Stevedore, you will need:

* GNU make, as the build is `makefile`-based. You can bypass this requirement by manually translating the contents of the makefile into a `.bat` or `.sh` script.
* [tniASM v0.45](http://tniasm.tni.nl/) as Z80 assembler. Using a different assembler may require adjustments in paths and syntax of the source code.
* [PCXTOOLS v3.0](https://github.com/theNestruo/pcxtools) to convert the PNG images to TMS9918-ready binaries, and Tiled maps to binary files.
* [ZX0](https://github.com/einar-saukas/ZX0) v2.1 to compress the binaries.

Additionally, you can also use:

* [Tiled](http://www.mapeditor.org/) to inspect and edit stage files.
* [Vortex Tracker II](http://bulba.untergrund.net/vortex_e.htm) to inspect and edit music assets. You can use an alternative version such as [Vortex Tracker Improved](https://github.com/oisee/vti).
* [AYFX Editor](https://shiru.untergrund.net/software.shtml) to inspect and edit sound effects. You can use an alternative version such as [AY Sound FX Editor (Improved)](https://github.com/Threetwosevensixseven/ayfxedit-improved).


### How to assemble

Run `make`, as the build is `makefile`-based.


### Files and folder structure

The source code is comprised of:

* `makefile`: the build script.

* `games/stevedore/`: contains the main Stevedore source code, as well as the graphic assets, maps, musics and sound effects.

	Note: intermediate resources (such as already-converted graphic assets, and already-compressed binary files) are provided for convenience.

* `lib/`, `libext/`, and `splash/`: contain a snapshot of MSXlib, the external libraries of MSXlib, and the main MSXlib splashscreen. Please <strong>do not use these version</strong> and go instead to the main <a href="https://github.com/thenestruo/msx-msxlib">MSXlib repository</a>.

	The external libraries used in Stevedore are:
	* [ayFX Replayer v1.31](http://www.z80st.es/downloads/code/) by SapphiRe
	* [PT3 Replayer](http://www.z80st.es/downloads/code/) by Dioniso, MSX-KUN (ROM version), SapphiRe (asMSX version)
	* [ZX0](https://github.com/einar-saukas/ZX0) v2.1 by Einar Saukas

Additionally:

* `dist/`: contains the distributable package published at <a href="https://thenestruo.itch.io/stevedore"><b>thenestruo.itch.io/stevedore</b></a>.


### Changelog

#### v1.2 (2021-10-18)

* Digital edition release.
* Improved experience on emulators (alternative keys to `SELECT` and `STOP`).
* Toolchain updated (PCX files replaced by PNG, and ZX7 compressor replaced by ZX0) to make source code easier to use.
* CRC32: `859C04AD`
* CRC64: `B3F3591B9D61C70F`

#### v1.1 (2020-11-06)

* Improved cartridge initialization code for compatibility reasons.
* CRC32: `D73F2A46`
* CRC64: `BF38D6A8DED456FA`

#### v1.0 (2020-10-18)

* Initial physical edition release.
* CRC32: `AC18BC5E`
* CRC64: `799D7134D16875F2`


## Licenses

### Stevedore

> This game is free to download but it is NOT FREELY DISTRIBUTABLE, neither digitally or on any physical format, without the explicit consent from theNestruo & Wonder.
You can find the official download link only at github.com/theNestruo and thenestruo.itch.io, and you can buy a physical copy of the game only at www.msxcartridgeshop.com.
>
> No derivatives or adaptations of the work are permitted.
>
> Stevedore © theNestruo & Wonder 2020

Please note that hacks and/or ports to run the patched game on different platforms than MSX (such as ColecoVision, Sega SG-1000 or Sega Master System) are considered derivative and/or adaptations of the work, and therefore are not permitted by this license.

### Stevedore source code

> Stevedore source code (including graphic assets, maps, musics and sound effects) is licensed under CC BY-NC-ND 4.0 (Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License).
> To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
>
> Stevedore © theNestruo & Wonder 2020

### MSXlib

Please check the main <a href="https://github.com/thenestruo/msx-msxlib">MSXlib repository</a> for licensing information.

### External libraries

The external libraries used by MSXlib and, therefore, by Stevedore, have their own individual licenses. Please check their individual folders for LICENSE or README files, and/or check their web pages:

* [ayFX Replayer v1.31](http://www.z80st.es/downloads/code/) by SapphiRe
* [PT3 Replayer](http://www.z80st.es/downloads/code/) by Dioniso, MSX-KUN (ROM version), SapphiRe (asMSX version)
* [ZX0](https://github.com/einar-saukas/ZX0) by Einar Saukas

---

<p align="center"><strong>
	Stevedore<br>
	&copy; theNestruo & Wonder 2020</strong></p>

<p align="center">
	Concept, code & GFX: theNestruo<br>
	Music & SFX: Wonder<br>
	Cover art: Sirelion</p>

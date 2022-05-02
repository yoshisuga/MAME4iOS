# Version 2022.2
* Updated to [MAME 243](https://www.mamedev.org/releases/whatsnew_0243.txt).
* hi-res font for `MAME` Config Menu.
* use the entire screen (ignore safe area) if `Keep Aspect Ratio` is `OFF`
* better touch mouse support, tap is LEFT button, two finger tap is RIGHT button.
    - touch mouse can be enabled or disabled in `Settings` > `Input Options` > `Touch Analog`

# Version 2022.1
* Updated to [MAME 241](https://www.mamedev.org/releases/whatsnew_0241.txt).
* Minimum version is now iOS 13.4, tvOS 13.4, and macOS 10.15.5 (Catalina)
* Removed MAME4mac build Target, build MAME4iOS for Catalyst instead 
* Support for Software keyboard for machines that need keyboard input.
* Non git-tracked `Developer.xcconfig`
* Minimal Benchmark support, results stored in `benchmark.csv`
    - Benchmark button at bottom of `Settings`
* fix for `MAME` Artwork
    - `Game & Watch` artwork issues
* Ignore software-lists on 139
    - dont filter `Consoles` when `Hide BIOS` option selected.
* game controller can now be used to drive choose game UX
    - `MENU` => `ContextMenu`
    - `OPTION` => `Settings`
* new `Alert` and `Action Sheet` UX
* added `AddROMS` button to toolbar
* create `software` and `shaders` directories at startup, if they dont exist
    - `software` contains non-software-list files (cart, flop, roms, etc...)
    - `shaders` is for a future release
* show romless Arcade games, like breakout and pong
    - see list below
* support romless Console Machines
    - any file in the `software` folder can be play'd via a supported Machine.
    - see list below
* support running non-software-list ROMs
    - Any files in the `software` directory will be shown, and user can choose machine to run.
    - Import most known file types automaticly
* get info on any game, not just ones with info in `HISTORY.DAT`
* added a `Play With...` context menu item to games that can be played on multiple machines.
* collapse sections for clone machines and Consoles by default.
* remember and try to restore the selected item in Choose Game UX
* added a "Group by Software" option, this will create sections by Software List name not Machine/System name
* HUD on tvOS works with any game controller, when HUD is enabled in-game menu is the HUD.
* Filter NTSC and PAL Software Lists.
    - uses adhoc method based on Machine description.
* Added "Paste Image" to set the title image used in Choose Game UX.
* Support adding additional command line arguments for a game/software title. Long tapping a game/title will now show a "Add Arguments..." in the context menu that will let you add command line arguments. Use with caution and only if you know what you are doing :)

## ROMless Arcade Machines

Name        |Description
------------|-----------------------
pongf       |Pong (Rev E) [TTL]        
pongd       |Pong Doubles [TTL]        
rebound     |Rebound (Rev B) [TTL]   
breakout    |Breakout [TTL]     

## ROMless Console Machines

The following is a list of *some* of the Consoles and file types supported by MAME4iOS "out of the box"

Name    |Description                                                |Media File Types
--------|-----------------------------------------------------------|----------------
a2600   |Atari 2600 (NTSC)                                          |a26, bin
a2600p  |Atari 2600 (PAL)                                           |a26, bin
gen_nomd|Genesis Nomad (USA Genesis handheld)                       |md, smd, bin, gen
genesis |Genesis (USA, NTSC)                                        |cmd, smd, bin, gen
megadrij|Mega Drive (Japan, NTSC)                                   |md, smd, bin, gen
megadriv|Mega Drive (Europe, PAL)                                   |md, smd, bin, gen
megajet |Mega Jet (Japan Mega Drive handheld)                       |md, smd, bin, gen
nes     |Nintendo Entertainment System / Famicom (NTSC)             |unif, nes, unf
nespal  |Nintendo Entertainment System (PAL)                        |unif, nes, unf
1292apvs|1292 Advanced Programmable Video System                    |rom, tvc, bin, pgm
1392apvs|1392 Advanced Programmable Video System                    |rom, tvc, bin, pgm
pico    |Pico (Europe, PAL)                                         |md, bin
picoj   |Pico (Japan, NTSC)                                         |md, bin
picou   |Pico (USA, NTSC)                                           |md, bin
vboy    |Virtual Boy                                                |vb, bin
sgx     |SuperGrafx                                                 |cue, gdi, toc, chd, bin, cdr, nrg, pce, iso
pce     |PC Engine                                                  |cue, gdi, toc, chd, bin, cdr, nrg, pce, iso
tg16    |TurboGrafx 16                                              |cue, gdi, toc, chd, bin, cdr, nrg, pce, iso

## Console Machines and Computers (that require BIOS)

The following is a list of *some* of the Consoles, Computers, and file types supported by MAME4iOS, but BIOS files must be installed first.

Name    |Description                                                |Media File Types
--------|-----------------------------------------------------------|----------------
a5200   |Atari 5200                                                 |rom, a52, bin, car
a800    |Atari 800 (NTSC)                                           |rom, xfd, atr, dsk, bin, car
a7800   |Atari 7800 (NTSC)                                          |a78
famicom |Famicom                                                    |unif, nes, unf
fds     |Famicom (w/ Disk System add-on)                            |fds
snes    |Super Nintendo Entertainment System / Super Famicom (NTSC) |sfc
snespal |Super Nintendo Entertainment System (PAL)                  |sfc
32x     |Genesis with 32X (USA, NTSC)                               |32x, bin
32xe    |Mega Drive with 32X (Europe, PAL)                          |32x, bin
32xj    |Mega Drive with 32X (Japan, NTSC)                          |32x, bin
neogeo  |Neo-Geo MV-6F                                              |neo, bin
ngp     |NeoGeo Pocket                                              |npc, ngp, ngc, bin
ngpc    |NeoGeo Pocket Color                                        |npc, ngp, ngc, bin
n64     |Nintendo 64                                                |rom, v64, n64, z64, bin
n64dd   |Nintendo 64DD                                              |bin, 2mg, rom, n64, z64, hdv, hd, v64, chd, hdi
c64gs   |Commodore 64 Games System (PAL)                            |a0, 80, prg, t64, e0, p00, crt
c64     |Commodore 64 (NTSC)                                        |d64, tap, prg, a0, g64, 80, g41, g71, wav, p00, mfi, dfi, t64, e0, crt
gameboy |Game Boy                                                   |gb, gbc, bin 
gba     |Game Boy Advance                                           |gba, bin 
gbcolor |Game Boy Color                                             |gb, gbc, bin
apple1  |Apple I                                                    |wav, snp
apple2  |Apple ][                                                   |do, mfi, dsk, rti, edd, wav, woz, nib, dfi, po
apple2gs|Apple IIgs (ROM03)                                         |mfi, edd, mfm, td0, 360, img, do, nib, imd, dc42, hfe, rti, ima, po, d77, ufi, woz, dsk, 2mg, cqi, dfi, cqm, d88, 1dd
mac128k |Macintosh 128k                                             |d88, dsk, cqm, d77, img, dc42, mfm, 2mg, 1dd, cqi, imd, dfi, mfi, woz, td0, ufi, 360, ima, hfe
ibm5150 |IBM PC 5150                                                |mfi, td0, mfm, wav, hdv, 360, img, hd, xdf, imd, hfe, 2mg, ima, hdi, d77, ufi, dsk, chd, cqi, dfi, cqm, d88, 1dd
bbca    |BBC Micro Model A                                          |wav, uef, rom, bin, csw
bbcb    |BBC Micro Model B                                          |adf, mfi, fsd, td0, mfm, wav, 360, ads, csw, img, rom, prn, adl, imd, bin, bbc, hfe, adm, ima, d77, dsk, ufi, uef, ssd, cqi, dfi, dsd, cqm, d88, 1dd

# Version 2022.0
* Updated to [MAME 239](https://www.mamedev.org/releases/whatsnew_0239.txt).
* Support CHEATs and HISCOREs for latest MAME, and stay compatible with 139.
* On-screen MENU selection will wrap top to bottom, and bottom to top.

# Version 2021.8
* Updated to [MAME 238](https://www.mamedev.org/releases/whatsnew_0238.txt).
* Build in all `MAME` software list `XML` files, no need to import XML files anymore.
* Added Menu (and button in Settings) to open `Document` directory in `Files.app` (or `Finder.app`)
* Handle romsets names that end with `dash` number. (like `packman - 3.zip`)
* Dont conflict with system keyboard shortcut for Prefrences `CMD+,`
* Handle system keyboard shortcut for Escape `CMD+.`
* Build `LIBMAME` via Xcode, no more need to run scripts from `Terminal.app`
* fix `MOUSE` and `LIGHTGUN` input in `MAME` 2xx build.
* Import `CHD` files.  if the `CHD` file is named `<romname>.chd` it will be copied into `roms/<romname>`
* added `Use DRC` Option. disable the use of `DRC` on `MAME 2xx`, for some games.

# Version 2021.7
**NOTE** `MAME4iOS` 2021.7 comes in two versions, one that uses `MAME 139u1`, and one that uses the latest `MAME` (currently 234).  Make sure you download the version that is compatible with your ROMs, You can get the current version from the `Settings` page. If you want to use software based (ie cartridge, etc) romsets, please read the **Software Lists** section in the HELP or README.

* `OSD` changes.
* Ability to build with latest `MAME` version
* New `Category.ini` from `MAME` 230
* Attack of the Clones! - support import of merged romsets.
* `MAME` Software List (aka softlist) support.
    - allow sloftlist `XML` files to be imported.
    - *smart* import of software romsets.
* Collapsable sections in `ChooseGameUI`
* Snapshot button on `HUD` and ability to use a Snapshot as Title image.
* handle import of `7z` files.
    - 139 version of `MAME4iOS` will ignore `7z` romsets
* Support for new `Apple Remote` with tvOS 14.6
* Added ability to group Clones in a different section in `ChooseGameUI`

# Version 2021.6
* `Mouse` device support.
* `MAME` full keyboard support.
* Remove `Netplay`
* `OSD` cleanup.
* Option to turn ON/OFF haptic feedback.
* New in-game menu using InfoHUD technology.
* New Game Controller `MENU` modifiers. 
    - `MENU+A` Speed 2x 
    - `MENU+B` Pause `MAME`
* Remove ColorSpace choices from the UI.
* Remember changes made in Shader parameter editor.
* `HUD` Info mode.
* Native `Metal` FPS display.
* Support extra brightness on `HDR` displays.
* **tvOS** `HUD` can be used on tvOS, but only with SiriRemote.
* **macOS** use larger fonts for `MENU` and ChooseGameUI (like tvOS).
* **macOS** ⌘+ENTER will cycle through `FULLSCREEN` modes.

## Game controller MENU combos

| | |  
---------------- |-------------
MENU             |Open MAME4iOS MENU   
MENU+L1       |Player Coin                 
MENU+R1       |Player Start               
MENU+L2       |Player 2 Coin                
MENU+R2       |Player 2 Start               
MENU+A          |Speed 2x              
MENU+B          |Pause MAME   
MENU+X          |Exit Game                 
MENU+Y          |Open MAME menu   
MENU+DOWN  |Save State ①               
MENU+UP        |Load State ①                
MENU+LEFT     |Save State ②                
MENU+RIGHT  |Load State ②               


# Version 2021.5
* Metal only, remove support for a software renderer.
* Fixed mirroring orientation in games like Lethal Enforcers, Space Gun

# Version 2021.4
* Better support for MFi controllers.
* Game Controllers with more than two menu buttons (Xbox, DualShock, Xinput, Nimbus+, new MFi)
    - Left menu button is always `SELECT`
    - Right menu button is always `START`
    - `SELECT` + `START` will bring up MAME4iOS menu
    - holding down `SELECT` or `START` will show a *quick help HUD*
* on iOS 14+ (not on tvOS) the XBox `GUIDE` button, and the DualShock `PS` button can be used instead of `SELECT`+`START`

# Version 2021.3
* This is a Mac-only release that has all the updates to 2021.2 and supports both Intel and Apple Silicon Macs.

# Version 2021.2
* Fix for dynamic recompile core setting for games like Killer Instinct

# Version 2021.1
* bugfixes for tvOS.

# Version 2020.14
* Build on Xcode 12.2
* Build Simulator and Catalyst on a Apple Silicon (M1) machine.

# Version 2020.13
* New default artwork.
* Netplay bugfix, must be running a game to join or host.
* Save independant HUD position for landscape/portrait.
* iOS 14 Widget.
* tvOS TopShelf
* New ChooseGameUI look.
* iCloud import, export, and sync.
* Mame Warning messages now have their own Mame Menu entry.

# Version 2020.12
* `Metal` frame-skip updates and fixes.
* Updated the `lineTron` vector shader.
* The HUD will honor the system DynamicType size.
* PINCH and ZOOM to resize the HUD to exacly the size you want.
* set MAME pause_brightness to 1.0
* Support for Xbox `GUIDE`, DualShock `PS`, and Steam `STEAM` buttons on iOS 14.
* Support WideColor (aka DisplayP3) devices.
* Support SlideOver and SplitScreen on iPad.
* Support macOS via Catalyst, requires macOS 10.15 (aka Catalina) or higher.
* Mac menu bar and edge to edge game window.
* A,B,Y,X,L,R on a hardware keyboard will function as buttons.
* lineTron and simpleTron are now used as the default `LINE` and `SCREEN` shaders.
* Skin support, use `Export Skin...` to create a Skin template file, and open the `README.md` inside the Skin.

# Version 2020.11
* Added new Vector Shader category for Vector games on both iOS and tvOS.
* The HUD has received a lot of Ux updates, better sizing, new options, etc. 
* The HUD will honor the system DynamicType size.
* Added a means to Pause MAME but still tweak the Shaders in realtime (available in debug mode).
* Various texture cache fixes.
* Added in `ulTron` CRT Screen Shader: this is the ulTimate CRT shader *but* it is very heavy to compute and may not perform in realtime on lower class hardware and/or at higher Resolutions.
* Renamed the simpleCRT Screen Shader to `simpleTron`, to better align with the other shader naming conventions.
* Added in `lineTron` Vector shader, for the best dang lookin' Vector games around...
* P3 and P4 Start in the in-game and HUD menu.
* MAME Soft Reset (aka F3) in the HUD.

# Version 2020.10
* New `megaTron` Shader.
* Render with Metal on external displays.
* Video Options are no longer specific to Portrait or Landscape.
    - except option to default to fullscreen.
* New HUD UI, turn on `showHUD` to play with it.

# Version 2020.9
* Support for rendering with [Metal](https://en.wikipedia.org/wiki/Metal_(API)) (new)
   - Metal can be turned off in Options `use Metal`.
   - `Simple CRT` Effect, emulate a old CRT monitor.
* Video options (new)
    - Use Integer Scaling Only
    - Ability to select the ColorSpace used to display MAME screen.
* Colorspace (new)
    - DisplayRGB 
    - sRGB
    - CRT (gamma 2.5)
    - Rec709 (gamma 2.4)
* Border options (new)
    - Light
    - Dark
    - Solid Color
* Effect options (was checkboxes, now a list)
    - CRT
    - Scanline
    - Simple CRT (Metal only)
* Filter options (was a checkbox, now a list)
    - Nearest
    - Linear
* Artwork
    - Artwork is shown at hires by default.
* Add to Siri Support

      
# Version 2020.8
* Better INFO/HISTORY.DAT display in landscape (and tvOS)
* Fixed tvOS MAME top shelf wide logo

# Version 2020.7

* Added in 4K/UHD MAME render resolution support so that MAME artwork looks much better
* Added in iCade support for tvOS 
* Steam Controller support, controller must be in [bluetooth mode and paired](https://support.steampowered.com/kb_article.php?ref=7728-QESJ-4420)
* Fixed issue where audio would stop when playing back content from another source or being interrupted by a phone call.
* Set the audio catefory to `AVAudioSessionCategoryAmbient` so MAME4iOS will play nice with other audio apps.
* Make the 🅐 🅑 🅧 🅨 layout consistent across iPhone and iPad.
* Added a `Nintendo Button Layout` option.  if enabled the 🅐 🅑 and 🅧 🅨 buttons will be swapped to match a Nintendo layout.  This option has no effect on a custom layout, or a physical game controller.
* Better handling for 2 Player games, a 1 Player and a 2 Player Start option will be on the in-game menu.  We try to detect how many Players, Inputs, and Coins the current game is looking for and try to adapt to that.
* Downgrade controllers, if you are trying to use Controller 3 on a game that only takes 2 inputs, Controller 3 will be mapped to Player 1.
* Controller Identify, when you hit `MENU` on a controller the Player number is displayed as the title of the in-game menu.
* Supports Controler trigger buttons `L2`, `R2`.  `MENU+L2` will Insert a `P2 COIN`, and `MENU+R2` will do a `P2 START`.
* Removed separate `Load State` and `Save State` from the in-game menu, to make room, the menu is cramped in landscape and tvOS
* 🅑 will exit a `MAME` menu
* Added support for HISTORY.DAT and MAMEINFO.DAT. you can import a .ZIP file containing the files or manualy copy files into `dats` directory.

# Version 2020.6

* Version and Build info shown in Settings
* Export all data for a game from Share context menu 

# Version 2020.5

* Allow for the exporting of a game and all of its state (hiscores, saved state, artwork, etc)
* Show app version number, and build info in Settings for easier tracking of builds
* Added Reset option in Settings

# Version 2020.4

* Updated default game icon when icons are not in the game database such as neogeo.zip and others
* Added a `RESET TO DEFAULTS` button 
* tvOS Settings page update and other UI/Layout improvements
* Massive Zip import speed increase and refactoring
* Added a means to filter by game driver such as CPS1, CPS2, etc

# Version 2020.3

* Turbo mode updates and Ux fixes
* Only show one row of recent games
* Menu context button updates
* Use alternate source location for title images

# Version 2020.2

* tvOS UI cleanup
* Add in Parallax UI behaviour in tvOS menu
* Mame logo and general branding updates
* General UI performance updates

# Version 2020.1

# Version 2020.0

0.139
-----
You can see whats new in the MAME core [here](https://www.mamedev.org/releases/whatsnew_0139.txt)

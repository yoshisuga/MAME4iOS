---
title: Help
---

# MAME4iOS Help

## Using MAME

When you start MAME4iOS, you are now presented with an updated and native iOS/tvOS MAME UI

### MAME UI Controls

- Onscreen D-Pad or MFI Controller D-Pad: Move through the menu
- A Button: Start Game

### In-Game

- Coin: `SELECT/COIN` for Player 1
- Start: `START` for Player 1
- Menu: Open the MAME4iOS menu
- Exit: Exit the game

## Adding ROMs to MAME4iOS

### iOS

For iOS users, you can download ROMs using Safari and save them to the `roms` directory by choosing the "Save to Files" (go to "On My iPhone" -> MAME4iOS) option after downloading a ROM. 

You can also use the "Start Server" option in the menu to start the webserver, and enter the address shown on the web browser on your computer.

You can also use the "Import ROMs" option to open up the native iOS file browser and load files that are saved locally or that exist on iCloud.

You can use "Import from iCloud" to download ROMs previously uploaded to iCloud.

### tvOS

on tvOS the only options are to copy ROMs via "Start Server" or downloading via "Import from iCloud".

## Adding Softare to MAME4iOS

MAME4iOS supports two types of Software

1. Software List (aka MESS) based software, installed via ZIP files into `roms`

2. Single file based image (cart, flop, dsk, ...), installed into `software`

## ROMless Machines

MAME4iOS includes a set of Machines/Systems that dont need any ROMs installed to run, and can be used "out of the box".

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
n64     |Nintendo 64                                                |rom, v64, n64, z64, bin
n64dd   |Nintendo 64DD                                              |bin, 2mg, rom, n64, z64, hdv, hd, v64, chd, hdi
c64gs   |Commodore 64 Games System (PAL)                            |a0, 80, prg, t64, e0, p00, crt
c64     |Commodore 64 (NTSC)                                        |d64, tap, prg, a0, g64, 80, g41, g71, wav, p00, mfi, dfi, t64, e0, crt
apple1  |Apple I                                                    |wav, snp
apple2  |Apple ][                                                   |do, mfi, dsk, rti, edd, wav, woz, nib, dfi, po
apple2gs|Apple IIgs (ROM03)                                         |mfi, edd, mfm, td0, 360, img, do, nib, imd, dc42, hfe, rti, ima, po, d77, ufi, woz, dsk, 2mg, cqi, dfi, cqm, d88, 1dd
mac128k |Macintosh 128k                                             |d88, dsk, cqm, d77, img, dc42, mfm, 2mg, 1dd, cqi, imd, dfi, mfi, woz, td0, ufi, 360, ima, hfe
ibm5150 |IBM PC 5150                                                |mfi, td0, mfm, wav, hdv, 360, img, hd, xdf, imd, hfe, 2mg, ima, hdi, d77, ufi, dsk, chd, cqi, dfi, cqm, d88, 1dd
bbca    |BBC Micro Model A                                          |wav, uef, rom, bin, csw
bbcb    |BBC Micro Model B                                          |adf, mfi, fsd, td0, mfm, wav, 360, ads, csw, img, rom, prn, adl, imd, bin, bbc, hfe, adm, ima, d77, dsk, ufi, uef, ssd, cqi, dfi, dsd, cqm, d88, 1dd

## Game Controller Support

Pair your MFi, Xbox, or Dual Shock controller with your iOS device, and it should 'just work'.
Up to 4 controllers are supported.

### Hotkey combinations (while in-game)

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

### Hotkey combinations (while in choose game UX)

| | |  
---------------- |-------------
MENU             |Game Context Menu  
OPTION           |MAME4iOS Settings              
A                |Play              

### Dual analog support

The right stick on the extended controller profile is fully supported, with support for 4 players (thank you @DarrenBranford!)

### Trigger buttons

The trigger buttons are mapped to analog controls and should be useful in assigning for pedal controls, for example.

## Touch Screen Lightgun Support (new in 2018, iOS only)

You can now use the touch screen for lightgun games like Operation Wolf and Lethal Enforcers. Holding down your finger simulates holding down the trigger, which is mapped to the "X" button. Tap with 2 fingers for the secondary fire, or the "B" button.

In full screen landscape mode, you can hide the onscreen controls using the "D-Pad" button at the top of the screen. When using a game controller, the top button of the screen opens the menu to load/save state or access settings.

Touch Lightgun setup is in Settings -> Input -> Touch Lightgun, where you can disable it altogether, or use tapping the bottom of the screen to simulate shooting offscreen (for game that make you reload like Lethal Enforcers).

#### Shortcuts while in Touch Screen Lightgun mode

- Touch with 2 fingers: secondary fire ("B" button)
- Touch with 3 fingers: press start button
- Touch with 4 fingers: insert coin

## Turbo Mode Toggle for Buttons (new in 2018)

Under Settings -> Game Input, there's a section called "Turbo Mode Toggle", that lets you turn on turbo firing for individual buttons. Holding down the button causes the button to fire in turbo mode.

## Touch Analog Mode (new in 2019, iOS only)

Also in Settings -> Game Input, you'll find a section called "Touch Analog" and "Touch Directional Input". "Touch Analog" lets you use your touchscreen as an analog device for games using input controls such as trackballs and knobs. These include games like Arkanoid or Crystal Castles. You can adjust the sensitivity of the analog controls, and also choose to hide the d-pad/analog stick in this mode.

"Touch Directional Input" is rather experimental and is for vertical shooters so you can move around using your finger. It still needs some work so just a word of caution :)


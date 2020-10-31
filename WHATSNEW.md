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

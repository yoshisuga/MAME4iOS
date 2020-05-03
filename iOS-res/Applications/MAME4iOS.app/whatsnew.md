<img src="mame_logo.png" width="60%">

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

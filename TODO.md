# MAME 2xx TODO

* Font is getting scaled badly, show info on startup is unreadable. 
    - fixed we always run at hi-res now.
* investigate loooooong startup time, and what can we do about it.
* Font scaled textures not cached, getting re-loaded every frame when Config or Main Menu is active. A seqid problem similar to one I fixed in 139. 
* Command line options for -cheat, -bench, -beam width need fixed. 
    - fixed
* Need to update at least help, and maybe UI to call out options that can’t be changed without restarting game. 
    - fixed any Settings change causes a restart
* How does the cheat system work on 2xx, do we need a new cheat.zip? Does the old one being around break anything?? Can we have a cheat.7z co-exist with cheat.zip
    - use cheat.7z for 2xx, and use cheat.zip for 139
* How does new hiscore system work, will old dat file conflict
    - 2xx HISCOREs needs the plugin system, we have copy in a resource plugin.zip, extract on first-run
    - old hiscore.dat will conflict, we delete it when running 2xx
* Figure out correct solution to delayed game_list
    - maybe dont pause the MAME thread when ChooseUI is active, just dont send any input to MAME.
    - fixed, we dont hard pause MAME when the UI is up.
* OSD needs to get the “input profile” for the current game (ie num-players, etc)
    - done.
* Clean up the OSD module stuff
    - done module stuff is all gone.
* Find out is FORCE_DRC_C_BACKEND or NOASM needed. 
    * -[no]drc
    * -drc_use_c
* Test mouse and lightgun input. 
* Handle sending command keys to MAME when in a game that uses the keyboard. 
    -  Big problem for ESC, we can’t even exit (maybe have a special MYOSD exit command, or special key)
    - fixed we do a schedule-exit so MAME will exit, even in a keyboard machine.
* Support switching keyboard modes, support UIMODEKEY 
    - uimodekey is mapped to backslash in DEBUG (for now)
* Support an on-screen keyboard for games that use keyboard, figure out simple UI for it.
    * Menu or HUD command to hide/show keyboard?
    * See if alpha can be applied to system keyboard?
    * Add a row of keys to top of keyboard, replacing suggestions (coin, start, menu, exit,….)
* See if 7z and ZIP files can co-exist
    * It looks like MAME will check ZIP first, then 7z question is will CRC fail in ZIP cause it to move along to 7z
    - **YES** you can have both `7z` and `zip` 2xx will find roms in the `7z` 139 will ignore `zip`
* See if a ZIP file renamed 7z will work. 
    - **NO** you cant just rename a ZIP -> 7Z, you must convert it
* Support -bench mode (in 139 and 2xx)
    * -str <n> -video none -sound none -nothrottle
* Support -autosave (139 and 2xx)
* Show Snaps and Videos in the UI and let user delete them (or make a snap the title image)
    - done.
* Figure out right value to use for osd-numprocessors
* Investigate pre-scale.
* Watchdog timer?
* -confirm_quit and -ui_mouse
*  -ui simple
* -bios <name>
* LUA console and HTTP server, disable?
* Support LCD screen type.
    - LCD is detected, but no special shader yet.


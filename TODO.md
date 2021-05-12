# MAME 2xx TODO

* Font is getting scaled badly, show info on startup is unreadable. 
* Font scaled textures not cached, getting re-loaded every frame when Config or Main Menu is active. A seqid problem similar to one I fixed in 139. 
* Command line options for -cheat, -bench, -beam width need fixed. 
* Need to update at least help, and maybe UI to call out options that can’t be changed without restarting game. 
* How does the cheat system work on 2xx, do we need a new cheat.zip? Does the old one being around break anything?? Can we have a cheat.7z co-exist with cheat.zip
* How does new hiscore system work, will old dat file conflict
* MAME 2xx will run/restore the last game, this is **bad** and needs turned off in the OSD. M4i manages restoring last game. 
* Figure out correct solution to delayed game_list
* OSD needs to get the “input profile” for the current game (ie num-players, etc)
* Clean up the OSD module stuff
* Find out is FORCE_DRC_C_BACKEND or NOASM needed. 
    * -[no]drc
    * -drc_use_c
* Test mouse and lightgun input. 
* Handle sending command keys to MAME when in a game that uses the keyboard. 
    *  Big problem for ESC, we can’t even exit (maybe have a special MYOSD exit command, or special key)
* Support switching keyboard modes, support UIMODEKEY 
* Support an on-screen keyboard for games that use keyboard, figure out simple UI for it.
    * Menu or HUD command to hide/show keyboard?
    * See if alpha can be applied to system keyboard?
    * Add a row of keys to top of keyboard, replacing suggestions (coin, start, menu, exit,….)
* See if 7z and ZIP files can co-exist
    * It looks like MAME will check ZIP first, then 7z question is will CRC fail in ZIP cause it to move along to 7z
* See if a ZIP file renamed 7z will work. 
* Support -bench mode (in 139 and 2xx)
    * -str <n> -video none -sound none -nothrottle
* Support -autosave (139 and 2xx)
* Show Snaps and Videos in the UI and let user delete them (or make a snap the title image)
* Figure out right value to use for osd-numprocessors
* Investigate pre-scale.
* Watchdog timer?
* -confirm_quit and -ui_mouse
*  -ui simple
* -bios <name>
* LUA console and HTTP server, disable?
* Support LCD screen type.
* 


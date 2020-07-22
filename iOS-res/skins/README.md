# MAME4iOS Skins

## Skin format
A `Skin` is just a `zip` file with images, and a single file `skin.json` used to override the MAME4iOS defaults.

## Skin names
The file name of the Skin is used as the display name in the select UI.

## Skin location
Custom Skins are stored in the `skins` folder.

## Removing a Skin
You can remove all Skins by selecting `Reset to Defaults` from `Settings`

## Making a new Skin.
1. run MAME4iOS and select the `Default` Skin from the UI.
2. Choose `Export Skin...` you will get a file called "Default Skin Template.zip"
    - this template will have all default images and button positions.
    - Unzip template and modify (or add) image files, and edit positions and meta data in `skin.json`
    - **Important** delete any image files and button positions you dont want to modify.
    - Rezip the directory and give it a new name, like "My Cool Skin.zip"
3. Import new Skin zip into MAME4iOS, it should be offered as an option in the UI.

## Changing a Skin.
1. run MAME4iOS and select the Skin you want to change from the UI.
2. Choose `Export Skin...` you will get a file named the same as the current Skin.
    - this template will *only* have images and button positions that are different from the default.
    - Unzip template and edit image files, and positions in `skin.json`
    - If you need access to default images or positions, export a Skin template and copy images or info from the template.
    - Rezip the directory and give it a new name, if you want.
3. Import modified Skin zip into MAME4iOS.

## Automatic selection of a Skin
Skins named with the `romname.zip`, `parent.zip`, or `driver.zip` of the currenly running game will be automaticaly selected.  They also will not be shown in the UI.  If you want to use the built-in layout editor (found in `Settings` > `Input Options` > `Change Current Layout`)  you should re-name your Skin file to not be the name of a rom, parent, or driver, for example name your Skin `My PacMan Skin.zip`

## Skins on tvOS
Only `border` and `background` images are used on tvOS.


## Format of `skin.json`

```
{
    "info": { <skin file info, see blow> },
    "portrait" : { <button locations for portrait mode on iPad> },
    "portrait_tall" : { <button locations for portrait mode on iPhone> },
    "landscape" : { <button locations for landscape mode on iPad> },
    "landscape_wide" : { <button locations for landscape mode on iPhone> }
}
```

## `skin.json` skin file info
Key                     | Description
----------------------- | -------------------------------------
version                 | `integer` version number, should be 1
author                  | `string` name of the author
description             | `string` long description of the `Skin`, not currently shown.

## `skin.json` button locations
The following are all the button names, the value in the dictionary is a `string` with 3 numbers separated by commas. The first two numbers are the X,Y of the center point of the button.  The third number is the size of the button, a zero size will hide the button. All positions are specifed as 0...1000 releative to the top left of the background image. For example `"A": "500,500,250"` will put the `A button` in the center of the background, and `"L1": "0,0,0"` will hide the `L1 button`

| Button|
|-------|
|A      |                 
|B      |                 
|Y      |
|X      |
|L1     |
|L2     |
|A+Y    |                 
|A+X    |                 
|B+Y    |
|B+X    |
|A+B    |
|SELECT |
|START  |
|EXIT   |
|OPTION |
|STICK  |


## Skin image files
The following are the images and names, if a Skin is missing an image file a default one will be used.

### Buttons
Name                    | Description
----------------------- | -------------------------------------
button_NotPress_A       | A button in the *up* state
button_NotPress_B       | B button in the *up* state
button_NotPress_Y       | Y button in the *up* state
button_NotPress_X       | X button in the *up* state
button_NotPress_L1      | L1 button in the *up* state
button_NotPress_L2      | L2 button in the *up* state
button_Press_A          | A button in the *down* state
button_Press_B          | B button in the *down* state
button_Press_Y          | Y button in the *down* state
button_Press_X          | X button in the *down* state
button_Press_L1         | L1 button in the *down* state
button_Press_L2         | L2 button in the *down* state
button_NotPress_start   | START button in the *up* state
button_NotPress_select  | SELECT button in the *up* state
button_NotPress_exit    | EXIT button in the *up* state
button_NotPress_option  | OPTION button in the *up* state
button_Press_start      | START button in the *down* state
button_Press_select     | SELECT button in the *down* state
button_Press_exit       | EXIT button in the *down* state
button_Press_option     | OPTION button in the *down* state

### Backgrounds
Name                        | Description
--------------------------- | -------------------------------------
background_landscape        | background image, landscape iPad
background_landscape_wide   | background image, landscape iPhone
background_landscape_tile   | background tiled image, landscape
background_portrait         | background image, portrait iPad
background_portrait_tall    | background image, portrait iPhone
background_portrait_tile    | background tiled image, portrait

### Joystick and DPAD
Name                        | Description
--------------------------- | -------------------------------------
stick-inner                 | image of the joystick ball
stick-outer                 | background image of the joystick when fullscreen
stick-background            | background image of the joystick 
stick-background-landscape  | background image of the joystick
DPad_NotPressed             | image of the DPAD
DPad_U                      | image of the DPAD UP
DPad_D                      | image of the DPAD DOWN
DPad_L                      | image of the DPAD LEFT
DPad_R                      | image of the DPAD RIGHT
DPad_UL                     | image of the DPAD UP LEFT
DPad_DL                     | image of the DPAD DOWN LEFT
DPad_DR                     | image of the DPAD DOWN RIGHT
DPad_UR                     | image of the DPAD UP RIGHT

## Skin optional files
The following files are used if present, there is no default.

Name                    | Description
----------------------- | -------------------------------------
background              | background of the whole app, tiled image, fullscreen portrait or landscape
border                  | border image, drawn around the game screen.
stick-U                 | image of the joystick ball UP
stick-D                 | image of the joystick ball DOWN
stick-L                 | image of the joystick ball LEFT
stick-R                 | image of the joystick ball RIGHT
stick-UL                | image of the joystick ball UP LEFT
stick-DL                | image of the joystick ball DOWN LEFT
stick-DR                | image of the joystick ball DOWN RIGHT
stick-UR                | image of the joystick ball UP RIGHT

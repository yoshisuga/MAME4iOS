# MAME4iOS Skins

## Skin format
A `Skin` is just a `zip` file with images used to override the MAME4iOS defaults.

## Skin version 1
Version 1 only lets you change the default images, it **DOES NOT** let you change the size or position of the backgrounds or buttons.

## How to create a `Skin`
* Choose `Export Skin` from the Settings page or File menu, to create a Skin template.
* un-zip template
* modify (or add) images
* **delete** images you did not modify, so MAME4iOS will use the defaults.
* re-zip and give the file a friendly name like "My Cool Skin.zip"
* Choose `Import` or use AirDrop to import `Skin` into MAME4iOS

## Skin files
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
back_landscape_iPad         | background image, landscape iPad
back_landscape_iPhone       | background image, landscape iPhone
back_portrait_iPad          | background image, landscape iPad
back_portrait_iPhone        | background image, landscape iPhone

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
background              | background of the whole app, tiled image
border                  | border image, drawn around the game screen.
background_landscape    | background used on both iPhone and iPad
background_portrait     | background used on both iPhone and iPad
stick-U                 | image of the joystick ball UP
stick-D                 | image of the joystick ball DOWN
stick-L                 | image of the joystick ball LEFT
stick-R                 | image of the joystick ball RIGHT
stick-UL                | image of the joystick ball UP LEFT
stick-DL                | image of the joystick ball DOWN LEFT
stick-DR                | image of the joystick ball DOWN RIGHT
stick-UR                | image of the joystick ball UP RIGHT





//============================================================
//
//  droidinput.c - Implementation of MAME input routines
//
//  Copyright (c) 1996-2007, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================

#include "osdepend.h"
#include "emu.h"
#include "ui.h"
#include "uimenu.h"

#include "myosd.h"

// the states
static int joy_buttons[NUM_JOY][12];
static int joy_axis[NUM_JOY][6];
static int joy_hats[NUM_JOY][4];

static int lightgun_buttons[NUM_JOY][2];
static int lightgun_axis[NUM_JOY][2];

static int mouse_buttons[NUM_JOY][3];   // L,R,M
static int mouse_axis[NUM_JOY][3];      // x,y,z

static myosd_input_state myosd_input;

static int poll_ports = 0;

int myosd_num_ways = 0;     // this will be set by init_port_state (in inptport.c)

static void my_poll_ports(running_machine *machine);
static INT32 my_get_state(void *device_internal, void *item_internal);
static INT32 my_axis_get_state(void *device_internal, void *item_internal);

void droid_ios_init_input(running_machine *machine)
{
    memset(&myosd_input,0,sizeof(myosd_input));
	memset(joy_buttons,0,sizeof(joy_buttons));
	memset(joy_axis,0,sizeof(joy_axis));
	memset(joy_hats,0,sizeof(joy_hats));
    
	input_device_class_enable(machine, DEVICE_CLASS_LIGHTGUN, TRUE);
	input_device_class_enable(machine, DEVICE_CLASS_JOYSTICK, TRUE);
	input_device_class_enable(machine, DEVICE_CLASS_MOUSE, TRUE);

	for (int i = 0; i < NUM_JOY; i++)
	{
		char name[10];
		input_device *devinfo;

		snprintf(name, 10, "Joy %d", i + 1);
		devinfo = input_device_add(machine, DEVICE_CLASS_JOYSTICK, name, NULL);
    
        input_device_item_add(devinfo, "LX Axis", &joy_axis[i][0], ITEM_ID_XAXIS, my_axis_get_state);
        input_device_item_add(devinfo, "LY Axis", &joy_axis[i][1], ITEM_ID_YAXIS, my_axis_get_state);
        input_device_item_add(devinfo, "RX Axis", &joy_axis[i][2], ITEM_ID_RXAXIS, my_axis_get_state);
        input_device_item_add(devinfo, "RY Axis", &joy_axis[i][3], ITEM_ID_RYAXIS, my_axis_get_state);
        
        input_device_item_add(devinfo, "LZ Axis", &joy_axis[i][4], ITEM_ID_ZAXIS, my_axis_get_state);
        input_device_item_add(devinfo, "RZ Axis", &joy_axis[i][5], ITEM_ID_RZAXIS, my_axis_get_state);
    
		input_device_item_add(devinfo, "A", &joy_buttons[i][0], ITEM_ID_BUTTON1, my_get_state);
		input_device_item_add(devinfo, "B", &joy_buttons[i][1], ITEM_ID_BUTTON2, my_get_state);
		input_device_item_add(devinfo, "Y", &joy_buttons[i][2], ITEM_ID_BUTTON3, my_get_state);
		input_device_item_add(devinfo, "X", &joy_buttons[i][3], ITEM_ID_BUTTON4, my_get_state);
		input_device_item_add(devinfo, "L", &joy_buttons[i][4], ITEM_ID_BUTTON5, my_get_state);
		input_device_item_add(devinfo, "R", &joy_buttons[i][5], ITEM_ID_BUTTON6, my_get_state);

		input_device_item_add(devinfo, "L2", &joy_buttons[i][6], ITEM_ID_BUTTON7, my_get_state);
		input_device_item_add(devinfo, "R2", &joy_buttons[i][7], ITEM_ID_BUTTON8, my_get_state);

		input_device_item_add(devinfo, "L3", &joy_buttons[i][8], ITEM_ID_BUTTON9, my_get_state);
		input_device_item_add(devinfo, "R3", &joy_buttons[i][9], ITEM_ID_BUTTON10, my_get_state);

        input_device_item_add(devinfo, "Select", &joy_buttons[i][10], ITEM_ID_SELECT, my_get_state);
        input_device_item_add(devinfo, "Start", &joy_buttons[i][11], ITEM_ID_START, my_get_state);

		input_device_item_add(devinfo, "D-Pad Up", &joy_hats[i][0],(input_item_id)( ITEM_ID_HAT1UP+i*4), my_get_state);
		input_device_item_add(devinfo, "D-Pad Down", &joy_hats[i][1],(input_item_id)( ITEM_ID_HAT1DOWN+i*4), my_get_state);
		input_device_item_add(devinfo, "D-Pad Left", &joy_hats[i][2], (input_item_id)(ITEM_ID_HAT1LEFT+i*4), my_get_state);
		input_device_item_add(devinfo, "D-Pad Right", &joy_hats[i][3], (input_item_id)(ITEM_ID_HAT1RIGHT+i*4), my_get_state);
	}

    input_device* keyboard_device = input_device_add(machine, DEVICE_CLASS_KEYBOARD, "Keyboard", NULL);
	if (keyboard_device == NULL)
		fatalerror("Error creating keyboard device");
    
    // make sure MYOSD_KEY enum matches ITEM_ID enum
    _Static_assert(MYOSD_KEY_A == ITEM_ID_A);
    _Static_assert(MYOSD_KEY_0 == ITEM_ID_0);
    _Static_assert(MYOSD_KEY_F1 == ITEM_ID_F1);
    _Static_assert(MYOSD_KEY_ESC == ITEM_ID_ESC);
    _Static_assert(MYOSD_KEY_LCMD == ITEM_ID_LWIN);
    _Static_assert(MYOSD_KEY_CANCEL == ITEM_ID_CANCEL);
    
    // add a key for every MAME key
    for (input_item_id key=ITEM_ID_A; key<=ITEM_ID_CANCEL; key++) {
        astring token;
        input_code_to_token(machine, token, INPUT_CODE(DEVICE_CLASS_KEYBOARD, 0, ITEM_CLASS_SWITCH, ITEM_MODIFIER_NONE, key));
        
        // extract xx from "KEYBOARD_xx_SWITCH"
        char* name = token.text;
        while (*name && *name != '_')
            name++;
        while (*name == '_')
            name++;
        char* pch = name;
        while (*pch && *pch != '_')
            pch++;
        *pch = 0;
        
        input_device_item_add(keyboard_device, name, &myosd_input.keyboard[key], key, my_get_state);
    }

    for (int i = 0; i < NUM_JOY; i++)
    {
        char name[10];
            snprintf(name, 10, "Lightgun %d", i + 1);

        input_device *lightgun_device = input_device_add(machine, DEVICE_CLASS_LIGHTGUN, name, NULL);
        if (lightgun_device == NULL)
            fatalerror("Error creating lightgun device\n");

       input_device_item_add(lightgun_device, "X Axis", &lightgun_axis[i][0], ITEM_ID_XAXIS, my_axis_get_state);
       input_device_item_add(lightgun_device, "Y Axis", &lightgun_axis[i][1], ITEM_ID_YAXIS, my_axis_get_state);
       input_device_item_add(lightgun_device, "A", &lightgun_buttons[i][0], ITEM_ID_BUTTON1, my_get_state);
       input_device_item_add(lightgun_device, "B", &lightgun_buttons[i][1], ITEM_ID_BUTTON2, my_get_state);

	   char mouse_name[10];
	   snprintf(mouse_name, 10, "Mouse %d", i + 1);
	   input_device *mouse_device = input_device_add(machine, DEVICE_CLASS_MOUSE, mouse_name, NULL);
	   if (mouse_device == NULL)
		   fatalerror("Error creating mouse device\n");

	   input_device_item_add(mouse_device, "X Axis", &mouse_axis[i][0], ITEM_ID_XAXIS, my_axis_get_state);
       input_device_item_add(mouse_device, "Y Axis", &mouse_axis[i][1], ITEM_ID_YAXIS, my_axis_get_state);
       input_device_item_add(mouse_device, "Z Axis", &mouse_axis[i][2], ITEM_ID_ZAXIS, my_axis_get_state);
       input_device_item_add(mouse_device, "Left",   &mouse_buttons[i][0], ITEM_ID_BUTTON1, my_get_state);
       input_device_item_add(mouse_device, "Middle", &mouse_buttons[i][1], ITEM_ID_BUTTON2, my_get_state);
       input_device_item_add(mouse_device, "Right",  &mouse_buttons[i][2], ITEM_ID_BUTTON3, my_get_state);
    }

    poll_ports = 1;
}

void my_poll_ports(running_machine *machine)
{
    const input_field_config *field;
	const input_port_config *port;
    if(poll_ports)
    {
        int way8 = 0;
        myosd_input.num_buttons = 0;
        myosd_input.num_lightgun = 0;
        myosd_input.num_mouse = 0;
        myosd_input.num_keyboard = 0;
        myosd_input.num_players = 1;
        myosd_input.num_coins = 1;
        myosd_input.num_inputs = 1;
        myosd_input.num_ways = myosd_num_ways;
        
        for (port = machine->m_portlist.first(); port != NULL; port = port->next())
        {
            for (field = port->fieldlist; field != NULL; field = field->next)
            {
//                printf("FIELD: %s player=%d type=%d\n", input_field_name(field), field->player, field->type);
                
                // walk the input seq and look for highest device/joystick
                if ((field->type >= __ipt_digital_joystick_start && field->type <= __ipt_digital_joystick_end) ||
                    (field->type >= IPT_BUTTON1 && field->type <= IPT_BUTTON12))
                {
                    const input_seq* seq = input_field_seq(field, SEQ_TYPE_STANDARD);
                    
//                    astring str;
//                    input_seq_name(machine, str, seq);
//                    printf("    SEQ: %s\n", str.text);
                
                    for (int i=0; i<ARRAY_LENGTH(seq->code) && seq->code[i] != SEQCODE_END; i++)
                    {
                        input_code code = seq->code[i];
                        if (INPUT_CODE_DEVINDEX(code) >= myosd_input.num_inputs)
                            myosd_input.num_inputs = INPUT_CODE_DEVINDEX(code)+1;
                    }
                }
                
                // count the number of COIN buttons.
                if (field->type == IPT_COIN2 && myosd_input.num_coins < 2)
                    myosd_input.num_coins = 2;
                if (field->type == IPT_COIN3 && myosd_input.num_coins < 3)
                    myosd_input.num_coins = 3;
                if (field->type == IPT_COIN4 && myosd_input.num_coins < 4)
                    myosd_input.num_coins = 4;
                
                // count the number of players, by looking at the types of START buttons.
                if (field->type == IPT_START2 && myosd_input.num_players < 2)
                    myosd_input.num_players = 2;
                if (field->type == IPT_START3 && myosd_input.num_players < 3)
                    myosd_input.num_players = 3;
                if (field->type == IPT_START4 && myosd_input.num_players < 4)
                    myosd_input.num_players = 4;
                if (field->player >= myosd_input.num_players)
                    myosd_input.num_players = field->player+1;
                
                if (field->player!=0)
                    continue;   // only count ways and buttons for Player 1
                
                // count the number of buttons
                if(field->type == IPT_BUTTON1)
                    if(myosd_input.num_buttons<1)myosd_input.num_buttons=1;
                if(field->type == IPT_BUTTON2)
                    if(myosd_input.num_buttons<2)myosd_input.num_buttons=2;
                if(field->type == IPT_BUTTON3)
                    if(myosd_input.num_buttons<3)myosd_input.num_buttons=3;
                if(field->type == IPT_BUTTON4)
                    if(myosd_input.num_buttons<4)myosd_input.num_buttons=4;
                if(field->type == IPT_BUTTON5)
                    if(myosd_input.num_buttons<5)myosd_input.num_buttons=5;
                if(field->type == IPT_BUTTON6)
                    if(myosd_input.num_buttons<6)myosd_input.num_buttons=6;
                if(field->type == IPT_JOYSTICKRIGHT_UP)//dual stick is mapped as buttons
                    if(myosd_input.num_buttons<4)myosd_input.num_buttons=4;
                if(field->type == IPT_POSITIONAL)//positional is mapped with two last buttons
                    if(myosd_input.num_buttons<6)myosd_input.num_buttons=6;
                
                // count the number of ways (joystick directions)
                if(field->type == IPT_JOYSTICK_UP || field->type == IPT_JOYSTICK_DOWN || field->type == IPT_JOYSTICKLEFT_UP || field->type == IPT_JOYSTICKLEFT_DOWN)
                    way8=1;
                if(field->type == IPT_AD_STICK_X || field->type == IPT_LIGHTGUN_X || field->type == IPT_MOUSE_X ||
                   field->type == IPT_TRACKBALL_X || field->type == IPT_PEDAL)
                    way8=1;

                // detect if mouse or lightgun input is wanted.
                if(field->type == IPT_DIAL   || field->type == IPT_PADDLE   || field->type == IPT_POSITIONAL   || field->type == IPT_TRACKBALL_X ||
                   field->type == IPT_DIAL_V || field->type == IPT_PADDLE_V || field->type == IPT_POSITIONAL_V || field->type == IPT_TRACKBALL_Y)
                    myosd_input.num_mouse = 1;
                if(field->type == IPT_MOUSE_X)
                    myosd_input.num_mouse = 1;
                if(field->type == IPT_LIGHTGUN_X)
                    myosd_input.num_lightgun = 1;
                if(field->type == IPT_KEYBOARD || field->type == IPT_KEYPAD)
                    myosd_input.num_keyboard = 1;
            }
        }
        poll_ports=0;
        
        //8 if analog or lightgun or up or down
        if (myosd_input.num_ways != 4) {
            if (way8)
                myosd_input.num_ways = 8;
            else
                myosd_input.num_ways = 2;
        }
        
        mame_printf_debug("Num Buttons %d\n",myosd_input.num_buttons);
        mame_printf_debug("Num WAYS %d\n",myosd_input.num_ways);
        mame_printf_debug("Num PLAYERS %d\n",myosd_input.num_players);
        mame_printf_debug("Num COINS %d\n",myosd_input.num_coins);
        mame_printf_debug("Num INPUTS %d\n",myosd_input.num_inputs);
        mame_printf_debug("Num MOUSE %d\n",myosd_input.num_mouse);
        mame_printf_debug("Num GUN %d\n",myosd_input.num_lightgun);
        mame_printf_debug("Num KEYBOARD %d\n",myosd_input.num_keyboard);
        
        myosd_poll_input_init(&myosd_input);
    }
    
}

static unsigned long myosd_joystick_read(int n)
{
    return myosd_input.joy_status[n];
}

static float myosd_joystick_read_analog(int n, int axis)
{
    return myosd_input.joy_analog[n][axis];
}

void droid_ios_poll_input(running_machine *machine)
{    
    myosd_input.input_mode = ui_is_menu_active() ? MYOSD_INPUT_MODE_MENU : MYOSD_INPUT_MODE_NORMAL;

    my_poll_ports(machine);
    myosd_poll_input(&myosd_input);
    
    // handle *special* EXIT and RESET keys
    if (myosd_input.keyboard[MYOSD_KEY_EXIT] != 0 && !machine->exit_pending())
        machine->schedule_exit();
    
    if (myosd_input.keyboard[MYOSD_KEY_RESET] != 0 && !machine->scheduled_event_pending())
        machine->schedule_hard_reset();
    
    for(int i=0; i<NUM_JOY; i++)
    {
        long _pad_status = myosd_joystick_read(i);

        joy_axis[i][0] = (int)(myosd_joystick_read_analog(i, MYOSD_AXIS_LX) *  32767 *  2 );
        joy_axis[i][1] = (int)(myosd_joystick_read_analog(i, MYOSD_AXIS_LY) *  32767 * -2 );
        joy_axis[i][2] = (int)(myosd_joystick_read_analog(i, MYOSD_AXIS_RX) *  32767 *  2 );
        joy_axis[i][3] = (int)(myosd_joystick_read_analog(i, MYOSD_AXIS_RY) *  32767 * -2 );
        joy_axis[i][4] = (int)(myosd_joystick_read_analog(i, MYOSD_AXIS_LZ) *  32767 *  2 );
        joy_axis[i][5] = (int)(myosd_joystick_read_analog(i, MYOSD_AXIS_RZ) *  32767 *  2 );
        
        joy_hats[i][0] = ((_pad_status & MYOSD_UP) != 0) ? 0x80 : 0;
        joy_hats[i][1] = ((_pad_status & MYOSD_DOWN) != 0) ? 0x80 : 0;
        joy_hats[i][2] = ((_pad_status & MYOSD_LEFT) != 0) ? 0x80 : 0;
        joy_hats[i][3] = ((_pad_status & MYOSD_RIGHT) != 0) ? 0x80 : 0;

        // ignore lightgun and mouse, if we have any joystick input. (why?)
        if(joy_axis[i][0] == 0 && joy_axis[i][1] == 0 && joy_axis[i][2] == 0 && joy_axis[i][3] == 0)
        {
            lightgun_axis[i][0] = (int)(myosd_input.lightgun_x[i] * 32767 *  2);
            lightgun_axis[i][1] = (int)(myosd_input.lightgun_y[i] * 32767 * -2);

            mouse_axis[i][0] = (int)myosd_input.mouse_x[i];
            mouse_axis[i][1] = (int)myosd_input.mouse_y[i];
            mouse_axis[i][2] = (int)myosd_input.mouse_z[i];
        }
        else
        {
            lightgun_axis[i][0] = 0;
            lightgun_axis[i][1] = 0;

            mouse_axis[i][0] = 0;
            mouse_axis[i][1] = 0;
            mouse_axis[i][2] = 0;
        }

        long lightgun_status = myosd_input.lightgun_status[i];
        lightgun_buttons[i][0] = (lightgun_status & MYOSD_A) ? 0x80 : 0x00;
        lightgun_buttons[i][1] = (lightgun_status & MYOSD_B) ? 0x80 : 0x00;

        long mouse_status = myosd_input.mouse_status[i];
        mouse_buttons[i][0] = (mouse_status & MYOSD_A) ? 0x80 : 0x00;
        mouse_buttons[i][1] = (mouse_status & MYOSD_Y) ? 0x80 : 0x00;
        mouse_buttons[i][2] = (mouse_status & MYOSD_B) ? 0x80 : 0x00;

        joy_buttons[i][0]  = ((_pad_status & MYOSD_A) != 0) ? 0x80 : 0;
        joy_buttons[i][1]  = ((_pad_status & MYOSD_B) != 0) ? 0x80 : 0;
        joy_buttons[i][2]  = ((_pad_status & MYOSD_Y) != 0) ? 0x80 : 0;
        joy_buttons[i][3]  = ((_pad_status & MYOSD_X) != 0) ? 0x80 : 0;
        joy_buttons[i][4]  = ((_pad_status & MYOSD_L1) != 0) ? 0x80 : 0;
        joy_buttons[i][5]  = ((_pad_status & MYOSD_R1) != 0) ? 0x80 : 0;

        joy_buttons[i][6]  = ((_pad_status & MYOSD_L2) != 0) ? 0x80 : 0;
        joy_buttons[i][7]  = ((_pad_status & MYOSD_R2) != 0) ? 0x80 : 0;

        joy_buttons[i][8]  = ((_pad_status & MYOSD_L3 ) != 0) ? 0x80 : 0;
        joy_buttons[i][9]  = ((_pad_status & MYOSD_R3  ) != 0) ? 0x80 : 0;

        joy_buttons[i][10]  = ((_pad_status & MYOSD_SELECT ) != 0) ? 0x80 : 0;
        joy_buttons[i][11]  = ((_pad_status & MYOSD_START  ) != 0) ? 0x80 : 0;
    }
}

//============================================================
//  osd_customize_inputport_list
//============================================================

void osd_customize_input_type_list(input_type_desc *typelist)
{
	input_type_desc *typedesc;

    // tweak the default UI input
    for (typedesc = typelist; typedesc != NULL; typedesc = typedesc->next)
    {
        switch (typedesc->type)
        {
            // allow the DPAD to move the UI
            case IPT_UI_UP:
                input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1UP));
                break;
            case IPT_UI_DOWN:
                input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1DOWN));
                break;
            case IPT_UI_LEFT:
                input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1LEFT));
                break;
            case IPT_UI_RIGHT:
                input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1RIGHT));
                break;
            /* TODO: this is used only by mame top level menu, not needed? */
            case IPT_OSD_1:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON4, 0));
                break;
                
            /* these are just the MAME defaults, dont change them!
            case IPT_UI_CONFIGURE:
                // having SELECT+START bring up the MAME MENU has the side effect of inserting a COIN and/or STARTing the game, not ideal.
                // input_seq_set_2(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 0), INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 0));
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], KEYCODE_TAB);
                break;
            case IPT_UI_PAUSE:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], KEYCODE_PAUSE);
                break;
            case IPT_SERVICE:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], KEYCODE_F2);
                break;
            case IPT_UI_SOFT_RESET:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], KEYCODE_F3);
                break;
            case IPT_UI_LOAD_STATE:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], KEYCODE_F7);
                break;
            case IPT_UI_SAVE_STATE:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], KEYCODE_F8);
                break;
            */
        }
    }

    // tweak player joystick input
	for (typedesc = typelist; typedesc != NULL; typedesc = typedesc->next)
	{
		switch (typedesc->type)
		{
            /* player 1 SELECT and START, leave as MAME defaults
            case IPT_COIN1:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 0));
                break;
            case IPT_START1:
                input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 0));
                break;
            */
                
            /* multi-player start with DPAD+SELECT or DPAD+START not needed MAME4iOS handles this via in-game menu now.
			case IPT_COIN2:
                input_seq_set_4(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 1), SEQCODE_OR,
                                                                   INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 0), INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1UP),0));
                break;
			case IPT_START2:
                input_seq_set_4(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 1), SEQCODE_OR,
                                                                   INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 0), STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1UP));
                break;
			case IPT_COIN3:
                input_seq_set_4(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 2), SEQCODE_OR,
                                                                   INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 0), INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1RIGHT),0));
				break;
			case IPT_START3:
				input_seq_set_4(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 2), SEQCODE_OR,
                                                                   INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 0), STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1RIGHT));
				break;
			case IPT_COIN4:
				input_seq_set_4(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 3), SEQCODE_OR,
                                                                   INPUT_CODE_SET_DEVINDEX(JOYCODE_SELECT, 0), INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1DOWN),0));
				break;
			case IPT_START4:
				input_seq_set_4(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 3), SEQCODE_OR,
                                                                   INPUT_CODE_SET_DEVINDEX(JOYCODE_START, 0), STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1DOWN));
				break;
            */
                
            /* these are mostly the same as MAME defaults, except we add dpad to them */
            case IPT_JOYSTICK_UP:
            case IPT_JOYSTICKLEFT_UP:
                if(typedesc->group == IPG_PLAYER1)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1UP));
                else if(typedesc->group == IPG_PLAYER2)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2UP),1));
                else if(typedesc->group == IPG_PLAYER3)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3UP),2));
                else if(typedesc->group == IPG_PLAYER4)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4UP),3));
                break;
			case IPT_JOYSTICK_DOWN:
			case IPT_JOYSTICKLEFT_DOWN:
				if(typedesc->group == IPG_PLAYER1)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1DOWN));
				else if(typedesc->group == IPG_PLAYER2)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2DOWN),1));
				else if(typedesc->group == IPG_PLAYER3)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3DOWN),2));
				else if(typedesc->group == IPG_PLAYER4)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4DOWN),3));
				break;
			case IPT_JOYSTICK_LEFT:
			case IPT_JOYSTICKLEFT_LEFT:
				if(typedesc->group == IPG_PLAYER1)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1LEFT));
				else if(typedesc->group == IPG_PLAYER2)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2LEFT),1));
				else if(typedesc->group == IPG_PLAYER3)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3LEFT),2));
				else if(typedesc->group == IPG_PLAYER4)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4LEFT),3));
				break;
			case IPT_JOYSTICK_RIGHT:
			case IPT_JOYSTICKLEFT_RIGHT:
				if(typedesc->group == IPG_PLAYER1)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1RIGHT));
				else if(typedesc->group == IPG_PLAYER2)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2RIGHT),1));
				else if(typedesc->group == IPG_PLAYER3)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3RIGHT),2));
				else if(typedesc->group == IPG_PLAYER4)
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_STANDARD],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4RIGHT),3));
				break;
                            
            /* MAMEs default for positional, dials and paddles is mouse axis and inc/dev with keyboard or joystick, add dpad to inc/dec */
			case IPT_PADDLE:
			case IPT_TRACKBALL_X:
			case IPT_AD_STICK_X:
			case IPT_LIGHTGUN_X:
            case IPT_POSITIONAL:
			case IPT_DIAL:
				if(typedesc->group == IPG_PLAYER1)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1LEFT),0));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1RIGHT),0));
				}
				else if(typedesc->group == IPG_PLAYER2)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2LEFT),1));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2RIGHT),1));
				}
				else if(typedesc->group == IPG_PLAYER3)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3LEFT),2));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3RIGHT),2));
				}
				else if(typedesc->group == IPG_PLAYER4)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4LEFT),3));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4RIGHT),3));
				}
				break;
			case IPT_PADDLE_V:
			case IPT_TRACKBALL_Y:
			case IPT_AD_STICK_Y:
			case IPT_LIGHTGUN_Y:
			case IPT_POSITIONAL_V:
			case IPT_DIAL_V:
				if(typedesc->group == IPG_PLAYER1)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1UP),0));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1DOWN),0));
				}
				else if(typedesc->group == IPG_PLAYER2)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2UP),1));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2DOWN),1));
				}
				else if(typedesc->group == IPG_PLAYER3)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3UP),2));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3DOWN),2));
				}
				else if(typedesc->group == IPG_PLAYER4)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4UP),3));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4DOWN),3));
				}
				break;
                
            /* mouse input inc/dec MAMEs default is arrow keys or Joystick, add in dpad */
			case IPT_MOUSE_X:
				if(typedesc->group == IPG_PLAYER1)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1LEFT),0));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1RIGHT),0));
				}
				else if(typedesc->group == IPG_PLAYER2)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2LEFT),1));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2RIGHT),1));
				}
				else if(typedesc->group == IPG_PLAYER3)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3LEFT),2));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3RIGHT),2));
				}
				else if(typedesc->group == IPG_PLAYER4)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4LEFT),3));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4RIGHT),3));
				}
				break;
			case IPT_MOUSE_Y:
				if(typedesc->group == IPG_PLAYER1)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1UP),0));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT1DOWN),0));
				}
				else if(typedesc->group == IPG_PLAYER2)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2UP),1));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT2DOWN),1));
				}
				else if(typedesc->group == IPG_PLAYER3)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3UP),2));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT3DOWN),2));
				}
				else if(typedesc->group == IPG_PLAYER4)
				{
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_DECREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4UP),3));
                    input_seq_append_or(&typedesc->seq[SEQ_TYPE_INCREMENT],INPUT_CODE_SET_DEVINDEX(STANDARD_CODE(JOYSTICK, 0, SWITCH, NONE, HAT4DOWN),3));
				}
				break;
                
            /* MAME has defaults for these, and these are Nintendo layout anyway, just keep what MAME has
			case IPT_JOYSTICKRIGHT_UP:
				if(typedesc->group == IPG_PLAYER1)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON4, 0));
				else if(typedesc->group == IPG_PLAYER2)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON4, 1));
				else if(typedesc->group == IPG_PLAYER3)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON4, 2));
				else if(typedesc->group == IPG_PLAYER4)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON4, 3));
				break;
			case IPT_JOYSTICKRIGHT_DOWN:
				if(typedesc->group == IPG_PLAYER1)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON2, 0));
				else if(typedesc->group == IPG_PLAYER2)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON2, 1));
				else if(typedesc->group == IPG_PLAYER3)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON2, 2));
				else if(typedesc->group == IPG_PLAYER4)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON2, 3));
				break;
			case IPT_JOYSTICKRIGHT_LEFT:
				if(typedesc->group == IPG_PLAYER1)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON3, 0));
				else if(typedesc->group == IPG_PLAYER2)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON3, 1));
				else if(typedesc->group == IPG_PLAYER3)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON3, 2));
				else if(typedesc->group == IPG_PLAYER4)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON3, 3));
				break;
			case IPT_JOYSTICKRIGHT_RIGHT:
				if(typedesc->group == IPG_PLAYER1)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON1, 0));
				else if(typedesc->group == IPG_PLAYER2)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON1, 1));
				else if(typedesc->group == IPG_PLAYER3)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON1, 2));
				else if(typedesc->group == IPG_PLAYER4)
					input_seq_set_1(&typedesc->seq[SEQ_TYPE_STANDARD], INPUT_CODE_SET_DEVINDEX(JOYCODE_BUTTON1, 3));
				break;
            */
                
            /* leave these alone
			case IPT_AD_STICK_Z:
			case IPT_START:
			case IPT_SELECT:
				input_seq_set_0(&typedesc->seq[SEQ_TYPE_STANDARD]);
				break;
            */
		}
	}
}

static INT32 my_get_state(void *device_internal, void *item_internal)
{
	UINT8 *keystate = (UINT8 *)item_internal;
	return *keystate;
}

static INT32 my_axis_get_state(void *device_internal, void *item_internal)
{
	INT32 *axisdata = (INT32 *) item_internal;
	return *axisdata;
}


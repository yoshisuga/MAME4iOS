/*
 * This file is part of MAME4droid.
 *
 * Copyright (C) 2013 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Linking MAME4droid statically or dynamically with other modules is
 * making a combined work based on MAME4droid. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * In addition, as a special exception, the copyright holders of MAME4droid
 * give you permission to combine MAME4droid with free software programs
 * or libraries that are released under the GNU LGPL and with code included
 * in the standard release of MAME under the MAME License (or modified
 * versions of such code, with unchanged license). You may copy and
 * distribute such a system following the terms of the GNU GPL for MAME4droid
 * and the licenses of the other code concerned, provided that you include
 * the source code of that other code when and as the GNU GPL requires
 * distribution of source code.
 *
 * Note that people who make modified versions of MAME4idroid are not
 * obligated to grant this special exception for their modified versions; it
 * is their choice whether to do so. The GNU General Public License
 * gives permission to release a modified version without this exception;
 * this exception also makes it possible to release a modified version
 * which carries forward this exception.
 *
 * MAME4droid is dual-licensed: Alternatively, you can license MAME4droid
 * under a MAME license, as set out in http://mamedev.org/
 */

package com.seleuco.mame4droid.input;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.StringTokenizer;

import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Rect;
import android.os.Handler;
import android.os.Vibrator;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnKeyListener;
import android.view.View.OnTouchListener;

import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.MAME4droid;
import com.seleuco.mame4droid.helpers.DialogHelper;
import com.seleuco.mame4droid.helpers.PrefsHelper;

public class InputHandler implements OnTouchListener, OnKeyListener, IController{
	
	protected AnalogStick stick = new AnalogStick();
	protected  TiltSensor tiltSensor = new TiltSensor();
	protected ControlCustomizer controlCustomizer = new ControlCustomizer();
	
	public TiltSensor getTiltSensor() {
		return tiltSensor;
	}
	
	public ControlCustomizer getControlCustomizer() {
		return controlCustomizer;
	}

	protected static final int[] emulatorInputValues = {
		UP_VALUE,
		DOWN_VALUE,
		LEFT_VALUE,
		RIGHT_VALUE, 
		B_VALUE, 
		X_VALUE, 
		A_VALUE, 
		Y_VALUE, 
		L1_VALUE, 
		R1_VALUE, 
		SELECT_VALUE, 
		START_VALUE,
		L2_VALUE,
		R2_VALUE
		///
	};
		
	/*
	2 = B
	1 = X
	B = Y
	A = A
	+ = START
	- = SELECT	 
	*/
	

	
	public static int[] defaultKeyMapping = {
		KeyEvent.KEYCODE_DPAD_UP,    //WP_Up
		KeyEvent.KEYCODE_DPAD_DOWN,  //WM_DOWN
		KeyEvent.KEYCODE_DPAD_LEFT,  //WM_LEFT
		KeyEvent.KEYCODE_DPAD_RIGHT, //WM_RIGHT
		KeyEvent.KEYCODE_DPAD_CENTER,//WM_A
		KeyEvent.KEYCODE_BACK,       //WM_B
		KeyEvent.KEYCODE_1,          //WM_1
		KeyEvent.KEYCODE_C,          //WM_2 suele ser 2
		KeyEvent.KEYCODE_Z,
		-1,
		KeyEvent.KEYCODE_P,          //WM+
		KeyEvent.KEYCODE_M,          //WM-
		KeyEvent.KEYCODE_H,          //WM HOME
		-1,
		//////		
		KeyEvent.KEYCODE_I,
		KeyEvent.KEYCODE_K,
		KeyEvent.KEYCODE_J,
		KeyEvent.KEYCODE_O,
		KeyEvent.KEYCODE_STAR,
		KeyEvent.KEYCODE_SLASH,
		KeyEvent.KEYCODE_COMMA,
		KeyEvent.KEYCODE_PERIOD,
		-1,
		-1,
		KeyEvent.KEYCODE_PLUS,
		KeyEvent.KEYCODE_MINUS,
		KeyEvent.KEYCODE_BACKSLASH,
		-1,
		//////
		KeyEvent.KEYCODE_PAGE_UP,
		KeyEvent.KEYCODE_PAGE_DOWN,
		KeyEvent.KEYCODE_MEDIA_REWIND,
		KeyEvent.KEYCODE_MEDIA_FAST_FORWARD,
		KeyEvent.KEYCODE_ENTER,
		KeyEvent.KEYCODE_DEL,
		KeyEvent.KEYCODE_SOFT_LEFT,
		KeyEvent.KEYCODE_SOFT_RIGHT,
		-1,
		-1,
		KeyEvent.KEYCODE_BUTTON_THUMBR,
		KeyEvent.KEYCODE_BUTTON_THUMBL,
		KeyEvent.KEYCODE_BUTTON_MODE,
		-1,		
		//////
		KeyEvent.KEYCODE_N,
		KeyEvent.KEYCODE_Q,
		KeyEvent.KEYCODE_T,
		KeyEvent.KEYCODE_APOSTROPHE,
		KeyEvent.KEYCODE_PICTSYMBOLS,
		KeyEvent.KEYCODE_SWITCH_CHARSET,
		KeyEvent.KEYCODE_NOTIFICATION,
		KeyEvent.KEYCODE_MUTE,
		-1,
		-1,
		KeyEvent.KEYCODE_BUTTON_START,
		KeyEvent.KEYCODE_BUTTON_SELECT,
		KeyEvent.KEYCODE_CLEAR,		
		-1
	};
			
	public static int[] keyMapping = new int[emulatorInputValues.length * 4];
	
	protected int ax = 0;
	protected int ay = 0;
	protected float dx = 1;
	protected float dy = 1;
				
	protected ArrayList<InputValue> values = new ArrayList<InputValue>();
	
	protected int [] pad_data = new int[4];
	
	protected int newtouch;
	protected int oldtouch;
	protected boolean touchstate;

	private boolean up_icade = false;
	private boolean down_icade = false;
	private boolean left_icade = false;
	private boolean right_icade = false;
	
	protected  int trackballSensitivity = 30;
	protected  boolean trackballEnabled = true;
		
	/////////////////
	
	final public static int STATE_SHOWING_CONTROLLER = 1;
	final public static int STATE_SHOWING_NONE = 3;
	
	protected int state = STATE_SHOWING_CONTROLLER;
	
	final public static int TYPE_MAIN_RECT = 1;
	final public static int TYPE_STICK_RECT = 2;
	final public static int TYPE_BUTTON_RECT = 3;
	final public static int TYPE_STICK_IMG = 4;
	final public static int TYPE_BUTTON_IMG = 5;
	final public static int TYPE_SWITCH  = 6;
	final public static int TYPE_OPACITY = 7;
	final public static int TYPE_ANALOG_RECT = 8;
	
	
	protected int stick_state;
	public int getStick_state() {
		return stick_state;
	}

	protected int old_stick_state;

	protected int btnStates[] = new int[NUM_BUTTONS];
	public int[] getBtnStates() {
		return btnStates;
	}

	protected int old_btnStates[] = new int[NUM_BUTTONS];
	
	protected MAME4droid mm = null;
	
	//protected Timer timer = new Timer();
	
	protected Handler handler = new Handler();
		
	protected Object lock = new Object();
	
	protected Runnable finishTrackBallMove = new Runnable(){
			//@Override
		    public void run() {
		    	//synchronized(lock){
		    	  //System.out.println("---> INIT C");	
		    	  //System.out.println("+CLEAR Set Pad "+pad_data+ " new:"+newtrack+" old:"+oldtrack);
		    	  //pad_data &= ~oldtrack;	
		    	  pad_data[0] &= ~UP_VALUE;
		    	  pad_data[0] &= ~DOWN_VALUE;
		    	  pad_data[0] &= ~LEFT_VALUE;
		    	  pad_data[0] &= ~RIGHT_VALUE;
				  Emulator.setPadData(0,pad_data[0]);

				  //System.out.println("++CLEAR Set Pad "+pad_data+ " new:"+newtrack+" old:"+oldtrack);
				  //System.out.println("---> CLEAR");
		    	//}
		}};	
		
	public InputHandler(MAME4droid value){
		
		mm = value;
				
		if(mm.getMainHelper().getscrOrientation() == Configuration.ORIENTATION_LANDSCAPE)
		{
			state = mm.getPrefsHelper().isLandscapeTouchController() ? STATE_SHOWING_CONTROLLER : STATE_SHOWING_NONE;
		}
		else
		{
			state = mm.getPrefsHelper().isPortraitTouchController() ? STATE_SHOWING_CONTROLLER : STATE_SHOWING_NONE;
		}
		
		stick_state = old_stick_state = STICK_NONE;
		for(int i=0; i<NUM_BUTTONS; i++)
			btnStates[i] = old_btnStates[i] = BTN_NO_PRESS_STATE;
		
    	for(int i=0;i<4;i++)
    	{	
	    	pad_data[i] = 0;
	    	Emulator.setPadData(i,pad_data[i]);
    	}
		
		stick.setMAME4droid(mm);
		tiltSensor.setMAME4droid(mm);
		controlCustomizer.setMAME4droid(mm);
	}
	
	public int setInputHandlerState(int value){
		return state = value;
	}
	
	public int getInputHandlerState(){
		return state;
	}
	
	public void changeState()
	{
	    if(state == STATE_SHOWING_CONTROLLER)
	    {				    	
	    	for(int i=0;i<4;i++)
	    	{	
		    	pad_data[i] = 0;
		    	Emulator.setPadData(i,pad_data[i]);
	    	}
	    	
	    	state = STATE_SHOWING_NONE;		    				    	
	    }
	    else
	    {
	    	state = STATE_SHOWING_CONTROLLER;
	    }	    	    	
	}
	
	public void setTrackballSensitivity(int trackballSensitivity) {
		this.trackballSensitivity = trackballSensitivity;
	}
	
	public void setTrackballEnabled(boolean trackballEnabled) {
		this.trackballEnabled = trackballEnabled;
	}
	
	public void setFixFactor(int ax, int ay, float dx, float dy){
		this.ax = ax;
		this.ay = ay;
		this.dx = dx;
		this.dy = dy;
		fixControllerCoords(values);
	}
	
	protected boolean setPadData(int i, KeyEvent event, int data){
		int action = event.getAction();
		if(action == KeyEvent.ACTION_DOWN)
			pad_data[i] |= data;
		else if(action == KeyEvent.ACTION_UP)
			pad_data[i] &= ~ data;
		return true;
	}
	
	protected boolean handlePADKey(int value, KeyEvent event){
		
		int v = emulatorInputValues[value%emulatorInputValues.length];
		
	    if(v==L2_VALUE)
	    { 
			if(!Emulator.isInMAME())
			{	
			  mm.showDialog(DialogHelper.DIALOG_EXIT);
			}  
	        else
	        {
	        	Emulator.setValue(Emulator.EXIT_GAME_KEY, 1);		    	
		    	try {
					Thread.sleep(100);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				Emulator.setValue(Emulator.EXIT_GAME_KEY, 0);
	        }  
		}
		else if(v==R2_VALUE)
		{
			 mm.showDialog(DialogHelper.DIALOG_OPTIONS);
		}
		else
		{				
			int i = value/emulatorInputValues.length;
			setPadData(i,event,v);			
			Emulator.setPadData(i,pad_data[i]);
		}
   		
		return true;		
	}
			
	public boolean onKey(View v, int keyCode, KeyEvent event) {
		 //Log.d("TECLA", "onKeyDown=" + keyCode + " " + event.getAction() + " " + event.getDisplayLabel() + " " + event.getUnicodeChar() + " " + event.getNumber());
		
		 if(ControlCustomizer.isEnabled())
		 {
			 if(keyCode == KeyEvent.KEYCODE_BACK)
			 {	 
				 mm.showDialog(DialogHelper.DIALOG_FINISH_CUSTOM_LAYOUT);
			 }	 
			 return true;
		 }
          
		 if(mm.getPrefsHelper().getInputExternal() != PrefsHelper.PREF_INPUT_DEFAULT)
		 {	 
			this.handleIcade(event);
			return true;
	     }
		
		 int value = -1;
		 for(int i=0; i<keyMapping.length; i++)
			 if(keyMapping[i]==keyCode)
				 value = i;
		  
         //if(value >=0 && value <=13)
         if(value!=-1)	 
		     if(handlePADKey(value, event))return true;
            
         return false;
	}
	
	public void handleVirtualKey(int action){
		
		pad_data[0] |= action;
		Emulator.setPadData(0,pad_data[0]);
		
		try {
			Thread.sleep(150);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		pad_data[0] &= ~ action;
		Emulator.setPadData(0,pad_data[0]);
		
	}
	
	//debug method
	public ArrayList<InputValue> getAllInputData(){
		if(state == STATE_SHOWING_CONTROLLER)
			return values;
		else
			return null;			    
	}
	
	public Rect getMainRect(){
		if(values==null)
		   return null;
		for(int i = 0; i <values.size();i++)
		{	
			if(values.get(i).getType()==TYPE_MAIN_RECT)
				return values.get(i).getOrigRect();
		}		
		return null;	
	}
	
	/*
	protected boolean handleTouchController(MotionEvent event){
		boolean b = false;
		
		if(event.getAction() == MotionEvent.ACTION_DOWN || event.getAction() == MotionEvent.ACTION_MOVE)
		{
		   //int x = (int)event.getRawX();
		   //int y = (int)event.getRawY();
		   
		   int x = (int)event.getX();
		   int y = (int)event.getY();
		   
		   for(int i =0; i< values.size();i++)
		   {
			   InputValue iv = values.get(i);
			   
			   if(iv.getRect().contains(x, y))
			   {	
				   if(iv.getType()==TYPE_ACTION)
				   {	 
				       pad_data |= getButtonValue(iv.getValue());				  
				       b =  true;//NO MULTITOUCH (SIC)
				  }
				  else if(iv.getType()==TYPE_SWITCH)
				  {					  
					  changeState();
					  mm.getMainHelper().updateViews();
					  return true;
				  }		
			   }				   
		   }	   		   
		}   
		else
		{
			pad_data = 0; b = true;
		}
		
		if(b)
	       Emulator.setPadData(pad_data);
		
        return b;
		
	}
	*/
	
	protected void handleImageStates(){
		
		PrefsHelper pH = mm.getPrefsHelper();
		
		if(!pH.isAnimatedInput() && !pH.isVibrate())
		   return;
		
	    switch ((int)pad_data[0] & (UP_VALUE|DOWN_VALUE|LEFT_VALUE|RIGHT_VALUE))
	    {
	        case    UP_VALUE:    stick_state = STICK_UP; break;
	        case    DOWN_VALUE:  stick_state = STICK_DOWN; break;
	        case    LEFT_VALUE:  stick_state = STICK_LEFT; break;
	        case    RIGHT_VALUE: stick_state = STICK_RIGHT; break;
	            
	        case    UP_VALUE | LEFT_VALUE:  stick_state = STICK_UP_LEFT; break;
	        case    UP_VALUE | RIGHT_VALUE: stick_state = STICK_UP_RIGHT; break;
	        case    DOWN_VALUE | LEFT_VALUE:  stick_state = STICK_DOWN_LEFT; break;
	        case    DOWN_VALUE | RIGHT_VALUE: stick_state = STICK_DOWN_RIGHT; break;
	            
	        default: stick_state = STICK_NONE;
	    }
			
		for (int j = 0; j < values.size(); j++) {
			InputValue iv = values.get(j);
			if(iv.getType()==TYPE_STICK_IMG && pH.getControllerType() == PrefsHelper.PREF_DIGITAL_DPAD)
			{
				if(stick_state != old_stick_state)
				{
					if(pH.isAnimatedInput())
					   mm.getInputView().invalidate(iv.getRect());					
					if(pH.isVibrate())
					{
						Vibrator v = (Vibrator) mm.getSystemService(Context.VIBRATOR_SERVICE);
						if(v!=null)v.vibrate(15);
					}
					old_stick_state = stick_state;
				}
			}
			else if(iv.getType()==TYPE_ANALOG_RECT && pH.getControllerType() != PrefsHelper.PREF_DIGITAL_DPAD)
			{
				if(stick_state != old_stick_state)
				{
					if(pH.isAnimatedInput() && (pH.getControllerType()==PrefsHelper.PREF_ANALOG_FAST || pH.getControllerType()==PrefsHelper.PREF_DIGITAL_STICK))
					{
					    if(pH.isDebugEnabled())
					      mm.getInputView().invalidate();
					    else
						  mm.getInputView().invalidate(iv.getRect());
					}   
					if(pH.isVibrate())
					{
						Vibrator v = (Vibrator) mm.getSystemService(Context.VIBRATOR_SERVICE);
						if(v!=null)v.vibrate(15);
					}
					old_stick_state = stick_state;
				}
			}			
			else if(iv.getType()==TYPE_BUTTON_IMG)
			{
				int i = iv.getValue();
				
				btnStates[i] = (pad_data[0] & getButtonValue(i,false)) !=0 ? BTN_PRESS_STATE: BTN_NO_PRESS_STATE;
				
				if(btnStates[iv.getValue()]!=old_btnStates[iv.getValue()])
			    {
			    	if(pH.isAnimatedInput())
					    mm.getInputView().invalidate(iv.getRect());			    	 
			    	if(pH.isVibrate())
			    	{
			    	   Vibrator v = (Vibrator) mm.getSystemService(Context.VIBRATOR_SERVICE);
			    	   if(v!=null)v.vibrate(15);
			    	}
			    	old_btnStates[iv.getValue()] = btnStates[iv.getValue()];
			    }
			}							
		}
	}

	protected boolean handleTouchController(MotionEvent event) {

		int action = event.getAction();
		
		oldtouch = newtouch;
				
		int x = (int) event.getX();
		int y = (int) event.getY();

		if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
			touchstate = false;
			
		} else {

			touchstate = true;

			for (int j = 0; j < values.size(); j++) {
				InputValue iv = values.get(j);

				if (iv.getRect().contains(x, y)) {

					if (iv.getType() == TYPE_BUTTON_RECT || iv.getType() == TYPE_STICK_RECT) {

						switch (action) {

						case MotionEvent.ACTION_DOWN:
						case MotionEvent.ACTION_POINTER_DOWN://ESTO NO ESTA en 1.6
						case MotionEvent.ACTION_MOVE:
							
							if(iv.getType() == TYPE_BUTTON_RECT)
							{	
							   newtouch = getButtonValue(iv.getValue(),true);
								 
							   if(iv.getValue()==BTN_L2)
							   { 
								    if(!Emulator.isInMAME())
									    mm.showDialog(DialogHelper.DIALOG_EXIT);
								    else
								    {
								    	if(Emulator.getValue(Emulator.IN_MENU)==0)
								    	{
								           mm.showDialog(DialogHelper.DIALOG_EXIT_GAME);
								    	}
								    	else
								    	{
					    		           Emulator.setValue(Emulator.EXIT_GAME_KEY, 1);		    	
				    			    	   try {Thread.sleep(100);} catch (InterruptedException e) {}
				    					   Emulator.setValue(Emulator.EXIT_GAME_KEY, 0);
								    	}
								    }
								}
								else if(iv.getValue()==BTN_R2)
								{
									 mm.showDialog(DialogHelper.DIALOG_OPTIONS);
								}
							}   
							else if(mm.getPrefsHelper().getControllerType() == PrefsHelper.PREF_DIGITAL_DPAD
									&& !(TiltSensor.isEnabled() && Emulator.isInMAME()))
							{	
							   newtouch = getStickValue(iv.getValue());
							}   
							
							if (oldtouch != newtouch) 
								pad_data[0] &= ~oldtouch;							
							pad_data[0] |= newtouch ;
						}
						break;
					} 
					/*
                   else if (iv.getType() == TYPE_SWITCH) {
						if (event.getAction() == MotionEvent.ACTION_DOWN) {
							touchstate = false;
							oldtouch = 0;
							changeState();
							mm.getMainHelper().updateMAME4droid();
							return true;
						}
					}
					*/
				}
			}			
		}

		if (!touchstate) {

			pad_data[0] &= ~oldtouch;
			newtouch = 0;
			oldtouch = 0;
		}

		handleImageStates();
		
		Emulator.setPadData(0,pad_data[0]);
		
		return true;
	}
	
	public boolean onTouch(View v, MotionEvent event) {
		
		//Log.d("touch",event.getRawX()+" "+event.getX()+" "+event.getRawY()+" "+event.getY());
		
        if(v == mm.getInputView())
		{
		    if(ControlCustomizer.isEnabled())
		    {	
		    	controlCustomizer.handleMotion(event);
		    	return true;
		    }
        	/*if(state == STATE_SHOWING_CONTROLLER)
		    {*/	
		    	if(mm.getPrefsHelper().getControllerType() != PrefsHelper.PREF_DIGITAL_DPAD && !(TiltSensor.isEnabled() && Emulator.isInMAME()))
		    		pad_data[0] = stick.handleMotion(event, pad_data[0]); 	 		    	
		    	handleTouchController(event);
		    	return true;
		    /*}*/
		    //return false;
		}
        else
        {
			if(mm.getMainHelper().getscrOrientation() == Configuration.ORIENTATION_PORTRAIT && state != STATE_SHOWING_NONE)
				return false;
			if(mm.getMainHelper().getscrOrientation() == Configuration.ORIENTATION_LANDSCAPE && state != STATE_SHOWING_NONE)
				return false;
	    	mm.showDialog(DialogHelper.DIALOG_FULLSCREEN);
			return true;
        }
	}

	public boolean onTrackballEvent(MotionEvent event) {

		int gap = 0;

		if(!trackballEnabled)return false;
		
		int action = event.getAction();

		if (action == MotionEvent.ACTION_MOVE /*&& trackballEnabled*/) {

			int newtrack = 0;

			final float x = event.getX();
			final float y = event.getY();

			//float d = Math.max(Math.abs(x), Math.abs(y));

			// System.out.println("x: "+x+" y:"+y);

			if (y < -gap) {
				newtrack |= UP_VALUE;
				// System.out.println("Up");
			} else if (y > gap) {
				newtrack |= DOWN_VALUE;
				// System.out.println("Down");
			}

			if (x < -gap) {
				newtrack |= LEFT_VALUE;
				// System.out.println("left_icade");
			} else if (x > gap) {
				newtrack |= RIGHT_VALUE;
				// System.out.println("right_icade");
			}

			// System.out.println("Set Pad "+pad_data+
			// " new:"+newtrack+" old:"+oldtrack);

			handler.removeCallbacks(finishTrackBallMove);
			handler.postDelayed(finishTrackBallMove, (int) (/* 50 * d */150 * trackballSensitivity));// TODO
			
			if (newtrack != 0) {
				pad_data[0] &= ~UP_VALUE;
				pad_data[0] &= ~DOWN_VALUE;
				pad_data[0] &= ~LEFT_VALUE;
				pad_data[0] &= ~RIGHT_VALUE;
				pad_data[0] |= newtrack;
			}

		} else if (action == MotionEvent.ACTION_DOWN) {
			pad_data[0] |= B_VALUE;

		} else if (action == MotionEvent.ACTION_UP) {
			pad_data[0] &= ~B_VALUE;
		}

		Emulator.setPadData(0,pad_data[0]);

		return true;
	}
		
	protected void fixControllerCoords(ArrayList<InputValue> values) {

		if (values != null) {
			for (int i = 0; i < values.size(); i++) {
				
				values.get(i).setFixData(dx, dy, ax, ay);
				
				if(values.get(i).getType() == TYPE_ANALOG_RECT)
				   stick.setStickArea(values.get(i).getRect());
			}
		}
	}
	
	protected void setButtonsSizes(ArrayList<InputValue> values) {
		
		if(mm.getMainHelper().getscrOrientation() != Configuration.ORIENTATION_LANDSCAPE)
			return;
		
	    int sz = 0;
	    switch(mm.getPrefsHelper().getButtonsSize())
	    {
	       case 1:sz=-30;break;
	       case 2:sz=-20;break;
	       case 3:sz=0;break;
	       case 4:sz=20;break;
	       case 5:sz=30;break;
	    }
	    
	    if(values == null || sz == 0)
	    	return;
	    
	    for (int j = 0; j < values.size(); j++) 
	    {
	    		    	    
	    	InputValue iv = values.get(j);
	    	if(iv.getType() == InputHandler.TYPE_BUTTON_IMG 
	    		|| iv.getType() == InputHandler.TYPE_BUTTON_RECT
	    		|| iv.getType() == InputHandler.TYPE_STICK_IMG)
	    	    iv.setSize(0, 0, sz, sz);
	    	
	    	if(iv.getType() == InputHandler.TYPE_STICK_RECT)
	    	{
	    		switch(iv.getValue())
	    		{
	    		   case 1: iv.setSize(0, 0, 0, 0); break;//upleft
	    		   case 2: iv.setSize(0, 0, sz,0); break;//up
	    		   case 3: iv.setSize(sz, 0, sz,0); break;//upright
	    		   case 4: iv.setSize(0, 0, sz/2,sz); break;//left	    		   
	    		   case 5: iv.setSize(sz/2, 0, sz,sz); break;//right
	    		   case 6: iv.setSize(0, sz, 0,sz); break;//downleft
	    		   case 7: iv.setSize(0, sz,sz,sz); break;	 //down
	    		   case 8: iv.setSize(sz, sz, sz,sz); break;//downright
	    		   default:
	    			 iv.setSize(0, 0,sz,sz);
	    		}
	    	}
	    		    	
			if(iv.getType() == InputHandler.TYPE_ANALOG_RECT)
			{   
				iv.setSize(0, 0,sz,sz);
			    mm.getInputHandler().getAnalogStick().setStickArea(iv.getRect());
			} 
	    }
	}
	
	public AnalogStick getAnalogStick() {
		return stick;
	}

	public int getOpacity(){
		
		ArrayList<InputValue> data = null;
		if(state==STATE_SHOWING_CONTROLLER)
			data = values;
		else
			return -1;
		
		for(InputValue v : data)
		{
		   if(v.getType() == TYPE_OPACITY)
			   return v.getValue();
		}
		return -1;
	}
	
	public void readControllerValues(int v){
		readInputValues(v,values);
		fixControllerCoords(values);
		setButtonsSizes(values);
		if(controlCustomizer!=null)
		   controlCustomizer.readDefinedControlLayout();
	}
	
	protected void readInputValues(int id, ArrayList<InputValue> values)
	{
	     InputStream is = mm.getResources().openRawResource(id);
	     
	     InputStreamReader isr = new InputStreamReader(is);
	     BufferedReader br = new BufferedReader(isr);
	     
	     InputValue iv = null;
	     values.clear();
	     
	     //int i=0;
	     try{
		     String s = br.readLine();
		     while(s!=null)
		     {
		    	 int [] data = new int[10]; 
		    	 StringTokenizer st = new StringTokenizer(s,",");
		    	    int j = 0;
		    		while(st.hasMoreTokens()){
		                String token = st.nextToken();
		                int k = token.indexOf("/");
		                if(k!=-1)
		                {
		                   token = token.substring(0, k);	
		                }
		                
		                token = token.trim();
		                if(token.equals(""))
			                break;
		                data[j] = Integer.parseInt(token);
		                j++;
		                if(k!=-1)break;
		            }    	 
		    	 		    
                    //values.
		    	    if(j!=0)
		    	    {			    	       				    	    	
		    	       iv = new InputValue(data,mm);				    	    
		    	       values.add(iv);
		    	    }  		    				    		
		    	    s = br.readLine();//i++;		    	       
		     }	 
	     }catch(IOException e)
	     {
	    	 e.printStackTrace();
	     }
	}
	
	int getStickValue(int i){
		int ways = mm.getPrefsHelper().getStickWays();
		boolean b = Emulator.isInMAME();
		
		if(ways==2 && b)
		{
			switch(i){
			   case 1: return   LEFT_VALUE;		   
			   case 3: return   RIGHT_VALUE;
			   case 4: return   LEFT_VALUE;
			   case 5: return   RIGHT_VALUE;
			   case 6: return   LEFT_VALUE;		   
			   case 8: return   RIGHT_VALUE;
			}	
		}
		else if(ways==4 /*&& b*/ || !b)
		{
			switch(i){
			   case 1: return   LEFT_VALUE;		   
			   case 2: return   UP_VALUE;
			   case 3: return   RIGHT_VALUE;
			   case 4: return   LEFT_VALUE;
			   case 5: return   RIGHT_VALUE;
			   case 6: return   LEFT_VALUE;		   
			   case 7: return   DOWN_VALUE;
			   case 8: return   RIGHT_VALUE;
			}			
		}
		else
		{
			switch(i){
			   case 1: return   UP_VALUE | LEFT_VALUE;		   
			   case 2: return   UP_VALUE;
			   case 3: return   UP_VALUE | RIGHT_VALUE;
			   case 4: return   LEFT_VALUE;
			   case 5: return   RIGHT_VALUE;
			   case 6: return   DOWN_VALUE | LEFT_VALUE;		   
			   case 7: return   DOWN_VALUE;
			   case 8: return   DOWN_VALUE | RIGHT_VALUE;
			}
		}
		return 0;
	}
	
	int getButtonValue(int i, boolean b){
		switch(i){
		   case 0: return  Y_VALUE;		   
		   case 1:
			    if(mm.getPrefsHelper().isBplusX() && b)
			    {			    	
	                return X_VALUE | B_VALUE | A_VALUE; //El A lo pongo para que salte la animación
                }
                else
                {
                	return  A_VALUE;
				}
		   case 2: return  B_VALUE;
		   case 3: return  X_VALUE;
		   
		   case 4: return  L1_VALUE;
		   case 5: return  R1_VALUE;   
		   case 6: return  L2_VALUE;
		   case 7: return  R2_VALUE;
		   
		   case 8: return  SELECT_VALUE;		   
		   case 9: return  START_VALUE;
		   
		   case 10: return  X_VALUE | A_VALUE;
		   case 11:
			    if(mm.getPrefsHelper().isBplusX() && mm.getPrefsHelper().getNumButtons() >=3 )
			    {
			    	return X_VALUE | B_VALUE;
                }	
			    else
			    	return 0;
			    			    
		   case 12: return Y_VALUE | A_VALUE;
		   case 13: return Y_VALUE | B_VALUE;		   
		}
		return 0;
	}
	
	protected  void dumpEvent(MotionEvent event) {
		   String names[] = { "DOWN" , "UP" , "MOVE" , "CANCEL" , "OUTSIDE" ,
		      "POINTER_DOWN" , "POINTER_UP" , "7?" , "8?" , "9?" };
		   StringBuilder sb = new StringBuilder();
		   int action = event.getAction();
		   int actionCode = action & MotionEvent.ACTION_MASK;
		   sb.append("event ACTION_" ).append(names[actionCode]);
		   if (actionCode == MotionEvent.ACTION_POINTER_DOWN
		         || actionCode == MotionEvent.ACTION_POINTER_UP) {
		      sb.append("(pid " ).append(
		      //action >> MotionEvent.ACTION_POINTER_ID_SHIFT);
		      (action & MotionEvent.ACTION_POINTER_ID_MASK)>> MotionEvent.ACTION_POINTER_ID_SHIFT);		  
		      sb.append(")" );
		   }
		   sb.append("[" );
		   for (int i = 0; i < event.getPointerCount(); i++) {
		      sb.append("#" ).append(i);
		      sb.append("(pid " ).append(event.getPointerId(i));
		      sb.append(")=" ).append((int) event.getX(i));
		      sb.append("," ).append((int) event.getY(i));
		      if (i + 1 < event.getPointerCount())
		         sb.append(";" );
		   }
		   sb.append("]" );
		   Log.d("touch", sb.toString());
		}
		
	protected void handleIcade(KeyEvent event)
	{ 

		int action = event.getAction();
		if(action != KeyEvent.ACTION_DOWN)
			return;
	    
		int ways = mm.getPrefsHelper().getStickWays();
		boolean b = Emulator.isInMAME();
			    
	    int keyCode = event.getKeyCode();
	    
	    boolean bCadeLayout = mm.getPrefsHelper().getInputExternal() == PrefsHelper.PREF_INPUT_ICADE;
	    
	    switch (keyCode)
	    {
	        // joystick up_icade
	        case KeyEvent.KEYCODE_W:              
	            if(ways==4 /*&& b*/ || !b)
	            {
	               pad_data[0] &= ~LEFT_VALUE;
	               pad_data[0] &= ~RIGHT_VALUE;
	            }            
	            if(!(ways==2 && b))
	              pad_data[0] |= UP_VALUE;
	            up_icade = true;     
	            break;
	        case KeyEvent.KEYCODE_E:
	            if(ways==4 && b)
	            {
	               if(left_icade)pad_data[0] |= LEFT_VALUE;
	               if(right_icade)pad_data[0] |= RIGHT_VALUE;
	            }            
	            pad_data[0] &= ~UP_VALUE;
	            up_icade = false;
	            break;
	            
	        // joystick down_icade
	        case KeyEvent.KEYCODE_X:
	            if(ways==4 /*&& b*/ || !b)
	            {
	               pad_data[0] &= ~LEFT_VALUE;
	               pad_data[0] &= ~RIGHT_VALUE;
	            }            
	            if(!(ways==2 && b))
	               pad_data[0] |= DOWN_VALUE;
	            down_icade = true;   
	            break;
	        case KeyEvent.KEYCODE_Z:
	            if(ways==4 && b)
	            {
	               if(left_icade)pad_data[0] |= LEFT_VALUE;
	               if(right_icade)pad_data[0] |= RIGHT_VALUE;
	            }
	            pad_data[0] &= ~DOWN_VALUE;
	            down_icade = false;   
	            break;
	            
	        // joystick right_icade
	        case KeyEvent.KEYCODE_D:            
	            if(ways==4 /*&& b*/ || !b)
	            {
	               pad_data[0] &= ~UP_VALUE;
	               pad_data[0] &= ~DOWN_VALUE;
	            }
	            pad_data[0] |= RIGHT_VALUE;
	            right_icade = true;
	            break;
	        case KeyEvent.KEYCODE_C:
	            if(ways==4 /*&& b*/ || !b)
	            {
	               if(up_icade)pad_data[0] |= UP_VALUE;
	               if(down_icade)pad_data[0] |= DOWN_VALUE;
	            }
	            pad_data[0] &= ~RIGHT_VALUE;
	            right_icade = false;
	            break;
	            
	        // joystick left_icade
	        case KeyEvent.KEYCODE_A:            
	            if(ways==4 /*&& b*/ || !b)
	            {
	               pad_data[0] &= ~UP_VALUE;
	               pad_data[0] &= ~DOWN_VALUE;
	            }
	            pad_data[0] |= LEFT_VALUE;
	            left_icade = true;
	            break;
	        case KeyEvent.KEYCODE_Q:
	            if(ways==4 /*&& b*/ ||!b)
	            {
	               if(up_icade)pad_data[0] |= UP_VALUE;
	               if(down_icade)pad_data[0] |= DOWN_VALUE;
	            }
	            pad_data[0] &= ~LEFT_VALUE;
	            left_icade = false;
	            break;
	            
	        // Y / UP
	        case KeyEvent.KEYCODE_I:
	            pad_data[0] |= Y_VALUE;
	            break;
	        case KeyEvent.KEYCODE_M:
	            pad_data[0] &= ~Y_VALUE;
	            break;
	            
	        // X / DOWN
	        case KeyEvent.KEYCODE_L:
	            pad_data[0] |= X_VALUE;
	            break;
	        case KeyEvent.KEYCODE_V:
	            pad_data[0] &= ~X_VALUE;
	            break;
	            
	        // A / LEFT
	        case KeyEvent.KEYCODE_K:
	            pad_data[0] |= A_VALUE;
	            break;
	        case KeyEvent.KEYCODE_P:
	            pad_data[0] &= ~A_VALUE;
	            break;
	            
	        // B / RIGHT
	        case KeyEvent.KEYCODE_O:
	            pad_data[0] |= B_VALUE;
	            break;
	        case KeyEvent.KEYCODE_G:
	            pad_data[0] &= ~B_VALUE;
	            break;
	            
	        // SELECT / COIN
	        case KeyEvent.KEYCODE_Y:
	            pad_data[0] |= SELECT_VALUE;
	            break;
	        case KeyEvent.KEYCODE_T:
	            pad_data[0] &= ~SELECT_VALUE;
	            break;
	            
	        // START
	        case KeyEvent.KEYCODE_U:
	            if(bCadeLayout) { 
	                pad_data[0] |= L1_VALUE;
	            }
	            else {
	                pad_data[0] |= START_VALUE;
	            }
	            break;
	        case KeyEvent.KEYCODE_F:
	            if(bCadeLayout) { 
	                pad_data[0] &= ~L1_VALUE;
	            }
	            else {
	                pad_data[0] &= ~START_VALUE;
	            }
	            break;
	            
	        // 
	        case KeyEvent.KEYCODE_H:
	            if(bCadeLayout) { 
	                pad_data[0] |= START_VALUE;
	            }
	            else {
	                pad_data[0] |= L1_VALUE;
	            }
	            break;
	        case KeyEvent.KEYCODE_R:
	            if(bCadeLayout) { 
	                pad_data[0] &= ~START_VALUE;
	            }
	            else {
	                pad_data[0] &= ~L1_VALUE;
	            }
	            break;
	            
	        // 
	        case KeyEvent.KEYCODE_J:
	            pad_data[0] |= R1_VALUE;
	            break;
	        case KeyEvent.KEYCODE_N:
	            pad_data[0] &= ~R1_VALUE;
	            break;
	    }
		Emulator.setPadData(0,pad_data[0]);
	}
}

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

import android.view.MotionEvent;

import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.MAME4droid;
import com.seleuco.mame4droid.helpers.DialogHelper;
import com.seleuco.mame4droid.helpers.PrefsHelper;

public class InputHandlerExt extends InputHandler {
	

	protected int [] touchContrData = new int[20];
	protected InputValue [] touchKeyData = new InputValue[20];
	
	protected static int [] newtouches = new int[20];
	protected static int [] oldtouches = new int[20];
	protected static boolean [] touchstates = new boolean[20];
	
	public InputHandlerExt(MAME4droid value) {
		super(value);
	}
		
	@Override
	protected boolean handleTouchController(MotionEvent event) {

		int action = event.getAction();
		int actionEvent = action & MotionEvent.ACTION_MASK;
		
		int pid = 0;
				
        try
        {
		   int pointerIndex = (event.getAction() & MotionEvent.ACTION_POINTER_INDEX_MASK) >> MotionEvent.ACTION_POINTER_INDEX_SHIFT;
           pid = event.getPointerId(pointerIndex);
        }
        catch(Error e)
        {
            pid = (action & MotionEvent.ACTION_POINTER_ID_SHIFT) >> MotionEvent.ACTION_POINTER_ID_SHIFT;
        }    
		
		//dumpEvent(event);
		
		for (int i = 0; i < 10; i++) 
		{
		    touchstates[i] = false;
		    oldtouches[i] = newtouches[i];
		}
		
		for (int i = 0; i < event.getPointerCount(); i++) {

			int actionPointerId = event.getPointerId(i);
						
			int x = (int) event.getX(i);
			int y = (int) event.getY(i);
			
			if(actionEvent == MotionEvent.ACTION_UP 
			   || (actionEvent == MotionEvent.ACTION_POINTER_UP && actionPointerId==pid) 
			   || actionEvent == MotionEvent.ACTION_CANCEL)
			{
                //nada
			}	
			else
			{		
				//int id = i;
				int id = actionPointerId;
				if(id>touchstates.length)continue;//strange but i have this error on my development console
				touchstates[id] = true;
				//newtouches[id] = 0;
				
				for (int j = 0; j < values.size(); j++) {
					InputValue iv = values.get(j);
										
					if (iv.getRect().contains(x, y)) {
						
						//Log.d("touch","HIT "+iv.getType()+" "+iv.getRect()+ " "+iv.getOrigRect());
						
						if (iv.getType() == TYPE_BUTTON_RECT || iv.getType() == TYPE_STICK_RECT) {
						
							switch (actionEvent) {
							
							case MotionEvent.ACTION_DOWN:
							case MotionEvent.ACTION_POINTER_DOWN:
							case MotionEvent.ACTION_MOVE:
															
								if(iv.getType() == TYPE_BUTTON_RECT)
								{	
								     newtouches[id] |= getButtonValue(iv.getValue(),true);
									 if(iv.getValue()==BTN_L2 && actionEvent!=MotionEvent.ACTION_MOVE)
									 { 
									    if(Emulator.getValue(Emulator.IN_MENU)!=0)
									    {
						    		        Emulator.setValue(Emulator.EXIT_GAME_KEY, 1);		    	
					    			    	try {Thread.sleep(100);} catch (InterruptedException e) {}
					    					Emulator.setValue(Emulator.EXIT_GAME_KEY, 0);									    	
									    }										 
									    else if(!Emulator.isInMAME())
										    mm.showDialog(DialogHelper.DIALOG_EXIT);
									    else
									        mm.showDialog(DialogHelper.DIALOG_EXIT_GAME);
									 } 
									 else if(iv.getValue()==BTN_R2)
									 {
										 mm.showDialog(DialogHelper.DIALOG_OPTIONS);
									 }
								}
								else if(mm.getPrefsHelper().getControllerType() == PrefsHelper.PREF_DIGITAL_DPAD
										&& !(TiltSensor.isEnabled() && Emulator.isInMAME()))
								{
									 newtouches[id] = getStickValue(iv.getValue());
								}
					            
								if(oldtouches[id] != newtouches[id])	            
					            	pad_data[0] &= ~(oldtouches[id]);
					            
								pad_data[0] |= newtouches[id];
							}
							
							if(mm.getPrefsHelper().isBplusX() && (iv.getValue()==BTN_B || iv.getValue()==BTN_X))
							   break;
							
						}/* else if (iv.getType() == TYPE_SWITCH) {
							if (event.getAction() == MotionEvent.ACTION_DOWN) {
																
								for (int ii = 0; ii < 10; ii++) 
								{
								    touchstates[ii] = false;
								    oldtouches[ii] = 0;
								}
								changeState();
								mm.getMainHelper().updateMAME4droid();
								return true;
							}
						}*/
					}
				}	                	            
			} 
		}

		for (int i = 0; i < touchstates.length; i++) {
			if (!touchstates[i] && newtouches[i]!=0) {
				boolean really = true;

				for (int j = 0; j < 10 && really; j++) {
					if (j == i)
						continue;
					really = (newtouches[j] & newtouches[i]) == 0;//try to fix something buggy touch screens
				}

				if (really)
				{
					pad_data[0] &= ~(newtouches[i]);
				}
				
				newtouches[i] = 0;
				oldtouches[i] = 0;
			}
		}
		
		handleImageStates();
		
		Emulator.setPadData(0,pad_data[0]);
		return true;
	}
}

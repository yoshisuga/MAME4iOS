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

import android.content.res.Configuration;
import android.graphics.Canvas;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.drawable.BitmapDrawable;
import android.view.MotionEvent;

import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.MAME4droid;
import com.seleuco.mame4droid.R;
import com.seleuco.mame4droid.helpers.PrefsHelper;

public class AnalogStick implements IController{
	
	float MY_PI	= 3.14159265f;
		
	Rect rStickArea = new Rect();
	Rect stickPos = new Rect();
	
	//protected int stick_state;
	
	Point ptCur = new Point();
	
	Point ptCenter = new Point();
    Point ptMin = new Point();
    Point ptMax = new Point();
    
    int stickWidth;
    int stickHeight;
    
    float deadZone = 0.1f;

	float ang;						/**< angle the joystick is being held		*/
	float mag;						/**< magnitude of the joystick (range 0-1)	*/
	float rx, ry, oldRx, oldRy;
	
	int motion_pid = -1;
	
	static BitmapDrawable inner_img = null;
	static BitmapDrawable outer_img = null;
	static BitmapDrawable stick_images[] = null;
		
	protected MAME4droid mm = null;
	
	final public float rad2degree(float r){
	   return ((r * 180.0f) / MY_PI);
	}
	
	public void setMAME4droid(MAME4droid value) {
		mm = value;
		
		if(inner_img==null)inner_img=(BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_inner);
		if(outer_img==null)outer_img=(BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_outer);
		if(stick_images==null)
		{
			stick_images = new BitmapDrawable[9];
			stick_images[InputHandler.STICK_DOWN] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_down);
			stick_images[InputHandler.STICK_DOWN_LEFT] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_down_left);
			stick_images[InputHandler.STICK_DOWN_RIGHT] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_down_right);
			stick_images[InputHandler.STICK_LEFT] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_left);
			stick_images[InputHandler.STICK_NONE] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_none);
			stick_images[InputHandler.STICK_RIGHT] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_right);
			stick_images[InputHandler.STICK_UP] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_up);
			stick_images[InputHandler.STICK_UP_LEFT] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_up_left);
			stick_images[InputHandler.STICK_UP_RIGHT] = (BitmapDrawable)mm.getResources().getDrawable(R.drawable.stick_up_right);
		}
	}
	
	public void setStickArea(Rect rStickArea) {
		 this.rStickArea = rStickArea;
		 ptMin.x = rStickArea.left;
		 ptMin.y = rStickArea.top;
		 ptMax.x = rStickArea.right;
		 ptMax.y = rStickArea.bottom;
		 ptCenter.x = rStickArea.centerX();
		 ptCenter.y = rStickArea.centerY();
		 stickWidth =  (int)((float)rStickArea.width() * (62f/100.0f));//0.60;
		 stickHeight = (int)((float)rStickArea.height() * (62f/100.0f));//0.60; 
		 calculateStickPosition(ptCenter);
	}
	
	protected int updateAnalog(int pad_data)
	{	     
		 switch(mm.getPrefsHelper().getAnalogDZ())
	     {
	       case 0: deadZone = 0.01f;break;
	       case 1: deadZone = 0.05f;break;
	       case 2: deadZone = 0.1f;break;
	       case 3: deadZone = 0.15f;break;
	       case 4: deadZone = 0.2f;break;
	       case 5: deadZone = 0.3f;break;
	     }
	 

	 	if(mag >= deadZone)
	 	{
			int ways = mm.getPrefsHelper().getStickWays();
			boolean b = Emulator.isInMAME();
				
			if(mm.getPrefsHelper().getControllerType() != PrefsHelper.PREF_DIGITAL_STICK)
			   Emulator.setAnalogData(0,rx,ry * -1.0f);
			
	 		float v = ang;
	 		
	 		if(ways==2 && b)
	 		{
	             if ( v < 180  ){
	 				pad_data |= RIGHT_VALUE;
	                
	 				pad_data &= ~UP_VALUE;
	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~LEFT_VALUE;						
	 			}
	 			else if ( v >= 180  ){
	 				pad_data |= LEFT_VALUE;
	                
	 				pad_data &= ~UP_VALUE;
	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;
	 			}
	 		}
	 		else if(ways==4 /*&& b*/ || !b)
	 		{
	 			if( v >= 315 || v < 45){
	 				pad_data |= DOWN_VALUE;

	                pad_data &= ~UP_VALUE;					        
	 		        pad_data &= ~LEFT_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;						
	 			}
	 			else if ( v >= 45 && v < 135){
	 				pad_data |= RIGHT_VALUE;

	                pad_data &= ~UP_VALUE;
	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~LEFT_VALUE;						
	 			}
	 			else if ( v >= 135 && v < 225){
	 				pad_data |= UP_VALUE;

	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~LEFT_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;
	 			}
	 			else if ( v >= 225 && v < 315 ){
	 				pad_data |= LEFT_VALUE;

	                pad_data &= ~UP_VALUE;
	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;
	 			}						
	 		}
	        else
	        {
	 			if( v >= 330 || v < 30){
	 				pad_data |= DOWN_VALUE;

	                pad_data &= ~UP_VALUE;					        
	 		        pad_data &= ~LEFT_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;						
	 			}
	 			else if ( v >= 30 && v <60  )  {
	 				pad_data |= DOWN_VALUE;
	 				pad_data |= RIGHT_VALUE;

	                pad_data &= ~UP_VALUE;
	 		        pad_data &= ~LEFT_VALUE;						
	 			}
	 			else if ( v >= 60 && v < 120  ){
	 				pad_data |= RIGHT_VALUE;

	                pad_data &= ~UP_VALUE;
	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~LEFT_VALUE;						
	 			}
	 			else if ( v >= 120 && v < 150  ){
	 				pad_data |= RIGHT_VALUE;
	 				pad_data |= UP_VALUE;

	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~LEFT_VALUE;
	 			}
	 			else if ( v >= 150 && v < 210  ){
	 				pad_data |= UP_VALUE;

	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~LEFT_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;
	 			}
	 			else if ( v >= 210 && v < 240  ){
	 				pad_data |= UP_VALUE;
	 				pad_data |= LEFT_VALUE;

	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;						
	 			}
	 			else if ( v >= 240 && v < 300  ){
	 				pad_data |= LEFT_VALUE;

	                pad_data &= ~UP_VALUE;
	 		        pad_data &= ~DOWN_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;
	 			}
	 			else if ( v >= 300 && v < 330  ){
	 				pad_data |= LEFT_VALUE;
	 				pad_data |= DOWN_VALUE;
	 				
	                pad_data &= ~UP_VALUE;
	 		        pad_data &= ~RIGHT_VALUE;
	 			}
	 		}												
	 	}
	 	else
	 	{
	 		Emulator.setAnalogData(0,0.0f,0.0f);
	 	     
	 	    pad_data &= ~UP_VALUE;
	 	    pad_data &= ~DOWN_VALUE;
	 	    pad_data &= ~LEFT_VALUE;
	 	    pad_data &= ~RIGHT_VALUE;		    	    				    
	 	}
/*	 					
	 	switch (pad_data & (UP_VALUE|DOWN_VALUE|LEFT_VALUE|RIGHT_VALUE))
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
*/	 	
	 	return pad_data;
	}
	 
	protected void calculateStickState(Point pt, Point min, Point max, Point center)
	{
	    if(pt.x > max.x)pt.x=max.x;
	    if(pt.x < min.x)pt.x=min.x;
	    if(pt.y > max.y)pt.y=max.y;
	    if(pt.y < min.y)pt.y=min.y;

		if (pt.x == center.x)
			rx = 0;
		else if (pt.x >= center.x)
			rx = ((float)(pt.x - center.x) / (float)(max.x - center.x));
		else
			rx = ((float)(pt.x - min.x) / (float)(center.x - min.x)) - 1.0f;

		if (pt.y == center.y)
			ry = 0;
		else if (pt.y >= center.y)
			ry = ((float)(pt.y - center.y) / (float)(max.y - center.y));
		else
			ry = ((float)(pt.y - min.y) / (float)(center.y - min.y)) - 1.0f;

		/* calculate the joystick angle and magnitude */
		ang = rad2degree((float)Math.atan(ry / rx));
		ang -= 90.0f;
		if (rx < 0.0f)
			ang -= 180.0f;
		ang = Math.abs(ang);
		mag = (float) Math.sqrt((rx * rx) + (ry * ry));
		
	}
	
	protected void calculateStickPosition(Point pt) 
	{
		int ways = mm.getPrefsHelper().getStickWays();
		boolean b = Emulator.isInMAME();
		   
	    if(ways==2 && b)
	    {
	       stickPos.left=  Math.min(ptMax.x-stickWidth,Math.max(ptMin.x,pt.x - (stickWidth/2)));
	       stickPos.top =  ptCenter.y - (stickHeight/2);
	    }
	    else if(ways==4 /*&& b*/ || !b)
	    {    
	       if(mm.getInputHandler().getStick_state() == STICK_RIGHT || mm.getInputHandler().getStick_state() == STICK_LEFT)
	       {
	    	  stickPos.left =  Math.min(ptMax.x-stickWidth,Math.max(ptMin.x,pt.x - (stickWidth/2)));
	    	  stickPos.top =  ptCenter.y - (stickHeight/2);
	       }  
	       else
	       {
	    	  stickPos.left =  ptCenter.x - (stickWidth/2);
	    	  stickPos.top  =  Math.min(ptMax.y-stickHeight,Math.max(ptMin.y,pt.y - (stickHeight/2)));
	       }
	    }
	    else
	    {
	    	 stickPos.left =  Math.min(ptMax.x-stickWidth,Math.max(ptMin.x,pt.x - (stickWidth/2)));
	    	 stickPos.top =  Math.min(ptMax.y-stickHeight,Math.max(ptMin.y,pt.y - (stickHeight/2)));
	    }
	    
	    stickPos.right = stickPos.left+stickWidth;
	    stickPos.bottom = stickPos.top + stickHeight;
	}
	
	public int handleMotion(MotionEvent event, int pad_data) {
		
		int pid = 0;
		int action = event.getAction();
		int actionEvent = action & MotionEvent.ACTION_MASK;
		
        try
        {
		   int pointerIndex = (action & MotionEvent.ACTION_POINTER_INDEX_MASK) >> MotionEvent.ACTION_POINTER_INDEX_SHIFT;
           pid = event.getPointerId(pointerIndex);
        }
        catch(Error e)
        {
           pid = (action & MotionEvent.ACTION_POINTER_ID_SHIFT) >> MotionEvent.ACTION_POINTER_ID_SHIFT;
        } 
        
		if( actionEvent == MotionEvent.ACTION_UP ||
		    (actionEvent == MotionEvent.ACTION_POINTER_UP && pid == motion_pid) || 
		    actionEvent == MotionEvent.ACTION_CANCEL)
		{
		       ptCur.x = ptCenter.x;
		       ptCur.y = ptCenter.y;
		       //stick_state = STICK_NONE;
		       rx = ry = mag = 0;
		       oldRx = oldRy = -999;
		       motion_pid = -1;
		}	
		else
		{
			for (int i = 0; i < event.getPointerCount(); i++) {
	
				int  pointerId = event.getPointerId(i);
				
				int x = (int) event.getX(i);
				int y = (int) event.getY(i);
							
				//if(actionEvent == MotionEvent.ACTION_DOWN || (actionEvent == MotionEvent.ACTION_POINTER_DOWN && pointerId==pid)) 
				//{
					if(rStickArea.contains(x, y) /*&& motion_pid==-1*/)
					{
						motion_pid = pointerId;
					}
				//}
						
				if(motion_pid == pointerId)
				{					
					ptCur.x = x;
					ptCur.y = y;
					calculateStickState(ptCur,ptMin,ptMax,ptCenter);
				}
			}
		}
	   
		//if(motion_pid!=-1)
		   pad_data = updateAnalog(pad_data);
		   
		double inc = mm.getPrefsHelper().isDebugEnabled() ? 0.01 : 0.08;   
	    
	    if((Math.abs(oldRx - rx) >= inc || Math.abs(oldRy - ry) >= inc) && mm.getPrefsHelper().isAnimatedInput() )
	    {
	      oldRx = rx;
	      oldRy = ry;
	      
	      calculateStickPosition((mag >= deadZone ? ptCur : ptCenter));      
	      
	      if(mm.getPrefsHelper().getControllerType() == PrefsHelper.PREF_ANALOG_PRETTY)
	      {
		      if(Emulator.isDebug())
		    	mm.getInputView().invalidate();
		      else
		        mm.getInputView().invalidate(rStickArea);
	      }
	    }  
	    
		return pad_data;
	}
	
	public void draw(Canvas canvas) {
		
		if( mm.getPrefsHelper().getControllerType() == PrefsHelper.PREF_ANALOG_PRETTY)
		{
			if(mm.getMainHelper().getscrOrientation() == Configuration.ORIENTATION_LANDSCAPE)
			{
				outer_img.setBounds(rStickArea);
				outer_img.setAlpha(mm.getInputHandler().getOpacity());
				outer_img.draw(canvas);
			}
			inner_img.setBounds(stickPos);
			inner_img.setAlpha(mm.getInputHandler().getOpacity());
			inner_img.draw(canvas);
		}
		else if( mm.getPrefsHelper().getControllerType() == PrefsHelper.PREF_ANALOG_FAST || mm.getPrefsHelper().getControllerType() == PrefsHelper.PREF_DIGITAL_STICK)
		{
			stick_images[mm.getInputHandler().getStick_state()].setBounds(rStickArea);
			stick_images[mm.getInputHandler().getStick_state()].setAlpha(mm.getInputHandler().getOpacity());
			stick_images[mm.getInputHandler().getStick_state()].draw(canvas);
		}
		
        if(Emulator.isDebug())
        {
			canvas.drawText("x="+ptCur.x+" y="+ptCur.y+" state="+mm.getInputHandler().getStick_state()+" rx="+rx+" ry="+ry+" ang="+ang+" mag="+mag, 5,  50, Emulator.getDebugPaint());
        }	
	}	
	
}

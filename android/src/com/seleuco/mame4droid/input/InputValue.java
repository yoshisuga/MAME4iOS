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

import com.seleuco.mame4droid.MAME4droid;

import android.graphics.Rect;


public class InputValue {
	
	private int type;
	private int value;
	
	private int o_x1;
	private int o_y1;
	private int o_x2;
	private int o_y2;
	
	private float dx = 1;
	private float dy = 1;
	private int ax = 0;
	private int ay = 0;
	
	private int xoff_tmp = 0;
	private int yoff_tmp = 0;

	private int xoff = 0;
	private int yoff = 0;
	
	private int sz_x1;
	private int sz_y1;
	private int sz_x2;
	private int sz_y2;
	
	private Rect rect = null;
	
	private Rect origRect = null;    
	
	private MAME4droid mm = null;
	    
    public InputValue(int d[], MAME4droid mm){
       this.mm = mm;
       //data = d;
       type = d[0];
       value = d[1];
       
       if(type == InputHandler.TYPE_STICK_RECT && mm.getPrefsHelper().isTouchDZ())
       {
    	   if(value == InputHandler.STICK_LEFT)
    	   {
    		   d[4] -= d[4] * 0.18f;
    	   }
    	   if(value == InputHandler.STICK_RIGHT)
    	   {		    	    		   
    		   d[2] += d[4] * 0.18f;
    		   d[4] -= (d[4] * 0.18f);
    	   }		    	    	   		    	    		  
       }
       
       o_x1 = d[2];
       o_y1 = d[3];
       o_x2 = o_x1 + d[4];
       o_y2 = o_y1 + d[5];       
    }
  
    public void setFixData(float dx, float dy, int ax, int ay)
    {
    	this.dx = dx;
    	this.dy = dy;
    	this.ax = ax;
    	this.ay = ay;
    	rect = null;
    }
    
    public void setSize(int sz_x1,int sz_y1, int sz_x2, int sz_y2)
    {
    	this.sz_x1 = sz_x1;
    	this.sz_x2 = sz_x2;
    	this.sz_y1 = sz_y1;
    	this.sz_y2 = sz_y2;
        rect = null;
    }
    
    public void setOffset(int xoff,int yoff)
    {
    	this.xoff = xoff;
    	this.yoff = yoff;
    	xoff_tmp = 0;
    	yoff_tmp = 0;
    	rect = null;
    }
    
    public void setOffsetTMP(int xoff_tmp,int yoff_tmp)
    {
    	this.xoff_tmp = xoff_tmp;
    	this.yoff_tmp = yoff_tmp;
    	rect = null;
    }
    
    public void commitChanges()
    {
    	xoff += xoff_tmp;
    	yoff += yoff_tmp;
    	xoff_tmp=0;
    	yoff_tmp=0;
    }
    
    public Rect getRect()
    {	
    	if(rect==null)
    	{
    		 rect = 
    			 new Rect( (int)(o_x1 * dx) + (int)(ax * 1) + xoff + xoff_tmp  + (int)(sz_x1*dx), 
    					   (int)(o_y1 * dy) + (int)(ay * 1) + yoff + yoff_tmp  + (int)(sz_y1*dy), 
    					   (int)(o_x2 * dx ) + (int)(ax * 1) + xoff + xoff_tmp + (int)(sz_x2*dx),
    					   (int)(o_y2 * dy ) + (int)(ay * 1) + yoff + yoff_tmp + (int)(sz_y2*dy) 
    					 ); 
    	}
    	return rect;
    }
       
    protected Rect getOrigRect()
    {
    	if(origRect==null)
    	{
    		 origRect =  new Rect( o_x1, o_y1, o_x2, o_y2); 
    	}
    	return origRect;
    }
    
    
    public int getType(){
    	return type;
    }
    
    public int  getValue(){
    	return value;
    }
    
	public int getXoff_tmp() {
		return xoff_tmp;
	}

	public int getYoff_tmp() {
		return yoff_tmp;
	}
	
	public int getXoff() {
		return xoff;
	}

	public int getYoff() {
		return yoff;
	}
}
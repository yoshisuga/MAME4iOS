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

//http://code.google.com/p/andengine/source/diff?spec=svn029966d918208057cef0cffcb84d0e32c3beb646&r=029966d918208057cef0cffcb84d0e32c3beb646&format=side&path=/src/org/anddev/andengine/sensor/orientation/OrientationData.java

//NOTAS: usar acelerometro es suficiente, 

package com.seleuco.mame4droid.input;

import java.text.DecimalFormat;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.view.Surface;

import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.MAME4droid;

public class TiltSensor {
	
	
    DecimalFormat df = new DecimalFormat("000.00");
	
	protected MAME4droid mm = null;
	
	public void setMAME4droid(MAME4droid value) {
		mm = value;
	}
	
	public static String str;
	
	public static float rx = 0;
	
    private float tilt;
    private float ang;
    
    static private boolean enabled = false;
            
	static public boolean isEnabled() {
		return enabled;
	}

	// Change this to make the sensors respond quicker, or slower:
    private static final int delay = SensorManager.SENSOR_DELAY_GAME;
    
    public TiltSensor() {
   
    }
    
    public void enable(){
    	
    	if(!enabled){
            if(mm==null)
            	return;
            if(!mm.getPrefsHelper().isTiltSensor())
            	return;
    	    SensorManager man = (SensorManager) mm.getApplicationContext().getSystemService(Context.SENSOR_SERVICE);             
            Sensor acc_sensor = man.getDefaultSensor(Sensor.TYPE_ACCELEROMETER); 
    	    enabled = man.registerListener(listen, acc_sensor, delay);  
    	}
    	
    }
    
    public void disable(){
    	if(enabled){
    		SensorManager man = (SensorManager) mm.getApplicationContext().getSystemService(Context.SENSOR_SERVICE);
    		man.unregisterListener(listen);
    		enabled = false;
    	}    	
    }
    
    int old = 0;
    
    // Special class used to handle sensor events:
    private final SensorEventListener listen = new SensorEventListener() {
        public void onSensorChanged(SensorEvent e) {
        	
        	final float alpha = 0.1f;
        	//final float alpha = 0.3f;       	
        	float value = - e.values[0]; 
        		
        	try{
               int r = mm.getWindowManager().getDefaultDisplay().getRotation();
               
           	   if(r == Surface.ROTATION_0)
        		  value = - e.values[0];
        	   else if(r == Surface.ROTATION_90)
        		  value =   e.values[1];
        	   else if (r == Surface.ROTATION_180)
        		  value =   e.values[0];
        	   else
        		  value = - e.values[1];        
        	}catch(Error ee){};
        	
        	tilt = alpha * tilt + (1 - alpha) * value;

        	float deadZone = getDZ();
        	             
        	if(Emulator.isInMAME()  )
        	{        		
        		if(Math.abs(tilt) < deadZone)
        		{
        			mm.getInputHandler().pad_data[0] &= ~InputHandler.LEFT_VALUE;
        			mm.getInputHandler().pad_data[0] &= ~InputHandler.RIGHT_VALUE;
        			old=0;
        		}
        		else if (tilt < 0)
        		{
        			mm.getInputHandler().pad_data[0] |= InputHandler.LEFT_VALUE;
        			mm.getInputHandler().pad_data[0] &= ~InputHandler.RIGHT_VALUE;
        			old=1;
        		}
        		else
        		{
        			mm.getInputHandler().pad_data[0] &= ~InputHandler.LEFT_VALUE;
        			mm.getInputHandler().pad_data[0] |= InputHandler.RIGHT_VALUE;
        			old=2;
        		}
        		
        		Emulator.setPadData(0, mm.getInputHandler().pad_data[0]);
        		mm.getInputHandler().handleImageStates();
        	}
        	else if(old!=0)
        	{
    			mm.getInputHandler().pad_data[0] &= ~InputHandler.LEFT_VALUE;
    			mm.getInputHandler().pad_data[0] &= ~InputHandler.RIGHT_VALUE;
        		old=0;
        		Emulator.setPadData(0, mm.getInputHandler().pad_data[0]);
        		mm.getInputHandler().handleImageStates();
        	}
        	        	
        	if(Math.abs(tilt) >=deadZone)
        	{
        		rx = ((float)(tilt - 0) / (float)(getSensitivity() - 0)); 
        		if(rx>1.0f)rx=1.0f;
        		if(rx<-1.0f)rx=-1.0f;
        	}
        	else
        	{
        		rx = 0;
        	}
        	Emulator.setAnalogData(0,rx,0);

        	if(Emulator.isDebug())
        	{	
            	ang = (float) Math.toDegrees(Math.atan( 9.81f / tilt) * 2);
            	ang = ang < 0 ? -(ang + 180) : 180 - ang;
                str = df.format(rx) + " "+ df.format(tilt)+" " +df.format(ang)+ " "+ getDZ()+ " "+ getSensitivity()+ " "+mm.getInputHandler().pad_data[0];
        		mm.getInputView().invalidate();
        	}    
        }
        
        public void onAccuracyChanged(Sensor event, int res) {}
    };

    protected float getDZ(){
    	float v = 0;
		switch(mm.getPrefsHelper().getTiltDZ())
        {
          case 1: v = 0.0f;break;
          case 2: v = 0.1f;break;
          case 3: v = 0.25f;break;
          case 4: v = 0.5f;break;
          case 5: v = 1.5f;break;
        }
		return v;
    }
    
    protected float getSensitivity(){
    	float v = 0;
		switch(mm.getPrefsHelper().getTiltSensitivity())
        {
          case 10: v = 1.0f;break;
          case 9: v = 1.5f;break;
          case 8: v = 2.0f;break;
          case 7: v = 2.5f;break;
          case 6: v = 3.0f;break;
          case 5: v = 3.5f;break;
          case 4: v = 4.0f;break;
          case 3: v = 4.5f;break;
          case 2: v = 5.0f;break;
          case 1: v = 5.5f;break;          
        }
		return v;
    }            
}

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

package com.seleuco.mame4droid.helpers;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import android.content.Intent;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Environment;
import android.view.Display;
import android.view.View;
import android.view.View.MeasureSpec;
import android.widget.FrameLayout.LayoutParams;

import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.HelpActivity;
import com.seleuco.mame4droid.MAME4droid;
import com.seleuco.mame4droid.R;
import com.seleuco.mame4droid.input.ControlCustomizer;
import com.seleuco.mame4droid.input.InputHandler;
import com.seleuco.mame4droid.prefs.UserPreferences;
import com.seleuco.mame4droid.views.FilterView;
import com.seleuco.mame4droid.views.IEmuView;
import com.seleuco.mame4droid.views.InputView;

public class MainHelper {
	
	final static public  int SUBACTIVITY_USER_PREFS = 1;
	final static public  int SUBACTIVITY_HELP = 2;
	final static public  int BUFFER_SIZE = 1024*48;
	
	final static public  String MAGIC_FILE = "dont-delete-00001.bin";
	final static public  String MAGIC_FILE_2 = "dont-delete-00002.bin";
	
	protected MAME4droid mm = null;
	
	public MainHelper(MAME4droid value){
		mm = value;
	}
	
	public String getLibDir(){	
		String cache_dir, lib_dir;
		try {
			cache_dir = mm.getCacheDir().getCanonicalPath();				
			lib_dir = cache_dir.replace("cache", "lib");
		} catch (Exception e) {
			e.printStackTrace();
			lib_dir = "/data/data/com.seleuco.mame4droid/lib";
		}
		return lib_dir;
	}
	

	public String getDefaultROMsDIR()
	{
		String res_dir = null;
				
		try {
			res_dir = Environment.getExternalStorageDirectory().getCanonicalPath()+"/ROMs/MAME4droid/";
		} catch (IOException e) {
			
			e.printStackTrace();
			res_dir = "/sdcard/ROMs/MAME4droid/";
		}
	
		return res_dir;
	}

	
	public boolean ensureROMsDir(String roms_dir){
				
		File res_dir = new File(roms_dir);
		
		boolean created = false;
		
		if(res_dir.exists() == false)
		{
			if(!res_dir.mkdirs())
			{
				mm.getDialogHelper().setErrorMsg("Can't find/create:\n '"+roms_dir+"'\nIs it writeable?");
				mm.showDialog(DialogHelper.DIALOG_ERROR_WRITING);
				return false;				
			}
			else
			{
               created= true;
			}
		}
		
		String str_sav_dir = roms_dir+"saves/";
		File sav_dir = new File(str_sav_dir);
		if(sav_dir.exists() == false)
		{
			
			if(!sav_dir.mkdirs())
			{
				mm.getDialogHelper().setErrorMsg("Can't find/create:\n'"+str_sav_dir+"'\nIs it writeable");
				mm.showDialog(DialogHelper.DIALOG_ERROR_WRITING);
				return false;				
			}
		}
		
		if(created )
		{			
			mm.getDialogHelper().setInfoMsg("Created: \n'"+roms_dir+"'\nCopy or move your zipped ROMs under './MAME4droid/roms' directory!.\n\nMAME4droid Reloaded uses only 0.139 MAME romset.");
			mm.showDialog(DialogHelper.DIALOG_INFO);
		}

	    try
		{
				
			File fm = new File(roms_dir + File.separator + "saves/" + MAGIC_FILE_2);
			if(!fm.exists())
			{
			   fm.createNewFile();
			   if(!created)
			   {
			      mm.getDialogHelper().setInfoMsg("Warning . MAME4droid Reloaded has been updated to MAME 0.139. Update your romset to 0.139 as well.");
				  mm.showDialog(DialogHelper.DIALOG_INFO);			      
			   }
			}   
		} catch (Exception e) {
				e.printStackTrace();
		}
						
		return true;		
	}
		
	public void copyFiles(){
		
		try {
			
			String roms_dir = mm.getPrefsHelper().getROMsDIR();
			
			File fm = new File(roms_dir + File.separator + "saves/" + MAGIC_FILE);
			if(fm.exists())
				return;
			
			fm.createNewFile();
			
			// Create a ZipInputStream to read the zip file
			BufferedOutputStream dest = null;
			InputStream fis = mm.getResources().openRawResource(R.raw.files);
			ZipInputStream zis = new ZipInputStream(

			new BufferedInputStream(fis));
			// Loop over all of the entries in the zip file
			int count;
			byte data[] = new byte[BUFFER_SIZE];
			ZipEntry entry;
			while ((entry = zis.getNextEntry()) != null) {
				if (!entry.isDirectory()) {

					String destination = roms_dir;
					String destFN = destination + File.separator + entry.getName();
					// Write the file to the file system
					FileOutputStream fos = new FileOutputStream(destFN);
					dest = new BufferedOutputStream(fos, BUFFER_SIZE);
					while ((count = zis.read(data, 0, BUFFER_SIZE)) != -1) {
						dest.write(data, 0, count);
					}
					dest.flush();
					dest.close();
				}
				else
				{
					File f = new File(roms_dir+ File.separator + entry.getName());
					f.mkdirs();
				}
				
			}
			zis.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	public int getscrOrientation() {
		Display getOrient = mm.getWindowManager().getDefaultDisplay();
		//int orientation = getOrient.getOrientation();
		
		int orientation  = mm.getResources().getConfiguration().orientation;


		// Sometimes you may get undefined orientation Value is 0
		// simple logic solves the problem compare the screen
		// X,Y Co-ordinates and determine the Orientation in such cases
		if (orientation == Configuration.ORIENTATION_UNDEFINED) {

			Configuration config = mm.getResources().getConfiguration();
			orientation = config.orientation;

			if (orientation == Configuration.ORIENTATION_UNDEFINED) {
				// if emu_height and widht of screen are equal then
				// it is square orientation
				if (getOrient.getWidth() == getOrient.getHeight()) {
					orientation = Configuration.ORIENTATION_SQUARE;
				} else { // if widht is less than emu_height than it is portrait
					if (getOrient.getWidth() < getOrient.getHeight()) {
						orientation = Configuration.ORIENTATION_PORTRAIT;
					} else { // if it is not any of the above it will defineitly
								// be landscape
						orientation = Configuration.ORIENTATION_LANDSCAPE;
					}
				}
			}
		}
		return orientation; // return values 1 is portrait and 2 is Landscape
							// Mode
	}
	
	public void reload() {

	    Intent intent = mm.getIntent();

	    mm.overridePendingTransition(0, 0);
	    intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
	    mm.finish();

	    mm.overridePendingTransition(0, 0);
	    mm.startActivity(intent);
	}
	
	public boolean updateOverlayFilter(){
		
        int type = -1;        
        
        if(getscrOrientation() == Configuration.ORIENTATION_PORTRAIT)
        	type = mm.getPrefsHelper().getPortraitOverlayFilterType();
        else
        	type = mm.getPrefsHelper().getLandscapeOverlayFilterType();
					
		if(Emulator.getOverlayFilterType() != type)
		{
			Emulator.setOverlayFilterType(type);
			reload();				
			return true;
		}
		else
		{
			Emulator.setOverlayFilterType(type);
		    return false;
		}    					
	}

	public boolean updateVideoRender (){
		
		if(Emulator.getVideoRenderMode() != mm.getPrefsHelper().getVideoRenderMode())
		{
			Emulator.setVideoRenderMode(mm.getPrefsHelper().getVideoRenderMode());
			reload();				
			return true;
		}
		else
		{
		    Emulator.setVideoRenderMode(mm.getPrefsHelper().getVideoRenderMode());
		    return false;
		}    					
    }
	
	public void setBorder(){
		
		int size = mm.getResources().getConfiguration().screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK; 
		
		if((size  == Configuration.SCREENLAYOUT_SIZE_LARGE || size  == Configuration.SCREENLAYOUT_SIZE_XLARGE) 
			&& mm.getMainHelper().getscrOrientation() == Configuration.ORIENTATION_PORTRAIT)
			{
		        LayoutParams lp  = (LayoutParams) mm.getEmuView().getLayoutParams();
				View v =  mm.findViewById(R.id.EmulatorFrame);
				LayoutParams lp2 = null;
				if(mm.getFilterView()!=null)
                   lp2 = (LayoutParams)mm.getFilterView().getLayoutParams();
			    if(mm.getPrefsHelper().isPortraitTouchController())
			    {					
			       v.setBackgroundDrawable(mm.getResources().getDrawable(R.drawable.border));
			       lp.setMargins(15, 15, 15, 15);
			       if(lp2!=null)
			    	 lp2.setMargins(15, 15, 15, 15);
			    }   
			    else
			    {
			    	v.setBackgroundDrawable(null);
			    	v.setBackgroundColor(R.color.emu_back_color);
			    	lp.setMargins(0, 0, 0, 0);
				    if(lp2!=null)
					  lp2.setMargins(0, 0, 0, 0);
			    }			    
			}		   	
	}
	
	
	public void updateMAME4droid(){
		
		if(updateVideoRender())return;
		if(updateOverlayFilter())return;
		
		View emuView =  mm.getEmuView();
		FilterView filterView = mm.getFilterView();

		InputView inputView =  mm.getInputView();
		InputHandler inputHandler = mm.getInputHandler();
		PrefsHelper prefsHelper = mm.getPrefsHelper();
		
		String definedKeys = prefsHelper.getDefinedKeys();
		final String[] keys = definedKeys.split(":");
		for(int i=0;i<keys.length;i++)
			InputHandler.keyMapping[i]=Integer.valueOf(keys[i]).intValue();
		
		Emulator.setValue(Emulator.FPS_SHOWED_KEY, prefsHelper.isFPSShowed() ? 1 : 0);
		Emulator.setValue(Emulator.INFOWARN_KEY, prefsHelper.isShowInfoWarnings() ? 1 : 0);
		Emulator.setDebug(prefsHelper.isDebugEnabled());
		Emulator.setValue(Emulator.IDLE_WAIT,prefsHelper.isIdleWait() ? 1 : 0);		
		Emulator.setThreadedSound(!prefsHelper.isSoundSync());
		
		Emulator.setValue(Emulator.THROTTLE,prefsHelper.isThrottle() ? 1 : 0);
		Emulator.setValue(Emulator.AUTOSAVE,prefsHelper.isAutosave() ? 1 : 0);
		Emulator.setValue(Emulator.CHEAT,prefsHelper.isCheat() ? 1 : 0);
		Emulator.setValue(Emulator.SOUND_VALUE,prefsHelper.getSoundValue());
		Emulator.setValue(Emulator.FRAME_SKIP_VALUE,prefsHelper.getFrameSkipValue());

		Emulator.setValue(Emulator.EMU_RESOLUTION,prefsHelper.getEmulatedResolution());
		Emulator.setValue(Emulator.FORCE_PXASPECT,prefsHelper.isForcedPixelAspect() ? 1 : 0);
		
		Emulator.setValue(Emulator.DOUBLE_BUFFER,mm.getPrefsHelper().isDoubleBuffer() ? 1 : 0);
		Emulator.setValue(Emulator.PXASP1,mm.getPrefsHelper().isPlayerXasPlayer1() ? 1 : 0);
		
		setBorder();
		
	    if(prefsHelper.isTiltSensor())
	    	inputHandler.getTiltSensor().enable();
	    else
	    	inputHandler.getTiltSensor().disable();
					
		inputHandler.setTrackballSensitivity( prefsHelper.getTrackballSensitivity());
		inputHandler.setTrackballEnabled(!prefsHelper.isTrackballNoMove());
				
		int state = mm.getInputHandler().getInputHandlerState();
		
		if(this.getscrOrientation() == Configuration.ORIENTATION_PORTRAIT)
		{
				        
			((IEmuView)emuView).setScaleType(prefsHelper.getPortraitScaleMode());
			if(filterView!=null)
			   filterView.setScaleType(mm.getPrefsHelper().getPortraitScaleMode());

			Emulator.setFrameFiltering(prefsHelper.isPortraitBitmapFiltering());
			
			if(state == InputHandler.STATE_SHOWING_CONTROLLER && !prefsHelper.isPortraitTouchController())
				inputHandler.changeState();
				
			if(state == InputHandler.STATE_SHOWING_NONE && prefsHelper.isPortraitTouchController())
			    inputHandler.changeState();	
			
			state = mm.getInputHandler().getInputHandlerState();
			
			if(state == InputHandler.STATE_SHOWING_NONE)
			{	
				inputView.setVisibility(View.GONE);
			}	
			else
			{	
			    inputView.setVisibility(View.VISIBLE);
			}   

			if(state == InputHandler.STATE_SHOWING_CONTROLLER)
			{			    	
			   	inputView.setImageDrawable(mm.getResources().getDrawable(R.drawable.back_portrait));				
			   	inputHandler.readControllerValues(R.raw.controller_portrait);
			}
			else
			{
				
			}
			
			if(ControlCustomizer.isEnabled() )
			{
				ControlCustomizer.setEnabled(false);
				mm.getDialogHelper().setInfoMsg("Control layout customization is only allowed in landscape mode");
				mm.showDialog(DialogHelper.DIALOG_INFO);
			}
			
		}
		else
		{
			((IEmuView)emuView).setScaleType(mm.getPrefsHelper().getLandscapeScaleMode());
			if(filterView!=null)
			   filterView.setScaleType(mm.getPrefsHelper().getLandscapeScaleMode());
			
			Emulator.setFrameFiltering(mm.getPrefsHelper().isLandscapeBitmapFiltering());
			
			if(state == InputHandler.STATE_SHOWING_CONTROLLER && !prefsHelper.isLandscapeTouchController())
				inputHandler.changeState();
			
			if(state == InputHandler.STATE_SHOWING_NONE && prefsHelper.isLandscapeTouchController())
			    inputHandler.changeState();	
			
			state = mm.getInputHandler().getInputHandlerState();
			
		    inputView.bringToFront();
			
			if(state == InputHandler.STATE_SHOWING_NONE)
			{	
				inputView.setVisibility(View.GONE);
			}	
			else
			{	
			    inputView.setVisibility(View.VISIBLE);
			}   

			if(state == InputHandler.STATE_SHOWING_CONTROLLER)
			{			    				    		
				inputView.setImageDrawable(null);
			   	inputHandler.readControllerValues(R.raw.controller_landscape);			   	    
								
				if(ControlCustomizer.isEnabled())
				{
				   mm.getEmuView().setVisibility(View.INVISIBLE);
				   mm.getInputView().requestFocus();
				}   
			}
			else
			{
				if(ControlCustomizer.isEnabled())
				{
					ControlCustomizer.setEnabled(false);
					mm.getDialogHelper().setInfoMsg("Control layout customization is only allowed when touch controller is visible");
					mm.showDialog(DialogHelper.DIALOG_INFO);
				}
			}			
		}
		
		int op = inputHandler.getOpacity();
		if (op != -1 && (state == InputHandler.STATE_SHOWING_CONTROLLER) )
			inputView.setAlpha(op);

		inputView.requestLayout();		  				
		emuView.requestLayout();
		if(filterView!=null)
		   filterView.requestLayout();
				
		inputView.invalidate();
		emuView.invalidate();
		if(filterView!=null)
		   filterView.invalidate();				
	}
	
	public void showWeb(){		
		Intent browserIntent = new Intent("android.intent.action.VIEW",
				Uri.parse("https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=seleuco%2enicator%40gmail%2ecom&lc=US&item_name=Seleuco%20Nicator&item_number=ixxxx4all&no_note=0&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest")
                //Uri.parse("http://code.google.com/p/xpectrum/")				
				);  
		mm.startActivity(browserIntent);
	}
	
	public void showSettings(){
		Intent i = new Intent(mm, UserPreferences.class);
		mm.startActivityForResult(i, MainHelper.SUBACTIVITY_USER_PREFS);
	}
	
	public void showHelp(){
		Intent i2 = new Intent(mm, HelpActivity.class);
		mm.startActivityForResult(i2, MainHelper.SUBACTIVITY_HELP);		
	}
	
	public void activityResult(int requestCode, int resultCode, Intent data) {
		
		if(requestCode == SUBACTIVITY_USER_PREFS)
		{	
            updateMAME4droid();
		}   
	}
	
	public ArrayList<Integer> measureWindow(int widthMeasureSpec, int heightMeasureSpec, int scaleType) {
		   
		int widthSize = 1;
		int heightSize = 1;
		
	
		if (scaleType == PrefsHelper.PREF_STRETCH)// FILL ALL
		{
			widthSize = MeasureSpec.getSize(widthMeasureSpec);
			heightSize = MeasureSpec.getSize(heightMeasureSpec);
		} 
		else 
		{
			
			//int emu_w = Emulator.getEmulatedWidth();
		    //int emu_h = Emulator.getEmulatedHeight();
			int emu_w = Emulator.getEmulatedVisWidth();
		    int emu_h = Emulator.getEmulatedVisHeight();		    
		    
		    if(scaleType == PrefsHelper.PREF_15X)
		    {
		    	emu_w = (int)(emu_w * 1.5f);
		    	emu_h = (int)(emu_h * 1.5f);
		    }
		    
		    if(scaleType == PrefsHelper.PREF_20X)
		    {
		    	emu_w = emu_w * 2;
		    	emu_h = emu_h * 2;
		    }
		    
		    if(scaleType == PrefsHelper.PREF_25X)
		    {
		    	emu_w = (int)(emu_w * 2.5f);
		    	emu_h = (int)(emu_h * 2.5f);
		    }
		    
			int w = emu_w;
			int h = emu_h;

			widthSize = MeasureSpec.getSize(widthMeasureSpec);
			heightSize = MeasureSpec.getSize(heightMeasureSpec);
						
			if(heightSize==0)heightSize=1;
			if(widthSize==0)widthSize=1;

			float scale = 1.0f;

			if (scaleType == PrefsHelper.PREF_SCALE)
				scale = Math.min((float) widthSize / (float) w,
						(float) heightSize / (float) h);

			w = (int) (w * scale);
			h = (int) (h * scale);

			float desiredAspect = (float) emu_w / (float) emu_h;

			widthSize = Math.min(w, widthSize);
			heightSize = Math.min(h, heightSize);

			float actualAspect = (float) (widthSize / heightSize);

			if (Math.abs(actualAspect - desiredAspect) > 0.0000001) {

				boolean done = false;

				// Try adjusting emu_width to be proportional to emu_height
				int newWidth = (int) (desiredAspect * heightSize);

				if (newWidth <= widthSize) {
					widthSize = newWidth;
					done = true;
				}

				// Try adjusting emu_height to be proportional to emu_width
				if (!done) {
					int newHeight = (int) (widthSize / desiredAspect);
					if (newHeight <= heightSize) {
						heightSize = newHeight;
					}
				}
			}
		}
		
		ArrayList<Integer> l = new ArrayList<Integer>();
		l.add(new Integer(widthSize));
		l.add(new Integer(heightSize));
		return l;
		
	}		
}

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

package com.seleuco.mame4droid;

import android.app.Activity;
import android.app.Dialog;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Shader;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.FrameLayout;

import com.seleuco.mame4droid.helpers.DialogHelper;
import com.seleuco.mame4droid.helpers.MainHelper;
import com.seleuco.mame4droid.helpers.MenuHelper;
import com.seleuco.mame4droid.helpers.PrefsHelper;
import com.seleuco.mame4droid.input.ControlCustomizer;
import com.seleuco.mame4droid.input.InputHandler;
import com.seleuco.mame4droid.input.InputHandlerFactory;
import com.seleuco.mame4droid.views.FilterView;
import com.seleuco.mame4droid.views.IEmuView;
import com.seleuco.mame4droid.views.InputView;

import android.app.*;
import android.content.*;

final class NotificationHelper
{
        private static NotificationManager notificationManager = null;

		public static void addNotification(Context ctx, String onShow, String title, String message)
        {
                if(notificationManager == null)
                        notificationManager = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
                int icon = R.drawable.icon_sb; // TODO: don't hard-code
                long when = System.currentTimeMillis();
                Notification notification = new Notification(icon, /*onShow*/null, when);
                notification.flags |= Notification.FLAG_ONGOING_EVENT | Notification.FLAG_AUTO_CANCEL;
                CharSequence contentTitle = title;
                CharSequence contentText = message;
                Intent notificationIntent = new Intent(ctx, MAME4droid.class);
                PendingIntent contentIntent = PendingIntent.getActivity(ctx, 0, notificationIntent, 0);

                notification.setLatestEventInfo(ctx, contentTitle, contentText, contentIntent);
                notificationManager.notify(1, notification);
        }
       
        public static void removeNotification()
        {
                if(notificationManager != null)
                        notificationManager.cancel(1);
        }
}

public class MAME4droid extends Activity {

	protected View emuView = null;

	protected InputView inputView = null;
	
	protected FilterView filterView = null;
	
	protected MainHelper mainHelper = null;
	protected MenuHelper menuHelper = null;
	protected PrefsHelper prefsHelper = null;
	protected DialogHelper dialogHelper = null;
	
	protected InputHandler inputHandler = null;
	
	protected FileExplorer fileExplore = null;
	
	public FileExplorer getFileExplore() {
		return fileExplore;
	}

	public MenuHelper getMenuHelper() {
		return menuHelper;
	}
    	
    public PrefsHelper getPrefsHelper() {
		return prefsHelper;
	}
    
    public MainHelper getMainHelper() {
		return mainHelper;
	}
    
    public DialogHelper getDialogHelper() {
		return dialogHelper;
	}
    
	public View getEmuView() {
		return emuView;
	}
	
	public InputView getInputView() {
		return inputView;
	}

	public FilterView getFilterView() {
		return filterView;
	}
	
    public InputHandler getInputHandler() {
		return inputHandler;
	}

	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
		Log.d("EMULATOR", "onCreate");
        
       // getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
        
       /*
        this.getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED);
        */
        
        	
       // getWindow().requestFeature(Window.FEATURE_ACTION_BAR_OVERLAY);
        
        //para saber at runtime si es llarge
        //Configuration config = getResources().getConfiguration();
                  
        setContentView(R.layout.main);
            
        prefsHelper = new PrefsHelper(this);
        
        dialogHelper  = new DialogHelper(this);
        
        mainHelper = new MainHelper(this);
        
        fileExplore = new FileExplorer(this);
                
        menuHelper = new MenuHelper(this);
                
        //inputHandler = new InputHandler(this);
        inputHandler = InputHandlerFactory.createInputHandler(this);
                
        FrameLayout fl = (FrameLayout)this.findViewById(R.id.EmulatorFrame);
               
        if(prefsHelper.getVideoRenderMode()==PrefsHelper.PREF_RENDER_SW)
        {
        	this.getLayoutInflater().inflate(R.layout.emuview_sw, fl);
        	emuView = this.findViewById(R.id.EmulatorViewSW);
        }
        else
        {
        	this.getLayoutInflater().inflate(R.layout.emuview_gl, fl);
        	emuView = this.findViewById(R.id.EmulatorViewGL);
        }
               
        inputView = (InputView) this.findViewById(R.id.InputView);
                
        ((IEmuView)emuView).setMAME4droid(this);

        inputView.setMAME4droid(this);
        
        Emulator.setMAME4droid(this);        
         
        /*
        if(mainHelper.getscrOrientation() == Configuration.ORIENTATION_LANDSCAPE)
        {*/        
        	View frame = this.findViewById(R.id.EmulatorFrame);
	        frame.setOnTouchListener(inputHandler);        	
        //}
        
        if((prefsHelper.getPortraitOverlayFilterType()!=PrefsHelper.PREF_FILTER_NONE && mainHelper.getscrOrientation() == Configuration.ORIENTATION_PORTRAIT)
        		||
           (prefsHelper.getLandscapeOverlayFilterType()!=PrefsHelper.PREF_FILTER_NONE && mainHelper.getscrOrientation() == Configuration.ORIENTATION_LANDSCAPE))
        {	
            int type;
            
            if(mainHelper.getscrOrientation() == Configuration.ORIENTATION_PORTRAIT)
            	type = prefsHelper.getPortraitOverlayFilterType();
            else
            	type = prefsHelper.getLandscapeOverlayFilterType();
           
            int dwb_id = -1;
            
            switch(type){
	            case 2: case 3: dwb_id = R.drawable.scanline_1;break;
	            case 4: case 5: dwb_id = R.drawable.scanline_2;break;
	            case 6: case 7: dwb_id = R.drawable.crt_1;break;
	            case 8: case 9: dwb_id = R.drawable.crt_2;break;
            }	
            
            if(dwb_id!=-1)
            {
	        	getLayoutInflater().inflate(R.layout.filterview, fl);
	            filterView = (FilterView)this.findViewById(R.id.FilterView);
	            Bitmap bmp = BitmapFactory.decodeResource(getResources(),dwb_id);
	            BitmapDrawable bitmapDrawable = new BitmapDrawable(bmp);
	            bitmapDrawable.setTileModeXY(Shader.TileMode.REPEAT, Shader.TileMode.REPEAT);
	            //bitmapDrawable.setAlpha((int)((type> 3 ? 0.16f : 0.35f) *255));
	            int alpha = 0;
	            if(type==2)
	            	alpha = 130;
	            else if(type==3)
	            	alpha = 180;	            
	            else if(type==4)
	            	alpha = 100;
	            else if(type==5)
	            	alpha = 150;	            
	            else if(type==6)	            	
	            	alpha = 50;
	            else if(type==7)	            	
	            	alpha = 130;	            
	            else if(type==8)
	            	alpha = 50;
	            else if(type==9)
	            	alpha = 120;	            
	            bitmapDrawable.setAlpha(alpha);
	            filterView.setBackgroundDrawable(bitmapDrawable);
	
	            //filterView.setAlpha(type> 3 ? 0.16f : 0.35f);
	            
	            filterView.setMAME4droid(this);
            }
        }
                
        emuView.setOnKeyListener(inputHandler);
        emuView.setOnTouchListener(inputHandler);
                     
        inputView.setOnTouchListener(inputHandler);
        inputView.setOnKeyListener(inputHandler);
        
        mainHelper.updateMAME4droid();
               
        if(!Emulator.isEmulating())
        {
			if(prefsHelper.getROMsDIR()==null)
			{	            
				if(DialogHelper.savedDialog==DialogHelper.DIALOG_NONE)
				   showDialog(DialogHelper.DIALOG_ROMs_DIR);                      
			}
			else
			{
				getMainHelper().ensureROMsDir(prefsHelper.getROMsDIR());
				runMAME4droid();	
			}
        }
    }
    
    public void runMAME4droid(){  	
	    getMainHelper().copyFiles();
    	Emulator.emulate(mainHelper.getLibDir(),prefsHelper.getROMsDIR());	
    }
    
	//MENU STUFF
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {		
		
		if(menuHelper!=null)
		{
		   if(menuHelper.createOptionsMenu(menu))return true;
		}  
		
		return super.onCreateOptionsMenu(menu);
	}

	@Override
	public boolean onPrepareOptionsMenu(Menu menu) {
		if(menuHelper!=null)
		{	
		   if(menuHelper.prepareOptionsMenu(menu)) return true;
		}   
		return super.onPrepareOptionsMenu(menu); 
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		if(menuHelper!=null)
		{
		   if(menuHelper.optionsItemSelected(item))
			   return true;
		}
		return super.onOptionsItemSelected(item);
	}

	//ACTIVITY
    @Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		if(mainHelper!=null)
		   mainHelper.activityResult(requestCode, resultCode, data);
	}
	
	//LIVE CYCLE
	@Override
	protected void onResume() {
		Log.d("EMULATOR", "onResume");				
		super.onResume();
		if(prefsHelper!=null)
		   prefsHelper.resume();
				
		if(DialogHelper.savedDialog!=-1)
			showDialog(DialogHelper.savedDialog);
		else if(!ControlCustomizer.isEnabled())
		  Emulator.resume();
		
		if(inputHandler!= null)
		{
			if(inputHandler.getTiltSensor()!=null)
			   inputHandler.getTiltSensor().enable();
		}
		
		NotificationHelper.removeNotification();
		//System.out.println("OnResume");
	}
	
	@Override
	protected void onPause() {
		Log.d("EMULATOR", "onPause");
		super.onPause();
		if(prefsHelper!=null)
		   prefsHelper.pause();
		if(!ControlCustomizer.isEnabled())		
		   Emulator.pause();
		if(inputHandler!= null)
		{
			if(inputHandler.getTiltSensor()!=null)
			   inputHandler.getTiltSensor().disable();
		}	
		
		if(dialogHelper!=null)
		{
			dialogHelper.removeDialogs();
		}
		
		if(prefsHelper.isNotifyWhenSuspend())
		  NotificationHelper.addNotification(getApplicationContext(), "MAME4droid was suspended!", "MAME4droid was suspended", "Press to return to MAME4droid");
		
		//System.out.println("OnPause");
	}
	
	@Override
	protected void onStart() {
		Log.d("EMULATOR", "onStart");		
		super.onStart();
		//System.out.println("OnStart");
	}

	@Override
	protected void onStop() {
		Log.d("EMULATOR", "onStop");
		super.onStop();
		//System.out.println("OnStop");
	}

	//Dialog Stuff
	@Override
	protected Dialog onCreateDialog(int id) {

		if(dialogHelper!=null)
		{	
			Dialog d = dialogHelper.createDialog(id);
			if(d!=null)return d;
		}
		return super.onCreateDialog(id);		
	}

	@Override
	protected void onPrepareDialog(int id, Dialog dialog) {
		if(dialogHelper!=null)
		   dialogHelper.prepareDialog(id, dialog);
	}
        
}
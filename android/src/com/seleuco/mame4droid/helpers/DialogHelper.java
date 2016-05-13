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

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.view.View;

import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.MAME4droid;
import com.seleuco.mame4droid.input.ControlCustomizer;

public class DialogHelper {
	
	public static int savedDialog = DialogHelper.DIALOG_NONE;

	public final static int DIALOG_NONE = -1;
	public final static int DIALOG_EXIT = 1;
	public final static int DIALOG_ERROR_WRITING = 2;
	public final static int DIALOG_INFO = 3;
	public final static int DIALOG_EXIT_GAME = 4;
	public final static int DIALOG_OPTIONS = 5;
	public final static int DIALOG_THANKS = 6;
	public final static int DIALOG_FULLSCREEN = 7;
	public final static int DIALOG_LOAD_FILE_EXPLORER = 8;
	public final static int DIALOG_ROMs_DIR = 9;
	public final static int DIALOG_FINISH_CUSTOM_LAYOUT = 10;
	
	protected MAME4droid mm = null;
	
	static protected String errorMsg;
	static protected String infoMsg;
	
	public void setErrorMsg(String errorMsg) {
		DialogHelper.errorMsg = errorMsg;
	}

	public void setInfoMsg(String infoMsg) {
		DialogHelper.infoMsg = infoMsg;
	}
		
	public DialogHelper(MAME4droid value){
		mm = value;
	}
	
	public Dialog createDialog(int id) {
		
		if(id==DialogHelper.DIALOG_LOAD_FILE_EXPLORER)
		{	
		   return mm.getFileExplore().create();
		}	
		
	    Dialog dialog;
	    AlertDialog.Builder builder = new AlertDialog.Builder(mm);
	    switch(id) {
	    case DIALOG_FINISH_CUSTOM_LAYOUT:
	    	
	    	builder.setMessage("Do you want to save changes?")
	    	       .setCancelable(false)
	    	       .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	        	   DialogHelper.savedDialog = DIALOG_NONE;  
	    	        	   mm.removeDialog(DIALOG_FINISH_CUSTOM_LAYOUT);
	    				   ControlCustomizer.setEnabled(false);
	    				   mm.getInputHandler().getControlCustomizer().saveDefinedControlLayout();
	    				   mm.getEmuView().setVisibility(View.VISIBLE);
	    				   mm.getEmuView().requestFocus();
	    				   Emulator.resume();
	    				   mm.getInputView().invalidate();	    				   
	    	           }
	    	       })
	    	       .setNegativeButton("No", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	        	   DialogHelper.savedDialog = DIALOG_NONE;  
	    	        	   mm.removeDialog(DIALOG_FINISH_CUSTOM_LAYOUT);
	    				   ControlCustomizer.setEnabled(false);
	    				   mm.getInputHandler().getControlCustomizer().discardDefinedControlLayout();
	    				   mm.getEmuView().setVisibility(View.VISIBLE);
	    				   mm.getEmuView().requestFocus();
	    				   Emulator.resume();
	    				   mm.getInputView().invalidate();
	    	           }
	    	       });
	    	dialog = builder.create();
	        break;       
	    case DIALOG_ROMs_DIR:
	    	
	    	builder.setMessage("Do you want to use default ROMs Path? (recomended)")
	    	       .setCancelable(false)
	    	       .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	        	   DialogHelper.savedDialog = DIALOG_NONE;
	    	        	   mm.removeDialog(DIALOG_ROMs_DIR);
	    	        	   if(mm.getMainHelper().ensureROMsDir(mm.getMainHelper().getDefaultROMsDIR()))
	    	        	   {	    	        	   
	    	        	      mm.getPrefsHelper().setROMsDIR(mm.getMainHelper().getDefaultROMsDIR());
	    	        	      mm.runMAME4droid();
	    	        	   }	    	        	   
	    	           }
	    	       })
	    	       .setNegativeButton("No", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	        	   DialogHelper.savedDialog = DIALOG_NONE;	    	        	   
	    	        	   mm.removeDialog(DIALOG_ROMs_DIR);
	    	               mm.showDialog(DialogHelper.DIALOG_LOAD_FILE_EXPLORER);
	    	           }
	    	       });
	    	dialog = builder.create();
	        break;	    
	    case DIALOG_EXIT:
	    	
	    	builder.setMessage("Are you sure you want to exit?")
	    	       .setCancelable(false)
	    	       .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	                //System.exit(0);
	    	                android.os.Process.killProcess(android.os.Process.myPid());   
	    	           }
	    	       })
	    	       .setNegativeButton("No", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	                dialog.cancel();
	    	           }
	    	       });
	    	dialog = builder.create();
	        break;
	    case DIALOG_ERROR_WRITING:
	    	builder.setMessage("Error")
	    	       .setCancelable(false)
	    	       .setPositiveButton("OK", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	                //System.exit(0);
	    	               DialogHelper.savedDialog = DIALOG_NONE;
	    	               mm.removeDialog(DIALOG_ERROR_WRITING);
	    	        	   mm.showDialog(DialogHelper.DIALOG_LOAD_FILE_EXPLORER);
	    	           }
	    	       });

	    	 dialog = builder.create();
	         break;
	    case DIALOG_INFO:
	    	builder.setMessage("Info")
	    	       .setCancelable(false)
	    	       .setPositiveButton("OK", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	                DialogHelper.savedDialog = DIALOG_NONE;
	    	                Emulator.resume();
	    	                mm.removeDialog(DIALOG_INFO);
	    	           }
	    	       });

	    	 dialog = builder.create();
	         break;
	    case DIALOG_EXIT_GAME:	    	
	    	builder.setMessage("Are you sure you want to exit game?")
	    	       .setCancelable(false)
	    	       .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	                DialogHelper.savedDialog = DIALOG_NONE;
	    	                Emulator.resume();
	    		        	Emulator.setValue(Emulator.EXIT_GAME_KEY, 1);		    	
	    			    	try {
	    						Thread.sleep(100);
	    					} catch (InterruptedException e) {
	    						e.printStackTrace();
	    					}
	    					Emulator.setValue(Emulator.EXIT_GAME_KEY, 0);	    	                
	    					mm.removeDialog(DIALOG_EXIT_GAME);
	    	           }
	    	       })
	    	       .setNegativeButton("No", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	    	        	   Emulator.resume();
	    	        	   DialogHelper.savedDialog = DIALOG_NONE;
	    	        	   mm.removeDialog(DIALOG_EXIT_GAME);
	    	           }
	    	       });
	    	dialog = builder.create();
	        break;
	    case DIALOG_OPTIONS:	  
	    	
	    	final CharSequence[] items1 = {"Help","Settings", "Support", "Load State", "Save State",};	    	
	    	final CharSequence[] items2 = {"Help","Settings", "Support"};
	    	
	    	builder.setTitle("Choose an option from the menu.");
	    	builder.setCancelable(true);
	    	builder.setItems(Emulator.isInMAME() ? items1 : items2, new DialogInterface.OnClickListener() {
	    	    public void onClick(DialogInterface dialog, int item) {
	    	        switch (item){
	    	          case 0: mm.getMainHelper().showHelp();break;
	    	          case 1: mm.getMainHelper().showSettings();break;
	    	          case 2: mm.showDialog(DialogHelper.DIALOG_THANKS);break;
	    	          case 3: Emulator.setValue(Emulator.LOADSTATE, 1);Emulator.resume();break;	    	          
	    	          case 4: Emulator.setValue(Emulator.SAVESTATE, 1);Emulator.resume();break;
	    	        }
  	        	    DialogHelper.savedDialog = DIALOG_NONE;
  	        	    mm.removeDialog(DIALOG_OPTIONS);
	    	    }	    	 
	    	});
	    	builder.setOnCancelListener(new  DialogInterface.OnCancelListener() {				
				@Override
				public void onCancel(DialogInterface dialog) {
  	        	    DialogHelper.savedDialog = DIALOG_NONE;
  	        	    Emulator.resume();
  	        	    mm.removeDialog(DIALOG_OPTIONS);
				}
			});
	    	dialog = builder.create();
	        break;
	    case DIALOG_THANKS:
	    	builder.setMessage("I am releasing everything for free, in keeping with the licensing MAME terms, which is free for non-commercial use only. This is strictly something I made because I wanted to play with it and have the skills to make it so. That said, if you are thinking on ways to support my development I suggest you to check my support page of other free works for the community.")
	    	       .setCancelable(false)
	    	       .setPositiveButton("OK", new DialogInterface.OnClickListener() {
	    	           public void onClick(DialogInterface dialog, int id) {
	     	        	   DialogHelper.savedDialog = DIALOG_NONE;
	    	        	   mm.getMainHelper().showWeb();
	     	        	   mm.removeDialog(DIALOG_THANKS);
	    	           }
	    	       });

	    	 dialog = builder.create();
	         break;
	    case DIALOG_FULLSCREEN:	    	
	    	final CharSequence[] items3 = {"Options","Exit","Load State","Save State"};
	    	final CharSequence[] items4 = {"Options","Exit"};
	    	builder.setTitle("Choose an option from the menu");
	    	builder.setCancelable(true);
	    	builder.setItems(Emulator.isInMAME() ? items3 : items4, new DialogInterface.OnClickListener() {
	    	    public void onClick(DialogInterface dialog, int item) {
	    	        switch (item){
	    	          case 0: mm.showDialog(DialogHelper.DIALOG_OPTIONS);break;
	    	          case 1:	    	        	
	    	        	if(!Emulator.isInMAME())
						    mm.showDialog(DialogHelper.DIALOG_EXIT);
					    else
					        mm.showDialog(DialogHelper.DIALOG_EXIT_GAME);
                        break;
	    	          case 2: Emulator.setValue(Emulator.LOADSTATE, 1);Emulator.resume();break;
	    	          case 3: Emulator.setValue(Emulator.SAVESTATE, 1);Emulator.resume();break;	    	          
	    	        }
	    	        DialogHelper.savedDialog = DIALOG_NONE;
	    	        mm.removeDialog(DIALOG_FULLSCREEN);
	    	    }
	    	});
	    	builder.setOnCancelListener(new  DialogInterface.OnCancelListener() {				
				@Override
				public void onCancel(DialogInterface dialog) {
  	        	    DialogHelper.savedDialog = DIALOG_NONE;
  	        	    Emulator.resume();
  	        	    mm.removeDialog(DIALOG_FULLSCREEN);
				}
			});
	    	dialog = builder.create();
	        break;	         
	    default:
	        dialog = null;
	    }
	    /*
	    if(dialog!=null)
	    {
	    	dialog.setCanceledOnTouchOutside(false);
	    }*/
	    return dialog;

	}

	public void prepareDialog(int id, Dialog dialog) {
		
		if(id==DIALOG_ERROR_WRITING)
		{
			((AlertDialog)dialog).setMessage(errorMsg);
			DialogHelper.savedDialog = DIALOG_ERROR_WRITING;
		}
		else if(id==DIALOG_INFO)
		{
			((AlertDialog)dialog).setMessage(infoMsg);
	    	Emulator.pause();
	        DialogHelper.savedDialog = DIALOG_INFO;
		}
	    else if(id==DIALOG_THANKS)
		{
	    	Emulator.pause();
	        DialogHelper.savedDialog = DIALOG_THANKS;
		}		
	    else if(id==DIALOG_EXIT_GAME)
		{
	    	Emulator.pause();
	        DialogHelper.savedDialog = DIALOG_EXIT_GAME;
		}
	    else if(id==DIALOG_OPTIONS)
		{
	    	Emulator.pause();
	    	DialogHelper.savedDialog = DIALOG_OPTIONS;
		}
	    else if(id==DIALOG_FULLSCREEN)
		{
	    	Emulator.pause();
	    	DialogHelper.savedDialog = DIALOG_FULLSCREEN;
		}
	    else if(id==DIALOG_ROMs_DIR)
		{
	    	DialogHelper.savedDialog = DIALOG_ROMs_DIR;
		}
	    else if(id==DIALOG_LOAD_FILE_EXPLORER)
		{
	    	DialogHelper.savedDialog = DIALOG_LOAD_FILE_EXPLORER;
		}
	    else if(id==DIALOG_FINISH_CUSTOM_LAYOUT)
		{
	    	DialogHelper.savedDialog = DIALOG_FINISH_CUSTOM_LAYOUT;
		}	
		
	}
        
	public void removeDialogs() {
		if(savedDialog==DIALOG_FINISH_CUSTOM_LAYOUT)
		{
		    mm.removeDialog(DIALOG_FINISH_CUSTOM_LAYOUT);
			DialogHelper.savedDialog = DIALOG_NONE;  
		}
	}
	
}

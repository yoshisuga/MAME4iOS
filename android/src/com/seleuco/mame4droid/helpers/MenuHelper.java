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

import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;

import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.MAME4droid;
import com.seleuco.mame4droid.R;
import com.seleuco.mame4droid.input.InputHandler;

public class MenuHelper {
	
	protected MAME4droid mm = null;
	
	public MenuHelper(MAME4droid value){
		mm = value;
	}
	
	public boolean createOptionsMenu(Menu menu) {
		
		MenuInflater inflater = mm.getMenuInflater();		
		inflater.inflate(R.menu.menu, menu);        
		
		return true;		
	}
	
	public boolean prepareOptionsMenu(Menu menu) {
		
		return true;
	}

	public boolean optionsItemSelected(MenuItem item) {
	
		switch (item.getItemId()) {

		case (R.id.menu_quit_option):
			 mm.showDialog(DialogHelper.DIALOG_EXIT);
			return true;
		case (R.id.menu_quit_game_option):
			if(Emulator.isInMAME())
			{
		       if(Emulator.getValue(Emulator.IN_MENU)==0)
				  mm.showDialog(DialogHelper.DIALOG_EXIT_GAME);
		       else
		       {
		           Emulator.setValue(Emulator.EXIT_GAME_KEY, 1);		    	
		    	   try {Thread.sleep(100);} catch (InterruptedException e) {}
				   Emulator.setValue(Emulator.EXIT_GAME_KEY, 0);
		       }
			}
			return true;			
		case R.id.menu_options_option:
			 mm.showDialog(DialogHelper.DIALOG_OPTIONS);
			return true;		
		case R.id.vkey_A:
			mm.getInputHandler().handleVirtualKey(InputHandler.A_VALUE);
			return true;
		case R.id.vkey_B:
			mm.getInputHandler().handleVirtualKey(InputHandler.B_VALUE);
			return true;
		case R.id.vkey_X:
			mm.getInputHandler().handleVirtualKey(InputHandler.X_VALUE);
			return true;
		case R.id.vkey_Y:
			mm.getInputHandler().handleVirtualKey(InputHandler.Y_VALUE);
			return true;
		case R.id.vkey_MENU:
			mm.getInputHandler().handleVirtualKey(InputHandler.START_VALUE);
			return true;
		case R.id.vkey_SELECT:
			mm.getInputHandler().handleVirtualKey(InputHandler.SELECT_VALUE);
			return true;
		}

		return false;

	}

}

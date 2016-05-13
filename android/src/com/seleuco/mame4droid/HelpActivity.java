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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import android.app.Activity;
import android.content.res.Resources.NotFoundException;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class HelpActivity extends Activity {

	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		switch(keyCode)
		{		
		    case KeyEvent.KEYCODE_BACK:		
				return true;
		    case KeyEvent.KEYCODE_HOME:		
				return true;
		}
		
		return false;
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {

		super.onCreate(savedInstanceState);
		
		setContentView(R.layout.help);
		
		final Button button = (Button) findViewById(R.id.ButtonContinue);
		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				finish();
			}
		});
		TextView v = (TextView)this.findViewById(R.id.TextView01);
		//v.setText(R.string.help);
		try {
			v.setText(this.convertStreamToString(getResources().openRawResource(R.raw.readme)));
		} catch (NotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
		}
	}
	
	public String convertStreamToString(InputStream is) throws IOException {

		if (is != null) {
			StringBuilder sb = new StringBuilder();
			String line;

			try {
				BufferedReader reader = new BufferedReader(
						new InputStreamReader(is, "UTF-8"));
				while ((line = reader.readLine()) != null) {
					sb.append(line).append("\n");
				}
			} finally {
				is.close();
			}
			return sb.toString();
		} else {
			return "";
		}
	}
}

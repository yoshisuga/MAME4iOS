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

package com.seleuco.mame4droid.prefs;


import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.widget.Button;
import android.widget.LinearLayout;


public class KeySelect extends Activity {

	protected int emulatorInputIndex;

	@Override
	public void onCreate(Bundle icicle) {
		super.onCreate(icicle);

		emulatorInputIndex = getIntent().getIntExtra("emulatorInputIndex", 0);
		setTitle("Press button for \""+ListKeys.emulatorInputLabels[emulatorInputIndex]+"\"");


		final Button chancelButton = new Button(this) {
			{
				setText("Cancel");
				setOnClickListener(new View.OnClickListener() {
					public void onClick(View v) {
						setResult(RESULT_CANCELED, new Intent());
						finish();
					}
				});
			}
		};

		final Button clearButton = new Button(this) {
			{
				setText("Clear");
				setOnClickListener(new View.OnClickListener() {
					public void onClick(View v) {
						setResult(RESULT_OK, new Intent().putExtra("androidKeyCode",  -1));
						finish();
					}
				});
			}
		};

		final View primaryView = new View(this) {
			{
				setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, 1));
				setFocusable(true);
				setFocusableInTouchMode(true);
				requestFocus();
			}
            /*
			@Override
			public boolean onKeyPreIme (int keyCode, KeyEvent event) {

				setResult(RESULT_OK, new Intent().putExtra("androidKeyCode", keyCode));
				finish();
				return true;
			}
			*/
			@Override
			public boolean onKeyDown (int keyCode, KeyEvent event) {

				setResult(RESULT_OK, new Intent().putExtra("androidKeyCode", keyCode));
				finish();
				return true;
			}
		};

		final LinearLayout parentContainer = new LinearLayout(this) {
			{
				setOrientation(LinearLayout.VERTICAL);
				addView(chancelButton);
				addView(clearButton);
				addView(primaryView);
			}
		};

		setContentView(parentContainer, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.WRAP_CONTENT));

	}

}
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

import java.nio.ByteBuffer;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.Paint.Style;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.view.SurfaceHolder;

import com.seleuco.mame4droid.helpers.PrefsHelper;
import com.seleuco.mame4droid.views.EmulatorViewGL;

public class Emulator 
{
	 
	
	final static public int FPS_SHOWED_KEY = 1;
	final static public int EXIT_GAME_KEY = 2;	
	//final static public int LAND_BUTTONS_KEY = 3;
	//final static public int HIDE_LR__KEY = 4;
	//final static public int BPLUSX_KEY = 5;
	//final static public int WAYS_STICK_KEY = 6;
	//final static public int ASMCORES_KEY = 7;
	final static public int INFOWARN_KEY = 8;
	final static public int EXIT_PAUSE = 9;
	final static public int IDLE_WAIT = 10;
	final static public int PAUSE = 11;
	final static public int FRAME_SKIP_VALUE = 12;
	final static public int SOUND_VALUE = 13;
	final static public int THROTTLE = 14;
	final static public int CHEAT = 15;
	final static public int AUTOSAVE = 16;
	final static public int SAVESTATE = 17;
	final static public int LOADSTATE = 18;
	final static public int IN_MENU = 19;
	final static public int EMU_RESOLUTION = 20;
	final static public int FORCE_PXASPECT = 21;	
	final static public int THREADED_VIDEO = 22;
	final static public int DOUBLE_BUFFER = 23;
	final static public int PXASP1 = 24;
	
    private static MAME4droid mm = null;
    
    private static boolean isEmulating = false;
    public static boolean isEmulating() {
		return isEmulating;
	}

	//private static boolean paused = false;
    private static Object lock1 = new Object();
	
	private static SurfaceHolder holder = null;
	private static Bitmap emuBitmap = Bitmap.createBitmap(320, 240, Bitmap.Config.RGB_565);
	private static ByteBuffer screenBuff = null;
	
	private static int []screenBuffPx = new int[640*480*3];	
	public  static int[] getScreenBuffPx() {
		return screenBuffPx;
	}

	private static boolean frameFiltering = false;	
	public static boolean isFrameFiltering() {
		return frameFiltering;
	}

	private static Paint emuPaint = null;
	private static Paint debugPaint = new Paint();
	
	private static Matrix mtx = new Matrix();
	
	private static int window_width = 320;
	public static int getWindow_width() {
		return window_width;
	}

	private static int window_height = 240;
	public static int getWindow_height() {
		return window_height;
	}

	private static int emu_width = 320;
	private static int emu_height = 240;
	private static int emu_vis_width = 320;
	private static int emu_vis_height = 240;
	
	private static AudioTrack audioTrack = null;
	
	private static boolean isThreadedSound  = false;
	private static boolean isDebug = false;
	private static int videoRenderMode  =  PrefsHelper.PREF_RENDER_SW;
	private static boolean inMAME = false;
	public static boolean isInMAME() {
		return inMAME;
	}
	private static int overlayFilterType  =  PrefsHelper.PREF_FILTER_NONE;
	
	public static int getOverlayFilterType() {
		return overlayFilterType;
	}

	public static void setOverlayFilterType(int overlayFilterType) {
		Emulator.overlayFilterType = overlayFilterType;
	}

	static long j = 0;
	static int i = 0;
	static int fps = 0;
	static long millis;
	
	private static SoundThread soundT = new SoundThread();
	private static Thread nativeVideoT = null;
	
	static
	{
		
		try
		{		
		    System.loadLibrary("mame4droid-jni");		  
		}
		catch(java.lang.Error e)
		{
		   e.printStackTrace();	
		}
				
	    debugPaint.setARGB(255, 255, 255, 255);
	    debugPaint.setStyle(Style.STROKE);		
	    debugPaint.setTextSize(16);
	    //videoT.start();
	}
	
	public static int getEmulatedWidth() {
		return emu_width;
	}

	public static int getEmulatedHeight() {
		return emu_height;
	}
	
	public static int getEmulatedVisWidth() {
		return emu_vis_width;
	}

	public static int getEmulatedVisHeight() {
		return emu_vis_height;
	}	
	
	public static boolean isThreadedSound() {
		return isThreadedSound;
	}

	public static void setThreadedSound(boolean isThreadedSound) {
		Emulator.isThreadedSound = isThreadedSound;
	}

	public static boolean isDebug() {
		return isDebug;
	}

	public static void setDebug(boolean isDebug) {
		Emulator.isDebug = isDebug;
	}
	
	public static int getVideoRenderMode() {
		return Emulator.videoRenderMode;
	}
	
	public static void setVideoRenderMode(int videoRenderMode) {
		Emulator.videoRenderMode = videoRenderMode;
	}

	public static Paint getEmuPaint() {
		return emuPaint;
	}
	
	public static Paint getDebugPaint() {
		return debugPaint;
	}
	
	public static Matrix getMatrix() {
		return mtx;
	}
	
	//synchronized
	public static SurfaceHolder getHolder(){
		return holder;
	}
	
	//synchronized 
	public static Bitmap getEmuBitmap(){
		return emuBitmap;
	}
	
	//synchronized 
	public static ByteBuffer getScreenBuffer(){
		return screenBuff;
	}
	
	
	public static void setHolder(SurfaceHolder value) {
		
		//Log.d("Thread Video", "Set holder nuevo "+values+" ant "+holder);
		synchronized(lock1)
		{
			if(value!=null)
			{
				holder = value;
				holder.setFormat(PixelFormat.OPAQUE);
				//holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
				holder.setKeepScreenOn(true);
				//ensureScreenDrawed();
				//Log.d("Thread Video", "Salgo start");
			}
			else
			{
				holder=null;
				//Log.d("Thread Video", "Salgo stop");
			}
		}		
	}
	
	public static Canvas lockCanvas(){
	    if(holder!=null)
		{
		    return holder.lockCanvas();	
		}
	    else 
	        return null;
	}
	
	public static void unlockCanvas(Canvas c){
	    if(holder!=null && c!=null)
		{
	       holder.unlockCanvasAndPost(c);
		}
	}
	
	public static void setMAME4droid(MAME4droid mm) {
		Emulator.mm = mm;	
	}
	
	//VIDEO
	public static void setWindowSize(int w, int h) {
		
		window_width = w;
		window_height = h;
		
		if(videoRenderMode == PrefsHelper.PREF_RENDER_GL)
			return;				

		mtx.setScale((float)(window_width / (float)emu_width), (float)(window_height / (float)emu_height));
		//mtx.setScale((float)(window_width / (float)emu_vis_width), (float)(window_height / (float)emu_vis_height));
	}

	public static void setFrameFiltering(boolean value) {
	    frameFiltering = value;			
		if(value)
		{
			emuPaint = new Paint();
			emuPaint.setFilterBitmap(true);
		}
		else
		{
			emuPaint = null;
		}
	}
	
	
	//synchronized 
	static void bitblt(ByteBuffer sScreenBuff, boolean inMAME) {

		//Log.d("Thread Video", "fuera lock");
		synchronized(lock1){
		//try {
			//Log.d("Thread Video", "dentro lock");					
			screenBuff = sScreenBuff;
			Emulator.inMAME = inMAME;
			   
			if(videoRenderMode == PrefsHelper.PREF_RENDER_GL){
				//if(mm.getEmuView() instanceof EmulatorViewGL)
				((EmulatorViewGL)mm.getEmuView()).requestRender();
			}
			else
			{		    					
				if (holder==null)
					return;
	
				Canvas canvas = holder.lockCanvas();		
				sScreenBuff.rewind();			
				emuBitmap.copyPixelsFromBuffer(sScreenBuff);												
				i++;
				canvas.concat(mtx);			
				canvas.drawBitmap(emuBitmap, 0, 0, emuPaint);
				//canvas.drawBitmap(emuBitmap, null, frameRect, emuPaint);
				if(isDebug)
				{	
					canvas.drawText("Normal fps:"+fps+ " "+inMAME, 5,  40, debugPaint);
					if(System.currentTimeMillis() - millis >= 1000) {fps = i; i=0;millis = System.currentTimeMillis();}
				}
				holder.unlockCanvasAndPost(canvas);				
			}
		/*    						
		} catch (Throwable t) {
			Log.getStackTraceString(t);
		}
		*/
		}
	}
	
	
	//synchronized 
	static public void changeVideo(int newWidth, int newHeight, int newVisWidth, int newVisHeight){	
				
		//Log.d("Thread Video", "changeVideo");
		synchronized(lock1){
		
		for(int i=0;i<4;i++)
			Emulator.setPadData(i,0);
		
		//if(emu_width!=newWidth || emu_height!=newHeight)
		//{
			emu_width = newWidth;
			emu_height = newHeight;
			emu_vis_width = newVisWidth;
			emu_vis_height = newVisHeight;
			
			emuBitmap = Bitmap.createBitmap(newWidth, newHeight, Bitmap.Config.RGB_565);
			mtx.setScale((float)(window_width / (float)emu_width), (float)(window_height / (float)emu_height));				
			
			if(videoRenderMode == PrefsHelper.PREF_RENDER_GL)
			{
				GLRenderer r = (GLRenderer)((EmulatorViewGL)mm.getEmuView()).getRender();				
				if(r!=null)r.changedEmulatedSize();	
			}
	    				
			mm.runOnUiThread(new Runnable() {
                public void run() {
                	mm.getMainHelper().updateMAME4droid();
                }
            });
		//}		  
		  }
						
		if(nativeVideoT==null)
		{
			nativeVideoT = new Thread(new Runnable(){
				public void run() {
					
					Emulator.setValue(Emulator.THREADED_VIDEO,mm.getPrefsHelper().isThreadedVideo() ? 1 : 0 );
					
					if( mm.getPrefsHelper().isThreadedVideo())					 
					   runVideoT();					
				}			
			},"emulatorNativeVideo-Thread");
			
			if(mm.getPrefsHelper().getVideoThreadPriority()==PrefsHelper.LOW)
			{	
			   nativeVideoT.setPriority(Thread.MIN_PRIORITY);
			}   
			else if(mm.getPrefsHelper().getVideoThreadPriority()==PrefsHelper.NORMAL)
			{
			   nativeVideoT.setPriority(Thread.NORM_PRIORITY);
			}   
			else
			   nativeVideoT.setPriority(Thread.MAX_PRIORITY);
			
			//nativeVideoT.setPriority(9);
			nativeVideoT.start();
		}
	}
	
	//SOUND
	static public void initAudio(int freq, boolean stereo)	
	{		
		
		int sampleFreq = freq;
		
		int channelConfig = stereo ? AudioFormat.CHANNEL_CONFIGURATION_STEREO : AudioFormat.CHANNEL_CONFIGURATION_MONO;
		int audioFormat = AudioFormat.ENCODING_PCM_16BIT;

		int bufferSize = AudioTrack.getMinBufferSize(sampleFreq, channelConfig, audioFormat);

		if(mm.getPrefsHelper().getSoundLatency()==PrefsHelper.LOW)
			bufferSize *= 1;
		else if (mm.getPrefsHelper().getSoundLatency()==PrefsHelper.NORMAL)
			bufferSize *= 2;
		else
			bufferSize *= 4;
				
		//System.out.println("Buffer Size "+bufferSize);
		
		audioTrack = new AudioTrack(AudioManager.STREAM_MUSIC,
				sampleFreq,
				channelConfig,
				audioFormat,
				bufferSize,
				AudioTrack.MODE_STREAM);
		
		audioTrack.play();				
	}
	
	public static void endAudio(){
		audioTrack.stop();
		audioTrack.release();	
		audioTrack = null;
	}
		
	public static void writeAudio(byte[] b, int sz)
	{
		//System.out.println("Envio "+sz+" "+audioTrack);
		if(audioTrack!=null)
		{
			
			if(isThreadedSound && soundT!=null)
			{
			   soundT.setAudioTrack(audioTrack);
			   soundT.writeSample(b, sz);
			}
			else
			{
			   audioTrack.write(b, 0, sz);
			}  
		}   
	}	
	
	
	//LIVE CYCLE
	public static void pause(){
		//Log.d("EMULATOR", "PAUSE");
		
		if(isEmulating)
		{		    
			//pauseEmulation(true);
			Emulator.setValue(Emulator.PAUSE, 1);
			//paused = true;
		}   
		
		if(audioTrack!=null)
		    audioTrack.pause();
	
	}
	
	public static void resume(){
		//Log.d("EMULATOR", "RESUME");
		
		if(audioTrack!=null)
		    audioTrack.play();
		
		if(isEmulating)
		{				
			Emulator.setValue(Emulator.PAUSE, 0);
			Emulator.setValue(Emulator.EXIT_PAUSE, 1);	    
		}    
	}
	
	//EMULATOR
	public static void emulate(final String libPath,final String resPath){

		//Thread.currentThread().setPriority(Thread.MAX_PRIORITY);
		
		if (isEmulating)return;
				
		Thread t = new Thread(new Runnable(){
			public void run() {
				isEmulating = true;
				init(libPath,resPath);
			}			
		},"emulatorNativeMain-Thread");
		
		
		if(mm.getPrefsHelper().getMainThreadPriority()==PrefsHelper.LOW)
		{	
		   t.setPriority(Thread.MIN_PRIORITY);
		}   
		else if(mm.getPrefsHelper().getMainThreadPriority()==PrefsHelper.NORMAL)
		{
		   t.setPriority(Thread.NORM_PRIORITY);
		}   
		else
		   t.setPriority(Thread.MAX_PRIORITY);
		
		t.start();		
	}
	
	//native
	protected static native void init(String libPath,String resPath);
	
	protected static native void runVideoT();
			
	synchronized public static native void setPadData(int i, long data);
	
	synchronized public static native void setAnalogData(int i, float v1, float v2);
	
	public static native int getValue(int key);
	
	public static native void setValue(int key, int value);
		
}

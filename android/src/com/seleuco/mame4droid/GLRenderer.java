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
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.ShortBuffer;
import java.util.Arrays;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;
import javax.microedition.khronos.opengles.GL11;
import javax.microedition.khronos.opengles.GL11Ext;

import android.opengl.GLSurfaceView.Renderer;
import android.util.Log;

public class GLRenderer implements Renderer {
    
    protected int mTex = -1;
    protected int[] mtexBuf = new int[1];    
	private final int[] mCrop;

    private final int[] mTextureName;   
    protected ShortBuffer shortBuffer = null;
    
	private FloatBuffer mFVertexBuffer;
	private FloatBuffer mTexBuffer;
	private ShortBuffer mIndexBuffer;
    
    protected boolean textureInit = false;
    protected boolean force10 = false;
   
    protected boolean smooth = false;
    
	protected MAME4droid mm = null;
    
	public void setMAME4droid(MAME4droid mm) {
		this.mm = mm;
		
		force10 = mm.getPrefsHelper().isForcedGLES10();
	}
    
    public GLRenderer()
    {
        mTextureName = new int[1];
        mCrop = new int[4];
    }

	public void changedEmulatedSize(){
        Log.v("mm","changedEmulatedSize "+shortBuffer+" "+Emulator.getScreenBuffer());
        if(Emulator.getScreenBuffer()==null)return;
        shortBuffer = Emulator.getScreenBuffer().asShortBuffer(); 
        textureInit = false;
	}
	
	private int getP2Size(int size){
		if(size<=256)
			return 256;
		else if(size<=512)
			return 512;
		else
			return 1024;
	}
	
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
    	
        Log.v("mm","onSurfaceCreated ");
        
        gl.glHint(GL10.GL_PERSPECTIVE_CORRECTION_HINT, GL10.GL_FASTEST);

        gl.glClearColor(0.5f, 0.5f, 0.5f, 1);
        gl.glClear(GL10.GL_COLOR_BUFFER_BIT | GL10.GL_DEPTH_BUFFER_BIT);
        
        gl.glShadeModel(GL10.GL_FLAT);
        gl.glEnable(GL10.GL_TEXTURE_2D);
               
        gl.glDisable(GL10.GL_DITHER);
        gl.glDisable(GL10.GL_LIGHTING);
        gl.glDisable(GL10.GL_BLEND);
        gl.glDisable(GL10.GL_CULL_FACE);        
        gl.glDisable(GL10.GL_DEPTH_TEST);
        gl.glDisable(GL10.GL_MULTISAMPLE);
                	
		if(!(gl instanceof GL11Ext) || force10)
		{
           gl.glEnableClientState(GL10.GL_VERTEX_ARRAY);
           gl.glEnableClientState(GL10.GL_TEXTURE_COORD_ARRAY);
		}  
        
        textureInit=false;
    }
       
    public void onSurfaceChanged(GL10 gl, int w, int h) {
        Log.v("mm","sizeChanged: ==> new Viewport: ["+w+","+h+"]");

        gl.glViewport(0, 0, w, h);

        gl.glMatrixMode(GL10.GL_PROJECTION);
        gl.glLoadIdentity();
        gl.glOrthof (0f, w, h, 0f, -1f,1f);

        
        gl.glFrontFace(GL10.GL_CCW);
        
        gl.glClearColor(0.5f, 0.5f, 0.5f, 1);
        gl.glClear(GL10.GL_COLOR_BUFFER_BIT | GL10.GL_DEPTH_BUFFER_BIT);
        
        textureInit=false;
    }
    
    protected boolean isSmooth(){
    	return Emulator.isFrameFiltering();
    }
    
    protected int loadTexture(final GL10 gl) {

        int textureName = -1;
        if (gl != null) {
            gl.glGenTextures(1, mTextureName, 0);

            textureName = mTextureName[0];
            gl.glBindTexture(GL10.GL_TEXTURE_2D, textureName);
            
            smooth = isSmooth();
            	
            gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_MIN_FILTER,
                    GL10.GL_NEAREST);
            gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_MAG_FILTER,
                  smooth ? GL10.GL_LINEAR : GL10.GL_NEAREST);
                  
            gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_WRAP_S,
                    GL10.GL_CLAMP_TO_EDGE);
            gl.glTexParameterf(GL10.GL_TEXTURE_2D, GL10.GL_TEXTURE_WRAP_T,
                    GL10.GL_CLAMP_TO_EDGE);

            gl.glTexEnvf(GL10.GL_TEXTURE_ENV, GL10.GL_TEXTURE_ENV_MODE,
                    GL10.GL_REPLACE);
            
            final int error = gl.glGetError();
            if (error != GL10.GL_NO_ERROR) {
                Log.e("GLRender", "Texture Load GLError: " + error);
            }
        }
        return textureName;
    }
    
	public void initVertexes(GL10 gl) {
		
		if(gl instanceof GL11Ext && !force10)
			return;
		
		int width = Emulator.getEmulatedWidth();
		int height = Emulator.getEmulatedHeight();

		ByteBuffer vbb = ByteBuffer.allocateDirect(4 * 3 * 4);
		vbb.order(ByteOrder.nativeOrder());
		mFVertexBuffer = vbb.asFloatBuffer();

		ByteBuffer tbb = ByteBuffer.allocateDirect(4 * 2 * 4);
		tbb.order(ByteOrder.nativeOrder());
		mTexBuffer = tbb.asFloatBuffer();

		ByteBuffer ibb = ByteBuffer.allocateDirect(4 * 2);
		ibb.order(ByteOrder.nativeOrder());
		mIndexBuffer = ibb.asShortBuffer();
		
		float scaleX = (float) Emulator.getWindow_width()/Emulator.getEmulatedWidth();
		float scaleY = (float) Emulator.getWindow_height()/Emulator.getEmulatedHeight();
		
		float[] coords = {
				// X, Y, Z				
				(int) ((float) width * scaleX), 0, 0,
				(int) ((float) width * scaleX),(int) ((float) height * scaleY), 0, 
				0, 0, 0, 
				0,(int) ((float) height * scaleY), 0 };
	    
        int width_p2  =  getP2Size(Emulator.getEmulatedWidth());
        int height_p2 =  getP2Size(Emulator.getEmulatedHeight());
        	
		// Texture coords
		float[] texturCoords = new float[] {

		        1f / ((float) width_p2 / width), 0f, 0,
				1f / ((float) width_p2 / width),
				1f / ((float) height_p2 / height), 0, 0f, 0f, 0, 0f,
				1f / ((float) height_p2 / height), 0 };

		for (int i = 0; i < 4; i++) {
			for (int j = 0; j < 3; j++) {
				mFVertexBuffer.put(coords[i * 3 + j]);
			}
		}

		for (int i = 0; i < 4; i++) {
			for (int j = 0; j < 2; j++) {
				mTexBuffer.put(texturCoords[i * 3 + j]);
			}
		}

		for (int i = 0; i < 4; i++) {
			mIndexBuffer.put((short) i);
		}

		mFVertexBuffer.position(0);
		mTexBuffer.position(0);
		mIndexBuffer.position(0);
	}
    
	private void releaseTexture(GL10 gl) {
		if (mTex != -1) {
			gl.glDeleteTextures(1, new int[] { mTex }, 0);
		}		
	}
	
	public void dispose(GL10 gl) {
		releaseTexture(gl);
	}
    
    public void onDrawFrame(GL10 gl) {
       // Log.v("mm","onDrawFrame called "+shortBuffer); 
    //gl.glClearColor(50, 50, 50, 1.0f);
    //gl.glClear(GL10.GL_COLOR_BUFFER_BIT | GL10.GL_DEPTH_BUFFER_BIT);
    			
    	if(shortBuffer==null){
    		ByteBuffer buf = Emulator.getScreenBuffer();
    		if(buf==null)return;
            shortBuffer = buf.asShortBuffer();
    	}
    	
    	if(mTex==-1 || smooth!=isSmooth()) 
    		mTex = loadTexture(gl);  
    	
        gl.glActiveTexture(mTex);
        gl.glClientActiveTexture(mTex);

        shortBuffer.rewind();

        gl.glBindTexture(GL10.GL_TEXTURE_2D, mTex);
        
        if(!textureInit)
        {
        	initVertexes(gl);
        	
        	ShortBuffer tmp = ShortBuffer.allocate(getP2Size(Emulator.getEmulatedWidth()) * getP2Size(Emulator.getEmulatedHeight()));        	
        	short a[] = tmp.array();
        	Arrays.fill(a, (short)0);
        	        	
        	gl.glTexImage2D(GL10.GL_TEXTURE_2D, 0,  GL10.GL_RGB,
        			getP2Size(Emulator.getEmulatedWidth()), 
        			getP2Size(Emulator.getEmulatedHeight()), 
                0,  GL10.GL_RGB,
                GL10.GL_UNSIGNED_SHORT_5_6_5 , tmp);
            textureInit = true;
        }
       
        /*
    	gl.glTexImage2D(GL10.GL_TEXTURE_2D, 0,  GL10.GL_RGB,
    			 Emulator.getEmulatedWidth(),Emulator.getEmulatedHeight(), 0,  GL10.GL_RGB,
                GL10.GL_UNSIGNED_SHORT_5_6_5, shortBuffer);
        */
        
        int width = Emulator.getEmulatedWidth();
        int height = Emulator.getEmulatedHeight();
                
		gl.glTexSubImage2D(GL11.GL_TEXTURE_2D, 0, 0, 0, width, height, GL10.GL_RGB, GL10.GL_UNSIGNED_SHORT_5_6_5, shortBuffer);
        
		if((gl instanceof GL11Ext) && !force10)
		{
	        mCrop[0] = 0; // u
	        mCrop[1] = height; // v
	        mCrop[2] = width; // w
	        mCrop[3] = -height; // h
	        
	        ((GL11) gl).glTexParameteriv(GL10.GL_TEXTURE_2D,GL11Ext.GL_TEXTURE_CROP_RECT_OES, mCrop, 0);	        	                              
	        ((GL11Ext) gl).glDrawTexiOES(0, 0, 0,Emulator.getWindow_width(),Emulator.getWindow_height());
		}
		else
		{	
			gl.glVertexPointer(3, GL10.GL_FLOAT, 0, mFVertexBuffer);
			gl.glTexCoordPointer(2, GL10.GL_FLOAT, 0, mTexBuffer);
			gl.glDrawElements(GL10.GL_TRIANGLE_STRIP, 4,
					GL10.GL_UNSIGNED_SHORT, mIndexBuffer);		    					
		}		
    }
}
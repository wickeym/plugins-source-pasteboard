//
//  copy.java
//  Pasteboard Plugin
//
//  Copyright (c) 2013 Coronalabs. All rights reserved.
//

// Package name
package plugin.pasteboard;

// Java Imports
import java.util.*;
import java.lang.*;

// Android Imports
import android.content.Intent;
import android.content.Context;
import android.net.Uri;
import android.content.pm.ResolveInfo;
import android.os.Parcelable;

// JNLua imports
import com.naef.jnlua.LuaState;
import com.naef.jnlua.LuaType;

// Corona Imports
import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeListener;
import com.ansca.corona.CoronaRuntimeTask;
import com.ansca.corona.CoronaRuntimeTaskDispatcher;
import com.ansca.corona.storage.FileContentProvider;
import com.ansca.corona.storage.FileServices;


/**
 * Implements the copy() function in Lua.
 * <p>
 * Checks whether a chooser dialog can show the specified service.
 */
public class copy implements com.naef.jnlua.NamedJavaFunction 
{
	/**
	 * Gets the name of the Lua function as it would appear in the Lua script.
	 * @return Returns the name of the custom Lua function.
	 */
	@Override
	public String getName() 
	{
		return "copy";
	}

	// Functions for API Level 11 and above
	private static class ApiLevel11
	{
		/** Constructor made private to prevent instances from being made. */
		private ApiLevel11() { }

		// Function to copy a String to the Clipboard
		public static boolean copyStringToClipboard( Context context, String text )
		{
			// If there is no text, just return
			if ( text == null )
			{
				return false;
			}

			// Setup a Clipboard manager instance
			android.content.ClipboardManager clipboardManager;
			clipboardManager = ( android.content.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );
			// Create a Clipdata object
			android.content.ClipData data = android.content.ClipData.newPlainText( text, text );
			// Set the primary clip
			clipboardManager.setPrimaryClip( data );

			return true;
		}
	}


	// Function to copy a String to the Clipboard
	private boolean copyStringToClipboard( String text )
	{
		// If there is no text, just return
		if ( text == null )
		{
			return false;
		}

		// If we have a valid context
		if ( CoronaEnvironment.getApplicationContext() != null )
		{
			// Get the application context
			Context context = CoronaEnvironment.getApplicationContext();

			// Api levels above or equal to 11
			if ( android.os.Build.VERSION.SDK_INT >= 11 )
			{
				ApiLevel11.copyStringToClipboard( context, text );
			}
			// Api's older than 11
			else
			{
				// Setup a Clipboard manager instance
				android.text.ClipboardManager clipboardManager;
				clipboardManager = ( android.text.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );
				// Set the text
				clipboardManager.setText( text );
			}
		}

		return true;
	}


	/**
	 * This method is called when the Lua function is called.
	 * <p>
	 * Warning! This method is not called on the main UI thread.
	 * @param luaState Reference to the Lua state.
	 *                 Needed to retrieve the Lua function's parameters and to return values back to Lua.
	 * @return Returns the number of values to be returned by the Lua function.
	 */
	@Override
	public int invoke( LuaState luaState ) 
	{
		try
		{
			// The type of data we want to copy to the clipboard
			String copyType = luaState.checkString( 1 );

			// If we are copying a String or Url
			if ( copyType.equalsIgnoreCase( "string" ) || copyType.equalsIgnoreCase( "url" ) )
			{
				// The string/url the user wishes to copy to the Clipboard
				final String stringToCopy = luaState.checkString( 2 );

				// Corona Activity
				CoronaActivity coronaActivity = null;
				if ( CoronaEnvironment.getCoronaActivity() != null )
				{
					coronaActivity = CoronaEnvironment.getCoronaActivity();
				}

				// Create a new runnable object to invoke our activity
				Runnable activityRunnable = new Runnable()
				{
					public void run()
					{
						// Copy the string to the clipboard
						copyStringToClipboard( stringToCopy );
					}
			    };

			    // Run the activity on the uiThread
				if ( CoronaEnvironment.getCoronaActivity() != null )
				{
					coronaActivity.runOnUiThread( activityRunnable );
				}
			}
		}
		catch( Exception ex )
		{
			// An exception will occur if given an invalid argument or no argument. Print the error.
			ex.printStackTrace();
		}
		
		return 0;
	}
}

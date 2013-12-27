//
//  clear.java
//  Pasteboard Plugin
//
//  Copyright (c) 2013 Coronalabs. All rights reserved.
//

// Package name
package plugin.pasteboard;

// Android Imports
import android.content.Context;

// JNLua imports
import com.naef.jnlua.LuaState;
import com.naef.jnlua.LuaType;

// Corona Imports
import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;

/**
 * Implements the clear() function in Lua.
 * <p>
 * Allows clearing of data on the pasteboard/clipboard.
 */
public class clear implements com.naef.jnlua.NamedJavaFunction 
{
	/**
	 * Gets the name of the Lua function as it would appear in the Lua script.
	 * @return Returns the name of the custom Lua function.
	 */
	@Override
	public String getName() 
	{
		return "clear";
	}

	// Functions for API Level 11 and above
	private static class ApiLevel11
	{
		/** Constructor made private to prevent instances from being made. */
		private ApiLevel11() { }

		// Function to clear the Clipboard
		public static boolean clearClipboard( Context context )
		{
			// Setup a Clipboard manager instance
			android.content.ClipboardManager clipboardManager;
			clipboardManager = ( android.content.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );
			// Create a Clipdata object
			android.content.ClipData data = android.content.ClipData.newPlainText( "", "" );
			// Set the primary clip
			clipboardManager.setPrimaryClip( data );

			return true;
		}
	}


	// Function to clear the Clipboard
	private boolean clearClipboard()
	{
		// If we have a valid context
		if ( CoronaEnvironment.getApplicationContext() != null )
		{
			// Get the application context
			Context context = CoronaEnvironment.getApplicationContext();

			// Api levels above or equal to 11
			if ( android.os.Build.VERSION.SDK_INT >= 11 )
			{
				ApiLevel11.clearClipboard( context );
			}
			// Api's older than 11
			else
			{
				// Setup a Clipboard manager instance
				android.text.ClipboardManager clipboardManager;
				clipboardManager = ( android.text.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );
				// Set the text
				clipboardManager.setText( "" );
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
					// Clear the clipboard
					clearClipboard();
			   	}
			};
		    
		    // Run the activity on the uiThread
		    if ( coronaActivity != null )
		    {
		    		coronaActivity.runOnUiThread( activityRunnable );
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

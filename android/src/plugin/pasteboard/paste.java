//
//  paste.java
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
public class paste implements com.naef.jnlua.NamedJavaFunction 
{
	/**
	 * Gets the name of the Lua function as it would appear in the Lua script.
	 * @return Returns the name of the custom Lua function.
	 */
	@Override
	public String getName() 
	{
		return "paste";
	}

	// Function to see if a string can be resolved to a Url
	private boolean canStringResolveToURL( String urlString )
	{
		// If there is no url, just return
		if ( urlString == null )
		{
			return false;
		}

		// The result of the operation
		boolean result = true;

		// See if we can resolve the urlString to a Url
		try 
		{
			java.net.URL url = new java.net.URL( urlString );
		}
		catch ( java.net.MalformedURLException e ) 
		{  
			result = false;
		}

		return result;
	}


	// Function to check the data type of the Clipboard object and return the type
	private String clipboardContainsDataType()
	{
		// The type of data on the clipboard, in string representation
		String dataType = "none";

		// If we have a valid context
		if ( CoronaEnvironment.getApplicationContext() != null )
		{
			// Get the application context
			Context context = CoronaEnvironment.getApplicationContext();

			// Api levels above or equal to 11
			if ( android.os.Build.VERSION.SDK_INT >= 11 )
			{
				// Setup a Clipboard manager instance
				android.content.ClipboardManager clipboardManager;
				clipboardManager = ( android.content.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );

				// If the Clipboard contains data
				if ( clipboardManager.hasPrimaryClip() )
				{
					// If we have a plain text object on the Clipboard
					if ( clipboardManager.getPrimaryClipDescription().hasMimeType( android.content.ClipDescription.MIMETYPE_TEXT_PLAIN ) )
					{
						// Clipdata item
						android.content.ClipData.Item clipDataItem = clipboardManager.getPrimaryClip().getItemAt( 0 );
						// The Clipboard string
						String clipboardContents = clipDataItem.getText().toString();

						// See if we can resolve the clipboardContents to a Url
						boolean stringCanResolveToUrl = canStringResolveToURL( clipboardContents );

						// If the string resolves to a Url
						if ( stringCanResolveToUrl )
						{
							// Set the data type
							dataType = "url";

							// Debug
							System.out.println( ">>>> There is a URL on the Clipboard <<<<" );
						}
						else
						{
							// Set the data type
							dataType = "string";

							// Debug
							System.out.println( ">>>> There is a STRING on the Clipboard <<<<" );
						}
					}
				}
			}
			// Api's older than 11
			else
			{
				// Setup a Clipboard manager instance
				android.text.ClipboardManager clipboardManager;
				clipboardManager = ( android.text.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );

				// If the Clipboard contains text (the only supported type at API level 10 and below)
				if ( clipboardManager.hasText() )
				{
					// The Clipboard string
					String clipboardContents = clipboardManager.getText().toString();

					// See if we can resolve the clipboardContents to a Url
					boolean stringCanResolveToUrl = canStringResolveToURL( clipboardContents );

					// If the string resolves to a Url
					if ( stringCanResolveToUrl )
					{
						// Set the data type
						dataType = "url";

						// Debug
						System.out.println( ">>>> There is a URL on the Clipboard <<<<" );
					}
					else
					{
						// Set the data type
						dataType = "string";

						// Debug
						System.out.println( ">>>>There is a STRING on the Clipboard <<<<" );
					}
				}
			}
		}

		// Return the data type
		return dataType;
	}


	// Functions for API Level 11 and above
	private static class ApiLevel11
	{
		/** Constructor made private to prevent instances from being made. */
		private ApiLevel11() { }

		// Function to paste a string from the Clipboard
		public static String pasteStringFromClipboard( Context context )
		{
			// The resulting string from the Clipboard
			String result = null;

			// Setup a Clipboard manager instance
			android.content.ClipboardManager clipboardManager;
			clipboardManager = ( android.content.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );
			
			// If the Clipboard contains data
			if ( clipboardManager.hasPrimaryClip() )
			{
				// If we have a plain text object on the Clipboard
				if ( clipboardManager.getPrimaryClipDescription().hasMimeType( android.content.ClipDescription.MIMETYPE_TEXT_PLAIN ) )
				{
					// Create a Clipdata item
					android.content.ClipData.Item data = clipboardManager.getPrimaryClip().getItemAt( 0 );
					// Set the result
					result = data.getText().toString();
				}
			}

			return result;
		}
	}


	// Function to paste a string from the Clipboard
	private String pasteStringFromClipboard()
	{
		// The resulting string from the Clipboard
		String result = null;

		// If we have a valid context
		if ( CoronaEnvironment.getApplicationContext() != null )
		{
			// Get the application context
			Context context = CoronaEnvironment.getApplicationContext();

			// Api levels above or equal to 11
			if ( android.os.Build.VERSION.SDK_INT >= 11 )
			{
				result = ApiLevel11.pasteStringFromClipboard( context );
			}
			// Api's older than 11
			else
			{
				// Setup a Clipboard manager instance
				android.text.ClipboardManager clipboardManager;
				clipboardManager = ( android.text.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );
				if ( clipboardManager.hasText() )
				{
					result = clipboardManager.getText().toString();
				}
			}
		}

		// Debug
		System.out.println( ">>> String on the Clipboard is: " + result + "<<<" );
		
		return result;
	}


	// Event task
	private static class LuaCallBackListenerTask implements CoronaRuntimeTask 
	{
		private int fLuaListenerRegistryId;
		private String fStringResult = null;
		private String fPasteType = null;

		public LuaCallBackListenerTask( int luaListenerRegistryId, String pasteType, String result ) 
		{
			fLuaListenerRegistryId = luaListenerRegistryId;
			fStringResult = result;
			fPasteType = pasteType;
		}

		@Override
		public void executeUsing( CoronaRuntime runtime )
		{
			try 
			{
				// Fetch the Corona runtime's Lua state.
				final LuaState L = runtime.getLuaState();

				// Dispatch the lua callback
				if ( CoronaLua.REFNIL != fLuaListenerRegistryId ) 
				{
					// Setup the event
					CoronaLua.newEvent( L, "pasteboard" );

					// Event type
					L.pushString( "paste" );
					L.setField( -2, "type" );

					// Event result
					L.pushString( fStringResult );
					L.setField( -2, fPasteType );

					// Dispatch the event
					CoronaLua.dispatchEvent( L, fLuaListenerRegistryId, 0 );
				}
			}
			catch ( Exception ex ) 
			{
				ex.printStackTrace();
			}
		}
	}

	// Our lua callback listener
	private int fListener;

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
			// If there is a listener function defined
			if ( CoronaLua.isListener( luaState, 1, "paste" ) ) 
			{
				// Assign the callback listener to a new lua ref
				fListener = CoronaLua.newRef( luaState, 1 );
			}
			else
			{
				fListener = CoronaLua.REFNIL;
			}

			// Corona Activity
			CoronaActivity coronaActivity = null;
			if ( CoronaEnvironment.getCoronaActivity() != null )
			{
				coronaActivity = CoronaEnvironment.getCoronaActivity();
			}

			// Corona runtime task dispatcher
			final CoronaRuntimeTaskDispatcher dispatcher = new CoronaRuntimeTaskDispatcher( luaState );

			// Create a new runnable object to invoke our activity
			Runnable runnableActivity = new Runnable()
			{
				public void run()
				{
					// Get type of data on the Clipboard
					String pasteType = clipboardContainsDataType();

					// If the pasteType isn't "none"
					if ( ! pasteType.equalsIgnoreCase( "none" ) )
					{
						// The string from the Clipboard
						String pasteboardString = pasteStringFromClipboard();

						// Create the task
						LuaCallBackListenerTask task = new LuaCallBackListenerTask( fListener, pasteType, pasteboardString );

						// Send the task to the Corona runtime asynchronously.
						dispatcher.send( task );
					}
				}
			};

			// Run the activity on the uiThread
			if ( coronaActivity != null )
			{
				coronaActivity.runOnUiThread( runnableActivity );
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

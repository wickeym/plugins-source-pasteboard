//
//  clipboardListener.java
//  pasteboard Plugin
//
//  Copyright (c) 2013 Coronalabs. All rights reserved.
//

// Package name
package plugin.pasteboard;

// Java Imports
import java.util.*;
import java.lang.*;

// Android Imports
import android.content.Context;

// Corona Imports
import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;


// Clipboard listener class
public class ClipboardListener
{
	// Private vars
	private Timer timer;

	// Functions for API Level 11 and above
	private static class ApiLevel11
	{
		/** Constructor made private to prevent instances from being made. */
		private ApiLevel11() { }

		// Private vars
		private static android.content.ClipboardManager clipboardManager;
		private static android.content.ClipboardManager.OnPrimaryClipChangedListener primaryClipChangedListener;

		// Function to add the clipChanged listener
		public static boolean addClipChangedListener( final Context context )
		{
			// Verify environment
			CoronaActivity coronaActivity = CoronaEnvironment.getCoronaActivity();
			if ( coronaActivity == null ) { return false; }
			
			// Create a new runnable object to invoke our activity
			Runnable activityRunnable = new Runnable()
			{
				public void run()
				{
					// Grab the initial clipboard contents and put them in pasteboard, if any.
					setNewPasteboardItem( context );

					// Clip changed listener
					primaryClipChangedListener = new android.content.ClipboardManager.OnPrimaryClipChangedListener()
					{
						public void onPrimaryClipChanged()
						{
							setNewPasteboardItem( context );
						}
					};

					// Add the clip listener
					clipboardManager.addPrimaryClipChangedListener( primaryClipChangedListener );
				}
			};

			// Run the activity on the uiThread
			coronaActivity.runOnUiThread( activityRunnable );

			return true;
		}

		// Function to remove the clipChanged listener
		public static boolean removeClipChangedListener()
		{
			// Remove the clip listener
			clipboardManager.removePrimaryClipChangedListener( primaryClipChangedListener );
			return true;
		}

		// Function to set a new pasteboard item.
		// Can be called from lua thread or UI thread.
		private static void setNewPasteboardItem( Context context ) {

			// Assign the clipboard manager
			clipboardManager = ( android.content.ClipboardManager )context.getSystemService( context.CLIPBOARD_SERVICE );

			// If the Clipboard contains data
			if ( clipboardManager.hasPrimaryClip() )
			{
				// Get the primary clip
				android.content.ClipData clipData = clipboardManager.getPrimaryClip();

				// Set the clipdata item
				android.content.ClipData.Item item = clipData.getItemAt( 0 );

				// Set the currentPasteboard item to the new text.
				shared.setCurrentPasteboardItem(shared.ApiLevel11.coerceToString(context, item));
			}
		}
	}



	// Function to add the clipboard listener
	public boolean addClipChangedListener()
	{
		// Verify environment
		Context context = CoronaEnvironment.getApplicationContext();
		if ( context == null ) { return false; }

		// Api levels above or equal to 11
		if ( android.os.Build.VERSION.SDK_INT >= 11 )
		{
			ApiLevel11.addClipChangedListener( context );
		}
		// Api's older than 11
		else
		{
			// Create a new timer
			timer = new Timer();
			// Setup a Clipboard manager instance
			final android.text.ClipboardManager clipboardManager;
			clipboardManager = ( android.text.ClipboardManager )context.getSystemService( Context.CLIPBOARD_SERVICE );
			// Set the currentPasteboard item to the new text
			shared.setCurrentPasteboardItem(clipboardManager.getText().toString());

			// Start the timer
			timer.scheduleAtFixedRate( new java.util.TimerTask()
			{
				@Override
				public void run()
				{
					// Set the currentPasteboard item to the new text
					shared.setCurrentPasteboardItem(clipboardManager.getText().toString());
				}
			}, 0, 100 );
		}

		return true;
	}

	// Function to remove the clipboard listener
	public boolean removeClipChangedListener()
	{
		// Verify environment
		Context context = CoronaEnvironment.getApplicationContext();
		if ( context == null ) { return false; }

		// Api levels above or equal to 11
		if ( android.os.Build.VERSION.SDK_INT >= 11 )
		{
			ApiLevel11.removeClipChangedListener();
		}
		// Api's older than 11
		else
		{
			timer.cancel();
		}

		return true;
	}
}

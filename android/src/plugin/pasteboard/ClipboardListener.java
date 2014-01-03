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
					clipboardManager = ( android.content.ClipboardManager )context.getSystemService( context.CLIPBOARD_SERVICE );
					
					// If the Clipboard contains data
					if ( clipboardManager.hasPrimaryClip() )
					{
						// Get the primary clip
						android.content.ClipData clipData = clipboardManager.getPrimaryClip();
								
						// Set the clipdata item
						android.content.ClipData.Item item = clipData.getItemAt( 0 );
						shared.currentPasteboardItem = item.getText().toString();
					}

					// Clip changed listener
					primaryClipChangedListener = new android.content.ClipboardManager.OnPrimaryClipChangedListener()
					{
						public void onPrimaryClipChanged()
						{
							// Assign the clipboard manager
							clipboardManager = ( android.content.ClipboardManager )context.getSystemService( context.CLIPBOARD_SERVICE );
							
							// If the Clipboard contains data
							if ( clipboardManager.hasPrimaryClip() )
							{
								// Get the primary clip
								android.content.ClipData clipData = clipboardManager.getPrimaryClip();
								
								// Set the clipdata item
								android.content.ClipData.Item item = clipData.getItemAt( 0 );

								// Set the currentPasteboard item to the new text
								shared.currentPasteboardItem = item.getText().toString();
							}
						}
					};

					// Add the clip listener
					clipboardManager.addPrimaryClipChangedListener( primaryClipChangedListener );
				}
			};

			// Run the activity on the uiThread
			if ( coronaActivity != null )
			{
				coronaActivity.runOnUiThread( activityRunnable );
			}

			return true;
		}

		// Function to remove the clipChanged listener
		public static boolean removeClipChangedListener()
		{
			// Remove the clip listener
			clipboardManager.removePrimaryClipChangedListener( primaryClipChangedListener );
			return true;
		}
	}



	// Function to add the clipboard listener
	public boolean addClipChangedListener()
	{
		// If we have a valid context
		if ( CoronaEnvironment.getApplicationContext() != null )
		{
			// Get the application context
			Context context = CoronaEnvironment.getApplicationContext();

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
				shared.currentPasteboardItem = clipboardManager.getText().toString();

				// Start the timer
				timer.scheduleAtFixedRate( new java.util.TimerTask() 
				{
					@Override
					public void run()
					{
						// Set the currentPasteboard item to the new text
						shared.currentPasteboardItem = clipboardManager.getText().toString();
					}
				}, 0, 100 );
			}
		}

		return true;
	}

	// Function to remove the clipboard listener
	public boolean removeClipChangedListener()
	{
		// If we have a valid context
		if ( CoronaEnvironment.getApplicationContext() != null )
		{
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
		}

		return true;
	}
}

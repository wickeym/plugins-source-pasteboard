//
//  shared.java
//  Pasteboard Plugin
//
//  Copyright (c) 2013 Coronalabs. All rights reserved.
//

// Package name
package plugin.pasteboard;

import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import java.lang.CharSequence;

public class shared
{
	// The types of data we can paste
	public static boolean canPasteString = true;
	public static boolean canPasteUrl = true;

	// State of pasteboard items;
	private static String previousPasteboardItem;
	private static String currentPasteboardItem;

	// Utility methods useful to the entire plugin
	public static String getCurrentPasteboardItem()
	{
		return currentPasteboardItem;
	}

	public static void setCurrentPasteboardItem( String newPasteboardItem )
	{
		// Log the previous item before setting the new one.
		previousPasteboardItem = currentPasteboardItem;
		currentPasteboardItem = newPasteboardItem;
	}


	// Functions for API Level 11 and above
	public static class ApiLevel11
	{
		/**
		 * Constructor made private to prevent instances from being made.
		 */
		private ApiLevel11() { }

		/**
		 * Turns the provided ClipData.Item into a string, regardless of the type of data it actually contains.
		 * <p>
		 * Since API Level 11 and above can put more than just strings on to the clipboard,
		 * if plain text doesn't exist on the clipboard, we use the string representation of
		 * the other possible types.
		 * <p>
		 * @param context The caller's Context, from which its ContentResolver and other things can be retrieved.
		 * @param item The ClipData.Item we want to get useful String data from.
		 * @return Returns the most useful String data contained in this ClipData.Item.
		 * <p>
		 * Priority on usefulness is as follows:
		 * - HTML-encoded text (if on API Level 16 or higher)
		 * - Plain text
		 * - Uris
		 * - Intents
		 */
		public static String coerceToString( Context context, ClipData.Item item )
		{
			String coercedClipDataItem = null;
			if ( android.os.Build.VERSION.SDK_INT >= 16 )
			{
				coercedClipDataItem = ApiLevel16.coerceToString( context, item );
			}
			else
			{
				coercedClipDataItem = item.coerceToText( context ).toString();

				// Perform any additional post-processing on the coercedClipDataItem.
				CharSequence plainText = item.getText();
				Uri uri = item.getUri();
				Intent intent = item.getIntent();

				// If empty string was found, determine if it was intentional or
				// a result of no data being found.
				if ( "".equals(coercedClipDataItem)
						&& plainText == null
						&& uri == null
						&& intent == null )
				{
					// No data found.
					coercedClipDataItem = null;
				}
				else if ( plainText == null &&
						(uri != null || intent != null) )
				{
					// The coerce function gave us an encoded URI in string form, so decode it.
					coercedClipDataItem = Uri.decode(coercedClipDataItem);
				}
			}

			if (coercedClipDataItem == null)
			{
				// Clipboard data has been corruprted somehow. Let the user know.
				Log.v("Corona", "ERROR: shared.ApiLevel11.getStringDataFromClipDataItem(): " +
						"Data from Android clipboard has been corrupted. Pasteboard will " +
						"continue using the last known valid state.");

				// Restore the last working clipboard item.
				coercedClipDataItem = previousPasteboardItem;
			}

			return coercedClipDataItem;
		}
	}

	// Functions for API Level 16 and above
	public static class ApiLevel16
	{
		/**
		 * Constructor made private to prevent instances from being made.
		 */
		private ApiLevel16() { }

		/**
		 * Turns the provided ClipData.Item into a string, regardless of the type of data it actually contains.
		 * <p>
		 * Since API Level 11 and above can put more than just strings on to the clipboard,
		 * if plain text doesn't exist on the clipboard, we use the string representation of
		 * the other possible types.
		 * <p>
		 * @param context The caller's Context, from which its ContentResolver and other things can be retrieved.
		 * @param item The ClipData.Item we want to get useful String data from.
		 * @return Returns the most useful String data contained in this ClipData.Item.
		 * <p>
		 * Priority on usefulness is as follows:
		 * - HTML-encoded text
		 * - Plain text
		 * - Uris
		 * - Intents
		 */
		public static String coerceToString( Context context, ClipData.Item item )
		{
			String coercedClipDataItem = item.coerceToStyledText( context ).toString();

			// Perform any additional post-processing on the coercedClipDataItem.
			String htmlText = item.getHtmlText();
			CharSequence plainText = item.getText();
			Uri uri = item.getUri();
			Intent intent = item.getIntent();

			// If empty string was found, determine if it was intentional or
			// a result of no data being found.
			if ( "".equals(coercedClipDataItem)
					&& htmlText == null
					&& plainText == null
					&& uri == null
					&& intent == null )
			{
				// Return null for no data found.
				return null;
			}
			else if ( htmlText == null && plainText == null
					&& (uri != null || intent != null) )
			{
				// The coerce function gave us an encoded URI in string form, so decode it.
				coercedClipDataItem = Uri.decode(coercedClipDataItem);
			}

			return coercedClipDataItem;
		}
	}
}

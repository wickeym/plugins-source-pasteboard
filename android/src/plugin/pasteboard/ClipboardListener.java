//
//  clipboardListener.java
//  pasteboard Plugin
//
//  Copyright (c) 2013 Coronalabs. All rights reserved.
//

// Package name
package plugin.pasteboard;

// Android Imports
import android.content.Context;

// Corona Imports
import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;


// Clipboard listener class
public class ClipboardListener implements android.content.ClipboardManager.OnPrimaryClipChangedListener
{
    //public  String currentPasteboardItem;

    public void onPrimaryClipChanged()
    {
        // Get the application context
        Context context = CoronaEnvironment.getApplicationContext();
        android.content.ClipboardManager clipboardManager = ( android.content.ClipboardManager )context.getSystemService( context.CLIPBOARD_SERVICE );
        android.content.ClipData clipData = clipboardManager.getPrimaryClip();
        
        // Set the clipdata item
        android.content.ClipData.Item item = clipData.getItemAt( 0 );

        // Set the currentPasteboard item to the new text
        allowedTypes.currentPasteboardItem = item.getText().toString();
    }

    // Function to Add the clipboard clipchanged listener
    public boolean addClipChangedListener( final Context context )
    {
        // Corona Activity
        CoronaActivity coronaActivity = CoronaEnvironment.getCoronaActivity();
        
        // Create a new runnable object to invoke our activity
        Runnable activityRunnable = new Runnable()
        {
            public void run()
            {
                android.content.ClipboardManager clipboardManager = ( android.content.ClipboardManager )context.getSystemService( context.CLIPBOARD_SERVICE );
                clipboardManager.addPrimaryClipChangedListener( new ClipboardListener() );
            }
        };

        // Run the activity on the uiThread
        if ( coronaActivity != null )
        {
            coronaActivity.runOnUiThread( activityRunnable );
        }

        return true;
    }
}

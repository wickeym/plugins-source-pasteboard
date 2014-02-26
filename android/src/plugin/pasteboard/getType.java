//
//  getType.java
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
 * Implements the getType() function in Lua.
 * <p>
 * Gets the type of data currently on the pasteboard/clipboard.
 */
public class getType implements com.naef.jnlua.NamedJavaFunction 
{
	/**
	 * Gets the name of the Lua function as it would appear in the Lua script.
	 * @return Returns the name of the custom Lua function.
	 */
	@Override
	public String getName() 
	{
		return "getType";
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

	/**
	 * This method is called when the Lua function is called.
	 * <p>
	 * Warning! This method is not called on the main UI thread.
	 * @param luaState Reference to the Lua state.
	 *                 Needed to retrieve the Lua function's parameters and to return values back to Lua.
	 * @return Returns the number of values to be returned by the Lua function.
	 */
	@Override
	public int invoke( final LuaState luaState ) 
	{
		final String dataType = shared.currentPasteboardItem;

		// If there is no data on the Clipboard, push nil
		if (  dataType == null || dataType.equalsIgnoreCase( "" )  )
		{
			luaState.pushNil();
		}
		// Data found, push the string
		else
		{
			if ( canStringResolveToURL( dataType ) )
			{
				luaState.pushString( "url" );
			}
			else
			{
				luaState.pushString( "string" );
			}
		}
		
		// This function returns one value
		return 1;
	}
}

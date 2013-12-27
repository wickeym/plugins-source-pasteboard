//
//  setAllowedTypes.java
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

/**
 * Implements the setAllowedTypes() function in Lua.
 * <p>
 * Sets the type of data allowed to be pasted by the recieving (corona) app.
 */
public class setAllowedTypes implements com.naef.jnlua.NamedJavaFunction 
{
	/**
	 * Gets the name of the Lua function as it would appear in the Lua script.
	 * @return Returns the name of the custom Lua function.
	 */
	@Override
	public String getName() 
	{
		return "setAllowedTypes";
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
			// Number of types
			int numTypes = 0;
			// If the types field is a table
			if ( luaState.isTable( -1 ) )
			{
				// Set the allowed paste types to false
				allowedTypes.canPasteString = false;
				allowedTypes.canPasteUrl = false;

				// Get the tables length
				numTypes = luaState.length( -1 );
			}
			
			// If there are types
			if ( numTypes > 0 )
			{
				// table is an array of 'types'
				for ( int i = 1; i <= numTypes; i++ )
				{
					luaState.rawGet( -1, i );
					
					// Get the type
					final String type = luaState.toString( -1 );

					// If the type is "string", allow pasting of strings
					if ( type.equalsIgnoreCase( "string" ) )
					{
						allowedTypes.canPasteString = true;
					}

					// If the type is "url", allow pasting of Url's
					if ( type.equalsIgnoreCase( "url" )  )
					{
						allowedTypes.canPasteUrl = true;
					}

					// Pop the type
					luaState.pop( 1 );
				}
			}

			// If the types field is nil, disable pasting
			if ( luaState.isNil( -1 ) )
			{
				allowedTypes.canPasteString = false;
				allowedTypes.canPasteUrl = false;
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

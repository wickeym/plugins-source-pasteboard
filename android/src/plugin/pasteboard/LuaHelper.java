//
//  LuaHelper.java
//  Lua helper class
//
//  Copyright (c) 2013 Coronalabs. All rights reserved.
//

// Package name
package plugin.pasteboard; // You change this per project to match the projects package name

// JNLua imports
import com.naef.jnlua.LuaState;
import com.naef.jnlua.LuaType;

// Out LuaHelper Class
public class LuaHelper
{
	// Function to retrieve the baseDirectory from Lua
	public String getBaseDirectory( LuaState luaState, int fileNameIndex, int baseDirIndex )
	{
		// The resulting file path
		String filePath = null;

		// Get the image path from lua using the pathforFile function
		luaState.getGlobal( "system" );
		luaState.getField( -1, "pathForFile" );
		luaState.pushValue( fileNameIndex );
		luaState.pushValue( baseDirIndex );
		luaState.call( 2, 1 ); // Call pathForFile() with 2 arguments and 1 return value.
		filePath = luaState.toString( -1 );
		luaState.pop( 2 );

		// Return the filePath
		return filePath;
	}
}

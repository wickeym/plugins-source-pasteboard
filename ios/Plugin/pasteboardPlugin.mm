//
//  PasteboardPlugin.mm
//  Pasteboard Plugin
//
//  Copyright (c) 2013 CoronaLabs. All rights reserved.
//

#import "pasteboardPlugin.h"

#import <UIKit/UIKit.h>

#import "CoronaRuntime.h"
#include "CoronaAssert.h"
#include "CoronaEvent.h"
#include "CoronaLua.h"
#include "CoronaLibrary.h"

// ----------------------------------------------------------------------------

@class UIViewController;

namespace Corona
{

// ----------------------------------------------------------------------------

class pasteboardLibrary
{
	public:
		typedef pasteboardLibrary Self;

	public:
		static const char kName[];
		
	public:
		static int Open( lua_State *L );
		static int Finalizer( lua_State *L );
		static Self *ToLibrary( lua_State *L );

	protected:
		pasteboardLibrary();
		bool Initialize( void *platformContext );
		
	public:
		UIViewController* GetAppViewController() const { return fAppViewController; }
	
	public:
		static int copy( lua_State *L );
		static int paste( lua_State *L );
		static int getType( lua_State *L );
		static int setAllowedTypes( lua_State *L );
		static int clear( lua_State *L );

	private:
		UIViewController *fAppViewController;
};

// ----------------------------------------------------------------------------

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
const char pasteboardLibrary::kName[] = "plugin.pasteboard";

//Pointer to our pasteboard
UIPasteboard *appPasteBoard = nil;

int
pasteboardLibrary::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );
	
	//CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );
	void *platformContext = CoronaLuaGetContext( L );

	// Set library as upvalue for each library function
	Self *library = new Self;

	if ( library->Initialize( platformContext ) )
	{
		// Functions in library
		static const luaL_Reg kFunctions[] =
		{
			{ "copy", copy },
			{ "paste", paste },
			{ "getType", getType },
			{ "setAllowedTypes", setAllowedTypes },
			{ "clear", clear },
			{ NULL, NULL }
		};

		// Register functions as closures, giving each access to the
		// 'library' instance via ToLibrary()
		{
			CoronaLuaPushUserdata( L, library, kMetatableName );
			luaL_openlib( L, kName, kFunctions, 1 ); // leave "library" on top of stack
		}
	}

	return 1;
}

int
pasteboardLibrary::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );
	delete library;
	
	// Get rid of the pasteboard
	appPasteBoard = nil;
	
	return 0;
}

pasteboardLibrary *
pasteboardLibrary::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}

pasteboardLibrary::pasteboardLibrary()
:	fAppViewController( nil )
{
}

bool
pasteboardLibrary::Initialize( void *platformContext )
{
	bool result = ( ! fAppViewController );

	if ( result )
	{
		id<CoronaRuntime> runtime = (id<CoronaRuntime>)platformContext;
		fAppViewController = runtime.appViewController; // TODO: Should we retain?
	}

	return result;
}

// ----------------------------------------------------------------------------

// Function to return a string for the chosen base directory
static const char *
baseDirectoryToString( lua_State *L, void *baseDir )
{
	const char *baseDirStr = NULL;

	// Get the paths
	lua_getglobal( L, "system" );
	lua_getfield( L, -1, "ResourceDirectory" );
	void *resourceDirectoryConstant = lua_touserdata( L, -1 );
	lua_pop( L, 1 );
	lua_getfield( L, -1, "DocumentsDirectory" );
	void *documentsDirectoryConstant = lua_touserdata( L, -1 );
	lua_pop( L, 1 );
	lua_getfield( L, -1, "TemporaryDirectory" );
	void *temporaryDirectoryConstant = lua_touserdata( L, -1 );
	lua_pop( L, 1 );
	lua_getfield( L, -1, "CachesDirectory" );
	void *cachesDirectoryConstant = lua_touserdata( L, -1 );
	lua_pop( L, 2 ); // Pop the caches key and the system key from the stack
	
	// Check which system constant the user specified
	if ( baseDir == resourceDirectoryConstant)
	{
		baseDirStr = "ResourceDirectory";
	}
	else if ( baseDir == documentsDirectoryConstant )
	{
		baseDirStr = "DocumentsDirectory";
	}
	else if ( baseDir == temporaryDirectoryConstant )
	{
		baseDirStr = "TemporaryDirectory";
	}
	else if ( baseDir == cachesDirectoryConstant )
	{
		baseDirStr = "CachesDirectory";
	}
	
	return baseDirStr;
}


// Types of data allowed to be pasted
static bool isImagePastingAllowed = true;
static bool isStringPastingAllowed = true;
static bool isUrlPastingAllowed = true;

// Function to create the pasteboard
static void
createPasteboardIfNil()
{
	if ( nil == appPasteBoard )
	{
		appPasteBoard = [UIPasteboard generalPasteboard];
		appPasteBoard.persistent = YES;
	}
}


// Set the file types the application can recieve
int
pasteboardLibrary::setAllowedTypes( lua_State *L )
{
	// Create the pasteboard if it doesn't exist
	createPasteboardIfNil();
	
	// If the user has passed in a table
	if ( lua_istable( L, 1 ) )
	{
		// Disable all pasting until we get the allowed types
		isImagePastingAllowed = false;
		isStringPastingAllowed = false;
		isUrlPastingAllowed = false;
	
		// Get the number of defined filters from lua
		int numOfTypes = luaL_getn( L, 1 );

		// Loop through the filter array
		for ( int i = 1; i <= numOfTypes; i++ )
		{
			// Get the tables first value
			lua_rawgeti( L, -1, i );
			
			// Enforce string type
			luaL_checktype( L, -1, LUA_TSTRING );
	
			// The current type
			const char *currentType = lua_tostring( L, -1 );
			
			// Image
			if ( 0 == strcmp( "image", currentType ) )
			{
				isImagePastingAllowed = true;
			}
			// String
			if ( 0 == strcmp( "string", currentType ) )
			{
				isStringPastingAllowed = true;
			}
			// Url
			if ( 0 == strcmp( "url", currentType ) )
			{
				isUrlPastingAllowed = true;
			}

			// Pop the current filter
			lua_pop( L, 1 );
		}
	}
	// If the user passed nil, disable pasting
	if ( lua_isnil( L, 1 ) )
	{
		isImagePastingAllowed = false;
		isStringPastingAllowed = false;
		isUrlPastingAllowed = false;
	}
	
	return 0;
}


// Copy a string, url or image onto the pasteboard
int
pasteboardLibrary::copy( lua_State *L )
{
	// Create the pasteboard if it doesn't exist
	createPasteboardIfNil();
	
	// Enforce string type for #1 & #2 arguments
	luaL_checktype( L, 1, LUA_TSTRING );
	luaL_checktype( L, 2, LUA_TSTRING );
	
	// The copy type string
	const char *copyType = lua_tostring( L, 1 );
	
	// Copy String
	if ( 0 == strcmp( "string", copyType ) )
	{
		// Get the string
		const char *string = lua_tostring( L, 2 );
		NSString *pasteboardString = [NSString stringWithUTF8String:string];
		[appPasteBoard setString:pasteboardString];
	}
	// Copy Url
	if ( 0 == strcmp( "url", copyType ) )
	{
		// Get the url
		const char *url = lua_tostring( L, 2 );
		NSString *pasteboardUrlString = [NSString stringWithUTF8String:url];
		NSURL *pasteBoardUrl = [NSURL URLWithString:[pasteboardUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[appPasteBoard setURL:pasteBoardUrl];
	}
	// Copy Image
	if ( 0 == strcmp( "image", copyType ) )
	{
		// The image filename
		const char *fileName = lua_tostring( L, 2 );

		// File path and filename
		NSString *filePath = nil;
		NSString *fileFromCString = [NSString stringWithUTF8String:fileName];
		
		// The specified system directory path constant
		void *userPathConstant = lua_touserdata( L, 3 );
		
		// Get the baseDir as a string
		const char *baseDir = baseDirectoryToString( L, userPathConstant );
		
		// Check which system constant the user specified
		if ( 0 == strcmp( "ResourceDirectory", baseDir ) )
		{
			// Set the filePath
			filePath = [[NSBundle mainBundle] pathForResource:fileFromCString ofType:nil];
		}
		else if ( 0 == strcmp( "DocumentsDirectory", baseDir ) )
		{
			// Get the documents path
			NSString *documentsPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
			
			// Set the filePath
			filePath = [documentsPath stringByAppendingPathComponent:fileFromCString];
		}
		else if ( 0 == strcmp( "TemporaryDirectory", baseDir ) )
		{
			// Set the filePath
			filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileFromCString];
		}
		else if ( 0 == strcmp( "CachesDirectory", baseDir ) )
		{
			// Get the caches path
			NSString *cachespath = [NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES) lastObject];
			// Set the filePath
			filePath = [cachespath stringByAppendingString:[NSString stringWithFormat:@"/caches/%@", fileFromCString]];
		}
		else
		{
			luaL_error( L, "baseDirectory expected, got nil" );
		}
				
		// Attempt to create the image
		UIImage *image = [UIImage imageWithContentsOfFile:filePath];
		
		// If we can't create the image then throw an error
		if ( image )
		{
			// Copy the image to the pasteboard
			[appPasteBoard setImage:image];
			image = nil;
		}
		else
		{
			luaL_error( L, "Couldn't copy image with filename: %s to the clipboard/pasteboard as it doesn't exist", fileName );
		}
	}
	
	return 0;
}


// Paste an object that is on the pasteboard into the app
int
pasteboardLibrary::paste( lua_State *L )
{
	// Create the pasteboard if it doesn't exist
	createPasteboardIfNil();
	
	// Listener
	Lua::Ref listenerRef = NULL;
	
	// Event Name
	const char *eventName = "pasteboard";
	// Event Type
	const char *eventType = "paste";
		
	// Create native reference to listener
	if ( Lua::IsListener( L, -1, eventName ) )
	{
		listenerRef = Lua::NewRef( L, -1 );
	}
	else
	{
		luaL_error( L, "Listener expected, got nil" );
	}
	
	// If Pasting a String
	if ( ( ( appPasteBoard.string ) && ( isStringPastingAllowed ) ) && ! appPasteBoard.URL )
	{
		// Dispatch the event
		if ( listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, eventName );
			
			// Event type
			lua_pushstring( L, eventType );
			lua_setfield( L, -2, CoronaEventTypeKey() );
			
			// String
			lua_pushstring( L, [appPasteBoard.string UTF8String] );
			lua_setfield( L, -2, "string" );
			
			// Dispatch the event
			Lua::DispatchEvent( L, listenerRef, 0 );
		}
	}
	
	// If Pasting a Url
	if ( ( appPasteBoard.URL ) && ( isUrlPastingAllowed ) )
	{
		// Dispatch the event
		if ( listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, eventName );
			
			// Event type
			lua_pushstring( L, eventType );
			lua_setfield( L, -2, CoronaEventTypeKey() );
			
			// String
			NSString *url = [appPasteBoard.URL absoluteString];
			lua_pushstring( L, [url UTF8String] );
			lua_setfield( L, -2, "url" );
			
			// Dispatch the event
			Lua::DispatchEvent( L, listenerRef, 0 );
		}
	}
	
	// If Pasting an Image
	if ( ( appPasteBoard.image ) && ( isImagePastingAllowed ) )
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectoryPath = [paths objectAtIndex:0];
		NSString *pastedFileName = @"_pasteboard_paste.png";
		NSString* pngFilePath = [documentsDirectoryPath stringByAppendingPathComponent:pastedFileName];
		
		// Does the "_pasteboard_paste.png" file exist?
		BOOL unprefixedFileExists = [[NSFileManager defaultManager] fileExistsAtPath:pngFilePath];
		
		// If the "_pasteboard_paste.png" file already exists, we need to append it's filename with a numeric index
		if ( unprefixedFileExists )
		{
			// Loop through until we reach a paste index that hasn't been used yet.
			for ( int i = 1; i < INFINITY; i++ )
			{
				// The name of the numeric appended filename
				NSString *currentFileName = [NSString stringWithFormat:@"%s%d%s", [pastedFileName UTF8String], i, ".png"];
				// The path to the file
				NSString *actualFilePath = [documentsDirectoryPath stringByAppendingPathComponent:currentFileName];
				// Does the numeric appended file exist
				BOOL numericAppendedFileExists = [[NSFileManager defaultManager] fileExistsAtPath:actualFilePath];
				
				// If the numeric appended file doesn't exist, then we can use that numeric index to append to our filename
				if ( ! numericAppendedFileExists )
				{
					// Set the filename
					pastedFileName = currentFileName;
					break;
				}
			}
		}
			
		// Set the output file write path
		NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", pastedFileName]];
		
		// Write the image to a png file
		[UIImagePNGRepresentation(appPasteBoard.image) writeToFile:pngPath atomically:YES];
		
		// Dispatch the event
		if ( listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, eventName );
			
			// Event type
			lua_pushstring( L, eventType );
			lua_setfield( L, -2, CoronaEventTypeKey() );
			
			// Filename
			lua_pushstring( L, [pastedFileName UTF8String] );
			lua_setfield( L, -2, "filename" );
			
			// Base directory
			lua_getglobal( L, "system" );
			lua_getfield( L, -1, "DocumentsDirectory" );
			lua_setfield( L, -3, "baseDir" );
			lua_pop( L, 1 ); //Pop the system table
			
			// Dispatch the event
			Lua::DispatchEvent( L, listenerRef, 0 );
		}
	}
	
	// Nothing to paste..
	if ( ! appPasteBoard.string && ! appPasteBoard.URL && ! appPasteBoard.image )
	{
		// Dispatch the event
		if ( listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, eventName );
			
			// Event type
			lua_pushnil( L );
			lua_setfield( L, -2, CoronaEventTypeKey() );
			
			// Dispatch the event
			Lua::DispatchEvent( L, listenerRef, 0 );
		}
	}
	
	return 0;
}


// Get the data type of the topmost item on the pasteboard
int
pasteboardLibrary::getType( lua_State *L )
{
	// Create the pasteboard if it doesn't exist
	createPasteboardIfNil();
	
	// Check to see the item type on the pasteboard
	bool typeString = [appPasteBoard containsPasteboardTypes:UIPasteboardTypeListString];
	bool typeUrl = [appPasteBoard containsPasteboardTypes:UIPasteboardTypeListURL];
	bool typeImage = [appPasteBoard containsPasteboardTypes:UIPasteboardTypeListImage];
	
	// String
	if ( typeString )
	{
		lua_pushstring( L, "string" );
		return 1;
	}
	// Url
	if ( typeUrl )
	{
		lua_pushstring( L, "url" );
		return 1;
	}
	// Image
	if ( typeImage )
	{
		lua_pushstring( L, "image" );
		return 1;
	}
	
	// No Data
	lua_pushnil( L );
	return 1;
}


// Clear the pasteboard
int
pasteboardLibrary::clear( lua_State *L )
{
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setValue:@"" forPasteboardType:UIPasteboardNameGeneral];
	
	return 0;
}

// ----------------------------------------------------------------------------

} // namespace Corona

//



// ----------------------------------------------------------------------------

CORONA_EXPORT
int luaopen_plugin_pasteboard( lua_State *L )
{
	return Corona::pasteboardLibrary::Open( L );
}

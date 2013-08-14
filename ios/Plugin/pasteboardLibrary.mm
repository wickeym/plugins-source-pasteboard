// ----------------------------------------------------------------------------
// pasteboardLibrary.mm
//
// Copyright (c) 2013 Corona Labs Inc. All rights reserved.
// ----------------------------------------------------------------------------

#import "pasteboardLibrary.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Accounts/Accounts.h>
#import <AVFoundation/AVFoundation.h>

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
		static int queryType( lua_State *L );
		static int setAllowedTypes( lua_State *L );

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
			{ "queryType", queryType },
			{ "setAllowedTypes", setAllowedTypes },
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
	
	return 0;
}


// Copy a string, url or image onto the pasteboard
int
pasteboardLibrary::copy( lua_State *L )
{
	// Create the pasteboard if it doesn't exist
	createPasteboardIfNil();
	
	const char *copyType = lua_tostring( L, 1 );
	
	// Copy String
	if ( 0 == strcmp( "string", copyType ) )
	{
		printf( "Copying a string\n" );
		
		const char *string = lua_tostring( L, 2 );
		NSString *pasteboardString = [NSString stringWithUTF8String:string];
		[appPasteBoard setString:pasteboardString];
	}
	// Copy Url
	if ( 0 == strcmp( "url", copyType ) )
	{
		printf( "Copying a url\n" );
		
		const char *url = lua_tostring( L, 2 );
		NSString *pasteboardUrlString = [NSString stringWithUTF8String:url];
		NSURL *pasteBoardUrl = [NSURL URLWithString:[pasteboardUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[appPasteBoard setURL:pasteBoardUrl];
	}
	
	// Copy Image
	if ( 0 == strcmp( "image", copyType ) )
	{
		printf( "Copying a image\n" );
		
		// The image filename
		const char *fileName = lua_tostring( L, 2 );

		// File path and 
		NSString *filePath = nil;
		NSString *fileFromCString = [NSString stringWithUTF8String:fileName];
		
		
		// The specified system directory path
		void *userPathConstant = lua_touserdata( L, 3 );
		
		// Get the paths
		lua_getglobal( L, "system" );
		lua_getfield( L, -1, "DocumentsDirectory" );
		void *documentsDirectoryConstant = lua_touserdata( L, -1 );
		lua_pop( L, 1 );
		lua_getfield( L, -1, "TemporaryDirectory" );
		void *temporaryDirectoryConstant = lua_touserdata( L, -1 );
		lua_pop( L, 1 );
		lua_getfield( L, -1, "CachesDirectory" );
		void *cachesDirectoryConstant = lua_touserdata( L, -1 );
		lua_pop( L, 2 );
		
		// Check which system constant the user specified
		if ( userPathConstant == documentsDirectoryConstant )
		{
			printf( "Directory is Documents\n" );
			// Get the documents path
			NSString *documentsPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
			
			// Set the filePath
			filePath = [documentsPath stringByAppendingPathComponent:fileFromCString];
		}
		else if ( userPathConstant == temporaryDirectoryConstant )
		{
			printf( "Directory is Temporary\n" );
			// Set the filePath
			filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileFromCString];
		}
		else if ( userPathConstant == cachesDirectoryConstant )
		{
			printf( "Directory is Caches\n" );
			// Get the caches path
			NSString *cachespath = [NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES) lastObject];
			// Set the filePath
			filePath = [cachespath stringByAppendingPathComponent:fileFromCString];
		}
		else
		{
			printf( "Directory is Resource\n" );
			// Get the fileName & extension
			NSString* fName = [[fileFromCString lastPathComponent] stringByDeletingPathExtension];
			NSString* ext = [fileFromCString pathExtension];
			
			// Set the filePath
			filePath = [[NSBundle mainBundle] pathForResource:fName ofType:ext];
		}
				
		// Attempt to create the image
		UIImage* image = [UIImage imageWithContentsOfFile:filePath];
		
		if ( NULL == image )
		{
			luaL_error( L, "Couldn't copy image with filename: %s to the clipboard as it doesn't exist", fileName );
		}
		else
		{
			// Copy the image to the pasteboard
			[appPasteBoard setImage:image];
			image = nil;
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
		
	// Create native reference to listener
	if ( Lua::IsListener( L, -1, "pasteboard" ) )
	{
		listenerRef = Lua::NewRef( L, -1 );
	}
	
	// If Pasting a String
	if ( appPasteBoard.string )
	{
		// Dispatch the event
		if ( NULL != listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, "pasteboard" );
			
			// Event type
			lua_pushstring( L, "paste" );
			lua_setfield( L, -2, CoronaEventTypeKey() );
			
			// String
			lua_pushstring( L, [appPasteBoard.string UTF8String] );
			lua_setfield( L, -2, "string" );
			
			// Dispatch the event
			Lua::DispatchEvent( L, listenerRef, 0 );
		}
	}
	
	// If Pasting a Url
	if ( appPasteBoard.URL )
	{
		// Dispatch the event
		if ( NULL != listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, "pasteboard" );
			
			// Event type
			lua_pushstring( L, "paste" );
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
	if ( appPasteBoard.image )
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
		NSString *documentsDirectoryPath = [paths objectAtIndex:0];
		NSString *oldFile = [documentsDirectoryPath stringByAppendingPathComponent:@"clipboard.png"];
		[[NSFileManager defaultManager] removeItemAtPath:oldFile error:NULL];
		
		//NSString* pngFile = [documentsPath stringByAppendingPathComponent:@"Documents/clipboard.png"];
		//BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:pngFile];
		
		// QUESTION: Do we want to remove and replace the old clipboard image or append the filename with numeric indexes so a potentially unlimited (storage limited) number of image pastes can be achieved?
	
		// Set the output path
		NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/clipboard.png"];
		
		// Write the image to a png file
		[UIImagePNGRepresentation(appPasteBoard.image) writeToFile:pngPath atomically:YES];
		
		// Dispatch the event
		if ( NULL != listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, "pasteboard" );
			
			// Event type
			lua_pushstring( L, "paste" );
			lua_setfield( L, -2, CoronaEventTypeKey() );
			
			// Filename
			lua_pushstring( L, "clipboard.png" );
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
		if ( NULL != listenerRef )
		{
			// Event name
			Corona::Lua::NewEvent( L, "pasteboard" );
			
			// Event type
			lua_pushnil( L );
			lua_setfield( L, -2, CoronaEventTypeKey() );
			
			// Dispatch the event
			Lua::DispatchEvent( L, listenerRef, 0 );
		}
	}
	
	return 0;
}


// Query the data type of the topmost item on the pasteboard
int
pasteboardLibrary::queryType( lua_State *L )
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
	
	// None
	lua_pushstring( L, "none" );
	return 1;
}

// ----------------------------------------------------------------------------

} // namespace Corona

//



// ----------------------------------------------------------------------------

// IMPORTANT > the name here (and in the .h file) MUST match the name of the plugin.
// This plugin is named "plugin.iTunes" via lua so here it is plugin_iTunes
// If you wanted to rename it to just "iTunes" you would change it to luaopen_iTunes
// If you wanted to rename it to "plugin.myPlugin" you would change it to luaopen_plugin_myPlugin
CORONA_EXPORT
int luaopen_plugin_pasteboard( lua_State *L )
{
	return Corona::pasteboardLibrary::Open( L );
}

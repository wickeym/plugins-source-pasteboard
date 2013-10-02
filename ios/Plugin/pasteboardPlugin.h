//
//  PasteboardPlugin.h
//  Pasteboard Plugin
//
//  Copyright (c) 2013 CoronaLabs. All rights reserved.
//

#ifndef _PasteboardPlugin_H__
#define _PasteboardPlugin_H__

#include "CoronaLua.h"
#include "CoronaMacros.h"

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
// where the '.' is replaced with '_'
CORONA_EXPORT int luaopen_plugin_pasteboard( lua_State *L );

#endif // _PasteboardPlugin_H__

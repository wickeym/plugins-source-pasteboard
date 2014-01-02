-- 
-- Abstract: Pasteboard sample app
--  
-- Version: 1.0
-- 
-- Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- Copyright (C) 2013 Corona Labs Inc. All Rights Reserved.
--
-- Demonstrates how to use Corona to interact with the device pasteboard.

-- Require the Widget library
local widget = require( "widget" )

-- Require the plugin library
local pasteboard = require( "plugin.pasteboard" )

-- Create a background
local background = display.newImageRect( "back-whiteorange.png", display.contentWidth, display.contentHeight );
background.x = display.contentCenterX
background.y = display.contentCenterY
background:addEventListener( "touch", function() native.setKeyboardFocus( nil ) end )

-- Create a textfield
local textField = native.newTextField( display.contentCenterX, 60, 200, 40 )

-- Container for our image
local imgContainer = display.newRect( display.contentCenterX, 160, 100, 100 )
imgContainer:setFillColor( 0 )
imgContainer.img = nil

-- Set the data types this application allows (from a paste)
pasteboard.setAllowedTypes( { "url", "string", "image" } )

-- Retrieve the type of data on the pasteboard
local function getType()
	local function printType()
		-- Query the type of data on the pasteboard
		local pType = pasteboard.getType()

		-- Print the data type
		print( "Type of data on pasteboard is:", pType )
	end

	timer.performWithDelay( 100, printType )
end


-- Handler for our transition
local imgTransition = nil

-- Callback function for the paste method
local function onPaste( event )
	print( "event name:", event.name )
	print( "event type:", event.type )
	print( "Pasting a/an ", pasteboard.getType() )
	
	-- Paste an image
	if event.filename then
		display.remove( imgContainer.img )
		imgContainer.img = nil
		imgContainer.img = display.newImageRect( event.filename, event.baseDir, 80, 80 )
		imgContainer.img.alpha = 0
		imgContainer.img.x = imgContainer.x
		imgContainer.img.y = imgContainer.y

		if imgTransition then
			transition.cancel( imgTransition )
			imgTransition = nil
		end
		imgTransition = transition.to( imgContainer.img, { alpha = 1 } )
	end
	
	-- Paste a string
	if event.string then
		-- Update the textfield's text
		textField.text = event.string
	end
	
	-- Paste a url
	if event.url then
		-- Update the textfield's text
		textField.text = event.url
	end
end

-- Widget button handlers
-----------------------------------------------------------------

-- Function to clear the pasteboard
local function clearPasteboard()
	pasteboard.clear()
end

-- Function to copy an Image to pasteboard
local function copyImage()	
	pasteboard.copy( "image", "Icon.png", system.ResourceDirectory )
end

-- Function to copy a string to the pasteboard
local function copyString()
	pasteboard.copy( "string", "Hello Corona World!" )
end

-- Function to copy a url to the pasteboard
local function copyUrl()
	pasteboard.copy( "url", "http://www.coronalabs.com" )
end

-- Function to paste the contents of the pasteboard
local function paste()
	pasteboard.paste( onPaste )
end

-- Create widget buttons
-----------------------------------------------------------------

-- Positioning vars
local topPosition = 230

-- Only show the image copy button on iOS
if system.getInfo( "platformName" ) ~= "Android" then
	-- Button - Copy Image
	local copyImageButton = widget.newButton
	{
		left = 60,
		top = topPosition,
		label = "Copy Image",
		onRelease = copyImage,
	}
	topPosition = copyImageButton.y + copyImageButton.contentHeight - 28
end

-- Button - Copy String
local copyStringButton = widget.newButton
{
	left = 60,
	top = topPosition,
	label = "Copy String",
	onRelease = copyString,
}

-- Button - Copy Url
local copyUrlButton = widget.newButton
{
	left = 60,
	top = copyStringButton.y + copyStringButton.contentHeight - 28,
	label = "Copy Url",
	onRelease = copyUrl,
}

-- Button - Paste
local pasteButton = widget.newButton
{
	left = 60,
	top = copyUrlButton.y + copyUrlButton.contentHeight - 28,
	label = "Paste",
	onRelease = paste,
}

-- Button - Clear Pasteboard
local clearButton = widget.newButton
{
	left = 60,
	top = pasteButton.y + pasteButton.contentHeight - 28,
	label = "Clear Pasteboard",
	onRelease = clearPasteboard,
}

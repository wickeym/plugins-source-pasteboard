local widget = require( "widget" )

-- Function to copy a file
local function copyFile( options )
	local _sourceFile = options.sourceFile or error( "idUtils:copyFile - options.sourceFile is either nil or omitted" )
	local _sourcePath = options.sourcePath or error( "idUtils:copyFile - options.sourcePath is either nil or omitted" )
	local _destinationFile = options.destinationFile or error( "idUtils:copyFile - options.destinationFile is either nil or omitted" )
	local _destinationPath = options.destinationPath or error( "idUtils:copyFile - options.destinationPath is either nil or omitted" )
    
	-- Assume copy went ok
	local results = true

    -- Copy the source file to the destination file
    local readPath = system.pathForFile( _sourceFile, _sourcePath )
    local writePath = system.pathForFile( _destinationFile, _destinationPath )
 
    local readHandle = io.open( readPath, "rb" ) --Ensure this is ok..          
    local writeHandle = io.open( writePath, "wb" ) --Ensure this is ok..
        
    if not writeHandle then
        error( "idUtils:copyFile - Problem opening write file path" )
        results = false
    else
        -- Read the file from the source directory and write it to the destination directory
        local data = readHandle:read( "*a" )
         
		-- Check if we were able to read the data file
        if not data then
            error( "idUtils:copyFile - Problem reading data!" )
            results = false
        else
            if not writeHandle:write( data ) then
                print( "idUtils:copyFile - Problem writing data!" ) 
                results = false
            end
        end
    end
        
    -- Clean up our file handles
    readHandle:close()
    readHandle = nil
    writeHandle:close()
    writeHandle = nil
 
	return results  
end

--------------------------------------------------


-- Require the plugin library
local pasteboard = require( "plugin.pasteboard" )

-- Create a background
local background = display.newImageRect( "back-whiteorange.png", display.contentWidth, display.contentHeight );
background.x = display.contentCenterX
background.y = display.contentCenterY
background:addEventListener( "touch", function() native.setKeyboardFocus( nil ) end )

-- Create a textfield
local textField = native.newTextField( 60, 40, 200, 40 )

-- Container for our image
local imgContainer = display.newRect( 100, 100, 100, 100 )
imgContainer:setFillColor( 0 )
imgContainer.img = nil

-- Set the data types this application allows (from a paste)
--pasteboard.setAllowedTypes( { "url", "string", "image" } )

-- Query the type of data on the pasteboard
--local pType = pasteboard.getType()

-- Print the data type
--print( "Type of data on pasteboard is:", pType )

-- Callback function for the paste method
local function onPaste( event )
	print( ">>>> WE MADE IT INTO THE PASTE COMPLETION LISTENER <<<<" )

	if "table" == type( event ) then
		for k, v in pairs( event ) do
			print( k, v )
		end
	end


	
	--print( "Pasting a/an ", pasteboard.getType() )
	
	-- Paste an image
	if event.filename then
		--print( "IMAGE" )
		--display.remove( imgContainer.img )
		
		--print( "filename is:", event.filename )
		--print( "baseDir is:", event.baseDir )

		imgContainer.img = display.newImageRect( event.filename, event.baseDir, 80, 80 )
		imgContainer.img.alpha = 0
		imgContainer.img.x = imgContainer.x
		imgContainer.img.y = imgContainer.y
		transition.to( imgContainer.img, { alpha = 1 } )
	end
	
	-- Paste a string
	if event.string then
		--print( "STRING" )
		--local text = display.newText( event.string, 0, 0, native.systemFontBold, 16 )
		--text.x = display.contentCenterX
		--text.y = display.contentCenterY
		textField.text = event.string
	end
	
	-- Paste a url
	if event.url then
		--print( "URL" )
		textField.text = event.url
		--local webView = native.newWebView( 0, 0, display.contentWidth, display.contentHeight )
		--webView:request( event.url )
	end
end

--[[
-- Copy a file to the temporary directory (for testing)
copyFile( 
{ 
	sourceFile = "Icon.png",
	sourcePath = system.ResourceDirectory,
	destinationFile = "tempTest.png",
	destinationPath = system.TemporaryDirectory,
})
--]]

--[[
-- Copy a file to the caches directory (for testing)
copyFile( 
{ 
	sourceFile = "Icon.png",
	sourcePath = system.ResourceDirectory,
	destinationFile = "cacheTest.png",
	destinationPath = system.CachesDirectory,
})
--]]

---[[
-- Copy a file to the documents directory (for testing)
copyFile( 
{ 
	sourceFile = "Icon.png.txt",
	sourcePath = system.ResourceDirectory,
	destinationFile = "docsTest.png",
	destinationPath = system.DocumentsDirectory,
})
--]]

-- Test image copy to pasteboard
local function copyImage()	
	pasteboard.copy( "image", "Icon.png", system.ResourceDirectory )
	--pasteboard.copy( "image", "docsTest.png", system.DocumentsDirectory )
	--pasteboard.copy( "image", "tempTest.png", system.TemporaryDirectory )
	--pasteboard.copy( "image", "tempTest.png", system.CachesDirectory )
end

-- Test copying a string to the pasteboard
local function copyString()
	pasteboard.copy( "string", "Hello Corona World!" )
end

-- Test copying a url to the pasteboard
local function copyUrl()
	pasteboard.copy( "url", "http://www.coronalabs.com" )
end

-- Paste whatever is on the clipboard
local function paste()
	pasteboard.paste( onPaste )
end

local img = display.newImage( "docsTest.png", system.DocumentsDirectory )
print( "path" .. system.pathForFile( "docsTest.png", system.DocumentsDirectory ) )

-- Button - Copy Image
local copyImageButton = widget.newButton
{
	left = 60,
	top = 230,
	label = "Copy Image",
	onRelease = copyImage,
}

-- Button - Copy String
local copyStringButton = widget.newButton
{
	left = 60,
	top = copyImageButton.y + copyImageButton.contentHeight - 10,
	label = "Copy String",
	onRelease = copyString,
}

-- Button - Copy Url
local copyUrlButton = widget.newButton
{
	left = 60,
	top = copyStringButton.y + copyStringButton.contentHeight - 10,
	label = "Copy Url",
	onRelease = copyUrl,
}

-- Button - Paste
local pasteButton = widget.newButton
{
	left = 60,
	top = copyUrlButton.y + copyUrlButton.contentHeight - 10,
	label = "Paste",
	onRelease = paste,
}

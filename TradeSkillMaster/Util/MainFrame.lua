-- This file contains all the APIs regarding TSM's main frame (what shows when you type '/tsm').

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local private = {icons={}, currentIcon=0}
local lib = TSMAPI


--- Opens the main TSM window.
function lib:OpenFrame()
	TSM.Frame:Show()
end

--- Closes the main TSM window.
function lib:CloseFrame()
	TSM.Frame:Hide()
end

--- Registers a new icon to be displayed in the main TSM window.
-- @param displayName The text that shows when the user hovers over the icon (localized).
-- @param icon The texture to use for the icon.
-- @param loadGUI A function that will get called when the user clicks on the icon.
-- @param moduleName The name of the module that's registering this icon (unlocalized).
-- @param side The side of the main TSM frame to put the icon on. The options are "crafting" (left side), "module" (bottom), and "options" (right side).
-- @return Returns an error message as the second return value upon error.
function lib:RegisterIcon(displayName, icon, loadGUI, moduleName, side)
	if not (displayName and icon and loadGUI and moduleName) then
		return nil, "invalid args", displayName, icon, loadGUI, moduleName
	end
	
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	if side and not (side == "module" or side == "crafting" or side == "options") then
		return nil, "invalid side", side
	end
	
	local icon = {name=displayName, moduleName=moduleName, icon=icon, loadGUI=loadGUI, side=(strlower(side or "module"))}
	if TSM.Frame then
		icon.texture = icon.icon
		if icon.side == "crafting" then
			icon.where = "bottom"
		elseif icon.side == "options" then
			icon.where = "topLeft"
		else
			icon.where = "topRight"
		end
		
		TSM.Frame:AddIcon(icon)
	end
	
	tinsert(private.icons, icon)
end

--- Selects an icon in the main TSM window once it's open.
-- @param moduleName Which module the icon belongs to (unlocalized).
-- @param iconName The text that shows in the tooltip of the icon to be clicked (localized).
-- @return Returns an error message as the second return value upon error.
function lib:SelectIcon(moduleName, iconName)
	if not moduleName then return nil, "no moduleName passed" end
	
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	for _, data in ipairs(private.icons) do
		if not data.frame then return nil, "not ready yet" end
		if data.moduleName == moduleName and data.name == iconName then
			data.frame:Click()
		end
	end
end


function TSM:CreateMainFrame()
	local mainFrame = AceGUI:Create("TSMMainFrame")
	local version = TSM.version
	if strfind(version, "@") then version = "Dev" end
	mainFrame:SetIconText(version)
	mainFrame:SetIconLabels("Module Options", "Module Features", "Crafting Professions")
	mainFrame:SetLayout("Fill")
	mainFrame:SetWidth(823)
	mainFrame:SetHeight(686)
	mainFrame.frame:SetWidth(823)
	mainFrame.frame:SetHeight(686)
	
	for _, icon in ipairs(private.icons) do
		icon.texture = icon.icon
		if icon.side == "crafting" then
			icon.where = "bottom"
		elseif icon.side == "options" then
			icon.where = "topLeft"
		else
			icon.where = "topRight"
		end
		
		mainFrame:AddIcon(icon)
	end
	TSM.Frame = mainFrame
	--TSM.Frame.helpButton = TSM:CreateHelpButton()
	
	TSMAPI:CreateTimeDelay("mainFrameSize", .5, function() mainFrame:SetWidth(823) mainFrame:SetHeight(686) end)
end
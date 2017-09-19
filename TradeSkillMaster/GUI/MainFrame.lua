-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the APIs regarding TSM's main frame (what shows when you type '/tsm').

local TSM = select(2, ...)
local MainFrame = TSM:NewModule("MainFrame")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {icons={}, frame=nil}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Operations:ShowOptions(moduleName, operation, groupPath)
	TSM.loadModuleOptionsTab = {module=moduleName, operation=operation, group=groupPath}
	MainFrame:SelectIcon("TradeSkillMaster", L["Operations"])
	TSM.loadModuleOptionsTab = nil
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function MainFrame:Show()
	if not private.frame then
		local mainFrame = LibStub("AceGUI-3.0"):Create("TSMMainFrame")
		mainFrame:SetIconText(TSM._version)
		mainFrame:SetIconLabels(L["Options / Core Features"], L["Module Features"])
		mainFrame:SetLayout("Fill")
		
		for _, icon in ipairs(private.icons) do
			icon.texture = icon.icon
			if icon.side == "options" then
				icon.where = "topLeft"
			else
				icon.where = "topRight"
			end
			
			mainFrame:AddIcon(icon)
		end
		private.frame = mainFrame
		
		TSMAPI.Delay:AfterFrame(1, function() private.frame:SetWidth(private.frame.frame.options.width) private.frame:SetHeight(private.frame.frame.options.height) end)
	end
	private.frame:Show()
	if #private.frame.children > 0 then
		private.frame:ReleaseChildren()
	else
		MainFrame:SelectIcon("TradeSkillMaster", L["TSM Features"])
	end
end

function MainFrame:RegisterMainFrameIcon(displayName, icon, loadGUI, moduleName, side)
	if not (displayName and icon and loadGUI and moduleName) then
		return nil, "invalid args", displayName, icon, loadGUI, moduleName
	end
	
	if side and not (side == "module" or side == "options") then
		return nil, "invalid side", side
	end
	
	local icon = {name=displayName, moduleName=moduleName, icon=icon, loadGUI=loadGUI, side=(strlower(side or "module"))}
	if private.frame then
		icon.texture = icon.icon
		if icon.side == "options" then
			icon.where = "topLeft"
		else
			icon.where = "topRight"
		end
		
		private.frame:AddIcon(icon)
	end
	
	tinsert(private.icons, icon)
end

function MainFrame:SelectIcon(moduleName, iconName)
	if not private.frame or not private.frame:IsVisible() then
		MainFrame:Show()
	end
	TSMAPI:Assert(type(moduleName) == "string", "Invalid moduleName parameter")
	for _, data in ipairs(private.icons) do
		if data.moduleName == moduleName and data.name == iconName then
			data.frame:Click()
		end
	end
end
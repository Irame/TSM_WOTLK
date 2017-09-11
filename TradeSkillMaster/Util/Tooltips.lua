-- This file contains all the APIs regarding putting TSM info into item tooltips.

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table

local tooltipLib = LibStub("nTipHelper:1")
local registeredTooltips = {}
local lib = TSMAPI


function TSM:InitializeTooltip()
	tooltipLib:Activate()
	tooltipLib:AddCallback(function(...) TSM:LoadTooltip(...) end)
end

function TSM:LoadTooltip(tipFrame, link, quantity)
	local itemID = lib:GetItemID(link)
	if not itemID then return end
	
	local lines = {}
	for _, v in ipairs(registeredTooltips) do
		local moduleLines = v.loadFunc(itemID, quantity)
		if type(moduleLines) ~= "table" then moduleLines = {} end
		for _, line in ipairs(moduleLines) do
			tinsert(lines, line)
		end
	end
	
	if #lines > 0 then
		tooltipLib:SetFrame(tipFrame)
		tooltipLib:AddLine(" ", nil, true)
		tooltipLib:SetColor(1,1,0)
		tooltipLib:AddLine(L["TradeSkillMaster Info:"], nil, true)
		tooltipLib:SetColor(0.4,0.4,0.9)
		
		for i=1, #lines do
			tooltipLib:AddLine(lines[i], nil, true)
		end
		
		tooltipLib:AddLine(" ", nil, true)
	end
end


--- Registers a callback that will be called when an item's tooltip is called.
-- This API should be used for all modules which wish to add a line underneath "TradeSkillMaster Info:" in item tooltips.
-- @param moduleName The name of the module which is registering the tooltip.
-- @param callback The function to be called when a tooltip is shown. Two parameters will be passed: itemID and stackSize. A list of lines to add to the tooltip should be returned.
function lib:RegisterTooltip(moduleName, callback)
	if not (moduleName and callback) then
		return nil, "Invalid arguments", moduleName, callback
	elseif not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	tinsert(registeredTooltips, {module=moduleName, loadFunc=callback})
end

--- Unegisters the first tooltip callback (in order of registration) which was registerd under the given module name.
-- @param moduleName The name of the module which the tooltip is registered under.
function lib:UnregisterTooltip(moduleName)
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	for i, v in ipairs(registeredTooltips) do
		if v.module == moduleName then
			tremove(registeredTooltips, i)
			return
		end
	end
end
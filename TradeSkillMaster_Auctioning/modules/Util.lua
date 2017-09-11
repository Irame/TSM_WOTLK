-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Auctioning - AddOn by Sapu94							 	  --
--   			http://www.curse.com/addons/wow/tradeskillmaster_accounting  		  			  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local Util = TSM:NewModule("Util")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

function Util:ValidateGroupName(value)
	-- if it's an itemlink, get the actual name of the item
	local ok, name = pcall(function() return GetItemInfo(value) end)
	value = ok and name or value
	
	value = (strlower(value) or ""):trim()
	if TSM.db.profile.groups[value] or TSM.db.profile.categories[value] then
		return nil, format(L["Group/Category named \"%s\" already exists!"], value)
	elseif value == "" then
		return nil, L["Invalid group name."]
	end
	
	return value
end

function Util:UnformatTextMoney(value)
	local gold = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)g|r") or string.match(value, "([0-9]+)g"))
	local silver = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)s|r") or string.match(value, "([0-9]+)s"))
	local copper = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)c|r") or string.match(value, "([0-9]+)c"))
		
	if gold or silver or copper then
		-- Convert it all into copper
		copper = (copper or 0) + ((gold or 0) * COPPER_PER_GOLD) + ((silver or 0) * COPPER_PER_SILVER)
	end

	return copper
end

-- check if an item is soulbound or not
local scanTooltip
local resultsCache = {lastClear=GetTime()}
function Util:IsSoulbound(bag, slot)
	if GetTime() - resultsCache.lastClear > 0.5 then
		resultsCache = {lastClear=GetTime()}
	end

	local slotID = bag.."@"..slot
	if resultsCache[slotID] ~= nil then return resultsCache[slotID] end
	
	if not scanTooltip then
		scanTooltip = CreateFrame("GameTooltip", "TSMAucScanTooltip", UIParent, "GameTooltipTemplate")
		scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	scanTooltip:ClearLines()
	scanTooltip:SetBagItem(bag, slot)
	
	for id=1, scanTooltip:NumLines() do
		local text = _G["TSMAucScanTooltipTextLeft" .. id]
		if text and ((text:GetText() == ITEM_BIND_ON_PICKUP and id < 4) or text:GetText() == ITEM_SOULBOUND or text:GetText() == ITEM_BIND_QUEST) then
			resultsCache[slotID] = true
			return true
		end
	end
	
	resultsCache[slotID] = false
	return false
end
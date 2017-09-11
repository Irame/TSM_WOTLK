-- ------------------------------------------------------------------------------------- --
--					TradeSkillMaster_Crafting - AddOn by Sapu94									  --
--	 http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx	 --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/				  --
--	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- The following functions are contained attached to this file:
-- Engineering:HasProfession() - determines if the player is an tailor

-- The following "global" (within the addon) variables are initialized in this file:

-- Engineering.slot - hardcoded list of the slot of every craft
-- ===================================================================================== --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Engineering = TSM:NewModule("Engineering", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is an tailor
function Engineering:HasProfession()
	local professionIDs = {4036, 4037, 4038, 12656, 30350, 51306, 82774}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

function Engineering:GetSlotIndex(slotName)
	for i, name in ipairs(Engineering.slotList) do
		if name == slotName then
			return i
		end
	end
end

function Engineering:GetSlot(itemID)
	if not itemID then return end
	
	local _, _, _, _, _, iType, subType, _, equipSlot = GetItemInfo(itemID)
	local auctionClasses = {GetAuctionItemClasses()}
	
	-- Weapons
	if iType == auctionClasses[1] then
		local subClasses = {GetAuctionItemSubClasses(1)}
		
		-- Guns/Bows/Crossbows
		if subType == subClasses[4] or subType == subClasses[3] or subType == subClasses[15] then
			return Engineering:GetSlotIndex(L["Guns"])
		end
	-- Armor
	elseif iType == auctionClasses[2] then
		local subClasses = {GetAuctionItemSubClasses(2)}
		
		-- Miscellaneous/Trinket
		if subType == subClasses[1] and equipSlot == "INVTYPE_TRINKET" then
			return Engineering:GetSlotIndex(L["Trinkets"])
		-- Other Armor
		else
			return Engineering:GetSlotIndex(L["Armor"])
		end
	-- Consumable
	elseif iType == auctionClasses[4] then
		return Engineering:GetSlotIndex(L["Consumables"])
	-- Trade Goods
	elseif iType == auctionClasses[6] then
		local subClasses = {GetAuctionItemSubClasses(6)}
		
		-- Devices
		if subType == subClasses[10] then
			return Engineering:GetSlotIndex(L["Scopes"])
		-- Explosives
		elseif subType == subClasses[11] then
			return Engineering:GetSlotIndex(L["Explosives"])
		end
	-- Miscellaneous
	elseif iType == auctionClasses[9] then
		local subClasses = {GetAuctionItemSubClasses(9)}
		
		-- Pets
		if subType == subClasses[3] then
			return Engineering:GetSlotIndex(L["Companions"])
		end
	end
	
	return #Engineering.slotList
end

Engineering.slotList = {
	L["Armor"], 
	L["Guns"], 
	L["Scopes"], 
	L["Consumables"], 
	L["Explosives"], 
	L["Companions"], 
	L["Trinkets"], 
	L["Misc Items"]
}

--[[
Changed Items:
60858: Misc -> Consumables
6219: Gun -> Misc
68049: Misc -> Consumables
]]

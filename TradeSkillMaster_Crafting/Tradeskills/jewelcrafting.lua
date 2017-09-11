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
-- Jewelcrafting:HasProfession() - determines if the player is a jewelcrafter

-- The following "global" (within the addon) variables are initialized in this file:
-- Jewelcrafting.slot - hardcoded list of the slot of every craft

-- ===================================================================================== --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Jewelcrafting = TSM:NewModule("Jewelcrafting", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is a jewelcrafter
function Jewelcrafting:HasProfession()
	local professionIDs = {25229, 25230, 28894, 28895, 28897, 51311, 73318}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

function Jewelcrafting:GetSlotIndex(slotName)
	for i, name in ipairs(Jewelcrafting.slotList) do
		if name == slotName then
			return i
		end
	end
end

function Jewelcrafting:GetSlot(itemID, _, _)
	if not itemID then return end
	
	local types = {GetAuctionItemClasses()}
	local subTypes = {GetAuctionItemSubClasses(8)}
	
	local name, _, rarity, _, _, iType, subType = GetItemInfo(itemID)
	if iType == types[8] then
		if subType == subTypes[1] then
			return Jewelcrafting:GetSlotIndex(L["Red Gems"])
		elseif subType == subTypes[2] then
			return Jewelcrafting:GetSlotIndex(L["Blue Gems"])
		elseif subType == subTypes[3] then
			return Jewelcrafting:GetSlotIndex(L["Yellow Gems"])
		elseif subType == subTypes[4] then
			return Jewelcrafting:GetSlotIndex(L["Purple Gems"])
		elseif subType == subTypes[5] then
			return Jewelcrafting:GetSlotIndex(L["Green Gems"])
		elseif subType == subTypes[6] then
			return Jewelcrafting:GetSlotIndex(L["Orange Gems"])
		elseif subType == subTypes[7] then
			return Jewelcrafting:GetSlotIndex(L["Meta Gems"])
		elseif subType == subTypes[8] then
			return Jewelcrafting:GetSlotIndex(L["Prismatic Gems"])
		else
			return Jewelcrafting:GetSlotIndex(L["Misc Items"])
		end
	end

	return #Jewelcrafting.slotList
end

Jewelcrafting.slotList = {L["Red Gems"], L["Blue Gems"], L["Yellow Gems"], L["Purple Gems"], L["Green Gems"],
	L["Orange Gems"], L["Meta Gems"], L["Prismatic Gems"], L["Misc Items"], L["Other"]}

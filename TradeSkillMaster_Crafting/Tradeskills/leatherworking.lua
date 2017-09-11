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
-- Leatherworking:HasProfession() - determines if the player is an leatherworker

-- The following "global" (within the addon) variables are initialized in this file:
-- Leatherworking.slot - hardcoded list of the slot of every craft

-- ===================================================================================== --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Leatherworking = TSM:NewModule("Leatherworking", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is an leatherworkers
function Leatherworking:HasProfession()
	local professionIDs = {2108, 3104, 3811, 10662, 32549, 51302, 81199}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

function Leatherworking:GetSlotIndex(slotName)
	for i, name in ipairs(Leatherworking.slotList) do
		if name == slotName then
			return i
		end
	end
end

function Leatherworking:GetSlot(itemID)
	if not itemID then return end
	
	local _, _, _, _, _, iType, subType, _, equipSlot = GetItemInfo(itemID)
	local auctionClasses = {GetAuctionItemClasses()}
	
	-- Armor
	if iType == auctionClasses[2] then
		-- Back
		if equipSlot == "INVTYPE_CLOAK" then
			return Leatherworking:GetSlotIndex(L["Armor - Back"])
		-- Chest
		elseif equipSlot == "INVTYPE_CHEST" or equipSlot == "INVTYPE_ROBE" then
			return Leatherworking:GetSlotIndex(L["Armor - Chest"])
		-- Feet
		elseif equipSlot == "INVTYPE_FEET" then
			return Leatherworking:GetSlotIndex(L["Armor - Feet"])
		-- Hand
		elseif equipSlot == "INVTYPE_HAND" then
			return Leatherworking:GetSlotIndex(L["Armor - Hands"])
		-- Head
		elseif equipSlot == "INVTYPE_HEAD" then
			return Leatherworking:GetSlotIndex(L["Armor - Head"])
		-- Legs
		elseif equipSlot == "INVTYPE_LEGS" then
			return Leatherworking:GetSlotIndex(L["Armor - Legs"])
		-- Shoulders
		elseif equipSlot == "INVTYPE_SHOULDER" then
			return Leatherworking:GetSlotIndex(L["Armor - Shoulders"])
		-- Waist
		elseif equipSlot == "INVTYPE_WAIST" then
			return Leatherworking:GetSlotIndex(L["Armor - Waist"])
		-- Wrist
		elseif equipSlot == "INVTYPE_WRIST" then
			return Leatherworking:GetSlotIndex(L["Armor - Wrists"])
		end
	-- Containers
	elseif iType == auctionClasses[3] then
		return Leatherworking:GetSlotIndex(L["Bags"])
	-- Consumables
	elseif iType == auctionClasses[4] then
		return Leatherworking:GetSlotIndex(L["Consumables"])
	-- Trade Goods
	elseif iType == auctionClasses[6] then
		local subClasses = {GetAuctionItemSubClasses(6)}
		
		-- Leather
		if subType == subClasses[3] then
			return Leatherworking:GetSlotIndex(L["Leather"])
		end
	end
	
	return #Leatherworking.slotList
end
		
Leatherworking.slotList = {
	L["Armor - Back"],
	L["Armor - Chest"],
	L["Armor - Feet"],
	L["Armor - Hands"],
	L["Armor - Head"],
	L["Armor - Legs"],
	L["Armor - Shoulders"],
	L["Armor - Waist"],
	L["Armor - Wrists"],
	L["Bags"], 
	L["Consumables"], 
	L["Leather"], 
	L["Other"]
}

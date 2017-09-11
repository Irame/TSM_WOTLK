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
-- Tailoring:HasProfession() - determines if the player is an tailor

-- The following "global" (within the addon) variables are initialized in this file:
-- Tailoring.slot - hardcoded list of the slot of every craft

-- ===================================================================================== --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Tailoring = TSM:NewModule("Tailoring", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is an tailor
function Tailoring:HasProfession()
	local professionIDs = {3908, 3909, 3910, 12180, 26790, 51309, 75156}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

function Tailoring:GetSlotIndex(slotName)
	for i, name in ipairs(Tailoring.slotList) do
		if name == slotName then
			return i
		end
	end
end

function Tailoring:GetSlot(itemID, _, _)
	if not itemID then return end
	
	local _, _, _, _, _, iType, subType, _, equipSlot = GetItemInfo(itemID)
	local auctionClasses = {GetAuctionItemClasses()}
	
	-- Armor
	if iType == auctionClasses[2] then
		-- Head
		if equipSlot == "INVTYPE_HEAD" then
			return Tailoring:GetSlotIndex(L["Armor - Head"])
		-- Shoulder
		elseif equipSlot == "INVTYPE_SHOULDER" then
			return Tailoring:GetSlotIndex(L["Armor - Shoulders"])
		-- Chest
		elseif equipSlot == "INVTYPE_CHEST" or equipSlot == "INVTYPE_ROBE" then
			return Tailoring:GetSlotIndex(L["Armor - Chest"])
		-- Waist
		elseif equipSlot == "INVTYPE_WAIST" then
			return Tailoring:GetSlotIndex(L["Armor - Waist"])
		-- Legs
		elseif equipSlot == "INVTYPE_LEGS" then
			return Tailoring:GetSlotIndex(L["Armor - Legs"])
		-- Feet
		elseif equipSlot == "INVTYPE_FEET" then
			return Tailoring:GetSlotIndex(L["Armor - Feet"])
		-- Wrists
		elseif equipSlot == "INVTYPE_WRIST" then
			return Tailoring:GetSlotIndex(L["Armor - Wrists"])
		-- Hand
		elseif equipSlot == "INVTYPE_HAND" then
			return Tailoring:GetSlotIndex(L["Armor - Hands"])
		-- Back
		elseif equipSlot == "INVTYPE_CLOAK" then
			return Tailoring:GetSlotIndex(L["Armor - Back"])
		else
			return Tailoring:GetSlotIndex(L["Other"])
		end
	-- Bags
	elseif iType == auctionClasses[3] then
		return Tailoring:GetSlotIndex(L["Bags"])
	-- Consumables
	elseif iType == auctionClasses[4] then
		return Tailoring:GetSlotIndex(L["Consumables"])
	-- Cloth
	elseif iType == auctionClasses[6] then
		return Tailoring:GetSlotIndex(L["Cloth"])
	else
		return Tailoring:GetSlotIndex(L["Other"])
	end
	
	return #Tailoring.slotList
end

Tailoring.slotList = {
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
	L["Cloth"],
	L["Other"]
}
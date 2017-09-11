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
-- Blacksmithing:HasProfession() - determines if the player is an blacksmith

-- The following "global" (within the addon) variables are initialized in this file:
-- Blacksmithing.slot - hardcoded list of the slot of every craft

-- ===================================================================================== --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Blacksmithing = TSM:NewModule("Blacksmithing", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is an blacksmith
function Blacksmithing:HasProfession()
	local professionIDs = {2018, 3100, 3538, 9785, 29844, 51300, 76666}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

function Blacksmithing:GetSlotIndex(slotName)
	for i, name in ipairs(Blacksmithing.slotList) do
		if name == slotName then
			return i
		end
	end
end

function Blacksmithing:GetSlot(itemID, _, _)
	if not itemID then return end
	
	local _, _, _, _, _, iType, subType, _, equipSlot = GetItemInfo(itemID)
	local auctionClasses = {GetAuctionItemClasses()}
	
	-- Weapon
	if iType == auctionClasses[1] then		
		-- Main Hand
		if equipSlot == "INVTYPE_WEAPONMAINHAND" then
			return Blacksmithing:GetSlotIndex(L["Weapon - Main Hand"])
		-- One Hand
		elseif equipSlot == "INVTYPE_WEAPON" then
			return Blacksmithing:GetSlotIndex(L["Weapon - One Hand"])
		-- Two Hand
		elseif equipSlot == "INVTYPE_2HWEAPON" then
			return Blacksmithing:GetSlotIndex(L["Weapon - Two Hand"])
		-- Thrown
		elseif equipSlot == "INVTYPE_THROWN" then
			return Blacksmithing:GetSlotIndex(L["Weapon - Thrown"])
		else
			return Blacksmithing:GetSlotIndex(L["Misc Items"])
		end
	-- Armor
	elseif iType == auctionClasses[2] then
		-- Head			 
		if equipSlot == "INVTYPE_HEAD" then
			return Blacksmithing:GetSlotIndex(L["Armor - Head"])
		-- Shoulder
		elseif equipSlot == "INVTYPE_SHOULDER" then
			return Blacksmithing:GetSlotIndex(L["Armor - Shoulders"])
		-- Chest
		elseif equipSlot == "INVTYPE_CHEST" then
			return Blacksmithing:GetSlotIndex(L["Armor - Chest"])
		-- Waist
		elseif equipSlot == "INVTYPE_WAIST" then
			return Blacksmithing:GetSlotIndex(L["Armor - Waist"])
		-- Legs
		elseif equipSlot == "INVTYPE_LEGS" then
			return Blacksmithing:GetSlotIndex(L["Armor - Legs"])
		-- Feet
		elseif equipSlot == "INVTYPE_FEET" then
			return Blacksmithing:GetSlotIndex(L["Armor - Feet"])
		-- Wrist
		elseif equipSlot == "INVTYPE_WRIST" then
			return Blacksmithing:GetSlotIndex(L["Armor - Wrists"])
		-- Hands
		elseif equipSlot == "INVTYPE_HAND" then
			return Blacksmithing:GetSlotIndex(L["Armor - Hands"])
		-- Shield
		elseif equipSlot == "INVTYPE_SHIELD" then
			return Blacksmithing:GetSlotIndex(L["Armor - Shield"])
		else
			return Blacksmithing:GetSlotIndex(L["Misc Items"])
		end
	-- Consumable
	elseif iType == auctionClasses[4] then
		local subClasses = {GetAuctionItemSubClasses(4)}
		
		if subType == subClasses[6] then
			return Blacksmithing:GetSlotIndex(L["Item Enhancements"])
		else
			return Blacksmithing:GetSlotIndex(L["Misc Items"])
		end
	else
		return Blacksmithing:GetSlotIndex(L["Misc Items"])
	end
	
	return #Blacksmithing.slotList
end

Blacksmithing.slotList = {
	L["Item Enhancements"], 
	L["Armor - Chest"], 
	L["Armor - Feet"], 
	L["Armor - Hands"],
	L["Armor - Head"], 
	L["Armor - Legs"], 
	L["Armor - Shield"], 
	L["Armor - Shoulders"], 
	L["Armor - Waist"], 
	L["Armor - Wrists"],
	L["Weapon - Main Hand"], 
	L["Weapon - One Hand"], 
	L["Weapon - Thrown"], 
	L["Weapon - Two Hand"], 
	L["Misc Items"], 
	L["Other"]
}

--[[
Item IDs that were once listed under 'Item Enhancements' and are now 'Other':
---
23529
12404
28421
3239
3241
7965
2862
18262
3240
25521
23559
23575
2863
2871
12643
23528
23576
7964
28420
]]
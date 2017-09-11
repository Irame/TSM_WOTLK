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
-- Cooking:HasProfession() - determines if the player is an tailor

-- The following "global" (within the addon) variables are initialized in this file:
-- Cooking.slot - hardcoded list of the slot of every craft

-- ===================================================================================== --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Cooking = TSM:NewModule("Cooking", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is an tailor
function Cooking:HasProfession()
	local professionIDs = {2550, 3102, 3413, 18260, 33359, 51296, 88053}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end


function Cooking:GetSlotIndex(slotName)
	for i, name in ipairs(Cooking.slotList) do
		if name == slotName then
			return i
		end
	end
end

function Cooking:GetSlot(itemID, _, _)
	if not itemID then return end
	
	local _, _, _, _, minLevel = GetItemInfo(itemID)
	
	if minLevel ~= nil then
		if minLevel <= 35 then
			return Cooking:GetSlotIndex(L["Level 1-35"])
		elseif minLevel <= 70 then
				return Cooking:GetSlotIndex(L["Level 36-70"])
		else
			return Cooking:GetSlotIndex(L["Level 71+"])
		end
	end
	
	return #Cooking.slotList
end

function Cooking:GetSlot2(itemID)
	if not itemID then return end
	return Cooking.slot[itemID] or #Cooking.slotList
end

Cooking.slotList = {
	L["Level 1-35"], 
	L["Level 36-70"], 
	L["Level 71+"], 
	L["Other"]
}
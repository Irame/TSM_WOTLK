-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Alchemy = TSM:NewModule("Alchemy", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is an alchemist
function Alchemy:HasProfession()
	local professionIDs = {2259, 3101, 3464, 11611, 28596, 51304, 80731}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

function Alchemy:GetSlotIndex(slotName)
	for i, name in ipairs(Alchemy.slotList) do
		if name == slotName then
			return i
		end
	end
end

function Alchemy:GetSlot(itemID, _, index)
	if not itemID then return end
	
	if GetTradeSkillTools(index) and itemID ~= 31080 then -- it requires some tool and is not mercurial stone
		return Alchemy:GetSlotIndex(L["Transmutes"])
	end
	
	local types = {GetAuctionItemClasses()}
	local subTypes = {GetAuctionItemSubClasses(4)}
	
	local name, _, rarity, _, _, iType, subType = GetItemInfo(itemID)
	if iType == types[4] then
		if subType == subTypes[2] then
			return Alchemy:GetSlotIndex(L["Potion"])
		elseif subType == subTypes[3] then
			return Alchemy:GetSlotIndex(L["Elixir"])
		elseif subType == subTypes[4] then
			return Alchemy:GetSlotIndex(L["Flask"])
		else
			return Alchemy:GetSlotIndex(L["Other Consumable"])
		end
	end
	
	return #Alchemy.slotList
end

Alchemy.slotList = {L["Elixir"], L["Potion"], L["Flask"], L["Other Consumable"], L["Transmutes"], L["Misc Items"], L["Other"]}
-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- The following functions are contained attached to this file:
-- Inscription:HasProfession() - determines if the player is a scribe

-- The following "global" (within the addon) variables are initialized in this file:
-- Inscription.slot - hardcoded list of the slot of every craft

-- ===================================================================================== --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local Inscription = TSM:NewModule("Inscription", "AceEvent-3.0")

local debug = function(...) TSM:Debug(...) end -- for debugging

-- determines if the player is a scribe
function Inscription:HasProfession()
	local professionIDs = {45357, 45358, 45359, 45360, 45361, 45363, 86008}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

local inkLookup = {[79254]=1, [61978]=2, [43126]=3, [43124]=4, [43122]=5, [43120]=6, [43118]=7, [43116]=8, [39774]=9}
function Inscription:GetSlot(itemID, mats)
	if not itemID then return end
	
	local inkID = 0
	for sID in pairs(mats) do
		if not TSM.Vendor:GetVendorPrice(sID) then
			inkID = sID
		end
	end
	
	local names = {GetAuctionItemClasses()}
	local classLookup = {}
	for i, v in pairs({GetAuctionItemSubClasses(5)}) do
		classLookup[v] = i
	end
	
	local name, _, rarity, _, _, iType, subType = GetItemInfo(itemID)
	if TSM.db.profile.inscriptionGrouping == 1 then
		if iType == names[5] and inkLookup[inkID] then
			return inkLookup[inkID]
		end
	elseif TSM.db.profile.inscriptionGrouping == 2 then
		if iType == names[5] and classLookup[subType] then
			return classLookup[subType]
		end
	else
		error("Invalid inscription grouping.")
	end
	
	local slotList = Inscription:GetSlotList()
	
	if iType == names[6] and subType == select(9, GetAuctionItemSubClasses(6)) then -- Trade Goods -> Parts
		for i=1, #slotList do
			if slotList[i] == L["Inks"] then
				return i
			end
		end
	end
	if iType == names[4] and subType == select(7, GetAuctionItemSubClasses(4)) then -- Consumable -> Scroll
		for i=1, #slotList do
			if slotList[i] == L["Scrolls"] then
				return i
			end
		end
	end
	if iType == names[2] then -- Armor
		for i=1, #slotList do
			if slotList[i] == L["Armor"] then
				return i
			end
		end
	end
	
	return #slotList
end

function Inscription:GetInk(itemID)
	for inkID, data in pairs(Inscription.inks) do
		if data.pigment == itemID then
			return inkID, data.pigmentPerInk
		end
	end
end

function Inscription:GetInkMats(itemID)
	if not itemID then return end
	
	return Inscription.inks[itemID]
end

function Inscription:GetInkFromPigment(pigmentID)
	for inkID, data in pairs(Inscription.inks) do
		if data.pigment == pigmentID then
			return inkID, data
		end
	end
end

function Inscription:GetSlotList()
	local tableNum = TSM.db.profile.inscriptionGrouping
	return Inscription["slotList"..tableNum]
end

Inscription.slotList1 = {L["Ink of Dreams"], L["Blackfallow Ink"], L["Ink of the Sea"], L["Ethereal Ink"], L["Shimmering Ink"], L["Celestial Ink"], L["Jadefire Ink"],
	L["Lion's Ink"], L["Midnight Ink"], L["Inks"], L["Scrolls"], L["Armor"], L["Other"]}

Inscription.slotList2 = {L["Inks"], L["Scrolls"], L["Armor"], L["Other"]}
	
do
	local oldList = CopyTable(Inscription.slotList2)
	Inscription.slotList2 = {GetAuctionItemSubClasses(5)}
	for i=1, #oldList do
		tinsert(Inscription.slotList2, oldList[i])
	end
end

Inscription.inks = CopyTable(TSMAPI.DestroyingData.mill[1])
Inscription.inks[61981] = { -- Inferno Ink
	herbs = {
		{itemID = 52983, pigmentPerMill = 0.5},
		{itemID = 52984, pigmentPerMill = 0.5},
		{itemID = 52985, pigmentPerMill = 0.5},
		{itemID = 52986, pigmentPerMill = 0.5},
		{itemID = 52987, pigmentPerMill = 0.8},
		{itemID = 52988, pigmentPerMill = 0.8},
	},
	pigment = 61980,
	pigmentPerInk = 2,
}
Inscription.inks[43115] = { -- hunter's ink
	herbs = {
		{itemID = 785, pigmentPerMill = 0.25},
		{itemID = 2450, pigmentPerMill = 0.25},
		{itemID = 2452, pigmentPerMill = 2.5},
		{itemID = 2453, pigmentPerMill = 0.5},
		{itemID = 3820, pigmentPerMill = 0.5},
	},
	pigment = 43103,
	pigmentPerInk = 1,
}
Inscription.inks[43119] = { -- royal ink
	herbs = {
		{itemID = 3819, pigmentPerMill = 0.5},
		{itemID = 3818, pigmentPerMill = 0.5},
		{itemID = 3821, pigmentPerMill = 0.25},
		{itemID = 3358, pigmentPerMill = 0.25},
	},
	pigment = 43105,
	pigmentPerInk = 1,
}
Inscription.inks[43121] = { -- fiery ink
	herbs = {
		{itemID = 8845, pigmentPerMill = 0.5},
		{itemID = 8846, pigmentPerMill = 0.5},
		{itemID = 8839, pigmentPerMill = 0.5},
		{itemID = 8836, pigmentPerMill = 0.5},
		{itemID = 4625, pigmentPerMill = 0.5},
		{itemID = 8838, pigmentPerMill = 0.5},
		{itemID = 8831, pigmentPerMill = 0.5},
	},
	pigment = 43106,
	pigmentPerInk = 1,
}
Inscription.inks[43125] = { -- darkflame ink
	herbs = {
		{itemID = 22792, pigmentPerMill = 0.5},
		{itemID = 22791, pigmentPerMill = 0.5},
		{itemID = 22790, pigmentPerMill = 0.5},
		{itemID = 22793, pigmentPerMill = 0.5},
		{itemID = 22786, pigmentPerMill = 0.25},
		{itemID = 22785, pigmentPerMill = 0.25},
		{itemID = 22787, pigmentPerMill = 0.25},
		{itemID = 22789, pigmentPerMill = 0.25},
	},
	pigment = 43108,
	pigmentPerInk = 1,
}
Inscription.inks[43123] = { -- ink of the sky
	herbs = {
		{itemID = 13467, pigmentPerMill = 0.5},
		{itemID = 13466, pigmentPerMill = 0.5},
		{itemID = 13465, pigmentPerMill = 0.5},
		{itemID = 13463, pigmentPerMill = 0.25},
		{itemID = 13464, pigmentPerMill = 0.25},
	},
	pigment = 43107,
	pigmentPerInk = 1,
}
Inscription.inks[43127] = { -- snowfall ink
	herbs = {
		{itemID = 37921, pigmentPerMill = 0.25},
		{itemID = 36901, pigmentPerMill = 0.25},
		{itemID = 36907, pigmentPerMill = 0.25},
		{itemID = 36904, pigmentPerMill = 0.25},
		{itemID = 39970, pigmentPerMill = 0.25},
		{itemID = 39969, pigmentPerMill = 0.25},
		{itemID = 36903, pigmentPerMill = 0.5},
		{itemID = 36906, pigmentPerMill = 0.5},
		{itemID = 36905, pigmentPerMill = 0.5},
	},
	pigment = 43109,
	pigmentPerInk = 2,
}
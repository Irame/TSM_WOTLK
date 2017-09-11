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
local Smelting = TSM:NewModule("Smelting", "AceEvent-3.0")

-- determines if the player is an leatherworkers
function Smelting:HasProfession()
	local professionIDs = {2656}
	for _, id in pairs(professionIDs) do
		if IsSpellKnown(id) then return true end
	end
end

function Smelting:GetSlot(itemID)
	if not itemID then return end
	return Smelting.slot[itemID] or #Smelting.slotList
end

Smelting.slotList = {L["Bars"], L["Other"]}

Smelting.slot = {
	[2840]=1, -- Bars
	[2842]=1, -- Bars
	[3576]=1, -- Bars
	[2841]=1, -- Bars
	[3575]=1, -- Bars
	[3577]=1, -- Bars
	[3859]=1, -- Bars
	[3860]=1, -- Bars
	[12359]=1, -- Bars
	[11371]=1, -- Bars
	[6037]=1, -- Bars
	[12655]=1, -- Bars
	[23445]=1, -- Bars
	[23448]=1, -- Bars
	[17771]=1, -- Bars
	[23573]=1, -- Bars
	[23446]=1, -- Bars
	[23449]=1, -- Bars
	[35128]=1, -- Bars
	[23447]=1, -- Bars
	[36916]=1, -- Bars
	[36913]=1, -- Bars
	[37663]=1, -- Bars
	[41163]=1, -- Bars
	[54849]=1, -- Bars
	[53039]=1, -- Bars
	[52186]=1, -- Bars
	[51950]=1, -- Bars
}
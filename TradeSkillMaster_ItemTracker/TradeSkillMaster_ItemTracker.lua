-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_ItemTracker", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ItemTracker")

TSM.version = GetAddOnMetadata("TradeSkillMaster_ItemTracker","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_ItemTracker", "Version") -- current version of the addon
TSM.versionKey = 2

-- default values for the savedDB
local savedDBDefaults = {
	-- any global 
	global = {
	},
	
	-- data that is stored per realm/faction combination
	factionrealm = {
		characters = {},
		guilds = {},
		charactersToSync = {},
	},
	
	-- data that is stored per user profile
	profile = {
		tooltip = "simple",
	},
}

local characterDefaults = { -- anything added to the characters table will have these defaults
	bags = {},
	bank = {},
	auctions = {},
	guild = nil,
}
local guildDefaults = {
	items = {},
	characters = {},
}

-- Called once the player has loaded into the game
-- Anything that needs to be done in order to initialize the addon should go here
function TSM:OnInitialize()
	-- create shortcuts to all the modules
	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end
	
	-- load the saved variables table into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_ItemTrackerDB", savedDBDefaults, true)
	TSM.characters = TSM.db.factionrealm.characters
	TSM.guilds = TSM.db.factionrealm.guilds
	
	if not next(TSM.characters) then
		TSMAPI:CreateTimeDelay(L["trackerMessage"], 1, function() TSM:Print(L["If you previously used TSM_Gathering, note that inventory data was not transfered to TSM_ItemTracker and will not show up until you log onto each character and visit the bank / gbank / auction house."]) end)
	end
	
	-- register the module with TSM
	TSMAPI:RegisterReleasedModule("TradeSkillMaster_ItemTracker", TSM.version, GetAddOnMetadata("TradeSkillMaster_ItemTracker", "Author"),
		GetAddOnMetadata("TradeSkillMaster_ItemTracker", "Notes"), TSM.versionKey)
		
	TSMAPI:RegisterIcon("ItemTracker", "Interface\\Icons\\INV_Misc_Gem_Variety_01",
		function(...) TSM.Config:Load(...) end, "TradeSkillMaster_ItemTracker")
		
	if not TSM.characters[UnitName("player")] then
		TSM.characters[UnitName("player")] = characterDefaults
	end
	if GetGuildInfo("player") and not TSM.guilds[GetGuildInfo("player")] then
		TSM.guilds[GetGuildInfo("player")] = guildDefaults
	end
	
	TSM.Data:Initialize()
	TSM.Comm:DoSync()
	
	if TSM.db.profile.tooltip ~= "hide" then
		TSMAPI:RegisterTooltip("TradeSkillMaster_ItemTracker", function(...) return TSM:LoadTooltip(...) end)
	end
	
	local itemIDs = {}
	for _, data in pairs(TSM.characters) do
		for itemID in pairs(data.bags) do
			itemIDs[itemID] = true
		end
		for itemID in pairs(data.bank) do
			itemIDs[itemID] = true
		end
		for itemID in pairs(data.auctions) do
			itemIDs[itemID] = true
		end
	end
	for _, data in pairs(TSM.guilds) do
		for itemID in pairs(data.items) do
			itemIDs[itemID] = true
		end
	end
	TSMAPI:GetItemInfoCache(itemIDs, true)
end

function TSM:LoadTooltip(itemID)
	if TSM.db.profile.tooltip == "simple" then
		local player, alts = TSM.Data:GetPlayerTotal(itemID)
		local guild = TSM.Data:GetGuildTotal(itemID)
		local auctions = TSM.Data:GetAuctionsTotal(itemID)
		local text = format(L["ItemTracker: %s on player, %s on alts, %s in guild banks, %s on AH"], "|cffffffff"..player.."|r", "|cffffffff"..alts.."|r", "|cffffffff"..guild.."|r", "|cffffffff"..auctions.."|r")
		
		return {text}
	elseif TSM.db.profile.tooltip == "full" then
		local text = {}
		
		for name, data in pairs(TSM.characters) do
			local bags = data.bags[itemID] or 0
			local bank = data.bank[itemID] or 0
			local auctions = data.auctions[itemID] or 0
			
			local totalText = "|cffffffff"..(bags+bank+auctions).."|r"
			local bagText = "|cffffffff"..bags.."|r"
			local bankText = "|cffffffff"..bank.."|r"
			local auctionText = "|cffffffff"..auctions.."|r"
		
			if (bags + bank + auctions) > 0 then
				tinsert(text, format(L["%s: %s (%s in bags, %s in bank, %s on AH)"], name, totalText, bagText, bankText, auctionText))
			end
		end
		
		for name, data in pairs(TSM.guilds) do
			local gbank = data.items[itemID] or 0
			
			local gbankText = "|cffffffff"..(gbank).."|r"
		
			if gbank > 0 then
				tinsert(text, format(L["%s: %s in guild bank"], name, gbankText))
			end
		end
		
		return text
	end
end

-- Make sure the item isn't soulbound
local scanTooltip
local resultsCache = {}
function TSM:IsSoulbound(bag, slot, itemID)
	local slotID = tostring(bag) .. tostring(slot) .. tostring(itemID)
	if resultsCache[slotID] then return resultsCache[slotID] end
	
	if not scanTooltip then
		scanTooltip = CreateFrame("GameTooltip", "TSMItemTrackerScanTooltip", UIParent, "GameTooltipTemplate")
		scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	scanTooltip:ClearLines()
	
	if bag < 0 or bag > NUM_BAG_SLOTS then
		scanTooltip:SetHyperlink("item:"..itemID)
	else
		scanTooltip:SetBagItem(bag, slot)
	end
	
	for id=1, scanTooltip:NumLines() do
		local text = _G["TSMItemTrackerScanTooltipTextLeft" .. id]
		if text and ((text:GetText() == ITEM_BIND_ON_PICKUP and id < 4) or text:GetText() == ITEM_SOULBOUND or text:GetText() == ITEM_BIND_QUEST) then
			resultsCache[slotID] = true
			return true
		end
	end
	
	resultsCache[slotID] = nil
	return false
end
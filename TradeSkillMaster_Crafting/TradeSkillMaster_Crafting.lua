-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_Crafting", "AceEvent-3.0", "AceConsole-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
TSM.version = GetAddOnMetadata("TradeSkillMaster_Crafting","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_Crafting", "Version") -- current version of the addon

TSM.tradeSkills = {{name="Enchanting", spellID=7411}, {name="Inscription", spellID=45357},
	{name="Jewelcrafting", spellID=25229}, {name="Alchemy", spellID=2259},
	{name="Blacksmithing", spellID=2018}, {name="Leatherworking", spellID=2108},
	{name="Tailoring", spellID=3908}, {name="Engineering", spellID=4036},
	{name="Cooking", spellID=2550}}--, {name="Smelting", spellID=2656}}

local GOLD_TEXT = "|cffffd70fg|r"
local SILVER_TEXT = "|cffb7b7bfs|r"
local COPPER_TEXT = "|cffeda55fc|r"

-- default values for the savedDB
local savedDBDefaults = {
	global = {
		treeStatus = {[2] = true, [5] = true},
		queueSort = "profit",
		queueSortDescending = true,
		crossAccountCraftingCosts = {},
	},
	-- data that is stored per user profile
	profile = {
		profitPercent = 0, -- percentage to subtract from buyout when calculating profit (5% = AH cut)
		matCostSource = "DBMarket", -- how to calculate the cost of materials
		craftCostSource = "DBMinBuyout",
		craftHistory = {}, -- stores a history of what crafts were crafted
		queueMinProfitGold = {default = 50},
		queueMinProfitPercent = {default = 0.5},
		restockAH = true,
		altAddon = "ItemTracker",
		altGuilds = {},
		altCharacters = {},
		queueProfitMethod = {default = "gold"},
		doubleClick = 2,
		maxRestockQuantity = {default = 3},
		seenCountFilterSource = "",
		seenCountFilter = 0,
		ignoreSeenCountFilter = {},
		minRestockQuantity = {default = 1},
		limitIlvl = {default = false},
 		minilvlToCraft = {default = 1},
		dontQueue = {},
		craftManagementWindowScale = 1,
		inscriptionGrouping = 2,
		lastScan = {},
		alwaysQueue = {},
		unknownProfitMethod = {default = "unknown"},
		enableNewTradeskills = false,
		showPercentProfit = true,
		tooltip = true,
		playerProfessionInfo = {},
		playerProfessionInfo = {},
 		assumeVendorInBags = false,
 		limitVendorItemPrice = false,
 		maxVendorPrice = 1000,
		craftingCostSources = {},
		craftingCostTarget = "",
		secondaryPriceSource = "none",
		lowestPriceSource = false,
	},
}

-- Called once the player has loaded WOW.
function TSM:OnEnable()
	-- create shortcuts to TradeSkillMaster_Crafting's modules
	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end
	
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_CraftingDB", savedDBDefaults, true)
	TSM.Data:Initialize() -- setup TradeSkillMaster_Crafting's internal data table using some savedDB data
	
	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Crafting", TSM.version, GetAddOnMetadata("TradeSkillMaster_Crafting", "Author"),
		GetAddOnMetadata("TradeSkillMaster_Crafting", "Notes"))
	TSMAPI:RegisterData("shopping", TSM.Queue.GetMatsForQueue)
	TSMAPI:RegisterData("craftingcost", TSM.GetCraftingCost)
	TSMAPI:RegisterData("professionitems", TSM.GetProfessionItems)
	TSMAPI:AddPriceSource("Crafting", L["Crafting Cost"], function(itemLink, itemID) return TSMAPI:GetData("craftingcost", itemID) end)
	
	if TSM.db.profile.tooltip then
		TSMAPI:RegisterTooltip("TradeSkillMaster_Crafting", function(...) return TSM:LoadTooltip(...) end)
	end
	
	-- Gathering was renamed to "ItemTracker" with the release of TSM
	if TSM.db.profile.altAddon == "Gathering" then
		TSM.db.profile.altAddon = "ItemTracker"
	end
end

function TSM:LoadTooltip(itemID)
	for _, profession in pairs(TSM.tradeSkills) do
		if TSM.Data[profession.name].crafts[itemID] then
			local cost, _, profit = TSM.Data:GetCraftPrices(itemID, profession.name)
			
			local preProfitText = ""
			if profit and profit <= 0 then
				preProfitText = "-"
				profit = abs(profit)
			end
			local costText = TSM:FormatTextMoney(cost, nil, true, true) or "|cffffffff---|r"
			local profitText = preProfitText..(TSM:FormatTextMoney(profit, nil, true, true) or "|cffffffff---|r")
			local text1 = format(L["Crafting Cost: %s (%s profit)"], costText, profitText)
			
			return {text1}
		end
	end
end

function TSM:IsEnchant(link)
	if not link then return end
	return strfind(link, "enchant:") and true
end

function TSM:GetDBValue(key, profession, itemID)
	return (itemID and TSM.db.profile[key][itemID]) or (profession and TSM.db.profile[key][profession]) or TSM.db.profile[key].default
end

local equivItems = {
	{lower=10938, upper=10939, ratio=3}, -- Lesser/Greater Magic Essence
	{lower=10998, upper=11082, ratio=3}, -- Lesser/Greater Astral Essence
	{lower=11134, upper=11135, ratio=3}, -- Lesser/Greater Mystic Essence
	{lower=11174, upper=11175, ratio=3}, -- Lesser/Greater Nether Essence
	{lower=16202, upper=16203, ratio=3}, -- Lesser/Greater Eternal Essence
	{lower=22447, upper=22446, ratio=3}, -- Lesser/Greater Planar Essence
	{lower=34056, upper=34055, ratio=3}, -- Lesser/Greater Cosmic Essence
	{lower=52718, upper=52719, ratio=3}, -- Lesser/Greater Celestial Essence
	{lower=37700, upper=36523, ratio=10}, -- Crystallized/Eternal Air
	{lower=37701, upper=35624, ratio=10}, -- Crystallized/Eternal Earth
	{lower=37702, upper=36860, ratio=10}, -- Crystallized/Eternal Fire
	{lower=37703, upper=35627, ratio=10}, -- Crystallized/Eternal Shadow
	{lower=37704, upper=35625, ratio=10}, -- Crystallized/Eternal Life
	{lower=37705, upper=35622, ratio=10}, -- Crystallized/Eternal Water
}
function TSM:GetEquivItem(itemID)
	for _, itemPair in ipairs(equivItems) do
		if itemID == itemPair.lower then
			return itemPair.upper, TSMAPI:SafeDivide(1, itemPair.ratio)
		elseif itemID == itemPair.upper then
			return itemPair.lower, itemPair.ratio
		end
	end
end

local BIG_NUMBER = 100000000000 -- 10 million gold
function TSM:FormatTextMoney(copper, textColor, noCopper, noSilver, noColor)
	if not copper then return end
	if copper == 0 or copper > BIG_NUMBER then return end
	
	local gold = floor(copper / COPPER_PER_GOLD)
	local silver = floor((copper - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(math.fmod(copper, COPPER_PER_SILVER))
	local text = ""
	
	-- Add gold
	if gold > 0 then
		if noColor then
			text = format("%s", gold.."g")
		elseif textColor then
			text = format("%s%s", textColor..gold.."|r", (noColor and "g" or GOLD_TEXT).." ")
		else
			text = format("%s%s", gold, (noColor and "g" or GOLD_TEXT).." ")
		end
	end
	
	-- Add silver
	if (not noSilver or gold == 0) and (silver > 0 or copper > 0) then
		if noColor then
			text = format("%s%s", text, silver.."s")
		elseif textColor then
			text = format("%s%s%s", text, textColor..silver.."|r", (noColor and "s" or SILVER_TEXT).." ")
		else
			text = format("%s%s%s", text, silver, (noColor and "s" or SILVER_TEXT).." ")
		end
	end
	
	-- Add copper if we have no silver/gold found, or if we actually have copper
	if (not noCopper or (silver == 0 and gold==0)) and (text == "" or copper > 0) then
		if noColor then
			text = format("%s%s", text, copper.."c")
		elseif textColor then
			text = format("%s%s%s", text, textColor..copper.."|r", (noColor and "c" or COPPER_TEXT))
		else
			text = format("%s%s%s", text, copper, (noColor and "c" or COPPER_TEXT))
		end
	end
	
	return text:trim()
end

function TSM:GetMoneyValue(value)
	local gold = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)g|r") or string.match(value, "([0-9]+)g")) or 0
	local silver = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)s|r") or string.match(value, "([0-9]+)s")) or 0
	local copper = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)c|r") or string.match(value, "([0-9]+)c")) or 0
	
	return (gold or silver or copper) and (gold*COPPER_PER_GOLD + silver*SILVER_PER_GOLD + copper)
end



function TSM:GetItemMarketPrice(itemID, itemType)
	if not itemID then return end
	local itemLink = select(2, GetItemInfo(itemID)) or itemID
	local source = (itemType == "mat" and TSM.db.profile.matCostSource) or (itemType == "craft" and TSM.db.profile.craftCostSource)
	local itemValue = TSMAPI:GetItemValue(itemLink, source)
	
	if TSM.db.profile.secondaryPriceSource ~= "none" then
		local secondaryItemValue = TSMAPI:GetItemValue(itemLink, TSM.db.profile.secondaryPriceSource)
		if not itemValue then
			itemValue = secondaryItemValue
		elseif TSM.db.profile.lowestPriceSource then
			if secondaryItemValue then
				itemValue = min(itemValue, secondaryItemValue)
			end
		end
	end
	
	return itemValue
end

function TSM:GetSeenCount(itemID)
	if AucAdvanced and TSM.db.profile.seenCountFilterSource == "Auctioneer" then
		local link = select(2, GetItemInfo(itemID)) or itemID
		return select(2, AucAdvanced.API.GetMarketValue(link))
	elseif TSM.db.profile.seenCountFilterSource == "AuctionDB" then
		return TSMAPI:GetData("seenCount", itemID)
	end
end

-- returns a table containing a list of all itemIDs of mats for this profession
function TSM:GetMats(mode)
	local matTemp, returnTbl = {}, {}
	
	for _, chant in pairs(TSM.Data[mode].crafts) do
		for matID in pairs(chant.mats) do
			if not matTemp[matID] then
				tinsert(returnTbl, matID)
			end
			matTemp[matID] = true 
		end
	end
	
	sort(returnTbl)
	return returnTbl
end

-- takes a non-integer-indexed table and returns a sorted integer-indexed table
function TSM:GetSortedData(oTable, sortFunc)
	local temp = {}
	for index, data in pairs(oTable) do
		local tTemp = {}
		for i, v in pairs(data) do tTemp[i] = v end
		tTemp.originalIndex = index
		tinsert(temp, tTemp)
	end
	
	sort(temp, sortFunc)
	
	return temp
end

-- returns a list of all items associated with a profession
function TSM:GetProfessionItems(profession, list)
	local items = list or {}
	if not TSM.Data[profession] or type(items) ~= "table" then return end
	
	for itemID in pairs(TSM.Data[profession].crafts) do
		items[itemID] = true
	end
	
	for itemID in pairs(TSM.Data[profession].mats) do
		items[itemID] = true
	end
	
	return items
end

function TSM:GetCraftingCost(itemID, isMat)
	if not isMat then
		for _, skill in pairs(TSM.tradeSkills) do
			local mode = skill.name
			if TSM.Data[mode].crafts[itemID] then
				return TSM.Data:GetCraftCost(itemID, mode)
			end
		end
	end
	for _, skill in pairs(TSM.tradeSkills) do
		local mode = skill.name
		if TSM.Data[mode].mats[itemID] then
			return TSM.Data:GetMatCost(mode, itemID)
		end
	end
	
	return TSM.db.global.crossAccountCraftingCosts[itemID]
end

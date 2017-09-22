-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_Shopping", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0")

local settingsInfo = {
	version = 3,
	global = {
		sniperVendorPrice = { type = "boolean", default = true, lastModifiedVersion = 2 },
		postBidPercent = { type = "number", default = 0.95, lastModifiedVersion = 1 },
		minDeSearchLvl = { type = "number", default = 1, lastModifiedVersion = 1 },
		maxDeSearchLvl = { type = "number", default = 735, lastModifiedVersion = 1 },
		maxDeSearchPercent = { type = "number", default = 1, lastModifiedVersion = 1 },
		postUndercut = { type = "string", default = "1c", lastModifiedVersion = 3 },
		normalPostPrice = { type = "string", default = "150% dbmarket", lastModifiedVersion = 1 },
		marketValueSource = { type = "string", default = "dbmarket", lastModifiedVersion = 1 },
		sniperCustomPrice = { type = "string", default = "0c", lastModifiedVersion = 1 },
		sniperSound = { type = "string", default = TSMAPI:GetNoSoundKey(), lastModifiedVersion = 1 },
		savedSearches = { type = "table", default = {}, lastModifiedVersion = 1 },
		helpPlatesShown = { type = "table", default = { auction = nil }, lastModifiedVersion = 1 },
	},
}
local tooltipDefaults = {
	maxPrice = false,
}
local operationDefaults = {
	restockQuantity = 0,
	maxPrice = 1,
	evenStacks = nil,
	showAboveMaxPrice = nil,
	includeInSniper = nil,
	restockSources = {},
}

function TSM:OnInitialize()
	if TradeSkillMasterModulesDB then
		TradeSkillMasterModulesDB.Shopping = TradeSkillMaster_ShoppingDB
	end

	-- load settings
	TSM.db = TSMAPI.Settings:Init("TradeSkillMaster_ShoppingDB", settingsInfo)

	for name, module in pairs(TSM.modules) do
		TSM[name] = module
	end

	-- register with TSM
	TSM:RegisterModule()

	-- TSM3 changes
	for _ in TSMAPI:GetTSMProfileIterator() do
		for _, operation in pairs(TSM.operations) do
			operation.restockQuantity = operation.restockQuantity or operationDefaults.restockQuantity
			operation.restockSources = operation.restockSources or operationDefaults.restockSources
		end
	end
	
	-- fix patch 7.3 sound changes
	local sounds = TSMAPI:GetSounds()
	if not sounds[TSM.db.global.sniperSound] then
		TSM.db.global.sniperSound = TSM.NO_SOUND_KEY
	end
end

-- registers this module with TSM by first setting all fields and then calling TSMAPI:NewModule().
function TSM:RegisterModule()
	TSM.operations = { maxOperations = 1, callbackOptions = "Options:GetOperationOptionsInfo", callbackInfo = "GetOperationInfo", defaults = operationDefaults }
	TSM.auctionTab = { callbackShow = "AuctionTab:Show", callbackHide = "AuctionTab:Hide" }
	TSM.moduleOptions = { callback = "Options:Load" }
	TSM.moduleAPIs = {
		{ key = "startSearchGathering", callback = "StartSearchGathering" },
		{ key = "startSearchAuctioning", callback = "StartSearchAuctioning" },
	}
	TSM.tooltip = { callbackLoad = "LoadTooltip", callbackOptions = "Options:LoadTooltipOptions", defaults = tooltipDefaults }

	TSMAPI:NewModule(TSM)
end

function TSM:GetOperationInfo(operationName)
	TSMAPI.Operations:Update("Shopping", operationName)
	local operation = TSM.operations[operationName]
	if not operation then return end

	if operation.showAboveMaxPrice and operation.evenStacks then
		return format(L["Shopping for even stacks including those above the max price"])
	elseif operation.showAboveMaxPrice then
		return format(L["Shopping for auctions including those above the max price."])
	elseif operation.evenStacks then
		return format(L["Shopping for even stacks with a max price set."])
	else
		return format(L["Shopping for auctions with a max price set."])
	end
end

function TSM:LoadTooltip(itemString, quantity, options, moneyCoins, lines)
	if not options.maxPrice then return end -- only 1 tooltip option
	itemString = TSMAPI.Item:ToBaseItemString(itemString, true)
	local numStartingLines = #lines

	local operationName = TSMAPI.Operations:GetFirstByItem(itemString, "Shopping")
	if not operationName or not TSM.operations[operationName] then return end
	TSMAPI.Operations:Update("Shopping", operationName)

	local maxPrice = TSMAPI:GetCustomPriceValue(TSM.operations[operationName].maxPrice, itemString)
	if maxPrice then
		local priceText = (TSMAPI:MoneyToString(maxPrice, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil) or "|cffffffff---|r")
		tinsert(lines, { left = "  " .. L["Max Shopping Price:"], right = format("%s", priceText) })
	end

	if #lines > numStartingLines then
		tinsert(lines, numStartingLines + 1, "|cffffff00TSM Shopping:|r")
	end
end

function TSM:StartSearchGathering(itemString, quantity, callback, disableCrafting, ignoreDE, even)
	TSMAPI:Assert(itemString and quantity and callback)
	local searchInfo = { item = itemString, extraInfo = { searchType = "apiGathering", maxQuantity = quantity, buyCallback = callback }, searchBoxText = "~"..L["gathering"].."~" }
	if even then
		searchInfo.extraInfo.evenOnly = true
	end
	if not disableCrafting and TSMAPI.Conversions:GetSourceItems(itemString) then
		-- do crafting mode search
		searchInfo.searchMode = "crafting"
		if ignoreDE then
			searchInfo.extraInfo.ignoreDisenchant = true
		end
	else
		-- do normal mode search
		searchInfo.searchMode = "normal"
	end
	return TSM.AuctionTab:StartSearch(searchInfo)
end

function TSM:StartSearchAuctioning(itemString, database, callback, filterFunc)
	TSMAPI:Assert(itemString and database and callback)
	local searchInfo = { item = itemString, searchMode = "normal", extraInfo = { searchType = "apiAuctioning", database = database, filterFunc = filterFunc, buyCallback = callback }, searchBoxText = "~"..L["auctioning"].."~" }
	return TSM.AuctionTab:StartSearch(searchInfo)
end

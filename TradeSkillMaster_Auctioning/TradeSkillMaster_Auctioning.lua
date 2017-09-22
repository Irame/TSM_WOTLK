-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_Auctioning", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
TSM.operationLookup = {}
TSM.operationNameLookup = {}


local settingsInfo = {
	version = 1,
	global = {
		cancelWithBid = { type = "boolean", default = false, lastModifiedVersion = 1 },
		disableInvalidMsg = { type = "boolean", default = false, lastModifiedVersion = 1 },
		roundNormalPrice = { type = "boolean", default = false, lastModifiedVersion = 1 },
		matchWhitelist = { type = "boolean", default = true, lastModifiedVersion = 1 },
		priceColumn = { type = "number", default = 1, lastModifiedVersion = 1 },
		scanCompleteSound = { type = "string", default = TSMAPI:GetNoSoundKey(), lastModifiedVersion = 1 },
		confirmCompleteSound = { type = "string", default = TSMAPI:GetNoSoundKey(), lastModifiedVersion = 1 },
		helpPlatesShown = { type = "table", default = { selection = nil }, lastModifiedVersion = 1 },
	},
	factionrealm = {
		whitelist = { type = "table", default = {}, lastModifiedVersion = 1 },
		player = { type = "table", default = {}, lastModifiedVersion = 1 },
	},
}
local tooltipDefaults = {
	operationPrices = false,
}
local operationDefaults = {
	-- general
	matchStackSize = nil,
	blacklist = "",
	ignoreLowDuration = 0,
	-- post
	stackSize = 1,
	stackSizeIsCap = nil,
	postCap = 1,
	keepQuantity = 0,
	keepQtySources = {},
	maxExpires = 0,
	duration = 24,
	bidPercent = 1,
	undercut = 1,
	minPrice = 50000,
	maxPrice = 5000000,
	normalPrice = 1000000,
	priceReset = "none",
	aboveMax = "normalPrice",
	-- cancel
	cancelUndercut = true,
	keepPosted = 0,
	cancelRepost = true,
	cancelRepostThreshold = 10000,
	-- reset
	resetEnabled = nil,
	resetMaxQuantity = 5,
	resetMaxInventory = 10,
	resetMaxCost = 500000,
	resetMinProfit = 500000,
	resetResolution = 100,
	resetMaxItemCost = 1000000,
}

-- Addon loaded
function TSM:OnInitialize()
	if TradeSkillMasterModulesDB then
		TradeSkillMasterModulesDB.Auctioning = TradeSkillMaster_AuctioningDB
	end

	-- load settings
	TSM.db = TSMAPI.Settings:Init("TradeSkillMaster_AuctioningDB", settingsInfo)

	for name, module in pairs(TSM.modules) do
		TSM[name] = module
	end

	-- Add this character to the alt list so it's not undercut by the player
	TSM.db.factionrealm.player[UnitName("player")] = true

	-- register this module with TSM
	TSM:RegisterModule()

	for _ in TSMAPI:GetTSMProfileIterator() do
		for _, operation in pairs(TSM.operations) do
			operation.resetMaxInventory = operation.resetMaxInventory or operationDefaults.resetMaxInventory
			operation.aboveMax = operation.aboveMax or operationDefaults.aboveMax
			operation.keepQuantity = operation.keepQuantity or operationDefaults.keepQuantity
			operation.keepQtySources = operation.keepQtySources or operationDefaults.keepQtySources
			operation.maxExpires = operation.maxExpires or operationDefaults.maxExpires
			operation.blacklist = operation.blacklist or ""
		end
	end
	
	-- fix patch 7.3 sound changes
	local sounds = TSMAPI:GetSounds()
	if not sounds[TSM.db.global.scanCompleteSound] then
		TSM.db.global.scanCompleteSound = TSM.NO_SOUND_KEY
	end
	if not sounds[TSM.db.global.confirmCompleteSound] then
		TSM.db.global.confirmCompleteSound = TSM.NO_SOUND_KEY
	end
end

-- registers this module with TSM by first setting all fields and then calling TSMAPI:NewModule().
function TSM:RegisterModule()
	TSM.operations = { maxOperations = 5, callbackOptions = "Options:GetOperationOptionsInfo", callbackInfo = "GetOperationInfo", defaults = operationDefaults}
	TSM.auctionTab = { callbackShow = "GUI:ShowSelectionFrame", callbackHide = "GUI:HideSelectionFrame" }
	TSM.moduleOptions = {callback="Options:Load"}
	TSM.bankUiButton = { callback = "Util:createTab" }
	TSM.tooltip = {callbackLoad="LoadTooltip", callbackOptions="Options:LoadTooltipOptions", defaults=tooltipDefaults}
	TSM.moduleAPIs = {
		{key="getMinPrice", callback="GetMinPrice"},
		{key="getPostCap", callback="GetPostCap"},
	}

	TSMAPI:NewModule(TSM)
end

function TSM:GetMinPrice(item)
	local itemString = TSMAPI.Item:ToItemString(item)
	if not itemString then return end
	local operationName = TSMAPI.Operations:GetFirstByItem(itemString, "Auctioning")
	if not operationName then return end
	TSMAPI.Operations:Update("Auctioning", operationName)
	local operation = TSM.operations[operationName]
	if not operation then return end
	return TSM.Util:GetMinPrice(operation, itemString)
end

function TSM:GetPostCap(item)
	local itemString = TSMAPI.Item:ToItemString(item)
	if not itemString then return end
	local operationName = TSMAPI.Operations:GetFirstByItem(itemString, "Auctioning")
	if not operationName then return end
	TSMAPI.Operations:Update("Auctioning", operationName)
	local operation = TSM.operations[operationName]
	if not operation then return end
	return operation.postCap
end

function TSM:GetOperationInfo(operationName)
	TSMAPI.Operations:Update("Auctioning", operationName)
	local operation = TSM.operations[operationName]
	if not operation then return end
	local parts = {}

	-- get the post string
	if operation.postCap == 0 then
		tinsert(parts, L["No posting."])
	else
		tinsert(parts, format(L["Posting %d stack(s) of %d for %d hours."], operation.postCap, operation.stackSize, operation.duration))
	end

	-- get the cancel string
	if operation.cancelUndercut and operation.cancelRepost then
		tinsert(parts, format(L["Canceling undercut auctions and to repost higher."]))
	elseif operation.cancelUndercut then
		tinsert(parts, format(L["Canceling undercut auctions."]))
	elseif operation.cancelRepost then
		tinsert(parts, format(L["Canceling to repost higher."]))
	else
		tinsert(parts, L["Not canceling."])
	end

	-- get the reset string
	if operation.resetEnabled then
		tinsert(parts, L["Resetting enabled."])
	else
		tinsert(parts, L["Not resetting."])
	end
	return table.concat(parts, " ")
end

function TSM:LoadTooltip(itemString, quantity, options, moneyCoins, lines)
	if not options.operationPrices then return end -- only 1 tooltip option
	itemString = TSMAPI.Item:ToBaseItemString(itemString, true)
	local numStartingLines = #lines

	-- get operation
	local operationName = TSMAPI.Operations:GetFirstByItem(itemString, "Auctioning")
	if not operationName or not TSM.operations[operationName] then return end
	TSMAPI.Operations:Update("Auctioning", operationName)

	local prices = TSM.Util:GetItemPrices(TSM.operations[operationName], itemString, false, {minPrice=true, maxPrice=true, normalPrice=true})
	if prices then
		local minPrice = (TSMAPI:MoneyToString(prices.minPrice, "|cffffffff", moneyCoins and "OPT_ICON" or nil) or "|cffffffff---|r")
		local normPrice = (TSMAPI:MoneyToString(prices.normalPrice, "|cffffffff", moneyCoins and "OPT_ICON" or nil) or "|cffffffff---|r")
		local maxPrice = (TSMAPI:MoneyToString(prices.maxPrice, "|cffffffff", moneyCoins and "OPT_ICON" or nil) or "|cffffffff---|r")
		tinsert(lines, {left="  "..L["Min/Normal/Max Prices:"], right=format("%s / %s / %s", minPrice, normPrice, maxPrice)})
	end

	if #lines > numStartingLines then
		tinsert(lines, numStartingLines+1, "|cffffff00TSM Auctioning:|r")
	end
end

function TSM:GetAuctionPlayer(player, player_full)
	local realm = GetRealmName() or ""
	if player_full and strjoin("-", player, realm) ~= player_full then
		return player_full
	else
		return player
	end
end

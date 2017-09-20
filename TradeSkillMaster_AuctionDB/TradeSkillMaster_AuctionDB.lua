-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_AuctionDB                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctiondb           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_AuctionDB", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_AuctionDB") -- loads the localization table
local private = {region=nil, globalKeyLookup={}}

TSM.MAX_AVG_DAY = 1
local SECONDS_PER_DAY = 60 * 60 * 24

StaticPopupDialogs["TSM_AUCTIONDB_NO_DATA_POPUP"] = {
	text = L["|cffff0000WARNING:|r TSM_AuctionDB doesn't currently have any pricing data for your realm. Either download the TSM Desktop Application from |cff99ffffhttp://tradeskillmaster.com|r to automatically update TSM_AuctionDB's data, or run a manual scan in-game."],
	button1 = OKAY,
	timeout = 0,
	hideOnEscape = false,
}

local settingsInfo = {
	version = 2,
	realm = {
		hasAppData = { type = "boolean", default = true, lastModifiedVersion = 1},
		lastSaveTime = { type = "number", default = 0, lastModifiedVersion = 1},
		lastCompleteScan = { type = "number", default = 0, lastModifiedVersion = 1},
		lastPartialScan = { type = "number", default = 0, lastModifiedVersion = 1},
		scanData = { type = "string", default = "", lastModifiedVersion = 1},
	},
	global = {
		scanDataUS = { type = "string", default = "", lastModifiedVersion = 2},
		scanDataEU = { type = "string", default = "", lastModifiedVersion = 2},
		lastUpdateUS = { type = "number", default = 0, lastModifiedVersion = 2},
		lastUpdateEU = { type = "number", default = 0, lastModifiedVersion = 2},
		helpPlatesShown = { type = "table", default = { auction = nil }, lastModifiedVersion = 1},
		showAHTab = { type = "boolean", default = true, lastModifiedVersion = 1},
	},
}
local tooltipDefaults = {
	_version = 2,
	minBuyout = true,
	marketValue = true,
	historical = false,
	regionMinBuyout = false,
	regionMarketValue = true,
	regionHistorical = false,
	regionSale = true,
	regionSalePercent = true,
	regionSoldPerDay = true,
	globalMinBuyout = false,
	globalMarketValue = false,
	globalHistorical = false,
	globalSale = false,
}

-- Called once the player has loaded WOW.
function TSM:OnInitialize()
	if TradeSkillMasterModulesDB then
		TradeSkillMasterModulesDB.AuctionDB = TradeSkillMaster_AuctionDBDB
	end

	-- load settings
	TSM.db = TSMAPI.Settings:Init("TradeSkillMaster_AuctionDBDB", settingsInfo)

	-- make easier references to all the modules
	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end

	-- register this module with TSM
	TSM:RegisterModule()
end

-- registers this module with TSM by first setting all fields and then calling TSMAPI:NewModule().
function TSM:RegisterModule()
	TSM.priceSources = {
		{ key = "DBMarket", label = L["AuctionDB - Market Value"], callback = "GetRealmItemData", arg = "marketValue", takeItemString = true },
		{ key = "DBMinBuyout", label = L["AuctionDB - Minimum Buyout"], callback = "GetRealmItemData", arg = "minBuyout", takeItemString = true },
		-- prices from the app
		{ key = "DBHistorical", label = L["AuctionDB - Historical Price (via TSM App)"], callback = "GetRealmItemData", arg = "historical", takeItemString = true },
		{ key = "DBRegionMinBuyoutAvg", label = L["AuctionDB - Region Minimum Buyout Average (via TSM App)"], callback = "GetRegionItemData", arg = "regionMinBuyout", takeItemString = true },
		{ key = "DBRegionMarketAvg", label = L["AuctionDB - Region Market Value Average (via TSM App)"], callback = "GetRegionItemData", arg = "regionMarketValue", takeItemString = true },
		{ key = "DBRegionHistorical", label = L["AuctionDB - Region Historical Price (via TSM App)"], callback = "GetRegionItemData", arg = "regionHistorical", takeItemString = true },
		{ key = "DBRegionSaleAvg", label = L["AuctionDB - Region Sale Average (via TSM App)"], callback = "GetRegionItemData", arg = "regionSale", takeItemString = true },
		{ key = "DBGlobalMinBuyoutAvg", label = L["AuctionDB - Global Minimum Buyout Average (via TSM App)"], callback = "GetGlobalItemData", arg = "globalMinBuyout", takeItemString = true },
		{ key = "DBGlobalMarketAvg", label = L["AuctionDB - Global Market Value Average (via TSM App)"], callback = "GetGlobalItemData", arg = "globalMarketValue", takeItemString = true },
		{ key = "DBGlobalHistorical", label = L["AuctionDB - Global Historical Price (via TSM App)"], callback = "GetGlobalItemData", arg = "globalHistorical", takeItemString = true },
		{ key = "DBGlobalSaleAvg", label = L["AuctionDB - Global Sale Average (via TSM App)"], callback = "GetGlobalItemData", arg = "globalSale", takeItemString = true },
	}
	TSM.moduleOptions = {callback="Config:Load"}
	if TSM.db.global.showAHTab then
		TSM.auctionTab = { callbackShow = "GUI:Show", callbackHide = "GUI:Hide" }
	end
	TSM.moduleAPIs = {
		{ key = "lastCompleteScan", callback = TSM.GetLastCompleteScan },
		{ key = "lastCompleteScanTime", callback = TSM.GetLastCompleteScanTime },
	}
	TSM.tooltip = {callbackLoad="LoadTooltip", callbackOptions="Config:LoadTooltipOptions", defaults=tooltipDefaults}
	TSMAPI:NewModule(TSM)
end

function TSM:OnEnable()
	if TSMAPI.GetRegion then
		private.region = TSMAPI:GetRegion()
	else
		StaticPopupDialogs["TSM_AUCTIONDB_TSM_UPDATE"] = {
			text = "|cffff0000WARNING:|r TradeSkillMaster v3.3.18 or higher is required for TSM_AuctionDB to function properly. Please update your addons.",
			button1 = OKAY,
			timeout = 0,
			hideOnEscape = false,
		}
		TSMAPI.Util:ShowStaticPopupDialog("TSM_AUCTIONDB_TSM_UPDATE")
	end

	local realmAppData, regionAppDataUS, regionAppDataEU = nil, nil, nil
	local appData = TSMAPI.AppHelper and TSMAPI.AppHelper:FetchData("AUCTIONDB_MARKET_DATA") -- get app data from TSM_AppHelper if it's installed
	if appData then
		for _, info in ipairs(appData) do
			local realm, data = unpack(info)
			local downloadTime = "?"
			if realm == "US" then
				regionAppDataUS = TSM:ProcessAppData(data)
				downloadTime = SecondsToTime(time() - regionAppDataUS.downloadTime).." ago"
			elseif realm == "EU" then
				regionAppDataEU = TSM:ProcessAppData(data)
				downloadTime = SecondsToTime(time() - regionAppDataEU.downloadTime).." ago"
			elseif TSMAPI.AppHelper:IsCurrentRealm(realm) then
				realmAppData = TSM:ProcessAppData(data)
				downloadTime = SecondsToTime(time() - realmAppData.downloadTime).." ago"
			end
			TSM:LOG_INFO("Got AppData for %s (isCurrent=%s, %s)", realm, tostring(TSMAPI.AppHelper:IsCurrentRealm(realm)), downloadTime)
		end
	end

	-- check if we can load realm data from the app
	if realmAppData and (realmAppData.downloadTime > TSM.db.realm.lastCompleteScan or (realmAppData.downloadTime == TSM.db.realm.lastCompleteScan and realmAppData.downloadTime > TSM.db.realm.lastPartialScan)) then
		TSM.updatedRealmData = (realmAppData.downloadTime > TSM.db.realm.lastCompleteScan)
		TSM.db.realm.lastCompleteScan = realmAppData.downloadTime
		TSM.db.realm.hasAppData = true
		TSM.realmData = {}
		local fields = realmAppData.fields
		for _, data in ipairs(realmAppData.data) do
			local itemString
			for i, key in ipairs(fields) do
				if i == 1 then
					-- item string must be the first field
					if type(data[i]) == "number" then
						itemString = "i:"..data[i]
					else
						itemString = gsub(data[i], ":0:", "::")
					end
					TSM.realmData[itemString] = {}
				else
					TSM.realmData[itemString][key] = data[i]
				end
			end
			TSM.realmData[itemString].lastScan = realmAppData.downloadTime
		end
	else
		TSM.Compress:LoadRealmData()
	end

	-- check if we can load US region data from the app
	if regionAppDataUS and regionAppDataUS.downloadTime >= TSM.db.global.lastUpdateUS then
		TSM.updatedRegionDataUS = (regionAppDataUS.downloadTime > TSM.db.global.lastUpdateUS)
		TSM.db.global.lastUpdateUS = regionAppDataUS.downloadTime
		TSM.regionDataUS = {}
		local fields = regionAppDataUS.fields
		for _, data in ipairs(regionAppDataUS.data) do
			local itemString
			for i, key in ipairs(fields) do
				if i == 1 then
					-- item string must be the first field
					if type(data[i]) == "number" then
						itemString = "i:"..data[i]
					else
						itemString = gsub(data[i], ":0:", "::")
					end
					TSM.regionDataUS[itemString] = {}
				else
					TSM.regionDataUS[itemString][key] = data[i]
				end
			end
		end
	else
		TSM.Compress:LoadRegionDataUS()
	end

	-- check if we can load EU region data from the app
	if regionAppDataEU and regionAppDataEU.downloadTime >= TSM.db.global.lastUpdateEU then
		TSM.updatedRegionDataEU = (regionAppDataEU.downloadTime > TSM.db.global.lastUpdateEU)
		TSM.db.global.lastUpdateEU = regionAppDataEU.downloadTime
		TSM.regionDataEU = {}
		local fields = regionAppDataEU.fields
		for _, data in ipairs(regionAppDataEU.data) do
			local itemString
			for i, key in ipairs(fields) do
				if i == 1 then
					-- item string must be the first field
					if type(data[i]) == "number" then
						itemString = "i:"..data[i]
					else
						itemString = gsub(data[i], ":0:", "::")
					end
					TSM.regionDataEU[itemString] = {}
				else
					TSM.regionDataEU[itemString][key] = data[i]
				end
			end
		end
	else
		TSM.Compress:LoadRegionDataEU()
	end

	for itemString in pairs(TSM.realmData) do
		TSMAPI.Item:FetchInfo(itemString)
	end
	if not next(TSM.realmData) then
		TSMAPI.Util:ShowStaticPopupDialog("TSM_AUCTIONDB_NO_DATA_POPUP")
	end
end

function TSM:ProcessAppData(rawData)
	if #rawData < 3500000 then
		-- we can safely just use loadstring() for strings below 3.5M
		return assert(loadstring(rawData)())
	end
	-- We'll manually load the data part, since that might be too big for loadstring() to process
	local leader, itemData, trailer = strmatch(rawData, "^(.+)data={{(.+)}}(.+)$")
	__AUCTIONDB_IMPORT_TEMP = {}
	for _, part in ipairs(TSMAPI.Util:SafeStrSplit(itemData, "},{")) do
		local entry = {(","):split(part)}
		for j = 1, #entry do
			entry[j] = entry[j]:trim("\"")
			entry[j] = tonumber(entry[j]) or (entry[j] ~= "" and entry[j]) or nil
		end
		tinsert(__AUCTIONDB_IMPORT_TEMP, entry)
	end
	local result = assert(loadstring(leader.."data=__AUCTIONDB_IMPORT_TEMP"..trailer)())
	__AUCTIONDB_IMPORT_TEMP = nil
	return result
end

function TSM:OnTSMDBShutdown()
	TSM.Compress:SaveRealmData()
	TSM.Compress:SaveRegionDataUS()
	TSM.Compress:SaveRegionDataEU()
end

local TOOLTIP_STRINGS = {
	minBuyout = {L["Min Buyout:"], L["Min Buyout x%s:"]},
	marketValue = {L["Market Value:"], L["Market Value x%s:"]},
	historical = {L["Historical Price:"], L["Historical Price x%s:"]},
	regionMinBuyout = {L["Region Min Buyout Avg:"], L["Region Min Buyout Avg x%s:"]},
	regionMarketValue = {L["Region Market Value Avg:"], L["Region Market Value Avg x%s:"]},
	regionHistorical = {L["Region Historical Price:"], L["Region Historical Price x%s:"]},
	regionSale = {L["Region Sale Avg:"], L["Region Sale Avg x%s:"]},
	regionSalePercent = {L["Region Sale Rate:"], L["Region Sale Rate x%s:"]},
	regionSoldPerDay = {L["Region Avg Daily Sold:"], L["Region Avg Daily Sold x%s:"]},
	globalMinBuyout = {L["Global Min Buyout Avg:"], L["Global Min Buyout Avg x%s:"]},
	globalMarketValue = {L["Global Market Value Avg:"], L["Global Market Value Avg x%s:"]},
	globalHistorical = {L["Global Historical Price:"], L["Global Historical Price x%s:"]},
	globalSale = {L["Global Sale Avg:"], L["Global Sale Avg x%s:"]},
}
local function TooltipMoneyFormat(value, quantity, moneyCoins)
	return TSMAPI:MoneyToString(value*quantity, "|cffffffff", "OPT_PAD", moneyCoins and "OPT_ICON" or nil)
end
local function TooltipX100Format(value)
	return "|cffffffff"..format("%0.2f", value/100).."|r"
end
local function InsertTooltipValueLine(itemString, quantity, key, scope, lines, options, formatter, ...)
	if not options[key] then return end
	local value = nil
	if scope == "global" then
		value = TSM:GetGlobalItemData(itemString, key)
	elseif scope == "region" then
		value = TSM:GetRegionItemData(itemString, key)
	elseif scope == "realm" then
		value = TSM:GetRealmItemData(itemString, key)
	else
		TSMAPI:Assert(false, "Invalid scope: "..tostring(scope))
	end
	if not value then return end
	local strings = TOOLTIP_STRINGS[key]
	TSMAPI:Assert(strings, "Could not find tooltip strings for :"..tostring(key))

	local leftStr = "  "..(quantity > 1 and format(strings[2], quantity) or strings[1])
	local rightStr = formatter(value, quantity, ...)
	tinsert(lines, {left=leftStr, right=rightStr})
end

function TSM:LoadTooltip(itemString, quantity, options, moneyCoins, lines)
	if not itemString then return end
	local numStartingLines = #lines

	-- add min buyout
	InsertTooltipValueLine(itemString, quantity, "minBuyout", "realm", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add market value
	InsertTooltipValueLine(itemString, quantity, "marketValue", "realm", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add historical price
	InsertTooltipValueLine(itemString, quantity, "historical", "realm", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add region min buyout
	InsertTooltipValueLine(itemString, quantity, "regionMinBuyout", "region", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add region market value
	InsertTooltipValueLine(itemString, quantity, "regionMarketValue", "region", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add region historical price
	InsertTooltipValueLine(itemString, quantity, "regionHistorical", "region", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add region sale avg
	InsertTooltipValueLine(itemString, quantity, "regionSale", "region", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add region sale rate
	InsertTooltipValueLine(itemString, quantity, "regionSalePercent", "region", lines, options, TooltipX100Format)
	-- add region sold per day
	InsertTooltipValueLine(itemString, quantity, "regionSoldPerDay", "region", lines, options, TooltipX100Format)
	-- add global min buyout
	InsertTooltipValueLine(itemString, quantity, "globalMinBuyout", "global", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add global market value
	InsertTooltipValueLine(itemString, quantity, "globalMarketValue", "global", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add global historical price
	InsertTooltipValueLine(itemString, quantity, "globalHistorical", "global", lines, options, TooltipMoneyFormat, moneyCoins)
	-- add global sale avg
	InsertTooltipValueLine(itemString, quantity, "globalSale", "global", lines, options, TooltipMoneyFormat, moneyCoins)

	-- add the header if we've added at least one line
	if #lines > numStartingLines then
		local lastScan = TSM:GetRealmItemData(itemString, "lastScan")
		local rightStr = "|cffffffff"..L["Not Scanned"].."|r"
		if lastScan then
			local timeColor = (time() - lastScan) > 60*60*3 and "|cffff0000" or "|cff00ff00"
			local timeDiff = SecondsToTime(time() - lastScan)
			local numAuctions = TSM:GetRealmItemData(itemString, "numAuctions") or 0
			rightStr = format("%s (%s)", format("|cffffffff"..L["%d auctions"].."|r", numAuctions), format(timeColor..L["%s ago"].."|r", timeDiff))
		end
		tinsert(lines, numStartingLines+1, {left="|cffffff00TSM AuctionDB:|r", right=rightStr})
	end
end

function TSM:GetLastCompleteScan()
	local lastScan = {}
	for itemString, data in pairs(TSM.realmData) do
		if data.lastScan >= TSM.db.realm.lastCompleteScan and data.minBuyout then
			lastScan[itemString] = {marketValue=data.marketValue, minBuyout=data.minBuyout, numAuctions=data.numAuctions}
		end
	end

	return lastScan
end

function TSM:GetLastCompleteScanTime()
	return TSM.db.realm.lastCompleteScan
end

function private.GetItemDataHelper(tbl, key, itemString)
	if not itemString or not tbl then return end
	local value = nil
	if tbl[itemString] then
		value = tbl[itemString][key]
	else
		local quality = TSMAPI.Item:GetQuality(itemString)
        if quality and quality >= 3 then
            if strmatch(itemString, "^i:[0-9]+:[0-9%-]*:") then return end
        end
		local baseItemString = TSMAPI.Item:ToBaseItemString(itemString)
		if not baseItemString then return end
		value = tbl[baseItemString] and tbl[baseItemString][key]
	end
	if not value or value <= 0 then return end
	return value
end

function TSM:GetRealmItemData(itemString, key)
	return private.GetItemDataHelper(TSM.realmData, key, itemString)
end

function TSM:GetRegionItemData(itemString, key)
	if private.region == "US" then
		return private.GetItemDataHelper(TSM.regionDataUS, key, itemString)
	elseif private.region == "EU" then
		return private.GetItemDataHelper(TSM.regionDataEU, key, itemString)
	else
		-- unsupported region (or PTR)
		return
	end
end

function TSM:GetGlobalItemData(itemString, key)
	-- translate to region keys
	if not private.globalKeyLookup[key] then
		private.globalKeyLookup[key] = gsub(key, "^global", "region")
	end
	key = private.globalKeyLookup[key]
	local valueUS = private.GetItemDataHelper(TSM.regionDataUS, key, itemString)
	local valueEU = private.GetItemDataHelper(TSM.regionDataEU, key, itemString)
	if valueUS and valueEU then
		-- average the regions to get the global value
		return TSMAPI.Util:Round((valueUS + valueEU) / 2)
	elseif valueUS then
		return valueUS
	elseif valueEU then
		return valueEU
	else
		-- neither region has a valid price
		return
	end
end

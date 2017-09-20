-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_AuctionDB                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctiondb           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Scan = TSM:NewModule("Scan", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_AuctionDB") -- loads the localization table
local private = {threadId=nil}

local MIN_PERCENTILE = 0.15 -- consider at least the lowest 15% of auctions
local MAX_PERCENTILE = 0.30 -- consider at most the lowest 30% of auctions
local MAX_JUMP = 1.2 -- between the min and max percentiles, any increase in price over 120% will trigger a discard of remaining auctions



-- ============================================================================
-- Module Functions
-- ============================================================================

function Scan:StartFullScan()
	Scan:StopScanning()
	TSM:AnalyticsEvent("START_FULL_SCAN")
	private.threadId = TSMAPI.Threading:Start(private.FullScanThread, 0.7, Scan.StopScanning)
end

function Scan:StartGroupScan(itemList)
	Scan:StopScanning()
	TSM:AnalyticsEvent("START_GROUP_SCAN")
	private.threadId = TSMAPI.Threading:Start(private.GroupScanThread, 0.7, Scan.StopScanning, itemList)
end

function Scan:StartGetAllScan()
	Scan:StopScanning()
	TSM:AnalyticsEvent("START_GETALL_SCAN")
	private.threadId = TSMAPI.Threading:Start(private.GetAllScanThread, 0.7, Scan.StopScanning)
end

function Scan:StopScanning()
	TSMAPI.Threading:Kill(private.threadId)
	private.threadId = nil
end

function Scan:IsScanning()
	return private.threadId and true or false
end



-- ============================================================================
-- Scan Threads
-- ============================================================================

function private.FullScanThread(self)
	self:SetThreadName("AUCTIONDB_FULL_SCAN")
	TSM.GUI:UpdateStatus(L["Running query..."], 0, 0)

	local database = TSMAPI.Auction:NewDatabase()
	TSMAPI.Auction:ScanQuery("AuctionDB", {name=""}, self:GetSendMsgToSelfCallback(), nil, database)
	local startTime = time()
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "SCAN_PAGE_UPDATE" then
			-- the page we're scanning has changed
			local page, total = unpack(args)
			local remainingPages = total - page
			local statusText = format(L["Scanning page %s/%s"], page, total)
			if page > 50 and remainingPages > 0 then
				-- add approximate time remaining to the status text
				statusText = format(L["Scanning page %s/%s - Approximately %s remaining"], page, total, SecondsToTime(floor((page / (time() - startTime)) * remainingPages)))
			end
			TSM.GUI:UpdateStatus(statusText, page*100/total)
		elseif event == "SCAN_COMPLETE" then
			-- we're done scanning
			break
		elseif event == "INTERRUPTED" then
			-- scan was interrupted
			TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
			return
		else
			error("Unexpected message: "..tostring(event))
		end
	end

	TSM.GUI:UpdateStatus(L["Processing data..."], 100)
	local success = true
	local scanData = {}
	for _, record in ipairs(database.records) do
		if not record.itemString then
			success = false
			break
		end
		if not scanData[record.itemString] then
			scanData[record.itemString] = {buyouts={}, minBuyout=0, numAuctions=0}
		end
		if record.itemBuyout > 0 then
			if scanData[record.itemString].minBuyout == 0 or record.itemBuyout < scanData[record.itemString].minBuyout then
				scanData[record.itemString].minBuyout = record.itemBuyout
			end
			for i=1, record.stackSize do
				tinsert(scanData[record.itemString].buyouts, record.itemBuyout)
			end
		end
		scanData[record.itemString].numAuctions = scanData[record.itemString].numAuctions + 1
		self:Yield()
	end
	if success then
		private:ProcessScanDataThread(self, scanData)
	else
		TSM:Print(L["The scan did not run successfully due to issues on Blizzard's end. Using the TSM desktop application for your scans is recommended."])
	end
	TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
end

function private.GroupScanThread(self, itemList)
	self:SetThreadName("AUCTIONDB_GROUP_SCAN")

	-- generate queries
	TSM.GUI:UpdateStatus(L["Preparing Filters..."], 0, 0)
	TSMAPI.Auction:GenerateQueries(itemList, self:GetSendMsgToSelfCallback())
	local queries = nil
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "QUERY_COMPLETE" then
			-- we've got the queries
			queries = unpack(args)
			break
		elseif event == "INTERRUPTED" then
			-- we were interrupted
			TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
			return
		else
			error("Unexpected message: "..tostring(event))
		end
	end

	-- scan queries
	TSM.GUI:UpdateStatus(L["Running query..."])
	local numQueries = #queries
	local database = TSMAPI.Auction:NewDatabase()
	for i=1, numQueries do
		TSM.GUI:UpdateStatus(format(L["Scanning %d / %d (Page %d / %d)"], i, numQueries, 1, 1), (i-1)*100/numQueries, 0)
		TSMAPI.Auction:ScanQuery("AuctionDB", queries[i], self:GetSendMsgToSelfCallback(), nil, database)
		while true do
			local args = self:ReceiveMsg()
			local event = tremove(args, 1)
			if event == "SCAN_PAGE_UPDATE" then
				-- the page we're scanning has changed
				local page, numPages = unpack(args)
				TSM.GUI:UpdateStatus(format(L["Scanning %d / %d (Page %d / %d)"], i, numQueries, page+1, numPages), (i-1)*100/numQueries, page*100/numPages)
			elseif event == "SCAN_COMPLETE" then
				-- we're done scanning this query
				break
			elseif event == "INTERRUPTED" then
				-- scan was interrupted
				TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
				return
			else
				error("Unexpected message: "..tostring(event))
			end
		end
	end

	TSM.GUI:UpdateStatus(L["Processing data..."], 100)
	local success = true
	local scanData = {}
	for _, record in ipairs(database.records) do
		if not record.itemString then
			success = false
			break
		end
		if not scanData[record.itemString] then
			scanData[record.itemString] = {buyouts={}, minBuyout=0, numAuctions=0}
		end
		if record.itemBuyout > 0 then
			if scanData[record.itemString].minBuyout == 0 or record.itemBuyout < scanData[record.itemString].minBuyout then
				scanData[record.itemString].minBuyout = record.itemBuyout
			end
			for i=1, record.stackSize do
				tinsert(scanData[record.itemString].buyouts, record.itemBuyout)
			end
		end
		scanData[record.itemString].numAuctions = scanData[record.itemString].numAuctions + 1
		self:Yield()
	end
	if success then
		private:ProcessScanDataThread(self, scanData, itemList)
	else
		TSM:Print(L["The scan did not run successfully due to issues on Blizzard's end. Using the TSM desktop application for your scans is recommended."])
	end
	TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
end

function private.GetAllScanThread(self)
	self:SetThreadName("AUCTIONDB_GETALL_SCAN")
	TSMAPI.Auction:GetAllScan("AuctionDB", self:GetSendMsgToSelfCallback())
	local scanData = nil
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "GETALL_QUERY_START" then
			-- getall query was sent to the server
			TSM.GUI:UpdateStatus(L["Running query..."], 0, 0)
		elseif event == "GETALL_PROGRESS" then
			-- progress update
			local currentIndex, numAuctions = unpack(args)
			TSM.GUI:UpdateStatus(L["Scanning results..."], currentIndex*100/numAuctions)
		elseif event == "SCAN_COMPLETE" then
			-- we are done scanning
			scanData = unpack(args)
			break
		elseif event == "GETALL_BUSY" then
			-- can't run GetAll right now
			TSM:Print(L["Can't run a GetAll scan right now."])
			return
		elseif event == "GETALL_BAD_DATA" then
			-- got bad data from the server
			TSM:Print(L["The scan did not run successfully due to issues on Blizzard's end. Using the TSM desktop application for your scans is recommended."])
			TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
			return
		else
			error("Unexpected message: "..tostring(event))
		end
	end

	-- process the scan data
	TSM.GUI:UpdateStatus(L["Processing data..."], 100)
	private:ProcessScanDataThread(self, scanData)
	TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:ProcessScanDataThread(self, scanData, itemList)
	local scanTime = time()
	TSM.db.realm.lastPartialScan = scanTime

	local scannedItems = nil
	if itemList then
		scannedItems = {}
		for _, itemString in ipairs(itemList) do
			scannedItems[itemString] = true
		end
	elseif not TSM.db.realm.hasAppData then
		TSM.db.realm.lastCompleteScan = scanTime
	end

	-- clear min buyotus / num auctions and update last scan time for items we should have scanned
	for itemString, data in pairs(TSM.realmData) do
		if not scannedItems or scannedItems[itemString] then
			data.minBuyout = nil
			data.numAuctions = nil
			data.lastScan = scanTime
			self:Yield()
		end
	end

	-- process new data
	TSM.updatedRealmData = true
	for itemString, data in pairs(scanData) do
		itemString = TSMAPI.Item:ToBaseItemString(itemString)
		if TSM.db.realm.hasAppData and TSM.realmData[itemString] then
			-- if we have data from the app, just update the minBuyout/numAuctions/lastScan
			TSM.realmData[itemString].minBuyout = data.minBuyout
			TSM.realmData[itemString].numAuctions = data.numAuctions
			TSM.realmData[itemString].lastScan = scanTime
		else
			TSM.realmData[itemString] = TSM.realmData[itemString] or {}
			if #data.buyouts > 0 then
				TSM.realmData[itemString].marketValue = private:CalculateMarketValue(data.buyouts)
			else
				TSM.realmData[itemString].marketValue = TSM.realmData[itemString].marketValue or 0
			end
			TSM.realmData[itemString].minBuyout = data.minBuyout
			TSM.realmData[itemString].numAuctions = data.numAuctions
			TSM.realmData[itemString].lastScan = scanTime
		end
		self:Yield()
	end
end

function private:CalculateMarketValue(buyouts)
	local totalNum, totalBuyout = 0, 0
	local numRecords = #buyouts

	for i=1, numRecords do
		totalNum = i - 1
		if i ~= 1 and i > numRecords*MIN_PERCENTILE and (i > numRecords*MAX_PERCENTILE or buyouts[i] >= MAX_JUMP*buyouts[i-1]) then
			break
		end

		totalBuyout = totalBuyout + buyouts[i]
		if i == numRecords then
			totalNum = i
		end
	end

	local uncorrectedMean = totalBuyout / totalNum
	local varience = 0

	for i=1, totalNum do
		varience = varience + (buyouts[i]-uncorrectedMean)^2
	end

	local stdDev = sqrt(varience/totalNum)
	local correctedTotalNum, correctedTotalBuyout = 1, uncorrectedMean

	for i=1, totalNum do
		if abs(uncorrectedMean - buyouts[i]) < 1.5*stdDev then
			correctedTotalNum = correctedTotalNum + 1
			correctedTotalBuyout = correctedTotalBuyout + buyouts[i]
		end
	end

	local correctedMean = floor(correctedTotalBuyout / correctedTotalNum + 0.5)

	return correctedMean
end

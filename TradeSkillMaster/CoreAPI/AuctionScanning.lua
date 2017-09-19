-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code for scanning the auction house
local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {callbackHandler=nil, scanThreadId=nil, database=nil, currentModule=nil, pageTemp=nil, optimize=nil}
-- some constants
local SCAN_THREAD_PRIORITY = 0.8
local SCAN_RESULT_DELAY = 0.1
local MAX_SOFT_RETRIES = 20
local MAX_HARD_RETRIES = 2



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Auction:ScanQuery(module, query, callbackHandler, resolveSellers, database)
	TSMAPI:Assert(TSMAPI:HasModule(module), "Invalid module")
	TSMAPI:Assert(type(query) == "table", "Invalid query type: "..type(query))
	TSMAPI:Assert(type(callbackHandler) == "function", "Invalid callbackHandler type: "..type(callbackHandler))
	TSMAPI:Assert(AuctionFrame:IsVisible())
	if not private:CanScan(module) then
		private:ShowScanBusyPopup(module)
		callbackHandler("INTERRUPTED")
		return
	end
	TSMAPI.Auction:StopScan(module)
	private.callbackHandler = callbackHandler
	private.database = database
	private.currentModule = module
	if query.name ~= "" and (not query.items or #query.items == 1) then
		private.optimize = true
	end
	TSM:SetAuctionTabFlashing(private.currentModule, true)

	-- set up the query
	query.resolveSellers = resolveSellers
	query.page = 0

	-- sort by bid and then buyout
	SortAuctionItems("list", "bid")
	if IsAuctionSortReversed("list", "bid") then
		SortAuctionItems("list", "bid")
	end
	SortAuctionItems("list", "buyout")
	if IsAuctionSortReversed("list", "buyout") then
		SortAuctionItems("list", "buyout")
	end

	private.scanThreadId = TSMAPI.Threading:Start(private.ScanAllPagesThread, SCAN_THREAD_PRIORITY, private.ScanThreadDone, query)
end

function TSMAPI.Auction:ScanLastPage(module, callbackHandler, database)
	TSMAPI:Assert(TSMAPI:HasModule(module), "Invalid module")
	TSMAPI:Assert(type(callbackHandler) == "function", "Invalid callbackHandler type: "..type(callbackHandler))
	TSMAPI:Assert(AuctionFrame:IsVisible())
	if not private:CanScan(module) then
		private:ShowScanBusyPopup(module)
		callbackHandler("INTERRUPTED")
		return
	end
	TSMAPI.Auction:StopScan(module)
	private.callbackHandler = callbackHandler
	private.database = database
	private.currentModule = module
	TSM:SetAuctionTabFlashing(private.currentModule, true)

	-- clear the auction sort
	SortAuctionClearSort("list")

	private.scanThreadId = TSMAPI.Threading:Start(private.ScanLastPageThread, SCAN_THREAD_PRIORITY, private.ScanThreadDone)
end

function TSMAPI.Auction:GetAllScan(module, callbackHandler)
	TSMAPI:Assert(TSMAPI:HasModule(module), "Invalid module")
	TSMAPI:Assert(type(callbackHandler) == "function", "Invalid callbackHandler type: "..type(callbackHandler))
	TSMAPI:Assert(AuctionFrame:IsVisible())
	if not private:CanScan(module) then
		private:ShowScanBusyPopup(module)
		callbackHandler("GETALL_BUSY")
		return
	end
	TSMAPI.Auction:StopScan(module)
	private.callbackHandler = callbackHandler
	private.currentModule = module
	TSM:SetAuctionTabFlashing(private.currentModule, true)

	private.scanThreadId = TSMAPI.Threading:Start(private.GetAllScanThread, SCAN_THREAD_PRIORITY, private.ScanThreadDone)
end

function TSMAPI.Auction:FindAuction(module, targetInfo, callbackHandler, database)
	TSMAPI:Assert(TSMAPI:HasModule(module), "Invalid module")
	TSMAPI:Assert(type(targetInfo) == "table", "Invalid targetInfo type: "..type(targetInfo))
	TSMAPI:Assert(type(callbackHandler) == "function", "Invalid callbackHandler type: "..type(callbackHandler))
	TSMAPI:Assert(AuctionFrame:IsVisible())
	if not private:CanScan(module) then
		private:ShowScanBusyPopup(module)
		callbackHandler("INTERRUPTED")
		return
	end
	TSMAPI.Auction:StopScan(module)
	private.callbackHandler = callbackHandler
	private.database = database
	private.currentModule = module
	TSM:SetAuctionTabFlashing(private.currentModule, true)

	-- sort by bid and then buyout
	SortAuctionItems("list", "bid")
	if IsAuctionSortReversed("list", "bid") then
		SortAuctionItems("list", "bid")
	end
	SortAuctionItems("list", "buyout")
	if IsAuctionSortReversed("list", "buyout") then
		SortAuctionItems("list", "buyout")
	end

	private.scanThreadId = TSMAPI.Threading:Start(private.FindAuctionThread, SCAN_THREAD_PRIORITY, private.ScanThreadDone, targetInfo)
end

function TSMAPI.Auction:FindAuctionNoScan(targetInfo)
	TSMAPI:Assert(type(targetInfo) == "table", "Invalid targetInfo type: "..type(targetInfo))
	TSMAPI:Assert(AuctionFrame:IsVisible())

	local keys = {"itemString", "stackSize", "displayBid", "buyout", "seller"}
	for i=#keys, 1, -1 do
		if not targetInfo[keys[i]] then
			tremove(keys, i)
		end
	end
	return private:SearchCurrentPageForTargetItem(targetInfo, keys)
end

function TSMAPI.Auction:StopScan(module)
	-- modules can't stop other module's scans
	if not private:CanScan(module) then return end
	-- if the scanning thread is active, kill it
	if private.scanThreadId then
		-- the scan was interrupted by something
		private:DoCallback("INTERRUPTED")
		TSMAPI.Threading:Kill(private.scanThreadId)
	end

	TSM:SetAuctionTabFlashing(private.currentModule, false) -- stop flashing the tab of the current module
	private.currentModule = nil
	private.optimize = nil
	private.scanThreadId = nil
	private.callbackHandler = nil
	private.pageTemp = nil
	private.database = nil
end



-- ============================================================================
-- General Helper Functions
-- ============================================================================

-- make sure all scanning stops when AH is closed
LibStub("AceEvent-3.0"):RegisterEvent("AUCTION_HOUSE_CLOSED", function() TSMAPI.Auction:StopScan(private.currentModule) end)

function private:CanScan(module)
	-- anybody can scan if there's not currently a scan going on
	if not private.currentModule then return true end
	-- Check if a module can start a scan (if they are currently scanning or nobody is currently scanning)
	TSMAPI:Assert(TSMAPI:HasModule(module), "Invalid module")
	return private.currentModule == module
end

function private:ShowScanBusyPopup(module)
	StaticPopupDialogs["TSMScanBusyPopup"] = StaticPopupDialogs["TSMScanBusyPopup"] or {
		text = L["|cffffff00TSM Scan Blocked|r\n\nAnother module is currently scanning. Stop the other module's scan before retrying this scan."],
		button1 = OKAY,
		timeout = 0,
	}
	TSMAPI.Util:ShowStaticPopupDialog("TSMScanBusyPopup")
end

function private:DoCallback(...)
	if type(private.callbackHandler) == "function" then
		private.callbackHandler(...)
	end
end

function private:GetNumPages()
	local _, total = GetNumAuctionItems("list")
	return ceil(total / NUM_AUCTION_ITEMS_PER_PAGE)
end

function private:GetLastPage()
	local _, total = GetNumAuctionItems("list")
	return floor(total / NUM_AUCTION_ITEMS_PER_PAGE)
end


function private:CompareTableKeys(keys, tbl1, tbl2)
	for _, key in ipairs(keys) do
		if tbl1[key] ~= tbl2[key] then
			return
		end
	end
	return true
end

function private:CompareBidBuyout(a, b)
	local result = a.buyout == b.buyout and (b.displayedBid - a.displayedBid) or (b.buyout - a.buyout)
	if result > 0 then
		return "before"
	elseif result < 0 then
		return "after"
	else
		return "equal"
	end
end



-- ============================================================================
-- Auction Scanning Helper Functions
-- ============================================================================

function private:IsTargetAuction(index, targetInfo, keys)
	local _, _, stackSize, _, _, _, _, minBid, _, buyout, bid, _, _, seller, seller_full = GetAuctionItemInfo("list", index)
	seller = TSM:GetAuctionPlayer(seller, seller_full)
	local displayedBid = bid == 0 and minBid or bid
	local itemString = TSMAPI.Item:ToItemString(GetAuctionItemLink("list", index))
	local auctionData = {itemString=itemString, stackSize=stackSize, displayedBid=displayedBid, buyout=buyout, seller=seller}
	return private:CompareTableKeys(keys, auctionData, targetInfo), auctionData
end

function private:IsAuctionPageValid(resolveSellers)
	local numAuctions, totalAuctions = GetNumAuctionItems("list")
	if totalAuctions <= NUM_AUCTION_ITEMS_PER_PAGE and numAuctions ~= totalAuctions then
		-- there are cases where we get (0, 1) from the API - no idea why and it'll cause bugs later, so we should count it as invalid
		TSM:LOG_ERR("Unexpected number of auctions (%d, %d)", numAuctions, totalAuctions)
		return false
	end
	if numAuctions == 0 then return true end

	local numLinks, prevLink = 0, nil
	for i=1, numAuctions do
		-- checks to make sure all the data has been sent to the client
		-- if not, the data is bad and we'll wait / try again
		local _, _, stackSize, _, _, _, _, minBid, minIncrement, buyout, bid, highBidder, _, seller, seller_full = GetAuctionItemInfo("list", i)
		seller = TSM:GetAuctionPlayer(seller, seller_full)
		local timeLeft = GetAuctionItemTimeLeft("list", i)
		local link = TSMAPI.Item:GeneralizeLink(GetAuctionItemLink("list", i))
		local itemString = TSMAPI.Item:ToItemString(link)
		local name = TSMAPI.Item:GetName(link)
		local itemLevel = TSMAPI.Item:GetItemLevel(link)
		if not itemString or not buyout or not stackSize or not itemLevel or not name then
			return false
		elseif not seller and resolveSellers and buyout ~= 0 then
			return false
		end
	end

	return true
end

function private:GetAuctionRecord(index)
	local _, texture, stackSize, _, _, _, _, minBid, minIncrement, buyout, bid, highBidder, _, seller, seller_full = GetAuctionItemInfo("list", index)
	local timeLeft = GetAuctionItemTimeLeft("list", index)
	local rawLink = GetAuctionItemLink("list", index)
	local link = TSMAPI.Item:GeneralizeLink(rawLink)
	seller = TSM:GetAuctionPlayer(seller, seller_full) or "?"
	return TSMAPI.Auction:NewRecord(link, texture, stackSize, minBid, minIncrement, buyout, bid, seller, timeLeft, highBidder, rawLink)
end

-- scans the current page and stores the results
function private:StorePageResults(duplicateRecord)
	local numAuctions = nil
	if duplicateRecord then
		numAuctions = NUM_AUCTION_ITEMS_PER_PAGE
		private.pageTemp = {}
		for i=1, numAuctions do
			private.pageTemp[i] = duplicateRecord
		end
	else
		numAuctions = GetNumAuctionItems("list")
		private.pageTemp = {}
		if numAuctions == 0 then return end

		for i=1, numAuctions do
			private.pageTemp[i] = private:GetAuctionRecord(i)
		end
	end

	for i=1, numAuctions do
		if private.usableOptimize then
			private.usableOptimize[private.pageTemp[i]] = true
		end
		private.database:InsertAuctionRecord(private.pageTemp[i])
	end
end

function private:SearchCurrentPageForTargetItem(targetInfo, keys)
	-- check for the target item on this page
	local indexList, firstAuction, lastAuction
	for i=1, GetNumAuctionItems("list") do
		local _, _, stackSize, _, _, _, _, minBid, _, buyout, bid, _, _, seller, seller_full = GetAuctionItemInfo("list", i)
		seller = TSM:GetAuctionPlayer(seller, seller_full)
		local displayedBid = bid == 0 and minBid or bid
		local itemString = TSMAPI.Item:ToItemString(GetAuctionItemLink("list", i))
		local auctionData = {itemString=itemString, stackSize=stackSize, displayedBid=displayedBid, buyout=buyout, seller=seller}
		local isTarget = private:CompareTableKeys(keys, auctionData, targetInfo)
		if i == 1 then
			firstAuction = auctionData
		elseif i == NUM_AUCTION_ITEMS_PER_PAGE then
			lastAuction = auctionData
		end
		if isTarget then
			indexList = indexList or {}
			tinsert(indexList, i)
		end
	end
	return indexList, firstAuction, lastAuction
end



-- ============================================================================
-- Thread Helper Functions
-- ============================================================================

-- fires off a query and waits for the AH to update (without any retries)
function private.ScanThreadDoQuery(self, query)
	-- wait for the AH to be ready
	while not CanSendAuctionQuery() do self:Yield(true) end

	-- send the query
	if not query.filterInfoCache and (query.class or query.subClass or query.invType) then
		if query.invType == LE_INVENTORY_TYPE_CHEST_TYPE or query.invType == LE_INVENTORY_TYPE_ROBE_TYPE then
			-- default AH sends in queries for both chest types, we need to mimic this when using a chest filter
			query.filterInfoCache = {{classID=query.class, subClassID=query.subClass, inventoryType=LE_INVENTORY_TYPE_CHEST_TYPE}, {classID=query.class, subClassID=query.subClass, inventoryType=LE_INVENTORY_TYPE_ROBE_TYPE}}
		else
			query.filterInfoCache = {{classID=query.class, subClassID=query.subClass, inventoryType=query.invType}}
		end		
	end
	QueryAuctionItems(query.name, query.minLevel, query.maxLevel, query.page, query.usable, query.quality, nil, query.exact, query.filterInfoCache)

	-- wait for the update event
	self:WaitForEvent("AUCTION_ITEM_LIST_UPDATE")
end

-- does a query until it's successful (or we run out of retries)
function private.ScanThreadDoQueryAndValidate(self, query)
	for i=0, MAX_HARD_RETRIES do
		-- make the query
		private.ScanThreadDoQuery(self, query)
		if query.doNotify then
			private:DoCallback("SCAN_PAGE_UPDATE", 0, private:GetNumPages())
			query.doNotify = nil
		end
		-- check the result
		for j=0, MAX_SOFT_RETRIES do
			-- wait a small delay and then try and get the result
			self:Sleep(SCAN_RESULT_DELAY)
			-- get result
			if private:IsAuctionPageValid(query.resolveSellers) then
				-- result is valid, so we're done
				return
			end
		end
		-- keep doing soft retries until we can send the next query
		while not CanSendAuctionQuery() do
			-- wait a small delay and then try and get the result
			self:Sleep(SCAN_RESULT_DELAY)
			-- get result
			if private:IsAuctionPageValid(query.resolveSellers) then
				-- result is valid, so we're done
				return
			end
		end
		self:Yield()
	end
	-- ran out of retries
	TSM:LOG_INFO("Ran out of scan retries on page %d", query.page)
end

function private:ScanCurrentPageThread(self, query, data)
	query.doNotify = (data.pagesScanned == 0)
	-- query until we get good data or run out of retries
	private.ScanThreadDoQueryAndValidate(self, query)
	-- do the callback for the number of pages we've scanned
	data.pagesScanned = data.pagesScanned + 1
	private:DoCallback("SCAN_PAGE_UPDATE", data.pagesScanned, private:GetNumPages())
	-- we've made the query, now scan the page
	private:StorePageResults()
	if private.optimize then
		data.skipInfo[query.page] = {private.pageTemp[1], private.pageTemp[NUM_AUCTION_ITEMS_PER_PAGE]}
	end
end



-- ============================================================================
-- Main Thread Functions
-- ============================================================================

function private.ScanAllPagesThread(self, query)
	self:SetThreadName("AUCTION_SCANNING_SCAN_ALL_PAGES")
	-- wait for the AH to be ready
	self:Sleep(0.1)
	while not CanSendAuctionQuery() do self:Yield(true) end

	local tempData = {skipInfo={}, pagesScanned=0}

	-- loop until we're through all the pages, at which point we'll break out
	local numPages
	local MAX_SKIP = 4
	while not numPages or query.page < numPages do
		-- see if we should try and skip pages
		if private.optimize and query.page >= 1 and numPages and numPages - query.page > MAX_SKIP and numPages > MAX_SKIP + 1 then
			local didSkip = nil
			for numToSkip=MAX_SKIP, 1, -1 do
				-- try and skip
				query.page = query.page + numToSkip
				private:ScanCurrentPageThread(self, query, tempData)
				TSM:LOG_INFO("Trying to skip %d pages from page %d (out of %d)", numToSkip, query.page, numPages)
				local shouldSkip = nil
				if not tempData.skipInfo[query.page] or not tempData.skipInfo[query.page][1] or not tempData.skipInfo[query.page-numToSkip-1] or not tempData.skipInfo[query.page-numToSkip-1][2] then
					TSM:LOG_ERR("Did not have valid skip info")
				elseif tempData.skipInfo[query.page][1].hash3 == tempData.skipInfo[query.page-numToSkip-1][2].hash3 then
					shouldSkip = true
				end
				if shouldSkip then
					-- skip was successful!
					for i=1, numToSkip do
						-- "scan" the skipped pages
						private:StorePageResults(tempData.skipInfo[query.page][1])
					end
					tempData.pagesScanned = tempData.pagesScanned + numToSkip
					query.page = query.page - numToSkip
					private:DoCallback("SCAN_PAGE_UPDATE", tempData.pagesScanned, private:GetNumPages())
					didSkip = numToSkip
					break
				else
					-- skip failed, reset the page being queried
					query.page = query.page - numToSkip
				end
			end

			if not didSkip then
				-- just regularly scan the last page we tried to skip
				private:ScanCurrentPageThread(self, query, tempData)
			end
			query.page = query.page + MAX_SKIP + 1
		else
			-- do a normal scan of this page
			private:ScanCurrentPageThread(self, query, tempData)
			query.page = query.page + 1
		end
		numPages = private:GetNumPages()
	end

	private:DoCallback("SCAN_COMPLETE")
end

function private.ScanLastPageThread(self)
	self:SetThreadName("AUCTION_SCANNING_SCAN_LAST_PAGE")
	-- wait for the AH to be ready
	self:Sleep(0.1)
	while not CanSendAuctionQuery() do self:Yield(true) end
	
	-- get to the last page of the AH
	local lastPage = private:GetLastPage()
	local query = {name="", page=lastPage}
	local onLastPage = false
	while not onLastPage do
		-- make the query
		private.ScanThreadDoQuery(self, query)
		local lastPage = private:GetLastPage()
		onLastPage = (query.page == lastPage)
		query.page = lastPage
	end
	
	-- check the result
	for j=0, MAX_SOFT_RETRIES do
		-- wait a small delay and then try and get the result
		self:Sleep(SCAN_RESULT_DELAY)
		-- get result
		if private:IsAuctionPageValid() then
			-- result is valid, so break and store the result
			break
		end
	end
	
	-- scan the page and store the results then do the callback
	private:StorePageResults()
	private:DoCallback("SCAN_COMPLETE")
end

function private.FindAuctionThread(self, targetInfo)
	if self then self:SetThreadName("AUCTION_SCANNING_FIND_AUCTION") end
	local minLevel = TSMAPI.Item:GetMinLevel(targetInfo.itemString)
	local query = {
		name = TSMAPI.Item:GetName(targetInfo.itemString),
		minLevel = minLevel,
		maxLevel = minLevel,
		class = TSMAPI.Item:GetClassId(targetInfo.itemString),
		subClass = TSMAPI.Item:GetSubClassId(targetInfo.itemString),
		quality = TSMAPI.Item:GetQuality(targetInfo.itemString),
		page = 0,
		exact = true
	}
	local keys = {"itemString", "stackSize", "displayBid", "buyout", "seller"}
	local indexList = nil
	for i=#keys, 1, -1 do
		if not targetInfo[keys[i]] then
			tremove(keys, i)
		end
	end

	-- check if the item is on the current page
	indexList = private:SearchCurrentPageForTargetItem(targetInfo, keys)
	if not self then
		-- this must be a no-scan run of this thread, so return here
		return indexList
	end
	if indexList then
		private:DoCallback("FOUND_AUCTION", indexList)
		return
	end

	local searchDirection = nil
	local estimatedPage = nil
	local totalPages = math.huge
	if private.database and not private.database.disableFastFind then
		-- make an educated guess at the starting page and do a linear search from there
		local view = private.database:CreateView()
		local results = view:OrderBy("buyout"):OrderBy("displayedBid"):Execute()
		-- set other orders for comparison purposes
		for _, key in ipairs(keys) do
			if key ~= "buyout" and key ~= "displayedBid" then
				view:OrderBy(key)
			end
		end
		local estimatedIndex = 0
		local pageQuantities = {}
		for _, record in ipairs(results) do
			if record.baseItemString == targetInfo.baseItemString then
				estimatedIndex = estimatedIndex + 1
				local page = floor((estimatedIndex-1)/50)
				if view:CompareRecords(record, targetInfo) == 0 then
					pageQuantities[page] = (pageQuantities[page] or 0) + 1
				end
				if record == targetInfo and not estimatedPage then
					-- just in-case the page quantities fail
					estimatedPage = floor((estimatedIndex-1)/50)
				end
			end
		end
		-- pick the page with the highest quantity of items
		local maxNum = 0
		for page, num in pairs(pageQuantities) do
			if num > maxNum then
				estimatedPage = page
				maxNum = num
			end
		end
	end
	if estimatedPage then
		query.page = estimatedPage
	else
		query.page = 0
		searchDirection = 1
	end


	while true do
		private.ScanThreadDoQueryAndValidate(self, query)
		totalPages = private:GetNumPages()
		local indexList, firstAuction, lastAuction = private:SearchCurrentPageForTargetItem(targetInfo, keys)
		-- figure out what we should search next or if we are done
		local cmpFirst = firstAuction and private:CompareBidBuyout(targetInfo, firstAuction) or "before"
		local cmpLast = lastAuction and private:CompareBidBuyout(targetInfo, lastAuction) or "before"
		if (cmpFirst == "after" and cmpLast == "before") or indexList then
			-- it should be on this page
			private:DoCallback("FOUND_AUCTION", indexList)
			return
		elseif cmpFirst == "before" then
			TSMAPI:Assert(cmpLast == "before")
			searchDirection = -1
		elseif cmpLast == "after" then
			TSMAPI:Assert(cmpFirst == "after")
			searchDirection = 1
		elseif cmpFirst == "equal" and cmpLast == "equal" then
			-- It could be either on the next or previous page. If we're already going in a
			-- direction, keep going. Otherwise, start from page 0 and do a slow search.
			if not searchDirection then
				searchDirection = 1
				query.page = -1
				break
			end
		end
		query.page = query.page + (searchDirection or 1)
		if query.page >= totalPages or query.page < 0 then
			private:DoCallback("FOUND_AUCTION", nil)
			return
		end
	end

	private:DoCallback("FOUND_AUCTION", nil)
end

function private.GetAllScanThread(self)
	self:SetThreadName("GETALL_SCAN")

	-- wait until we can send the GetAll query
	while true do
		local canScan, canGetAll = CanSendAuctionQuery()
		if canScan then
			if not canGetAll then
				private:DoCallback("GETALL_BUSY")
				return
			end
			break
		end
		self:Yield(true)
	end

	private:DoCallback("GETALL_QUERY_START")
	QueryAuctionItems("", 0, 0, 0, false, 0, true, false, nil)
	self:WaitForEvent("AUCTION_ITEM_LIST_UPDATE")
	self:WaitForFunction(CanSendAuctionQuery)

	local numAuctions, totalNum = GetNumAuctionItems("list")
	if numAuctions ~= totalNum then
		return private:DoCallback("GETALL_BAD_DATA")
	end
	private:DoCallback("GETALL_PROGRESS", 1, numAuctions)

	-- scan the results (slowly as to not cause disconnects)
	local scanData = {}
	for i=1, numAuctions do
		local itemString = TSMAPI.Item:ToBaseItemString(GetAuctionItemLink("list", i))
		local _, _, stackSize, _, _, _, _, _, _, buyout = GetAuctionItemInfo("list", i)
		if not itemString or not stackSize or not buyout then
			return private:DoCallback("GETALL_BAD_DATA")
		end

		local itemBuyout = TSMAPI.Util:Round(buyout / stackSize)
		if not scanData[itemString] then
			scanData[itemString] = {buyouts={}, minBuyout=0, numAuctions=0}
		end
		if itemBuyout > 0 then
			if scanData[itemString].minBuyout == 0 or itemBuyout < scanData[itemString].minBuyout then
				scanData[itemString].minBuyout = itemBuyout
			end
			for i=1, stackSize do
				tinsert(scanData[itemString].buyouts, itemBuyout)
			end
		end
		scanData[itemString].numAuctions = scanData[itemString].numAuctions + 1

		if i % 500 == 0 then
			private:DoCallback("GETALL_PROGRESS", i, numAuctions)
			self:Sleep(0.1)
		end
		self:Yield()
	end
	private:DoCallback("GETALL_PROGRESS", numAuctions, numAuctions)
	if numAuctions ~= GetNumAuctionItems("list") then
		return private:DoCallback("GETALL_BAD_DATA")
	end

	private:DoCallback("SCAN_COMPLETE", scanData)
end

function private.ScanThreadDone()
	private.scanThreadId = nil
	TSMAPI.Auction:StopScan(private.currentModule)
end

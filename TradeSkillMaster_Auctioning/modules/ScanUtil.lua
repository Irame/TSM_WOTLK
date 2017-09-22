-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Scan = TSM:NewModule("Scan", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local private = {scanThreadId=nil, callbackThreadId=nil, database=nil, filterArgs=nil, lowestAuctionCache={}}



function private:DoCallback(...)
	if private.callbackThreadId then
		TSMAPI.Threading:SendMsg(private.callbackThreadId, {...})
	end
end

function private.ScanThread(self, itemList)
	self:SetThreadName("AUCTIONING_SCAN")
	-- generate queries
	TSM.Manage:UpdateStatus("query", 0, -1)
	TSMAPI.Auction:GenerateQueries(itemList, self:GetSendMsgToSelfCallback())
	local event, queries = unpack(self:ReceiveMsg())
	TSMAPI:Assert(event == "QUERY_COMPLETE")
	TSM.Manage:UpdateStatus("query", 1, 1)
	if #queries == 0 then
		-- nothing to scan
		TSM.Manage:UpdateStatus("scan", 0, 0)
		return
	end
	
	-- scan all the queries
	local scannedItems = {}
	for i=1, #queries do
		TSM.Manage:UpdateStatus("scan", i-1, #queries)
		TSM.Manage:UpdateStatus("page", 0, 1)
		TSMAPI.Auction:ScanQuery("Auctioning", queries[i], self:GetSendMsgToSelfCallback(), true, private.database)
		while true do
			local args = self:ReceiveMsg()
			local event = tremove(args, 1)
			if event == "SCAN_PAGE_UPDATE" then
				TSM.Manage:UpdateStatus("page", unpack(args))
			elseif event == "SCAN_COMPLETE" then
				-- we're done scanning this query
				for _, itemString in ipairs(queries[i].items) do
					if not scannedItems[itemString] then
						scannedItems[itemString] = true
						private:DoCallback("PROCESS_ITEM", itemString)
						self:Yield()
					end
				end
				break
			elseif event == "INTERRUPTED" then
				-- scan was interrupted
				TSM.Manage:StopScan()
				return
			else
				error("Unexpected message: "..tostring(event))
			end
		end
	end
	
	-- we're done scanning
	TSM.Manage:UpdateStatus("scan", #queries, #queries)
	private:DoCallback("DONE_SCANNING")
end

function Scan:StopScanning()
	TSMAPI.Threading:Kill(private.scanThreadId)
	private.scanThreadId = nil
	private.callbackThreadId = nil
end

function Scan:StartItemScan(itemList, callbackThreadId)
	Scan:ClearLowestAuctionCache()
	private.database = TSMAPI.Auction:NewDatabase()
	private.dbView = private.database:CreateView():OrderBy("baseItemString"):OrderBy("itemBuyout")
	Scan:StopScanning()
	Scan:RegisterEvent("AUCTION_HOUSE_CLOSED", Scan.StopScanning)
	private.callbackThreadId = callbackThreadId
	private.scanThreadId = TSMAPI.Threading:Start(private.ScanThread, 0.7, Scan.StopScanning, itemList)
end

function Scan:GetDatabase()
	return private.database
end

function Scan:GetDatabaseView()
	return private.dbView
end

function Scan:ClearLowestAuctionCache()
	wipe(private.lowestAuctionCache)
end

function Scan:GetFilterFunction(itemString, operation)
	return function(record)
		private.filterItemString = itemString
		private.filterOperation = operation
		local result = private.AuctionRecordFilter(record)
		private.filterItemString = nil
		private.filterOperation = nil
		return result
	end
end

function Scan:Clear()
	private.database = nil
	private.dbView = nil
end


function private.AuctionRecordFilter(record)
	TSMAPI:Assert(private.filterItemString and private.filterOperation)
	if record.itemString ~= private.filterItemString and record.baseItemString ~= private.filterItemString then
		return
	end
	if record.buyout == 0 then
		return
	end
	if record.timeLeft <= private.filterOperation.ignoreLowDuration then
		-- ignoring low duration
		return
	elseif private.filterOperation.matchStackSize and record.stackSize ~= private.filterOperation.stackSize then	
		-- matching stack size
		return
	elseif private.filterOperation.priceReset == "ignore" and record.itemBuyout then
		local minPrice = TSM.Util:GetMinPrice(private.filterOperation, record.itemString)
		if minPrice and record.itemBuyout <= minPrice then	
			-- ignoring auctions below threshold
			return
		end
	end
	return true
end

function private:GetAuctionRecords(itemString, operation)
	private.filterItemString = itemString
	private.filterOperation = operation
	private.dbView:SetFilter(private.AuctionRecordFilter, itemString..tostring(operation))
	local auctionRecords = private.dbView:Execute()
	private.filterItemString = nil
	private.filterOperation = nil
	return auctionRecords
end

function private.LowestAuctionSort(a, b)
	if a.isBlacklist == b.isBlacklist then
		if a.isWhitelist == b.isWhitelist then
			if a.isPlayer == b.isPlayer then
				return tostring(a) < tostring(b)
			end
			return a.isPlayer
		end
		return a.isWhitelist
	end
	return a.isBlacklist
end

-- Find out the lowest price for this item
function Scan:GetLowestAuction(itemString, operation)
	if private.lowestAuctionCache[itemString..tostring(operation)] then
		return private.lowestAuctionCache[itemString..tostring(operation)]
	end
	local lowestBuyoutInfo = nil
	for _, record in ipairs(private:GetAuctionRecords(itemString, operation)) do
		if not lowestBuyoutInfo then
			-- this is a record at the lowest buyout
			lowestBuyoutInfo = {}
			lowestBuyoutInfo.buyout = record.itemBuyout
		end
		if record.itemBuyout == lowestBuyoutInfo.buyout then
			local temp = {buyout=record.itemBuyout, bid=record.itemDisplayedBid, seller=record.seller}
			temp.isWhitelist = TSM.db.factionrealm.whitelist[strlower(record.seller)] and true or false
			temp.isPlayer = TSMAPI.Player:IsPlayer(record.seller, true, true, true)
			if not temp.isWhitelist and not temp.isPlayer then
				-- there is a non-whitelisted competitor, so we don't care if a whitelisted competitor also posts at this price
				lowestBuyoutInfo.ignoreWhitelist = true
			end
			if record.seller == "?" and next(TSM.db.factionrealm.whitelist) then
				lowestBuyoutInfo.hasInvalidSeller = true
			end
			if operation.blacklist then
				local blacklist = {(","):split(operation.blacklist)}
				for _, player in ipairs(blacklist) do
					if strlower(player:trim()) == strlower(record.seller) then
						temp.isBlacklist = true
						break
					end
				end
			end
			tinsert(lowestBuyoutInfo, temp)
		else
			-- no more records of interest
			break
		end
	end
	
	if not lowestBuyoutInfo then return end
	
	-- prioritize blacklist, then whitelist, then player
	sort(lowestBuyoutInfo, private.LowestAuctionSort)
	-- preserve the hasInvalidSeller flag
	lowestBuyoutInfo[1].hasInvalidSeller = lowestBuyoutInfo.hasInvalidSeller
	if lowestBuyoutInfo[1].isWhitelist and lowestBuyoutInfo.ignoreWhitelist then
		lowestBuyoutInfo[1].isWhitelist = false
	end
	private.lowestAuctionCache[itemString..tostring(operation)] = lowestBuyoutInfo[1]
	return private.lowestAuctionCache[itemString..tostring(operation)]
end

-- gets the buyout / bid of the next lowest auction of the item
function Scan:GetNextLowest(itemString, lowestBuyout, operation)
	for _, record in ipairs(private:GetAuctionRecords(itemString, operation)) do
		if record.itemBuyout > lowestBuyout then
			return record.itemBuyout, record.itemDisplayedBid
		end
	end
end

-- This gets how many auctions are posted specifically at this pricing tier.
-- It does not get how many of the items are up at this pricing tier but purely the number of auctions.
function Scan:GetPlayerAuctionCount(itemString, findBuyout, findBid, findStackSize, operation)
	findBuyout = floor(findBuyout)
	findBid = floor(findBid)
	local quantity = 0
	for _, record in ipairs(private:GetAuctionRecords(itemString, operation)) do
		if record.itemBuyout == findBuyout and record.itemDisplayedBid == findBid and record.stackSize == findStackSize and TSMAPI.Player:IsPlayer(record.seller, true, true, true) then
			quantity = quantity + 1
		end
	end
	
	return quantity
end

-- returns true if the current player is the only seller
function Scan:IsPlayerOnlySeller(itemString, operation)
	for _, record in ipairs(private:GetAuctionRecords(itemString, operation)) do
		if not TSMAPI.Player:IsPlayer(record.seller, true, true, true) then
			return false
		end
	end
	return true
end

-- gets the buyout of the current player's cheapest auction
function Scan:GetPlayerLowestBuyout(itemString, operation)
	for _, record in ipairs(private:GetAuctionRecords(itemString, operation)) do
		if TSMAPI.Player:IsPlayer(record.seller, true, true, true) then
			return record.itemBuyout
		end
	end
end
-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Auctioning - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctioning.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local Scan = TSM:NewModule("Scan", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

Scan.auctionData = {}
local auctionData = Scan.auctionData

function Scan:StartItemScan(filterList)
	wipe(auctionData)
	TSMAPI:StartScan(filterList, function(...) Scan:OnCallback(...) end, {sellerResolution=true, queryFinishedCallbacks=true, missingSellerName="?", maxRetries=TSM.db.global.maxRetries})
end

function Scan:ShouldIgnoreAuction(record)
	if not record.parent.group then
		local itemString = record.parent:GetItemString()
		local itemID = record.parent:GetItemID()
		if not TSM.itemReverseLookup[itemString] and TSM.itemReverseLookup[itemID] then
			itemString = itemID
		end
		record.parent.group = TSM.Config:GetConfigObject(itemString)
	end
	local group = record.parent.group
	return (record.timeLeft <= group.minDuration or record.count > group.ignoreStacksOver or record.count < group.ignoreStacksUnder)
end

function Scan:ShouldScan(itemString, mode, groups)
	local isGroupDisabled = TSM.Config:GetBoolConfigValue(itemString, "disabled")
	local isGroupNoCancel = (mode == "Cancel") and TSM.Config:GetBoolConfigValue(itemString, "noCancel")
	local isGroupCustomDisabled = groups and not groups[TSM.itemReverseLookup[itemString]]
	
	return not (isGroupDisabled or isGroupNoCancel or isGroupCustomDisabled)
end

function Scan:OnCallback(event, data, arg2)
	local msg, args = nil, {}
	if event == "QUERY_FINISHED" then
		Scan:ProcessAuctionData(data.data, data.filter.arg)
		msg = "TSMAuc_"..event
		args = {data.filter.arg, data.data}
   elseif event == "NEW_ITEM_DATA" then
		for _, itemString in ipairs(data.filter.arg) do
			-- only process this item if we meant to search for it
			if itemString == data.item then
				Scan:ProcessAuctionData(data.data, data.item)
				msg = "TSMAuc_"..event
				args = {data.item, data.data}
				break
			end
		end
	elseif event == "SCAN_COMPLETE" or event == "SCAN_INTERRUPTED" then
		msg = "TSMAuc_"..event
	elseif event == "SCAN_STATUS_UPDATE" then
		msg = "TSMAuc_SCAN_NEW_PAGE"
		args = {TSMAPI:SafeDivide(data,arg2)}
	elseif event == "SCAN_ERROR" then
		TSM:Print(L["Error with scan. Scanned item multiple times unexpectedly. You can try restarting the scan. Item:"].." "..data)
	end
	
	if msg then
		TSMAPI:CreateTimeDelay("aucScanMsgDelay"..random(), 0.05, function() Scan:SendMessage(msg, unpack(args)) end)
	end
end

-- map the scan results to Auctioning's data format
function Scan:ProcessAuctionData(scanData, newItem)
	local auction = scanData[newItem]
	if not auction then return end
	auction:SetRecordParams({"GetItemBuyout", "GetItemDisplayedBid", "seller"})
	auction:PopulateCompactRecords()
	auction:SetAlts(TSM.db.factionrealm.player)
	if #auction.records > 0 then
		auction:SetMarketValue(TSMAPI:GetData("market", auction:GetItemID()))
		auctionData[newItem] = auction
	end
end

-- This gets how many auctions are posted specifically on this tier, it does not get how many of the items they up at this tier
-- but purely the number of auctions
function Scan:GetPlayerAuctionCount(itemString, findBuyout, findBid)
	findBuyout = floor(findBuyout)
	findBid = floor(findBid)
	
	local quantity = 0
	for _, record in ipairs(auctionData[itemString].compactRecords) do
		if not Scan:ShouldIgnoreAuction(record) and record:IsPlayer() then
			if record:GetItemBuyout() == findBuyout and record:GetItemDisplayedBid() == findBid then
				quantity = quantity + record.numAuctions
			end
		end
	end
	
	return quantity
end

-- gets the buyout / bid of the second lowest auction for this item
function Scan:GetSecondLowest(itemString, lowestBuyout)
	local auctionItem = auctionData[itemString]
	if not auctionItem then return end
	
	local buyout, bid
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record) then
			local recordBuyout = record:GetItemBuyout()
			if recordBuyout and (not buyout or recordBuyout < buyout) and recordBuyout > lowestBuyout then
				buyout, bid = recordBuyout, record:GetItemDisplayedBid()
			end
		end
	end
	
	return buyout, bid
end

-- Find out the lowest price for this item
function Scan:GetLowestAuction(auctionItem)
	if type(auctionItem) == "string" or type(auctionItem) == "number" then -- it's an itemString (from the logST code)
		auctionItem = auctionData[auctionItem]
	end
	if not auctionItem then return end
	
	-- Find lowest
	local buyout, bid, owner, invalidSellerEntry
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record) then
			local recordBuyout = record:GetItemBuyout()
			if recordBuyout then
				local recordBid = record:GetItemDisplayedBid()
				if not buyout or recordBuyout < buyout or (recordBuyout == buyout and recordBid < bid) then
					buyout, bid, owner = recordBuyout, recordBid, record.seller
				end
			end
		end
	end
	if owner == "?" and (next(TSM.db.factionrealm.whitelist) or next(TSM.db.factionrealm.blacklist)) then
		invalidSellerEntry = true
	end

	-- Now that we know the lowest, find out if this price "level" is a friendly person
	-- the reason we do it like this, is so if Apple posts an item at 50g, Orange posts one at 50g
	-- but you only have Apple on your white list, it'll undercut it because Orange posted it as well
	-- However, if either Apple or Orange are on your blacklist, we will undercut this auction
	local isWhitelist, isBlacklist, isPlayer = true, false, true
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record) then
			local recordBuyout = record:GetItemBuyout()
			if not record:IsPlayer() and recordBuyout and recordBuyout == buyout then
				isPlayer = nil
				if not TSM.db.factionrealm.whitelist[strlower(record.seller)] then
					isWhitelist = nil
				end
				
				if TSM.db.factionrealm.blacklist[strlower(record.seller)] then
					isBlacklist = true
				end
				
				-- If the lowest we found was from the player, but someone else is matching it (and they aren't on our white list)
				-- then we swap the owner to that person
				buyout, bid, owner = recordBuyout, record:GetItemDisplayedBid(), record.seller
			end
		end
	end
	if owner == "?" and (next(TSM.db.factionrealm.whitelist) or next(TSM.db.factionrealm.blacklist)) then
		invalidSellerEntry = true
	end

	return buyout, bid, owner, isWhitelist, isBlacklist, isPlayer, invalidSellerEntry
end

function Scan:GetPlayerLowestBuyout(auctionItem)
	if not auctionItem then return end
	
	-- Find lowest
	local buyout
	for _, record in ipairs(auctionItem.compactRecords) do
		if not Scan:ShouldIgnoreAuction(record) then
			local recordBuyout = record:GetItemBuyout()
			if record:IsPlayer() and recordBuyout and (not buyout or recordBuyout < buyout) then
				buyout = recordBuyout
			end
		end
	end

	return buyout
end
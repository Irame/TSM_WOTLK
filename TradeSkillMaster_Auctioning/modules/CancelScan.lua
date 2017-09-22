-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Cancel = TSM:NewModule("Cancel", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local private = {queue={}, threadId=nil, specialScanOptions=nil}
local CANCEL_ALL_OPERATION = {isFake=true}


function Cancel:StartScan(isGroup, scanInfo)
	wipe(private.queue)
	wipe(TSM.operationLookup)
	private.specialScanOptions = nil
	TSM.operationNameLookup[CANCEL_ALL_OPERATION] = "|cffff0000"..L["Cancel All"].."|r"
	local processedItems, scanList = {}, {}

	for i=1, GetNumAuctionItems("owner") do
		local name, _, quantity, _, _, _, _, _, _, _, bid, _, _, _, _, isSold = GetAuctionItemInfo("owner", i)
		local itemString
		if isGroup then
			itemString = TSMAPI.Item:ToBaseItemString(GetAuctionItemLink("owner", i), true)
		else
			itemString = TSMAPI.Item:ToItemString(GetAuctionItemLink("owner", i))
		end
		if isSold == 0 and itemString and not processedItems[itemString] then
			processedItems[itemString] = true
			if isGroup then
				if not TSM.db.global.cancelWithBid and bid > 0 then
					-- we aren't canceling auctions with bids
					TSM.Log:AddLogRecord(itemString, "cancel", "Skip", "bid", CANCEL_ALL_OPERATION)
				elseif scanInfo[itemString] then
					local operations = {}
					for _, operation in pairs(scanInfo[itemString]) do
						if operation.cancelUndercut or operation.cancelRepost then
							tinsert(operations, operation)
						end
					end
					if #operations > 0 then
						TSM.operationLookup[itemString] = operations
						local isValid
						for _, operation in pairs(operations) do
							if operation.cancelUndercut or operation.cancelRepost then
								isValid = true
								if not private:ValidateOperation(itemString, operation) then
									isValid = nil
									break
								end
							end
						end
						if isValid then
							tinsert(scanList, itemString)
						end
					end
				end
			else
				if scanInfo.cancelAll then
					if not TSM.db.global.cancelWithBid and bid > 0 then
						-- we aren't canceling auctions with bids
						TSM.Log:AddLogRecord(itemString, "cancel", "Skip", "bid", CANCEL_ALL_OPERATION)
					else
						tinsert(scanList, itemString)
					end
				elseif scanInfo.duration then
					local timeLeft = GetAuctionItemTimeLeft("owner", i)
					if timeLeft <= scanInfo.duration then
						if not TSM.db.global.cancelWithBid and bid > 0 then
							-- we aren't canceling auctions with bids
							TSM.Log:AddLogRecord(itemString, "cancel", "Skip", "bid", CANCEL_ALL_OPERATION)
						else
							tinsert(scanList, itemString)
						end
					end
				elseif scanInfo.filter then
					if strfind(strlower(name), strlower(scanInfo.filter)) then
						if not TSM.db.global.cancelWithBid and bid > 0 then
							-- we aren't canceling auctions with bids
							TSM.Log:AddLogRecord(itemString, "cancel", "Skip", "bid", CANCEL_ALL_OPERATION)
						else
							tinsert(scanList, itemString)
						end
					end
				end
			end
		end
	end

	if #scanList == 0 then return false end
	private.specialScanOptions = not isGroup and scanInfo
	if isGroup then
		TSM:AnalyticsEvent("CANCEL_GROUP_START")
	elseif scanInfo.cancelAll then
		TSM:AnalyticsEvent("CANCEL_ALL_START")
	elseif scanInfo.duration then
		TSM:AnalyticsEvent("CANCEL_DURATION_START", scanInfo.duration)
	elseif scanInfo.filter then
		TSM:AnalyticsEvent("CANCEL_FILTER_START")
	end
	private.threadId = TSMAPI.Threading:Start(private.CancelScanThread, 0.7, TSM.Manage.StopScan, scanList)
	return true
end

function private:ValidateOperation(itemString, operation)
	local prices = TSM.Util:GetItemPrices(operation, itemString, false, {minPrice=true, normalPrice=true, maxPrice=true, cancelRepostThreshold=true, undercut=true})
	local errMsg = nil

	-- don't cancel this item if their settings are invalid
	if not prices.minPrice then
		errMsg = format(L["Did not cancel %s because your minimum price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.minPrice)
	elseif not prices.maxPrice then
		errMsg = format(L["Did not cancel %s because your maximum price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.maxPrice)
	elseif not prices.normalPrice then
		errMsg = format(L["Did not cancel %s because your normal price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.normalPrice)
	elseif operation.cancelRepost and not prices.cancelRepostThreshold then
		errMsg = format(L["Did not cancel %s because your cancel to repost threshold (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.cancelRepostThreshold)
	elseif not prices.undercut then
		errMsg = format(L["Did not cancel %s because your undercut (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.undercut)
	elseif prices.maxPrice < prices.minPrice then
		errMsg = format(L["Did not cancel %s because your maximum price (%s) is lower than your minimum price (%s). Check your settings."], TSMAPI.Item:GetLink(itemString), operation.maxPrice, operation.minPrice)
	elseif prices.normalPrice < prices.minPrice then
		errMsg = format(L["Did not cancel %s because your normal price (%s) is lower than your minimum price (%s). Check your settings."], TSMAPI.Item:GetLink(itemString), operation.normalPrice, operation.minPrice)
	end

	if errMsg then
		if not TSM.db.global.disableInvalidMsg then
			TSM:Print(errMsg)
		end
		TSM.Log:AddLogRecord(itemString, "cancel", "Skip", "invalid", operation)
		return false
	else
		return true
	end
end

function private.CancelScanThread(self, scanList)
	self:SetThreadName("AUCTIONING_CANCEL_SCAN")
	local currentItem, doneScanning
	local numToCancel, numCanceled, numConfirmed = 0, 0, 0
	local usedItemIndex, itemsCanceled, failedCancels = {}, {}, {}
	TSM.GUI:SetScanThreadId(self:GetThreadId())
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) if msg == ERR_AUCTION_REMOVED then self:SendMsgToSelf("ACTION_CONFIRMED") end end)
	self:RegisterEvent("UI_ERROR_MESSAGE", function(_, msg) if msg == ERR_ITEM_NOT_FOUND then self:SendMsgToSelf("ACTION_FAILED") end end)

	if private.specialScanOptions then
		for _, itemString in ipairs(scanList) do
			self:SendMsgToSelf("PROCESS_ITEM", itemString)
		end
		self:SendMsgToSelf("DONE_SCANNING")
		TSM.Manage:UpdateStatus("query", 1, 1)
		TSM.Manage:UpdateStatus("scan", 1, 1)
	else
		TSM.Scan:StartItemScan(scanList, self:GetThreadId())
	end

	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "PROCESS_ITEM" then
			-- process a newly scanned item
			local itemString = unpack(args)
			numToCancel = numToCancel + private:ProcessItem(self, itemString)
			TSM.GUI:UpdateSTData()
		elseif event == "DONE_SCANNING" then
			-- we are done scanning
			doneScanning = true
			sort(private.queue, function(a, b) return (a.index or 0) > (b.index or 0) end)
			TSMAPI:DoPlaySound(TSM.db.global.scanCompleteSound)
		elseif event == "ACTION_BUTTON" then
			-- cancel an auction
			TSM.GUI:SetButtonsEnabled(false)
			-- figure out which index the item goes to
			local index, backupIndex
			for i=GetNumAuctionItems("owner"), 1, -1 do
				local _, _, quantity, _, _, _, _, bid, _, buyout, activeBid = GetAuctionItemInfo("owner", i)
				local itemString
				if private.specialScanOptions then
					-- use regular item strings for special scans
					itemString = TSMAPI.Item:ToItemString(GetAuctionItemLink("owner", i))
				else
					itemString = TSMAPI.Item:ToBaseItemString(GetAuctionItemLink("owner", i), true)
				end
				bid = bid or 0
				buyout = buyout or 0
				if itemString == currentItem.itemString and abs(buyout - (currentItem.buyout or 0)) < quantity and abs(bid - (currentItem.bid or 0)) < quantity and (not TSM.db.global.cancelWithBid and activeBid == 0 or TSM.db.global.cancelWithBid) then
					if not usedItemIndex[itemString..buyout..bid..i] then
						usedItemIndex[itemString..buyout..bid..i] = true
						index = i
						break
					else
						backupIndex = backupIndex or i
					end
				end
			end
			-- if we found an index then cancel the item
			if index then
				CancelAuction(index)
			elseif backupIndex then
				CancelAuction(backupIndex)
			end
			tinsert(itemsCanceled, tremove(private.queue, 1))
			numCanceled = numCanceled + 1
		elseif event == "ACTION_CONFIRMED" then
			-- a cancel has been confirmed by the server
			numConfirmed = numConfirmed + 1
		elseif event == "ACTION_FAILED" then
			-- a cancel has failed
			numConfirmed = numConfirmed + 1
			TSM:LOG_INFO("Failed to cancel auction (%d, %d, %d)", numConfirmed, #failedCancels, #itemsCanceled)
			tinsert(failedCancels, itemsCanceled[numConfirmed].itemString)
		elseif event == "SKIP_BUTTON" then
			-- skip the current item
			tinsert(itemsCanceled, tremove(private.queue, 1))
			numConfirmed = numConfirmed + 1
			numCanceled = numCanceled + 1
		else
			error("Unpexected message: "..tostring(event))
		end

		-- update the current item / button state
		currentItem = #private.queue > 0 and private.queue[1] or nil
		TSM.GUI:SetButtonsEnabled(currentItem and true or false)
		TSM.Manage:SetCurrentItem(currentItem)
		if numToCancel > 0 then
			TSM.Manage:UpdateStatus("manage", numCanceled, numToCancel)
			TSM.Manage:UpdateStatus("confirm", numConfirmed, numToCancel)
		end

		if doneScanning and numConfirmed == numToCancel then
			if #failedCancels > 0 then
				numCanceled = numToCancel
				for _, itemString in ipairs(failedCancels) do
					numToCancel = numToCancel + private:ProcessItem(self, itemString, true)
					self:Yield()
				end
				wipe(failedCancels)
				-- send a message to ourselves in order to refresh the current item / status
				TSMAPI.Threading:SendMsg(self:GetThreadId(), {"DONE_SCANNING"})
			else
				-- we're done canceling
				TSMAPI:DoPlaySound(TSM.db.global.confirmCompleteSound)
				TSM.Manage:StopScan() -- will kill this thread
				return
			end
		end
	end
end

function private:ProcessItem(self, itemString, noLog)
	local numAddedToQueue = 0
	if private.specialScanOptions then
		for i=GetNumAuctionItems("owner"), 1, -1 do
			local name, _, quantity, _, _, _, _, bid, _, buyout, activeBid, _, _, _, _, isSold = GetAuctionItemInfo("owner", i)
			if isSold == 0 and (TSM.db.global.cancelWithBid or activeBid == 0) then
				if itemString == TSMAPI.Item:ToItemString(GetAuctionItemLink("owner", i)) then
					local shouldCancel = false
					if private.specialScanOptions.cancelAll then
						shouldCancel = true
					elseif private.specialScanOptions.duration then
						local timeLeft = GetAuctionItemTimeLeft("owner", i)
						if timeLeft <= private.specialScanOptions.duration then
							shouldCancel = true
						end
					elseif private.specialScanOptions.filter then
						if strfind(strlower(name), strlower(private.specialScanOptions.filter)) then
							shouldCancel = true
						end
					end
					if shouldCancel then
						numAddedToQueue = numAddedToQueue + 1
						tinsert(private.queue, {itemString=itemString, stackSize=quantity, buyout=buyout, bid=bid, index=i, numStacks=1, operation=CANCEL_ALL_OPERATION})
						if not noLog then
							TSM.Log:AddLogRecord(itemString, "cancel", "Cancel", "cancelAll", CANCEL_ALL_OPERATION)
						end
					end
				end
			end
		end
	else
		if not TSM.operationLookup[itemString] then return 0 end
		for _, operation in pairs(TSM.operationLookup[itemString]) do
			local toCancel, reasonToCancel, reasonNotToCancel, lowBuyout
			local cancelAuctions = {}
			for i=GetNumAuctionItems("owner"), 1, -1 do
				local buyout, _, _, _, _, _, isSold = select(10, GetAuctionItemInfo("owner", i))
				if isSold == 0 and itemString == TSMAPI.Item:ToBaseItemString(GetAuctionItemLink("owner", i), true) then
					local shouldCancel, reason = private:ShouldCancel(i, itemString, operation)
					if shouldCancel then
						shouldCancel.reason = reason
						tinsert(cancelAuctions, shouldCancel)
						lowBuyout = lowBuyout and min(lowBuyout, buyout) or buyout
					else
						reasonNotToCancel = reasonNotToCancel or reason
						lowBuyout = lowBuyout and min(lowBuyout, buyout) or buyout
					end
				end
				self:Yield()
			end

			local numKept = 0
			sort(cancelAuctions, function(a, b) return a.buyout < b.buyout end)
			for i=#cancelAuctions, 1, -1 do
				local auction = cancelAuctions[i]
				if (auction.reason == "whitelistUndercut" or auction.reason == "undercut" or auction.reason == "notLowest") and numKept < operation.keepPosted then
					numKept = numKept + 1
					reasonNotToCancel = "keepPosted"
				else
					toCancel = true
					reasonToCancel = auction.reason
					numAddedToQueue = numAddedToQueue + 1
					tinsert(private.queue, auction)
				end
			end

			if not noLog then
				if toCancel then
					TSM.Log:AddLogRecord(itemString, "cancel", "Cancel", reasonToCancel, operation, lowBuyout)
				elseif reasonNotToCancel then
					TSM.Log:AddLogRecord(itemString, "cancel", "Skip", reasonNotToCancel, operation, lowBuyout)
				end
			end
		end
	end
	return numAddedToQueue
end

function private:ShouldCancel(index, itemString, operation)
	local _, _, quantity, _, _, _, _, bid, _, buyout, activeBid, _, _, _, _, wasSold = GetAuctionItemInfo("owner", index)
	local buyoutPerItem = floor(buyout / quantity)
	local bidPerItem = floor(bid / quantity)
	if operation.matchStackSize and quantity ~= operation.stackSize then
		return
	end

	local cancelData = {itemString=itemString, stackSize=quantity, buyout=buyout, bid=bid, index=index, numStacks=1, operation=operation}
	local lowestAuction = TSM.Scan:GetLowestAuction(itemString, operation)
	local prices = TSM.Util:GetItemPrices(operation, itemString, false, {minPrice=true, normalPrice=true, maxPrice=true, resetPrice=true, cancelRepostThreshold=true, undercut=true, aboveMax=true})

	if not lowestAuction then
		-- all auctions which are posted (including ours) have been ignored, so we should cancel to post higher
		if operation.cancelRepost and prices.normalPrice - buyoutPerItem > prices.cancelRepostThreshold then
			return cancelData, "repost"
		else
			return false, "notUndercut"
		end
	elseif lowestAuction.isInvalidSeller then
		TSM:Printf(L["The seller name of the lowest auction for %s was not given by the server. Skipping this item."], GetAuctionItemLink("owner", index))
		return false, "invalidSeller"
	end

	if not TSM.db.global.cancelWithBid and activeBid > 0 then
		-- Don't cancel an auction if it has a bid and we're set to not cancel those
		return false, "bid"
	end

	local secondLowestBuyout = TSM.Scan:GetNextLowest(itemString, lowestAuction.buyout, operation) or 0
	if buyoutPerItem < prices.minPrice and not lowestAuction.isBlacklist then
		-- this auction is below min price
		if operation.cancelRepost and prices.resetPrice and buyoutPerItem < (prices.resetPrice - prices.cancelRepostThreshold) then
			-- canceling to post at reset price
			return cancelData, "reset"
		end
		return false, "belowMinPrice"
	elseif lowestAuction.buyout < prices.minPrice and not lowestAuction.isBlacklist then
		-- lowest buyout is below min price, so do nothing
		return false, "belowMinPrice"
	else
		-- lowest buyout is above the min price
		if operation.cancelUndercut and (buyoutPerItem - prices.undercut) > (TSM.Scan:GetPlayerLowestBuyout(itemString, operation) or math.huge) then
			-- this is not our lowest auction
			return cancelData, "notLowest"
		elseif TSM.Scan:IsPlayerOnlySeller(itemString, operation) then
			-- we are posted at the aboveMax price with no competition under our max price
			-- check if we can repost higher
			if operation.cancelRepost and prices.normalPrice - buyoutPerItem > prices.cancelRepostThreshold then
				-- we can repost higher
				return cancelData, "repost"
			end
			return false, "atNormal"
		elseif lowestAuction.isPlayer and (secondLowestBuyout > prices.maxPrice) then
			-- we are posted at the aboveMax price with no competition under our max price
			-- check if we can repost higher
			if operation.cancelRepost and operation.aboveMax ~= "none" and prices.aboveMax - buyoutPerItem > prices.cancelRepostThreshold then
				-- we can repost higher
				return cancelData, "repost"
			end
			return false, "atAboveMax"
		elseif lowestAuction.isPlayer then
			-- we are the loewst auction
			-- check if we can repost higher
			if operation.cancelRepost and ((secondLowestBuyout - prices.undercut) - lowestAuction.buyout) > prices.cancelRepostThreshold then
				-- we can repost higher
				return cancelData, "repost"
			end
			return false, "notUndercut"
		elseif not operation.cancelUndercut then
			return -- we're undercut but not canceling undercut auctions
		elseif lowestAuction.isWhitelist and buyoutPerItem == lowestAuction.buyout then
			-- at whitelisted player price
			return false, "atWhitelist"
		elseif not lowestAuction.isWhitelist then
			-- we've been undercut by somebody not on our whitelist
			return cancelData, "undercut"
		elseif buyoutPerItem ~= lowestAuction.buyout or bidPerItem ~= lowestAuction.bid then
			-- somebody on our whitelist undercut us (or their bid is lower)
			return cancelData, "whitelistUndercut"
		end
	end

	error("unexpectedly reached end", buyoutPerItem, lowestAuction.buyout, lowestAuction.isWhitelist, lowestAuction.isPlayer, prices.minPrice)
end

function Cancel:StopCanceling()
	TSMAPI.Threading:Kill(private.threadId)
	Cancel:UnregisterAllEvents()
	wipe(private.queue)
	private.threadId = nil
	private.specialScanOptions = nil
end

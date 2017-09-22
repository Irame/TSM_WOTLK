-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Post = TSM:NewModule("Post", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local private = {queue={}, threadId=nil, postInfo=nil}

local QUICK_POST_OPERATION = {
	isFake = true,
	-- general
	matchStackSize = nil,
	blacklist = "",
	ignoreLowDuration = 0,
	-- post
	stackSize = 1,
	stackSizeIsCap = nil,
	postCap = 100,
	keepQuantity = 0,
	keepQtySources = {},
	duration = 24,
	bidPercent = 1,
	undercut = 4,
	maxExpires = 0,
	priceReset = "none",
	aboveMax = "normalPrice",
	-- prices are set in Post:OnEnable() based on the modules which are present
	minPrice = nil,
	maxPrice = nil,
	normalPrice = nil,
}


function Post:OnEnable()
	-- generate the quick posting prices based on the modules they have installed
	local priceSources = {}
	if TSMAPI:HasModule("Crafting") then
		tinsert(priceSources, "crafting")
	end
	if TSMAPI:HasModule("AuctionDB") then
		tinsert(priceSources, "dbmarket")
		tinsert(priceSources, "dbglobalminbuyoutavg")
		tinsert(priceSources, "dbglobalmarketavg")
	end
	if TSMAPI:HasModule("WoWuction") then
		tinsert(priceSources, "wowuctionmarket")
		tinsert(priceSources, "wowuctionregionmarket")
	end

	if #priceSources == 0 then
		tinsert(priceSources, "vendorsell")
	end

	QUICK_POST_OPERATION.minPrice = format("max(0.25*avg(%s), 1.5*vendorsell)", table.concat(priceSources, ","))
	QUICK_POST_OPERATION.maxPrice = format("max(5*avg(%s), 30*vendorsell)", table.concat(priceSources, ","))
	QUICK_POST_OPERATION.normalPrice = format("max(2*avg(%s), 12*vendorsell)", table.concat(priceSources, ","))
end

function Post:StartScan(isGroup, scanInfo)
	wipe(private.queue)
	wipe(TSM.operationLookup)
	TSM.operationNameLookup[QUICK_POST_OPERATION] = "|cffff0000"..L["Quick Post"].."|r"

	local scanList = {}
	local bagState = private:GetBagState()

	for itemString, numHave in pairs(bagState) do
		if isGroup then
			if scanInfo[itemString] then
				local validOperations = {}
				-- get the operations which we have enough items in our bags to satisfy
				for _, operation in ipairs(scanInfo[itemString]) do
					if operation.postCap > 0 and private:HasEnoughToPost(itemString, operation, numHave) then
						local isValid = true
						if operation.maxExpires > 0 and TSMAPI:HasModule("Accounting") then
							local numExpires = select(2, TSMAPI:ModuleAPI("Accounting", "getAuctionStatsSinceLastSale", itemString))
							if type(numExpires) == "number" and numExpires > operation.maxExpires then
								isValid = false
								TSM.Log:AddLogRecord(itemString, "post", "Skip", "maxExpires", operation)
							end
						end
						if isValid then
							tinsert(validOperations, operation)
						end
					elseif operation.postCap > 0 then
						TSM.Log:AddLogRecord(itemString, "post", "Skip", "notEnough", operation)
					end
				end
				-- check if any operation is invalid
				local hasInvalidOperation = false
				for i, operation in ipairs(validOperations) do
					if not private:ValidateOperation(itemString, operation) then
						hasInvalidOperation = true
						break
					end
				end
				if not hasInvalidOperation and #validOperations > 0 then
					TSM.operationLookup[itemString] = validOperations
					tinsert(scanList, itemString)
				end
			end
		else
			local quality = TSMAPI.Item:GetQuality(itemString) or 0
			if quality > 0 and not TSMAPI.Operations:GetFirstByItem(itemString, "Auctioning") and private:HasEnoughToPost(itemString, QUICK_POST_OPERATION, numHave) then
				if private:ValidateOperation(itemString, QUICK_POST_OPERATION, true) then
					TSM.operationLookup[itemString] = {QUICK_POST_OPERATION}
					tinsert(scanList, itemString)
				else
					-- assume it's invalid due to not having any pricing data
					TSM:Printf(L["Could not post %s because there is no pricing data for this item. Please ensure that you have AuctionDB and/or WoWuction price data."], TSMAPI.Item:GetLink(itemString))
				end
			end
		end
	end

	TSM.GUI:UpdateSTData()
	if #scanList == 0 then return false end
	if isGroup then
		TSM:AnalyticsEvent("POST_GROUP_START")
	else
		TSM:AnalyticsEvent("QUICK_POST_START")
	end
	private.threadId = TSMAPI.Threading:Start(private.PostScanThread, 0.7, TSM.Manage.StopScan, scanList)
	return true
end

local bagState, bagInfo, bagInfoUpdate = {}, {}, 0
function private:GetBagState(forceUpdate)
	if bagInfoUpdate == time() and not forceUpdate then
		return bagState, bagInfo
	end
	wipe(bagInfo)
	wipe(bagState)
	for bag, slot, itemString, quantity in TSMAPI.Inventory:BagIterator(true) do
		tinsert(bagInfo, {bag, slot, itemString, quantity})
		bagState[itemString] = (bagState[itemString] or 0) + quantity
	end
	bagInfoUpdate = time()
	return bagState, bagInfo
end

function private:HasEnoughToPost(itemString, operation, numHave)
	local maxStackSize = TSMAPI.Item:GetMaxStack(itemString) or 1
	local perAuction = min(maxStackSize, operation.stackSize)
	local perAuctionIsCap = operation.stackSizeIsCap
	local keepQuantity = operation.keepQuantity
	if operation.keepQtySources.bank then
		keepQuantity = keepQuantity - TSMAPI.Inventory:GetBankQuantity(itemString) - TSMAPI.Inventory:GetReagentBankQuantity(itemString)
	end
	if operation.keepQtySources.guild then
		keepQuantity = keepQuantity - TSMAPI.Inventory:GetGuildQuantity(itemString)
	end

	local num = numHave - max(keepQuantity, 0)
	return num >= perAuction or (perAuctionIsCap and num > 0)
end

function private:ValidateOperation(itemString, operation, silent)
	local errMsg = nil
	local maxStackSize = TSMAPI.Item:GetMaxStack(itemString)
	local vendorSellPrice = TSMAPI.Item:GetVendorPrice(itemString) or 0
	local prices = TSM.Util:GetItemPrices(operation, itemString, false, {minPrice=true, normalPrice=true, maxPrice=true, undercut=true})

	if not prices.minPrice then
		errMsg = format(L["Did not post %s because your minimum price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.minPrice)
	elseif not prices.maxPrice then
		errMsg = format(L["Did not post %s because your maximum price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.maxPrice)
	elseif not prices.normalPrice then
		errMsg = format(L["Did not post %s because your normal price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.normalPrice)
	elseif not prices.undercut then
		errMsg = format(L["Did not post %s because your undercut (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.undercut)
	elseif prices.normalPrice < prices.minPrice then
		errMsg = format(L["Did not post %s because your normal price (%s) is lower than your minimum price (%s). Check your settings."], TSMAPI.Item:GetLink(itemString), operation.normalPrice, operation.minPrice)
	elseif prices.maxPrice < prices.minPrice then
		errMsg = format(L["Did not post %s because your maximum price (%s) is lower than your minimum price (%s). Check your settings."], TSMAPI.Item:GetLink(itemString), operation.maxPrice, operation.minPrice)
	end

	if errMsg then
		if not silent and not TSM.db.global.disableInvalidMsg then
			TSM:Print(errMsg)
		end
		TSM.Log:AddLogRecord(itemString, "post", "Skip", "invalid", operation)
		return false
	else
		if vendorSellPrice > 0 and prices.minPrice <= vendorSellPrice*1.05 then
			-- just a warning, not an error
			TSM:Printf(L["WARNING: You minimum price for %s is below its vendorsell price (with AH cut taken into account). Consider raising your minimum price, or vendoring the item."], TSMAPI.Item:GetLink(itemString))
		end
		return true
	end
end

function private.PostScanThread(self, scanList)
	self:SetThreadName("AUCTIONING_POST_SCAN")
	local numToPost, numPosted, numConfirmed = 0, 0, 0
	local pendingBagChanges = {}
	local lastBagUpdate = 0
	local confirmQueue = {}
	local failedQueue = {}
	private.postInfo = {currentItem=nil, doneScanning=nil, hasPosted={}}
	TSM.GUI:SetScanThreadId(self:GetThreadId())
	TSM.Scan:StartItemScan(scanList, self:GetThreadId())
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) if msg == ERR_AUCTION_STARTED then self:SendMsgToSelf("ACTION_CONFIRMED") end end)
	local ERR_MESSAGES_NO_RETRY = {ERR_AUCTION_REPAIR_ITEM, ERR_AUCTION_LIMITED_DURATION_ITEM, ERR_AUCTION_USED_CHARGES, ERR_AUCTION_WRAPPED_ITEM, ERR_AUCTION_BAG}
	local ERR_MESSAGES = {ERR_ITEM_NOT_FOUND, ERR_AUCTION_DATABASE_ERROR,}
	self:RegisterEvent("UI_ERROR_MESSAGE", function(_, msg) if tContains(ERR_MESSAGES, msg) or tContains(ERR_MESSAGES_NO_RETRY, msg) then ClearCursor() self:SendMsgToSelf("ACTION_FAILED", tContains(ERR_MESSAGES_NO_RETRY, msg) and true) end end)
	self:RegisterEvent("BAG_UPDATE", function()
		if GetTime() > lastBagUpdate then
			lastBagUpdate = GetTime()
			wipe(pendingBagChanges)
		end
	end)
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "PROCESS_ITEM" then
			-- process a newly scanned item
			local itemString = unpack(args)
			numToPost = numToPost + private:ProcessItem(itemString)
		elseif event == "REPROCESS_ITEM" then
			self:Sleep(0.1)
			-- re-process the specified item
			local itemString = unpack(args)
			-- Remove any existing entries for this item from the queue and log
			for i=#private.queue, 1, -1 do
				if private.queue[i].itemString == itemString then
					tremove(private.queue, i)
					numToPost = numToPost - 1
				end
			end
			local logData = TSM.Log:GetData()
			for i=#logData, 1, -1 do
				if logData[i].itemString == itemString then
					tremove(logData, i)
				end
			end
			TSM.Scan:ClearLowestAuctionCache()
			numToPost = numToPost + private:ProcessItem(itemString, 1)
		elseif event == "DONE_SCANNING" then
			-- we are done scanning
			private.postInfo.doneScanning = true
			TSM.GUI:UpdateSTData()
			TSMAPI:DoPlaySound(TSM.db.global.scanCompleteSound)
		elseif event == "ACTION_BUTTON" then
			-- post an auction
			TSM.GUI:SetButtonsEnabled(false)
			private.postInfo.hasPosted[private.postInfo.currentItem.itemString] = true
			ClearCursor()
			AuctionFrameAuctions.duration = private.postInfo.currentItem.postTime -- required to avoid Blizzard errors
			local bag, slot = private:FindItemSlot(private.postInfo.currentItem.itemString, pendingBagChanges, private.postInfo.currentItem.stackSize)
			if bag and slot then
				PickupContainerItem(bag, slot)
				ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton")
				StartAuction(private.postInfo.currentItem.bid, private.postInfo.currentItem.buyout, private.postInfo.currentItem.postTime, private.postInfo.currentItem.stackSize, 1)
				private:UpdatePendingChanges(pendingBagChanges, bag, slot, private.postInfo.currentItem.stackSize, private.postInfo.currentItem.itemString)
				-- wait for the create auction interface to clear
				local timeout = debugprofilestop() + 5000 -- stop waiting after 5 seconds
				while select(3, GetContainerItemInfo(bag, slot)) and AuctionsCreateAuctionButton:IsEnabled() and debugprofilestop() < timeout do self:Yield(true) end
				tinsert(confirmQueue, tremove(private.queue, 1))
				numPosted = numPosted + 1
			else
				-- they could have deleted or otherwise posted the item in which case just pretend we posted it
				tinsert(confirmQueue, tremove(private.queue, 1))
				numPosted = numPosted + 1
			end
		elseif event == "ACTION_CONFIRMED" then
			-- a post has been confirmed by the server
			numConfirmed = numConfirmed + 1
		elseif event == "ACTION_FAILED" then
			-- a post has failed
			numConfirmed = numConfirmed + 1
			local noRetry = unpack(args)
			local info = confirmQueue[numConfirmed]
			if not noRetry then
				tinsert(failedQueue, info)
			end
			TSM:LOG_INFO("Posting auction %d failed (itemString=%s, bid=%s, buyout=%s, stackSize=%d, numStacks=%d, postTime=%d)", numConfirmed, info.itemString, info.bid, info.buyout, info.stackSize, info.numStacks, info.postTime)
		elseif event == "SKIP_BUTTON" then
			-- skip the current item
			for i=#private.queue, 1, -1 do
				if private.queue[i].itemString == private.postInfo.currentItem.itemString and private.queue[i].bid == private.postInfo.currentItem.bid and private.queue[i].buyout == private.postInfo.currentItem.buyout then
					tinsert(confirmQueue, tremove(private.queue, i))
					numConfirmed = numConfirmed + 1
					numPosted = numPosted + 1
				end
			end
		elseif event == "EDIT_POST_PRICE" then
			-- change the post price of the current item
			local itemString, buyout, operation, duration = unpack(args)
			for _, data in ipairs(private.queue) do
				if data.itemString == itemString then
					data.buyout = buyout
					data.bid = buyout * operation.bidPercent
					data.postTime = (duration == 48 and 3) or (duration == 24 and 2) or 1
				end
			end
		else
			error("Unpexected message: "..tostring(event))
		end

		if private.postInfo.doneScanning and numConfirmed == numToPost and #failedQueue > 0 then
			TSM:Printf(L["Blizzard failed to properly post %d auction(s). They have been re-added to the post queue so you can try posting them again."], #failedQueue)
			for i=1, #failedQueue do
				tinsert(private.queue, failedQueue[i])
				numToPost = numToPost + 1
			end
			wipe(failedQueue)
			wipe(pendingBagChanges)
			private:GetBagState(true)
		end

		-- update the current item / button state
		ClearCursor()
		private.postInfo.currentItem = #private.queue > 0 and private.queue[1] or nil
		TSM.GUI:SetButtonsEnabled(private.postInfo.currentItem and true or false)
		TSM.Manage:SetCurrentItem(private.postInfo.currentItem)
		if numToPost > 0 then
			TSM.Manage:UpdateStatus("manage", numPosted, numToPost)
			TSM.Manage:UpdateStatus("confirm", numConfirmed, numToPost)
		end

		if private.postInfo.doneScanning and numConfirmed == numToPost then
			-- we're done posting
			TSMAPI:DoPlaySound(TSM.db.global.confirmCompleteSound)
			TSM.Manage:StopScan() -- will kill this thread
			return
		end
	end
end

function private:ProcessItem(itemString, queueIndex)
	if not TSM.operationLookup[itemString] then return 0 end
	local numToPost = 0
	local bagState = private:GetBagState()
	local numInBags = bagState[itemString] or 0
	local pendingPosts = {}
	for _, operation in ipairs(TSM.operationLookup[itemString]) do
		local keepQuantity = operation.keepQuantity
		if operation.keepQtySources.bank then
			keepQuantity = keepQuantity - TSMAPI.Inventory:GetBankQuantity(itemString) - TSMAPI.Inventory:GetReagentBankQuantity(itemString)
		end
		if operation.keepQtySources.guild then
			keepQuantity = keepQuantity - TSMAPI.Inventory:GetGuildQuantity(itemString)
		end
		keepQuantity = max(keepQuantity, 0)
		local reason, posts, logBuyout = private:ShouldPost(itemString, operation, numInBags-keepQuantity, pendingPosts)
		if posts then
			local postTime = (operation.duration == 48 and 3) or (operation.duration == 24 and 2) or 1
			for _, info in ipairs(posts) do
				local stackSize, numStacks, bid, buyout = unpack(info)
				numInBags = numInBags - (stackSize * numStacks)
				for i=1, numStacks do
					tinsert(pendingPosts, {bid=bid, buyout=buyout, postTime=postTime, stackSize=stackSize, numStacks=(numStacks-i+1), itemString=itemString, operation=operation})
					numToPost = numToPost + 1
				end
			end
		end
		TSM.Log:AddLogRecord(itemString, "post", (posts and L["Post"] or L["Skip"]), reason, operation, logBuyout)
		if numInBags == 0 then break end
	end
	for _, postInfo in ipairs(pendingPosts) do
		if queueIndex then
			tinsert(private.queue, queueIndex, postInfo)
			queueIndex = queueIndex + 1
		else
			tinsert(private.queue, postInfo)
		end
	end
	TSM.GUI:UpdateSTData()

	return numToPost
end

function private:ShouldPost(itemString, operation, numInBags, pendingPosts)
	local maxStackSize = TSMAPI.Item:GetMaxStack(itemString)
	if operation.stackSize > maxStackSize and not operation.stackSizeIsCap then
		return "notEnough"
	end
	local perAuction = min(operation.stackSize, maxStackSize)
	local maxCanPost = min(floor(numInBags / perAuction), operation.postCap)

	if maxCanPost == 0 then
		if operation.stackSizeIsCap then
			perAuction = numInBags
			maxCanPost = 1
		else
			 -- not enough for single post
			return "notEnough"
		end
	end

	local lowestAuction = TSM.Scan:GetLowestAuction(itemString, operation)
	local prices = TSM.Util:GetItemPrices(operation, itemString, false, {minPrice=true, maxPrice=true, normalPrice=true, resetPrice=true, undercut=true, aboveMax=true})

	local reason, bid, buyout
	local activeAuctions = 0
	if not lowestAuction then
		-- post as many as we can at the normal price
		reason = "postingNormal"
		buyout = prices.normalPrice
	elseif lowestAuction.hasInvalidSeller then
		-- we didn't get all the necessary seller info
		TSM:Printf(L["The seller name of the lowest auction for %s was not given by the server. Skipping this item."], TSMAPI.Item:GetLink(itemString))
		return "invalidSeller"
	elseif lowestAuction.isBlacklist and lowestAuction.isPlayer then
		TSM:Printf(L["Did not post %s because you or one of your alts (%s) is on the blacklist which is not allowed. Remove this character from your blacklist."], TSMAPI.Item:GetLink(itemString), lowestAuction.seller)
		return "invalid"
	elseif lowestAuction.isBlacklist and lowestAuction.isWhitelist then
		TSM:Printf(L["Did not post %s because the owner of the lowest auction (%s) is on both the blacklist and whitelist which is not allowed. Adjust your settings to correct this issue."], TSMAPI.Item:GetLink(itemString), lowestAuction.seller)
		return "invalid"
	elseif lowestAuction.buyout <= prices.minPrice then
		if prices.resetPrice then
			-- lowest is below the min price, but there is a reset price
			local resetReasonLookup = {minPrice="postingResetMin", maxPrice="postingResetMax", normalPrice="postingResetNormal"}
			TSMAPI:Assert(resetReasonLookup[operation.priceReset], "Unexpected 'below minimum price' setting: "..tostring(operation.priceReset))
			reason = resetReasonLookup[operation.priceReset]
			buyout = prices.resetPrice
			bid = max(bid or buyout * operation.bidPercent, prices.minPrice)
			activeAuctions = TSM.Scan:GetPlayerAuctionCount(itemString, buyout, bid, perAuction, operation)
		elseif lowestAuction.isBlacklist then
			-- undercut the blacklisted player
			reason = "undercuttingBlacklist"
			buyout = lowestAuction.buyout - prices.undercut
		else
			-- don't post this item
			return "belowMinPrice"
		end
	elseif lowestAuction.isPlayer or (lowestAuction.isWhitelist and TSM.db.global.matchWhitelist) then
		-- we (or a whitelisted play we should match) is lowest, so match the current price and post as many as we can
		activeAuctions = TSM.Scan:GetPlayerAuctionCount(itemString, lowestAuction.buyout, lowestAuction.bid, perAuction, operation)
		if lowestAuction.isPlayer then
			reason = "postingPlayer"
		else
			reason = "postingWhitelist"
		end
		bid = lowestAuction.bid
		buyout = lowestAuction.buyout
	elseif lowestAuction.isWhitelist then
		-- don't undercut a whitelisted player
		return "notPostingWhitelist"
	elseif (lowestAuction.buyout - prices.undercut) > prices.maxPrice then
		-- we'd be posting above the max price, so resort to the aboveMax setting
		local aboveMaxReasons = {minPrice="aboveMaxMin", maxPrice="aboveMaxMax", normalPrice="aboveMaxNormal", none="aboveMaxNoPost"}
		if operation.aboveMax == "none" then
			return "aboveMaxNoPost"
		end
		TSMAPI:Assert(aboveMaxReasons[operation.aboveMax], "Unexpected 'above max price' setting: "..tostring(operation.aboveMax))
		reason = aboveMaxReasons[operation.aboveMax]
		buyout = prices.aboveMax
	else
		-- we just need to do a normal undercut of the lowest auction
		reason = "postingUndercut"
		buyout = lowestAuction.buyout - prices.undercut
	end
	if reason == "undercuttingBlacklist" then
		bid = bid or buyout * operation.bidPercent
	else
		buyout = max(buyout, prices.minPrice)
		bid = max(bid or buyout * operation.bidPercent, prices.minPrice)
	end

	-- check if we can't post anymore
	for _, info in ipairs(pendingPosts) do
		if info.stackSize == perAuction and info.buyout/info.stackSize == buyout then
			activeAuctions = activeAuctions + 1
		end
	end
	maxCanPost = min(operation.postCap - activeAuctions, maxCanPost)
	if maxCanPost <= 0 then
		return "tooManyPosted"
	end

	local extraStack = (maxCanPost < operation.postCap and operation.stackSizeIsCap and (numInBags % perAuction)) or 0
	local posts = {}
	tinsert(posts, {perAuction, maxCanPost, bid*perAuction, buyout*perAuction})
	if extraStack > 0 then
		tinsert(posts, {extraStack, 1, bid*extraStack, buyout*extraStack})
	end
	return reason, posts, buyout
end


function private:GetItemSlotInfo(bagInfo, itemString, pendingBagChanges)
	local slotInfo = {ascendingList={}, descendingList={}, lookup={}}
	for _, info in ipairs(bagInfo) do
		local bag, slot, slotItemString, quantity = unpack(info)
		if slotItemString == itemString then
			for _, info in ipairs(pendingBagChanges) do
				if info.bag == bag and info.slot == slot and info.itemString == itemString then
					quantity = quantity - info.quantity
				end
			end
			if quantity > 0 then
				local slotId = (bag * 1000 + slot)
				slotInfo.lookup[slotId] = quantity
				tinsert(slotInfo.ascendingList, slotId)
				tinsert(slotInfo.descendingList, slotId)
			end
		end
	end
	sort(slotInfo.ascendingList, function(a, b) return a < b end)
	sort(slotInfo.descendingList, function(a, b) return a > b end)
	return slotInfo
end

function private:UpdatePendingChanges(pendingBagChanges, bag, slot, selectedQuantity, itemString, slotInfo)
	if not slotInfo then
		slotInfo = private:GetItemSlotInfo(select(2, private:GetBagState()), itemString, pendingBagChanges)
	end
	local selectedSlotId = bag * 1000 + slot

	-- try to post completely from the selected slot (rule #2)
	if (slotInfo.lookup[selectedSlotId] or 0) >= selectedQuantity then
		tinsert(pendingBagChanges, {bag=bag, slot=slot, quantity=selectedQuantity, itemString=itemString})
		return
	end

	-- try and find a stack at a lower slot which has enough to post from (rule #3)
	for _, slotId in ipairs(slotInfo.ascendingList) do
		if slotId < selectedSlotId then
			local num = slotInfo.lookup[slotId]
			if num >= selectedQuantity then
				local tempBag, tempSlot = floor(slotId / 1000), slotId % 1000
				tinsert(pendingBagChanges, {bag=tempBag, slot=tempSlot, quantity=selectedQuantity, itemString=itemString})
				return
			end
		end
	end

	-- try to post using the selected slot and the lower slots (rule #1)
	local numNeeded = selectedQuantity
	local temp = {}
	for _, slotId in ipairs(slotInfo.descendingList) do
		if slotId <= selectedSlotId then
			local num = slotInfo.lookup[slotId]
			if num > numNeeded then
				-- we just need part of this stack
				local tempBag, tempSlot = floor(slotId / 1000), slotId % 1000
				tinsert(temp, {bag=tempBag, slot=tempSlot, quantity=numNeeded, itemString=itemString})
				numNeeded = 0
			else
				-- use this entire stack
				numNeeded = numNeeded - num
				local tempBag, tempSlot = floor(slotId / 1000), slotId % 1000
				tinsert(temp, {bag=tempBag, slot=tempSlot, quantity=num, itemString=itemString})
			end
			if numNeeded == 0 then
				for _, info in ipairs(temp) do
					tinsert(pendingBagChanges, info)
				end
				return
			end
		end
	end

	-- try the next highest slot (rule #4)
	local nextHighestSlotId = nil
	for _, slotId in ipairs(slotInfo.ascendingList) do
		if slotId > selectedSlotId then
			nextHighestSlotId = slotId
			break
		end
	end
	TSMAPI:Assert(nextHighestSlotId, "This should never happen that we don't find the next highest slot!")
	bag, slot = floor(nextHighestSlotId / 1000), nextHighestSlotId % 1000
	return private:UpdatePendingChanges(pendingBagChanges, bag, slot, selectedQuantity, itemString, slotInfo)
end

function private:FindItemSlot(findItemString, pendingBagChanges, targetQuantity)
	local bagInfo = select(2, private:GetBagState())
	local resultBag, resultSlot, resultExtra = nil, nil, nil
	for _, data in ipairs(bagInfo) do
		local bag, slot, itemString, quantity = unpack(data)
		if findItemString == itemString then
			for _, info in ipairs(pendingBagChanges) do
				if info.bag == bag and info.slot == slot and info.itemString == itemString then
					quantity = quantity - info.quantity
				end
			end
			if quantity > 0 and not resultBag and not resultSlot then
				resultBag = bag
				resultSlot = slot
			end
			local extra = quantity - targetQuantity
			if extra == 0 then
				-- anytime we can use a stack of exactly the right size, we should
				return bag, slot
			elseif extra > 0 then
				if not resultExtra or extra < resultExtra then
					resultBag = bag
					resultSlot = slot
					resultExtra = extra
				end
			elseif not resultExtra then
				resultBag = bag
				resultSlot = slot
			end
		end
	end
	return resultBag, resultSlot
end

function Post:CanBuyAuction(itemString)
	if not itemString or not private.postInfo then return end
	if not private.postInfo.doneScanning then return nil, "scanning" end
	if private.postInfo.hasPosted[itemString] then return nil, "posted" end
	return true
end

function Post:StopPosting()
	TSMAPI.Threading:Kill(private.threadId)
	Post:UnregisterAllEvents()
	wipe(private.queue)
	private.threadId = nil
	private.postInfo = nil
end

-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local AuctionTab = TSM:NewModule("AuctionTab", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local private = { frame = nil, threadId = nil, searchInProgress = false, searchMode = "normal", targetItem = nil }

-- ============================================================================
-- Module Functions
-- ============================================================================

function AuctionTab:OnEnable()
	private.ShowAHTab = TSMAPI.Auction:GetTabShowFunction("Shopping")
	-- setup hooks for inserting item links into the search bar to easily search for items
	local function SearchItemLink(origFunc, link)
		local putIntoChat = origFunc(link)
		if not putIntoChat and private.frame and private.frame:IsVisible() and not private.searchInProgress and TSMAPI.Auction:IsTabVisible("Shopping") then
			local itemString = TSMAPI.Item:ToItemString(link)
			if itemString then
				if itemString == TSMAPI.Item:ToBaseItemString(itemString) then
					AuctionTab:StartSearch({ searchMode = private.searchMode, extraInfo = { searchType = "item" }, item = itemString })
				else
					local name = TSMAPI.Item:GetName(TSMAPI.Item:ToBaseItemString(itemString))
					if not name then return false end
					AuctionTab:StartSearch({ searchMode = private.searchMode, extraInfo = { searchType = "filter" }, filter = name, filterItem = itemString })
				end
				return true
			end
		end
		return putIntoChat
	end

	AuctionTab:RawHook("HandleModifiedItemClick", function(link) return SearchItemLink(AuctionTab.hooks.HandleModifiedItemClick, link) end, true)
	AuctionTab:RawHook("ChatEdit_InsertLink", function(link) return SearchItemLink(AuctionTab.hooks.ChatEdit_InsertLink, link) end, true)
	TSM.AuctionTabFrame:SetPrivate(private)
end

function AuctionTab:Show(parent)
	private:CreateAHFrame(parent)
	private.threadId = TSMAPI.Threading:Start(private.AuctionTabThread, 0.7)
end

function AuctionTab:Hide()
	if not private.frame then return end
	TSMAPI.Threading:Kill(private.threadId)
	private.threadId = nil
	private.frame:Hide()
end

function AuctionTab:StartSearch(searchInfo)
	-- fix a bug in Blizzard's code as of 7.0.x caused by auctions missing from the AH pages
	if not ITEM_QUALITY_COLORS[-1] then
		ITEM_QUALITY_COLORS[-1] = {r=0, b=0, g=0}
	end
	if private.searchInProgress then return end
	private:ShowAHTab()
	TSMAPI:Assert(TSMAPI.Auction:IsTabVisible("Shopping"))
	TSMAPI.Threading:SendMsg(private.threadId, { "START_SEARCH", searchInfo }, true)
	return true
end



-- ============================================================================
-- GUI Related Functions
-- ============================================================================

function private:CreateAHFrame(parent)
	if private.frame then return end
	TSM.AuctionTabFrame:Create(parent)
	TSMAPI.Design:SetFrameColor(private.frame.content)
	TSMAPI.Design:SetFrameColor(private.frame.content.result)
	private.frame.content.result.confirmation:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
	private.frame.content.result.confirmation:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
	TSMAPI.Design:SetFrameColor(private.frame.content.result.confirmation.progress)
	TSMAPI.Design:SetFrameColor(private.frame.content.result.confirmation.buyout)
	TSMAPI.Design:SetFrameColor(private.frame.content.result.confirmation.post)
	TSMAPI.Design:SetFrameColor(private.frame.content.result.confirmation.cancel)
	TSMAPI.Design:SetFrameColor(private.frame.content.result.confirmation.bid)
	private.frame.content.result.confirmation.post.buyoutBox:SetTextInsets(0, 2, 0, 0)
end



-- ============================================================================
-- Scan Threads
-- ============================================================================

function private.ItemScanThread(self, itemList)
	self:SetThreadName("SHOPPING_ITEM_SCAN")
	TSMAPI:Assert(type(itemList) == "table")

	-- generate queries
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
			self:SendMsgToParent("SCAN_DONE")
			return
		else
			error("Unexpected message: " .. tostring(event))
		end
	end

	-- scan all the queries
	local database = TSMAPI.Auction:NewDatabase()
	private.extraInfo.queries = queries
	private.extraInfo.queryCache = {}
	for i = 1, #queries do
		private.frame:UpdateScanStatus("scan", i, #queries)
		private.frame:UpdateScanStatus("page", 0, 1)
		TSMAPI.Auction:ScanQuery("Shopping", queries[i], self:GetSendMsgToSelfCallback(), true, database)
		while true do
			local args = self:ReceiveMsg()
			local event = tremove(args, 1)
			if event == "SCAN_PAGE_UPDATE" then
				-- the page we're scanning has changed
				private.frame:UpdateScanStatus("page", unpack(args))
			elseif event == "SCAN_COMPLETE" then
				-- we're done scanning this query
				self:SendMsgToParent("SCAN_NEW_DATA", database)
				break
			elseif event == "INTERRUPTED" then
				-- scan was interrupted
				self:SendMsgToParent("SCAN_DONE")
				return
			else
				error("Unexpected message: " .. tostring(event))
			end
		end
	end
	self:SendMsgToParent("SCAN_DONE")
end

function private.FilterScanThread(self, filterStr)
	self:SetThreadName("SHOPPING_FILTER_SCAN")
	TSMAPI:Assert(filterStr)

	-- scan all the queries
	local database = TSMAPI.Auction:NewDatabase()
	local queries = TSM.AuctionTabUtil:ParseFilterString(filterStr)
	private.extraInfo.queries = queries
	private.extraInfo.queryCache = {}
	for i = 1, #queries do
		private.frame:UpdateScanStatus("scan", i, #queries)
		private.frame:UpdateScanStatus("page", 0, 1)
		TSMAPI.Auction:ScanQuery("Shopping", queries[i], self:GetSendMsgToSelfCallback(), true, database)
		while true do
			local args = self:ReceiveMsg()
			local event = tremove(args, 1)
			if event == "SCAN_PAGE_UPDATE" then
				-- the page we're scanning has changed
				private.frame:UpdateScanStatus("page", unpack(args))
			elseif event == "SCAN_COMPLETE" then
				-- we're done scanning this query
				self:SendMsgToParent("SCAN_NEW_DATA", database)
				break
			elseif event == "INTERRUPTED" then
				-- scan was interrupted
				self:SendMsgToParent("SCAN_DONE")
				return
			else
				error("Unexpected message: " .. tostring(event))
			end
		end
	end
	self:SendMsgToParent("SCAN_DONE")
end

function private.SniperScanThread(self)
	self:SetThreadName("SHOPPING_SNIPER_SCAN")

	local ignoreCallbacks = nil
	local function ScanCallback(...)
		if ignoreCallbacks then return end
		self:SendMsgToSelf(...)
	end

	-- continously scan the last page
	local numTotalAuctions = 0
	local seenAuctions = {}
	local badSellerRecords = {}
	local scanIteration = 1
	local database = TSMAPI.Auction:NewDatabase()
	database.disableFastFind = true -- we can't do a fast find based on this DB
	local tempDatabase = TSMAPI.Auction:NewDatabase()
	tempDatabase.disableFastFind = true -- we can't do a fast find based on this DB
	TSMAPI.Auction:ScanLastPage("Shopping", ScanCallback, tempDatabase)
	private.frame.content.result.statusBar:SetStatusText(L["Scanning Last Page..."])
	private.frame.content.result.statusBar:UpdateStatus(100, 100)
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "SCAN_COMPLETE" then
			-- go through and insert any new auctions
			local shouldUpdate = false
			for i, record in ipairs(tempDatabase.records) do
				if not seenAuctions[record.hash] or seenAuctions[record.hash] == scanIteration then
					-- add new record which we haven't previously seen
					seenAuctions[record.hash] = scanIteration
					database:InsertAuctionRecord(record)
					badSellerRecords[record.hash] = badSellerRecords[record.hash] or {}
					tinsert(badSellerRecords[record.hash], record)
					shouldUpdate = true
				elseif record.seller ~= "?" and badSellerRecords[record.hash] then
					-- fix missing seller names
					for _, bRecord in ipairs(badSellerRecords[record.hash]) do
						bRecord.seller = record.seller
					end
					badSellerRecords[record.hash] = nil
					shouldUpdate = true
				end
			end
			if shouldUpdate then
				self:SendMsgToParent("SCAN_NEW_DATA", database)
			end
			-- start the scan again
			tempDatabase:WipeRecords()
			TSMAPI.Auction:ScanLastPage("Shopping", ScanCallback, tempDatabase)
			scanIteration = scanIteration + 1
		elseif event == "INTERRUPTED" then
			-- scan was interrupted
			break
		elseif event == "SCAN_PAUSE" then
			-- pause the sniper scan
			ignoreCallbacks = true
			TSMAPI.Auction:StopScan("Shopping")
			ignoreCallbacks = false
		elseif event == "SCAN_RESUME" then
			-- resume the sniper scan
			private.sniperSleeping = debugprofilestop() + 500
			self:Sleep(0.5)
			private.sniperSleeping = nil
			tempDatabase:WipeRecords()
			TSMAPI.Auction:ScanLastPage("Shopping", ScanCallback, tempDatabase)
			scanIteration = scanIteration + 1
			numTotalAuctions = private.frame.content.result.rt:GetTotalAuctions()
		else
			error("Unexpected message: " .. tostring(event))
		end
		local totalAuctions = private.frame.content.result.rt:GetTotalAuctions()
		if totalAuctions ~= numTotalAuctions then
			-- the number of available auctions has changed, so play the appropriate sound
			TSMAPI:DoPlaySound(TSM.db.global.sniperSound)
			numTotalAuctions = totalAuctions
		end
	end
	self:SendMsgToParent("SCAN_DONE")
end



-- ============================================================================
-- Confirmation Threads
-- ============================================================================

function private.BuyAuctionsThread(self, auctionInfo)
	self:SetThreadName("SHOPPING_BUY_AUCTIONS")
	local auctionRecord = auctionInfo.record
	private.frame.content.result.cancelBtn:Disable()
	private.frame.content.result.postBtn:Disable()
	private.frame.content.result.bidBtn:Disable()
	private.frame.content.result.buyoutBtn:Disable()
	private.frame.content.result.confirmation.buyout.buyoutBtn:Disable()
	private.frame.content.result.confirmation.buyout.closeBtn:Enable()
	private.frame.UpdateConfirmation("progress", nil, L["Searching for auction..."])
	local lastMsgIsBid = nil
	local pendingBuyMsg = format(ERR_AUCTION_WON_S, auctionRecord.name)
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg)
		if pendingBuyMsg == msg then
			self:SendMsgToSelf("BUYOUT_PLACED")
		end
	end)
	self:RegisterEvent("UI_ERROR_MESSAGE", function(_, msg) if msg == ERR_AUCTION_HIGHER_BID or msg == ERR_ITEM_NOT_FOUND or msg == ERR_AUCTION_BID_OWN or msg == ERR_NOT_ENOUGH_MONEY then self:SendMsgToSelf("BUYOUT_FAILED") end end)

	local buyoutInfo = { progress = 0, totalNum = auctionInfo.numAuctions, perBuyQuantity = auctionRecord.stackSize }
	if private.searchMode == "crafting" then
		local rate = TSM.AuctionTabUtil:GetConvertRate(private.targetItem, auctionRecord.itemString, auctionRecord)
		buyoutInfo.perBuyQuantity = auctionRecord.stackSize * rate
	end
	while true do
		local indexList = TSMAPI.Auction:FindAuctionNoScan(auctionRecord)
		if not indexList then
			-- clear out the message queue before continuing
			while self:GetNumMsgs() > 0 do self:ReceiveMsg() end
			TSMAPI.Auction:FindAuction("Shopping", auctionRecord, self:GetSendMsgToSelfCallback(), auctionInfo.database)
			local args = self:ReceiveMsg()
			local event = tremove(args, 1)
			indexList = unpack(args)
			if event == "INTERRUPTED" then
				self:SendMsgToParent("CONFIRM_DONE")
				return
			end
			TSMAPI:Assert(event == "FOUND_AUCTION", "Unexpected event: " .. tostring(event))
			if not indexList or #indexList == 0 then
				TSM:LOG_INFO("Could not find auction!")
				private.frame.content.result.rt:RemoveSelectedRecord(buyoutInfo.totalNum)
				self:SendMsgToParent("CONFIRM_DONE")
				TSM:Print(L["Could not find this item on the AH. Removing it."])
				return
			end
		end
		sort(indexList)

		-- we have a list of auction indicies for the item we want to buy
		local buyProgress, confirmProgress = 0, 0
		private.frame.content.result.confirmation.buyout.buyoutBtn:Enable()
		private.frame.content.result.confirmation.buyout.closeBtn:Enable()
		private.frame.UpdateConfirmation("buyout", auctionRecord, buyoutInfo)
		while true do
			local args = self:ReceiveMsg()
			local event = tremove(args, 1)
			if event == "AUCTION_CONFIRMED" then
				local index = tremove(indexList)
				if index then
					buyProgress = buyProgress + 1
					local temp = buyoutInfo.progress
					buyoutInfo.progress = temp + buyProgress
					private.frame.UpdateConfirmation("buyout", auctionRecord, buyoutInfo)
					buyoutInfo.progress = temp
					if not auctionRecord:DoBuyout(index) then
						-- we failed to buy this auction
						TSM:Print(L["Failed to buy this auction. Skipping it."])
						self:SendMsgToSelf("BUYOUT_FAILED")
					end
					private:SetMaxQuantity(auctionRecord, private:GetMaxQuantity(auctionRecord) - buyoutInfo.perBuyQuantity)
				end
				private.frame.content.result.confirmation.buyout.buyoutBtn:Disable()
				private.frame.content.result.confirmation.buyout.closeBtn:Disable()
				if private:GetMaxQuantity(auctionRecord) > 0 and #indexList > 0 then
					-- wait one frame before re-enabling the buttons
					self:Yield(true)
					private.frame.content.result.confirmation.buyout.buyoutBtn:Enable()
					private.frame.content.result.confirmation.buyout.closeBtn:Enable()
				end
			elseif event == "INTERRUPTED" then
				if private.extraInfo.searchType ~= "apiAuctioning" then
					private.frame.content.result.rt:RemoveSelectedRecord(buyProgress)
				end
				self:SendMsgToParent("CONFIRM_DONE")
				return
			elseif event == "BUYOUT_PLACED" or event == "BUYOUT_FAILED" then
				if event == "BUYOUT_FAILED" then
					private:SetMaxQuantity(auctionRecord, private:GetMaxQuantity(auctionRecord) + buyoutInfo.perBuyQuantity)
					local temp = buyoutInfo.progress
					buyoutInfo.progress = temp + 1
					private.frame.UpdateConfirmation("buyout", auctionRecord, buyoutInfo)
					buyoutInfo.progress = temp
				elseif event == "BUYOUT_PLACED" and private.extraInfo and private.extraInfo.buyCallback then
					-- notify the module API user (i.e. Crafting's gathering feature or Auctioning's post scan) that we bought an auction
					private.extraInfo.buyCallback(auctionRecord.itemString, buyoutInfo.perBuyQuantity)
				end
				confirmProgress = confirmProgress + 1
				TSM:LOG_INFO("buy progress: %d %d %d", buyProgress, confirmProgress, #indexList)
				if confirmProgress == buyProgress then
					if private:GetMaxQuantity(auctionRecord) <= 0 then
						-- we've bought the max quantity
						break
					end
					if #indexList == 0 then
						-- do the find scan again
						buyoutInfo.progress = buyoutInfo.progress + buyProgress
						break
					end
				end
			else
				error("Unexpected message: " .. tostring(event))
			end
		end
		TSM:LOG_INFO("Removing auction after buying.")
		private.frame.content.result.rt:RemoveSelectedRecord(buyProgress)
		if buyoutInfo.progress >= auctionInfo.numAuctions or private:GetMaxQuantity(auctionRecord) <= 0 then
			self:Yield(true)
			break
		else
			self:Sleep(1)
			-- clear out the message queue before continuing
			while self:GetNumMsgs() > 0 do self:ReceiveMsg() end
		end
	end
	self:SendMsgToParent("CONFIRM_DONE")
end

function private.PostAuctionsThread(self, auctionInfo)
	self:SetThreadName("SHOPPING_POST_AUCTIONS")
	local auctionRecord = auctionInfo.record
	local postFrame = private.frame.content.result.confirmation.post
	private.frame.content.result.cancelBtn:Disable()
	private.frame.content.result.postBtn:Disable()
	private.frame.content.result.bidBtn:Disable()
	private.frame.content.result.buyoutBtn:Disable()
	postFrame.postBtn:Enable()
	postFrame.closeBtn:Enable()

	local undercut = (TSMAPI:GetCustomPriceValue(TSM.db.global.postUndercut, auctionRecord.itemString) or 1)
	if undercut > auctionRecord.itemBuyout then
		undercut = 1
	end
	if TSMAPI.Player:IsPlayer(auctionRecord.seller, true, true, true) then
		-- don't undercut ourselves
		undercut = 0
	end
	local auctionBuyout
	if auctionRecord.isFake then
		auctionBuyout = TSMAPI:GetCustomPriceValue(TSM.db.global.normalPostPrice, auctionRecord.itemString) or 1000000
	else
		auctionBuyout = auctionRecord.buyout - (undercut * auctionRecord.stackSize)
	end
	local numInBags = TSM.AuctionTabUtil:GetNumInBags(auctionRecord.itemString)
	local inventoryItemString, inventoryRawItemLink = select(3, TSM.AuctionTabUtil:GetItemLocation(auctionRecord.itemString))
	local maxStackSize = TSMAPI.Item:GetMaxStack(auctionRecord.itemLink)
	local maxNumStacks = (maxStackSize == 1) and 1 or math.huge
	local postDuration = postFrame.durationDropdown:GetValue() or 2

	auctionBuyout = floor(auctionBuyout / auctionRecord.stackSize) * min(auctionRecord.stackSize, numInBags)
	local postInfo = { buyout = auctionBuyout, stackSize = min(auctionRecord.stackSize, numInBags), numInBags = numInBags, numStacks = 1, duration = postDuration, updateBuyout = true, isDonePosting = nil, itemLink = TSMAPI.Item:GetLink(inventoryItemString), rawItemLink = inventoryRawItemLink }
	private.frame.UpdateConfirmation("post", auctionRecord, postInfo)
	self:RegisterEvent("BAG_UPDATE", function() self:SendMsgToSelf("BAG_UPDATE") end)
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) if postInfo.numStacks == 1 and msg == ERR_AUCTION_STARTED then self:SendMsgToSelf("AUCTION_POSTED", 1) end end)
	local lastMultipostQuantity = 0
	self:RegisterEvent("AUCTION_MULTISELL_UPDATE", function(_, arg1, arg2)
		if postInfo.numStacks <= 1 then return end
		if arg1 == arg2 then
			self:SendMsgToSelf("AUCTION_POSTED", arg2)
		else
			lastMultipostQuantity = arg1
		end
	end)
	self:RegisterEvent("AUCTION_MULTISELL_FAILURE", function()
		self:SendMsgToSelf("AUCTION_POSTED", lastMultipostQuantity)
	end)
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "UPDATE_CONFIRMATION" then
			-- update the post frame
			local change = unpack(args)
			local stackSize = postFrame.stackSizeBox:GetNumber()
			local numStacks = postFrame.numStacksBox:GetNumber()
			postInfo.duration = postFrame.durationDropdown:GetValue()
			postInfo.updateBuyout = true
			if change == "numStacksMax" then
				numStacks = min(maxNumStacks, floor(postInfo.numInBags / postInfo.stackSize))
			elseif change == "stackSizeMax" then
				stackSize = min(maxStackSize, postInfo.numInBags)
				numStacks = min(maxNumStacks, floor(postInfo.numInBags / stackSize), numStacks)
			elseif change == "buyout" then
				local buyout = TSMAPI:MoneyFromString(postFrame.buyoutBox:GetText()) or 0
				postInfo.buyout = (postFrame.modeDropdown:GetValue() == 1) and buyout or (buyout * postInfo.stackSize)
				postInfo.updateBuyout = nil
			end
			local stackSizeValid = stackSize > 0 and stackSize <= min(maxStackSize, postInfo.numInBags)
			if stackSizeValid and stackSize ~= postInfo.stackSize then
				-- recalculate the auction buyout for the new stack size
				if postInfo.buyout > 0 then
					postInfo.buyout = TSMAPI.Util:Round(stackSize * postInfo.buyout / postInfo.stackSize)
				end
				postInfo.stackSize = stackSize
				numStacks = min(maxNumStacks, floor(postInfo.numInBags / stackSize), numStacks)
			end

			if postInfo.buyout > 0 and stackSizeValid and numStacks > 0 and numStacks <= maxNumStacks and numStacks * stackSize <= postInfo.numInBags then
				postInfo.numStacks = numStacks
				private.frame.UpdateConfirmation("post", auctionRecord, postInfo)
				postFrame.postBtn:Enable()
			else
				postFrame.postBtn:Disable()
			end
		elseif event == "BAG_UPDATE" then
			-- update the number in the player's bags
			postInfo.numInBags = TSM.AuctionTabUtil:GetNumInBags(auctionRecord.itemString)
			if postInfo.numInBags == 0 or postInfo.isDonePosting then
				break -- done posting
			end
		elseif event == "INTERRUPTED" then
			-- posting was stopped
			break
		elseif event == "AUCTION_CONFIRMED" then
			-- post the auction
			local bag, slot = TSM.AuctionTabUtil:GetItemLocation(auctionRecord.itemString)
			TSMAPI:Assert(bag and slot)
			AuctionFrameAuctions.duration = postInfo.duration -- Fix for Blizzard bug
			PickupContainerItem(bag, slot)
			ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton")
			local bid = floor(max(postInfo.buyout * TSM.db.global.postBidPercent, 1))
			StartAuction(bid, postInfo.buyout, postInfo.duration, postInfo.stackSize, postInfo.numStacks)
			private.frame.UpdateConfirmation("progress", nil, L["Posting auctions..."])
		elseif event == "AUCTION_POSTED" then
			-- auction was posted so add the records and close the confirmation frame
			local numStacksPosted = unpack(args)
			local bid = floor(max(postInfo.buyout * TSM.db.global.postBidPercent, 1))
			local timeLeft = postInfo.duration == 1 and 3 or 4
			local record = auctionRecord(postInfo.itemLink, auctionRecord.texture, postInfo.stackSize, bid, 0, postInfo.buyout, 0, UnitName("player"), timeLeft, false, postInfo.rawItemLink)
			if auctionRecord.isFake then
				-- remove the fake row
				private.frame.content.result.rt:RemoveSelectedRecord(1)
			end
			private.frame.content.result.rt:InsertAuctionRecord(numStacksPosted, record)
			postInfo.isDonePosting = true
		else
			error("Unexpected message: " .. tostring(event))
		end
	end
	self:SendMsgToParent("CONFIRM_DONE")
end

function private.CancelAuctionsThread(self, auctionInfo)
	self:SetThreadName("SHOPPING_CANCEL_AUCTIONS")
	local auctionRecord = auctionInfo.record
	local cancelFrame = private.frame.content.result.confirmation.cancel
	private.frame.content.result.cancelBtn:Disable()
	private.frame.content.result.postBtn:Disable()
	private.frame.content.result.bidBtn:Disable()
	private.frame.content.result.buyoutBtn:Disable()
	cancelFrame.cancelBtn:Enable()
	cancelFrame.closeBtn:Enable()

	local indexList = {}
	local cancelInfo = { progress = 0, totalNum = auctionInfo.numAuctions, pendingUpdate = nil, pendingCancel = nil }
	for i = GetNumAuctionItems("owner"), 1, -1 do
		if auctionRecord:ValidateIndex("owner", i) then
			tinsert(indexList, i)
		end
	end
	private.frame.UpdateConfirmation("cancel", auctionRecord, cancelInfo)
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function() self:SendMsgToSelf("AUCTIONS_UPDATED") end)
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) if msg == ERR_AUCTION_REMOVED then self:SendMsgToSelf("AUCTION_CANCELED") end end)
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "INTERRUPTED" then
			-- canceling was stopped
			break
		elseif event == "AUCTIONS_UPDATED" then
			-- repopulate the list of indicies
			wipe(indexList)
			for i = GetNumAuctionItems("owner"), 1, -1 do
				if auctionRecord:ValidateIndex("owner", i) then
					tinsert(indexList, i)
				end
			end
			if cancelInfo.pendingUpdate and not cancelInfo.pendingCancel then
				-- auction was successfully canceled
				cancelFrame.cancelBtn:Enable()
				cancelFrame.closeBtn:Enable()
				cancelInfo.progress = cancelInfo.progress + 1
				private.frame.content.result.rt:RemoveSelectedRecord(1)
				private.frame.UpdateConfirmation("cancel", auctionRecord, cancelInfo)
			end
			cancelInfo.pendingUpdate = nil
			if not cancelInfo.pendingUpdate and not cancelInfo.pendingCancel and #indexList == 0 then
				-- nothing left to cancel
				break
			end
		elseif event == "AUCTION_CONFIRMED" then
			-- cancel the auction
			local index = tremove(indexList)
			if not auctionRecord:DoCancel(index) then
				-- canceling should only fail if there is a bidder
				TSM:Print(L["Failed to cancel auction because somebody has bid on it."])
				break
			end
			cancelFrame.cancelBtn:Disable()
			cancelFrame.closeBtn:Disable()
			cancelInfo.pendingUpdate = true
			cancelInfo.pendingCancel = true
		elseif event == "AUCTION_CANCELED" then
			-- auction was canceled so remove the record
			if cancelInfo.pendingCancel and not cancelInfo.pendingUpdate then
				-- auction was successfully canceled
				if private.extraInfo and private.extraInfo.buyCallback then
					-- notify the module API user (i.e. Crafting's gathering feature or Auctioning's post scan) that we canceled an auction
					private.extraInfo.buyCallback(auctionRecord.itemString, auctionRecord.stackSize)
				end
				cancelFrame.cancelBtn:Enable()
				cancelFrame.closeBtn:Enable()
				cancelInfo.progress = cancelInfo.progress + 1
				private.frame.content.result.rt:RemoveSelectedRecord(1)
				private.frame.UpdateConfirmation("cancel", auctionRecord, cancelInfo)
			end
			cancelInfo.pendingCancel = nil
			if not cancelInfo.pendingUpdate and not cancelInfo.pendingCancel and #indexList == 0 then
				-- nothing left to cancel
				break
			end
		else
			error("Unexpected message: " .. tostring(event))
		end
	end
	self:SendMsgToParent("CONFIRM_DONE")
end

function private.BidAuctionsThread(self, auctionInfo)
	self:SetThreadName("SHOPPING_BID_AUCTIONS")
	local auctionRecord = auctionInfo.record
	local bidFrame = private.frame.content.result.confirmation.bid
	private.frame.content.result.cancelBtn:Disable()
	private.frame.content.result.postBtn:Disable()
	private.frame.content.result.bidBtn:Disable()
	private.frame.content.result.buyoutBtn:Disable()
	bidFrame.bidBtn:Disable()
	bidFrame.closeBtn:Enable()
	private.frame.UpdateConfirmation("progress", nil, L["Searching for auction..."])
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) if msg == ERR_AUCTION_BID_PLACED then self:SendMsgToSelf("BID_PLACED") end end)
	self:RegisterEvent("UI_ERROR_MESSAGE", function(_, msg) if msg == ERR_AUCTION_HIGHER_BID or msg == ERR_ITEM_NOT_FOUND or msg == ERR_NOT_ENOUGH_MONEY then self:SendMsgToSelf("BID_FAILED") end end)

	local bidInfo = { progress = 0, totalNum = auctionInfo.numAuctions, bid = auctionRecord.requiredBid, index = nil }
	local indexList = TSMAPI.Auction:FindAuctionNoScan(auctionRecord)
	if indexList then
		-- remove auctions which we've already bid on
		for i = #indexList, 1, -1 do
			if select(12, GetAuctionItemInfo("list", indexList[i])) then
				tremove(indexList, i)
			end
		end
	end
	if not indexList or #indexList == 0 then
		TSMAPI.Auction:FindAuction("Shopping", auctionRecord, self:GetSendMsgToSelfCallback(), auctionInfo.database)
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		indexList = unpack(args)
		if event == "INTERRUPTED" then
			self:SendMsgToParent("CONFIRM_DONE")
			return
		end
		TSMAPI:Assert(event == "FOUND_AUCTION", "Unexpected event: " .. tostring(event))
		if indexList then
			-- remove auctions which we've already bid on
			for i = #indexList, 1, -1 do
				if select(12, GetAuctionItemInfo("list", indexList[i])) then
					tremove(indexList, i)
				end
			end
		end
		if not indexList or #indexList == 0 then
			TSM:LOG_INFO("Could not find auction!")
			private.frame.content.result.rt:RemoveSelectedRecord(bidInfo.totalNum)
			self:SendMsgToParent("CONFIRM_DONE")
			TSM:Print(L["Could not find this item on the AH. Removing it."])
			return
		end
	end
	sort(indexList)
	TSM:LOG_INFO(table.concat(indexList, ", "))

	-- we have a list of auction indicies for the item we want to bid on
	bidFrame.bidBtn:Enable()
	bidFrame.closeBtn:Enable()
	private.frame.UpdateConfirmation("bid", auctionRecord, bidInfo)
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "UPDATE_CONFIRMATION" then
			-- update the confirmation frame
			local change = unpack(args)
			if change == "bid" then
				bidInfo.bid = TSMAPI:MoneyFromString(bidFrame.bidBox:GetText()) or 0
				bidFrame.bidBtn:SetDisabled(bidInfo.bid < auctionRecord.requiredBid or (auctionRecord.buyout > 0 and bidInfo.bid >= auctionRecord.buyout))
			else
				local temp = gsub(gsub(strsub(bidFrame.bidBox:GetText(), 1, bidFrame.bidBox:GetCursorPosition()), "\124cff([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", ""), "\124r", "")
				private.frame.UpdateConfirmation("bid", auctionRecord, bidInfo)
				if bidFrame.bidBox:HasFocus() then
					bidFrame.bidBox:SetCursorPosition(#temp)
				end
			end
			bidFrame.bidBox:HighlightText(0, 0)
		elseif event == "AUCTION_CONFIRMED" then
			-- bid on the auction
			local index = tremove(indexList)
			if index then
				if not auctionRecord:DoBid(index, bidInfo.bid) then
					-- we failed to bid on this auction
					TSM:Print(L["Failed to bid on this auction. Skipping it."])
					break
				else
					bidInfo.index = index
				end
			end
			bidFrame.bidBtn:Disable()
			bidFrame.closeBtn:Disable()
		elseif event == "INTERRUPTED" then
			-- abort the bidding confirmation
			break
		elseif event == "BID_PLACED" or event == "BID_FAILED" then
			-- bid was placed or failed
			bidInfo.progress = bidInfo.progress + 1
			private.frame.UpdateConfirmation("bid", auctionRecord, bidInfo)
			private.frame.content.result.rt:RemoveSelectedRecord()
			if event == "BID_PLACED" then
				-- update and re-insert this record
				local minBid, minIncrement, bid, highBidder = TSMAPI.Util:Select({ 8, 9, 11, 12 }, GetAuctionItemInfo("list", bidInfo.index))
				auctionRecord:SetData(auctionRecord.itemLink, auctionRecord.texture, auctionRecord.stackSize, minBid, minIncrement, auctionRecord.buyout, bid, auctionRecord.seller, auctionRecord.timeLeft, highBidder, auctionRecord.rawItemLink)
				private.frame.content.result.rt:InsertAuctionRecord(1, auctionRecord)
			end
			break
		else
			error("Unexpected message: " .. tostring(event))
		end
	end
	self:SendMsgToParent("CONFIRM_DONE")
end



-- ============================================================================
-- Main Thread + Helpers
-- ============================================================================

function private:GetMaxQuantity(auctionRecord)
	local value = nil
	if type(private.extraInfo.maxQuantity) == "number" then
		-- global max quantity
		value = private.extraInfo.maxQuantity
	elseif type(private.extraInfo.maxQuantity) == "table" then
		-- per-item max quantity
		value = private.extraInfo.maxQuantity[auctionRecord.itemString]
	elseif private.extraInfo.queries then
		-- per-query max quantity
		value = TSM.AuctionTabUtil:GetMatchingFilter(private.extraInfo.queries, auctionRecord).maxQuantity
	end
	return value or math.huge
end

function private:SetMaxQuantity(auctionRecord, value)
	if private.extraInfo and private.extraInfo.maxQuantity then
		if type(private.extraInfo.maxQuantity) == "number" then
			-- global max quantity
			private.extraInfo.maxQuantity = value
		elseif type(private.extraInfo.maxQuantity) == "table" and private.extraInfo.maxQuantity[auctionRecord.itemString] then
			-- per-item max quantity
			private.extraInfo.maxQuantity[auctionRecord.itemString] = value
		end
	elseif private.extraInfo.queries then
		-- per-query max quantity
		TSM.AuctionTabUtil:GetMatchingFilter(private.extraInfo.queries, auctionRecord).maxQuantity = value
	end
end

function private.ValidateDatabaseRecord(record, auctionInfo)
	if not record.itemString then return end
	local maxPrice = nil
	-- filter sniping results
	if private.extraInfo.searchType == "sniper" then
		-- we just want to apply price filters for sniper
		-- check for below vendor price
		local recordPrice = ((record.itemBuyout > 0) and record.itemBuyout or record.itemDisplayedBid)
		if TSM.db.global.sniperVendorPrice and recordPrice < (TSMAPI.Item:GetVendorPrice(record.itemString) or 0) then
			return true
		end
		-- check group max prices
		local operationName = TSMAPI.Operations:GetFirstByItem(record.itemString, "Shopping")
		local opSettings = operationName and TSM.operations[operationName]
		if opSettings and opSettings.includeInSniper then
			if recordPrice < (TSMAPI:GetCustomPriceValue(opSettings.maxPrice, record.itemString) or 0) then
				return true
			end
			return
		end
		-- check general custom price
		if recordPrice < (TSMAPI:GetCustomPriceValue(TSM.db.global.sniperCustomPrice, record.itemString) or 0) then
			return true
		end
		return
	elseif private.extraInfo.searchType == "apiAuctioning" then
		return private.extraInfo.filterFunc(record)
	end
	-- filter out unexpected items in crafting mode
	if private.targetItem and record.itemString ~= private.targetItem and not TSM.AuctionTabUtil:GetConvertRate(private.targetItem, record.itemString, record) then
		return
	end
	-- filter group search results
	if private.extraInfo.searchType == "group" then
		local groupItemString = private.extraInfo.itemOperations[record.itemString] and record.itemString or record.baseItemString
		if not private.extraInfo.itemOperations[groupItemString] then
			return
		end
		-- set max price for filtering further down in this function
		if not private.extraInfo.itemOperations[groupItemString].showAboveMaxPrice then
			maxPrice = TSMAPI:GetCustomPriceValue(private.extraInfo.itemOperations[groupItemString].maxPrice, record.itemString)
			if not maxPrice then
				return
			end
		end
		-- filter uneven stacks if evenStacks was specified
		if private.extraInfo.itemOperations[groupItemString].evenStacks and record.stackSize % 5 ~= 0 then
			return
		end
	elseif private.extraInfo.searchType == "vendor" then
		maxPrice = TSMAPI.Item:GetVendorPrice(record.itemString) or 0
	elseif private.extraInfo.searchType == "disenchant" then
		maxPrice = TSMAPI:GetItemValue(record.itemLink, "Destroy") or 0
		if maxPrice > 0 and record.itemBuyout > TSM.db.global.maxDeSearchPercent * maxPrice then
			return
		end
	end

	-- filter by items which were searched for
	if auctionInfo.searchItemsLookup and not auctionInfo.searchItemsLookup[record.itemString] and not auctionInfo.searchItemsLookup[record.baseItemString] then
		return
	end

	-- apply crafting mode evenOnly filter
	if private.searchMode == "crafting" and private.extraInfo.evenOnly then
		local num, requiresFive = TSM.AuctionTabUtil:GetConvertRate(private.targetItem, record.itemString, record)
		if requiresFive then
			num = 0.2
		end
		num = (num * record.stackSize) % 1
		if min(1 - num, num) > 0.001 then
			return
		end
	end

	-- run query-based filters
	local query = private.extraInfo.queryCache[record.itemString]
	if query == nil then
		query = TSM.AuctionTabUtil:GetMatchingFilter(private.extraInfo.queries, record)

		if not query then
			private.extraInfo.queryCache[record.itemString] = false
			return
		else
			private.extraInfo.queryCache[record.itemString] = query
		end
	elseif query == false then
		return
	end

	-- filter uneven stacks when evenOnly was specified
	if query.evenOnly and record.stackSize % 5 ~= 0 then
		return
	end

	-- check the item level
	if (query.minILevel or 0) > 0 and record.itemLevel < query.minILevel then
		return
	end
	if (query.maxILevel or 0) > 0 and record.itemLevel > query.maxILevel then
		return
	end

	-- filter by max price
	maxPrice = maxPrice or query.maxPrice
	if maxPrice and ((record.itemBuyout > 0) and record.itemBuyout or record.itemDisplayedBid) > maxPrice then
		return
	end

	-- filter by max quantity
	if private:GetMaxQuantity(record) <= 0 then
		return
	end

	return true
end

function private.AuctionTabThread(self)
	self:SetThreadName("SHOPPING_AUCTION_TAB")
	-- show the GUI
	private.frame:Show()
	private.frame.content.result.rt:Show()
	private.frame.content.result.rt:Clear()
	private.frame.content.result.rt:SetSort(9)
	private.frame.content.result.cancelBtn:Disable()
	private.frame.content.result.postBtn:Disable()
	private.frame.content.result.bidBtn:Disable()
	private.frame.content.result.buyoutBtn:Disable()
	private.frame.content.result.statusBar:UpdateStatus(0, 0)
	private.frame.content.result.statusBar:SetStatusText("")
	private.frame.UpdateCurrentTab("saved")
	private.frame.UpdateSearchMode("normal")
	private.frame.UpdateSearchInProgress(false)
	private.frame.UpdateConfirmation()
	private.frame.header.searchBox:SetText("")
	private.frame.header.searchBox:SetFocus()
	private.targetItem = nil
	private.extraInfo = nil

	local scanThreadId, confirmThreadId = nil, nil
	local auctionInfo = { record = nil, database = nil, searchItems = nil, searchInfo = nil, searchItemsLookup = nil }
	local dbFilterFunc = function(record) return private.ValidateDatabaseRecord(record, auctionInfo) end
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "START_SEARCH" then
			local searchInfo = unpack(args)
			TSMAPI:Assert(searchInfo.searchMode and searchInfo.extraInfo)
			private.extraInfo = searchInfo.extraInfo
			private.targetItem = nil
			private.frame.UpdateSearchMode(searchInfo.searchMode)
			TSMAPI.Threading:Kill(scanThreadId) -- kill any currently running scan
			scanThreadId = nil
			wipe(auctionInfo)
			auctionInfo.searchInfo = searchInfo
			local searchFilter = nil
			if searchInfo.searchMode == "normal" then
				-- run a normal search either for an item or based on a filter string
				if private.extraInfo.searchType == "sniper" then
					-- it's a sniper scan
					private.frame.header.searchBox:SetText(searchInfo.searchBoxText)
					scanThreadId = TSMAPI.Threading:Start(private.SniperScanThread, 0.7, nil, nil, self:GetThreadId())
					TSMAPI:Assert(not searchInfo.filter and not searchInfo.item) -- only one type of search is allowed
				elseif private.extraInfo.searchType == "apiAuctioning" then
					private.frame.header.searchBox:SetText(searchInfo.searchBoxText)
					private.frame.UpdateConfirmation()
					private.frame.content.result.rt:SetDisabled(true)
					private.frame.UpdateSearchInProgress(true, true)
					self:SendMsgToSelf("SCAN_NEW_DATA", searchInfo.extraInfo.database)
					self:SendMsgToSelf("SCAN_DONE", true)
				elseif searchInfo.item then
					TSMAPI:Assert(not searchInfo.filter) -- only one type of search is allowed
					TSMAPI:Assert(type(searchInfo.item) == "table" or type(searchInfo.item) == "string")
					for i = 1, 30 do
						if type(searchInfo.item) == "table" then
							local isValid = true
							for _, itemString in pairs(searchInfo.item) do
								if not TSMAPI.Item:GetName(itemString) then
									isValid = false
								end
							end
							if isValid then break end
						else
							if TSMAPI.Item:GetName(searchInfo.item) then break end
						end
						self:Sleep(0.1)
					end
					if type(searchInfo.item) ~= "table" then
						searchInfo.item = { searchInfo.item }
					end
					local names = {}
					auctionInfo.searchItemsLookup = {}
					for _, item in ipairs(searchInfo.item) do
						auctionInfo.searchItemsLookup[item] = true
						local name = TSMAPI.Item:GetName(item)
						if name then
							tinsert(names, name .. "/exact")
						else
							TSM:Printf(L["Could not lookup item info for '%s' so skipping it."], item)
						end
					end
					searchFilter = table.concat(names, ";")
					auctionInfo.searchItems = searchInfo.item
					scanThreadId = TSMAPI.Threading:Start(private.ItemScanThread, 0.7, nil, searchInfo.item, self:GetThreadId())
					private.frame.header.searchBox:SetText(searchInfo.searchBoxText or searchFilter)
				elseif searchInfo.filter then
					private.frame.header.searchBox:SetText(searchInfo.searchBoxText or searchInfo.filter)
					searchFilter = searchInfo.filter
					scanThreadId = TSMAPI.Threading:Start(private.FilterScanThread, 0.7, nil, searchFilter, self:GetThreadId())
				else
					error("Invalid normal search")
				end
			elseif searchInfo.searchMode == "crafting" then
				TSMAPI:Assert((searchInfo.filter and not searchInfo.item) or (searchInfo.item and not searchInfo.filter)) -- only one or the other
				local targetItem = nil
				if searchInfo.item then
					targetItem = searchInfo.item
				elseif searchInfo.filter then
					local parts = { ("/"):split(searchInfo.filter) }
					targetItem = TSMAPI.Conversions:GetTargetItemByName(parts[1])
					if #parts > 1 then
						for i = 2, #parts do
							local isValid = true
							parts[i] = strlower(parts[i]:trim())
							if parts[i] == "even" and not private.extraInfo.evenOnly then
								private.extraInfo.evenOnly = true -- special crafting even-only
							elseif parts[i] == "ignorede" and not private.extraInfo.ignoreDisenchant then
								private.extraInfo.ignoreDisenchant = true -- exclude weapons/armor for disenchanting
							elseif strmatch(parts[i], "^x[0-9]+$") and not private.extraInfo.maxQuantity then
								private.extraInfo.maxQuantity = tonumber(strsub(parts[i], 2))
							else
								targetItem = nil
								TSM:Printf(L["Unexpected filters (only '/even' or '/ignorede' or '/x<MAX_QUANTITY>' is supported in crafting mode): %s"], table.concat(parts, "/", 2))
							end
						end
					end
				end
				local isValidTargetItem = true
				if not targetItem then
					isValidTargetItem = false
				else
					for i = 1, 30 do
						isValidTargetItem = TSMAPI.Item:GetName(targetItem)
						if isValidTargetItem then break end
						self:Sleep(0.1)
					end
				end
				if not isValidTargetItem then
					TSM:Print(L["This is not a valid target item."])
				else
					searchFilter = TSM.AuctionTabUtil:GetCraftingFilterString(targetItem, private.extraInfo.ignoreDisenchant)
					if searchFilter then
						private.targetItem = targetItem
						private.frame.header.searchBox:SetText(TSMAPI.Item:GetName(targetItem) .. (private.extraInfo.evenOnly and "/even" or "") .. (private.extraInfo.maxQuantity and ("/x" .. private.extraInfo.maxQuantity) or "") .. (private.extraInfo.ignoreDisenchant and "/ignorede" or ""))
						scanThreadId = TSMAPI.Threading:Start(private.FilterScanThread, 0.7, nil, searchFilter, self:GetThreadId())
					else
						TSM:Print(L["Could not find crafting info for the specified item."])
					end
				end
			end
			if scanThreadId then
				private.frame.UpdateConfirmation()
				private.frame.content.result.rt:SetDisabled(private.extraInfo.searchType ~= "sniper") -- don't disable for sniper
				private.frame.UpdateSearchInProgress(true, true)
				if private.extraInfo.searchType == "item" or private.extraInfo.searchType == "filter" then
					if searchInfo.searchMode == "crafting" then
						if searchInfo.filter then
							TSM.AuctionTabSaved:AddRecentSearch(searchInfo.filter, searchInfo.searchMode)
						else
							TSM.AuctionTabSaved:AddRecentSearch(TSMAPI.Item:GetName(private.targetItem), searchInfo.searchMode)
						end
					else
						TSM.AuctionTabSaved:AddRecentSearch(searchFilter, searchInfo.searchMode)
					end
				end
			end
		elseif event == "SCAN_NEW_DATA" then
			-- process scan data
			local database = unpack(args)
			private.frame.content.result.rt:SetDatabase(database, dbFilterFunc)
			self:SendMsgToSelf("RESULT_ROW_SELECTED", private.frame.content.result.rt:GetSelection())
			auctionInfo.database = database
		elseif event == "SCAN_DONE" then
			-- the scan is done (or was interrupted)
			local isNoScan = unpack(args)
			private.frame.UpdateSearchInProgress(false, true)
			TSMAPI:Assert(isNoScan or (scanThreadId and not TSMAPI.Threading:IsValid(scanThreadId)))
			scanThreadId = nil
			local searchItem = auctionInfo.searchItems and #auctionInfo.searchItems == 1 and auctionInfo.searchItems[1] or auctionInfo.searchInfo.filterItem
			if searchItem and auctionInfo.database and #auctionInfo.database.records == 0 then
				-- there were no results, but we might have some to post from our bags
				local numInBags = TSM.AuctionTabUtil:GetNumInBags(searchItem)
				if numInBags > 0 then
					local link = TSMAPI.Item:GetLink(searchItem)
					local texture = TSMAPI.Item:GetTexture(searchItem)
					local record = TSMAPI.Auction:NewRecord(link, texture, 1, 1, 0, 0, 0, "---", 1, false, link)
					record.isFake = true
					private.frame.content.result.rt:InsertAuctionRecord(1, record)
				end
			end
			if private.extraInfo and private.extraInfo.searchType == "apiGathering" and private.extraInfo.buyCallback and auctionInfo.database and #auctionInfo.database.records == 0 then
				-- notify the module API user (i.e. Crafting's gathering feature) that we no auctions were found
				private.extraInfo.buyCallback(nil)
			end
			if private.extraInfo.searchType == "vendor" and auctionInfo.database then
				local totalProfit, numAuctions = 0, 0
				for _, record in ipairs(private.frame.content.result.rt.dbView:Execute()) do
					if record.buyout > 0 then
						local profit = (TSMAPI.Item:GetVendorPrice(record.itemString) or 0) * record.stackSize - record.buyout
						if profit > 0 then
							numAuctions = numAuctions + 1
							totalProfit = totalProfit + profit
						end
					end
				end
				TSM:Print(format(L["%d auctions found below vendor price for a potential profit of %s!"], numAuctions, TSMAPI:MoneyToString(totalProfit)))
			end
			private.frame.content.result.rt:SetDisabled(false)
		elseif event == "STOP_SCAN" then
			-- we should stop scanning
			TSMAPI.Auction:StopScan("Shopping")
			-- if the scan was running, the scanning thread will get an interrupted event, gracefully exit, and send this thread a "SCAN_DONE" msg
		elseif event == "RESULT_ROW_SELECTED" then
			-- update the action buttons for the selected row and start a find search
			local data = unpack(args)
			if data then
				local isPlayer = data.record.seller == UnitName("player")
				local isAlt = not isPlayer and TSMAPI.Player:IsPlayer(data.record.seller, true)
				if data.record.isFake then
					private.frame.content.result.cancelBtn:Disable()
					private.frame.content.result.postBtn:Enable()
					private.frame.content.result.bidBtn:Disable()
					private.frame.content.result.buyoutBtn:Disable()
				elseif private.extraInfo.searchType == "apiAuctioning" then
					private.frame.content.result.cancelBtn:Disable(not isPlayer)
					private.frame.content.result.postBtn:Disable()
					private.frame.content.result.bidBtn:Disable()
					private.frame.content.result.buyoutBtn:SetDisabled(isPlayer or isAlt or data.record.buyout == 0)
				else
					private.frame.content.result.cancelBtn:SetDisabled(not isPlayer)
					private.frame.content.result.postBtn:SetDisabled(TSM.AuctionTabUtil:GetNumInBags(data.record.itemString) == 0)
					private.frame.content.result.bidBtn:SetDisabled(data.record.isHighBidder or isPlayer or isAlt or data.record.requiredBid > GetMoney() or (data.record.buyout > 0 and data.record.requiredBid >= data.record.buyout))
					private.frame.content.result.buyoutBtn:SetDisabled(isPlayer or isAlt or data.record.buyout == 0 or data.record.buyout > GetMoney())
				end
				auctionInfo.record = data.record
				auctionInfo.numAuctions = data.numAuctions
				TSM:LOG_INFO("selected auction (num=%d, numInBags=%d)", auctionInfo.numAuctions, TSM.AuctionTabUtil:GetNumInBags(data.record.itemString))
			else
				private.frame.content.result.cancelBtn:Disable()
				private.frame.content.result.postBtn:Disable()
				private.frame.content.result.bidBtn:Disable()
				private.frame.content.result.buyoutBtn:Disable()
			end
		elseif event == "SHOW_CONFIRMATION" then
			-- show the confirmation window for the currently selected auction
			local mode = unpack(args)
			if TSMAPI.Threading:IsValid(confirmThreadId) then
				TSMAPI.Threading:SendMsg(confirmThreadId, { "INTERRUPTED" }, true)
				-- the thread should gracefully exit and send a CONFIRM_DONE message back to this thread
				TSMAPI:Assert(not TSMAPI.Threading:IsValid(confirmThreadId))
			end
			if private.extraInfo.searchType == "sniper" then
				private.frame.content.result.cancelBtn:Disable()
				private.frame.content.result.postBtn:Disable()
				private.frame.content.result.bidBtn:Disable()
				private.frame.content.result.buyoutBtn:Disable()
				while private.sniperSleeping and private.sniperSleeping + 5000 > debugprofilestop() do self:Sleep(0.1) end -- wait for the sniper thread to stop sleeping before trying to pause it
				TSMAPI.Threading:SendMsg(scanThreadId, { "SCAN_PAUSE" }, true)
			end
			if mode == "buyout" then
				confirmThreadId = TSMAPI.Threading:Start(private.BuyAuctionsThread, 0.7, nil, auctionInfo, self:GetThreadId())
			elseif mode == "post" then
				confirmThreadId = TSMAPI.Threading:Start(private.PostAuctionsThread, 0.7, nil, auctionInfo, self:GetThreadId())
			elseif mode == "cancel" then
				confirmThreadId = TSMAPI.Threading:Start(private.CancelAuctionsThread, 0.7, nil, auctionInfo, self:GetThreadId())
			elseif mode == "bid" then
				confirmThreadId = TSMAPI.Threading:Start(private.BidAuctionsThread, 0.7, nil, auctionInfo, self:GetThreadId())
			end
		elseif event == "UPDATE_CONFIRMATION" then
			TSMAPI.Threading:SendMsg(confirmThreadId, { "UPDATE_CONFIRMATION", unpack(args) })
		elseif event == "AUCTION_CONFIRMED" then
			-- the confirmation action was confirmed
			local didConfirm = unpack(args)
			if didConfirm then
				TSMAPI.Threading:SendMsg(confirmThreadId, { "AUCTION_CONFIRMED" }, true)
			else
				TSMAPI.Threading:SendMsg(confirmThreadId, { "INTERRUPTED" }, true)
				-- the thread should have gracefully exited and sent a CONFIRM_DONE message back to this thread
				TSMAPI:Assert(not TSMAPI.Threading:IsValid(confirmThreadId))
			end
		elseif event == "CONFIRM_DONE" then
			-- confirmation thread should now be closed
			TSMAPI:Assert(not TSMAPI.Threading:IsValid(confirmThreadId))
			confirmThreadId = nil
			if private:GetMaxQuantity(auctionInfo.record) <= 0 then
				TSM:Print(L["Purchased the maximum quantity of this item!"])
			end
			private.frame.UpdateConfirmation()
			private.frame.content.result.rt:SetDatabase(auctionInfo.database, dbFilterFunc)

			if private.extraInfo.searchType == "sniper" then
				-- resume the sniper scan
				TSMAPI.Threading:SendMsg(scanThreadId, { "SCAN_RESUME" })
			end
		else
			error("Unexpected message: " .. tostring(event))
		end
	end
end

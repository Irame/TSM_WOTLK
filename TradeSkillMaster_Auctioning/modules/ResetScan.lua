-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Auctioning                          --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctioning          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Reset = TSM:NewModule("Reset", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local private = {queue={}, threadId=nil, filterItem=nil, summarySTCache={}}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Reset:Show(frame)
	private:CreateResetFrame(frame)
	private.frame:Show()
	private.frame.summaryST:Hide()
	private.frame.summaryST:SetData({})
	private.frame.auctionST:Hide()
	private.frame.auctionST:SetData({})
	private.frame.buttonsFrame.stop:Enable()
	private.frame.buttonsFrame.stop:SetText(L["Stop"])
	private.frame.buttonsFrame.buyout:Disable()
	private.frame.buttonsFrame.cancel:Disable()
	private.frame.summaryBtn:Disable()
end

function Reset:Hide()
	if not private.frame then return end
	private.frame:Hide()
end

function Reset:StartScan(scanInfo)
	wipe(private.queue)
	wipe(TSM.operationLookup)
	wipe(private.summarySTCache)
	local scanList = {}

	for itemString, operations in pairs(scanInfo) do
		local validOperations = {}
		local hasInvalidOperation = false
		for _, operation in ipairs(operations) do
			if operation.resetEnabled then
				if private:ValidateOperation(itemString, operation) then
					tinsert(validOperations, operation)
				else
					hasInvalidOperation = true
					break
				end
			end
		end
		if not hasInvalidOperation and #validOperations > 0 then
			TSM.operationLookup[itemString] = validOperations
			tinsert(scanList, itemString)
		end
	end

	if #scanList == 0 then return false end
	TSM:AnalyticsEvent("RESET_START")
	private.threadId = TSMAPI.Threading:Start(private.ResetScanThread, 0.7, TSM.Manage.StopScan, scanList)
	return true
end

function Reset:StopResetting()
	TSMAPI.Threading:Kill(private.threadId)
	Reset:Hide()
	TSM.GUI:ShowSelectionFrame()
	Reset:UnregisterAllEvents()
	wipe(private.queue)
	private.threadId = nil
end



-- ============================================================================
-- GUI Creation
-- ============================================================================

function private:CreateResetFrame(parent)
	if private.frame then return end
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		parent = parent,
		points = "ALL",
		children = {
			{
				type = "ScrollingTableFrame",
				key = "summaryST",
				stCols = {{name=L["Item"], width=0.31}, {name=L["Operation"], width=0.17}, {name=L["Quantity (Yours)"], width=0.13, align="CENTER"}, {name=L["Total Cost"], width=0.12, align="RIGHT"}, {name=L["Target Price"], width=0.12, align="RIGHT"}, {name=L["Profit Per Item"], width=0.12, align="RIGHT"}},
				sortInfo = {true, 1},
				stDisableSelection = true,
				points = {{"TOPLEFT", parent.content}, {"BOTTOMRIGHT", parent.content}},
				scripts = {"OnEnter", "OnLeave", "OnClick"},
			},
			{
				type = "ScrollingTableFrame",
				key = "auctionST",
				stCols = {{name=L["Seller"], width=0.4}, {name=L["Stack Size"], width=0.2, align="CENTER"}, {name = L["Auction Buyout"], width=0.35, align="RIGHT"}},
				points = {{"TOPLEFT", parent.content}, {"BOTTOMRIGHT", parent.content}},
				scripts = {"OnClick"},
			},
			{
				type = "Button",
				key = "summaryBtn",
				text = L["Return to Summary"],
				textHeight = 16,
				size = {150, 20},
				points = {{"TOPRIGHT", -10, -50}},
				scripts = {"OnClick"},
			},
			{
				type = "Frame",
				key = "buttonsFrame",
				size = {210, 24},
				points = {{"BOTTOMRIGHT", -92, 5}},
				children = {
					{
						type = "Button",
						key = "buyout",
						name = "TSMAuctioningResetBuyoutButton",
						text = BUYOUT,
						textHeight = 22,
						size = {80, 24},
						points = {{"TOPLEFT", -5, 0}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "cancel",
						name = "TSMAuctioningResetCancelButton",
						text = CANCEL,
						textHeight = 22,
						size = {70, 24},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "stop",
						name = "TSMAuctioningResetStopButton",
						text = L["Stop"],
						textHeight = 18,
						size = {60, 24},
						points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}},
						scripts = {"OnClick"},
					},
				},
			},
		},
		handlers = {
			summaryST = {
				OnEnter = function(self, data, self)
					if not data.operation then return end
					local prices = TSM.Util:GetItemPrices(data.operation, data.itemString, true, {resetMaxCost=true, resetMinProfit=true})
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
					GameTooltip:AddLine(data.itemLink)
					GameTooltip:AddLine(L["Max Cost:"].." "..(TSMAPI:MoneyToString(prices.resetMaxCost, "|cffffffff") or "---"))
					GameTooltip:AddLine(L["Min Profit:"].." "..(TSMAPI:MoneyToString(prices.resetMinProfit, "|cffffffff") or "---"))
					GameTooltip:AddLine(L["Max Quantity:"].." |cffffffff"..data.operation.resetMaxQuantity.."|r")
					GameTooltip:AddLine(L["Max Price Per:"].." "..(TSMAPI:MoneyToString(data.operation.resetMaxPricePer, "|cffffffff") or "---"))

					if self.enabled then
						GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2").."\n"..L["Click to show auctions for this item."].."|r")
						GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2")..L["Shift-Right-Click to show the options for this item's Auctioning group."].."|r")
					else
						GameTooltip:AddLine("\n"..L["Must wait for scan to finish before starting to reset."])
					end
					GameTooltip:Show()
				end,
				OnLeave = function()
					GameTooltip:Hide()
				end,
				OnClick = function(self, data, _, button)
					if not self.enabled then return end
					if button == "LeftButton" then
						TSMAPI.Threading:SendMsg(private.threadId, {"SUMMARY_ROW_CLICKED", CopyTable(data)}, true)
					elseif button == "RightButton" then
						if IsShiftKeyDown() then
							TSMAPI.Operations:ShowOptions("Auctioning", TSM.operationNameLookup[data.operation])
						end
					end
				end,
			},
			auctionST = {
				OnClick = function(_, data) TSMAPI.Threading:SendMsg(private.threadId, {"AUCTION_ROW_CLICKED", data}) end,
			},
			summaryBtn = {
				OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"SHOW_SUMMARY"}) end,
			},
			buttonsFrame = {
				buyout = {
					OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"BUY_AUCTION"}, true) end,
				},
				cancel = {
					OnClick = function() TSMAPI.Threading:SendMsg(private.threadId, {"CANCEL_AUCTION"}, true) end,
				},
				stop = {
					OnClick = TSM.Manage.StopScan,
				},
			},
		},
	}
	private.frame = TSMAPI.GUI:BuildFrame(frameInfo)
end



-- ============================================================================
-- GUI Updating
-- ============================================================================

function private:UpdateSummaryST()
	local rows = {}
	for _, data in ipairs(private.queue) do
		local key = data.itemString .. data.targetPrice
		if not private.summarySTCache[key] then
			private.summarySTCache[key] = {
				cols = {
					{
						value = TSMAPI.Item:GetLink(data.itemString),
						sortArg = TSMAPI.Item:GetName(data.itemString),
					},
					{
						value = data.operation and TSM.operationNameLookup[data.operation] or "---",
						sortArg = data.operation and TSM.operationNameLookup[data.operation] or "---",
					},
					{
						value = data.playerQuantity > 0 and (data.quantity..TSMAPI.Design:GetInlineColor("link2").."("..data.playerQuantity..")|r") or data.quantity,
						sortArg = data.quantity,
					},
					{
						value = data.cost and TSMAPI:MoneyToString(data.cost, "OPT_PAD") or "---",
						sortArg = data.cost or 0,
					},
					{
						value = TSMAPI:MoneyToString(data.targetPrice, "OPT_PAD"),
						sortArg = data.targetPrice,
					},
					{
						value = TSMAPI:MoneyToString(data.profit, "OPT_PAD"),
						sortArg = data.profit,
					},
				},
				itemString = data.itemString,
				targetPrice = data.targetPrice,
				num = data.quantity,
				profit = data.profit,
				operation = data.operation,
			}
		end
		tinsert(rows, private.summarySTCache[key])
	end
	private.frame.summaryST:SetData(rows)
end

function private:UpdateAuctionST(currentItem)
	private.filterItem = currentItem.itemString
	local dbView = TSM.Scan:GetDatabaseView()
	dbView:SetFilter(private.MatchingItemFilter, private.filterItem)
	local rows = {}
	for _, record in ipairs(dbView:Execute()) do
		if record.itemBuyout and record.itemBuyout >= currentItem.targetPrice then
			break
		end
		local rowInfo = {
			cols = {
				{
					value = (TSMAPI.Player:IsPlayer(record.seller, true, true, true) and ("|cff99ffff"..record.seller.."|r")) or (TSM.db.factionrealm.whitelist[strlower(record.seller)] and (record.seller.." |cffff2222("..L["Whitelist"]..")|r")) or record.seller,
					sortArg = record.seller,
				},
				{
					value = record.stackSize,
					sortArg = record.stackSize,
				},
				{
					value = TSMAPI:MoneyToString(record.buyout, "OPT_PAD") or "---",
					sortArg = record.buyout,
				},
			},
			record = record,
			itemString = TSMAPI.Item:ToBaseItemString(record.itemString, true)
		}
		tinsert(rows, rowInfo)
	end
	private.filterItem = nil
	private.frame.auctionST:SetData(rows)
end



-- ============================================================================
-- Scan Thread
-- ============================================================================

function private.ResetScanThread(self, scanList)
	self:SetThreadName("AUCTIONING_RESET_SCAN")
	local numToReset, numReset = 0, 0
	local doneScanning, currentItem, targetAuction
	local summaryInfoText = L["Running Scan..."]
	local cancelConfirmed, buyoutConfirmed = nil, nil
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg)
		if msg == ERR_AUCTION_REMOVED then
			cancelConfirmed = true
		elseif msg == ERR_AUCTION_BID_PLACED then
			buyoutConfirmed = true
		end
	end)
	private.frame.summaryST.enabled = false
	self:SendMsgToSelf("SHOW_SUMMARY")
	TSM.GUI:SetScanThreadId(self:GetThreadId())
	TSM.Scan:StartItemScan(scanList, self:GetThreadId())
	while true do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == "PROCESS_ITEM" then
			-- process a newly scanned item
			local itemString = unpack(args)
			if TSM.operationLookup[itemString] then
				local added = false
				for _, operation in ipairs(TSM.operationLookup[itemString]) do
					if private:ProcessItemOperation(itemString, operation) > 0 then
						added = true
					end
					self:Yield()
				end
				if added then
					numToReset = numToReset + 1
				end
				private:UpdateSummaryST()
			end
		elseif event == "DONE_SCANNING" then
			-- we are done scanning
			doneScanning = true
			private.frame.summaryST.enabled = true
			local num, totalProfit = 0, 0
			local temp = {}
			for _, data in ipairs(private.queue) do
				if not temp[data.itemString] then
					temp[data.itemString] = true
					num = num + 1
					totalProfit = totalProfit + data.profit * data.quantity
				end
			end
			private.frame.buttonsFrame.stop:SetText(L["Restart"])
			summaryInfoText = format(L["Done Scanning!\n\nCould potentially reset %d items for %s profit."], num, TSMAPI:MoneyToString(totalProfit, "OPT_ICON"))
			self:SendMsgToSelf("SHOW_SUMMARY")
			TSMAPI:DoPlaySound(TSM.db.global.scanCompleteSound)
		elseif event == "SHOW_SUMMARY" then
			TSM.Manage:SetInfoText(summaryInfoText)
			private.frame.auctionST:Hide()
			private.frame.summaryST:Show()
			private.frame.buttonsFrame.buyout:Disable()
			private.frame.buttonsFrame.cancel:Disable()
			private.frame.summaryBtn:Disable()
			private:UpdateSummaryST()
			currentItem = nil
		elseif event == "SUMMARY_ROW_CLICKED" then
			local data = unpack(args)
			private.frame.summaryST:Hide()
			private.frame.auctionST:Show()
			private.frame.summaryBtn:Enable()
			if currentItem ~= data then
				currentItem = CopyTable(data)
			end
			currentItem.isReset = true
			private:UpdateAuctionST(currentItem)
			private.frame.auctionST:SetSelection(1)
			self:SendMsgToSelf("AUCTION_ROW_CLICKED", private.frame.auctionST.rowData[1])
			TSM.Manage:SetInfoText(currentItem)
			targetAuction = nil
		elseif event == "AUCTION_ROW_CLICKED" then
			local rowData = unpack(args)
			private.frame.buttonsFrame.cancel:Disable()
			private.frame.buttonsFrame.buyout:Disable()
			targetAuction = rowData.record
			if TSMAPI.Player:IsPlayer(targetAuction.seller) then
				private.frame.buttonsFrame.cancel:Enable()
			else
				TSMAPI.Auction:FindAuction("Auctioning", rowData.record, self:GetSendMsgToSelfCallback(), TSM.Scan:GetDatabase())
			end
		elseif event == "FOUND_AUCTION" then
			local index = unpack(args)
			if index then
				private.frame.buttonsFrame.buyout:Enable()
			else
				TSM:Print(L["Auction not found. Skipped."])
				currentItem.shouldRemove = true
			end
		elseif event == "BUY_AUCTION" then
			private.frame.buttonsFrame.buyout:Disable()
			local indexList = TSMAPI.Auction:FindAuctionNoScan(targetAuction)
			if indexList and indexList[1] and targetAuction:DoBuyout(indexList[1]) then
				-- wait for buyoutConfirmed to be set
				buyoutConfirmed = nil
				while not buyoutConfirmed do self:Yield(true) end
				currentItem.shouldRemove = true
			else
				self:SendMsgToSelf("AUCTION_ROW_CLICKED", private.frame.auctionST.rowData[private.frame.auctionST:GetSelection() or 1])
			end
		elseif event == "CANCEL_AUCTION" then
			private.frame.buttonsFrame.cancel:Disable()
			local index = nil
			for i=GetNumAuctionItems("owner"), 1, -1 do
				if targetAuction:ValidateIndex("owner", i) then
					index = i
					break
				end
			end
			if index and targetAuction:DoCancel(index) then
				-- wait for cancelConfirmed to be set
				cancelConfirmed = nil
				while not cancelConfirmed do self:Yield(true) end
			else
				TSM:Print(L["Auction not found. Skipped."])
			end
			currentItem.shouldRemove = true
		elseif event == "INTERRUPTED" then
			-- silently ignore as this could happen while finding auctions to buy
		else
			error("Unpexected message: "..tostring(event))
		end

		if currentItem and currentItem.shouldRemove then
			currentItem.shouldRemove = nil
			local row = private.frame.auctionST.rowData[private.frame.auctionST:GetSelection()]
			if row then
				local dbView = TSM.Scan:GetDatabaseView()
				dbView:SetFilter(private.MatchingItemFilter, currentItem.itemString)
				private.filterItem = currentItem.itemString
				dbView:Remove(row.record)
				private.filterItem = nil
				if #private.frame.auctionST.rowData == 1 then
					for i=#private.queue, 1, -1 do
						if private.queue[i].itemString == currentItem.itemString then
							tremove(private.queue, i)
						end
					end
					currentItem = nil
					numReset = numReset + 1
					self:SendMsgToSelf("SHOW_SUMMARY")
				else
					self:SendMsgToSelf("SUMMARY_ROW_CLICKED", currentItem)
				end
			end
		end

		TSM.Manage:UpdateStatus("manage", numReset, numToReset)
		TSM.Manage:UpdateStatus("confirm", numReset, numToReset)
		if doneScanning and numReset == numToReset and numToReset > 0 then
			-- we're done resetting
			TSM.Manage:StopScan()
			Reset:StopResetting() -- will kill this thread
			return
		end
	end
end



-- ============================================================================
-- Scan Functions
-- ============================================================================

function private:ProcessItemOperation(itemString, operation)
	private.filterItem = itemString
	local dbView = TSM.Scan:GetDatabaseView()
	dbView:SetFilter(private.MatchingItemFilter, private.filterItem)
	local records = dbView:Execute()
	private.filterItem = nil
	if #records == 0 then return 0 end

	local numAdded = 0
	local prices = TSM.Util:GetItemPrices(operation, itemString, true, {minPrice=true, maxPrice=true, normalPrice=true, resetMaxCost=true, resetMinProfit=true, resetResolution=true, resetMaxItemCost=true, undercut=true})
	local priceLevels = {}
	local addNormal, isFirstItem = true, true
	local currentPriceLevel = -math.huge

	for _, record in ipairs(records) do
		if record.itemBuyout > 0 then
			if not isFirstItem and record.itemBuyout > prices.minPrice and record.itemBuyout < prices.maxPrice and record.itemBuyout > (currentPriceLevel + prices.resetResolution) then
				if record.itemBuyout >= prices.normalPrice then
					addNormal = false
				end
				currentPriceLevel = record.itemBuyout
				tinsert(priceLevels, record.itemBuyout)
			end
			isFirstItem = false
		end
	end

	if addNormal then
		tinsert(priceLevels, prices.normalPrice)
	end

	for _, targetPrice in ipairs(priceLevels) do
		local playerCost, cost, quantity, maxItemCost, playerQuantity = 0, 0, 0, 0, 0
		for _, record in ipairs(records) do
			if record.itemBuyout > 0 then
				if record.itemBuyout >= targetPrice then
					break
				end
				if record.itemBuyout > maxItemCost then
					maxItemCost = record.itemBuyout
				end
				if not TSMAPI.Player:IsPlayer(record.seller) then
					cost = cost + record.buyout
				else
					playerQuantity = playerQuantity + record.stackSize
					playerCost = playerCost + record.buyout
				end
				quantity = quantity + record.stackSize
			end
		end

		local profit = (targetPrice * quantity - (cost + playerCost)) / quantity
		if quantity > 0 and profit >= prices.resetMinProfit and cost <= prices.resetMaxCost and maxItemCost <= prices.resetMaxItemCost and quantity <= operation.resetMaxQuantity and quantity <= (operation.resetMaxInventory - TSMAPI.Inventory:GetTotalQuantity(itemString)) then
			tinsert(private.queue, {prices=prices, itemString=itemString, targetPrice=targetPrice, cost=cost, quantity=quantity, profit=profit, maxItemCost=maxItemCost, playerQuantity=playerQuantity, operation=operation})
			numAdded = numAdded + 1
		end
	end

	return numAdded
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:ValidateOperation(itemString, operation)
	local prices = TSM.Util:GetItemPrices(operation, itemString, true, {minPrice=true, maxPrice=true, normalPrice=true, resetMaxCost=true, resetMinProfit=true, resetResolution=true, resetMaxItemCost=true, undercut=true})
	local errMsg

	-- don't reset this item if their settings are invalid
	if not prices.minPrice then
		errMsg = format(L["Did not reset %s because your minimum price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.minPrice)
	elseif not prices.maxPrice then
		errMsg = format(L["Did not reset %s because your maximum price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.maxPrice)
	elseif not prices.normalPrice then
		errMsg = format(L["Did not reset %s because your normal price (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.normalPrice)
	elseif not prices.resetMaxCost then
		errMsg = format(L["Did not reset %s because your reset max cost (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.resetMaxCost)
	elseif not prices.resetMinProfit then
		errMsg = format(L["Did not reset %s because your reset min profit (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.resetMinProfit)
	elseif not prices.resetResolution then
		errMsg = format(L["Did not reset %s because your reset resolution (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.resetResolution)
	elseif not prices.resetMaxItemCost then
		errMsg = format(L["Did not reset %s because your reset max item cost (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.resetMaxItemCost)
	elseif not prices.undercut then
		errMsg = format(L["Did not reset %s because your undercut (%s) is invalid. Check your settings."], TSMAPI.Item:GetLink(itemString), operation.undercut)
	elseif prices.maxPrice < prices.minPrice then
		errMsg = format(L["Did not reset %s because your maximum price (%s) is lower than your minimum price (%s). Check your settings."], TSMAPI.Item:GetLink(itemString), operation.maxPrice, operation.minPrice)
	elseif prices.normalPrice < prices.minPrice then
		errMsg = format(L["Did not reset %s because your normal price (%s) is lower than your minimum price (%s). Check your settings."], TSMAPI.Item:GetLink(itemString), operation.normalPrice, operation.minPrice)
	end

	if errMsg then
		if not TSM.db.global.disableInvalidMsg then
			TSM:Print(errMsg)
		end
		return false
	else
		if TSMAPI.Inventory:GetTotalQuantity(itemString) >= operation.resetMaxInventory then
			-- already have at least max inventory - do nothing here
			return false
		end
		return true
	end
end

function private.MatchingItemFilter(record)
	TSMAPI:Assert(private.filterItem)
	if record.itemBuyout == 0 then return end
	return record.itemString == private.filterItem or record.baseItemString == private.filterItem
end

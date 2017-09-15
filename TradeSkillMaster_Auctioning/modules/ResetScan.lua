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
local Reset = TSM:NewModule("Reset", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

local resetData, summarySTCache, showCache, itemsReset, justBought = {}, {}, {}, {}, {}
local isScanning, doneScanningText, currentItem, GUI
local summaryST, auctionST, resetButtons

function Reset:Show(frame)
	summaryST = summaryST or Reset:CreateSummaryST(frame.content)
	summaryST:Show()
	summaryST:SetData({})
	
	auctionST = auctionST or Reset:CreateAuctionST(frame.content)
	auctionST:Hide()
	auctionST:SetData({})
	
	resetButtons = resetButtons or Reset:CreateResetButtons(frame)
	resetButtons:Show()
	resetButtons.stop:Enable()
	resetButtons:Disable()
end

function Reset:Hide()
	summaryST:SetData({})
	summaryST:Hide()
	
	auctionST:SetData({})
	auctionST:Hide()
	
	resetButtons:Hide()
	Reset.isSearching = nil
end

local function ColSortMethod(st, aRow, bRow, col)
	local a, b = st:GetCell(aRow, col), st:GetCell(bRow, col)
	local column = st.cols[col]
	local direction = column.sort or column.defaultsort or "dsc"
	local aValue, bValue = ((a.args or {})[1] or a.value), ((b.args or {})[1] or b.value)
	if direction == "asc" then
		return aValue < bValue
	else
		return aValue > bValue
	end
end

function Reset:CreateSummaryST(parent)
	local events = {
		["OnEnter"] = function(_, cellFrame, data, _, _, rowNum, column)
			if rowNum then
				GameTooltip:SetOwner(cellFrame, "ANCHOR_NONE")
				GameTooltip:SetPoint("BOTTOMLEFT", cellFrame, "TOPLEFT")
				
				local row = CopyTable(data[rowNum].rowInfo)
				local resetMaxCost = TSM.Config:GetConfigValue(row.itemString, "resetMaxCost")
				local resetMinProfit = TSM.Config:GetConfigValue(row.itemString, "resetMinProfit")
				local resetMaxQuantity = TSM.Config:GetConfigValue(row.itemString, "resetMaxQuantity")
				local resetMaxPricePer = TSM.Config:GetConfigValue(row.itemString, "resetMaxPricePer")
				local groupName = TSM.itemReverseLookup[row.itemString] or "---"
				
				GameTooltip:AddLine(data[rowNum].cols[1].args[2] or "")				
				GameTooltip:AddLine(L["Max Cost:"].." "..(TSMAPI:FormatTextMoney(resetMaxCost, "|cffffffff") or "---"))
				GameTooltip:AddLine(L["Min Profit:"].." "..(TSMAPI:FormatTextMoney(resetMinProfit, "|cffffffff") or "---"))
				GameTooltip:AddLine(L["Max Quantity:"].." "..(TSMAPI:FormatTextMoney(resetMaxQuantity, "|cffffffff") or "---"))
				GameTooltip:AddLine(L["Max Price Per:"].." "..(TSMAPI:FormatTextMoney(resetMaxPricePer, "|cffffffff") or "---"))
				GameTooltip:AddLine(L["Group:"].." |cffffffff"..(groupName))		
				
				if TSM.Reset:IsScanning() then
					GameTooltip:AddLine("\n"..L["Must wait for scan to finish before starting to reset."])
				else
					GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2")..L["\nClick to show auctions for this item."].."|r")
					GameTooltip:AddLine(TSMAPI.Design:GetInlineColor("link2")..L["Shift-Right-Click to show the options for this item's Auctioning group."].."|r")
				end
				GameTooltip:Show()
			end
		end,
		["OnLeave"] = function(_, _, data, _, _, rowNum, column)
			if rowNum then
				GameTooltip:Hide()
			end
		end,
		["OnClick"] = function(_, _, data, _, _, rowNum, column, _, mouseButton)
			if rowNum and not TSM.Reset:IsScanning() then
				local row = data[rowNum].rowInfo
				if mouseButton == "RightButton" then
					if IsShiftKeyDown() then
						local group = TSM.itemReverseLookup[row.itemString]
						
						if group then
							TSMAPI:OpenFrame()
							TSMAPI:SelectIcon("TradeSkillMaster_Auctioning", L["Auctioning Groups/Options"])
							TSM.Config.treeGroup:SelectByPath(2, TSM.groupReverseLookup[group] or "~", group)
						else
							TSM:Print(L["Could not find item's group."])
						end
					end
				else
					summaryST:Hide()
					auctionST:Show()
					resetButtons.summaryButton:Enable()
					
					currentItem = CopyTable(data[rowNum].rowInfo)
					Reset:UpdateAuctionST()
					Reset:SelectAuctionRow(1)
					currentItem.isReset = true
					TSM.Manage:SetInfoText(currentItem)
				end
			
			
			
				
			end
		end,
	}

	local stCols = {
		{name=L["Item"], width=0.3, defaultort="asc", comparesort=ColSortMethod},
		{name=L["Quantity (Yours)"], width=0.15, align="CENTER", defaultort="asc", comparesort=ColSortMethod},
		{name=L["Total Cost"], width=0.17, align="RIGHT", defaultort="asc", comparesort=ColSortMethod},
		{name=L["Target Price"], width=0.17, align="RIGHT", defaultort="asc", comparesort=ColSortMethod},
		{name=L["Profit Per Item"], width=0.17, align="RIGHT", defaultort="asc", comparesort=ColSortMethod},
	}
	
	local function GetSTColInfo(width)
		local colInfo = CopyTable(stCols)
		for i=1, #colInfo do
			colInfo[i].width = floor(colInfo[i].width*width)
		end

		return colInfo
	end
	
	local ROW_HEIGHT = 19

	local font, size = TSMAPI.Design:GetContentFont("small")
	local st = TSMAPI:CreateScrollingTable(GetSTColInfo(parent:GetWidth()), {font, size, "SetWidgetTextColor"})
	st.frame:SetParent(parent)
	st.frame:SetPoint("TOPLEFT", 0, -50)
	st.frame:SetPoint("BOTTOMRIGHT")
	st.frame:SetScript("OnSizeChanged", function(_,width, height)
			st:SetDisplayCols(GetSTColInfo(width))
			st:SetDisplayRows(13, floor((height-20)/13))
		end)
	st:Show()
	st:SetData({})
	st:RegisterEvents(events)
	st.frame:GetScript("OnSizeChanged")(st.frame, st.frame:GetWidth(), st.frame:GetHeight())
	st:Hide()

	for i, row in ipairs(st.rows) do
		row:SetHeight(ROW_HEIGHT)
		local tex = row:CreateTexture()
		tex:SetPoint("TOPLEFT", 4, -2)
		tex:SetPoint("BOTTOMRIGHT", -4, 2)
		tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
		tex:SetTexCoord(0.017, 1, 0.083, 0.909)
		tex:SetAlpha(0.3)
		row:SetNormalTexture(tex)
		
		if i%2 == 1 then
			row:GetNormalTexture():SetAlpha(0)
		end
		
		for j, col in ipairs(row.cols) do
			col.text:SetHeight(ROW_HEIGHT)
			col.text:SetFont(TSMAPI.Design:GetContentFont("small"))
			TSMAPI.Design:SetWidgetTextColor(col.text)
			col.text:SetShadowColor(0, 0, 0, 0)
		end
	end

	st.scrollframe:SetScript("OnVerticalScroll", function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, st.rowHeight, function() st:Refresh() end)
			for i, row in ipairs(st.rows) do
				local tex = row:GetNormalTexture()
				if not tex then
					tex = row:CreateTexture()
					tex:SetPoint("TOPLEFT", 4, -2)
					tex:SetPoint("BOTTOMRIGHT", -4, 2)
					tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
					tex:SetTexCoord(0.017, 1, 0.083, 0.909)
				end
				if i%2 == st.offset%2 then
					tex:SetAlpha(0.3)
				else
					tex:SetAlpha(0)
				end
				row:SetNormalTexture(tex)
			end
		end)
	
	return st
end

function Reset:CreateAuctionST(parent)
	local events = {
		["OnClick"] = function(_, _, _, _, _, rowNum)
				if rowNum then
					Reset:SelectAuctionRow(rowNum)
				end
				return true
			end,
	}

	local stCols = {
		{name=L["Seller"], width=0.4, align="LEFT"},
		{name=L["Stack Size"], width=0.2, align="CENTER"},
		{name=L["Auction Buyout"], width=0.35, align="RIGHT"},
	}
	
	local function GetSTColInfo(width)
		local colInfo = CopyTable(stCols)
		for i=1, #colInfo do
			colInfo[i].width = floor(colInfo[i].width*width)
		end

		return colInfo
	end
	
	local ROW_HEIGHT = 25

	local font, size = TSMAPI.Design:GetContentFont("small")
	local st = TSMAPI:CreateScrollingTable(GetSTColInfo(parent:GetWidth()), {font, size, "SetWidgetTextColor"})
	st.frame:SetParent(parent)
	st.frame:SetPoint("TOPLEFT", 0, -50)
	st.frame:SetPoint("BOTTOMRIGHT")
	st.frame:SetScript("OnSizeChanged", function(_,width, height)
			st:SetDisplayCols(GetSTColInfo(width))
			st:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
		end)
	st:Show()
	st:RegisterEvents(events)
	st.frame:GetScript("OnSizeChanged")(st.frame, st.frame:GetWidth(), st.frame:GetHeight())
	st:EnableSelection(true)
	st:Hide()

	for i, row in ipairs(st.rows) do
		row:SetHeight(ROW_HEIGHT)
		local tex = row:CreateTexture()
		tex:SetPoint("TOPLEFT", 4, -2)
		tex:SetPoint("BOTTOMRIGHT", -4, 2)
		tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
		tex:SetTexCoord(0.017, 1, 0.083, 0.909)
		tex:SetAlpha(0.3)
		row:SetNormalTexture(tex)
		
		if i%2 == 1 then
			row:GetNormalTexture():SetAlpha(0)
		end
		
		for j, col in ipairs(row.cols) do
			col.text:SetHeight(ROW_HEIGHT)
			col.text:SetFont(TSMAPI.Design:GetContentFont("small"))
			TSMAPI.Design:SetWidgetTextColor(col.text)
			col.text:SetShadowColor(0, 0, 0, 0)
		end
	end
	
	return st
end

function Reset:CreateResetButtons(parent)
	local height = 24
	local frame, parent = TSMAPI:CreateSecureChild(parent)
	frame:SetHeight(height)
	frame:SetWidth(324)
	frame:SetPoint("BOTTOMRIGHT", -75, 6)
	
	frame.Disable = function(self)
		self.buyout:Disable()
		self.cancel:Disable()
		self.summaryButton:Disable()
	end
	
	local function OnCancelClick(self)
		if self.auction then
			for i=GetNumAuctionItems("owner"), 1, -1 do
				if Reset:VerifyAuction(i, "owner", self.auction.record, self.auction.itemString) then
					CancelAuction(i)
					break
				end
			end
		end
		self.auction = nil
		self:Disable()
		Reset:RegisterMessage("TSM_AH_EVENTS", Reset.RemoveCurrentAuction)
		TSMAPI:WaitForAuctionEvents("Cancel")
	end
	
	local function OnStopClick()
		TSM.Manage:OnGUIEvent("stop")
		GUI:Stopped(true)
		Reset:DoneScanning()
	end
	
	local function ReturnToSummary()
		frame:Disable()
		auctionST:Hide()
		summaryST:Show()
		Reset:UpdateSummaryST()
	end
	
	local button = TSMAPI.GUI:CreateButton(frame, 18, "TSMAuctioningResetBuyoutButton")
	button:SetPoint("TOPLEFT", -5, 0)
	button:SetWidth(90)
	button:SetHeight(height)
	button:SetText(L["Buyout"])
	button:SetScript("OnClick", Reset.BuyAuction)
	frame.buyout = button
	
	local button =TSMAPI.GUI:CreateButton(frame, 18, "TSMAuctioningResetCancelButton")
	button:SetPoint("TOPLEFT", 95, 0)
	button:SetWidth(90)
	button:SetHeight(height)
	button:SetText(L["Cancel"])
	button:SetScript("OnClick", OnCancelClick)
	frame.cancel = button
	
	local button = TSMAPI.GUI:CreateButton(frame, 18, "TSMAuctioningResetStopButton")
	button:SetPoint("TOPLEFT", 195, 0)
	button:SetWidth(110)
	button:SetHeight(height)
	button:SetText(L["Stop Scan"])
	button:SetScript("OnClick", OnStopClick)
	frame.stop = button
	
	local summaryButton = TSMAPI.GUI:CreateButton(frame, 16)
	summaryButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -50)
	summaryButton:SetHeight(17)
	summaryButton:SetWidth(150)
	summaryButton:SetScript("OnClick", ReturnToSummary)
	summaryButton:SetText(L["Return to Summary"])
	frame.summaryButton = summaryButton
	
	return frame
end




function Reset:GetScanListAndSetup(GUIRef, options)
	local scanList, tempList, groupTemp = {}, {}, {}
	
	GUI = GUIRef
	doneScanningText = nil
	isScanning = true
	wipe(resetData)
	wipe(summarySTCache)
	wipe(showCache)
	wipe(itemsReset)
	
	-- Add a scan based on items in the AH that match
	for groupName, items in pairs(TSM.db.profile.groups) do
		if (not options or options.groups[groupName]) and TSM.Config:GetConfigValue(groupName, "resetEnabled", true) then
			for itemString in pairs(items) do
				local itemID = TSMAPI:GetItemID(itemString)
				if TSM.itemReverseLookup[itemID] then
					itemString = itemID
				end
				tempList[itemString] = true
			end
		end
	end
	
	for itemString in pairs(tempList) do
		local groupName = TSM.itemReverseLookup[itemString]
		local searchTerm = TSM.Config:GetConfigValue(itemString, "searchTerm")
		if not TSM.db.profile.itemIDGroups[groupName] and searchTerm and searchTerm ~= "" then
			searchTerm = strlower(searchTerm)
			groupTemp[searchTerm] = groupTemp[searchTerm] or {group=groupName}
			tinsert(groupTemp[searchTerm], itemString)
		end
	end
	
	for searchTerm, items in pairs(groupTemp) do
		tinsert(scanList, {name=searchTerm, items=items, group=items.group})
		for _, itemString in ipairs(items) do
			tempList[itemString] = nil
		end
	end
	
	for itemString in pairs(tempList) do
		tinsert(scanList, itemString)
	end
	
	return scanList
end

function Reset:ProcessItem(itemString)
	local item = TSM.Config:GetConfigObject(itemString)
	local scanData = TSM.Scan.auctionData[itemString]
	if not scanData then return end
	
	local priceLevels = {}
	local addFallback, isFirstItem = true, true
	local currentPriceLevel = -math.huge
	
	for _, record in ipairs(scanData.compactRecords) do
		local itemBuyout = record:GetItemBuyout()
		if itemBuyout then
			if not isFirstItem and itemBuyout > item.threshold and itemBuyout < (item.fallback * item.fallbackCap) and itemBuyout > (currentPriceLevel + item.resetResolution) then
				if itemBuyout >= item.fallback then
					addFallback = false
				end
				currentPriceLevel = itemBuyout
				tinsert(priceLevels, itemBuyout)
			end
			isFirstItem = false
		end
	end
	
	if addFallback then
		tinsert(priceLevels, item.fallback)
	end
	
	for _, targetPrice in ipairs(priceLevels) do
		local playerCost, cost, quantity, maxItemCost, playerQuantity = 0, 0, 0, 0, 0
		
		for _, record in ipairs(scanData.compactRecords) do
			local itemBuyout = record:GetItemBuyout()
			if itemBuyout then
				if itemBuyout >= targetPrice then
					break
				end
				
				if itemBuyout > maxItemCost then
					maxItemCost = itemBuyout
				end
				
				if not record:IsPlayer() then
					cost = cost + (record:GetItemBuyout() * record.totalQuantity)
				else
					playerQuantity = playerQuantity + record.totalQuantity
					playerCost = playerCost + (record:GetItemBuyout() * record.totalQuantity)
				end
				quantity = quantity + record.totalQuantity
			end
		end
		
		local profit = TSMAPI:SafeDivide((targetPrice * quantity - (cost + playerCost)), quantity)
		if profit > 0 then
			tinsert(resetData, {configObj=item, itemString=itemString, targetPrice=targetPrice, cost=cost, quantity=quantity, profit=profit, maxItemCost=maxItemCost, playerQuantity=playerQuantity})
		end
	end
	
	Reset:UpdateSummaryST()
end

function Reset:ShouldShow(data)
	local result = {validCost=true, validQuantity=true, validProfit=true, isValid=true}
	local item = data.configObj
	
	if data.cost > item.resetMaxCost then
		result.validCost = false
	elseif data.maxItemCost > item.resetMaxPricePer then
		result.validCost = false
	end
	
	if data.quantity > item.resetMaxQuantity then
		result.validQuantity = false
	end
	
	if data.profit < item.resetMinProfit then
		result.validProfit = false
	end
	
	return (result.validCost and result.validQuantity and result.validProfit), result
end

function Reset:GetSummarySTRow(data)
	local function GetQuantityText(quantity, playerQuantity, isValid)
		if isValid then
			if playerQuantity > 0 then
				return quantity..TSMAPI.Design:GetInlineColor("link2")..playerQuantity..")|r"
			else
				return quantity
			end
		end
		
		return "|cffff2222"..quantity.."|r"
	end
	
	local function GetPriceText(amount, isValid)
		local color
		if not isValid then
			color = "|cffff2222"
		end
	
		return TSMAPI:FormatTextMoney(amount, color, true) or "---"
	end

	local name, itemLink = GetItemInfo(data.itemString)
	local _, shouldShowDetails = Reset:ShouldShow(data)

	local row = {
		cols = {
			{
				value = itemLink,
				args = {name, itemLink},
			},
			{
				value = GetQuantityText,
				args = {data.quantity, data.playerQuantity, shouldShowDetails.validQuantity},
			},
			{
				value = GetPriceText,
				args = {data.cost or 0, shouldShowDetails.validCost},
			},
			{
				value = GetPriceText,
				args = {data.targetPrice, true},
			},
			{
				value = GetPriceText,
				args = {data.profit, shouldShowDetails.validProfit},
			},
		},
		rowInfo = {itemString=data.itemString, targetPrice=data.targetPrice, num=data.quantity, profit=data.profit},
	}
	
	return row, shouldShow
end

function Reset:UpdateSummaryST()
	local rows = {}
	local num = 0
	
	for _, data in ipairs(resetData) do
		if not itemsReset[data.itemString] then
			if showCache[data] == nil then
				showCache[data] = Reset:ShouldShow(data) or false
			end
			if showCache[data] then
				local key = data.itemString .. data.targetPrice
				if not summarySTCache[key] then num = num + 1 end
				summarySTCache[key] = summarySTCache[key] or Reset:GetSummarySTRow(data)
				tinsert(rows, summarySTCache[key])
			end
		end
	end

	summaryST:SetData(rows)
	
	if doneScanningText then
		TSM.Manage:SetInfoText(doneScanningText)
	end
end

function Reset:GetAuctionSTRow(record, index)
	local function GetSellerText(name)
		if strlower(name) == strlower(UnitName("player")) then
			return "|cff99ffff" .. name .. "|r"
		elseif TSM.db.factionrealm.whitelist[strlower(name)] then
			return name .. " |cffff2222" .. L["(whitelisted)"] .. "|r"
		elseif TSM.db.factionrealm.blacklist[strlower(name)] then
			return name .. " |cffff2222" .. L["(blacklisted)"] .. "|r"
		end
		
		return name
	end

	local function GetPriceText(amount)
		return TSMAPI:FormatTextMoney(amount, nil, true) or "---"
	end
	
	local itemString = record.parent:GetItemString()
	local itemID = TSMAPI:GetItemID(itemString)
	if TSM.itemReverseLookup[itemID] then
		itemString = itemID
	end
	
	local row = {
		cols = {
			{
				value = GetSellerText,
				args = {record.seller}
			},
			{
				value = record.count,
				args = {record.count},
			},
			{
				value = GetPriceText,
				args = {record.buyout},
			},
		},
		record = record,
		itemString = itemString,
		index = index,
	}
	
	return row
end

function Reset:UpdateAuctionST()
	local scanData = TSM.Scan.auctionData[currentItem.itemString]
	
	local rows = {}
	
	for i, record in ipairs(scanData.records) do
		local itemBuyout = record:GetItemBuyout()
		if itemBuyout and itemBuyout >= currentItem.targetPrice then
			break
		end
		
		tinsert(rows, Reset:GetAuctionSTRow(record, i))
	end
	
	auctionST:SetData(rows)
end

function Reset:SelectAuctionRow(rowNum)
	local function OnAuctionFound(index)
		local row = auctionST.data[auctionST:GetSelection()]
		
		resetButtons.summaryButton:Enable()
		resetButtons.buyout:Enable()
		resetButtons.buyout.auction = {index=index, row=row.itemString, record=row.record}
	end
	
	local row = auctionST.data[rowNum]
	auctionST:SetSelection(rowNum)
	TSMAPI:StopFindScan()
	resetButtons.buyout:Disable()
	resetButtons.cancel:Disable()
	justBought = {}
	
	if row.record:IsPlayer() then
		resetButtons.summaryButton:Enable()
		resetButtons.cancel:Enable()
		resetButtons.cancel.auction = {record=row.record, itemString=row.itemString}
	else
		Reset:FindCurrentAuctionForBuyout(row.itemString, row.record.buyout, row.record.count)
	end
end

function Reset:RemoveCurrentAuction()
	Reset:UnregisterMessage("TSM_AH_EVENTS")
	if not currentItem then return end
	local scanData = TSM.Scan.auctionData[currentItem.itemString]
	if not scanData then return end
	local row = auctionST.data[auctionST:GetSelection()]
	if not row then return end

	scanData:RemoveRecord(row.index)
	itemsReset[row.itemString] = true
	Reset:UpdateAuctionST()
	
	if #auctionST.data == 0 then
		TSM.Scan.auctionData[row.itemString] = nil
		resetButtons.summaryButton:Enable()
		resetButtons.summaryButton:Click()
		Reset:UpdateSummaryST()
	else
		TSMAPI:CreateTimeDelay("resetBuyDelay", 0.2, function() Reset:SelectAuctionRow(1) end)
	end
end

function Reset:VerifyAuction(index, tab, record, itemString)
	local iString = TSMAPI:GetItemString(GetAuctionItemLink(tab, index))
	local _, _, count, _, _, _, minBid, _, buyout, bid = GetAuctionItemInfo(tab, index)
	return (iString == itemString and bid == record.bid and minBid == record.minBid and buyout == record.buyout and count == record.count)
end



function Reset:GetStatus()
	return 0, 0, 100
end

function Reset:DoAction()

end

function Reset:SkipItem()

end

function Reset:Stop()
	isScanning = false
end

function Reset:DoneScanning()
	local num, totalProfit = 0, 0
	local temp = {}

	for _, data in ipairs(resetData) do
		if not temp[data.itemString] and Reset:ShouldShow(data) then
			temp[data.itemString] = true
			num = num + 1
			totalProfit = totalProfit + data.profit * data.quantity
		end
	end
	
	resetButtons.stop:Disable()
	isScanning = false
	doneScanningText = format(L["Done Scanning!\n\nCould potentially reset %d items for %s profit."], num, TSMAPI:FormatTextMoneyIcon(totalProfit))
	TSM.Manage:SetInfoText(doneScanningText)
end

function Reset:SetupForAction()

end

function Reset:GetCurrentItem()

end

function Reset:IsScanning()
	return isScanning
end


local function ValidateAuction(index, listType)
	local itemString = TSMAPI:GetItemString(GetAuctionItemLink(listType, index))
	if type(currentAuction.itemString) == "number" then
		itemString = TSMAPI:GetItemID(itemString)
	end
	local _, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo(listType, index)
	return count == currentAuction.count and buyout == currentAuction.buyout and itemString == currentAuction.itemString
end

function Reset:BuyAuction()
	local altIndex, mainIndex, foundAuction
	TSMAPI:CancelFrame("resetFindRepeat")
	Reset.isSearching = nil

	for i=GetNumAuctionItems("list"), 1, -1 do
		if ValidateAuction(i, "list") then
			if not justBought[i] then
				mainIndex = i
				break
			else
				altIndex = altIndex or i
			end
		end
	end
	if mainIndex or altIndex then
		PlaceAuctionBid("list", mainIndex or altIndex, currentAuction.buyout)
		foundAuction = true
		justBought[mainIndex or altIndex] = true
	end
	
	resetButtons.buyout:Disable()
	if foundAuction then
		-- wait for all the events that are triggered by this action
		Reset:RegisterMessage("TSM_AH_EVENTS", Reset.RemoveCurrentAuction)
		TSMAPI:WaitForAuctionEvents("Buyout")
	else
		TSM:Print(L["Auction not found. Skipped."])
		Reset:RemoveCurrentAuction()
	end
end

function Reset:OnAuctionFound(index)
	if not Reset.isSearching then return end
	resetButtons.buyout:Enable()
end

function Reset:FindCurrentAuctionForBuyout(itemString, buyout, count)
	currentAuction = {itemString=itemString, buyout=buyout, count=count}
	TSMAPI:CancelFrame("resetFindRepeat")
	TSMAPI:FindAuction(function(...) Reset:OnAuctionFound(...) end, currentAuction)
	TSMAPI:CreateTimeDelay("resetFindRepeat", 0.1, function(...)
			local isFindScanning = TSMAPI:IsFindScanning()
			if TSMAPI:AHTabIsVisible() then
				if not isFindScanning then
					TSMAPI:FindAuction(function(...) Reset:OnAuctionFound(...) end, currentAuction)
				else
					local itemString = isFindScanning.itemString
					if type(currentAuction.itemString) == "number" then
						itemString = TSMAPI:GetItemID(itemString)
					end
					if itemString ~= currentAuction.itemString then
						TSMAPI:FindAuction(function(...) Reset:OnAuctionFound(...) end, currentAuction)
					end
				end
			end
		end, 0.1)
	Reset.isSearching = true
end
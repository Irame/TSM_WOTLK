local TSM = select(2, ...)
local Destroying = TSM:NewModule("Destroying", "AceEvent-3.0")
local GUI = TSMAPI:GetGUIFunctions()
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table

function Destroying:OnInitialize()
	Destroying.auctions = {}
	TSMAPI:RegisterAuctionFunction("TradeSkillMaster_Shopping", Destroying, "Destroying", "Search for things you can mill, prospect, disenchant, or otherwise transform into other items.")
end


-- ------------------------------------------------ --
--							GUI functions						 --
-- ------------------------------------------------ --

function Destroying:Show(frame, automaticMode)
	if automaticMode ~= "automatic" and Destroying.isAutomaticMode then
		wipe(Destroying.auctions)
		Destroying.searchST:SetData({})
		Destroying.topLabel:SetText("", "")
		Destroying.isAutomaticMode = nil
		Destroying.mode = nil
		Destroying.filter1 = nil
		Destroying.filter2 = nil
		Destroying.isScanning = nil
		TSMAPI:StopScan()
	elseif automaticMode == "automatic" then
		Destroying.isAutomaticMode = true
	end

	Destroying.filterFrame = Destroying.filterFrame or Destroying:CreateFilterFrame(frame)
	Destroying.filterFrame:Show()
	Destroying.filterFrame:Enable()
	
	Destroying.topLabel = Destroying.topLabel or Destroying:CreateTopLabel(frame.content)
	Destroying.topLabel:Show()
	
	Destroying.searchST = Destroying.searchST or Destroying:CreateSearchST(frame.content)
	Destroying.searchST:Show()
	
	Destroying:RegisterMessage("TSM_SHOPPING_AH_EVENT")
	TSM.AuctionControl:Show(frame)
	TSMAPI:ShowPricePerCheckBox()
end

function Destroying:ShowAutomaticFrames(parent)
	Destroying:Show(parent, "automatic")
	Destroying.filterFrame:Hide()
	Destroying.searchST:SetData({})
end

function Destroying:Hide()
	Destroying:UnregisterAllMessages()
	if not Destroying.filterFrame then return end
	Destroying.filterFrame:Hide()
	Destroying.topLabel:Hide()
	Destroying.searchST:Hide()
	Destroying.isScanning = nil
	TSMAPI:StopScan()
	TSM.AuctionControl:Hide()
end

function Destroying:CreateFilterFrame(parent)
	local frame, parent = TSMAPI:CreateSecureChild(parent)
	frame:SetPoint("TOPLEFT", 125, -15)
	frame:SetHeight(30)
	frame:SetPoint("TOPRIGHT", -20, -15)
	
	local text = TSMAPI.GUI:CreateLabel(frame)
	TSMAPI.Design:SetWidgetLabelColor(text)
	text:SetPoint("RIGHT", frame, "LEFT")
	text:SetText(L["Mode:"])
	
	local cb = GUI:CreateCheckBox(frame, L["Even Stacks (Ore/Herbs)"], 250, {"TOPLEFT", -40, -35}, L["If checked, only 5/10/15/20 stacks of ore and herbs will be shown."])
	cb:SetValue(TSM.db.profile.evenStacks)
	cb:SetCallback("OnValueChanged", function(_,_,value) TSM.db.profile.evenStacks = value end)
	frame.evenStackCB = cb
	
	frame.Disable = function(self)
		if Destroying.mode ~= "mill" then
			frame.millIcon:Disable()
		end
		if Destroying.mode ~= "prospect" then
			frame.prospectIcon:Disable()
		end
		if Destroying.mode ~= "disenchant" then
			frame.deIcon:Disable()
		end
		if Destroying.mode ~= "transform" then
			frame.transformIcon:Disable()
		end
		
		frame.filter1:SetDisabled(true)
		frame.filter2:SetDisabled(true)
		frame.searchButton:Disable()
	end
	
	frame.Enable = function(self)
		frame.millIcon:Enable()
		frame.prospectIcon:Enable()
		frame.deIcon:Enable()
		frame.transformIcon:Enable()
		
		-- this will handle enabling the dropdowns and search button
		Destroying:UpdateFilters()
	end
	
	local function OnIconClick(self)
		if Destroying.isScanning then return end
		frame.millIcon:UnlockHighlight()
		frame.prospectIcon:UnlockHighlight()
		frame.deIcon:UnlockHighlight()
		frame.transformIcon:UnlockHighlight()
		
		self:LockHighlight()
		Destroying.mode = self.mode
		Destroying.filter1 = nil
		Destroying.filter2 = nil
		Destroying:UpdateFilters()
		Destroying.searchST:ChangeCols(self.mode)
	end
	
	local millIcon = GUI:CreateIcon(frame, "Interface\\Icons\\Ability_Miling", 30, {"TOPLEFT", 10, 0}, L["Click on this icon to enter milling mode."])
	millIcon.mode = "mill"
	millIcon:SetScript("OnClick", OnIconClick)
	frame.millIcon = millIcon
	
	local prospectIcon = GUI:CreateIcon(frame, "Interface\\Icons\\inv_misc_gem_bloodgem_01", 30, {"TOPLEFT", 60, 0}, L["Click on this icon to enter prospecting mode."])
	prospectIcon.mode = "prospect"
	prospectIcon:SetScript("OnClick", OnIconClick)
	frame.prospectIcon = prospectIcon
	
	local deIcon = GUI:CreateIcon(frame, "Interface\\Icons\\Inv_Enchant_Disenchant", 30, {"TOPLEFT", 110, 0}, L["Click on this icon to enter disenchanting mode."])
	deIcon.mode = "disenchant"
	deIcon:SetScript("OnClick", OnIconClick)
	frame.deIcon = deIcon
	
	local transformIcon = GUI:CreateIcon(frame, "Interface\\Icons\\Spell_Shaman_SpectralTransformation", 30, {"TOPLEFT", 160, 0}, L["Click on this icon to enter transformation mode."])
	transformIcon.mode = "transform"
	transformIcon:SetScript("OnClick", OnIconClick)
	frame.transformIcon = transformIcon
	
	
	local dd = GUI:CreateDropdown(frame, nil, 200, {}, {"TOPLEFT", 220, 0}, L["Primary Filter"])
	dd:SetCallback("OnValueChanged", function(_,_,value) Destroying.filter1 = value Destroying.filter2 = nil Destroying:UpdateFilters() end)
	frame.filter1 = dd
	
	local dd = GUI:CreateDropdown(frame, nil, 200, {}, {"TOPLEFT", 410, 0}, L["Secondary Filter"])
	dd:SetCallback("OnValueChanged", function(_,_,value) Destroying.filter2 = value Destroying:UpdateFilters() end)
	frame.filter2 = dd
	
	local btn = TSMAPI.GUI:CreateButton(frame, 18, "TSMAHDestroyingButton")
	btn:SetPoint("TOPLEFT", 600, -2)
	btn:SetWidth(90)
	btn:SetHeight(24)
	btn:SetText(SEARCH)
	btn:SetScript("OnClick", function() Destroying:StartNewSearch() end)
	frame.searchButton = btn
	
	return frame
end

function Destroying:UpdateFilters()
	Destroying.filterFrame.searchButton:Disable()
	local mode = Destroying.mode
	if not mode then
		Destroying.filterFrame.filter1:SetList({L["Select Mode"]})
		Destroying.filterFrame.filter1:SetValue(1)
		Destroying.filterFrame.filter1:SetDisabled(true)
		Destroying.filterFrame.filter2:SetList({L["Select Mode"]})
		Destroying.filterFrame.filter2:SetValue(1)
		Destroying.filterFrame.filter2:SetDisabled(true)
		return
	end

	local data = TSMAPI.DestroyingData[Destroying.mode]
	local groups, items = {}, {}
	
	for i=1, #data do
		groups[data[i].desc] = data[i].desc
		if Destroying.filter1 == data[i].desc then
			for item, iData in pairs(data[i]) do
				if item ~= "desc" and iData.name then
					items[iData.name] = iData.name
				end
			end
		end
	end
	
	Destroying.filterFrame.filter1:SetDisabled(false)
	Destroying.filterFrame.filter1:SetList(groups)
	Destroying.filterFrame.filter1:SetValue(Destroying.filter1)
	
	if Destroying.filter1 then
		Destroying.filterFrame.filter2:SetDisabled(false)
		Destroying.filterFrame.filter2:SetList(items)
		Destroying.filterFrame.filter2:SetValue(Destroying.filter2)
		if Destroying.filter2 then
			Destroying.filterFrame.searchButton:Enable()
		end
	else
		Destroying.filterFrame.filter2:SetList({L["Select Primary Filter"]})
		Destroying.filterFrame.filter2:SetValue(1)
		Destroying.filterFrame.filter2:SetDisabled(true)
	end
end

function Destroying:CreateTopLabel(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()
	
	frame.SetText = function(self, statusText, linkText)
		if statusText then
			self.text:SetText(statusText)
		end
		if linkText then
			self.linkText.link = linkText
			self.linkText:SetText(linkText)
			if linkText == "" then
				self.linkText.bg:Hide()
			else
				self.linkText.bg:Show()
			end
		end
		
		local linkWidth = self.linkText:GetWidth()
		frame.text:SetPoint("BOTTOM", parent, "TOP", -linkWidth/2, 15)
	end

	local text = TSMAPI.GUI:CreateLabel(frame)
	text:SetPoint("BOTTOM", parent, "TOP", 0, 15)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("CENTER")
	text:SetText("")
	frame.text = text
	
	local text2 = TSMAPI.GUI:CreateLabel(frame)
	text2:SetPoint("LEFT", frame.text, "RIGHT", 2, 0)
	text2:SetJustifyH("LEFT")
	text2:SetJustifyV("CENTER")
	text2:SetText("")
	frame.linkText = text2
	frame:SetAllPoints(frame.linkText)
	
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetPoint("TOPLEFT", text2, -2, 2)
	bg:SetPoint("BOTTOMRIGHT", text2, 2, -2)
	TSMAPI.Design:SetContentColor(bg)
	bg:Hide()
	text2.bg = bg
	
	frame:SetScript("OnEnter", function(self)
			local link = self.linkText.link
			if link and link ~= "" and Destroying.mode ~= "prospect" then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(link)
				GameTooltip:Show()
			end
		end)
	frame:SetScript("OnLeave", function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
	
	return frame
end

function Destroying:CreateSearchST(parent)
	local events = {
		["OnClick"] = function(self, _, data, _, _, rowNum, column, st, button)
			if rowNum then
				if Destroying.isScanning then return true end
				
				-- they clicked on a data row
				if button == "LeftButton" then
					-- go to the page for this item
					TSM.AuctionControl:SetCurrentAuction(data[rowNum].record)
					TSMAPI:FindAuction(function() end, {itemString=data[rowNum].itemString, buyout=data[rowNum].record.buyout, count=data[rowNum].record.count})
				else
					TSMAPI:GetSTRowRightClickFunction()(self, data[rowNum].record.parent.itemLink)
				end
				st:SetSelection(rowNum)
				return true
			else
				Destroying:RegisterMessage("TSM_AUCTION_ST_ON_SORT", function()
						Destroying:UnregisterMessage("TSM_AUCTION_ST_ON_SORT")
						Destroying:UpdateSearchSTData()
					end)
				st:OnColumnClick(column)
			end
		end,
	}
	
	local function GetPriceColName()
		if TSMAPI:GetPricePerUnitValue() then
			return L["Auction Item Price"]
		else
			return L["Auction Stack Price"]
		end
	end

	local colInfo = {
		{name=L["Item"], width=0.3},
		{name=L["Auctions"], width=0.09, align="CENTER"},
		{name=L["Stack Size"], width=0.06, align="CENTER"},
		{name=L["Seller"], width=0.13, align="CENTER"},
		{name=L["Price Per Target Item"], width=0.15, align="RIGHT"},
		{name=GetPriceColName(), width=0.15, align="RIGHT"},
		{name=L["% Market Value"], width=0.1, align="CENTER"},
	}

	local st = TSMAPI:CreateAuctionsST(parent, colInfo, events)
	st:Hide()
	st.expanded = {}
	st.UpdateSTData = Destroying.UpdateSearchSTData
	st.ChangeCols = function(self, mode)
		local cols = self.head.cols
		if Destroying.isAutomaticMode then
			cols[5]:GetFontString():SetText(L["Price Per Crafting Mat"])
			cols[7]:GetFontString():SetText(L["% Expected Cost"])
		else
			cols[7]:GetFontString():SetText(L["% Market Value"])
			if mode == "disenchant" then
				cols[5]:GetFontString():SetText(L["Price Per Enchanting Mat"])
			elseif mode == "prospect" then
				cols[5]:GetFontString():SetText(L["Price Per Gem"])
			elseif mode == "mill" then
				cols[5]:GetFontString():SetText(L["Price Per Ink"])
			else
				cols[5]:GetFontString():SetText(L["Price Per Target Item"])
			end
		end
	end
	st.head.cols[TSM.db.profile.destroyingDefaultSort]:Click()
	
	local function OnPriceCBChanged()
		if not st.frame:IsVisible() then return end
		Destroying:UpdateSearchSTData()
		st.head.cols[6]:GetFontString():SetText(GetPriceColName())
	end
	
	st.frame:SetScript("OnShow", function() Destroying:RegisterMessage("TSM_PRICE_PER_CHECKBOX_CHANGED", OnPriceCBChanged) end)
	
	return st
end


-- ------------------------------------------------ --
--				Scanning / Processing functions			 --
-- ------------------------------------------------ --

function Destroying:StartNewSearch(automaticData, parent)
	TSM.AuctionControl:HideAuctionConfirmation()
	if automaticData and automaticData ~= true then
		Destroying.mode, Destroying.filter1, Destroying.filter2, Destroying.isAutomaticMode = unpack(automaticData)
		Destroying:ShowAutomaticFrames(parent)
	end
	local destroyData = TSM.DestroyingUtil:GetData(Destroying.mode, Destroying.filter1, Destroying.filter2)
	local tempQueue = {}
	
	TSM.DestroyingUtil:GetScanData(Destroying.mode, destroyData.data, tempQueue)
	if destroyData.vendorTrade then
		TSM.DestroyingUtil:GetScanData(Destroying.mode, destroyData.vendorTrade.mat, tempQueue)
	end
	
	-- make sure we're not scanning for the same thing twice
	local used, scanQueue = {}, {}
	for i=1, #tempQueue do
		local uniqueString = tempQueue[i].name or tempQueue[i].uniqueString
		if not used[uniqueString] then
			used[uniqueString] = true
			tinsert(scanQueue, tempQueue[i])
		end
	end
	
	Destroying.currentSearchData = destroyData
	if not automaticData then
		Destroying.filterFrame:Disable()
		Destroying.isAutomaticMode = nil
	end
	
	if Destroying.mode ~= "prospect" then
		Destroying.currentSearchData.targetString = select(2, GetItemInfo(Destroying.currentSearchData.itemID))
	else
		Destroying.currentSearchData.targetString = TSMAPI.Design:GetInlineColor("link")..Destroying.filter1.." - "..Destroying.filter2.."|r"
	end
	
	Destroying.searchST:ChangeCols(Destroying.mode)
	TSM:StartScan(scanQueue, Destroying)
end

function Destroying:OnScanCallback(event, ...)
	if event == "QUERY_FINISHED" then
		local data = ...
		Destroying:ProcessScan(data.data)
	elseif event == "SCAN_STATUS_UPDATE" then
		Destroying:UpdateTopLabel(...)
	elseif event == "SCAN_COMPLETE" or event == "SCAN_INTERRUPTED" then
		local data = select(1, ...)
		Destroying:ProcessScan(data, true)
	end
end

function Destroying:UpdateTopLabel(page, numPages, numLeft)
	local queryNum = Destroying.isScanning - numLeft + 1
	Destroying.topLabel:SetText(format(L["Scanning page %s of %s for filter %s of %s..."], page, numPages, queryNum, Destroying.isScanning), "")
end

function Destroying:ProcessScan(scanData, isComplete)
	if not Destroying.isAutomaticMode then
		Destroying.filterFrame:Enable()
	end
	if not scanData then return end
	
	local numAuctions = 0
	local toRemove = {}
	for itemString, obj in pairs(scanData) do
		local numPerTarget, isOre = TSMAPI:GetDestroyingConversionNum(Destroying.mode, Destroying.currentSearchData.itemID, TSMAPI:GetItemID(itemString))
		if Destroying.isAutomaticMode and Destroying.mode == "prospect" and numPerTarget == 1 and TSMAPI:GetItemID(itemString) ~= Destroying.isAutomaticMode then
			numPerTarget = nil
		elseif Destroying.isAutomaticMode and isOre then
			-- if we are shopping for a specific gem via prospecting, we need 6 times as much ore per target gem
			numPerTarget = numPerTarget * 6
		end
		if numPerTarget then
			obj:SetDestroyingNum(numPerTarget)
			if Destroying.isAutomaticMode then
				obj:SetMarketValue(TSM.Automatic.currItem.cost and TSMAPI:SafeDivide(TSM.Automatic.currItem.cost, numPerTarget))
			else
				obj:SetMarketValue(TSMAPI:GetData("market", obj:GetItemID()))
			end
			numAuctions = numAuctions + #obj.records
			if TSM.db.profile.evenStacks then
				local itemID = obj:GetItemID()
				obj:FilterRecords(function(record)
						return not TSM.DestroyingUtil:IsEvenStack(Destroying.mode, itemID, record.count)
					end)
				if #obj.records == 0 then
					tinsert(toRemove, itemString)
				end
			end
		else
			tinsert(toRemove, itemString)
		end
	end
	
	for _, itemString in ipairs(toRemove) do
		scanData[itemString] = nil
	end
	
	if isComplete then
		if numAuctions == 0 then
			Destroying.topLabel:SetText(L["No items found that can be turned into:"], Destroying.currentSearchData.targetString)
		else
			Destroying.topLabel:SetText(format(L["Summary of all %s auctions that can be turned into:"], TSMAPI.Design:GetInlineColor("link")..numAuctions.."|r"), Destroying.currentSearchData.targetString)
		end
		
		if Destroying.isAutomaticMode then
			Destroying:SendMessage("TSM_AUTOMATIC_SCAN_COMPLETE")
		end
		Destroying.isScanning = nil
	end
	
	Destroying.auctions = scanData
	Destroying:UpdateSearchSTData()
end

local defaultSortOrderPerItem = {"DestroyingBuyout", "Percent", "ItemBuyout", "ItemDisplayedBid", "TimeLeft", "Count", "Seller", "NumAuctions", "Name"}
local defaultSortOrderPerStack = {"DestroyingBuyout", "Percent", "Buyout", "DisplayedBid", "TimeLeft", "Count", "Seller", "NumAuctions", "Name"}
local colSortInfoPerItem = {"Name", "NumAuctions", "Count", "Seller", "DestroyingBuyout", "ItemBuyout", "Percent"}
local colSortInfoPerStack = {"Name", "NumAuctions", "Count", "Seller", "DestroyingBuyout", "Buyout", "Percent"}
function Destroying:UpdateSearchSTData()
	if not Destroying.searchST then return end

	local sortParams
	if TSMAPI:GetPricePerUnitValue() then
		sortParams = defaultSortOrderPerItem
		tinsert(sortParams, 1, colSortInfoPerItem[Destroying.searchST.sortInfo.col])
	else
		sortParams = defaultSortOrderPerStack
		tinsert(sortParams, 1, colSortInfoPerStack[Destroying.searchST.sortInfo.col])
	end

	local results = {}
	for itemString, auction in pairs(Destroying.auctions) do
		-- combine auctions with the same buyout / count / seller
		if auction.destroyingNum then
			auction:PopulateCompactRecords(sortParams, Destroying.searchST.sortInfo.order == "asc")
			tinsert(results, auction)
		end
	end
	
	TSMAPI:SetSTData(Destroying.searchST, results)
end

function Destroying:GetAuctionData(itemString)
	return Destroying.auctions[itemString].records
end

function Destroying:TSM_SHOPPING_AH_EVENT(_, mode, postInfo)
	local stSelection = Destroying.searchST:GetSelection()
	local itemString, bid, buyout, count = unpack(Destroying.searchST.data[stSelection].args)
	
	-- If we are in Automatic mode and this was the last one we needed to buy, don't bother updating anything.
	if Destroying.isAutomaticMode then
		if mode == "Buyout" then
			local isDone = TSM.Automatic:ProcessPurchase(itemString, count)
			if isDone then	return end
		end
	end
	
	if mode == "Buyout" or mode == "Cancel" then
		local auctionItem = Destroying.auctions[itemString]
		if auctionItem then
			for i, record in ipairs(auctionItem.records) do
				if record:GetDisplayedBid() == bid and record.buyout == buyout and record.count == count then
					auctionItem:RemoveRecord(i)
					break
				end
			end
			
			if #auctionItem.records == 0 then
				Destroying.auctions[itemString] = nil
			end
		end
	elseif mode == "Post" then
		Destroying.auctions[itemString] = Destroying.auctions[itemString] or TSMAPI:NewAuctionItem()
		for i=1, postInfo.numStacks do
			Destroying.auctions[itemString]:AddAuctionRecord(unpack(postInfo))
		end
	end
	
	local rowIndex = TSM.AuctionControl:GetRowNum(Destroying.searchST, stSelection)
	Destroying:UpdateSearchSTData()
	
	if not TSM.AuctionControl:IsConfirmationVisible() then
		if rowIndex and stSelection and Destroying.searchST.data[stSelection] and Destroying.searchST.rows[rowIndex] then
			Destroying.searchST.rows[rowIndex].cols[1]:Click()
		else
			Destroying.searchST:SetSelection()
			TSM.AuctionControl:SetCurrentAuction()
		end
	end
end
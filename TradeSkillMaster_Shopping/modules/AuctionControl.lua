local TSM = select(2, ...)
local AuctionControl = TSM:NewModule("AuctionControl", "AceEvent-3.0")
local GUI = TSMAPI:GetGUIFunctions()
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table

local function debug(...)
	if TSMAPI.debugging then
		print(...)
	end
end

local private = {}
local confirmationMode, currentAuction

AuctionControl.matchList = {}
AuctionControl.currentPage = {}

local diffFrame = CreateFrame("Frame")
diffFrame:Hide()
diffFrame.num = 0
diffFrame:RegisterEvent("CHAT_MSG_SYSTEM")
diffFrame:RegisterEvent("UI_ERROR_MESSAGE")
diffFrame:SetScript("OnEvent", function(self, event, arg)
	if event == "UI_ERROR_MESSAGE" then
		if arg == ERR_ITEM_NOT_FOUND then
			self.num = self.num - 1
		elseif arg == ERR_AUCTION_HIGHER_BID then
			self.num = self.num - 1
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		if arg == ERR_AUCTION_BID_PLACED then
			self.num = self.num - 1
		end
	end
	
	if self.num < 0 then
		debug("ERROR")
	else
		debug("UPDATE DIFF", self.num)
	end
end)


function AuctionControl:Show(parent)
	private.controlButtons = private.controlButtons or private:CreateControlButtons(parent)
	private.controlButtons:Show()
	
	private.confirmationFrame = private.confirmationFrame or private:CreateConfirmationFrame(parent)
	private.confirmationFrame:Hide()
	
	AuctionControl:SetCurrentAuction()
	AuctionControl:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	diffFrame.num = 0
end

function AuctionControl:Hide()
	AuctionControl:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
	
	private.controlButtons:Hide()
	AuctionControl:HideAuctionConfirmation()
	AuctionControl:SetCurrentAuction()
end

function AuctionControl:SetCurrentAuction(record)
	if not record then
		currentAuction = nil
		private.controlButtons.buyout:Disable()
		private.controlButtons.post:Disable()
		private.controlButtons.cancel:Disable()
		return
	elseif type(record) == "string" then
		local ok, link = pcall(function() return select(2, GetItemInfo(record)) end)
		local itemString = ok and TSMAPI:GetItemString(link)
		if not ok or not private:GetBagLocation(itemString) or not itemString then return end
		
		currentAuction = {}
		currentAuction.itemString = TSMAPI:GetItemString(link)
		currentAuction.link = link
		currentAuction.count = 1
		currentAuction.num = 1
		currentAuction.buyout = (TSMAPI:GetItemValue(link, TSM.db.profile.postPriceSource) or 0) * TSM.db.profile.postPriceSourcePercent
		
		private.controlButtons.post:Enable()
		private.controlButtons.buyout:Disable()
		private.controlButtons.cancel:Disable()
	else
		currentAuction = {}
		currentAuction.itemString = record.parent:GetItemString()
		currentAuction.link = record.parent.itemLink
		currentAuction.buyout = record.buyout
		currentAuction.count = record.count
		currentAuction.numAuctions = record.numAuctions
		currentAuction.seller = record.seller
		currentAuction.isPlayer = record:IsPlayer()
		currentAuction.num = 1
		
		if currentAuction.isPlayer then
			-- it is our so we can cancel but not buy
			private.controlButtons.buyout:Disable()
			private.controlButtons.cancel:Enable()
		else
			-- it isn't ours so we can buy but not cancel
			private.controlButtons.buyout:Enable()
			private.controlButtons.cancel:Disable()
		end
		
		if private:GetBagLocation(currentAuction.itemString) then
			private.controlButtons.post:Enable()
		else
			private.controlButtons.post:Disable()
		end
	end
end

function AuctionControl:IsConfirmationVisible()
	return private.confirmationFrame and private.confirmationFrame:IsVisible()
end

local function ValidateAuction(index, list)
	local itemString, count, buyout, data
	if type(list) == "table" then
		itemString, count, buyout = unpack(list)
	elseif type(list) == "string" then
		itemString = TSMAPI:GetItemString(GetAuctionItemLink(list, index))
		_, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo(list, index)
		data = {itemString, count, buyout}
	else
		return
	end
	return count == currentAuction.count and buyout == currentAuction.buyout and itemString == currentAuction.itemString, data
end

local function GetConfirmationText()
	if confirmationMode == "Buyout" then
		return BUYOUT, L["Purchasing"]
	elseif confirmationMode == "Cancel" then
		return CANCEL, L["Canceling"]
	elseif confirmationMode == "Post" then
		return L["Post"], L["Posting"]
	end
end

function private:GetBagLocation(itemString)
	for bag=0, 4 do
		for slot=1, GetContainerNumSlots(bag) do
			if TSMAPI:GetItemString(GetContainerItemLink(bag, slot)) == itemString then
				return bag, slot
			end
		end
	end
end

function private:OnAuctionFound()
	if not private.isSearching or not currentAuction then return end
	private.isSearching = nil
	
	AuctionControl:UpdateMatchList()
	
	if #AuctionControl.matchList == 0 then
		debug("try again")
		private:FindCurrentAuctionForBuyout()
	else
		debug("auc found")
		private:UpdateAuctionConfirmation()
	end
end

function AuctionControl:IsBuyingComplete()
	debug("isComplete", diffFrame.num)
	return diffFrame.num <= 0
end

function private:FindCurrentAuctionForBuyout()
	if not AuctionControl:IsBuyingComplete() then
		debug("waiting")
		return TSMAPI:CreateTimeDelay("diffDelay", 0.2, private.FindCurrentAuctionForBuyout)
	end
	if not currentAuction then return end
	
	AuctionControl:UpdateMatchList(true)
	if #AuctionControl.matchList > 0 then
		-- the next item is on the current page
		private:UpdateAuctionConfirmation()
		return
	end
	
	debug("finding")
	AuctionControl.matchList = {}
	AuctionControl.currentPage = {}
	
	TSMAPI:FindAuction(private.OnAuctionFound, {itemString=currentAuction.itemString, buyout=currentAuction.buyout, count=currentAuction.count})
	private.isSearching = true
end

function private:ShowConfirmationFrame(mode)
	if not currentAuction then	return end
	diffFrame:Show()

	confirmationMode = mode
	private.confirmationFrame:Show()
	private.confirmationFrame:Disable()
	private.confirmationFrame:ClearTexts()
	private.confirmationFrame.proceed:SetText(GetConfirmationText())
	private.confirmationFrame.searchingText:SetText(L["Searching for item..."])
	private.confirmationFrame:SetPostMode(mode == "Post")
	if mode == "Buyout" then
		private:FindCurrentAuctionForBuyout()
	else
		if mode == "Post" then
			AuctionFrameAuctions.duration = AuctionFrameAuctions.duration or 2
			if not GetAuctionSellItemInfo() or GetAuctionSellItemInfo() ~= GetItemInfo(currentAuction.itemString) then
				PickupContainerItem(private:GetBagLocation(currentAuction.itemString))
				ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton")
			end
			local maxStackSize, totalQuantity = select(8, GetAuctionSellItemInfo())
			currentAuction.postInfo = {maxStackSize=maxStackSize, totalQuantity=totalQuantity, stackSize=1, numStacks=1}
			if currentAuction.buyout then
				currentAuction.postInfo.stackSize = currentAuction.count
				MoneyInputFrame_SetCopper(TSMPostPriceBox, currentAuction.buyout - (not currentAuction.isPlayer and TSM.db.profile.postUndercut or 0))
			else
				MoneyInputFrame_SetCopper(TSMPostPriceBox, max(currentAuction.buyout - TSM.db.profile.postUndercut, 0))
			end
		end
		private:UpdateAuctionConfirmation()
	end
end

function private:UpdateAuctionConfirmation()
	local buyoutText = TSMAPI:FormatTextMoneyIcon(currentAuction.buyout, nil, true)
	local itemBuyoutText = TSMAPI:FormatTextMoneyIcon(floor(currentAuction.buyout/currentAuction.count), nil, true)
	local buttonText, infoText = GetConfirmationText()
	
	private.confirmationFrame.searchingText:SetText("")
	private.confirmationFrame.proceed:SetText(buttonText)
	private.confirmationFrame.linkText:SetText(currentAuction.link)
	
	if confirmationMode == "Post" then
		private.confirmationFrame.postFrame.numStacksBox:SetText(currentAuction.postInfo.numStacks)
		private.confirmationFrame.postFrame.stackSizeBox:SetText(min(currentAuction.postInfo.stackSize, currentAuction.postInfo.totalQuantity))
		private.confirmationFrame.postFrame.postInfo:SetText(format(L["You currently have %s of this item and it stacks up to %s."], currentAuction.postInfo.totalQuantity, currentAuction.postInfo.maxStackSize))
	else
		private.confirmationFrame.quantityText:SetText("x"..currentAuction.count)
		private.confirmationFrame.buyoutText:SetText(L["Item Buyout:"].." "..itemBuyoutText)
		private.confirmationFrame.buyoutText2:SetText(L["Auction Buyout:"].." "..buyoutText)
		private.confirmationFrame.purchasedText:SetText((infoText or "") .. " Auction: "..currentAuction.num.."/"..currentAuction.numAuctions)
	end
	private.confirmationFrame:Enable()
end

function AuctionControl:HideAuctionConfirmation()
	if private.confirmationFrame then private.confirmationFrame:Hide() end
	AuctionControl:UnregisterMessage("TSM_AH_EVENTS")
	private.isSearching = nil
	TSMAPI:StopFindScan()
	confirmationMode = nil
	diffFrame:Hide()
end

function private:DoAction()
	if private.isSearching or not currentAuction then return end
	local foundAuction, isMultiPost

	if confirmationMode == "Buyout" then
		for i=#AuctionControl.matchList, 1, -1 do
			local aucIndex = AuctionControl.matchList[i]
			tremove(AuctionControl.matchList, i)
			tremove(AuctionControl.currentPage, aucIndex)
			if ValidateAuction(aucIndex, "list") then
				PlaceAuctionBid("list", aucIndex, currentAuction.buyout)
				foundAuction = true
				diffFrame.num = diffFrame.num + 1
				break
			end
		end
		debug(foundAuction and "FOUND AUCTION" or "NO FIND AUCTION")
	elseif confirmationMode == "Cancel" then
		for i=GetNumAuctionItems("owner"), 1, -1 do
			if ValidateAuction(i, "owner") then
				CancelAuction(i)
				foundAuction = true
				break
			end
		end 
	elseif confirmationMode == "Post" then
		local buyout = max(MoneyInputFrame_GetCopper(TSMPostPriceBox), 0)
		local bid = floor(buyout * TSM.db.profile.postBidPercent)
		local stackSize = max(currentAuction.postInfo.stackSize, 1)
		local numStacks = max(currentAuction.postInfo.numStacks, 1)
		local postTime = currentAuction.postInfo.postDuration or TSM.db.profile.postDuration
		
		if buyout == 0 then
			private.confirmationFrame:Enable()
			TSM:Print(L["Cannot create auction with 0 buyout."])
			return
		end
		
		currentAuction.postInfo.buyout = buyout
		currentAuction.postInfo.bid = bid
		currentAuction.postInfo.stackSize = stackSize
		currentAuction.postInfo.numStacks = numStacks
		currentAuction.postInfo.postTime = postTime
		
		if GetAuctionSellItemInfo() ~= GetItemInfo(currentAuction.itemString) then
			PickupContainerItem(private:GetBagLocation(currentAuction.itemString))
			ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton")
		end
		StartAuction(bid, buyout, postTime, stackSize, numStacks)
		isMultiPost = numStacks > 1
		foundAuction = true
	end
	
	if confirmationMode == "Buyout" then
		AuctionControl.justBought = true
	elseif foundAuction then
		-- wait for all the events that are triggered by this action
		AuctionControl:RegisterMessage("TSM_AH_EVENTS", private.OnTSMAHEvent)
		TSMAPI:WaitForAuctionEvents(confirmationMode, isMultiPost)
	else
		TSM:Print(L["Auction not found. Skipped."])
		private:OnTSMAHEvent(confirmationMode)
	end
end

function AuctionControl:UpdateMatchList(noPageScanning)
	AuctionControl.matchList = {}
	
	if noPageScanning then
		for i=1, #AuctionControl.currentPage do
			if ValidateAuction(i, AuctionControl.currentPage) then
				tinsert(AuctionControl.matchList, i)
			end
		end
	else
		AuctionControl.currentPage = {}
		for i=1, GetNumAuctionItems("list") do
			local isValid, data = ValidateAuction(i, "list")
			AuctionControl.currentPage[i] = data
			if isValid then
				tinsert(AuctionControl.matchList, i)
			end
		end
	end
end

function AuctionControl:AUCTION_ITEM_LIST_UPDATE()
	if not currentAuction or not TSMAPI:AHTabIsVisible() then return end
	debug("update")
	
	if AuctionControl.justBought then
		AuctionControl.justBought = nil
		private:OnTSMAHEvent("Buyout")
	end
end

function private:OnTSMAHEvent(mode)
	if not currentAuction or not TSMAPI:AHTabIsVisible() then return AuctionControl:UnregisterMessage("TSM_AH_EVENTS") end
	currentAuction.num = currentAuction.num + 1
	if mode == "Post" or currentAuction.num > currentAuction.numAuctions then
		AuctionControl:HideAuctionConfirmation()
	elseif mode == "Buyout" then
		if #AuctionControl.matchList > 0 then
			debug("more items")
			private:UpdateAuctionConfirmation()
		else
			private:FindCurrentAuctionForBuyout()
		end
	else
		private:FindCurrentAuctionForBuyout()
	end
	
	local postInfo
	if mode == "Post" then
		local info = currentAuction.postInfo
		postInfo = {info.stackSize, info.bid, 0, info.buyout, 0, nil, UnitName("player"), (info.postTime == 1 and 3 or 4), numStacks=info.numStacks, itemString=currentAuction.itemString, bid=info.bid, buyout=currentAuction.buyout, count=currentAuction.count, link=currentAuction.link}
	end
	AuctionControl:SendMessage("TSM_SHOPPING_AH_EVENT", mode, postInfo)
end

function private:CreateControlButtons(parent)
	local frame, parent = TSMAPI:CreateSecureChild(parent)
	frame:SetHeight(24)
	frame:SetWidth(390)
	frame:SetPoint("BOTTOMRIGHT", -20, 6)
	
	local function OnClick(button)
		if private.confirmationFrame and private.confirmationFrame:IsVisible() then
			private.confirmationFrame:UpdateStrata()
			return
		elseif currentAuction and TSMAPI:AHTabIsVisible() then
			private:ShowConfirmationFrame(button.which)
		end
	end
	
	local button = TSMAPI.GUI:CreateButton(frame, 18, "TSMAHTabCancelButton")
	button:SetPoint("TOPLEFT", 0, 0)
	button:SetWidth(100)
	button:SetHeight(24)
	button:SetText(CANCEL)
	button.which = "Cancel"
	button:SetScript("OnClick", OnClick)
	frame.cancel = button
	
	local button = TSMAPI.GUI:CreateButton(frame, 18, "TSMAHTabPostButton")
	button:SetPoint("TOPLEFT", 104, 0)
	button:SetWidth(100)
	button:SetHeight(24)
	button:SetText(L["Post"])
	button.which = "Post"
	button:SetScript("OnClick", OnClick)
	button:SetScript("OnShow", function(self)
			TSMAPI:CreateTimeDelay("postEnableDelay", 0.1, function()
					if self:IsEnabled() and (not currentAuction or not private:GetBagLocation(currentAuction.itemString)) then
						self:Disable()
					end
				end, 0.1)
		end)
	button:Hide()
	button:SetScript("OnHide", function()
			TSMAPI:CancelFrame("postEnableDelay")
		end)
	button:Show()
	frame.post = button
	
	local button = TSMAPI.GUI:CreateButton(frame, 18, "TSMAHTabBuyoutButton")
	button:SetPoint("TOPLEFT", 208, 0)
	button:SetWidth(100)
	button:SetHeight(24)
	button:SetText(BUYOUT)
	button.which = "Buyout"
	button:SetScript("OnClick", OnClick)
	frame.buyout = button
	
	return frame
end

function private:CreateConfirmationFrame(parent)
	local frame, parent = TSMAPI:CreateSecureChild(parent)
	TSMAPI.Design:SetFrameBackdropColor(frame)
	frame:Hide()
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetWidth(300)
	frame:SetHeight(150)
	frame.UpdateStrata = function()
		frame:SetFrameStrata("DIALOG")
		frame.bg:SetFrameStrata("HIGH")
	end
	frame:SetScript("OnShow", frame.UpdateStrata)
	frame:SetScript("OnUpdate", function()
			if not TSMAPI:AHTabIsVisible() then
				AuctionControl:HideAuctionConfirmation()
			end
		end)
	
	frame.Enable = function(self)
		self.proceed:Enable()
	end
	
	frame.Disable = function(self)
		self.proceed:Disable()
	end
	
	frame.ClearTexts = function(self)
		self.linkText:SetText("")
		self.quantityText:SetText("")
		self.buyoutText:SetText("")
		self.buyoutText2:SetText("")
		self.purchasedText:SetText("")
		self.proceed:SetText("")
		self.searchingText:SetText("")
	end
	
	frame.SetPostMode = function(self, isPostMode)
		if isPostMode then
			self:SetWidth(400)
			self:SetHeight(200)
			self.purchasedText:Hide()
			self.buyoutText:Hide()
			self.buyoutText2:Hide()
			self.quantityText:Hide()
			self.postFrame:Show()
		else
			self:SetWidth(300)
			self:SetHeight(150)
			self.purchasedText:Show()
			self.buyoutText:Show()
			self.buyoutText2:Show()
			self.quantityText:Show()
			self.postFrame:Hide()
		end
	end
	
	local bg = CreateFrame("Frame", nil, frame)
	bg:SetFrameStrata("HIGH")
	bg:SetPoint("TOPLEFT", parent.content)
	bg:SetPoint("BOTTOMRIGHT", parent.content)
	bg:EnableMouse(true)
	TSMAPI.Design:SetFrameBackdropColor(bg)
	bg:SetAlpha(.2)
	frame.bg = bg
	
	local btn = TSMAPI.GUI:CreateButton(frame, 18, "TSMAHConfirmationActionButton")
	btn:SetPoint("BOTTOMLEFT", 10, 10)
	btn:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -2, 10)
	btn:SetHeight(25)
	btn:SetText("")
	btn:SetScript("OnClick", function()
			if not confirmationMode or not TSMAPI:AHTabIsVisible() then return end
			frame:Disable()
			private:DoAction()
		end)
	frame.proceed = btn
	
	local btn = TSMAPI.GUI:CreateButton(frame, 18, "TSMAHConfirmationActionButton")
	btn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 2, 10)
	btn:SetPoint("BOTTOMRIGHT", -10, 10)
	btn:SetHeight(25)
	btn:SetText(CLOSE)
	btn:SetScript("OnClick", function() frame:Hide() end)
	frame.close = btn
	
	local linkText = TSMAPI.GUI:CreateLabel(frame)
	linkText:SetFontObject(GameFontNormal)
	linkText:SetPoint("TOP", -10, -10)
	frame.linkText = linkText
	
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetPoint("TOPLEFT", linkText, -2, 2)
	bg:SetPoint("BOTTOMRIGHT", linkText, 2, -2)
	TSMAPI.Design:SetContentColor(bg)
	linkText.bg = bg
	bg:Show()
	
	local quantityText = TSMAPI.GUI:CreateLabel(frame)
	quantityText:SetPoint("LEFT", linkText, "RIGHT")
	frame.quantityText = quantityText
	
	local buyoutText = TSMAPI.GUI:CreateLabel(frame)
	buyoutText:SetPoint("TOPLEFT", 10, -41)
	buyoutText:SetJustifyH("LEFT")
	frame.buyoutText = buyoutText
	
	local buyoutText2 = TSMAPI.GUI:CreateLabel(frame)
	buyoutText2:SetPoint("TOPLEFT", buyoutText, "BOTTOMLEFT")
	buyoutText2:SetJustifyH("LEFT")
	frame.buyoutText2 = buyoutText2
	
	local purchasedText = TSMAPI.GUI:CreateLabel(frame)
	purchasedText:SetPoint("TOPLEFT", 10, -70)
	frame.purchasedText = purchasedText
	
	local searchingText = TSMAPI.GUI:CreateLabel(frame)
	searchingText:SetPoint("CENTER")
	frame.searchingText = searchingText
	
	
	-- post only stuff
	local function OnStackBoxTextChange(self, isUser)
		if self == frame.postFrame.numStacksBox then currentAuction.postInfo.numStacks = self:GetNumber()
		else currentAuction.postInfo.stackSize = self:GetNumber() end
		if not isUser then return end
		
		if self == frame.postFrame.numStacksBox then -- numStacksBox
			local numStacks = self:GetNumber()
			local stackSize = max(frame.postFrame.stackSizeBox:GetNumber(), 1)
			if stackSize * numStacks > currentAuction.postInfo.totalQuantity then
				frame.postFrame.stackSizeBox:SetNumber(floor(currentAuction.postInfo.totalQuantity / numStacks))
			end
		else -- stackSizeBox
			local stackSize
			local numStacks = max(frame.postFrame.stackSizeBox:GetNumber(), 1)
			if self:GetNumber() > currentAuction.postInfo.maxStackSize then
				self:SetNumber(currentAuction.postInfo.maxStackSize)
			end
			stackSize = self:GetNumber()
			if stackSize * numStacks > currentAuction.postInfo.totalQuantity then
				frame.postFrame.numStacksBox:SetNumber(floor(currentAuction.postInfo.totalQuantity / stackSize))
			end
			
			MoneyInputFrame_SetCopper(TSMPostPriceBox, floor(stackSize*currentAuction.buyout/currentAuction.count - (not currentAuction.isPlayer and TSM.db.profile.postUndercut or 0)))
		end
	end
	
	local function OnMaxButtonClicked(self)
		if self == frame.postFrame.numStacksMaxButton then
			local stackSize = frame.postFrame.stackSizeBox:GetNumber() or 1
			frame.postFrame.numStacksBox:SetNumber(floor(currentAuction.postInfo.totalQuantity / stackSize))
		elseif self == frame.postFrame.stackSizeMaxButton then
			local stackSize = min(currentAuction.postInfo.totalQuantity, currentAuction.postInfo.maxStackSize)
			local numStacks = min(frame.postFrame.numStacksBox:GetNumber(), floor(currentAuction.postInfo.totalQuantity / stackSize))
			frame.postFrame.stackSizeBox:SetNumber(stackSize)
			frame.postFrame.numStacksBox:SetNumber(numStacks)
		
			MoneyInputFrame_SetCopper(TSMPostPriceBox, floor(stackSize*currentAuction.buyout/currentAuction.count - (not currentAuction.isPlayer and TSM.db.profile.postUndercut or 0)))
		end
	end
	
	local function OnFocusLost(self)
		if self:GetNumber() == 0 then
			self:SetNumber(1)
			MoneyInputFrame_SetCopper(TSMPostPriceBox, floor(currentAuction.buyout/currentAuction.count - (not currentAuction.isPlayer and TSM.db.profile.postUndercut or 0)))
		end
	end
	
	local postFrame = CreateFrame("Frame", nil, frame)
	postFrame:SetAllPoints()
	frame.postFrame = postFrame
	
	local priceBoxLabel = TSMAPI.GUI:CreateLabel(postFrame)
	priceBoxLabel:SetPoint("TOPLEFT", 10, -50)
	priceBoxLabel:SetText(L["Auction Buyout (Stack Price):"])
	postFrame.priceBoxLabel = priceBoxLabel
	
	local priceBox = CreateFrame("Frame", "TSMPostPriceBox", postFrame, "MoneyInputFrameTemplate")
	priceBox:SetPoint("TOPLEFT", 200, -45)
	priceBox:SetHeight(20)
	priceBox:SetWidth(120)
	postFrame.priceBox = priceBox
	
	local stackInfoLabel = TSMAPI.GUI:CreateLabel(postFrame)
	stackInfoLabel:SetPoint("TOPLEFT", 10, -80)
	stackInfoLabel:SetText(L["Stack Info:"])
	postFrame.stackInfoLabel = stackInfoLabel
	
	local numStacksBox = TSMAPI.GUI:CreateInputBox(postFrame, "TSMPostNumStacksBox")
	numStacksBox:SetNumeric(true)
	numStacksBox:SetPoint("TOPLEFT", 110, -75)
	numStacksBox:SetHeight(20)
	numStacksBox:SetWidth(50)
	numStacksBox:SetScript("OnTextChanged", OnStackBoxTextChange)
	numStacksBox:SetScript("OnTabPressed", function() postFrame.stackSizeBox:SetFocus() end)
	numStacksBox:SetScript("OnEditFocusLost", OnFocusLost)
	postFrame.numStacksBox = numStacksBox
	
	local numStacksMaxButton = TSMAPI.GUI:CreateButton(postFrame, 16)
	numStacksMaxButton:SetPoint("TOPLEFT", 165, -75)
	numStacksMaxButton:SetHeight(20)
	numStacksMaxButton:SetWidth(40)
	numStacksMaxButton:SetText(L["MAX"])
	numStacksMaxButton:SetScript("OnClick", OnMaxButtonClicked)
	postFrame.numStacksMaxButton = numStacksMaxButton
	
	local stackInfoLabel = TSMAPI.GUI:CreateLabel(postFrame)
	stackInfoLabel:SetPoint("TOPLEFT", 225, -80)
	stackInfoLabel:SetText(L["stacks of"])
	postFrame.stackInfoLabel2 = stackInfoLabel
	
	local stackSizeBox = TSMAPI.GUI:CreateInputBox(postFrame, "TSMPostStackSizeBox")
	stackSizeBox:SetNumeric(true)
	stackSizeBox:SetPoint("TOPLEFT", 295, -75)
	stackSizeBox:SetHeight(20)
	stackSizeBox:SetWidth(50)
	stackSizeBox:SetScript("OnTextChanged", OnStackBoxTextChange)
	stackSizeBox:SetScript("OnTabPressed", function() postFrame.numStacksBox:SetFocus() end)
	stackSizeBox:SetScript("OnEditFocusLost", OnFocusLost)
	postFrame.stackSizeBox = stackSizeBox
	
	local stackSizeMaxButton = TSMAPI.GUI:CreateButton(postFrame, 16)
	stackSizeMaxButton:SetPoint("TOPLEFT", 350, -75)
	stackSizeMaxButton:SetHeight(20)
	stackSizeMaxButton:SetWidth(40)
	stackSizeMaxButton:SetText(L["MAX"])
	stackSizeMaxButton:SetScript("OnClick", OnMaxButtonClicked)
	postFrame.stackSizeMaxButton = stackSizeMaxButton
	
	local postInfo = TSMAPI.GUI:CreateLabel(postFrame)
	postInfo:SetFontObject(GameFontNormal)
	postInfo:SetTextColor(1, 1, 1, 1)
	postInfo:SetPoint("TOPLEFT", 10, -110)
	postInfo:SetWidth(200)
	postInfo:SetHeight(35)
	postInfo:SetText("")
	postFrame.postInfo = postInfo
	
	local durationDropdown = GUI:CreateDropdown(postFrame, L["Auction Duration"], 150, {L["12 hours"], L["24 hours"], L["48 hours"]}, {"TOPLEFT", 230, -105}, L["Use this checkbox to temporarily modify the post duration. You can change the default value in the Shopping options."])
	durationDropdown:SetValue(TSM.db.profile.postDuration)
	durationDropdown:SetCallback("OnValueChanged", function(_,_,value) currentAuction.postInfo.postDuration = value end)
	
	return frame
end

function AuctionControl:GetRowNum(st, targetRealRow)
	for row, realRow in pairs(st.filtered) do
		if realRow == targetRealRow then
			return row - st.offset
		end
	end
end
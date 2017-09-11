-- Don't change this file before talking to Sapu!
local TSM = select(2, ...)
local GUI = TSMAPI:GetGUIFunctions()
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table

local currentAuction
local private = TSM:GetAuctionFramePrivate()
LibStub("AceEvent-3.0"):Embed(private)
LibStub("AceHook-3.0"):Embed(private)

function TSMAPI:RegisterAuctionFunction(moduleName, obj, buttonText, buttonDesc)
	if not (moduleName and obj and buttonText) then
		return nil, "Invalid arguments", moduleName, obj, buttonText
	elseif not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	buttonDesc = TSMAPI.Design:GetInlineColor("link2")..moduleName.."|r\n\n"..(buttonDesc or "")
	
	tinsert(private.modes, private:GetModeObject(obj, buttonText, buttonDesc, moduleName))
end

function private:ADDON_LOADED(event, addonName)
	if addonName == "Blizzard_AuctionUI" then
		private:UnregisterEvent("ADDON_LOADED")
		if TSM.db then
			private:InitializeAHTab()
		else
			TSMAPI:CreateTimeDelay("blizzAHLoadedDelay", 0.2, private.InitializeAHTab, 0.2)
		end
	end
end

function private:InitializeAHTab()
	if not private:Validate() then return end
	TSMAPI:CancelFrame("blizzAHLoadedDelay")
	private:RegisterEvent("AUCTION_HOUSE_SHOW")
	local n = AuctionFrame.numTabs + 1

	local frame = CreateFrame("Button", "AuctionFrameTab"..n, AuctionFrame, "AuctionTabTemplate")
	frame:SetID(n)
	frame:SetText(TSMAPI.Design:GetInlineColor("link2").."TSM|r")
	frame:SetNormalFontObject(GameFontHighlightSmall)
	frame.isTSMTab = true
	frame:SetPoint("LEFT", _G["AuctionFrameTab"..n-1], "RIGHT", -8, 0)
	private.auctionFrameTab = frame

	PanelTemplates_SetNumTabs(AuctionFrame, n)
	PanelTemplates_EnableTab(AuctionFrame, n)
	AuctionFrame:SetMovable(TSM.db.profile.auctionFrameMovable)
	AuctionFrame:EnableMouse(true)
	if AuctionFrame:GetScale() ~= 1 and TSM.db.profile.auctionFrameScale == 1 then TSM.db.profile.auctionFrameScale = AuctionFrame:GetScale() end
	AuctionFrame:SetScale(TSM.db.profile.auctionFrameScale)
	AuctionFrame:SetScript("OnMouseDown", function(self) if self:IsMovable() then self:StartMoving() end end)
	AuctionFrame:SetScript("OnMouseUp", function(self) if self:IsMovable() then self:StopMovingOrSizing() end end)
	
	private:Hook("AuctionFrameTab_OnClick", function(self)
			if _G["AuctionFrameTab"..self:GetID()] == private.auctionFrameTab then
				private:OnTabClick()
				TSMAuctionFrame:Show()
				TSMAuctionFrame:SetAlpha(1)
				TSMAuctionFrame:SetFrameStrata(AuctionFrame:GetFrameStrata())
				TSMAuctionFrame:SetFrameLevel(AuctionFrame:GetFrameLevel() + 1)
			elseif TSMAuctionFrame.isAttached then
				private:MinimizeAHTab()
			end
		end, true)
	
	-- Makes sure the TSM tab hides correctly when used with addons that hook this function to change tabs (ie Auctionator)
	-- This probably doesn't have to be a SecureHook, but does need to be a Post-Hook.
	private:SecureHook("ContainerFrameItemButton_OnModifiedClick", function(self)
			local tab = _G["AuctionFrameTab"..PanelTemplates_GetSelectedTab(AuctionFrame)]
			if tab ~= private.auctionFrameTab and TSMAuctionFrame:IsVisible() and TSMAuctionFrame.isAttached then
				private:MinimizeAHTab()
			end
		end)
end

function TSMAPI:AHTabIsVisible()
	return not TSMAuctionFrame.isAttached or AuctionFrame.selectedTab == private.auctionFrameTab:GetID()
end

function private:AUCTION_HOUSE_SHOW()
	if TSM.db.profile.openAllBags then
		OpenAllBags()
	end
	if TSM.db.profile.isDefaultTab then
		for i = 1, AuctionFrame.numTabs do
			if i ~= AuctionFrame.selectedTab and _G["AuctionFrameTab"..i] and _G["AuctionFrameTab"..i].isTSMTab then
				_G["AuctionFrameTab"..i]:Click()
				if TSM.db.profile.detachByDefault then
					TSMAuctionFrame.detachButton:Click()
				end
				break
			end
		end
	end
end

function private:OnTabClick()
	AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft")
	AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top")
	AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight")
	AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft")
	AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot")
	AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")
	AuctionFrameMoneyFrame:Hide()
	AuctionFrameCloseButton:Hide()
	private:RegisterEvent("PLAYER_MONEY")
	
	TSMAPI:CreateTimeDelay("hideAHMoneyFrame", .1, function() AuctionFrameMoneyFrame:Hide() end)
	
	TSMAPI.Design:SetFrameBackdropColor(TSMAuctionFrame)
	AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 1)
	
	if not private.frame then
		private:CreateAHTab()
	end
	private.frame:Show()
	TSMAuctionFrame.moneyText:SetMoney(GetMoney())
end

function private:MinimizeAHTab()
	AuctionFrameMoneyFrame:Show()
	AuctionFrameCloseButton:Show()
	AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 12)
	
	TSMAuctionFrame:SetAlpha(0)
	TSMAuctionFrame:SetFrameStrata("LOW")
end

function private:HideCurrentMode()
	if private.mode then private.mode:Hide() end
	currentAuction = nil
	private.mode = nil
end

function private:PLAYER_MONEY()
	TSMAuctionFrame.moneyText:SetMoney(GetMoney())
end

function private:CreateAHTab()
	local iconFrame = CreateFrame("Frame", nil, TSMAuctionFrame)
	iconFrame:SetPoint("CENTER", TSMAuctionFrame, "TOPLEFT", 30, -30)
	iconFrame:SetHeight(100)
	iconFrame:SetWidth(100)
	local icon = iconFrame:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexture("Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon_Big")
	local ag = iconFrame:CreateAnimationGroup()
	local spin = ag:CreateAnimation("Rotation")
	spin:SetOrder(1)
	spin:SetDuration(2)
	spin:SetDegrees(90)
	local spin = ag:CreateAnimation("Rotation")
	spin:SetOrder(2)
	spin:SetDuration(4)
	spin:SetDegrees(-180)
	local spin = ag:CreateAnimation("Rotation")
	spin:SetOrder(3)
	spin:SetDuration(2)
	spin:SetDegrees(90)
	ag:SetLooping("REPEAT")
	iconFrame:SetScript("OnEnter", function() ag:Play() end)
	iconFrame:SetScript("OnLeave", function() ag:Stop() end)
	
	local moneyText = TSMAPI.GUI:CreateTitleLabel(TSMAuctionFrame, 16)
	moneyText:SetPoint("BOTTOMLEFT", 8, 12)
	TSMAPI.Design:SetIconRegionColor(moneyText)
	moneyText.SetMoney = function(self, money)
		self:SetText(TSMAPI:FormatTextMoneyIcon(money))
	end
	TSMAuctionFrame.moneyText = moneyText
	
	local btn = TSMAPI.GUI:CreateButton(TSMAuctionFrame, 16)
	btn:SetPoint("TOPRIGHT", -85, 15)
	btn:SetHeight(20)
	btn:SetWidth(150)
	btn:SetText("Detach TSM Tab")
	btn.tooltip = function()
		if TSMAuctionFrame.isAttached then
			return L["Click this button to detach the TradeSkillMaster tab from the rest of the auction house."]
		else
			return L["Click this button to re-attach the TradeSkillMaster tab to the auction house."]
		end
	end
	btn:SetScript("OnClick", function(self)
			if TSMAuctionFrame.isAttached then
				TSMAuctionFrame.isAttached = false
				TSMAuctionFrame:StartMoving() -- no clue why I have to do this, but I do
				if TSMAuctionFrame.detachedPoint then
					TSMAuctionFrame:ClearAllPoints()
					TSMAuctionFrame:SetPoint(unpack(TSMAuctionFrame.detachedPoint))
				else
					TSMAuctionFrame:SetPoint("TOPLEFT", 200, -200)
				end
				TSMAuctionFrame:StopMovingOrSizing()
				private.auctionFrameTab:Hide()
				AuctionFrameTab1:Click()
				self:SetText(L["Attach TSM Tab"])
				AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 12)
			else
				TSMAuctionFrame.isAttached = true
				TSMAuctionFrame:SetAllPoints(AuctionFrame)
				private.auctionFrameTab:Show()
				private.auctionFrameTab:Click()
				self:SetText(L["Detach TSM Tab"])
				AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 2)
			end
		end)
	btn:SetScript("OnShow", function() btn:SetText(L["Detach TSM Tab"]) end)
	TSMAuctionFrame.detachButton = btn

	TSMAuctionFrame.OnManualClose = function()
		TSMAuctionFrame.isAttached = true
		TSMAuctionFrame:SetAllPoints(AuctionFrame)
		private.auctionFrameTab:Show()
		_G["AuctionFrameTab"..AuctionFrame.selectedTab]:Click()
		TSMAuctionFrame:SetAlpha(0)
		TSMAuctionFrame:SetFrameStrata("LOW")
		btn:SetText(L["Detach TSM Tab"])
	end
	
	TSMAuctionFrame:SetScript("OnShow", function(self)
			self:SetParent(AuctionFrame)
			self:SetAllPoints(AuctionFrame)
			self.isAttached = true
			private.auctionFrameTab:Show()
		end)

	local frame = private:GetAHTabFrame()
	frame:SetAllPoints(TSMAuctionFrame)

	frame.content = private:CreateContentFrame(frame)
	frame.controlFrame = private:CreateControlFrame(frame)
	private:CreateSidebarButtons(frame)
	
	private.frame = frame
end

function private:CreateContentFrame(parent)
	local frame = CreateFrame("Frame")
	parent:AddSecureChild(frame)
	frame:SetPoint("TOPLEFT", 4, -80)
	frame:SetPoint("BOTTOMRIGHT", -4, 35)
	TSMAPI.Design:SetFrameColor(frame)
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 181, -8)
	content:SetPoint("BOTTOMRIGHT", -8, 8)
	TSMAPI.Design:SetContentColor(content)
	return content
end

function private:CreateControlFrame(parent)
	local frame = CreateFrame("Frame")
	parent:AddSecureChild(frame)
	frame:SetHeight(24)
	frame:SetWidth(390)
	frame:SetPoint("BOTTOMRIGHT", -20, 6)

	local cb = GUI:CreateCheckBox(frame, L["Show stacks as price per item"], 210, {"TOPLEFT", -240, 0}, "")
	cb:SetValue(TSM.db.global.pricePerUnit)
	cb:SetCallback("OnValueChanged", function(_,_,value)
			TSM.db.global.pricePerUnit = value
			TSMAPI:WipeAuctionSTCache()
			private:SendMessage("TSM_PRICE_PER_CHECKBOX_CHANGED")
		end)
	cb.frame:Hide()
	frame.checkBox = cb
	
	local button = TSMAPI.GUI:CreateButton(frame, 18, "TSMAHTabCloseButton")
	button:SetPoint("TOPLEFT", 330, 0)
	button:SetWidth(75)
	button:SetHeight(24)
	button:SetText(CLOSE)
	button:SetScript("OnClick", function()
			if TSMAuctionFrame.isAttached then
				CloseAuctionHouse()
			else
				TSMAuctionFrame:OnManualClose()
			end
		end)
	frame.close = button
	
	return frame
end

local BUTTON_HEIGHT = 26
function private:CreateSidebarButtons(parent)
	local function CreateSidebarButtonContainer(titleText)
		titleText = gsub(titleText, "TradeSkillMaster_", "")
		local frame = CreateFrame("Frame")
		parent:AddSecureChild(frame)
		frame:SetWidth(160)
		TSMAPI.Design:SetFrameColor(frame)
		
		local title = frame:CreateFontString(nil, "OVERLAY")
		title:SetPoint("CENTER", frame, "TOP")
		title:SetJustifyH("CENTER")
		title:SetJustifyV("CENTER")
		title:SetFont(TSMAPI.Design:GetBoldFont(), 16)
		title:SetText(titleText)
		TSMAPI.Design:SetIconRegionColor(title)
		
		local titleBG = frame:CreateTexture(nil, "ARTWORK")
		titleBG:SetPoint("TOPLEFT", title, -2, 0)
		titleBG:SetPoint("BOTTOMRIGHT", title, 2, 0)
		TSMAPI.Design:SetFrameColor(titleBG)
		
		return frame
	end
	
	local buttonFrames = {}
	local function UnlockAllHighlight()
		for _, frame in ipairs(buttonFrames) do
			for _, button in ipairs(frame.buttons) do
				button:UnlockHighlight()
			end
		end
	end
	
	local function OnShow(self)
		self:UnlockHighlight()
		if self.flag then
			TSMAPI:CreateTimeDelay("auctionButtonClick", 0.01, function() self:GetScript("OnMouseUp")(self) end)
		end
	end
	
	local buttonInfo, modules = {}, {}
	for _, mode in ipairs(private.modes) do
		modules[mode.module] = modules[mode.module] or {}
		tinsert(modules[mode.module], mode)
	end
	for module, modes in pairs(modules) do
		local moduleButtons = {module=module, modes=modes}
		tinsert(buttonInfo, moduleButtons)
	end
	sort(buttonInfo, function(a, b) return a.module < b.module end)
	
	for i, moduleInfo in ipairs(buttonInfo) do
		local frame = CreateSidebarButtonContainer(moduleInfo.module)
		tinsert(buttonFrames, frame)
		local buttons = {}
		frame.buttons = buttons
		for j, mode in ipairs(moduleInfo.modes) do
			local btn = CreateFrame("Button", nil, frame)
			tinsert(buttons, btn)
			local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
			highlight:SetAllPoints()
			highlight:SetTexture(0, 0, 0, .1)
			highlight:SetBlendMode("BLEND")
			btn.highlight = highlight
			if j == 1 then
				btn:SetPoint("TOPLEFT", 4, -22)
				btn:SetPoint("TOPRIGHT", -4, -22)
			else
				btn:SetPoint("TOPLEFT", buttons[j-1], "BOTTOMLEFT", 0, -4)
				btn:SetPoint("TOPRIGHT", buttons[j-1], "BOTTOMRIGHT", 0, -4)
			end
			btn:SetHeight(22)
			btn:SetScript("OnClick", nil)
			btn:Show()
			local label = TSMAPI.GUI:CreateTitleLabel(btn, 18)
			label:SetPoint("TOP")
			label:SetJustifyH("CENTER")
			label:SetJustifyV("CENTER")
			label:SetHeight(18)
			label:SetText(mode.buttonText)
			btn:SetFontString(label)
			btn:SetScript("OnMouseUp", function(self, button)
					UnlockAllHighlight()
					self:LockHighlight()
					private:OnSidebarButtonClick(mode, button)
				end)
			btn:SetScript("OnEnter", function(self)
					if mode.buttonDesc then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:AddLine(mode.buttonDesc, 1, 1, 1, true)
						GameTooltip:Show()
					end
				end)
			btn:SetScript("OnLeave", function()
					GameTooltip:ClearLines()
					GameTooltip:Hide()
				end)
			btn:Hide()
			btn:SetScript("OnShow", OnShow)
			btn.flag = (mode.obj.moduleName == "Search")
			btn:Show()
		end
		
		if i == 1 then
			frame:SetPoint("TOPLEFT", 15, -100)
		else
			frame:SetPoint("TOPLEFT", buttonFrames[i-1], "BOTTOMLEFT", 0, -15)
		end
		frame:SetHeight(#buttons * 22 + 40)
	end
end

function TSMAPI:GetPricePerUnitValue()
	return TSM.db.global.pricePerUnit
end

function TSMAPI:ShowPricePerCheckBox()
	if not private.frame then return end
	private.frame.controlFrame.checkBox.frame:Show()
end

function TSMAPI:HidePricePerCheckBox()
	if not private.frame then return end
	private.frame.controlFrame.checkBox.frame:Hide()
end

function TSMAPI:CreateSecureChild(parent)
	if not parent.AddSecureChild then error("Invalid secure parent.", 2) end
	
	local child = CreateFrame("Frame")
	local parentRef = parent:AddSecureChild(child)
	return child, parentRef
end

do
	if IsAddOnLoaded("Blizzard_AuctionUI") then
		private:InitializeAHTab()
	else
		private:RegisterEvent("ADDON_LOADED")
	end
end

function private.Validate()
	return TSM.db and tonumber(select(3, strfind(debugstack(), "([0-9]+)"))) == private.num
end
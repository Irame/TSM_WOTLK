-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {auctionTabs={}, queuedTabs={}, previousTab=nil, showCallbacks={}}
LibStub("AceEvent-3.0"):Embed(private)
LibStub("AceHook-3.0"):Embed(private)



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Auction:IsTabVisible(module)
	if not AuctionFrame or not module then return end
	local tab = private:GetAuctionFrame(_G["AuctionFrameTab"..AuctionFrame.selectedTab])
	return module and tab and tab.module == module
end

function TSMAPI.Auction:GetTabShowFunction(moduleName)
	TSMAPI:Assert(not private.showCallbacks[moduleName])
	private.showCallbacks[moduleName] = true
	return function()
		for _, tabFrame in ipairs(private.auctionTabs) do
			if tabFrame.module == moduleName then
				tabFrame.tab:Click()
			end
		end
	end
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function TSM:GetAuctionPlayer(player, player_full)
	if not player then return end
	local realm = GetRealmName() or ""
	if player_full and strjoin("-", player, realm) ~= player_full then
		return player_full
	else
		return player
	end
end

function TSM:SetAuctionTabFlashing(moduleName, flashing)
	if not moduleName then return end
	local moduleTab = nil
	for _, tabFrame in ipairs(private.auctionTabs) do
		if tabFrame.module == moduleName then
			moduleTab = tabFrame
			break
		end
	end
	moduleTab.flashing = flashing
	private:UpdateFlashing()
end

local registeredModules = {}
function TSM:RegisterAuctionFunction(moduleName, callbackShow, callbackHide)
	if registeredModules[moduleName] then return end
	registeredModules[moduleName] = true
	if AuctionFrame then
		private:CreateTSMAHTab(moduleName, callbackShow, callbackHide)
	else
		tinsert(private.queuedTabs, {moduleName, callbackShow, callbackHide})
	end
end



-- ============================================================================
-- Tab Creation Function
-- ============================================================================

function private:CreateTSMAHTab(moduleName, callbackShow, callbackHide)
	TSMAPI.Delay:Cancel("blizzAHLoadedDelay")

	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		parent = AuctionFrame,
		hidden = true,
		mouse = true,
		points = "ALL",
		scripts = {"OnMouseDown", "OnMouseUp", "OnShow", "OnHide"},
		children = {
			{
				type = "TSMLogo",
				versionString = TSM._version,
				size = {100, 100},
				points = {{"CENTER", BFC.PARENT, "TOPLEFT", 30, -30}},
			},
			{
				type = "Button",
				key = "closeBtn",
				textHeight = 18,
				text = CLOSE,
				size = {75, 24},
				points = {{"BOTTOMRIGHT", -5, 5}},
				scripts = {"OnClick"},
			},
			{
				type = "Frame",
				key = "moneyTextFrame",
				mouse = true,
				size = {155, 30},
				points = {{"BOTTOMLEFT", 8, 2}},
				scripts = {"OnEnter", "OnLeave"},
				children = {
					{
						type = "Text",
						key = "text",
						text = "",
						textFont = {TSMAPI.Design:GetBoldFont(), 16},
						justify = {"CENTER", "MIDDLE"},
						points = "ALL",
					},
				},
			},
			{
				type = "Frame",
				key = "content",
				points = {{"TOPLEFT", 4, -80}, {"BOTTOMRIGHT", -4, 35}},
			},
		},
		handlers = {
			OnMouseDown = function() if AuctionFrame:IsMovable() then AuctionFrame:StartMoving() end end,
			OnMouseUp = function() if AuctionFrame:IsMovable() then AuctionFrame:StopMovingOrSizing() end end,
			OnShow = function(self)
				self:SetAllPoints()
				self.shown = true
				if not self.minimized then
					callbackShow(self)
				end
			end,
			OnHide = function(self)
				if not self.minimized and self.shown then
					self.shown = nil
					callbackHide()
				end
			end,
			closeBtn = {
				OnClick = CloseAuctionHouse,
			},
			moneyTextFrame = {
				OnEnter = function(self)
					local currentTotal = 0
					local incomingTotal = 0
					for i=1, GetNumAuctionItems("owner") do
						local count, buyoutAmount = TSMAPI.Util:Select({3, 10}, GetAuctionItemInfo("owner", i))
						if count == 0 then
							incomingTotal = incomingTotal + buyoutAmount
						else
							currentTotal = currentTotal + buyoutAmount
						end
					end
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(L["Gold Info:"])
					GameTooltip:AddDoubleLine(L["Player Gold"], TSMAPI:MoneyToString(GetMoney(), "OPT_ICON"), 1, 1, 1, 1, 1, 1)
					GameTooltip:AddDoubleLine(L["Incoming Auction Sales"], TSMAPI:MoneyToString(incomingTotal, "OPT_ICON"), 1, 1, 1, 1, 1, 1)
					GameTooltip:AddDoubleLine(L["Current Auctions Value"], TSMAPI:MoneyToString(currentTotal, "OPT_ICON"), 1, 1, 1, 1, 1, 1)
					GameTooltip:Show()
				end,
				OnLeave = function()
					GameTooltip:ClearLines()
					GameTooltip:Hide()
				end,
			},
		},
	}
	local auctionTab = TSMAPI.GUI:BuildFrame(frameInfo)
	auctionTab.module = moduleName
	auctionTab:SetMovable(true)
	TSMAPI.Design:SetTitleTextColor(auctionTab.moneyTextFrame.text)
	TSMAPI.Design:SetIconRegionColor(auctionTab.moneyTextFrame.text)
	TSMAPI.Design:SetContentColor(auctionTab.contentFrame)

	local tabId = AuctionFrame.numTabs + 1
	local tab = CreateFrame("Button", "AuctionFrameTab"..tabId, AuctionFrame, "AuctionTabTemplate")
	tab:Hide()
	tab:SetID(tabId)
	tab:SetText(TSMAPI.Design:GetInlineColor("link2")..moduleName.."|r")
	tab:SetNormalFontObject(GameFontHighlightSmall)
	tab:SetPoint("LEFT", _G["AuctionFrameTab"..tabId-1], "RIGHT", -8, 0)
	tab:Show()
	PanelTemplates_SetNumTabs(AuctionFrame, tabId)
	PanelTemplates_EnableTab(AuctionFrame, tabId)
	auctionTab.tab = tab

	local ag = tab:CreateAnimationGroup()
	local flash = ag:CreateAnimation("Alpha")
	flash:SetOrder(1)
	flash:SetFromAlpha(1)
	flash:SetToAlpha(0.5)
	flash:SetDuration(0.5)
	local flash = ag:CreateAnimation("Alpha")
	flash:SetOrder(2)
	flash:SetFromAlpha(0.5)
	flash:SetToAlpha(1)
	flash:SetDuration(0.5)
	ag:SetLooping("REPEAT")
	auctionTab.flash = ag

	tinsert(private.auctionTabs, auctionTab)
end



-- ============================================================================
-- Initialization Functions
-- ============================================================================

function private:InitializeAHTab()
	if not TSM.db then
		return TSMAPI.Delay:AfterTime(0.2, private.InitializeAHTab)
	end
	for _, info in ipairs(private.queuedTabs) do
		private:CreateTSMAHTab(unpack(info))
	end
	private.queuedTabs = {}
	private:InitializeAuctionFrame()
	private.isInitialized = true
	if AuctionFrame and AuctionFrame:IsVisible() then
		private:AUCTION_HOUSE_SHOW()
	end
end

function private:InitializeAuctionFrame()
	-- make the AH movable if this option is enabled
	AuctionFrame:SetMovable(TSM.db.profile.auctionFrameMovable)
	AuctionFrame:EnableMouse(true)
	AuctionFrame:SetScript("OnMouseDown", function(self) if self:IsMovable() then self:StartMoving() end end)
	AuctionFrame:SetScript("OnMouseUp", function(self) if self:IsMovable() then self:StopMovingOrSizing() end end)

	-- scale the auction frame according to the TSM option
	if AuctionFrame:GetScale() ~= 1 and TSM.db.profile.auctionFrameScale == 1 then TSM.db.profile.auctionFrameScale = AuctionFrame:GetScale() end
	AuctionFrame:SetScale(TSM.db.profile.auctionFrameScale)

	private:Hook("AuctionFrameTab_OnClick", private.TabChangeHook, true)

	-- Makes sure the TSM tab hides correctly when used with addons that hook this function to change tabs (ie Auctionator)
	-- This probably doesn't have to be a SecureHook, but does need to be a Post-Hook.
	private:SecureHook("ContainerFrameItemButton_OnModifiedClick", function()
		local currentTab = _G["AuctionFrameTab"..PanelTemplates_GetSelectedTab(AuctionFrame)]
		if private:IsTSMTab(currentTab) then return end
		private.TabChangeHook(currentTab)
	end)
end



-- ============================================================================
-- Tab Changing Functions
-- ============================================================================

function private.TabChangeHook(selectedTab)
	if private.previousTab and private:IsTSMTab(private.previousTab) then
		-- we are switching away from a TSM tab to a non-TSM tab, so minimize the TSM tab
		private:MinimizeTab(private:GetAuctionFrame(private.previousTab))
	end
	if private:IsTSMTab(selectedTab) then
		private:ShowTab(private:GetAuctionFrame(selectedTab))
	end
	private.previousTab = selectedTab
	private:UpdateFlashing()
end

function private:ShowTab(tab)
	AuctionFrameTopLeft:Hide()
	AuctionFrameTop:Hide()
	AuctionFrameTopRight:Hide()
	AuctionFrameBotLeft:Hide()
	AuctionFrameBot:Hide()
	AuctionFrameBotRight:Hide()
	AuctionFrameMoneyFrame:Hide()
	AuctionFrameCloseButton:Hide()
	private:RegisterEvent("PLAYER_MONEY", "OnEvent")

	TSMAPI.Delay:AfterTime(0.1, function() AuctionFrameMoneyFrame:Hide() end)

	TSMAPI.Design:SetFrameBackdropColor(tab)
	AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 1)
	AuctionFrame:SetFrameLevel(1)

	tab:Show()
	tab.minimized = nil
	tab.moneyTextFrame.text:SetText(TSMAPI:MoneyToString(GetMoney(), "OPT_ICON"))
	tab:SetFrameStrata(AuctionFrame:GetFrameStrata())
	tab:SetFrameLevel(AuctionFrame:GetFrameLevel() + 1)
end

function private:MinimizeTab(tab)
	tab.minimized = true
	tab:Hide()

	AuctionFrameTopLeft:Show()
	AuctionFrameTop:Show()
	AuctionFrameTopRight:Show()
	AuctionFrameBotLeft:Show()
	AuctionFrameBot:Show()
	AuctionFrameBotRight:Show()
	AuctionFrameMoneyFrame:Show()
	AuctionFrameCloseButton:Show()
	AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 12)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:IsTSMTab(auctionTab)
	return private:GetAuctionFrame(auctionTab) and true or false
end

function private:GetAuctionFrame(targetTab)
	for _, tabFrame in ipairs(private.auctionTabs) do
		if tabFrame.tab == targetTab then
			return tabFrame
		end
	end
end

function private:UpdateFlashing()
	for _, tabFrame in ipairs(private.auctionTabs) do
		if tabFrame.flashing and tabFrame.minimized then
			tabFrame.flash:Play()
		else
			tabFrame.flash:Stop()
		end
	end
end



-- ============================================================================
-- Event Handler
-- ============================================================================

function private:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		-- watch for the AH to be loaded
		local addonName = ...
		if addonName == "Blizzard_AuctionUI" then
			private:UnregisterEvent("ADDON_LOADED")
			private:InitializeAHTab()
		end
	elseif event == "PLAYER_MONEY" then
		-- update player money text on AH tabs
		for _, tab in ipairs(private.auctionTabs) do
			if tab:IsVisible() then
				tab.moneyTextFrame.text:SetText(TSMAPI:MoneyToString(GetMoney(), "OPT_ICON"))
			end
		end
	elseif event == "AUCTION_HOUSE_SHOW" then
		-- AH frame was shown
		if private.isInitialized then
			if TSM.db.profile.protectAH and not private.hasShown then
				AuctionFrame.Hide = function() end
				HideUIPanel(AuctionFrame)
				AuctionFrame.Hide = nil
				SetUIPanelAttribute(AuctionFrame, "area", nil)
				private.hasShown = true
			end
			if TSM.db.profile.openAllBags then
				OpenAllBags()
			end
			for i = AuctionFrame.numTabs, 1, -1 do
				local text = gsub(_G["AuctionFrameTab"..i]:GetText(), "|r", "")
				text = gsub(text, "|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]", "")
				if text == TSM.db.profile.defaultAuctionTab then
					_G["AuctionFrameTab"..i]:Click()
					return
				end
			end
			_G["AuctionFrameTab1"]:Click()
		end
	elseif event == "AUCTION_HOUSE_CLOSED" then
		-- AH frame was closed
		for _, tab in ipairs(private.auctionTabs) do
			tab.minimized = nil
			tab:GetScript("OnHide")(tab)
		end
	end
end

do
	private:RegisterEvent("AUCTION_HOUSE_SHOW", "OnEvent")
	private:RegisterEvent("AUCTION_HOUSE_CLOSED", "OnEvent")
	if IsAddOnLoaded("Blizzard_AuctionUI") then
		private:InitializeAHTab()
	else
		private:RegisterEvent("ADDON_LOADED", "OnEvent")
	end
	hooksecurefunc("message", function()
		if not AuctionFrame then return end
		if not private:IsTSMTab(_G["AuctionFrameTab"..PanelTemplates_GetSelectedTab(AuctionFrame)]) then return end

		-- suppress Auctioneer's message
		if BasicScriptErrorsText:GetText() == "The Server is not responding correctly.\nClosing and reopening the Auctionhouse may fix this problem." then
			-- hide the error by clicking the button
			BasicScriptErrorsButton:Click()
		end
	end)
end

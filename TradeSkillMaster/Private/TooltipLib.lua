-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local TooltipLib = TSM:NewModule("TooltipLib")
local private = {tooltipRegistry={}, callback=nil, hookedBattlepetGlobal=nil, tooltipMethodPrehooks=nil, tooltipMethodPosthooks=nil, numExtraTips=0}



-- ============================================================================
-- Module Functions
-- ============================================================================

function TooltipLib:Initialize(callback)
	private.callback = callback
	private.RegisterTooltip(GameTooltip)
	private.RegisterTooltip(ItemRefTooltip)
	private.RegisterTooltip(BattlePetTooltip)
	private.RegisterTooltip(FloatingBattlePetTooltip)
end

function TooltipLib:AddLine(tooltip, text, r, g, b)
	if TSM.db.profile.embeddedTooltip and not private.IsBattlePetTooltip(tooltip) then
		tooltip:AddLine(text, r, g, b)
	else
		local reg = private.tooltipRegistry[tooltip]
		reg.extraTip:AddLine(text, r, g, b)
		reg.extraTipUsed = true
	end
end

function TooltipLib:AddDoubleLine(tooltip, textLeft, textRight, lr, lg, lb, rr, rg, rb)
	if TSM.db.profile.embeddedTooltip and not private.IsBattlePetTooltip(tooltip) then
		tooltip:AddDoubleLine(textLeft, textRight, lr, lg, lb, rr, rg, rb)
	else
		local reg = private.tooltipRegistry[tooltip]
		reg.extraTip:AddDoubleLine(textLeft, textRight, lr, lg, lb, rr, rg, rb)
		reg.extraTipUsed = true
	end
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.RegisterTooltip(tooltip)
	local reg = { extraTip = private.NewExtraTip(tooltip) }
	reg.extraTip:Attach(tooltip)
	private.tooltipRegistry[tooltip] = reg

	if private.IsBattlePetTooltip(tooltip) then
		local scriptHooks = {
			OnHide = private.OnTooltipCleared
		}
		for script, prehook in pairs(scriptHooks) do
			local orig = tooltip:GetScript(script)
			tooltip:SetScript(script, function(...)
				prehook(...)
				if orig then
					orig(...)
				end
			end)
		end
		if not private.hookedBattlepetGlobal then
			private.hookedBattlepetGlobal = true
			hooksecurefunc("BattlePetTooltipTemplate_SetBattlePet", private.OnTooltipSetBattlePet)
		end
	else
		local scriptHooks = {
			OnTooltipSetItem = private.OnTooltipSetItem,
			OnTooltipCleared = private.OnTooltipCleared
		}
		for script, prehook in pairs(scriptHooks) do
			local orig = tooltip:GetScript(script)
			tooltip:SetScript(script, function(...)
				prehook(...)
				if orig then
					orig(...)
				end
			end)
		end

		for method, prehook in pairs(private.tooltipMethodPrehooks) do
			local posthook = private.tooltipMethodPosthooks[method]
			local orig = tooltip[method]
			tooltip[method] = function(...)
				prehook(...)
				local a, b, c, d, e, f, g, h, i, j, k = orig(...)
				posthook(...)
				return a, b, c, d, e, f, g, h, i, j, k
			end
		end
	end
end

function private.IsBattlePetTooltip(tooltip)
	return tooltip == BattlePetTooltip or tooltip == FloatingBattlePetTooltip
end

function private.GetLibExtraTipFrame(tooltip, ...)
	for i = 1, select('#', ...) do
		local frame = select(i, ...)
		if frame.InitLines and frame:GetParent() == tooltip and frame:IsVisible() then
			return frame
		end
	end
end



-- ============================================================================
-- Tooltip Script Handlers
-- ============================================================================

function private.OnTooltipSetItem(tooltip)
	local reg = private.tooltipRegistry[tooltip]
	if reg.hasItem then return end

	tooltip:Show()
	local testName, item = tooltip:GetItem()
	if not item then
		item = reg.item
	elseif testName == "" then
		-- this is likely a case where :GetItem() is broken for recipes - detect and try to fix it
		if strmatch(item, "item:([0-9]*):") == "" then
			item = reg.item
		end
	end
	if not item then return end

	reg.hasItem = true
	reg.extraTip:Attach(tooltip)
	local r, g, b = GetItemQualityColor(TSMAPI.Item:GetQuality(item) or 0)
	reg.extraTip:AddLine(TSMAPI.Item:GetName(item), r, g, b)

	private.callback(tooltip, item, reg.quantity or 1)
	tooltip:Show()
	if reg.extraTipUsed then
		reg.extraTip:Show()
	end
end

function private.OnTooltipCleared(tooltip)
	local reg = private.tooltipRegistry[tooltip]
	if reg.ignoreOnCleared then return end
	tooltip:SetFrameLevel(1)

	reg.extraTipUsed = nil
	reg.minWidth = 0
	reg.quantity = nil
	reg.hasItem = nil
	reg.item = nil
	reg.extraTip:Hide()
	reg.extraTip.minWidth = 0
	reg.extraTip:SetHeight(0)
end

function private.OnTooltipSetBattlePet(tooltip, data)
	local reg = private.tooltipRegistry[tooltip]
	if reg.hasItem then
		private.OnTooltipCleared(tooltip)
	end
	-- extract values from data
	local speciesID = data.speciesID
	local level = data.level
	local breedQuality = data.breedQuality
	local maxHealth = data.maxHealth
	local power = data.power
	local speed = data.speed
	local battlePetID = data.battlePetID or "0x0000000000000000"
	local name = data.name
	local customName = data.customName
	local colcode, r, g, b
	if breedQuality == -1 then
		colcode = NORMAL_FONT_COLOR_CODE
		r, g, b = NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b
	else
		local coltable = ITEM_QUALITY_COLORS[breedQuality] or ITEM_QUALITY_COLORS[0]
		colcode = coltable.hex
		r, g, b = coltable.r, coltable.g, coltable.b
	end

	local quantity = reg.quantity or 1
	local link = reg.item
	if not link then
		link = format("%s|Hbattlepet:%d:%d:%d:%d:%d:%d:%s|h[%s]|h|r", colcode, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID, customName or name)
	end

	reg.hasItem = true
	reg.extraTip:Attach(tooltip)
	reg.extraTip:AddLine(name, r, g, b)

	private.callback(tooltip, link, reg.quantity or 1)
	if reg.extraTipUsed then
		reg.extraTip:Show()
	end
end



-- ============================================================================
-- Hook Setup Code
-- ============================================================================

do
	local function PreHookHelper(self, quantityFunc, quantityOffset, ...)
		private.OnTooltipCleared(self)
		local reg = private.tooltipRegistry[self]
		reg.ignoreOnCleared = true
		if type(quantityFunc) == "number" then
			reg.quantity = quantityFunc
		else
			reg.quantity = select(quantityOffset, quantityFunc(...))
		end
		return reg
	end
	private.tooltipMethodPrehooks = {
		SetQuestItem = function(self, ...) PreHookHelper(self, GetQuestItemInfo, 3, ...) end,
		SetQuestLogItem = function(self, type, ...)
			local quantityFunc = type == "choice" and GetQuestLogChoiceInfo or GetQuestLogRewardInfo
			PreHookHelper(self, quantityFunc, 3, ...)
		end,
		SetRecipeReagentItem = function(self, ...)
			local reg = PreHookHelper(self, C_TradeSkillUI.GetRecipeReagentInfo, 3, ...)
			reg.item = C_TradeSkillUI.GetRecipeReagentItemLink(...)
		end,
		SetRecipeResultItem = function(self, ...)
			private.OnTooltipCleared(self)
			local reg = private.tooltipRegistry[self]
			reg.ignoreOnCleared = true
			local lNum, hNum = C_TradeSkillUI.GetRecipeNumItemsProduced(...)
			-- the quantity can be a range, so use a quantity of 1 if so
			reg.quantity = lNum == hNum and lNum or 1
		end,
		SetBagItem = function(self, ...) PreHookHelper(self, GetContainerItemInfo, 2, ...) end,
		SetGuildBankItem = function(self, ...)
			local reg = PreHookHelper(self, GetGuildBankItemInfo, 2, ...)
			reg.item = GetGuildBankItemLink(...)
		end,
		SetVoidItem = function(self, ...) PreHookHelper(self, 1) end,
		SetVoidDepositItem = function(self, ...) PreHookHelper(self, 1) end,
		SetVoidWithdrawalItem = function(self, ...) PreHookHelper(self, 1) end,
		SetInventoryItem = function(self, ...) PreHookHelper(self, GetInventoryItemCount, 1, ...) end,
		SetMerchantItem = function(self, ...)
			local reg = PreHookHelper(self, GetMerchantItemInfo, 4, ...)
			reg.item = GetMerchantItemLink(...)
		end,
		SetMerchantCostItem = function(self, ...) PreHookHelper(self, GetMerchantItemCostItem, 2, ...) end,
		SetBuybackItem = function(self, ...) PreHookHelper(self, GetBuybackItemInfo, 4, ...) end,
		SetAuctionItem = function(self, ...)
			local reg = PreHookHelper(self, GetAuctionItemInfo, 3, ...)
			reg.item = GetAuctionItemLink(...)
		end,
		SetAuctionSellItem = function(self, ...) PreHookHelper(self, GetAuctionSellItemInfo, 3, ...) end,
		SetInboxItem = function(self, index) PreHookHelper(self, GetInboxItem, 4, index, 1) end,
		SetSendMailItem = function(self, ...) PreHookHelper(self, GetSendMailItem, 4, ...) end,
		SetLootItem = function(self, ...) PreHookHelper(self, GetLootSlotInfo, 3, ...) end,
		SetLootRollItem = function(self, ...) PreHookHelper(self, GetLootRollItemInfo, 3, ...) end,
		SetTradePlayerItem = function(self, ...) PreHookHelper(self, GetTradePlayerItemInfo, 3, ...) end,
		SetTradeTargetItem = function(self, ...) PreHookHelper(self, GetTradeTargetItemInfo, 3, ...) end,
		SetHyperlink = function(self, link)
			local reg = private.tooltipRegistry[self]
			if reg.ignoreSetHyperlink then return end
			private.OnTooltipCleared(self)
			reg.ignoreOnCleared = true
			reg.item = link
		end,
	}

	-- populate all the posthooks
	local function TooltipMethodPostHook(self)
		private.tooltipRegistry[self].ignoreOnCleared = nil
	end
	private.tooltipMethodPosthooks = {}
	for funcName in pairs(private.tooltipMethodPrehooks) do
		private.tooltipMethodPosthooks[funcName] = TooltipMethodPostHook
	end
	-- SetHyperlink is special
	private.tooltipMethodPosthooks.SetHyperlink = function(self)
		local reg = private.tooltipRegistry[self]
		if not reg.ignoreSetHyperlink then
			reg.ignoreOnCleared = nil
		end
	end
end



-- ============================================================================
-- ExtraTip Functions
-- ============================================================================

private.extraTipMethods = {
	Attach = function(self, tooltip)
		self:SetOwner(tooltip, "ANCHOR_NONE")
		self.anchorFrame = nil
		self:OnUpdate()
	end,

	Show = function(self)
		self:SetScript("OnUpdate", self.OnUpdate)
		self.anchorFrame = nil
		GameTooltip.Show(self)
		self:OnUpdate()
		local numLines = self:NumLines()
		local changedLines = self.changedLines or 0
		if changedLines >= numLines then return end
		for i = changedLines + 1, numLines do
			local left, right = self.Left[i], self.Right[i]
			local font = i == 1 and GameFontNormal or GameFontNormalSmall
			local r, g, b, a = nil, nil, nil, nil

			r, g, b, a = left:GetTextColor()
			left:SetFontObject(font)
			left:SetTextColor(r, g, b, a)

			r, g, b, a = right:GetTextColor()
			right:SetFontObject(font)
			right:SetTextColor(r, g, b, a)
		end
		self.changedLines = numLines
		GameTooltip.Show(self)
		self:OnUpdate()
	end,

	OnUpdate = function(self)
		local tooltip = self:GetParent()
		local anchorFrame = private.GetLibExtraTipFrame(tooltip, tooltip:GetChildren()) or tooltip
		if anchorFrame ~= self.anchorFrame then
			self:SetPoint("TOP", anchorFrame, "BOTTOM")
			self.anchorFrame = anchorFrame
		end
	end,
}

function private.NewExtraTip(tooltip)
	private.numExtraTips = private.numExtraTips + 1
	local extraTip = CreateFrame("GameTooltip", "TSMExtraTip"..private.numExtraTips, tooltip, "GameTooltipTemplate")
	extraTip:SetClampedToScreen(false)

	for name, func in pairs(private.extraTipMethods) do
		extraTip[name] = func
	end

	local lineMetatable = {
		__index = function(t, k)
			local v = _G[t.name..k]
			rawset(t, k, v)
			return v
		end
	}
	extraTip.Left = setmetatable({name = extraTip:GetName().."TextLeft"}, lineMetatable)
	extraTip.Right = setmetatable({name = extraTip:GetName().."TextRight"}, lineMetatable)
	return extraTip
end

-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_Crafting.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Vendor = TSM:NewModule("Vendor", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting")

function Vendor:OnInitialize()
	Vendor:RegisterEvent("MERCHANT_SHOW", "CreateMerchantBuyButton")
end

function Vendor:CreateMerchantBuyButton()
	if not Vendor.merchantButton then
		local buyButton = CreateFrame("Button", nil, MerchantFrame, "UIPanelButtonTemplate")
		buyButton:SetHeight(25)
		buyButton:SetText(L["TSM_Crafting - Buy Vendor Items"])
		buyButton:GetFontString():SetPoint("CENTER")
		local tFile, tSize = GameFontNormal:GetFont()
		buyButton:GetFontString():SetFont(tFile, tSize, "OUTLINE")
		buyButton:GetFontString():SetTextColor(1, 1, 1, 1)
		buyButton:SetPushedTextOffset(0, 0)
		buyButton:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 20,
			insets = {left = 2, right = 2, top = 4, bottom = 4},
		})
		buyButton:SetScript("OnDisable", function(self) self:GetFontString():SetTextColor(0.5, 0.5, 0.5, 1) end)
		buyButton:SetScript("OnEnable", function(self) self:GetFontString():SetTextColor(1, 1, 1, 1) end)	
		buyButton:SetScript("OnClick", function(self)
				self:Disable()
				TSMAPI:CreateTimeDelay("gathervendor", 5, function() self:Enable() end)
				Vendor:BuyFromMerchant()
			end)
		buyButton:SetPoint("TOPLEFT", 70, 10)
		buyButton:SetPoint("TOPRIGHT", -40, 10)
		
		Vendor.merchantButton = buyButton
		
		local texture = "Interface\\TokenFrame\\UI-TokenFrame-CategoryButton"
		local offset = 6
		
		local normalTex = buyButton:CreateTexture()
		normalTex:SetTexture(texture)
		normalTex:SetPoint("TOPRIGHT", buyButton, "TOPRIGHT", -offset, -offset)
		normalTex:SetPoint("BOTTOMLEFT", buyButton, "BOTTOMLEFT", offset, offset)
		
		local disabledTex = buyButton:CreateTexture()
		disabledTex:SetTexture(texture)
		disabledTex:SetPoint("TOPRIGHT", buyButton, "TOPRIGHT", -offset, -offset)
		disabledTex:SetPoint("BOTTOMLEFT", buyButton, "BOTTOMLEFT", offset, offset)
		disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
		
		local highlightTex = buyButton:CreateTexture()
		highlightTex:SetTexture(texture)
		highlightTex:SetPoint("TOPRIGHT", buyButton, "TOPRIGHT", -offset, -offset)
		highlightTex:SetPoint("BOTTOMLEFT", buyButton, "BOTTOMLEFT", offset, offset)
		
		local pressedTex = buyButton:CreateTexture()
		pressedTex:SetTexture(texture)
		pressedTex:SetPoint("TOPRIGHT", buyButton, "TOPRIGHT", -offset, -offset)
		pressedTex:SetPoint("BOTTOMLEFT", buyButton, "BOTTOMLEFT", offset, offset)
		pressedTex:SetVertexColor(1, 1, 1, 0.5)
		normalTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		disabledTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		highlightTex:SetTexCoord(0.005, 0.994, 0.613, 0.785)
		highlightTex:SetVertexColor(0.3, 0.3, 0.3, 0.7)
		pressedTex:SetTexCoord(0.0256, 0.743, 0.017, 0.158)
		
		buyButton:SetPushedTextOffset(0, -3)
		buyButton:SetNormalTexture(normalTex)
		buyButton:SetDisabledTexture(disabledTex)
		buyButton:SetHighlightTexture(highlightTex)
		buyButton:SetPushedTexture(pressedTex)
	end
end

function Vendor:BuyFromMerchant()
	local shoppingList = select(2, TSM.Queue:GetMatsForQueue(modes))
	local matList = {}
	for _, data in pairs(shoppingList) do
		matList[data[1]] = data[2]
	end
	
	for i=1, GetMerchantNumItems() do
		local itemID = TSMAPI:GetItemID(GetMerchantItemLink(i))
		if matList[itemID] then
			local maxStack = GetMerchantItemMaxStack(i)
			local toBuy = matList[itemID]
			while toBuy > 0 do
				BuyMerchantItem(i, math.min(toBuy, maxStack))
				toBuy = toBuy - maxStack
			end
		end
	end
end


local vendorTrades = {
	[37101] = {itemID=79254, quantity=1}, -- Ivory Ink
	[39469] = {itemID=79254, quantity=1}, -- Moonglow Ink
	[39774] = {itemID=79254, quantity=1}, -- Midnight Ink
	[43116] = {itemID=79254, quantity=1}, -- Lion's Ink
	[43118] = {itemID=79254, quantity=1}, -- Jadefire Ink
	[43120] = {itemID=79254, quantity=1}, -- Celestial Ink
	[43122] = {itemID=79254, quantity=1}, -- Shimmering Ink
	[43124] = {itemID=79254, quantity=1}, -- Ethereal Ink
	[43126] = {itemID=79254, quantity=1}, -- Ink of the Sea
	[61978] = {itemID=79254, quantity=1}, -- Blackfallow Ink
	[43127] = {itemID=79254, quantity=10}, -- Snowfall Ink
	[61981] = {itemID=79254, quantity=10}, -- Inferno Ink
	[79255] = {itemID=79254, quantity=10}, -- Starlight Ink
}

function Vendor:GetItemVendorTrade(matID)
	if vendorTrades[matID] then
		return vendorTrades[matID].itemID, vendorTrades[matID].quantity
	end
end

local vendorMats = {[2320]=0.001, [2321]=0.001, [2324]=0.0025, [2325]=0.1, [2604]=0.005, [2605]=0.001, [2678]=0.001,
	[2880]=0.01, [3371]=0.01, [3466]=0.2, [4289]=0.005, [4291]=0.05, [4340]=0.035, [4341]=0.05, [4342]=0.25, [4399]=0.02,
	[4400]=0.2, [4470]=0.0038, [6260]=0.005, [6261]=0.01, [8343]=0.2, [10290]=0.25, [10647]=0.2, [10648]=0.01, [11291]=0.45,
	[14341]=0.5, [17020]=0.1, [17194]=0.001, [17196]=0.005, [30817]=0.0025, [34412]=0.1, [35949]=0.85, [38426]=3, [38682]=0.1,
	[39354]=0.0015, [39501]=0.12, [39502]=0.5, [39684]=0.9, [40533]=5, [44835]=0.001, [44853]=0.0025, [52188]=1.5, [58274]=1.1,
	[58278]=1.6, [62323]=6, [62786]=0.1, [62787]=0.1, [62788]=0.1, [67319]=32.8990, [67335]=44.5561, [67348]=39.4755, [68047]=17.0437
}

function Vendor:GetVendorPrice(itemID)
	return vendorMats[itemID] and floor(vendorMats[itemID]*COPPER_PER_GOLD)
end
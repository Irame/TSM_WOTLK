-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Crafting = TSM:GetModule("Crafting")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table


-- **************************************************************************
--										General Util Functions
-- **************************************************************************

function Crafting:GetCurrentTradeskill()
	local currentName = GetTradeSkillLine()
	for _, data in pairs(TSM.tradeSkills) do
		local professionName = GetSpellInfo(data.spellID)
		if professionName == currentName then
			return data.name
		end
	end
end

-- returns the Data.crafts table as a 2D array with a slot index (chants[slot][chant] instead of chants[chant])
function Crafting:GetDataByGroups(mode)
	local craftsByGroup = {}
	for itemID, data in pairs(TSM.Data[mode or TSM.mode].crafts) do
		if data.group then
			craftsByGroup[data.group] = craftsByGroup[data.group] or {}
			craftsByGroup[data.group][itemID] = CopyTable(data)
		end
	end
	
	return craftsByGroup
end


-- **************************************************************************
--										GUI Util Functions
-- **************************************************************************

-- adds a tooltip to the specified row
function Crafting:AddTooltip(row) -- updated
	local function ShowTooltip(row)
		if row.tooltip then
			GameTooltip:SetOwner(row, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(row.tooltip, nil, nil, nil, nil, true)
			GameTooltip:Show()
		elseif row.itemID then
			if row.button and row.button:IsVisible()  then
				GameTooltip:SetOwner(row.button, "ANCHOR_RIGHT")
			else
				GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			end
			
			local link = select(2, GetItemInfo(row.itemID))
			if link then
				GameTooltip:SetHyperlink(link)
			end
			
			if row.extraTooltip then
				GameTooltip:AddLine(YELLOW..row.extraTooltip, nil, nil, nil, true)
			end
			
			GameTooltip:Show()
		end
	end

	row:SetScript("OnEnter", ShowTooltip)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function Crafting:ApplyTexturesToButton(btn, isopenCloseButton)
	local texture = "Interface\\TokenFrame\\UI-TokenFrame-CategoryButton"
	local offset = 6
	if isopenCloseButton then
		offset = 5
		texture = "Interface\\Buttons\\UI-AttributeButton-Encourage-Hilight"
	end
	
	local normalTex = btn:CreateTexture()
	normalTex:SetTexture(texture)
	normalTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	normalTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	
	local disabledTex = btn:CreateTexture()
	disabledTex:SetTexture(texture)
	disabledTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	disabledTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
	
	local highlightTex = btn:CreateTexture()
	highlightTex:SetTexture(texture)
	highlightTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	highlightTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	
	local pressedTex = btn:CreateTexture()
	pressedTex:SetTexture(texture)
	pressedTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	pressedTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	pressedTex:SetVertexColor(1, 1, 1, 0.5)
	
	if isopenCloseButton then
		normalTex:SetTexCoord(0.041, 0.975, 0.129, 1.00)
		disabledTex:SetTexCoord(0.049, 0.931, 0.008, 0.121)
		highlightTex:SetTexCoord(0, 1, 0, 1)
		highlightTex:SetVertexColor(0.9, 0.9, 0.9, 0.9)
		pressedTex:SetTexCoord(0.035, 0.981, 0.014, 0.670)
	btn:SetPushedTextOffset(0, -1)
	else
		normalTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		disabledTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		highlightTex:SetTexCoord(0.005, 0.994, 0.613, 0.785)
		highlightTex:SetVertexColor(0.3, 0.3, 0.3, 0.7)
		pressedTex:SetTexCoord(0.0256, 0.743, 0.017, 0.158)
	btn:SetPushedTextOffset(0, -3)
	end
	
	btn:SetNormalTexture(normalTex)
	btn:SetDisabledTexture(disabledTex)
	btn:SetHighlightTexture(highlightTex)
	btn:SetPushedTexture(pressedTex)
end

function Crafting:CreateButton(parent, text, fontObject, fontSize, buttonName, inheritsFrame) -- updated
	local btn = CreateFrame("Button", buttonName, parent, inheritsFrame or "UIPanelButtonTemplate")
	btn:SetText(text)
	btn:GetFontString():SetPoint("CENTER")
	local tFile, tSize = fontObject:GetFont()
	btn:GetFontString():SetFont(tFile, tSize + fontSize, "OUTLINE")
	return btn
end

function Crafting:CreateWhiteButton(parent, height, text, fontSize, buttonName, inheritsFrame) -- updated
	local btn = Crafting:CreateButton(parent, text, SubZoneTextFont, fontSize + 6, buttonName, inheritsFrame)
	btn:GetFontString():SetTextColor(1, 1, 1, 1)
	btn:SetPushedTextOffset(0, 0)
	btn:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = height > 29 and 24 or 18,
		insets = {left = 2, right = 2, top = 4, bottom = 4},
	})
	btn:SetHeight(height)
	btn:SetScript("OnDisable", function(self) self:GetFontString():SetTextColor(0.5, 0.5, 0.5, 1) end)
	btn:SetScript("OnEnable", function(self) self:GetFontString():SetTextColor(1, 1, 1, 1) end)
	Crafting:ApplyTexturesToButton(btn)	
	return btn
end


-- **************************************************************************
--										Filter Util Functions
-- **************************************************************************

-- removes all filters from the current tradeskill
function Crafting:RemoveAllFilters()
	SetTradeSkillSubClassFilter(0, 1, 1)
	SetTradeSkillInvSlotFilter(0, 1, 1)
	if TradeSkillFrameEditBox then
		TradeSkillFrameEditBox:SetText("")
	end
	if TradeSkillFrameAvailableFilterCheckButton:GetChecked() then
		TradeSkillFrameAvailableFilterCheckButton:Click()
	end
	for i=GetNumTradeSkills(), 1, -1 do
		local _, sType, _, isExpanded = GetTradeSkillInfo(i)
		if sType == "header" and not isExpanded then
			ExpandTradeSkillSubClass(i)
		end
	end
end

function Crafting:IsFilterSet()
	if not GetTradeSkillSubClassFilter(0) or not GetTradeSkillInvSlotFilter(0) or TradeSkillFrameAvailableFilterCheckButton:GetChecked() then
		return true
	end

	local searchText = TradeSkillFrameEditBox:GetText()
	if searchText ~= "" and searchText ~= " " and searchText ~= SEARCH then
		return true
	end
	
	for i=GetNumTradeSkills(), 1, -1 do
		local _, sType, _, isExpanded = GetTradeSkillInfo(i)
		if sType == "header" and not isExpanded then
			return true
		end
	end
end


-- **************************************************************************
--										Queue Util Functions
-- **************************************************************************

function Crafting:GetQueueItemOrder(item, itemID)
	if TSM.db.global.queueSort == "buyout" then
		return TSM:GetItemMarketPrice(itemID, "craft") or math.huge
	elseif TSM.db.global.queueSort == "quantity" then
		return TSM.Data:GetTotalQuantity(itemID)
	elseif TSM.db.global.queueSort == "name" then
		return item.name
	elseif TSM.db.global.queueSort == "profitPercent" then
		local _, buyout, profit = TSM.Data:GetCraftPrices(itemID, Crafting.mode)
		if profit and buyout then
			return TSMAPI:SafeDivide(profit, buyout)
		else
			return math.huge
		end
	else -- sort by profit
		return TSM.Data:GetCraftProfit(itemID, Crafting.mode) or math.huge
	end
end

-- gets information that's used to determine where this craft goes in the queue
local matLookup = {}
local function UpdateMatLookup(mode)
	for itemID, eData in pairs(TSM.Data[mode].crafts) do
		matLookup[eData.spellID] = eData.mats
	end
end
function Crafting:GetOrderIndex(mode, data, usedMats)
	usedMats = usedMats or {}
	if not matLookup[data.spellID] then
		UpdateMatLookup(mode)
	end
	local mats = matLookup[data.spellID]
	local needEssence = 0
	local essenceID = 0
	local haveMats = nil
	local partial = true
	if not mats then return end
	for itemID, nQuantity in pairs(mats) do
		local numHave = TSM.Data:GetPlayerNum(itemID) - (usedMats[itemID] or 0)
		local numHaveTotal = TSM.Data:GetPlayerNum(itemID, true)
		local need = nQuantity * data.quantity
		
		-- usedMats[itemId] == -1 means that this item is a vendor item
 		-- and the user has chosen to assume that they have this in their
 		-- bags, or can get it, when building an on-hand queue
 		if usedMats[itemID] == -1 then
 			numHave = need
 		end
		
		local equivItemID, ratio = TSM:GetEquivItem(itemID)
		if equivItemID and need > numHave then -- there is an equiv item (eternal / essence)
			local diff = need - numHave
			local numEquiv = (TSM.Data:GetPlayerNum(equivItemID) - (usedMats[equivItemID] or 0)) / ratio
			if numEquiv >= diff then
				numHave = need
				needEssence = ceil(diff * ratio)
				essenceID = equivItemID
			end
		end
		
		if numHave < need then
			if not haveMats or haveMats == 3 then
				if numHaveTotal > need then
					haveMats = 2
				else
					haveMats = 1
				end
			end
			if haveMats == 2 and numHaveTotal < need then
				haveMats = 1
			end
		else
			if not haveMats then
				haveMats = 3
			end
		end
		
		if numHave < nQuantity then
			partial = false
		end
	end
	return haveMats, needEssence, essenceID, partial
end
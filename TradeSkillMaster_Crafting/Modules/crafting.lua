-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- create a local reference to the TradeSkillMaster_Crafting table and register a new module
local TSM = select(2, ...)
local Crafting = TSM:NewModule("Crafting", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table

-- intialize some internal-global variables
local ROW_HEIGHT_CRAFTING = 16
local ROW_HEIGHT_SHOPPING = 12
local ROW_HEIGHT_QUEUING = 12
local MAX_ROWS_CRAFTING = 16
local MAX_ROWS_SHOPPING = 12
local MAX_ROWS_QUEUING = 20
local FRAME_HEIGHT = 500
local FRAME_WIDTH = 870

-- color codes
local GREEN = "|cff00ff00"
local RED = "|cffff0000"
local WHITE = "|cffffffff"
local GOLD = "|cffffbb00"
local YELLOW = "|cffffd000"

local groupShown = {}

Crafting.isCrafting = 0

function Crafting:OnInitialize()
	-- add hook for ATSW addon if necessary
	if select(4, GetAddOnInfo("AdvancedTradeSkillWindow")) == 1 then
		local oldShow = ATSW_ShowWindow
		ATSW_ShowWindow = function()
				oldShow()
				Crafting:PrepareFrame()
				Crafting.mode = Crafting.mode or Crafting:GetCurrentTradeskill()
			end
	end
	
	Crafting:RegisterEvent("TRADE_SKILL_SHOW")
	Crafting:RegisterEvent("TRADE_SKILL_CLOSE")
end

-- opens the crafting window
function Crafting:OpenCrafting(nextFunc, mode)
	local forcedMode = mode and true
	mode = mode or TSM.mode
	CloseTradeSkill()
	for _, data in ipairs(TSM.tradeSkills) do
		if data.name == mode then
			local spellName = GetSpellInfo(data.spellID)
			Crafting.nextFunc = nextFunc
			if not TSM[mode]:HasProfession() then
				Crafting.mode = forcedMode and mode or Crafting:GetCurrentTradeskill() or mode
				Crafting:PrepareFrame()
			else
				CastSpellByName(spellName) -- opens the profession
			end
			break
		end
	end
end

-- opens the tradeskill frame and then the crafting window
function Crafting:OpenFrame(mode)
	Crafting:OpenCrafting(Crafting.PrepareFrame, mode)
end
	
function Crafting:PrepareFrame(hide)
	Crafting:ShowFrame(hide and Crafting.frame and hide == "hide")
	
	local toHide = (hide and Crafting.frame and hide == "hide")
	if toHide then Crafting.frame:Hide() end
	Crafting.openCloseButton:Show()
	
	-- register events and collect some data
	Crafting.isCrafting = 0
	Crafting:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Crafting:RegisterEvent("UNIT_SPELLCAST_FAILED")
	Crafting:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	Crafting:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	Crafting:RegisterEvent("BAG_UPDATE")
	Crafting.frame.text:SetText("Crafting ("..TSM.version..") - "..(Crafting.mode or ""))
	Crafting.frame.titleBackground:SetWidth(Crafting.frame.text:GetWidth()+10)
	
	-- update the frame for the first time and then show it
	if not toHide then
		Crafting:RegisterEvent("TRADE_SKILL_UPDATE")
		Crafting:UpdateShopping()
		Crafting:UpdateQueuing()
		TSMAPI:CreateTimeDelay("updateCraftingOnOpen", 0.2, function()
				TSM.Queue:UpdateQueue(Crafting.mode)
				Crafting:UpdateCrafting()
			end)
	end
	
	-- update profession icon highlights
	for _, icon in ipairs(Crafting.frame.professionBar.icons) do
		if icon.mode == Crafting.mode then
			icon:LockHighlight()
		else
			icon:UnlockHighlight()
		end
	end
end

function Crafting:UpdateAllScrollFrames()
	TSM.Queue:UpdateQueue(Crafting.mode)
	Crafting:UpdateCrafting()
	Crafting:UpdateShopping()
	Crafting:UpdateQueuing()
end

-- initializes the craft queue frame when it is shown for the first time
function Crafting:ShowFrame(hidden)
	if not Crafting.frame then
		Crafting:CreateCraftMangementWindow()
		hidden = true
	end
	
	local tsframe, ofsx, ofsy, bofsx, bofsy = Crafting:GetTradeSkillFrameAndOffsets()
	if not tsframe then return end
	local openCloseStrata, openCloseLevel = "HIGH", 30
	
	Crafting.openCloseButton:ClearAllPoints()
	Crafting.frame:ClearAllPoints()
	if Crafting.mode and TSM[Crafting.mode]:HasProfession() then
		Crafting.frame.craftingScroll:Show()
		if Crafting.craftNextButton then
			Crafting.craftNextButton:Show()
		end
		Crafting.frame:SetParent(UIParent)
		Crafting.frame:SetPoint("TOPLEFT", tsframe, "TOPLEFT", ofsx, ofsy)
		Crafting.openCloseButton:SetParent(tsframe)
		Crafting.openCloseButton:SetPoint("TOPLEFT", tsframe, "TOPLEFT", bofsx, bofsy)
		openCloseStrata = tsframe:GetFrameStrata() or openCloseStrata
		openCloseLevel = tsframe:GetFrameLevel() or openCloseLevel
		if not Crafting.horribleHackVar then
			Crafting.horribleHackVar = false
			Crafting.openCloseButton:ClearAllPoints()
			Crafting.openCloseButton:SetPoint("BOTTOMRIGHT", Crafting.frame, "TOPRIGHT", 0, 2)
			Crafting.openCloseButton:SetScale(TSM.db.profile.craftManagementWindowScale)
		end
	else
		Crafting.frame.craftingScroll:Hide()
		if Crafting.craftNextButton then
			Crafting.craftNextButton:Hide()
		end
		Crafting.frame:SetParent(UIParent)
		Crafting.frame:SetPoint("CENTER", UIParent, "CENTER", -100, 100)
		openCloseStrata = Crafting.frame:GetFrameStrata() or openCloseStrata
		openCloseLevel = Crafting.frame:GetFrameLevel() or openCloseLevel
		Crafting.openCloseButton:SetParent(Crafting.frame)
		Crafting.openCloseButton:SetScale(TSM.db.profile.craftManagementWindowScale)
		Crafting.openCloseButton:SetPoint("BOTTOMRIGHT", Crafting.frame, "TOPRIGHT", 0, 2)
	end
	Crafting.openCloseButton:SetHeight(25)
	Crafting.openCloseButton:SetWidth(250)
	Crafting.openCloseButton:SetFrameStrata(openCloseStrata)
	Crafting.openCloseButton:SetFrameLevel(openCloseLevel+1)
	Crafting.frame:SetWidth(FRAME_WIDTH)
	Crafting.frame:SetHeight(FRAME_HEIGHT)
	Crafting.frame:SetScale(TSM.db.profile.craftManagementWindowScale)
	Crafting.frame:SetFrameStrata("High")
	Crafting.frame:Show()
end

function Crafting:GetTradeSkillFrameAndOffsets() -- updated
	local tsframe, ofsx, ofsy, bofsx, bofsy
	if ATSWFrame then
		tsframe, ofsx, ofsy = ATSWFrame, 50, -10
		bofsx, bofsy = 0, 12
	elseif SkilletFrame then
		tsframe, ofsx, ofsy = SkilletFrame, 50, 0
		bofsx, bofsy = 0, 12
	elseif GnomeWorks then
		tsframe, ofsx, ofsy = GnomeWorks:GetMainFrame(), 50, 0
		bofsx, bofsy = 0, 12
	elseif TradeSkillFrame then
		tsframe, ofsx, ofsy = TradeSkillFrame, 50, 9
		bofsx, bofsy = 53, 20
	else
		tsframe, ofsx, ofsy = UIParent, 30, -30
		bofsx, bofsy = 33, -19
	end
	return tsframe, ofsx, ofsy, bofsx, bofsy
end

function Crafting:CreateCraftMangementWindow() -- updated
	Crafting:CreateCraftingFrame() -- creates the frame itself along with the open/close button and sidebar
	Crafting:CreateFrameTitle() -- creates background for the title text at the top of the window
	Crafting:CreateCraftingDisabledMessage() -- create the message that shows up when the craft queue is disabled
	Crafting:CreateTotalGoldText() -- creates the total gold text
	Crafting:CreateCraftingRegion() -- create the "crafting" region of the craft management window
	Crafting:CreateButtons() -- create all the buttons that go in the frame: "Craft Next", "Restock Queue", "On-Hand Queue", "Clear Queue", "Remove Filters"
	Crafting:CreateBars() -- create all the dividing bars
	Crafting:CreateShoppingRegion() -- create the "shopping" region of the craft management window
	Crafting:CreateQueuingRegion() -- create the "queuing" region of the craft management window
end

function Crafting:CreateCraftingFrame() -- updated
	local tsframe, ofsx, ofsy, bofsx, bofsy = Crafting:GetTradeSkillFrameAndOffsets()
	
	
	-- Open/Close button for the frame
	local btn = Crafting:CreateButton(tsframe, L["Close TradeSkillMaster_Crafting"], GameFontHighlight, 0)
	btn:SetHeight(25)
	btn:SetWidth(250)
	btn:SetPoint("TOPLEFT", tsframe, "TOPLEFT", bofsx, bofsy)
	btn:SetScript("OnClick", function(self)
		if Crafting.frame:IsVisible() then
			Crafting.frame:Hide()
			Crafting:TRADE_SKILL_CLOSE(Crafting.mode)
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", tsframe, "TOPLEFT", bofsx, bofsy)
			btn:SetHeight(25)
			btn:SetWidth(250)
		else
			TSM.Crafting:OpenFrame(Crafting:GetCurrentTradeskill())
			self:ClearAllPoints()
			self:SetPoint("BOTTOMRIGHT", Crafting.frame, "TOPRIGHT", 0, 2)
			btn:SetHeight(25)
			btn:SetWidth(250)
		end
	end)
	btn:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 18,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	Crafting:ApplyTexturesToButton(btn, true)
	Crafting.openCloseButton = btn
	
	
	-- Craft Management Window
	local frame = CreateFrame("Frame", "TSMCraftingFrame", UIParent)
	frame:SetWidth(FRAME_WIDTH)
	frame:SetHeight(FRAME_HEIGHT)
	frame:SetPoint("TOPLEFT", tsframe, "TOPLEFT", ofsx, ofsy)
	frame:SetFrameStrata("High")
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseDown", frame.StartMoving)
	frame:SetScript("OnMouseUp", frame.StopMovingOrSizing)
	frame:SetScript("OnShow", function() Crafting.openCloseButton:SetText(L["Close TradeSkillMaster_Crafting"]) end)
	frame:SetScript("OnHide", function() Crafting:UnregisterEvent("BAG_UPDATE") Crafting.openCloseButton:SetText(L["Open TradeSkillMaster_Crafting"]) end)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 24,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	frame:SetBackdropColor(0, 0, .05, 1)
	frame:SetBackdropBorderColor(0, 0, 1, 1)
	tinsert(UISpecialFrames, frame:GetName())
	Crafting.frame = frame
	
	
	-- sidebar from that has an icon for each profession for quickly changing between professions
	local sideFrame = CreateFrame("Frame", nil, frame)
	sideFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 20,
		insets = {left = 4, right = 1, top = 4, bottom = 4},
	})
	sideFrame:SetBackdropColor(0, 0, .05, 1)
	sideFrame:SetBackdropBorderColor(0, 0, 1, 1)
	sideFrame:EnableMouse(true)
	sideFrame:SetFrameLevel(1)
	sideFrame:SetWidth(60)
	sideFrame:SetPoint("TOPRIGHT", frame, "TOPLEFT", 8, -10)
	sideFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 8, 10)
	sideFrame.icons = {}
	
	local modes, lnames, textures = {}, {}, {}
	for _, data in ipairs(TSM.tradeSkills) do
		local name, _, texture = GetSpellInfo(data.spellID)
		tinsert(modes, data.name)
		tinsert(lnames, name)
		tinsert(textures, texture)
	end
	
	local numItems = #TSM.tradeSkills
	local count = 0
	local spacing = min(TSMAPI:SafeDivide(sideFrame:GetHeight() - 10, numItems), 200)

	for i=1, numItems do
		local iframe = CreateFrame("Button", nil, sideFrame)
		iframe:SetScript("OnClick", function()
				Crafting:OpenFrame(modes[i])
			end)
		iframe:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT", -5, -20)
				GameTooltip:SetText(lnames[i])
				GameTooltip:Show()
			end)
		iframe:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

		local image = iframe:CreateTexture(nil, "BACKGROUND")
		image:SetWidth(40)
		image:SetHeight(40)
		image:SetPoint("TOP")
		iframe.image = image

		local highlight = iframe:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints(image)
		highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
		highlight:SetTexCoord(0, 1, 0.23, 0.77)
		highlight:SetBlendMode("ADD")
		iframe.highlight = highlight
		
		iframe:SetHeight(40)
		iframe:SetWidth(40)
		iframe.image:SetTexture(textures[i])
		iframe.image:SetVertexColor(1, 1, 1)
		
		sideFrame.icons[i] = iframe
		
		count = count + 1
		iframe:SetPoint("BOTTOMLEFT", sideFrame, "TOPLEFT", 10, -((count-1)*spacing)-50)
		iframe.mode = modes[i]
	end
	frame.professionBar = sideFrame
end

function Crafting:CreateFrameTitle() -- updated
	local titlebg = CreateFrame("Frame", nil, Crafting.frame)
	titlebg:EnableMouse(true)
	titlebg:SetScript("OnMouseDown", function(self) self:GetParent():StartMoving() end)
	titlebg:SetScript("OnMouseUp", function(self) self:GetParent():StopMovingOrSizing() end)
	titlebg:SetWidth(360)
	titlebg:SetHeight(30)
	titlebg:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2},
	})
	titlebg:SetBackdropColor(0, 0, .05, 1)
	titlebg:SetBackdropBorderColor(0, 0, 1, 1)
	titlebg:SetPoint("TOP", 0, 28)
	Crafting.frame.titleBackground = titlebg
	
	-- Tittle frame which contains the tittle text
	local tFile, tSize = GameFontNormalLarge:GetFont()
	local titleText = Crafting.frame.titleBackground:CreateFontString(nil, "Overlay", "GameFontNormalLarge")
	titleText:SetFont(tFile, tSize, "OUTLINE")
	titleText:SetTextColor(1, 1, 1, 1)
	titleText:SetPoint("CENTER", Crafting.frame.titleBackground, "CENTER", 0, 0)
	titleText:SetText("Crafting ("..TSM.version..") - ")
	Crafting.frame.text = titleText
end

function Crafting:CreateCraftingRegion() -- updated
	-- scroll frame
	local scrollFrame = CreateFrame("ScrollFrame", "TSMCraftingScrollCrafting", Crafting.frame, "FauxScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", Crafting.frame, "TOPRIGHT", -330, -166)
	scrollFrame:SetPoint("BOTTOMRIGHT", Crafting.frame, "BOTTOMRIGHT", -30, 46)
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT_CRAFTING, Crafting.UpdateCrafting) 
	end)
	Crafting.frame.craftingScroll = scrollFrame

	
	-- rows
	-- rows of the scrollframe containing the crafts in the queue
	-- each row is the clickable name of a craft (we set up the script to craft the craft later)
	local craftRows = {}
	for count=1, MAX_ROWS_CRAFTING do
		local row = CreateFrame("Frame", nil, Crafting.frame)
		row:SetHeight(ROW_HEIGHT_CRAFTING)
		
		row.UpdateState = function(self)
			if self.isTitle then
				self.button:SetText(format(L["<Crafting Stage #%s>"], self.stageNum))
				self.button:Disable()
			else
				self.button:Enable()
			end
		end
		
		local button = CreateFrame("Button", nil, row, "SecureActionButtonTemplate")
		button:SetHeight(ROW_HEIGHT_CRAFTING)
		button:SetPoint("LEFT")
		button:SetPoint("RIGHT")
		button:SetNormalFontObject(GameFontHighlight)
		button:SetText("*")
		button:GetFontString():SetPoint("LEFT", 0, 0)
		button:SetPushedTextOffset(0, 0)
		button:SetAttribute("type", "macro")
		button:SetScript("PostClick", function(self)
				Crafting.isCrafting = self.data.quantity
				Crafting.craftNextButton:Disable()
			end)
		button:SetScript("OnEnter", function(self)
				if not self.data then return end
				GameTooltip:SetOwner(self, "ANCHOR_NONE")
				GameTooltip:SetPoint("LEFT", self, "RIGHT")
				GameTooltip:AddLine(self.data.name)
				for itemID, nQuantity in pairs(TSM.Data[Crafting.mode].crafts[self.data.itemID].mats) do
					local name = GetItemInfo(itemID) or (TSM.Data[Crafting.mode].crafts[itemID] and TSM.Data[Crafting.mode].crafts[itemID].name) or "?"
					local inventory = TSM.Data:GetPlayerNum(itemID)
					local need = nQuantity * self.data.quantity
					local color
					if inventory >= need then color = "|cff00ff00" else color = "|cffff0000" end
					name = color .. inventory .. "/" .. need .. "|r " .. name
					GameTooltip:AddLine(name)
				end
				GameTooltip:Show()
			end)
		button:SetScript("OnLeave", function()
				GameTooltip:ClearLines()
				GameTooltip:Hide()
			end)
		button:Show()
		row.button = button
		
		if count > 1 then
			row:SetPoint("TOPLEFT", craftRows[count - 1], "BOTTOMLEFT", 0, -2)
			row:SetPoint("TOPRIGHT", Crafting.frame.craftingScroll, "BOTTOMRIGHT", 0, -2)
		else
			row:SetPoint("TOPLEFT", Crafting.frame.craftingScroll, "TOPLEFT", 0, 0)
			row:SetPoint("TOPRIGHT", Crafting.frame.craftingScroll, "TOPRIGHT", -12, 0)
		end
		
		craftRows[count] = row
	end
	Crafting.craftRows = craftRows
end

function Crafting:CreateCraftingDisabledMessage() -- updated
	local frame = CreateFrame("Frame", nil, Crafting.frame)
	frame:SetWidth(280)
	frame:SetHeight(100)
	frame:SetPoint("BOTTOMRIGHT", -40, 150)
	frame:SetScript("OnShow", function()
			if not Crafting.craftNextButton then return end
			Crafting.craftNextButton:Hide()
			Crafting.frame.craftingScroll:Hide()
		end)
	
	local tFile, tSize = GameFontNormalLarge:GetFont()
	local text = frame:CreateFontString(nil, "Overlay", "GameFontNormalLarge")
	text:SetFont(tFile, tSize-4, "OUTLINE")
	text:SetTextColor(1, 1, 1, 1)
	text:SetWidth(280)
	text:SetPoint("TOP")
	text:SetText("")
	frame.text = text
	
	local delayFrame = CreateFrame("Frame")
	delayFrame:Hide()
	delayFrame:RegisterEvent("TRADE_SKILL_SHOW")
	delayFrame:SetScript("OnEvent", function(self)
			self.timeLeft = 0.1
		end)
	delayFrame:SetScript("OnUpdate", function(self, elapsed)
			if self.timeLeft then
				self.timeLeft = self.timeLeft - elapsed
				if self.timeLeft <= 0 then
					self:Hide()
					self:UnregisterAllEvents()
					Crafting.openCloseButton:SetParent(Crafting:GetTradeSkillFrameAndOffsets())
					Crafting:RegisterEvent("TRADE_SKILL_SHOW")
					TSM.Queue:UpdateQueue(Crafting.mode)
					Crafting:UpdateCrafting()
				end
			end
		end)
	
	local btn = Crafting:CreateWhiteButton(frame, 30, "", -20)
	btn:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 50, 0)
	btn:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -50, 0)
	btn:Hide()
	btn:SetScript("OnClick", function()
			delayFrame:Show()
			Crafting:UnregisterEvent("TRADE_SKILL_SHOW")
			for _, data in ipairs(TSM.tradeSkills) do
				if Crafting.mode == data.name then
					local name = GetSpellInfo(data.spellID)
					CastSpellByName(name)
					Crafting.isCrafting = 0
					Crafting:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
					Crafting:RegisterEvent("UNIT_SPELLCAST_FAILED")
					Crafting:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
					Crafting:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
					Crafting:RegisterEvent("BAG_UPDATE")
					break
				end
			end
		end)
	frame.button = btn
	Crafting.frame.noCrafting = frame
end

function Crafting:CreateButtons() -- updated
	local btn = Crafting:CreateWhiteButton(Crafting.frame, 40, L["Craft Next"], -16, "TSMCraftNextButton", "SecureActionButtonTemplate")
	btn:SetPoint("TOPLEFT", Crafting.frame.craftingScroll, "BOTTOMLEFT", -6, -2)
	btn:SetPoint("TOPRIGHT", Crafting.frame.craftingScroll, "BOTTOMRIGHT", 25, -2)
	Crafting.craftNextButton = btn
	
	local btn = Crafting:CreateWhiteButton(Crafting.frame, 45, L["Restock Queue"], 0)
	btn:SetPoint("TOPLEFT", Crafting.frame, "TOPLEFT", FRAME_WIDTH-330, -20)
	btn:SetPoint("TOPRIGHT", Crafting.frame, "TOPRIGHT", -6, -20)
	btn:SetScript("OnClick", function() TSM.Queue:CreateRestockQueue() Crafting:UpdateAllScrollFrames() end)
	Crafting.restockQueueButton = btn

	local btn = Crafting:CreateWhiteButton(Crafting.frame, 30, L["On-Hand Queue"], -20)
	btn:SetPoint("TOPLEFT", Crafting.frame, "TOPLEFT", FRAME_WIDTH-330, -65)
	btn:SetPoint("TOPRIGHT", Crafting.frame, "TOPRIGHT", -164, -65)
	btn:SetScript("OnClick", function() TSM.Queue:CreateOnHandQueue() Crafting:UpdateAllScrollFrames() end)
	Crafting.onHandQueueButton = btn

	local btn = Crafting:CreateWhiteButton(Crafting.frame, 30, L["Clear Queue"], -20)
	btn:SetPoint("TOPLEFT", Crafting.frame, "TOPLEFT", FRAME_WIDTH-168, -65)
	btn:SetPoint("TOPRIGHT", Crafting.frame, "TOPRIGHT", -6, -65)
	btn:SetScript("OnClick", function() TSM.Queue:ClearQueue() Crafting:UpdateAllScrollFrames() end)
	Crafting.clearQueueButton = btn
	
	local btn = Crafting:CreateWhiteButton(Crafting.frame, 25, L["Clear Tradeskill Filters"], -20)
	btn:SetPoint("TOPLEFT", Crafting.frame, "TOPLEFT", FRAME_WIDTH-330, -135)
	btn:SetPoint("TOPRIGHT", Crafting.frame, "TOPRIGHT", -6, -135)
	btn:SetScript("OnClick", Crafting.RemoveAllFilters)
	Crafting.clearFilterButton = btn
end

function Crafting:CreateBars() -- updated
	Crafting.frame.verticalBarFrame = TSMAPI:GetGUIFunctions():AddVerticalBar(Crafting.frame, FRAME_WIDTH-340, nil, true)
	Crafting.frame.verticalBarFrame:SetWidth(8)
	
	local horizontalBar = TSMAPI:GetGUIFunctions():AddHorizontalBar(Crafting.frame, 0, nil, true)
	horizontalBar:ClearAllPoints()
	horizontalBar:SetPoint("BOTTOMLEFT", Crafting.frame.craftingScroll, "TOPLEFT", -5, 0)
	horizontalBar:SetPoint("BOTTOMRIGHT", Crafting.frame.craftingScroll, "TOPRIGHT", 26, 0)
	horizontalBar:SetHeight(6)
	Crafting.frame.horizontalBarFrame = horizontalBar

	local horizontalBar2 = TSMAPI:GetGUIFunctions():AddHorizontalBar(Crafting.frame, 0, nil, true)
	horizontalBar2:ClearAllPoints()
	horizontalBar2:SetPoint("TOPLEFT", Crafting.frame, "TOPLEFT", 4, -300)
	horizontalBar2:SetPoint("TOPRIGHT", Crafting.frame.verticalBarFrame, "TOPRIGHT", -4, -311)
	horizontalBar2:SetHeight(6)
	Crafting.frame.horizontalBarFrame2 = horizontalBar2
end

function Crafting:CreateTotalGoldText() -- updated
	local frame = CreateFrame("Frame", nil, Crafting.frame)
	frame:SetPoint("TOPRIGHT", -6, -100)
	frame:SetPoint("BOTTOMLEFT", Crafting.frame, "TOPRIGHT", -330, -140)
	
	local tFile, tSize = GameFontNormalLarge:GetFont()
	local text = frame:CreateFontString(nil, "Overlay", "GameFontNormalLarge")
	text:SetFont(tFile, tSize-4, "OUTLINE")
	text:SetTextColor(1, 1, 1, 1)
	text:SetPoint("TOPLEFT")
	text:SetPoint("TOPRIGHT")
	text:SetJustifyH("LEFT")
	text:SetText("")
	text.UpdateGoldAmount = function(self, amount) self:SetText(L["Estimated Total Mat Cost:"].." "..(TSM:FormatTextMoney(amount) or "---")) end
	frame.matTotal = text
	
	local text2 = frame:CreateFontString(nil, "Overlay", "GameFontNormalLarge")
	text2:SetFont(tFile, tSize-4, "OUTLINE")
	text2:SetTextColor(1, 1, 1, 1)
	text2:SetPoint("TOPLEFT", frame, "LEFT")
	text2:SetPoint("TOPRIGHT", frame, "RIGHT")
	text2:SetJustifyH("LEFT")
	text2:SetText("")
	text2.UpdateGoldAmount = function(self, amount) self:SetText(L["Estimated Total Profit:"].." "..(TSM:FormatTextMoney(amount) or "---")) end
	frame.profitTotal = text2
	Crafting.totalGoldFrame = frame
end

function Crafting:CreateShoppingRegion() -- updated
	-- scroll frame
	local shoppingScrollFrame = CreateFrame("ScrollFrame", "TSMCraftingScrollShopping", Crafting.frame, "FauxScrollFrameTemplate")
	shoppingScrollFrame:SetPoint("TOPLEFT", Crafting.frame.horizontalBarFrame2, "TOPLEFT", 4, -24)
	shoppingScrollFrame:SetPoint("BOTTOMRIGHT", Crafting.frame.verticalBarFrame, "BOTTOMLEFT", -21, 2)
	shoppingScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT_SHOPPING, Crafting.UpdateShopping) 
		end)
	Crafting.frame.shoppingScroll = shoppingScrollFrame
	
	
	-- title row
	local row = CreateFrame("Button", nil, Crafting.frame)
	row:SetHeight(14)
	row:SetPoint("TOPLEFT", shoppingScrollFrame, "TOPLEFT", 0, 18)
	row:SetPoint("TOPRIGHT", shoppingScrollFrame, "TOPRIGHT", 0, 18)
	
	local function AddLabel(text, x1, x2)
		local fontString = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		fontString:SetText(text)
		fontString:SetPoint("TOPLEFT", row, "TOPLEFT", x1, 0)
		if x2 then
			fontString:SetPoint("TOPRIGHT", row, "TOPLEFT", x2, 0)
		else
			fontString:SetPoint("TOPRIGHT")
		end
		fontString:SetJustifyH("Left")
		fontString:SetJustifyV("TOP")
	end
	
	row.name = AddLabel(L["Name"], 50, 170)
	row.need = AddLabel(L["Need"], 180, 230)
	row.bags = AddLabel(L["In Bags"], 240, 290)
	row.total = AddLabel(L["Total"], 290, 335)
	row.value = AddLabel(L["Cost"], 340, 380)
	row.source = AddLabel(L["Price Source"], 410)
	
	row.bar = row:CreateTexture()
	row.bar:SetPoint("BOTTOMLEFT", shoppingScrollFrame, "TOPLEFT")
	row.bar:SetPoint("BOTTOMRIGHT", shoppingScrollFrame, "BOTTOMRIGHT", 24, 0)
	row.bar:SetHeight(4)
	row.bar:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	row.bar:SetTexCoord(0.577, 0.683, 0.145, 0.309)
	row.bar:SetVertexColor(0, 0, 0.7, 0.5)
	shoppingScrollFrame.titleRow = row
	
	
	-- rows
	local shoppingRows = {}
	for count=1, MAX_ROWS_SHOPPING do
		local row = CreateFrame("Button", nil, Crafting.frame, "SecureActionButtonTemplate")
		row:SetHeight(ROW_HEIGHT_SHOPPING)
		row:SetScript("OnClick", function(self) SetItemRef("item:" .. self.itemID, self.itemID) end)
		Crafting:AddTooltip(row)
		
		if count > 1 then
			row:SetPoint("TOPLEFT", shoppingRows[count - 1], "BOTTOMLEFT", 0, -2)
			row:SetPoint("TOPRIGHT", shoppingScrollFrame, "BOTTOMRIGHT", 0, -2)
		else
			row:SetPoint("TOPLEFT", shoppingScrollFrame, "TOPLEFT", 0, 0)
			row:SetPoint("TOPRIGHT", shoppingScrollFrame, "TOPRIGHT", -12, 0)
		end
		
		row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		row.name:SetTextColor(1, 1, 1, 1)
		row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
		row.name:SetPoint("TOPRIGHT", row, "TOPLEFT", 188, 0)
		row.name:SetJustifyH("Left")
		row.name:SetJustifyV("TOP")
		
		row.need = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		row.need:SetTextColor(1, 1, 1, 1)
		row.need:SetPoint("TOPLEFT", row, "TOPLEFT", 190, 0)
		row.need:SetPoint("TOPRIGHT", row, "TOPLEFT", 238, 0)
		row.need:SetJustifyH("Left")
		row.need:SetJustifyV("TOP")
		
		row.bags = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		row.bags:SetTextColor(1, 1, 1, 1)
		row.bags:SetPoint("TOPLEFT", row, "TOPLEFT", 240, 0)
		row.bags:SetPoint("TOPRIGHT", row, "TOPLEFT", 288, 0)
		row.bags:SetJustifyH("Left")
		row.bags:SetJustifyV("TOP")
		
		row.total = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		row.total:SetTextColor(1, 1, 1, 1)
		row.total:SetPoint("TOPLEFT", row, "TOPLEFT", 290, 0)
		row.total:SetPoint("TOPRIGHT", row, "TOPLEFT", 338, 0)
		row.total:SetJustifyH("Left")
		row.total:SetJustifyV("TOP")
		
		row.value = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		row.value:SetTextColor(1, 1, 1, 1)
		row.value:SetPoint("TOPLEFT", row, "TOPLEFT", 340, 0)
		row.value:SetPoint("TOPRIGHT", row, "TOPLEFT", 403, 0)
		row.value:SetJustifyH("Left")
		row.value:SetJustifyV("TOP")
		
		row.source = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		row.source:SetTextColor(1, 1, 1, 1)
		row.source:SetPoint("TOPLEFT", row, "TOPLEFT", 405, 0)
		row.source:SetPoint("TOPRIGHT")
		row.source:SetJustifyH("Left")
		row.source:SetJustifyV("TOP")
		
		shoppingRows[count] = row
	end
	Crafting.shoppingRows = shoppingRows
end

function Crafting:CreateQueuingRegion() -- updated
	-- scroll frame
	local scrollFrame = CreateFrame("ScrollFrame", "TSMCraftingScrollQueuing", Crafting.frame, "FauxScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", Crafting.frame, "TOPLEFT", 6, -24)
	scrollFrame:SetPoint("BOTTOMRIGHT", Crafting.frame.horizontalBarFrame2, "TOPRIGHT", -25, 1)
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT_QUEUING, Crafting.UpdateQueuing) 
	end)
	Crafting.frame.queuingScroll = scrollFrame
	
	-- title row
	local row = CreateFrame("Frame", nil, Crafting.frame)
	row:SetHeight(14)
	row:SetPoint("TOPLEFT", Crafting.frame.queuingScroll, "TOPLEFT", 	0, 18)
	row:SetPoint("TOPRIGHT", Crafting.frame.queuingScroll, "TOPRIGHT", 0, 18)
	
	local function CreateTitleButton(text, x1, x2)
		local button = CreateFrame("Button", nil, row)
		button:SetPoint("TOPLEFT", row, "TOPLEFT", x1, 0)
		button:SetPoint("TOPRIGHT", row, "TOPLEFT", x2, 0)
		button:SetHeight(14)
		button:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
		
		local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		label:SetText(text)
		label:SetWidth(x2-x1)
		label:SetHeight(14)
		label:SetPoint("CENTER")
		label:SetJustifyH("CENTER")
		label:SetJustifyV("TOP")
		button.text = label
		
		return button
	end
	
	row.name = CreateTitleButton(L["Name"], 50, 150)
	row.name:SetScript("OnClick", function(self) Crafting:ChangeSort(self, row, "name") end)
	if TSM.db.global.queueSort == "name" then row.name:LockHighlight() end
	
	row.quantity = CreateTitleButton(L["AH/Bags/Bank/Alts"], 190, 300)
	row.quantity:SetScript("OnClick", function(self) Crafting:ChangeSort(self, row, "quantity") end)
	if TSM.db.global.queueSort == "quantity" then row.quantity:LockHighlight() end
	
	row.buyout = CreateTitleButton(L["Item Value"], 315, 410)
	row.buyout:SetScript("OnClick", function(self) Crafting:ChangeSort(self, row, "buyout") end)
	if TSM.db.global.queueSort == "buyout" then row.buyout:LockHighlight() end
	
	row.profit = CreateTitleButton(L["Profit"], 420, 455)
	row.profit:SetScript("OnClick", function(self) Crafting:ChangeSort(self, row, "profit") end)
	if TSM.db.global.queueSort == "profit" then row.profit:LockHighlight() end
	
	if TSM.db.profile.showPercentProfit then
		row.profitPercent = CreateTitleButton("(%)", 460, 485)
		row.profitPercent:SetScript("OnClick", function(self) Crafting:ChangeSort(self, row, "profitPercent") end)
		if TSM.db.global.queueSort == "profitPercent" then row.profitPercent:LockHighlight() end
	end
	
	row.bar = row:CreateTexture()
	row.bar:SetPoint("BOTTOMLEFT", Crafting.frame.queuingScroll, "TOPLEFT")
	row.bar:SetPoint("BOTTOMRIGHT", Crafting.frame.queuingScroll, "BOTTOMRIGHT", 24, 0)
	row.bar:SetHeight(4)
	row.bar:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	row.bar:SetTexCoord(0.577, 0.683, 0.145, 0.309)
	row.bar:SetVertexColor(0, 0, 0.7, 0.5)
	Crafting.frame.queuingScroll.titleRow = row
	
	-- quantity frame
	local frame = CreateFrame("Frame", nil, row)
	frame:SetHeight(80)
	frame:SetWidth(180)
	frame:SetPoint("TOPLEFT", 50, -100)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 24,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	frame:SetBackdropColor(0, 0, .05, 1)
	frame:SetBackdropBorderColor(0, 0, 1, 1)
	frame:Hide()
	frame:SetScript("OnShow", function(self)
			self.eb:SetNumber(TSM.Data[Crafting.mode].crafts[self.itemID].queued)
			self.eb:HighlightText()
		end)
	Crafting.frame.quantityFrame = frame
	
	local function SubmitQuantity()
		local itemID = frame.itemID
		local number = frame.eb:GetNumber()
		if itemID and number and number >= 0 then
			TSM.Data[Crafting.mode].crafts[itemID].queued = number
		end
		frame:Hide()
		Crafting:UpdateAllScrollFrames()
	end
	
	local function HideFrame()
		frame:Hide()
	end
	
	local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetFontObject(GameFontNormal)
	text:SetTextColor(1, 1, 1, 1)
	text:SetPoint("TOPLEFT", 10, -15)
	text:SetWidth(85)
	text:SetJustifyH("Right")
	text:SetText(L["# Queued:"])
	
	local eb = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	eb:SetPoint("TOPLEFT", 100, -8)
	eb:SetWidth(65)
	eb:SetHeight(30)
	eb:SetScript("OnEnterPressed", SubmitQuantity)
	eb:SetScript("OnEscapePressed", HideFrame)
	frame.eb = eb
	
	local btn = Crafting:CreateButton(frame, L["OK"], GameFontNormal, -1)
	btn:SetPoint("BOTTOMLEFT", 6, 6)
	btn:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -2, 6)
	btn:SetHeight(25)
	btn:SetScript("OnClick", SubmitQuantity)
	
	local btn = Crafting:CreateButton(frame, CANCEL, GameFontNormal, -1)
	btn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 2, 6)
	btn:SetPoint("BOTTOMRIGHT", -6, 6)
	btn:SetHeight(25)
	btn:SetScript("OnClick", HideFrame)
	
	
	-- rows
	local queuingRows = {}
	local offset = 0
	for count=1, MAX_ROWS_QUEUING do
		local row = CreateFrame("Button", nil, Crafting.frame, "SecureActionButtonTemplate")
		row:SetHeight(ROW_HEIGHT_QUEUING)
		row:RegisterForClicks("AnyUp")
		Crafting:AddTooltip(row)
		row:SetScript("OnClick", function(row, mouseButton) Crafting:OnCraftRowClicked(row, mouseButton, 1) end)
		row:SetScript("OnDoubleClick", function(row, mouseButton) Crafting:OnCraftRowClicked(row, mouseButton, TSM.db.profile.doubleClick) end)
		
		if count > 1 then
			row:SetPoint("TOPLEFT", queuingRows[count - 1], "BOTTOMLEFT", 0, -2)
			row:SetPoint("TOPRIGHT", Crafting.frame.queuingScroll, "BOTTOMRIGHT", 0, -2)
		else
			row:SetPoint("TOPLEFT", Crafting.frame.queuingScroll, "TOPLEFT", 	18, 0)
			row:SetPoint("TOPRIGHT", Crafting.frame.queuingScroll, "TOPRIGHT", -12, 0)
		end
		
		row.buyout = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.profit = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.quantity = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.name:SetText("*")
		row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
		row.name:SetPoint("TOPRIGHT", row, "TOPLEFT", 200, 0)
		row.name:SetJustifyH("Left")
		row.name:SetJustifyV("TOP")
		
		row.button = CreateFrame("Button", nil, row)
		row.button:SetScript("OnClick", function(button) Crafting:ToggleCategory(button) end)
		row.button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
		row.button:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
		row.button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
		row.button:SetPoint("TOPLEFT", row, "TOPLEFT", -16, 0)
		row.button:SetHeight(14)
		row.button:SetWidth(14)
		
		row.button:Hide()
		row:Hide()
		
		queuingRows[count] = row
	end
	Crafting.queuingRows = queuingRows
end

-- gets called to update the craft queue frame whenever something changes
function Crafting:UpdateCrafting()
	if not Crafting.mode or not Crafting.craftRows then return end
	for _, row in ipairs(Crafting.craftRows) do row:Hide() end
	if not TSM[Crafting.mode]:HasProfession() then
		Crafting.frame.noCrafting:Show()
		Crafting.frame.noCrafting.text:SetText(format("%s was not found so the craft queue has been disabled.", (Crafting.mode or "Profession")))
		Crafting.frame.noCrafting.button:Hide()
		return
	elseif TSM[Crafting.mode]:HasProfession() and Crafting:GetCurrentTradeskill() ~= Crafting.mode then
		Crafting.frame.noCrafting:Show()
		Crafting.frame.noCrafting.button:Show()
		Crafting.frame.noCrafting.button:SetText("Open "..Crafting.mode)
		Crafting.frame.noCrafting.text:SetText(L["You must have your profession window open in order to use the craft queue. Click on the button below to open it."])
		return
	end
	Crafting.frame.noCrafting:Hide()
	Crafting.frame.craftingScroll:Show()
	Crafting.craftNextButton:Show()
	
	if Crafting:IsFilterSet() then
		Crafting.clearFilterButton:Show()
	else
		Crafting.clearFilterButton:Hide()
	end
	
	-- Update the scroll bar
	FauxScrollFrame_Update(Crafting.frame.craftingScroll, TSM.Queue.queueInTotal, MAX_ROWS_CRAFTING-1, ROW_HEIGHT_CRAFTING)
	
	-- Now display the correct rows
	local offset = FauxScrollFrame_GetOffset(Crafting.frame.craftingScroll)
	local displayIndex = 0
	local totalCost, totalProfit = 0, 0
	
	local skillIndexLookup = {}
	for i=1, GetNumTradeSkills() do
		local spellID = TSMAPI:GetItemID(GetTradeSkillRecipeLink(i)) -- also works for spellIDs
		if spellID then
			skillIndexLookup[spellID] = i
		end
	end
	
	-- fills the queue list
	local queueList = {}
	if not TSM.Queue.queueList[Crafting.mode] then TSM.Queue:UpdateQueue(Crafting.mode) end
	for stageNum=1, #TSM.Queue.queueList[Crafting.mode] do
		tinsert(queueList, {isTitle=true, stageNum=stageNum})
		for _, craft in ipairs(TSM.Queue.queueList[Crafting.mode][stageNum]) do
			craft.uniqueID = tostring(craft.itemID)
			craft.stageNum = stageNum
			tinsert(queueList, craft)
		end
	end

	Crafting.craftNextButton:Disable()
	
	local craftables = {}
	for index, data in ipairs(queueList) do
		-- if the craft should be displayed based on the scope of the scrollframe
		if index >= offset and displayIndex < MAX_ROWS_CRAFTING then
			if data.isTitle then
				displayIndex = displayIndex + 1
				local row = Crafting.craftRows[displayIndex]
				row.isTitle = data.isTitle
				row.stageNum = data.stageNum
				row:Show()
				row:UpdateState()
			else
				local haveMats, needEssence, essenceID, partial = Crafting:GetOrderIndex(Crafting.mode, data)
				local color
				
				local canCraft
				if partial and haveMats ~= 3 then
					canCraft = true
					color = "|cff5599ff"
				elseif haveMats == 3 then
					canCraft = true
					color = "|cff00ff00"
				elseif haveMats == 2 then
					color = "|cffffff00"
				else
					color = "|cffff7700"
				end
				
				-- make sure the player can craft it
				if skillIndexLookup[data.spellID] then
					displayIndex = displayIndex + 1
					
					-- special case for enchants
					local velName, quantity
					if Crafting.mode == "Enchanting" then
						velName = "\n/use item:"..TSM.Enchanting.vellumID
						quantity = 1
					else
						velName = ""
						quantity = data.quantity
					end
					
					-- add to the list of stuff we can craft
					if canCraft then
						tinsert(craftables, {skillIndexLookup[data.spellID], needEssence, essenceID, data.spellID, quantity, velName, stageNum=data.stageNum, index=index})
					end
					
					-- we can craft this and we're not currently casting anything so enable the craft next button
					if (haveMats == 3 or partial) and not UnitCastingInfo("player") and Crafting.isCrafting == 0 then
						Crafting.craftNextButton:Enable()
					end
					
					-- setup the row frame
					local row = Crafting.craftRows[displayIndex]
					row:Show()
					row.isTitle = false
					row.stageNum = data.stageNum
					row.button.data = {name=data.name, quantity=data.quantity, itemID=data.itemID}
					row.button:SetText(format("    %s%s (x%s)|r", color, data.name or L["Craft"], data.quantity))
					row.button:SetAttribute("macrotext", format("/script DoTradeSkill(%d,%d)%s", skillIndexLookup[data.spellID], quantity, velName))
					row:UpdateState()
				end
			end
		end
		
		-- add up the total cost / profit (this if statement excludes intermediate crafts from the calculation)
		if not data.isTitle then
			local cost, buyout, profit = TSM.Data:GetCraftPrices(data.itemID, Crafting.mode)
			totalCost = totalCost + (cost or 0)*data.quantity
			totalProfit = totalProfit + (profit or 0)*data.quantity
		end
	end
	
	sort(craftables, function(a,b)
			if a.stageNum == b.stageNum then
				return a.index < b.index
			else
				return a.stageNum < b.stageNum
			end
		end)
	
	local data = craftables[1]
	if data then
		local cIndex, needEssence, essenceID, spellID, quantity, velName = unpack(data)
		
		local essence
		for k=1, floor(needEssence or 0) do
			essence = (essence or "").."/use item:"..essenceID.."\n"
		end
		
		-- setup the "Craft Next craft" button
		Crafting.craftNextButton:SetAttribute("type", "macro")
		if essence then
			Crafting.craftNextButton:SetText(L["Combine/Split Essences/Eternals"])
			Crafting.craftNextButton:SetAttribute("macrotext", essence)
			Crafting.craftNextButton:SetScript("PostClick", function(self)
					Crafting.isCrafting = 0
					self:Disable()
				end)
		else
			Crafting.craftNextButton:SetText(L["Craft Next"])
			Crafting.craftNextButton.spellID = spellID
			Crafting.craftNextButton:SetAttribute("macrotext", format("/script DoTradeSkill(%d,%d)%s", cIndex, quantity, velName))
			Crafting.craftNextButton:SetScript("PostClick", function(self)
					Crafting.isCrafting = quantity
					self:Disable()
				end)
		end
	end
	
	Crafting.totalGoldFrame.matTotal:UpdateGoldAmount(totalCost)
	Crafting.totalGoldFrame.profitTotal:UpdateGoldAmount(totalProfit)
	
	if displayIndex < MAX_ROWS_CRAFTING then
		FauxScrollFrame_Update(Crafting.frame.craftingScroll, displayIndex, MAX_ROWS_CRAFTING-1, ROW_HEIGHT_CRAFTING)
	end
end

function Crafting:UpdateShopping()
	if not Crafting.mode then return end
	for _, row in ipairs(Crafting.shoppingRows) do row:Hide() end
	local total, need = TSM.Queue:GetMatsForQueue(Crafting.mode, true)
	
	-- Update the scroll bar
	FauxScrollFrame_Update(Crafting.frame.shoppingScroll, #(total), MAX_ROWS_SHOPPING-1, ROW_HEIGHT_SHOPPING)
	
	-- Now display the correct rows
	local offset = FauxScrollFrame_GetOffset(Crafting.frame.shoppingScroll)
	local displayIndex = 0
	
	local temp = {}
	
	-- HORRIBLE CODE (but it sorts the shopping list hopefully)
	sort(total, function(a, b)
			local itemIDA, itemIDB = a[1], b[1]
			if not temp[itemIDA] or not temp[itemIDB] then
				for _, v in ipairs(need) do
					local needID = v[1]
					local needQuantity = v[2]
					if needID == itemIDA then
						temp[itemIDA] = {}
						temp[itemIDA].need = needQuantity
					end
					if needID == itemIDB then
						temp[itemIDB] = {}
						temp[itemIDB].need = needQuantity
					end
				end
			end
			
			if temp[itemIDA].need == temp[itemIDB].need then
				if not temp[itemIDA].bags then
					temp[itemIDA].bags = TSM.Data:GetPlayerNum(itemIDA)
				end
				if not temp[itemIDB].bags then
					temp[itemIDB].bags = TSM.Data:GetPlayerNum(itemIDB)
				end
				if temp[itemIDA].bags == temp[itemIDB].bags then
					return itemIDA < itemIDB
				else
					return temp[itemIDA].bags > temp[itemIDB].bags
				end
			else
				return temp[itemIDA].need < temp[itemIDB].need
			end
		end)
	
	for index, data in ipairs(total) do
		-- if the craft should be displayed based on the scope of the scrollframe
		if index >= offset and displayIndex < MAX_ROWS_SHOPPING then
			local needNum = 0
			for _, v in ipairs(need) do
				if v[1] == data[1] then
					needNum = v[2]
				end
			end
			
			local itemID = data[1]
			local name = TSM.Data[Crafting.mode].mats[itemID].name
			local cost = TSM.Data:GetMatCost(Crafting.mode, itemID)
			local totalNum = data[2]
			local source = TSM.Data[Crafting.mode].mats[itemID].source
			
			if source == "craft" then
				source = L["Craft"]
			elseif source == "mill" then
				source = L["Mill"]
			elseif source == "vendor" then
				source = L["Vendor"]
			elseif source == "vendortrade" then
				source = L["Vendor Trade"]
			elseif source == "auction" then
				source = L["Auction House"]
			else
				source = "---"
			end
			
			if not name then
				name = GetItemInfo(itemID)
				TSM.Data[Crafting.mode].mats[itemID].name = name
			end
			
			if needNum < 0 then needNum = 0 end
			
			if needNum == 0 and TSM.Data:GetPlayerNum(itemID) >= totalNum then
				needNum = 0
				color = "|cff00ff00"
			elseif needNum == 0 then
				color = "|cffffff00"
			else
				color = "|cffff0000"
			end
			
			cost = TSM:FormatTextMoney(cost, nil, true)
			
			displayIndex = displayIndex + 1
			
			local row = Crafting.shoppingRows[displayIndex]
			row.itemID = itemID
			row.name:SetText(color .. name .. "|r")
			row.total:SetText(color .. totalNum .. "|r")
			row.value:SetText(cost)
			row.need:SetText(color .. needNum .. "|r")
			row.bags:SetText(color .. TSM.Data:GetPlayerNum(itemID) .. "|r")
			row.source:SetText(source)
			row:Show()
		end
	end
end

local orderCache = {time = 0}
function Crafting:UpdateQueuing()
	if not Crafting.mode then return end
	for _, row in ipairs(Crafting.queuingRows) do row:Hide() end
	
	-- Now display the correct rows
	local offset = FauxScrollFrame_GetOffset(Crafting.frame.queuingScroll)
	local displayIndex = 0
	local rowDisplay = {}

	local groupedData = Crafting:GetDataByGroups(Crafting.mode)
	
	local sortedGroupedData = {}
	for i in pairs(groupedData) do
		groupedData[i] = groupedData[i] or {}
		local n = 0
		for itemID, data in pairs(groupedData[i]) do
			n = n + 1
			if not data.enabled then
				groupedData[i][itemID] = nil
			end
		end
		if orderCache.time < (GetTime() - 2) then wipe(orderCache) orderCache.time = GetTime() end
		sortedGroupedData[i] = TSM:GetSortedData(groupedData[i], function(a, b)
				if not orderCache[a.spellID] then orderCache[a.spellID] = Crafting:GetQueueItemOrder(a, a.originalIndex) end
				if not orderCache[b.spellID] then orderCache[b.spellID] = Crafting:GetQueueItemOrder(b, b.originalIndex) end
				if TSM.db.global.queueSortDescending then
					return orderCache[a.spellID] > orderCache[b.spellID]
				else
					return orderCache[a.spellID] < orderCache[b.spellID]
				end
			end)
	end
	
	local numPairs, topIndex = 0
	for i in pairs(sortedGroupedData) do
		if not topIndex or topIndex < i then
			topIndex = i
		end
		numPairs = numPairs + 1
	end
	
	local slotList = TSM[Crafting.mode].slotList
	if Crafting.mode == "Inscription" then
		slotList = TSM.Inscription:GetSlotList()
	end
	
	local allRows = {{name=L["All"], isParent=true, group=0}}
	if numPairs == topIndex then
		-- Add the index we will want in the correct order, so we can do offsets easily
		for group, crafts in ipairs(sortedGroupedData) do
			local parentRow = {}
			parentRow.name = slotList[group]
			parentRow.isParent = true
			parentRow.group = group
			
			local tempData = {}
			for _, sData in pairs(crafts) do
				local itemID = sData.originalIndex
				local item = TSM.Data[Crafting.mode].crafts[itemID]
				local data = {}
				
				data.name = data.name
				data.cost, data.buyout, data.profit = TSM.Data:GetCraftPrices(itemID, Crafting.mode)
				data.itemID = itemID
				data.spellID = item.spellID
				
				tinsert(tempData, data)
			end
			
			if #tempData > 0 then
				tinsert(rowDisplay, parentRow)
				
				if groupShown[group] or groupShown[0] then
					for _, data in ipairs(tempData) do
						if groupShown[group] then
							tinsert(rowDisplay, data)
						elseif groupShown[0] then
							tinsert(allRows, data)
						end
					end
				end
			end
		end
	else
		for group, crafts in pairs(sortedGroupedData) do
			local parentRow = {}
			parentRow.name = slotList[group]
			parentRow.isParent = true
			parentRow.group = group
			
			local tempData = {}
			for _, sData in pairs(crafts) do
				local itemID = sData.originalIndex
				local item = TSM.Data[Crafting.mode].crafts[itemID]
				local data = {}
				
				data.name = data.name
				data.cost, data.buyout, data.profit = TSM.Data:GetCraftPrices(itemID, Crafting.mode)
				data.itemID = itemID
				data.spellID = item.spellID
				
				tinsert(tempData, data)
			end
			
			if #tempData > 0 then
				tinsert(rowDisplay, parentRow)
				
				if groupShown[group] or groupShown[0] then
					for _, data in ipairs(tempData) do
						if groupShown[group] then
							tinsert(rowDisplay, data)
						elseif groupShown[0] then
							tinsert(allRows, data)
						end
					end
				end
			end
		end
	end
	
	sort(allRows, function(a, b)
			if a.isParent then return true end
			if b.isParent then return false end
			if not orderCache[a.spellID] then orderCache[a.spellID] = Crafting:GetQueueItemOrder(TSM.Data[Crafting.mode].crafts[a.itemID], a.itemID) end
			if not orderCache[b.spellID] then orderCache[b.spellID] = Crafting:GetQueueItemOrder(TSM.Data[Crafting.mode].crafts[b.itemID], b.itemID) end
			if TSM.db.global.queueSortDescending then
				return orderCache[a.spellID] > orderCache[b.spellID]
			else
				return orderCache[a.spellID] < orderCache[b.spellID]
			end
		end)
	for _, v in ipairs(rowDisplay) do tinsert(allRows, v) end
	
	-- Update the scroll bar
	FauxScrollFrame_Update(Crafting.frame.queuingScroll, #(allRows), MAX_ROWS_QUEUING-1, ROW_HEIGHT_QUEUING)
	
	-- Now display
	local offset = FauxScrollFrame_GetOffset(Crafting.frame.queuingScroll)
	local displayIndex = 0
	
	for index, data in pairs(allRows) do
		if index >= offset and displayIndex < MAX_ROWS_QUEUING then
			displayIndex = displayIndex + 1
			
			local row = Crafting.queuingRows[displayIndex]
			local item = TSM.Data[Crafting.mode].crafts[data.itemID]
			row.itemID = data.itemID
			
			row.button.group = data.group
			row.tooltipData = nil
			
			if not data.isParent then
				local numInBags, numInBank, numOnAH = TSM.Data:GetPlayerNum(data.itemID)
				local numOnAlts = TSM.Data:GetAltNum(data.itemID)
				
				-- sets up the colors of the text
				local c1 = GREEN
				local c2 = GREEN
				local c3 = GREEN
				local c4 = GREEN
				if numOnAH == "?" then c1 = WHITE
				elseif numOnAH > 0 then c1 = RED end
				if numInBags > 0 then c2 = RED end
				if numOnAlts > 0 then c3 = RED end
				if numInBank > 0 then c4 = RED end
				row.quantity:SetText(format("%s%s|r/%s%s|r/%s%s|r/%s%s|r", c1, numOnAH, c2, numInBags, c4, numInBank, c3, numOnAlts))
			else
				row.quantity:SetText("")
			end
			
			local cost, buyout, profit = data.cost, data.buyout, data.profit
			local specialBuyout = false
			
			if cost and not buyout and TSM:GetDBValue("unknownProfitMethod") == "fallback" and TSMAPI:GetData("auctioningFallback", data.itemID) then
				buyout = TSMAPI:GetData("auctioningFallback", data.itemID)
				profit = buyout - cost
				specialBuyout = true
			end
			
			if buyout and profit then
				local percentText = ""
				if TSM.db.profile.showPercentProfit and profit > 0 then
					percentText = " ("..GREEN..(floor((profit/buyout)*100+0.5)).."|r%)"
				elseif TSM.db.profile.showPercentProfit then
					percentText = " ("..RED..(floor((profit/buyout)*100+0.5)).."|r%)"
				end
				
				local color = GREEN
				if profit <= 0 then color = RED end
				buyout = (TSM:FormatTextMoney(buyout, (specialBuyout and TSMAPI.Design:GetInlineColor("link2")), true) or "---")
				profit = (profit<=0 and RED.."-".."|r" or "")..(TSM:FormatTextMoney(abs(profit), color, true, true) or "---")..percentText
			else
				buyout = nil
				profit = nil
			end

			if buyout then
				row.buyout:SetText(buyout)
			elseif data.isParent then
				row.buyout:SetText("")
			else
				if TSM.db.profile.unknownProfitMethod == "fallback" and TSMAPI:GetData("auctioningFallback", data.itemID) then
					local fallback = TSMAPI:GetData("auctioningFallback", data.itemID)
					fallback = ""
					row.buyout:SetText(fallback)
				else
					row.buyout:SetText("---")
				end
			end
			
			if profit then
				row.profit:SetText(profit)
			elseif data.isParent then
				row.profit:SetText("")
			else
				row.profit:SetText("----")
			end
			
			-- Displaying a parent
			if data.isParent then
				row.name:SetText(data.name)
				row.name:ClearAllPoints()
				row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
				row.name:SetPoint("TOPRIGHT", row, "TOPLEFT", 200, 0)

				row:Show()
				row.button:Show()

				row.buyout:ClearAllPoints()
				row.buyout:SetPoint("TOPRIGHT", row, "TOPRIGHT", -14, 0)
				
				row.quantity:ClearAllPoints()
				row.quantity:SetPoint("TOPRIGHT", row, "TOPRIGHT", -160, 0)

				-- Is the button supposed to be + or -?
				if groupShown[row.button.group] then
					row.button:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
					row.button:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
					row.button:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-Hilight", "ADD")
				else
					row.button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
					row.button:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
					row.button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
				end
				
			-- Orrr a child
			else
				local link = select(2, GetItemInfo(data.itemID))
				local craftQuantity = ""
				
				if item.queued > 0 then
					craftQuantity = format("%s%dx|r", GREEN, item.queued)
				end
				
				row.name:ClearAllPoints()
				row.name:SetPoint("TOPLEFT", row, "TOPLEFT", -2, 0)
				row.name:SetPoint("TOPRIGHT", row, "TOPLEFT", 200, 0)

				row.name:SetFormattedText("%s|r%s", craftQuantity, item.name)
				row:Show()
				row.button:Hide()
				
				row.buyout:ClearAllPoints()
				row.buyout:SetPoint("TOPLEFT", row, "TOPLEFT", 300, 0)
				
				row.profit:ClearAllPoints()
				row.profit:SetPoint("TOPLEFT", row, "TOPLEFT", 400, 0)

				row.quantity:ClearAllPoints()
				row.quantity:SetPoint("TOPLEFT", row, "TOPLEFT", 205, 0)
			end
		end
	end
end

-- trade skill is shown so show the TSM button / load the frame
function Crafting:TRADE_SKILL_SHOW()
	if Crafting.frame then Crafting.frame:Hide() end
	if Crafting.openCloseButton then Crafting.openCloseButton:Hide() end
	if not TSM[Crafting:GetCurrentTradeskill()] then return end
	Crafting.horribleHackVar = true
	Crafting.mode = Crafting:GetCurrentTradeskill()
	Crafting:PrepareFrame("hide")
	if Crafting.nextFunc and Crafting.nextFunc ~= function() end then
		Crafting.horribleHackVar = false
		Crafting.nextFunc()
		Crafting.nextFunc = function() end
	end
end

-- cleans up the tables used and unregisters events when the trade skill window is closed
function Crafting:TRADE_SKILL_CLOSE()
	if Crafting.frame and Crafting.frame:IsVisible() then
		Crafting.openCloseButton:SetParent(Crafting.frame)
		Crafting:UpdateCrafting()
	else
		Crafting.mode = nil
	end
	
	Crafting:UnregisterEvent("TRADE_SKILL_UPDATE")
	Crafting:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Crafting:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	Crafting:UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	Crafting:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
end

-- updates the craft list scroll frame since the visible crafts have possibly changed
function Crafting:TRADE_SKILL_UPDATE()
	TSMAPI:CreateTimeDelay("craftingTradeskillUpdateBucket", 0.2, function() Crafting:UpdateCrafting() end)
end

-- updates all the scroll frames
function Crafting:BAG_UPDATE()
	TSMAPI:CreateTimeDelay("craftingBagUpdateBucket", 0.2, function() Crafting:UpdateAllScrollFrames() end)
end

-- detects when crafts are successfully cast and removes that item from the queue
function Crafting:UNIT_SPELLCAST_SUCCEEDED(_, unit, spellName)
	-- verifies that we are interested in this spellcast
	if unit ~= "player" or not TSM.Data[Crafting.mode] then
		return
	end
	
	for _, data in pairs(TSM.Data[Crafting.mode].crafts) do
		if spellName == GetSpellInfo(data.spellID) then
			-- decrements the number of this craft that are queued to be crafted
			data.queued = data.queued - 1
			TSM.db.profile.craftHistory[data.spellID] = (TSM.db.profile.craftHistory[data.spellID] or 0) + 1
			Crafting.isCrafting = Crafting.isCrafting - 1
			TSM.Queue.lastCraft = data.spellID
			TSMAPI:CreateTimeDelay("craftingSpellcastSucceededBucket", 0.2, function() Crafting:UpdateAllScrollFrames() end)
			break
		end
	end
end

function Crafting:UNIT_SPELLCAST_INTERRUPTED(...)
	Crafting:UNIT_SPELLCAST_FAILED_QUIET(...)
end

function Crafting:UNIT_SPELLCAST_FAILED(...)
	Crafting:UNIT_SPELLCAST_FAILED_QUIET(...)
end

function Crafting:UNIT_SPELLCAST_FAILED_QUIET(_, unit, spellName)
	-- verifies that we are interested in this spellcast
	if unit ~= "player" then
		return
	end

	if Crafting.craftNextButton.spellID and spellName == GetSpellInfo(Crafting.craftNextButton.spellID) then
		Crafting.isCrafting = 0
		TSMAPI:CreateTimeDelay("craftingSpellcastFailedBucket", 0.2, function() Crafting:UpdateAllScrollFrames() end)
	end
end


function Crafting:ToggleCategory(button) -- updated
	groupShown[button.group] = not groupShown[button.group]
	Crafting:UpdateQueuing()
end

function Crafting:OnCraftRowClicked(row, mouseButton, numClicks) -- updated
	if not row.itemID then
		Crafting:ToggleCategory(row.button)
	elseif mouseButton == "LeftButton" or mouseButton == "RightButton" then
		if IsShiftKeyDown() then
			Crafting.frame.quantityFrame:Hide()
			Crafting.frame.quantityFrame.itemID = row.itemID
			Crafting.frame.quantityFrame:Show()
		else
			for i=1, numClicks do
				if mouseButton == "LeftButton" then
					TSM.Data[Crafting.mode].crafts[row.itemID].queued = TSM.Data[Crafting.mode].crafts[row.itemID].queued + 1
				elseif mouseButton == "RightButton" and TSM.Data[Crafting.mode].crafts[row.itemID].queued > 0 then
					TSM.Data[Crafting.mode].crafts[row.itemID].queued = TSM.Data[Crafting.mode].crafts[row.itemID].queued - 1
				end
			end
			Crafting:UpdateAllScrollFrames()
		end
	end
end

function Crafting:ChangeSort(button, row, method)
	if row.profitPercent then row.profitPercent:UnlockHighlight() end
	row.name:UnlockHighlight()
	row.quantity:UnlockHighlight()
	row.buyout:UnlockHighlight()
	row.profit:UnlockHighlight()
	button:LockHighlight()
	
	if TSM.db.global.queueSort == method then
		TSM.db.global.queueSortDescending = not TSM.db.global.queueSortDescending
	else
		TSM.db.global.queueSort = method
	end
	
	orderCache.time = 0
	Crafting:UpdateQueuing()
end

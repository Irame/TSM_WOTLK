-- This module holds some GUI helper functions for modules to use.

local TSM = select(2, ...)
local lib = TSMAPI

TSMAPI.GUI = {}
local GUI = TSMAPI.GUI

function lib:CreateScrollingTable(colInfo, useTSMColor, ...)
	local st
	if useTSMColor then
		st = LibStub("ScrollingTable"):CreateST(colInfo, ...)
		st.type = "ScrollingTable"
		
		local oldSetDisplayCols = st.SetDisplayCols
		st.SetDisplayCols = function(self, ...)
			oldSetDisplayCols(self, ...)
			for _, col in ipairs(self.head.cols) do
				local fontString = col:GetFontString()
				fontString:SetShadowColor(0, 0, 0, 0)
				if type(useTSMColor) ~= "table" then
					local font, size = TSMAPI.Design:GetContentFont("small")
					useTSMColor = {font, size, "SetWidgetLabelColor"}
				end
				fontString:SetFont(useTSMColor[1], useTSMColor[2])
				TSMAPI.Design[useTSMColor[3]](nil, fontString)
				col:SetFontString(fontString)
			end
		end
		
		TSMAPI.Design:SetContentColor(st.frame)
		st.scrollframe:SetPoint("TOPLEFT", 6, -6)
		st.scrollframe:SetPoint("BOTTOMRIGHT", -6, 6)
		st.scrollframe:SetScript("OnHide", nil)
		local scrollBar = _G[st.scrollframe:GetName().."ScrollBar"]
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("BOTTOMRIGHT")
		scrollBar:SetPoint("TOPRIGHT")
		scrollBar:SetWidth(12)
		local thumbTex = scrollBar:GetThumbTexture()
		thumbTex:SetPoint("CENTER")
		TSMAPI.Design:SetFrameColor(thumbTex)
		thumbTex:SetHeight(150)
		thumbTex:SetWidth(scrollBar:GetWidth())
		_G[scrollBar:GetName().."ScrollUpButton"]:Hide()
		_G[scrollBar:GetName().."ScrollDownButton"]:Hide()
		_G[st.frame:GetName().."ScrollTrough"]:Hide()
		_G[st.frame:GetName().."ScrollTroughBorder"]:Hide()
	else
		st = LibStub("ScrollingTable"):CreateST(colInfo, ...)
		st.frame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 16,
				insets = {left = 3, right = 3, top = 5, bottom = 3},
			})
		st.frame:SetBackdropColor(0, 0, 0.05, 1)
		st.frame:SetBackdropBorderColor(0, 0, 1, 1)
		_G[st.frame:GetName().."ScrollTroughBorder"].background:SetTexture(0, 0, 1, 1)
	end
	
	-- custom functions that may or may not be in lib-st
	if not st.RowIsVisible then
		st.RowIsVisible = function(self, realrow)
			return (realrow > self.offset and realrow <= (self.displayRows + self.offset))
		end
	end
	if not st.SetScrollOffset then
		st.SetScrollOffset = function(self, offset)
			local maxOffset = max(#self.filtered - self.displayRows, 0)
			if not offset or offset < 0 or offset > maxOffset then
				return -- invalid offset
			end
			
			local scrollPercent = TSMAPI:SafeDivide(offset, maxOffset)
			local maxPixelOffset = self.scrollframe:GetVerticalScrollRange() + self.rowHeight
			local pixelOffset = scrollPercent * maxPixelOffset 
			self.scrollframe:SetVerticalScroll(pixelOffset)
			FauxScrollFrame_SetOffset(self.scrollframe, offset)
		end
	end
	
	return st
end

function TSM:CreateWidgetDisabledFrame(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()
	frame:SetFrameLevel(frame:GetFrameLevel()+2)
	frame:EnableMouse(true)
	frame:SetScript("OnShow", function(self) self:EnableMouse(true) end)
	frame:SetScript("OnHide", function(self) self:EnableMouse(false) end)
	frame:SetScript("OnEnter", function(self)
			local tooltip = self.obj.disabledTooltip
			if not tooltip then return end
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
			GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
			GameTooltip:Show()
		end)
	frame:SetScript("OnLeave", function(self)	GameTooltip:Hide() end)
	frame:SetScript("OnMouseUp", function(self, button)
			if button == "RightButton" and self.obj.rightClickCallback then
				self.obj:rightClickCallback(true)
			end
		end)
	return frame
end



-- Tooltips!
local function ShowTooltip(self)
	if self.link then
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
		GameTooltip:SetHyperlink(self.link)
		GameTooltip:Show()
	elseif type(self.tooltip) == "function" then
		local text = self.tooltip(self)
		if type(text) == "string" then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetText(text, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end
	elseif self.tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
		GameTooltip:Show()
	elseif self.frame.tooltip then
		GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetText(self.frame.tooltip, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end
end

local function HideTooltip()
	GameTooltip:Hide()
end

function GUI:CreateButton(parent, textHeight, name, isSecure)
	local btn = CreateFrame("Button", name, parent, isSecure and "SecureActionButtonTemplate")
	TSMAPI.Design:SetContentColor(btn)
	local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetTexture(1, 1, 1, .2)
	highlight:SetBlendMode("BLEND")
	btn.highlight = highlight
	btn:SetScript("OnEnter", function(self) if self.tooltip then ShowTooltip(self) end end)
	btn:SetScript("OnLeave", HideTooltip)
	btn:Show()
	local label = btn:CreateFontString()
	label:SetFont(TSMAPI.Design:GetContentFont(), textHeight)
	label:SetPoint("CENTER")
	label:SetJustifyH("CENTER")
	label:SetJustifyV("CENTER")
	label:SetHeight(textHeight)
	TSMAPI.Design:SetWidgetTextColor(label)
	btn:SetFontString(label)
	TSM:Hook(btn, "Enable", function() TSMAPI.Design:SetWidgetTextColor(label) end, true)
	TSM:Hook(btn, "Disable", function() TSMAPI.Design:SetWidgetTextColor(label, true) end, true)
	return btn
end

function GUI:CreateHorizontalLine(parent, ofsy, relativeFrame, invertedColor)
	relativeFrame = relativeFrame or parent
	local barTex = parent:CreateTexture()
	barTex:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 2, ofsy)
	barTex:SetPoint("TOPRIGHT", relativeFrame, "TOPRIGHT", -2, ofsy)
	barTex:SetHeight(2)
	if invertedColor then
		TSMAPI.Design:SetContentColor(barTex)
	else
		TSMAPI.Design:SetFrameColor(barTex)
	end
	return barTex
end

function GUI:CreateVerticalLine(parent, ofsx, relativeFrame, invertedColor)
	relativeFrame = relativeFrame or parent
	local barTex = parent:CreateTexture()
	barTex:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", ofsx, -2)
	barTex:SetPoint("BOTTOMLEFT", relativeFrame, "BOTTOMLEFT", ofsx, 2)
	barTex:SetWidth(2)
	if invertedColor then
		TSMAPI.Design:SetContentColor(barTex)
	else
		TSMAPI.Design:SetFrameColor(barTex)
	end
	return barTex
end

function GUI:CreateInputBox(parent, name)
	local function OnEscapePressed(self)
		self:ClearFocus()
		self:HighlightText(0, 0)
	end

	local eb = CreateFrame("EditBox", name, parent)
	eb:SetFont(TSMAPI.Design:GetContentFont("normal"))
	eb:SetShadowColor(0, 0, 0, 0)
	TSMAPI.Design:SetContentColor(eb)
	eb:SetAutoFocus(false)
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() self:HighlightText(0, 0) end)
	eb.disabled = false
	
	local SetDisabled = function(editbox, disabled)
		if editbox.disabled == disabled then return end
		editbox.disabled = disabled
		
		TSMAPI.Design:SetWidgetTextColor(editbox, disabled)
		editbox:EnableMouse(not disabled)
		if disabled then
			editbox:ClearFocus()
		end
	end
	
	eb.Disable = function(self) SetDisabled(self, true) end
	eb.Enable = function(self) SetDisabled(self, false) end
	eb.IsEnabled = function(self) return not self.disabled end
	
	return eb
end

function GUI:CreateLabel(parent, size)
	local label = parent:CreateFontString()
	label:SetFont(TSMAPI.Design:GetContentFont(size))
	TSMAPI.Design:SetWidgetLabelColor(label)
	return label
end

function GUI:CreateTitleLabel(parent, size)
	local label = parent:CreateFontString()
	label:SetFont(TSMAPI.Design:GetBoldFont(), size)
	TSMAPI.Design:SetTitleTextColor(label)
	return label
end
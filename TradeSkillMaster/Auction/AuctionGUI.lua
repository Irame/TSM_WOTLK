local TSM = select(2, ...)
local GUI = {}
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")


function GUI:AddHorizontalBar(parent, ofsy, relativeFrame)
	relativeFrame = relativeFrame or parent
	local barFrame = CreateFrame("Frame", nil, parent)
	barFrame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 4, ofsy)
	barFrame:SetPoint("TOPRIGHT", relativeFrame, "TOPRIGHT", -4, ofsy)
	barFrame:SetHeight(8)
	local barTex = barFrame:CreateTexture()
	barTex:SetAllPoints(barFrame)
	barTex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	barTex:SetTexCoord(0.577, 0.683, 0.145, 0.309)
	barTex:SetVertexColor(0, 0, 1, 1)
	barFrame.texture = barTex
	return barFrame
end

function GUI:AddVerticalBar(parent, ofsx, relativeFrame)
	relativeFrame = relativeFrame or parent
	local barFrame = CreateFrame("Frame", nil, parent)
	barFrame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", ofsx, -4)
	barFrame:SetPoint("BOTTOMLEFT", relativeFrame, "BOTTOMLEFT", ofsx, 4)
	barFrame:SetWidth(6)
	local barTex = barFrame:CreateTexture()
	barTex:SetAllPoints(barFrame)
	barTex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	barTex:SetTexCoord(0.269, 0.286, 0.115, 0.372)
	barTex:SetVertexColor(0, 0, 1, 1)
	barFrame.texture = barTex
	return barFrame
end

local frame
function TSMAPI:RunTest(parent, callback)
	local function incorrect()
		if frame.attempt == 1 then
			frame.attempt = 2
			print(L["Careful where you click!"])
		elseif frame.attempt == 2 then
			callback(frame:Hide())
		end
	end

	frame = frame or TSMAPI:CreateSecureChild(parent)
	frame:SetFrameLevel(frame:GetFrameLevel()+10)
	frame:SetAllPoints()
	frame.attempt = 1
	TSMAPI.Design:SetFrameColor(frame)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseUp", incorrect)
	frame:Show()
	
	frame.title = frame.title or TSMAPI.GUI:CreateLabel(frame)
	frame.title:SetText(L["TradeSkillMaster Human Check - Click on the Correct Button!"])
	frame.title:SetPoint("TOP", 0, -10)
	
	local maxX1 = frame:GetWidth()/2 - 110
	local maxX2 = frame:GetWidth() - 110
	local maxY = frame:GetHeight() - 50
	
	local function getXY(num)
		return random(10, (num == 1 and maxX1 or maxX2)), random(10, maxY)
	end
	
	local btn1Num = random(1, 2)
	frame.btn = frame.btn or TSMAPI.GUI:CreateButton(frame, 16)
	frame.btn:SetText(L["I am human!"])
	frame.btn:SetScript("OnClick", function(...) callback(..., frame:Hide()) end)
	frame.btn:SetHeight(25)
	frame.btn:SetWidth(100)
	frame.btn:SetPoint("BOTTOMLEFT", getXY(btn1Num))
	
	frame.wbtn = frame.wbtn or TSMAPI.GUI:CreateButton(frame, 16)
	frame.wbtn:SetText(L["I am a bot!"])
	frame.wbtn:SetScript("OnClick", incorrect)
	frame.wbtn:SetHeight(25)
	frame.wbtn:SetWidth(100)
	frame.wbtn:SetPoint("BOTTOMLEFT", getXY(btn1Num%2+1))
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

function GUI:CreateCheckBox(parent, label, width, point, tooltip)
	local cb = LibStub("AceGUI-3.0"):Create("TSMCheckBox")
	cb:SetType("checkbox")
	cb:SetWidth(width)
	cb:SetLabel(label)
	cb.frame:SetParent(parent)
	cb.frame:SetPoint(unpack(point))
	cb.frame:Show()
	if tooltip then
		cb.frame.tooltip = tooltip
		cb:SetCallback("OnEnter", ShowTooltip)
		cb:SetCallback("OnLeave", HideTooltip)
	end
	return cb
end

function GUI:CreateDropdown(parent, label, width, list, point, tooltip)
	local dd = LibStub("AceGUI-3.0"):Create("TSMDropdown")
	dd:SetDisabled()
	dd:SetMultiselect(false)
	dd:SetWidth(width)
	dd:SetLabel(label)
	dd:SetList(list)
	dd.frame:SetParent(parent)
	dd.frame:SetPoint(unpack(point))
	dd.frame:Show()
	dd.frame.tooltip = tooltip
	dd:SetCallback("OnEnter", ShowTooltip)
	dd:SetCallback("OnLeave", HideTooltip)
	return dd
end

function GUI:CreateEditBox(parent, label, width, point, tooltip)
	local eb = LibStub("AceGUI-3.0"):Create("TSMEditBox")
	eb:SetWidth(width)
	eb:SetLabel(label)
	eb.frame:SetParent(parent)
	eb.frame:SetPoint(unpack(point))
	eb.frame:Show()
	if tooltip then
		eb.frame.tooltip = tooltip
		eb:SetCallback("OnEnter", ShowTooltip)
		eb:SetCallback("OnLeave", HideTooltip)
	end
	return eb
end

function GUI:CreateIcon(parent, texture, size, point, tooltip)
	local iconButton = CreateFrame("Button", nil, parent, "ItemButtonTemplate")
	
	iconButton:SetNormalTexture(texture)
	iconButton:GetNormalTexture():SetWidth(size)
	iconButton:GetNormalTexture():SetHeight(size)
	iconButton:SetPushedTexture(texture)
	iconButton:SetPushedTextOffset(0, -4)
	
	iconButton:SetScript("OnEnter", ShowTooltip)
	iconButton:SetScript("OnLeave", HideTooltip)
	iconButton:SetPoint(unpack(point))
	iconButton:SetHeight(size)
	iconButton:SetWidth(size)
	iconButton.tooltip = tooltip
	return iconButton
end

function TSMAPI:GetGUIFunctions()
	return GUI
end
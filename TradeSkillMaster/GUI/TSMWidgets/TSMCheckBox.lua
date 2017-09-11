-- Much of this code is copied from .../AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua
-- This CheckBox widget is modified to fit TSM's theme / needs
local TSM = select(2, ...)
local Type, Version = "TSMCheckBox", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs = select, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function Control_OnClick(frame, button)
	local self = frame.obj
	if button == "RightButton" and self.rightClickCallback then
		self:rightClickCallback(false)
	end
end

local function CheckBox_OnMouseDown(frame)
	local self = frame.obj
	if not self.disabled then
		self.text:SetPoint("LEFT", self.btn, "RIGHT", 1, -1)
	end
	AceGUI:ClearFocus()
end

local function CheckBox_OnMouseUp(frame, button)
	local self = frame.obj
	if button == "RightButton" and self.rightClickCallback then
		self:rightClickCallback(false)
	elseif not self.disabled then
		self.text:SetPoint("LEFT", self.btn, "RIGHT", 0, 0)
		self:ToggleChecked()

		if self.checked then
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
		end

		self:Fire("OnValueChanged", self.checked)
	end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetType()
		self:SetValue()
		self:SetWidth(200)
		self:SetDisabled()
			self:SetHeight(24)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		TSMAPI.Design:SetWidgetLabelColor(self.text, disabled)
		if disabled then
			self.frame:Disable()
			local r, g, b = self.btn:GetBackdropColor()
			self.btn:SetBackdropColor(r, g, b, .5)
			SetDesaturation(self.check, true)
		else
			self.frame:Enable()
			local r, g, b = self.btn:GetBackdropColor()
			self.btn:SetBackdropColor(r, g, b, 1)
			SetDesaturation(self.check, false)
		end
		
		if self.rightClickCallback and disabled then
			self.disabledFrame:Show()
		else
			self.disabledFrame:Hide()
		end
	end,

	["SetValue"] = function(self,value)
		local check = self.check
		self.checked = value
		SetDesaturation(self.check, false)
		if value then
			self.check:Show()
		else
			self.check:Hide()
		end
		self:SetDisabled(self.disabled)
	end,

	["GetValue"] = function(self)
		return self.checked
	end,

	["SetType"] = function(self, type)
		local check = self.check

		if type == "radio" then
			self.btn:SetWidth(10)
			self.btn:SetHeight(10)
			self.btn:SetPoint("TOPLEFT", 7, -7)
			self.check:SetPoint("TOPLEFT", -1, 5)
		else
			self.btn:SetWidth(16)
			self.btn:SetHeight(16)
			self.btn:SetPoint("TOPLEFT", 4, -4)
			self.check:SetPoint("TOPLEFT")
		end
	end,

	["ToggleChecked"] = function(self)
		self:SetValue(not self:GetValue())
	end,

	["SetLabel"] = function(self, label)
		self.text:SetText(label)
	end,
	
	["SetRightClickCallback"] = function(self, callback, tooltip)
		if callback then
			self.rightClickCallback = callback
			self.disabledTooltip = tooltip
		else
			self.rightClickCallback = nil
			self.disabledTooltip = nil
			self.disabledFrame:Hide()
		end
	end,
}


--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
	local frame = CreateFrame("Button", nil, UIParent)
	frame:Hide()
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:SetScript("OnMouseUp", Control_OnClick)
	frame:SetScript("OnMouseDown", CheckBox_OnMouseDown)
	frame:SetScript("OnMouseUp", CheckBox_OnMouseUp)

	local btn = CreateFrame("Button", nil, frame)
	btn:EnableMouse(false)
	btn:SetWidth(16)
	btn:SetHeight(16)
	btn:SetPoint("TOPLEFT", 4, -4)
	TSMAPI.Design:SetContentColor(btn)
	local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetTexture(1, 1, 1, .2)
	highlight:SetBlendMode("BLEND")

	local check = btn:CreateTexture(nil, "OVERLAY")
	check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:SetTexCoord(.12, .88, .12, .88)
	check:SetBlendMode("BLEND")
	check:SetPoint("BOTTOMRIGHT")

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetJustifyH("LEFT")
	text:SetHeight(18)
	text:SetPoint("LEFT", btn, "RIGHT")
	text:SetPoint("RIGHT")
	text:SetFont(TSMAPI.Design:GetContentFont("normal"))
	
	local disabledFrame = TSM:CreateWidgetDisabledFrame(frame)

	local widget = {
		btn		 = btn,
		check     = check,
		text      = text,
		highlight = highlight,
		frame     = frame,
		disabledFrame = disabledFrame,
		type      = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	disabledFrame.obj, frame.obj = widget, widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
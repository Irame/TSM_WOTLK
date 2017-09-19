-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Debug = TSM:GetModule("Debug")
local private = {frame=nil, defaultState={}}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Debug:ShowGUIHelper()
	local widget = GetMouseFocus()
	if not widget or widget == WorldFrame then return print("Nothing under cursor") end
	local numPoints = widget:GetNumPoints()
	if numPoints == 0 then return print("This widget has no points!") end
	if numPoints > 4 then return print("This widget has too many points!") end

	private:CreateHelperFrame()
	private.frame:Show()
	private.widget = widget
	local state = private:UpdateFromWidget()
	private.defaultState[private.widget] = private.defaultState[private.widget] or state

	if not private.highlightFrame then
		private.highlightFrame = CreateFrame("Frame")
		local tex = private.highlightFrame:CreateTexture()
		tex:SetColorTexture(0, 1, 1, 0.2)
		tex:SetAllPoints(private.highlightFrame)
		tex:SetBlendMode("BLEND")
	end
	private.highlightFrame:SetParent(private.widget)
	private.highlightFrame:SetAllPoints(private.widget)
	private.highlightFrame:SetFrameStrata("TOOLTIP")
	private.highlightFrame:Show()
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:CreateHelperFrame()
	if private.frame then return end

	local anchors = {
		TOPLEFT="TOPLEFT",
		TOPRIGHT="TOPRIGHT",
		BOTTOMLEFT="BOTTOMLEFT",
		BOTTOMRIGHT="BOTTOMRIGHT",
		TOP="TOP",
		BOTTOM="BOTTOM",
		LEFT="LEFT",
		RIGHT="RIGHT",
		CENTER="CENTER",
	}

	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		hidden = true,
		strata = "FULLSCREEN_DIALOG",
		size = {530, 285},
		points = {{"BOTTOMRIGHT", -100, 100}},
		scripts = {"OnMouseDown", "OnMouseUp"},
		children = {
			{
				type = "Text",
				text = format("TSM GUI Helper"),
				textFont = {TSMAPI.Design:GetContentFont(), 18},
				textColor = {0.6, 1, 1, 1},
				points = {{"TOP", BFC.PARENT, 0, -3}},
			},
			{
				type = "VLine",
				offset = 0,
				size = {2, 25},
				points = {{"TOPRIGHT", -25, -1}},
			},
			{
				type = "Button",
				key = "closeBtn",
				text = "X",
				textHeight = 18,
				size = {19, 19},
				points = {{"TOPRIGHT", -3, -3}},
				scripts = {"OnClick"},
			},
			{
				type = "HLine",
				offset = -24,
			},
			{
				type = "Text",
				text = "Width:",
				size = {0, 20},
				points = {{"TOPLEFT", 50, -30}},
			},
			{
				type = "InputBox",
				key = "widthInput",
				numeric = true,
				size = {50, 0},
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "Text",
				text = "Height:",
				size = {0, 20},
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 100, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
			},
			{
				type = "InputBox",
				key = "heightInput",
				numeric = true,
				size = {50, 0},
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "HLine",
				offset = -55,
			},
			-- Point 1
			{
				type = "Text",
				text = "1:",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 40},
				points = {{"TOPLEFT", 5, -60}},
			},
			{
				type = "Dropdown",
				key = "point1PointDropdown",
				label = "Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Dropdown",
				key = "point1RelPointDropdown",
				label = "Rel. Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Text",
				text = "X Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point1XInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "Text",
				text = "Y Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point1YInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "HLine",
				offset = -105,
			},
			-- Point 2
			{
				type = "Text",
				text = "2:",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 40},
				points = {{"TOPLEFT", 5, -110}},
			},
			{
				type = "Dropdown",
				key = "point2PointDropdown",
				label = "Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Dropdown",
				key = "point2RelPointDropdown",
				label = "Rel. Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Text",
				text = "X Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point2XInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "Text",
				text = "Y Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point2YInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "HLine",
				offset = -155,
			},
			-- Point 3
			{
				type = "Text",
				text = "3:",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 40},
				points = {{"TOPLEFT", 5, -160}},
			},
			{
				type = "Dropdown",
				key = "point3PointDropdown",
				label = "Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Dropdown",
				key = "point3RelPointDropdown",
				label = "Rel. Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Text",
				text = "X Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point3XInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "Text",
				text = "Y Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point3YInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "HLine",
				offset = -205,
			},
			-- Point 4
			{
				type = "Text",
				text = "4:",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 40},
				points = {{"TOPLEFT", 5, -210}},
			},
			{
				type = "Dropdown",
				key = "point4PointDropdown",
				label = "Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Dropdown",
				key = "point4RelPointDropdown",
				label = "Rel. Point",
				list = anchors,
				size = {150, 40},
				points = {{"LEFT", BFC.PREV, "RIGHT", 5, 0}},
			},
			{
				type = "Text",
				text = "X Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point4XInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "Text",
				text = "Y Offset:",
				size = {0, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 10, 0}},
			},
			{
				type = "InputBox",
				key = "point4YInput",
				size = {30, 25},
				points = {{"LEFT", BFC.PREV, "RIGHT", 2, 0}},
				scripts = {"OnTextChanged"},
			},
			{
				type = "HLine",
				offset = -255,
			},
			{
				type = "Button",
				key = "resetBtn",
				text = "Reset Widget to Original State",
				textHeight = 18,
				size = {0, 20},
				points = {{"BOTTOMLEFT", 5, 5}, {"BOTTOMRIGHT", -5, 5}},
				scripts = {"OnClick"},
			},
		},
		handlers = {
			OnMouseDown = function(self)
				self:StartMoving()
			end,
			OnMouseUp = function(self)
				self:StopMovingOrSizing()
			end,
			closeBtn = {
				OnClick = function(self)
					self:GetParent():Hide()
				end,
			},
			resetBtn = {
				OnClick = private.ResetState,
			},
			widthInput = {
				OnTextChanged = private.UpdateWidget,
			},
			heightInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point1XInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point1YInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point2XInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point2YInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point3XInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point3YInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point4XInput = {
				OnTextChanged = private.UpdateWidget,
			},
			point4YInput = {
				OnTextChanged = private.UpdateWidget,
			},
		},
	}
	private.frame = TSMAPI.GUI:BuildFrame(frameInfo)
	private.frame:SetMovable(true)
	private.frame:SetScale(UIParent:GetScale())
	TSMAPI.Design:SetFrameBackdropColor(private.frame)
end

function private:UpdateFromWidget()
	local state = {}
	state.width = TSMAPI.Util:Round(private.widget:GetWidth(), 1)
	state.height = TSMAPI.Util:Round(private.widget:GetHeight(), 1)
	private.frame.widthInput:SetNumber(state.width)
	private.frame.heightInput:SetNumber(state.height)
	for i=1, 4 do
		local point, relFrame, relPoint, x, y = private.widget:GetPoint(i)
		if point then
			state[i] = {point, relFrame, relPoint, x, y}
			private.frame["point"..i.."PointDropdown"]:SetDisabled(false)
			private.frame["point"..i.."RelPointDropdown"]:SetDisabled(false)
			private.frame["point"..i.."XInput"]:Enable()
			private.frame["point"..i.."YInput"]:Enable()
			private.frame["point"..i.."PointDropdown"]:SetValue(point)
			private.frame["point"..i.."RelPointDropdown"]:SetValue(relPoint)
			private.frame["point"..i.."XInput"]:SetText(TSMAPI.Util:Round(x, 1))
			private.frame["point"..i.."YInput"]:SetText(TSMAPI.Util:Round(y, 1))
		else
			private.frame["point"..i.."PointDropdown"]:SetDisabled(true)
			private.frame["point"..i.."RelPointDropdown"]:SetDisabled(true)
			private.frame["point"..i.."XInput"]:Disable()
			private.frame["point"..i.."YInput"]:Disable()
			private.frame["point"..i.."PointDropdown"]:SetValue()
			private.frame["point"..i.."RelPointDropdown"]:SetValue()
			private.frame["point"..i.."XInput"]:SetText("")
			private.frame["point"..i.."YInput"]:SetText("")
		end
	end
	return state
end

function private:UpdateWidget()
	private.widget:ClearAllPoints()
	private.widget:SetHeight(private.frame.heightInput:GetNumber())
	private.widget:SetWidth(private.frame.widthInput:GetNumber())
	for i=1, #private.defaultState[private.widget] do
		local point = private.frame["point"..i.."PointDropdown"]:GetValue()
		local relFrame = private.defaultState[private.widget][i][2]
		local relPoint = private.frame["point"..i.."RelPointDropdown"]:GetValue()
		local x = tonumber(private.frame["point"..i.."XInput"]:GetText()) or 0
		local y = tonumber(private.frame["point"..i.."YInput"]:GetText()) or 0
		private.widget:SetPoint(point, relFrame, relPoint, x, y)
	end
	private:UpdateFromWidget()
end

function private:ResetState()
	private.widget:ClearAllPoints()
	private.widget:SetHeight(private.defaultState[private.widget].height)
	private.widget:SetWidth(private.defaultState[private.widget].width)
	for i=1, #private.defaultState[private.widget] do
		private.widget:SetPoint(unpack(private.defaultState[private.widget][i]))
	end
	private:UpdateFromWidget()
end

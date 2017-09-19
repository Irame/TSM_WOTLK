-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

--[[-----------------------------------------------------------------------------
Group Item List Widget
Provides two scroll lists with buttons to move selected items from one list to the other.
-------------------------------------------------------------------------------]]
local TSM = select(2, ...)
local Type, Version = "TSMGroupItemList", 1
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local ROW_HEIGHT = 16


--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]

local function ShowIcon(row)
	row.iconFrame:Show()
	row.label:SetPoint("TOPLEFT", 20, 0)
	row.label:SetPoint("BOTTOMRIGHT")
end

local function HideIcon(row)
	row.iconFrame:Hide()
	row.label:SetPoint("TOPLEFT", 0, 0)
	row.label:SetPoint("BOTTOMRIGHT")
end

local function UpdateScrollFrame(self)
	local parent = self:GetParent()
	if not parent.obj.GetListCallback then return end
	if parent == parent.obj.leftFrame then
		-- it's the left scroll frame
		parent.items = parent.obj.GetListCallback("left", parent.obj.frame.leftTitle.index)
	else
		-- it's the right scroll frame
		parent.items = parent.obj.GetListCallback("right", parent.obj.frame.rightTitle.index)
	end
	if not parent.list then
		parent.list = {}
		local usedItems = {}
		for _, itemString in ipairs(parent.items) do
			local name = TSMAPI.Item:GetName(itemString)
			local link = TSMAPI.Item:GetLink(itemString)
			local texture = TSMAPI.Item:GetTexture(itemString)
			if itemString and name and texture and not usedItems[itemString] then
				usedItems[itemString] = true
				tinsert(parent.list, {value=itemString, link=link, icon=texture, sortText=strlower(name)})
			end
		end
		sort(parent.list, function(a, b) return a.sortText < b.sortText end)
	end

	local rows = self.rows
	-- clear all the rows
	for _, v in pairs(rows) do
		v.value = nil
		v.label:SetText("")
		v.iconFrame.icon:SetTexture("")
		v:Hide()
	end

	local rowData = {}
	for _, data in ipairs(self:GetParent().list) do
		if not data.filtered then
			tinsert(rowData, data)
		end
	end

	local maxRows = floor((self.height-5)/(ROW_HEIGHT+2))
	FauxScrollFrame_Update(self, #(rowData), maxRows-1, ROW_HEIGHT)
	local offset = FauxScrollFrame_GetOffset(self)
	local displayIndex = 0

	-- make the rows bigger if the scroller isn't showing
	if self:IsVisible() then
		rows[1]:SetPoint("TOPRIGHT", self:GetParent(), -26, 0)
	else
		rows[1]:SetPoint("TOPRIGHT", self:GetParent(), -10, 0)
	end

	for index, data in ipairs(rowData) do
		if index >= offset and displayIndex < maxRows then
			displayIndex = displayIndex + 1
			local row = rows[displayIndex]

			row.label:SetText(data.link)
			row.value = data.value
			row.data = data

			if data.selected then
				row:LockHighlight()
			else
				row:UnlockHighlight()
			end

			if data.icon then
				row.iconFrame.icon:SetTexture(data.icon)
				ShowIcon(row)
			else
				HideIcon(row)
			end
			row:Show()
		end
	end
end

local function UpdateRows(parent)
	local numRows = floor((parent.height-5)/(ROW_HEIGHT+2))
	parent.rows = parent.rows or {}
	for i=1, numRows do
		if not parent.rows[i] then
			local row = CreateFrame("Button", parent:GetName().."Row"..i, parent:GetParent())
			row:SetHeight(ROW_HEIGHT)
			row:SetScript("OnClick", function(self)
				self.data.selected = not self.data.selected
				if self.data.selected then
					self:LockHighlight()
				else
					self:UnlockHighlight()
				end
			end)
			row:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_NONE")
				GameTooltip:SetPoint("LEFT", parent:GetParent():GetParent(), "RIGHT")
				TSMAPI.Util:SafeTooltipLink(self.data.link)
				GameTooltip:Show()
			end)
			row:SetScript("OnLeave", function() GameTooltip:Hide() BattlePetTooltip:Hide() end)

			if i > 1 then
				row:SetPoint("TOPLEFT", parent.rows[i-1], "BOTTOMLEFT", 0, -2)
				row:SetPoint("TOPRIGHT", parent.rows[i-1], "BOTTOMRIGHT", 0, -2)
			else
				row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
				row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 4, 0)
			end

			-- highlight / selection texture for the row
			local highlightTex = row:CreateTexture()
			highlightTex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
			highlightTex:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
			highlightTex:SetPoint("BOTTOMLEFT")
			highlightTex:SetAlpha(0.7)
			row:SetHighlightTexture(highlightTex)

			-- icon that goes to the left of the text
			local iconFrame = CreateFrame("Frame", nil, row)
			iconFrame:SetHeight(ROW_HEIGHT-2)
			iconFrame:SetWidth(ROW_HEIGHT-2)
			iconFrame:SetPoint("TOPLEFT")
			row.iconFrame = iconFrame

			-- texture that goes inside the iconFrame
			local iconTexture = iconFrame:CreateTexture(nil, "BACKGROUND")
			iconTexture:SetAllPoints(iconFrame)
			iconTexture:SetVertexColor(1, 1, 1)
			iconFrame.icon = iconTexture

			local label = row:CreateFontString(nil, "OVERLAY")
			label:SetFont(TSMAPI.Design:GetContentFont("normal"))
			label:SetJustifyH("LEFT")
			label:SetJustifyV("CENTER")
			label:SetPoint("TOPLEFT", 20, 0)
			label:SetPoint("BOTTOMRIGHT", 10, 0)
			TSMAPI.Design:SetWidgetTextColor(label)
			row.label = label

			parent.rows[i] = row
		end
	end
	UpdateScrollFrame(parent)
end

local function OnButtonClick(self)
	local selected = {}
	local rows, rowData

	if self.type == "Add" then
		rows = self.obj.leftFrame.scrollFrame.rows
		rowData = self.obj.leftFrame.list
	elseif self.type == "Remove" then
		rows = self.obj.rightFrame.scrollFrame.rows
		rowData = self.obj.rightFrame.list
	end
	if not rows then error("Invalid type") end

	local temp = {}
	for _, row in pairs(rows) do
		if row.data and row.data.selected and row.value then
			row.data.selected = false
			row:UnlockHighlight()
			temp[row.value] = true
			tinsert(selected, row.value)
		end
	end

	for _, data in pairs(rowData) do
		if data.selected and data.value and not temp[data.value] then
			data.selected = false
			tinsert(selected, data.value)
		end
	end

	if self.type == "Add" then
		self.obj:Fire("OnAddClicked", selected)
	elseif self.type == "Remove" then
		self.obj:Fire("OnRemoveClicked", selected)
	end
end

local function OnFilterSet(self)
	self:ClearFocus()
	local text = strlower(self:GetText():trim())
	local filterInfo = TSMAPI.ItemFilter:Parse(text)
	if not filterInfo then
		TSM:Print("Invalid filter.")
		return
	end

	for _, list in ipairs({self.obj.leftFrame.list, self.obj.rightFrame.list}) do
		for _, info in ipairs(list) do
			local selected = TSMAPI.ItemFilter:MatchesFilter(filterInfo, info.link, TSMAPI:GetCustomPriceValue(TSM.db.profile.groupFilterPrice, TSMAPI.Item:ToItemString(info.link)))
			info.selected = selected
			info.filtered = not selected
		end
	end
	FauxScrollFrame_SetOffset(self.obj.leftFrame.scrollFrame, 0)
	FauxScrollFrame_SetOffset(self.obj.rightFrame.scrollFrame, 0)
	UpdateScrollFrame(self.obj.leftFrame.scrollFrame)
	UpdateScrollFrame(self.obj.rightFrame.scrollFrame)
end

local function OnClearButtonClicked(self)
	for _, info in ipairs(self.obj.leftFrame.list) do
		info.selected = false
	end
	for _, info in ipairs(self.obj.rightFrame.list) do
		info.selected = false
	end
	UpdateScrollFrame(self.obj.leftFrame.scrollFrame)
	UpdateScrollFrame(self.obj.rightFrame.scrollFrame)
end

local function OnIgnoreChanged(self, _, value)
	TSM.db.global.ignoreRandomEnchants = value
	self.obj.leftFrame.list = nil
	UpdateScrollFrame(self.obj.leftFrame.scrollFrame)
end


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(550)
		TSMAPI.Delay:AfterTime(0.05, function() self.parent:DoLayout() end)
		self.filter:SetText("")
		self.ignoreCheckBox:SetValue(TSM.db.global.ignoreRandomEnchants)
	end,

	["OnRelease"] = function(self)
		-- clear any points / other values
		wipe(self.leftFrame.list)
		wipe(self.rightFrame.list)
		self.frame.leftTitle.text:SetText("")
		self.frame.rightTitle.text:SetText("")
		self.frame.leftTitle.list = nil
		self.frame.rightTitle.list = nil
		self.frame.leftTitle.index = 1
		self.frame.rightTitle.index = 1
	end,

	["OnHeightSet"] = function(self, height)
		if height == 100 then return end
		self.leftScrollFrame.height = self.frame:GetHeight() - 85
		self.rightScrollFrame.height = self.frame:GetHeight() - 85
		UpdateRows(self.leftScrollFrame)
		UpdateRows(self.rightScrollFrame)
	end,

	["SetListCallback"] = function(self, callback)
		self.GetListCallback = callback
		self.leftFrame.list = nil
		self.rightFrame.list = nil
		UpdateScrollFrame(self.leftScrollFrame)
		UpdateScrollFrame(self.rightScrollFrame)
	end,

	["SetTitle"] = function(self, side, list)
		TSMAPI:Assert(side == "left" or side == "right")
		if strlower(side) == "left" then
			self.frame.leftTitle.list = list
			self.frame.leftTitle.index = 1
			self.frame.leftTitle.text:SetText(list[1] or "")
		elseif strlower(side) == "right" then
			self.frame.rightTitle.list = list
			self.frame.rightTitle.index = 1
			self.frame.rightTitle.text:SetText(list[1] or "")
		end
	end,
}


--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
	local name = "TSMGroupItemList" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:Hide()

	local leftFrame = CreateFrame("Frame", name.."LeftFrame", frame)
	leftFrame:SetPoint("TOPLEFT", 0, -80)
	leftFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -7, 0)
	TSMAPI.Design:SetContentColor(leftFrame)
	leftFrame.list = {}
	frame.leftFrame = leftFrame

	local leftTitle = CreateFrame("Button", nil, frame)
	leftTitle:SetPoint("BOTTOMLEFT", leftFrame, "TOPLEFT", 8, 0)
	leftTitle:SetPoint("BOTTOMRIGHT", leftFrame, "TOPRIGHT", -8, 0)
	leftTitle:SetHeight(15)
	leftTitle.text = leftTitle:CreateFontString()
	leftTitle.text:SetFont(TSMAPI.Design:GetContentFont("normal"))
	TSMAPI.Design:SetTitleTextColor(leftTitle.text)
	leftTitle.text:SetJustifyH("LEFT")
	leftTitle.text:SetJustifyV("BOTTOM")
	leftTitle.text:SetAllPoints()
	leftTitle:SetFontString(leftTitle.text)
	leftTitle:SetScript("OnClick", function(self)
		if not self.list or #self.list <= 1 then return end
		self:GetParent().leftFrame.list = nil
		self.index = (self.index % #self.list) + 1
		self.text:SetText(self.list[self.index])
		FauxScrollFrame_SetOffset(self:GetParent().obj.leftFrame.scrollFrame, 0)
		UpdateScrollFrame(self:GetParent().leftFrame.scrollFrame)
	end)
	leftTitle:SetScript("OnEnter", function(self)
		if not self.list or #self.list <= 1 then return end
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint("LEFT", self, "RIGHT")
		GameTooltip:AddLine(L["Click to change what is shown in this column."])
		GameTooltip:Show()
	end)
	leftTitle:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame.leftTitle = leftTitle

	local leftSF = CreateFrame("ScrollFrame", name.."LeftFrameScrollFrame", leftFrame, "FauxScrollFrameTemplate")
	leftSF:SetPoint("TOPLEFT", 5, -5)
	leftSF:SetPoint("BOTTOMRIGHT", -5, 5)
	leftSF:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() UpdateScrollFrame(self) end)
	end)
	leftFrame.scrollFrame = leftSF

	local leftScrollBar = _G[leftSF:GetName().."ScrollBar"]
	leftScrollBar:ClearAllPoints()
	leftScrollBar:SetPoint("BOTTOMRIGHT")
	leftScrollBar:SetPoint("TOPRIGHT")
	leftScrollBar:SetWidth(12)

	local thumbTex = leftScrollBar:GetThumbTexture()
	thumbTex:SetPoint("CENTER")
	TSMAPI.Design:SetFrameColor(thumbTex)
	thumbTex:SetHeight(150)
	thumbTex:SetWidth(leftScrollBar:GetWidth())
	_G[leftScrollBar:GetName().."ScrollUpButton"]:Hide()
	_G[leftScrollBar:GetName().."ScrollDownButton"]:Hide()

	local rightFrame = CreateFrame("Frame", name.."RightFrame", frame)
	rightFrame:SetPoint("TOPLEFT", frame, "TOP", 7, -80)
	rightFrame:SetPoint("BOTTOMRIGHT", 0, 0)
	TSMAPI.Design:SetContentColor(rightFrame)
	rightFrame.list = {}
	frame.rightFrame = rightFrame

	local rightTitle = CreateFrame("Button", nil, frame)
	rightTitle:SetPoint("BOTTOMLEFT", rightFrame, "TOPLEFT", 8, 0)
	rightTitle:SetPoint("BOTTOMRIGHT", rightFrame, "TOPRIGHT", -8, 0)
	rightTitle:SetHeight(15)
	rightTitle.text = rightTitle:CreateFontString()
	rightTitle.text:SetFont(TSMAPI.Design:GetContentFont("normal"))
	TSMAPI.Design:SetTitleTextColor(rightTitle.text)
	rightTitle.text:SetJustifyH("LEFT")
	rightTitle.text:SetJustifyV("BOTTOM")
	rightTitle.text:SetAllPoints()
	rightTitle:SetFontString(rightTitle.text)
	rightTitle:SetScript("OnClick", function(self)
		if not self.list or #self.list <= 1 then return end
		self:GetParent().rightFrame.list = nil
		self.index = (self.index % #self.list) + 1
		self.text:SetText(self.list[self.index])
		FauxScrollFrame_SetOffset(self:GetParent().rightFrame.scrollFrame, 0)
		UpdateScrollFrame(self:GetParent().rightFrame.scrollFrame)
	end)
	rightTitle:SetScript("OnEnter", function(self)
		if not self.list or #self.list <= 1 then return end
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint("LEFT", self, "RIGHT")
		GameTooltip:AddLine(L["Click to change what is shown in this column."])
		GameTooltip:Show()
	end)
	rightTitle:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame.rightTitle = rightTitle

	local rightSF = CreateFrame("ScrollFrame", name.."RightFrameScrollFrame", rightFrame, "FauxScrollFrameTemplate")
	rightSF:SetPoint("TOPLEFT", 5, -5)
	rightSF:SetPoint("BOTTOMRIGHT", -5, 5)
	rightSF:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() UpdateScrollFrame(self) end)
	end)
	rightFrame.scrollFrame = rightSF

	local rightScrollBar = _G[rightSF:GetName().."ScrollBar"]
	rightScrollBar:ClearAllPoints()
	rightScrollBar:SetPoint("BOTTOMRIGHT")
	rightScrollBar:SetPoint("TOPRIGHT")
	rightScrollBar:SetWidth(12)

	local thumbTex = rightScrollBar:GetThumbTexture()
	thumbTex:SetPoint("CENTER")
	TSMAPI.Design:SetFrameColor(thumbTex)
	thumbTex:SetHeight(150)
	thumbTex:SetWidth(rightScrollBar:GetWidth())
	_G[rightScrollBar:GetName().."ScrollUpButton"]:Hide()
	_G[rightScrollBar:GetName().."ScrollDownButton"]:Hide()


	local label = TSM.GUI:CreateLabel(frame, "normal")
	label:SetText(L["Filter:"])
	label:SetPoint("TOPLEFT", 0, -5)
	label:SetHeight(20)
	label:SetJustifyV("CENTER")

	local filter = TSM.GUI:CreateInputBox(frame)
	filter:SetPoint("BOTTOMLEFT", label, "BOTTOMRIGHT", 2, 0)
	filter:SetHeight(20)
	filter:SetWidth(150)
	filter:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	filter:SetScript("OnEditFocusLost", OnFilterSet)
	filter.tooltip = L["Here you can filter the item lists below. You can enter a simple string to filter by, or a more complex filter which includes item level, rarity, price, etc. Ex: '/weapon/i600/epic/100g/500g'"]

	local line = TSM.GUI:CreateHorizontalLine(frame, 0)
	line:SetPoint("TOPLEFT", 0, -58)
	line:SetPoint("TOPRIGHT", 0, -58)
	local line = TSM.GUI:CreateVerticalLine(frame, 0)
	line:ClearAllPoints()
	line:SetPoint("TOP", 0, -60)
	line:SetPoint("BOTTOM")

	local ignoreCheckBox = TSM.GUI:CreateCheckBox(frame, L["When checked, random enchants will be ignored for ungrouped items.\n\nNB: This will not affect parent group items that were already added with random enchants\n\nIf you have this checked when adding an ungrouped randomly enchanted item, it will act as all possible random enchants of that item."])
	ignoreCheckBox:SetLabel(L["Ignore Random Enchants on Ungrouped Items"])
	ignoreCheckBox:SetPoint("BOTTOMLEFT", filter, "BOTTOMRIGHT", 20, 5)
	ignoreCheckBox:SetPoint("TOPRIGHT", 0, -2)
	ignoreCheckBox:SetCallback("OnValueChanged", OnIgnoreChanged)

	local addBtn = TSM.GUI:CreateButton(frame, 18)
	addBtn:SetPoint("TOPLEFT", 0, -33)
	addBtn:SetWidth(170)
	addBtn:SetHeight(20)
	addBtn:SetText(L["Add >>>"])
	addBtn.type = "Add"
	addBtn:SetScript("OnClick", OnButtonClick)

	local removeBtn = TSM.GUI:CreateButton(frame, 18)
	removeBtn:SetPoint("TOPRIGHT", 0, -33)
	removeBtn:SetWidth(170)
	removeBtn:SetHeight(20)
	removeBtn:SetText(L["<<< Remove"])
	removeBtn.type = "Remove"
	removeBtn:SetScript("OnClick", OnButtonClick)
	removeBtn.tooltip = L["You can hold shift while clicking this button to leave the items in the parent group (if one exists) rather than removing from all groups."]

	local clearBtn = TSM.GUI:CreateButton(frame, 16)
	clearBtn:SetPoint("BOTTOMLEFT", addBtn, "BOTTOMRIGHT", 15, 0)
	clearBtn:SetPoint("BOTTOMRIGHT", removeBtn, "BOTTOMLEFT", -15, 0)
	clearBtn:SetHeight(20)
	clearBtn:SetText(L["Clear Selection"])
	clearBtn:SetScript("OnClick", OnClearButtonClicked)
	clearBtn.tooltip = L["Deselects all items in both columns."]


	local widget = {
		leftFrame = leftFrame,
		leftScrollFrame = leftSF,
		rightFrame = rightFrame,
		rightScrollFrame = rightSF,
		ignoreCheckBox = ignoreCheckBox,
		filter = filter,
		clearBtn = clearBtn,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	addBtn.obj = widget
	removeBtn.obj = widget
	widget.ignoreCheckBox.obj = widget
	widget.filter.obj = widget
	widget.clearBtn.obj = widget
	widget.leftFrame.obj = widget
	widget.rightFrame.obj = widget
	widget.frame.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

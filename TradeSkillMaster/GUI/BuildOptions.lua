-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {customPriceFrame=nil}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

-- goes through a page-table and draws out all the containers and widgets for that page
function TSMAPI.GUI:BuildOptions(container, pageTable)
	TSMAPI:Assert(container.Add)
	container:PauseLayout()
	for _, data in ipairs(pageTable) do
		TSM.AddGUIElement(container, data)
	end
	container:ResumeLayout()
	container:DoLayout()
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function TSM.AddGUIElement(parent, args)
	TSMAPI:Assert(type(args) == "table" and type(args.type) == "string")
	if args.type == "InlineGroup" or args.type == "SimpleGroup" or args.type == "ScrollFrame" then
		-- it's a container, so will have children
		local container = private:CreateContainer("TSM"..args.type, parent, args)
		if args.type == "InlineGroup" then
			container:HideTitle(not args.title)
			container:HideBorder(args.noBorder)
			container:SetBackdrop(args.backdrop)
		elseif args.type == "SimpleGroup" then
			if args.height then container:SetHeight(args.height) end
		end
		-- build the children
		TSMAPI.GUI:BuildOptions(container, args.children)
	elseif args.type == "Image" then
		local image = private:CreateWidget("TSMImage", parent, args)
		image:SetImage(args.image)
		image:SetSizeRatio(args.sizeRatio)
	elseif args.type == "Label" then
		local labelWidget = private:CreateWidget("TSMLabel", parent, args)
		labelWidget:SetColor(args.colorRed, args.colorGreen, args.colorBlue)
	elseif args.type == "MultiLabel" then
		local labelWidget = private:CreateWidget("TSMMultiLabel", parent, args)
		labelWidget:SetLabels(args.labelInfo)
	elseif args.type == "InteractiveLabel" then
		local iLabelWidget = private:CreateWidget("TSMInteractiveLabel", parent, args)
		iLabelWidget:SetCallback("OnClick", args.callback)
	elseif args.type == "Button" then
		local buttonWidget = private:CreateWidget("TSMButton", parent, args)
		buttonWidget:SetCallback("OnClick", args.callback)
	elseif args.type == "GroupItemList" then
		local groupItemList = private:CreateWidget("TSMGroupItemList", parent, args)
		groupItemList:SetTitle("left", args.leftTitle)
		groupItemList:SetTitle("right", args.rightTitle)
		groupItemList:SetListCallback(args.listCallback)
		groupItemList:SetCallback("OnAddClicked", args.OnAddClicked)
		groupItemList:SetCallback("OnRemoveClicked", args.OnRemoveClicked)
	elseif args.type == "MacroButton" then
		local macroButtonWidget = private:CreateWidget("TSMMacroButton", parent, args)
		macroButtonWidget.frame:SetAttribute("type", "macro")
		macroButtonWidget.frame:SetAttribute("macrotext", args.macroText)
	elseif args.type == "EditBox" then
		local editBoxWidget = private:CreateWidget("TSMEditBox", parent, args)
		editBoxWidget:SetText(args.value)
		editBoxWidget:DisableButton(args.onTextChanged)
		editBoxWidget:SetAutoComplete(args.autoComplete)
		local function callback(self, event, value)
			if args.acceptCustom then
				local badPriceSource = type(args.acceptCustom) == "string" and strlower(args.acceptCustom)
				local isValid, err = TSMAPI:ValidateCustomPrice(value, badPriceSource)
				if isValid then
					self:SetText(private:FormatCopperCustomPrice(value))
					self:ClearFocus()
					args.callback(self, event, value)
				else
					TSM:Print(L["Invalid custom price."].." "..err)
					self:SetFocus()
				end
			else
				args.callback(self, event, value)
			end
		end
		editBoxWidget:SetCallback(args.onTextChanged and "OnTextChanged" or "OnEnterPressed", callback)
		if args.acceptCustom then
			private:CreateCustomPriceFrame()
			editBoxWidget:SetCallback("OnEditFocusGained", function() private.customPriceFrame:Show() end)
			editBoxWidget:SetCallback("OnEditFocusLost", function() private.customPriceFrame:Hide() end)
		end
	elseif args.type == "GroupBox" then
		local groupBoxWidget = private:CreateWidget("TSMGroupBox", parent, args)
		groupBoxWidget:SetText(args.value)
		groupBoxWidget:SetCallback("OnValueChanged", args.callback)
	elseif args.type == "CheckBox" then
		local checkBoxWidget = private:CreateWidget("TSMCheckBox", parent, args)
		checkBoxWidget:SetType(args.cbType or "checkbox")
		checkBoxWidget:SetValue(args.value)
		if args.label then checkBoxWidget:SetLabel(args.label) end
		checkBoxWidget:SetCallback("OnValueChanged", args.callback)
	elseif args.type == "Slider" then
		local sliderWidget = private:CreateWidget("TSMSlider", parent, args)
		sliderWidget:SetValue(args.value)
		sliderWidget:SetSliderValues(args.min, args.max, args.step)
		sliderWidget:SetIsPercent(args.isPercent)
		sliderWidget:SetCallback("OnValueChanged", args.callback)
	elseif args.type == "Icon" then
		local iconWidget = private:CreateWidget("Icon", parent, args)
		iconWidget:SetImage(args.image)
		iconWidget:SetImageSize(args.imageWidth, args.imageHeight)
		iconWidget:SetCallback("OnClick", args.callback)
	elseif args.type == "Dropdown" then
		local dropdownWidget = private:CreateWidget("TSMDropdown", parent, args)
		dropdownWidget:SetList(args.list, args.order)
		dropdownWidget:SetMultiselect(args.multiselect)
		if type(args.value) == "table" then
			for name, value in pairs(args.value) do
				dropdownWidget:SetItemValue(name, value)
			end
		else
			dropdownWidget:SetValue(args.value)
		end
		dropdownWidget:SetCallback("OnValueChanged", args.callback)
	elseif args.type == "ScrollingTable" then
		local st = AceGUI:Create("TSMScrollingTable")
		st:SetFullWidth(true)
		st:SetTag(args.tag)
		st:SetColInfo(args.colInfo)
		st:SetHandler(args.handlers)
		if args.defaultSort then
			st:EnableSorting(true, args.defaultSort)
		else
			st:EnableSorting()
		end
		st:DisableSelection(args.selectionDisabled)
		parent:AddChild(st)
	elseif args.type == "ColorPicker" then
		local colorPicker = private:CreateWidget("TSMColorPicker", parent, args)
		colorPicker:SetHasAlpha(args.hasAlpha)
		if type(args.value) == "table" then
			colorPicker:SetColor(unpack(args.value))
		end
		colorPicker:SetCallback("OnValueChanged", args.callback)
		colorPicker:SetCallback("OnValueConfirmed", args.callback)
	elseif args.type == "Spacer" then
		args.quantity = args.quantity or 1
		for i=1, args.quantity do
			parent:Add({type="Label", text=" ", relativeWidth=1})
		end
	elseif args.type == "HeadingLine" then
		local heading = AceGUI:Create("Heading")
		heading:SetText("")
		heading:SetRelativeWidth(args.relativeWidth or 1)
		parent:AddChild(heading)
	else
		TSMAPI:Assert(false, "Invalid widget type: "..args.type)
	end
end



-- ============================================================================
-- Custom TSM AceGUI Layouts
-- ============================================================================

local function TSMFillListLayout(content, children)
	local height = 0
	local width = content.width or content:GetWidth() or 0
	for i = 1, #children do
		local child = children[i]
		
		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()
		if i == 1 then
			frame:SetPoint("TOPLEFT", content)
		else
			frame:SetPoint("TOPLEFT", children[i-1].frame, "BOTTOMLEFT")
		end
		
		if i == #children then
			frame:SetPoint("BOTTOMLEFT", content)
		end
		
		if child.width == "fill" then
			child:SetWidth(width)
			frame:SetPoint("RIGHT", content)
			
			if child.DoLayout then
				child:DoLayout()
			end
		elseif child.width == "relative" then
			child:SetWidth(width * child.relWidth)
			
			if child.DoLayout then
				child:DoLayout()
			end
		end
		
		height = height + (frame.height or frame:GetHeight() or 0)
	end
	content.obj.LayoutFinished(content.obj, nil, height)
end
AceGUI:RegisterLayout("TSMFillList", TSMFillListLayout)



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:CreateCustomPriceFrame()
	if private.customPriceFrame then return end
	local customPriceSources = {}
	for name in pairs(TSM.db.global.customPriceSources) do
		tinsert(customPriceSources, name)
	end
	if #customPriceSources == 0 then
		tinsert(customPriceSources, "<None>")
	end
	
	local frameInfo = {
		type = "Frame",
		parent = TSMMainFrame1,
		hidden = true,
		size = {300, 500},
		points = {{"TOPLEFT", TSMMainFrame1, "TOPRIGHT", 2, 0}},
		children = {
			{
				type = "Text",
				text = L["Below are various ways you can set the value of the current editbox. Any combination of these methods is also supported."],
				size = {0, 55},
				points = {{"TOPLEFT", 5, -5}, {"TOPRIGHT", -5, -5}},
			},
			{
				type = "HLine",
				offset = -65,
			},
			{
				type = "Text",
				text = TSMAPI.Design:GetInlineColor("category")..L["Fixed Gold Value"].."|r",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -70}, {"TOPRIGHT", -5, -70}},
			},
			{
				type = "Text",
				text = L["A simple, fixed gold amount."],
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -95}, {"TOPRIGHT", -5, -95}},
			},
			{
				type = "HLine",
				offset = -120,
			},
			{
				type = "Text",
				text = TSMAPI.Design:GetInlineColor("category")..L["Percent of Price Source"].."|r",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -125}, {"TOPRIGHT", -5, -125}},
			},
			{
				type = "Text",
				text = L["Type '/tsm sources' to print out all available price sources."],
				justify = {"LEFT", "MIDDLE"},
				size = {0, 35},
				points = {{"TOPLEFT", 5, -150}, {"TOPRIGHT", -5, -150}},
			},
			{
				type = "HLine",
				offset = -190,
			},
			{
				type = "Text",
				text = TSMAPI.Design:GetInlineColor("category")..L["More Advanced Methods"].."|r",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -195}, {"TOPRIGHT", -5, -195}},
			},
			{
				type = "Text",
				text = L["See the following URL for more info."].."\n"..TSMAPI.Design:GetInlineColor("link").."https://tradeskillmaster.com/addon/custom-price|r",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 35},
				points = {{"TOPLEFT", 5, -220}, {"TOPRIGHT", -5, -220}},
			},
			{
				type = "HLine",
				offset = -260,
			},
			{
				type = "Text",
				text = TSMAPI.Design:GetInlineColor("category")..L["Examples"].."|r",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -265}, {"TOPRIGHT", -5, -265}},
			},
			{
				type = "Text",
				text = "20g50s",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -290}, {"TOPRIGHT", -5, -290}},
			},
			{
				type = "Text",
				text = "120% crafting",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -310}, {"TOPRIGHT", -5, -310}},
			},
			{
				type = "Text",
				text = "100% vendorSell + 5g",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -330}, {"TOPRIGHT", -5, -330}},
			},
			{
				type = "Text",
				text = "max(150% dbmarket, 1.2 * crafting)",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -350}, {"TOPRIGHT", -5, -350}},
			},
			{
				type = "Text",
				text = "max(vendorBuy, 120% crafting)",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -370}, {"TOPRIGHT", -5, -370}},
			},
			{
				type = "HLine",
				offset = -395,
			},
			{
				type = "Text",
				text = TSMAPI.Design:GetInlineColor("category")..L["Custom Price Sources"].."|r",
				justify = {"LEFT", "MIDDLE"},
				size = {0, 20},
				points = {{"TOPLEFT", 5, -400}, {"TOPRIGHT", -5, -400}},
			},
			{
				type = "Text",
				text = table.concat(customPriceSources, ","),
				justify = {"LEFT", "TOP"},
				size = {0, 60},
				points = {{"TOPLEFT", 5, -425}, {"TOPRIGHT", -5, -425}},
			},
		},
	}
	
	private.customPriceFrame = TSMAPI.GUI:BuildFrame(frameInfo)
	TSMAPI.Design:SetFrameBackdropColor(private.customPriceFrame)
end

function private:FormatCopperCustomPrice(value)
	value = gsub(value, TSMAPI.Util:StrEscape(TSM.GOLD_TEXT), "g")
	value = gsub(value, TSMAPI.Util:StrEscape(TSM.SILVER_TEXT), "s")
	value = gsub(value, TSMAPI.Util:StrEscape(TSM.COPPER_TEXT), "c")
	
	for copperPart in gmatch(value,"([0-9]+c)") do
		value = gsub(value, copperPart, gsub(copperPart, "c", TSM.COPPER_TEXT))
	end
	
	for silverPart in gmatch(value,"([0-9]+s)") do
		value = gsub(value, silverPart, gsub(silverPart, "s", TSM.SILVER_TEXT))
	end
	
	for goldPart in gmatch(value,"([0-9]+g)") do
		value = gsub(value, goldPart, gsub(goldPart, "g", TSM.GOLD_TEXT))
	end
	
	return value
end

function private:CreateContainer(cType, parent, args)
	local container = AceGUI:Create(cType)
	if not container then return end
	container:SetLayout(args.layout)
	if args.title then container:SetTitle(args.title) end
	container:SetRelativeWidth(args.relativeWidth or 1)
	container:SetFullHeight(args.fullHeight)
	parent:AddChild(container)
	return container
end

function private:CreateWidget(wType, parent, args)
	local widget = AceGUI:Create(wType)
	if args.settingInfo then
		args.value = args.value or args.settingInfo[1][args.settingInfo[2]]
		if args.acceptCustom then
			if tonumber(args.value) then
				args.value = TSMAPI:MoneyToString(args.value)
			elseif args.value then
				args.value = private:FormatCopperCustomPrice(args.value)
			end
		end
		local oldCallback = args.callback
		args.callback = function(...)
			local value = select(3, ...)
			if type(value) == "string" then value = value:trim() end
			if args.multiselect then
				local key = value
				value = select(4, ...)
				args.settingInfo[1][args.settingInfo[2]][key] = value
			else
				args.settingInfo[1][args.settingInfo[2]] = value
			end
			if oldCallback then oldCallback(...) end
		end
	end
	if args.text then widget:SetText(args.text) end
	if args.label then widget:SetLabel(args.label) end
	if args.width then
		widget:SetWidth(args.width)
	elseif args.relativeWidth then
		if args.relativeWidth == 1 then
			widget:SetFullWidth(true)
		else
			widget:SetRelativeWidth(args.relativeWidth-0.001)
		end
	else
		-- default to a 0.5 relative width
		widget:SetRelativeWidth(0.4999)
	end
	if args.height then widget:SetHeight(args.height) end
	if widget.SetDisabled then widget:SetDisabled(args.disabled) end
	if args.tooltip then
		-- add code for the tooltip
		widget:SetCallback("OnEnter", function(self)
			GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
			GameTooltip:SetPoint("BOTTOM", self.frame, "TOP")
			if args.label then
				GameTooltip:SetText(args.label, 1, .82, 0, 1)
			end
			if type(args.tooltip) == "number" then
				GameTooltip:SetHyperlink("item:" .. args.tooltip)
			elseif tonumber(args.tooltip) then
				GameTooltip:SetHyperlink("enchant:"..args.tooltip)
			elseif type(args.tooltip) == "string" and (strfind(args.tooltip, "i:") or strfind(args.tooltip, "p:")) then
				TSMAPI.Util:SafeTooltipLink(args.tooltip)
			else
				GameTooltip:AddLine(args.tooltip, 1, 1, 1, 1)
			end
			GameTooltip:Show()
		end)
		widget:SetCallback("OnLeave", function()
			BattlePetTooltip:Hide()
			GameTooltip:Hide()
		end)
	end
	parent:AddChild(widget)
	return widget
end
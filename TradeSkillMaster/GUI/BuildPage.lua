local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local lib = TSMAPI


--[[-----------------------------------------------------------------------------
TSMAPI:BuildPage() Support Functions
-------------------------------------------------------------------------------]]

local function AddTooltip(widget, text, title)
	if not text then return end
	widget:SetCallback("OnEnter", function(self)
			GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
			GameTooltip:SetPoint("BOTTOM", self.frame, "TOP")
			if title then
				GameTooltip:SetText(title, 1, .82, 0, 1)
			end
			if type(text) == "number" then
				GameTooltip:SetHyperlink("item:" .. text)
			elseif tonumber(text) then
				GameTooltip:SetHyperlink("enchant:"..text)
			else
				GameTooltip:AddLine(text, 1, 1, 1, 1)
			end
			GameTooltip:Show()
		end)
	widget:SetCallback("OnLeave", function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
end

local function CreateContainer(cType, parent, args)
	local container = AceGUI:Create(cType)
	if not container then print(cType, parent, args) end
	container:SetLayout(args.layout)
	if args.title then container:SetTitle(args.title) end
	container:SetRelativeWidth(args.relativeWidth or 1)
	container:SetFullHeight(args.fullHeight)
	parent:AddChild(container)
	return container
end

local function CreateWidget(wType, parent, args)
	local widget = AceGUI:Create(wType)
	if args.onRightClick then
		widget:SetRightClickCallback(args.onRightClick, args.disabledTooltip)
	end
	if args.text then widget:SetText(args.text) end
	if args.label then widget:SetLabel(args.label) end
	if args.fullWidth then
		widget:SetFullWidth(args.fullWidth)
	elseif args.width then
		widget:SetWidth(args.width)
	elseif args.relativeWidth then
		widget:SetRelativeWidth(args.relativeWidth)
	end
	if args.height then widget:SetHeight(args.height) end
	if widget.SetDisabled then widget:SetDisabled(args.disabled) end
	AddTooltip(widget, args.tooltip, args.label)
	parent:AddChild(widget)
	return widget
end

local Add = {
	InlineGroup = function(parent, args)
			local container = CreateContainer("TSMInlineGroup", parent, args)
			container:HideTitle(not args.title)
			container:HideBorder(args.noBorder)
			container:SetBackdrop(args.backdrop)
			return container
		end,
		
	SimpleGroup = function(parent, args)
			local container = CreateContainer("TSMSimpleGroup", parent, args)
			if args.height then container:SetHeight(args.height) end
			return container
		end,
		
	ScrollFrame = function(parent, args)
			return CreateContainer("TSMScrollFrame", parent, args)
		end,
		
	Label = function(parent, args)
			local labelWidget = CreateWidget("TSMLabel", parent, args)
			labelWidget:SetColor(args.colorRed, args.colorGreen, args.colorBlue)
			return labelWidget
		end,
		
	MultiLabel = function(parent, args)
			local labelWidget = CreateWidget("TSMMultiLabel", parent, args)
			labelWidget:SetLabels(args.labelInfo)
			return labelWidget
		end,
		
	InteractiveLabel = function(parent, args)
			local iLabelWidget = CreateWidget("TSMInteractiveLabel", parent, args)
			iLabelWidget:SetCallback("OnClick", args.callback)
			return iLabelWidget
		end,
		
	Button = function(parent, args)
			local buttonWidget = CreateWidget("TSMButton", parent, args)
			buttonWidget:SetCallback("OnClick", args.callback)
			return buttonWidget
		end,
		
	SelectionList = function(parent, args)
			local selectionList = CreateWidget("TSMSelectionList", parent, args)
			selectionList:SetList("left", args.leftList)
			selectionList:SetTitle("left", args.leftTitle)
			selectionList:SetList("right", args.rightList)
			selectionList:SetTitle("right", args.rightTitle)
			selectionList:SetTitle("filter", args.filterTitle)
			selectionList:SetTitle("filterTooltip", args.filterTooltip)
			selectionList:SetCallback("OnAddClicked", args.onAdd)
			selectionList:SetCallback("OnRemoveClicked", args.onRemove)
			selectionList:SetCallback("OnFilterEntered", args.onFilter)
			return selectionList
		end,
		
	--added by Geemoney 9-12-11
	DestroyButton = function(parent, args)
			local buttonWidget = CreateWidget("TSMFastDestroyButton", parent, args)
			buttonWidget:SetMode(args.mode)
			buttonWidget:SetSpell(args.spell)
			buttonWidget:SetLocationsFunc(args.locfunction)
			buttonWidget:SetCallback("OnClick", args.callback)
			buttonWidget:SetCallback("PreClick", args.preclick)
			buttonWidget:SetCallback("PostClick", args.postclick)
			buttonWidget:SetCallback("OnEnter", args.onenter)
			buttonWidget:SetCallback("OnLeave", args.onleave)
			return buttonWidget
		end,
		
	MacroButton = function(parent, args)
			local macroButtonWidget = CreateWidget("TSMMacroButton", parent, args)
			macroButtonWidget.frame:SetAttribute("type", "macro")
			macroButtonWidget.frame:SetAttribute("macrotext", args.macroText)
			return macroButtonWidget
		end,
	
	EditBox = function(parent, args)
			local editBoxWidget = CreateWidget("TSMEditBox", parent, args)
			editBoxWidget:SetText(args.value)
			editBoxWidget:DisableButton(args.onTextChanged)
			editBoxWidget:SetCallback(args.onTextChanged and "OnTextChanged" or "OnEnterPressed", args.callback)
			return editBoxWidget
		end,
		
	CheckBox = function(parent, args)
			local checkBoxWidget = CreateWidget("TSMCheckBox", parent, args)
			
			if args.quickCBInfo then
				args.value = args.value or args.quickCBInfo[1][args.quickCBInfo[2]]
				local oldCallback = args.callback
				args.callback = function(...)
					args.quickCBInfo[1][args.quickCBInfo[2]] = select(3, ...)
					if oldCallback then oldCallback(...) end
				end
			end
			
			checkBoxWidget:SetType(args.cbType or "checkbox")
			checkBoxWidget:SetValue(args.value)
			if args.label then checkBoxWidget:SetLabel(args.label) end
			if not args.fullWidth and not args.width and not args.relativeWidth then
				checkBoxWidget:SetRelativeWidth(0.5)
			end
			checkBoxWidget:SetCallback("OnValueChanged", args.callback)
			return checkBoxWidget
		end,
		
	Slider = function(parent, args)
			local sliderWidget = CreateWidget("TSMSlider", parent, args)
			sliderWidget:SetValue(args.value)
			sliderWidget:SetSliderValues(args.min, args.max, args.step)
			sliderWidget:SetIsPercent(args.isPercent)
			sliderWidget:SetCallback("OnValueChanged", args.callback)
			return sliderWidget
		end,
		
	Icon = function(parent, args)
			local iconWidget = CreateWidget("Icon", parent, args)
			iconWidget:SetImage(args.image)
			iconWidget:SetImageSize(args.imageWidth, args.imageHeight)
			iconWidget:SetCallback("OnClick", args.callback)
			return iconWidget
		end,
		
	Dropdown = function(parent, args)
			local dropdownWidget = CreateWidget("TSMDropdown", parent, args)
			dropdownWidget:SetList(args.list)
			dropdownWidget:SetMultiselect(args.multiselect)
			if type(args.value) == "table" then
				for name, value in pairs(args.value) do
					dropdownWidget:SetItemValue(name, value)
				end
			else
				dropdownWidget:SetValue(args.value)
			end
			dropdownWidget:SetCallback("OnValueChanged", args.callback)
			return dropdownWidget
		end,
		
	ColorPicker = function(parent, args)
			local colorPicker = CreateWidget("TSMColorPicker", parent, args)
			colorPicker:SetHasAlpha(args.hasAlpha)
			if type(args.value) == "table" then
				colorPicker:SetColor(unpack(args.value))
			end
			colorPicker:SetCallback("OnValueChanged", args.callback)
			colorPicker:SetCallback("OnValueConfirmed", args.callback)
			return colorPicker
		end,
		
	Spacer = function(parent, args)
			args.quantity = args.quantity or 1
			for i=1, args.quantity do
				local spacer = parent:Add({type="Label", text=" ", fullWidth=true})
			end
		end,
		
	HeadingLine = function(parent, args)
			local heading = AceGUI:Create("Heading")
			heading:SetText("")
			heading:SetRelativeWidth(args.relativeWidth or 1)
			parent:AddChild(heading)
		end,
}

-- creates a widget or container as detailed in the passed table (iTable) and adds it as a child of the passed parent
function lib.AddGUIElement(parent, iTable)
	assert(Add[iTable.type], "Invalid Widget or Container Type: "..iTable.type)
	return Add[iTable.type](parent, iTable)
end

-- goes through a page-table and draws out all the containers and widgets for that page
function lib:BuildPage(oContainer, oPageTable, noPause)
	local function recursive(container, pageTable)
		for _, data in pairs(pageTable) do
			local parentElement = container:Add(data)
			if data.children then
				parentElement:PauseLayout()
				-- yay recursive function calls!
				recursive(parentElement, data.children)
				parentElement:ResumeLayout()
				parentElement:DoLayout()
			end
		end
	end
	if not oContainer.Add then
		local container = AceGUI:Create("TSMSimpleGroup")
		container:SetLayout("fill")
		container:SetFullWidth(true)
		container:SetFullHeight(true)
		oContainer:AddChild(container)
		oContainer = container
	end
	if not noPause then
		oContainer:PauseLayout()
		recursive(oContainer, oPageTable)
		oContainer:ResumeLayout()
		oContainer:DoLayout()
	else
		recursive(oContainer, oPageTable)
	end
end
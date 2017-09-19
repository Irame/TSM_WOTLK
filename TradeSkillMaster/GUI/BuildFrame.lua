-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {frameInfo={}, CONSTANTS={PARENT={},PREV={}}}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.GUI:BuildFrame(info)
	-- create the widget
	local widget
	if info.type == "MovableFrame" then
		widget = TSM.GUI:CreateMovableFrame(info.name, info.movableDefaults)
		if info.minResize then
			widget:SetResizable(true)
			widget:SetMinResize(unpack(info.minResize))
		end
	elseif info.type == "Frame" then
		widget = CreateFrame("Frame", info.name, info.parent)
		if info.strata then
			widget:SetFrameStrata(info.strata)
		end
		widget:EnableMouse(info.mouse)
	elseif info.type == "Dropdown" then
		widget = TSM.GUI:CreateDropdown(info.parent, info.list, info.tooltip)
		widget:SetLabel(info.label)
		widget:SetMultiselect(info.multiselect)
		widget:SetValue(info.value)
	elseif info.type == "Button" then
		TSMAPI:Assert(info.textHeight, "Buttons require a textHeight:"..private:GetDebugString(info))
		widget = TSM.GUI:CreateButton(info.parent, info.textHeight, info.name, info.isSecure)
		if info.clicks then
			widget:RegisterForClicks(info.clicks)
		end
		widget.tooltip = info.tooltip
		TSMAPI:Assert(info.scripts, "Button without scripts: "..private:GetDebugString(info))
	elseif info.type == "InputBox" then
		widget = TSM.GUI:CreateInputBox(info.parent, info.name)
		widget:SetNumeric(info.numeric)
		if info.justify then
			widget:SetJustifyH(info.justify[1] or "LEFT")
			widget:SetJustifyV(info.justify[2] or "MIDDLE")
		end
		if info.autoComplete then
			TSM.GUI:SetAutoComplete(widget, info.autoComplete)
		end
	elseif info.type == "HLine" then
		widget = TSM.GUI:CreateHorizontalLine(info.parent, info.offset, info.relativeFrame, info.invertedColor)
	elseif info.type == "VLine" then
		widget = TSM.GUI:CreateVerticalLine(info.parent, info.offset, info.relativeFrame, info.invertedColor)
	elseif info.type == "ScrollingTable" then
		widget = TSM:CreateScrollingTable(info.parent)
		widget:SetColInfo(info.stCols)
		widget:SetHeadFontSize(info.headFontSize)
		widget:DisableSelection(info.stDisableSelection)
		widget:DisableHighlight(info.stDisableHighlight)
		if info.sortInfo then
			widget:EnableSorting(unpack(info.sortInfo))
		end
		widget:SetData({})
	elseif info.type == "ScrollingTableFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		TSMAPI.Design:SetFrameColor(widget)
		info._stTemp = {}
		for _, key in ipairs({"scripts", "handlers", "key", "stCols", "headFontSize", "stDisableSelection", "sortInfo"}) do
			info._stTemp[key] = info[key]
			info[key] = nil
		end
		if info._stTemp.key then
			info.key = info._stTemp.key.."Container"
		end
	elseif info.type == "GroupTreeFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		TSMAPI.Design:SetFrameColor(widget)
		if info.parent and info.key then
			info._gtKey = info.key
			info.key = info.key.."Container"
		end
	elseif info.type == "AuctionResultsTable" then
		widget = TSM:CreateAuctionResultsTable(info.parent)
		widget:SetSort(info.sortIndex)
		widget:Clear()
	elseif info.type == "AuctionResultsTableFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		info._rtTemp = {}
		for _, key in ipairs({"scripts", "handlers", "key", "sortIndex"}) do
			info._rtTemp[key] = info[key]
			info[key] = nil
		end
		if info._rtTemp.key then
			info.key = info._rtTemp.key.."Container"
		end
	elseif info.type == "StatusBarFrame" then
		TSMAPI:Assert(type(info.name) == "string", "Widget requires a name: "..info.type..private:GetDebugString(info))
		widget = CreateFrame("Frame", nil, info.parent)
		if info.parent and info.key then
			info._sbKey = info.key
			info.key = info.key.."Container"
		end
	elseif info.type == "IconButton" then
		widget = CreateFrame("Button", info.name, info.parent)
		widget.icon = widget:CreateTexture()
		widget.icon:SetAllPoints()
		widget.SetTexture = function(self, ...) self.icon:SetTexture(...) end
		if info.icon then
			widget:SetTexture(info.icon)
		end
	elseif info.type == "Text" then
		widget = TSM.GUI:CreateLabel(info.parent, info.textSize)
		widget:SetTextColor(1, 1, 1, 1)
		if info.justify then
			widget:SetJustifyH(info.justify[1] or "CENTER")
			widget:SetJustifyV(info.justify[2] or "MIDDLE")
		end
		if info.textHeight and not info.textFont and not info.textSize then
			widget:SetFont(TSMAPI.Design:GetContentFont(), info.textHeight)
		end
	elseif info.type == "TextureButton" then
		widget = CreateFrame("Button", info.name, info.parent)
		widget:SetNormalTexture(info.normalTexture)
		widget:SetPushedTexture(info.pushedTexture)
		widget:SetDisabledTexture(info.disabledTexture)
		widget:SetHighlightTexture(info.highlightTexture)
	elseif info.type == "MoneyInputBox" then
		TSMAPI:Assert(type(info.name) == "string", "Widget requires a name: "..info.type..private:GetDebugString(info))
		widget = CreateFrame("Frame", info.name, info.parent, "MoneyInputFrameTemplate")
		widget.SetCopper = MoneyInputFrame_SetCopper
		widget.GetCopper = MoneyInputFrame_GetCopper
	elseif info.type == "ItemLinkLabel" then
		TSMAPI:Assert(not info.scripts, "Scripts are not supported for ItemLinkLabels"..private:GetDebugString(info))
		widget = CreateFrame("Button", nil, info.parent)
		widget:SetScript("OnEnter", function(self) if self.link then GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT") TSMAPI.Util:SafeTooltipLink(self.link) GameTooltip:Show() end end)
		widget:SetScript("OnLeave", function() BattlePetTooltip:Hide() GameTooltip:Hide() end)
		widget:SetScript("OnClick", function(self) if self.link then HandleModifiedItemClick(self.link) end end)
		widget:SetHeight(info.textHeight)
		widget:Show()
		local text = widget:CreateFontString()
		text:SetAllPoints()
		if not info.textFont then
			text:SetFont(TSMAPI.Design:GetContentFont(), info.textHeight)
		end
		if info.justify then
			text:SetJustifyH(info.justify[1] or "CENTER")
			text:SetJustifyV(info.justify[2] or "MIDDLE")
		end
		widget:SetFontString(text)
	elseif info.type == "WidgetVList" then
		widget = {}
		TSMAPI:Assert(info.repeatCount and info.repeatCount > 1, "repeatCount must be > 1"..private:GetDebugString(info))
	elseif info.type == "CheckBox" then
		widget = TSM.GUI:CreateCheckBox(info.parent, info.tooltip)
		widget:SetLabel(info.label)
		widget:SetValue(info.value)
	elseif info.type == "TSMLogo" then
		TSMAPI:Assert(not info.scripts, "No scripts are allowed for the TSMLogo type!")
		widget = CreateFrame("Frame", nil, info.parent)
		local icon = widget:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexture("Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon_Big")
		local ag = widget:CreateAnimationGroup()
		local spin = ag:CreateAnimation("Rotation")
		spin:SetOrder(1)
		spin:SetDuration(2)
		spin:SetDegrees(90)
		local spin = ag:CreateAnimation("Rotation")
		spin:SetOrder(2)
		spin:SetDuration(4)
		spin:SetDegrees(-180)
		local spin = ag:CreateAnimation("Rotation")
		spin:SetOrder(3)
		spin:SetDuration(2)
		spin:SetDegrees(90)
		ag:SetLooping("REPEAT")
		widget:SetScript("OnEnter", function() ag:Play() end)
		widget:SetScript("OnLeave", function() ag:Stop() end)
		if info.versionString then
			local textFrame = CreateFrame("Frame", nil, info.parent)
			textFrame:SetAllPoints(widget)
			local iconText = textFrame:CreateFontString(nil, "OVERLAY")
			iconText:SetPoint("CENTER", widget)
			iconText:SetHeight(15)
			iconText:SetJustifyH("CENTER")
			iconText:SetJustifyV("CENTER")
			iconText:SetFont(TSMAPI.Design:GetContentFont("small"), 12)
			iconText:SetTextColor(165/255, 168/255, 188/255, .7)
			iconText:SetText(info.versionString)
		end
	end
	TSMAPI:Assert(widget, "Invalid widget type: "..tostring(info.type)..private:GetDebugString(info))
	
	if not info.handlers then
		info.handlers = (info.parent and private.frameInfo[info.parent] and private.frameInfo[info.parent].handlers and private.frameInfo[info.parent].handlers[info.key])
	end
	private.frameInfo[widget] = info
	widget.tsmFrameType = info.type
	
	-- add to parent table at specified key
	if info.parent and info.key then
		info.parent[info.key] = widget
	end
	
	-- set size
	if info.size then
		widget:SetWidth(info.size[1] or 0)
		widget:SetHeight(info.size[2] or 0)
	end
	
	-- set points
	if info.points == "ALL" then
		widget:ClearAllPoints()
		widget:SetAllPoints()
	elseif info.points then
		widget:ClearAllPoints()
		for i, pointInfo in ipairs(info.points) do
			TSMAPI:Assert(pointInfo[2] ~= "", "Deprecated use of \"\" as the relative frame: "..private:GetDebugString(info))
			if type(pointInfo[2]) == "string" then
				local parent = widget.AceGUIWidgetVersion and widget.frame:GetParent() or widget:GetParent()
				-- look up the relative frame
				if widget.AceGUIWidgetVersion then
					-- it's an AceGUI widget
					pointInfo[2] = parent[pointInfo[2]]
				else
					pointInfo[2] = parent[pointInfo[2]]
				end
				TSMAPI:Assert(pointInfo[2], "Could not lookup relative frame: "..tostring(pointInfo[2])..private:GetDebugString(info))
			end
			if pointInfo[2] == private.CONSTANTS.PARENT then
				TSMAPI:Assert(info.parent, "Using parent anchor without having a parent: "..private:GetDebugString(info))
				pointInfo[2] = info.parent
			elseif pointInfo[2] == private.CONSTANTS.PREV then
				TSMAPI:Assert(info.previousWidget, "Using previous anchor without having a previous widget set: "..private:GetDebugString(info))
				pointInfo[2] = info.previousWidget
			end
			if type(pointInfo[2]) == "table" and pointInfo[2].AceGUIWidgetVersion then
				pointInfo[2] = pointInfo[2].frame
			end
			widget:SetPoint(unpack(pointInfo))
		end
	end
	
	-- set hidden if applicable
	if info.hidden then
		widget:Hide()
	end
	
	-- set scripts
	TSMAPI:Assert(not info.scripts or info.handlers, "No handlers found"..private:GetDebugString(info))
	for _, script in ipairs(info.scripts or {}) do
		TSMAPI:Assert(info.handlers[script], "No handlers found for script: "..tostring(script)..private:GetDebugString(info))
		TSMAPI:Assert(script ~= "OnShow" or info.type ~= "MovableFrame", "Cannot register on OnShow handler for a MoveableFrame")
		if widget.AceGUIWidgetVersion then
			-- it's an AceGUI widget
			widget:SetCallback(script, function(self, script, ...) private.frameInfo[self].handlers[script](self, ...) end)
		elseif widget.isTSMScrollingTable or widget.isTSMResultsTable then
			-- it's a TSM ScrollingTable or ResultsTable
			widget:SetHandler(script, info.handlers[script])
		else
			-- it's a plain WoW widget
			local handler
			if type(info.handlers[script]) == "string" then
				handler = widget[info.handlers[script]]
			else
				handler = info.handlers[script]
			end
			widget:SetScript(script, handler)
			
			if info.type == "Button" then
				-- For some strange reason, WoW allows clicking of buttons which are hidden, so let's fix that.
				TSMAPI:Assert(script ~= "OnShow" and script ~= "OnHide", "OnShow/OnHide are not allowed on buttons:"..private:GetDebugString(info))
				if script == "OnClick" then
					widget._OnClickHandler = handler
					widget:SetScript("OnShow", private.OnButtonShow)
					widget:SetScript("OnHide", private.OnButtonHide)
					if widget:IsVisible() then
						private.OnButtonShow(widget)
					else
						private.OnButtonHide(widget)
					end
				end
			end
		end
	end
	
	-- set text attributes
	if info.text then
		widget:SetText(info.text)
	end
	if info.textColor then
		widget:SetTextColor(unpack(info.textColor))
	end
	if info.textFont then
		widget:SetFont(unpack(info.textFont))
	end
	
	-- set type-specific attributes for some types
	if info.type == "Frame" or info.type == "MovableFrame" then
		-- create children
		local previousWidget
		for _, childInfo in ipairs(info.children or {}) do
			childInfo.parent = widget
			childInfo.previousWidget = previousWidget
			previousWidget = TSMAPI.GUI:BuildFrame(childInfo)
		end
	elseif info.type == "WidgetVList" then
		for i=1, info.repeatCount do
			local childInfo = info.widget
			childInfo.parent = info.parent
			if i == 1 then
				childInfo.points = info.startPoints
			else
				childInfo.points = {{"TOPLEFT", widget[i-1], "BOTTOMLEFT", 0, info.repeatOffset}, {"TOPRIGHT", widget[i-1], "BOTTOMRIGHT", 0, info.repeatOffset}}
			end
			tinsert(widget, TSMAPI.GUI:BuildFrame(childInfo))
		end
	elseif info.type == "ScrollingTableFrame" then
		-- create ST
		local stInfo = {type="ScrollingTable", parent=widget}
		for i, v in pairs(info._stTemp) do
			stInfo[i] = v
		end
		info.handlers = private.frameInfo[info.parent].handlers
		info._stTemp = nil
		local st = TSMAPI.GUI:BuildFrame(stInfo)
		if info.parent and private.frameInfo[info.parent] and stInfo.key then
			info.parent[stInfo.key] = st
		end
	elseif info.type == "GroupTreeFrame" then
		local groupTree = TSM:CreateGroupTree(widget, unpack(info.groupTreeInfo))
		if info._gtKey then
			info.parent[info._gtKey] = groupTree
		end
	elseif info.type == "AuctionResultsTableFrame" then
		-- create RT
		local rtInfo = {type="AuctionResultsTable", parent=widget}
		for i, v in pairs(info._rtTemp) do
			rtInfo[i] = v
		end
		info.handlers = private.frameInfo[info.parent].handlers
		info._rtTemp = nil
		local st = TSMAPI.GUI:BuildFrame(rtInfo)
		if info.parent and private.frameInfo[info.parent] and rtInfo.key then
			info.parent[rtInfo.key] = st
		end
	elseif info.type == "StatusBarFrame" then
		local statusBar = TSM.GUI:CreateStatusBar(widget, info.name)
		if info._sbKey then
			info.parent[info._sbKey] = statusBar
		end
	end
	
	return widget
end

function TSMAPI.GUI:GetBuildFrameConstants()
	local copy = {}
	for i, v in pairs(private.CONSTANTS) do
		copy[i] = v
	end
	return copy
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:GetDebugString(info)
	return format(" (key='%s', type='%s')", tostring(info.key), tostring(info.type))
end

function private.OnButtonShow(self)
	self:SetScript("OnClick", self._OnClickHandler)
end
function private.OnButtonHide(self)
	self:SetScript("OnClick", nil)
end
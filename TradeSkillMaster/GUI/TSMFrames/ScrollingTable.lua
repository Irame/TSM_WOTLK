-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local ST_COUNT = 0

local ST_ROW_HEIGHT = 15
local ST_ROW_TEXT_SIZE = 13
local ST_HEAD_HEIGHT = 27
local ST_HEAD_SPACE = 4
local DEFAULT_COL_INFO = {{width=1}}



local function GetTableIndex(tbl, value)
	for i, v in pairs(tbl) do
		if value == v then
			return i
		end
	end
end

local function OnColumnClick(self, button, ...)
	if self.st.sortInfo.enabled and button == "LeftButton" then
		if self.st.sortInfo.col == self.colNum then
			self.st.sortInfo.ascending = not self.st.sortInfo.ascending
		else
			self.st.sortInfo.col = self.colNum
			self.st.sortInfo.ascending = true
		end
		self.st.updateSort = true
		self.st:RefreshRows()
	end
	if self.st.handlers.OnColumnClick then
		self.st.handlers.OnColumnClick(self, button, ...)
	end
end


local defaultColScripts = {
	OnEnter = function(self, ...)
		if not self.row.data then return end
		if not self.st.highlightDisabled then
			self.row.highlight:Show()
		end

		local handler = self.st.handlers.OnEnter
		if handler then
			handler(self.st, self.row.data, self, ...)
		end
	end,

	OnLeave = function(self, ...)
		if not self.row.data then return end
		if self.st.selectionDisabled or not self.st.selected or self.st.selected ~= GetTableIndex(self.st.rowData, self.row.data) then
			self.row.highlight:Hide()
		end

		local handler = self.st.handlers.OnLeave
		if handler then
			handler(self.st, self.row.data, self, ...)
		end
	end,

	OnClick = function(self, ...)
		if not self.row.data then return end
		self.st:ClearSelection()
		self.st.selected = GetTableIndex(self.st.rowData, self.row.data)
		self.row.highlight:Show()

		local handler = self.st.handlers.OnClick
		if handler then
			handler(self.st, self.row.data, self, ...)
		end
	end,

	OnDoubleClick = function(self, ...)
		if not self.row.data then return end
		local handler = self.st.handlers.OnDoubleClick
		if handler then
			handler(self.st, self.row.data, self, ...)
		end
	end,
}

local methods = {
	RefreshRows = function(st)
		if not st.rowData then return end
		FauxScrollFrame_Update(st.scrollFrame, #st.rowData, st.sizes.numRows, ST_ROW_HEIGHT)
		local offset = FauxScrollFrame_GetOffset(st.scrollFrame)
		st.offset = offset

		-- do sorting if enabled
		if st.sortInfo.enabled and st.sortInfo.col and st.updateSort then
			local function SortHelper(rowA, rowB)
				local sortArgA = rowA.cols[st.sortInfo.col].sortArg
				local sortArgB = rowB.cols[st.sortInfo.col].sortArg

				if st.sortInfo.ascending then
					return sortArgA < sortArgB
				else
					return sortArgA > sortArgB
				end
			end
			sort(st.rowData, SortHelper)
			st.updateSort = nil
		end

		-- set row data
		for i=1, st.sizes.numRows do
			st.rows[i].data = nil
			if i > #st.rowData then
				st.rows[i]:Hide()
			else
				st.rows[i]:Show()
				local data = st.rowData[i+offset]
				if not data then break end
				st.rows[i].data = data

				if (st.selected == GetTableIndex(st.rowData, data) and not st.selectionDisabled) or st.rows[i]:IsMouseOver() or (st.highlighted and st.highlighted == GetTableIndex(st.rowData, data)) then
					st.rows[i].highlight:Show()
				else
					st.rows[i].highlight:Hide()
				end

				for colNum, col in ipairs(st.rows[i].cols) do
					if st.colInfo[colNum] then
						local colData = data.cols[colNum]
						if type(colData.value) == "function" then
							col:SetText(colData.value(unpack(colData.args)))
						else
							col:SetText(colData.value)
						end
					end
				end
			end
		end
	end,

	SetData = function(st, rowData)
		st.rowData = rowData
		st.updateSort = true
		st:RefreshRows()
	end,

	SetSelection = function(st, rowNum)
		st.selected = rowNum
		st:RefreshRows()
	end,

	GetSelection = function(st)
		return st.selected
	end,

	ClearSelection = function(st)
		st.selected = nil
		st:RefreshRows()
	end,

	DisableSelection = function(st, value)
		st.selectionDisabled = value
	end,

	EnableSorting = function(st, value, defaultCol)
		st.sortInfo.enabled = value
		st.sortInfo.col = abs(defaultCol or 1)
		st.sortInfo.ascending = not defaultCol or defaultCol > 0
		st.updateSort = true
		st:RefreshRows()
	end,

	DisableHighlight = function(st, value)
		st.highlightDisabled = value
	end,

	GetNumRows = function(st)
		return st.sizes.numRows
	end,

	SetScrollOffset = function(st, offset)
		local maxOffset = max(#st.rowData - st.sizes.numRows, 0)
		if not offset or offset < 0 or offset > maxOffset then
			return -- invalid offset
		end

		local scrollPercent = offset / maxOffset
		local maxPixelOffset = st.scrollFrame:GetVerticalScrollRange() + ST_ROW_HEIGHT * 2
		local pixelOffset = scrollPercent * maxPixelOffset
		FauxScrollFrame_SetOffset(st.scrollFrame, offset)
		st.scrollFrame:SetVerticalScroll(pixelOffset)
	end,

	SetHighlighted = function(st, row)
		st.highlighted = row
		st:RefreshRows()
	end,

	Redraw = function(st)
		local width = st:GetWidth() - 14
		local height = st:GetHeight()

		if #st.colInfo > 1 or st.colInfo[1].name then
			-- there is a header row
			st.sizes.headHeight = st.sizes.headFontSize and (st.sizes.headFontSize + 4) or ST_HEAD_HEIGHT
		else
			-- no header row
			st.sizes.headHeight = 0
		end
		st.sizes.numRows = max(floor((st:GetParent():GetHeight()-st.sizes.headHeight-ST_HEAD_SPACE)/ST_ROW_HEIGHT), 0)

		-- update the frame
		st.scrollBar:ClearAllPoints()
		st.scrollBar:SetPoint("BOTTOMRIGHT", st, -1, 1)
		st.scrollBar:SetPoint("TOPRIGHT", st, -1, -st.sizes.headHeight-ST_HEAD_SPACE)

		if st.sizes.headHeight > 0 then
			st.headLine:Show()
			st.headLine:ClearAllPoints()
			st.headLine:SetPoint("TOPLEFT", 2, -st.sizes.headHeight)
			st.headLine:SetPoint("TOPRIGHT", -2, -st.sizes.headHeight)
		else
			st.headLine:Hide()
		end

		-- update the first row
		if st.rows and st.rows[1] then
			st.rows[1]:SetPoint("TOPLEFT", 0, -(st.sizes.headHeight+ST_HEAD_SPACE))
			st.rows[1]:SetPoint("TOPRIGHT", 0, -(st.sizes.headHeight+ST_HEAD_SPACE))
		end

		-- add header columns if necessary
		while #st.headCols < #st.colInfo do
			st:AddColumn()
		end

		-- adjust head col widths
		for colNum, col in ipairs(st.headCols) do
			if st.colInfo[colNum] then
				col:Show()
				col:SetWidth(st.colInfo[colNum].width*width)
				col:SetHeight(st.sizes.headHeight)
				col:SetText(st.colInfo[colNum].name or "")
				col.text:SetJustifyH(st.colInfo[colNum].headAlign or "CENTER")
			else
				col:Hide()
			end
		end

		-- add more rows if necessary
		while #st.rows < st.sizes.numRows do
			st:AddRow()
		end

		-- adjust rows widths
		for rowNum, row in ipairs(st.rows) do
			if rowNum > st.sizes.numRows then
				row.data = nil
				row:Hide()
			else
				row:Show()
				-- add any missing cols
				while #row.cols < #st.colInfo do
					st:AddRowCol(rowNum)
				end
				for colNum, col in ipairs(row.cols) do
					if st.headCols[colNum] and st.colInfo[colNum] then
						col:Show()
						col:SetWidth(st.colInfo[colNum].width*width)
						col.text:SetJustifyH(st.colInfo[colNum].align or "LEFT")
					else
						col:Hide()
					end
				end
			end
		end

		st:RefreshRows()
	end,

	AddColumn = function(st)
		local colNum = #st.headCols + 1
		local col = CreateFrame("Button", st:GetName().."HeadCol"..colNum, st.contentFrame)
		if colNum == 1 then
			col:SetPoint("TOPLEFT")
		else
			col:SetPoint("TOPLEFT", st.headCols[colNum-1], "TOPRIGHT")
		end
		col.st = st
		col.colNum = colNum
		col:RegisterForClicks("AnyUp")
		col:SetScript("OnClick", OnColumnClick)

		local text = col:CreateFontString()
		text:SetJustifyV("CENTER")
		text:SetFont(TSMAPI.Design:GetContentFont("normal"))
		TSMAPI.Design:SetWidgetTextColor(text)
		col.text = text
		col:SetFontString(text)
		text:SetAllPoints()

		local tex = col:CreateTexture()
		tex:SetAllPoints()
		tex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
		tex:SetTexCoord(0.025, 0.957, 0.087, 0.931)
		tex:SetAlpha(0.2)
		col:SetHighlightTexture(tex)

		tinsert(st.headCols, col)

		-- add new cells to the rows
		for rowNum, row in ipairs(st.rows) do
			while #row.cols < #st.headCols do
				st:AddRowCol(rowNum)
			end
		end
	end,

	AddRowCol = function(st, rowNum)
		local row = st.rows[rowNum]
		local colNum = #row.cols + 1
		local col = CreateFrame("Button", nil, row)
		local text = col:CreateFontString()
		text:SetFont(TSMAPI.Design:GetContentFont(), ST_ROW_TEXT_SIZE)
		text:SetJustifyV("CENTER")
		text:SetPoint("TOPLEFT", 1, -1)
		text:SetPoint("BOTTOMRIGHT", -1, 1)
		col.text = text
		col:SetFontString(text)
		col:SetHeight(ST_ROW_HEIGHT)
		col:RegisterForClicks("AnyUp")
		for name, func in pairs(defaultColScripts) do
			col:SetScript(name, func)
		end
		col.st = st
		col.row = row

		if colNum == 1 then
			col:SetPoint("TOPLEFT")
		else
			col:SetPoint("TOPLEFT", row.cols[colNum-1], "TOPRIGHT")
		end
		tinsert(row.cols, col)
	end,

	AddRow = function(st)
		local row = CreateFrame("Frame", nil, st.contentFrame)
		row:SetHeight(ST_ROW_HEIGHT)
		local rowNum = #st.rows + 1
		if rowNum == 1 then
			row:SetPoint("TOPLEFT", 0, -(st.sizes.headHeight+ST_HEAD_SPACE))
			row:SetPoint("TOPRIGHT", 0, -(st.sizes.headHeight+ST_HEAD_SPACE))
		else
			row:SetPoint("TOPLEFT", st.rows[rowNum-1], "BOTTOMLEFT")
			row:SetPoint("TOPRIGHT", st.rows[rowNum-1], "BOTTOMRIGHT")
		end
		local highlight = row:CreateTexture()
		highlight:SetAllPoints()
		highlight:SetColorTexture(1, .9, .9, .1)
		highlight:Hide()
		row.highlight = highlight
		row.st = st

		row.cols = {}
		st.rows[rowNum] = row
		for i=1, #st.colInfo do
			st:AddRowCol(rowNum)
		end
	end,

	SetHandler = function(st, ...)
		if select('#', ...) == 0 or not select(1, ...) then
			wipe(st.handlers)
		elseif type(select(1, ...)) == "table" then
			local handlers = ...
			for event, handler in pairs(handlers) do
				st.handlers[event] = handler
			end
		else
			local event, handler = ...
			st.handlers[event] = handler
		end
	end,

	SetHeadFontSize = function(st, size)
		st.sizes.headFontSize = size
		-- update the text size of the head cols
		for _, col in ipairs(st.headCols) do
			if st.sizes.headFontSize then
				col.text:SetFont(TSMAPI.Design:GetContentFont("normal"), st.sizes.headFontSize)
			else
				col.text:SetFont(TSMAPI.Design:GetContentFont("normal"))
			end
		end
		st:Redraw()
	end,

	SetColInfo = function(st, colInfo)
		colInfo = colInfo or DEFAULT_COL_INFO
		TSMAPI:Assert(type(colInfo) == "table" and type(colInfo[1]) == "table", "Invalid colInfo argument.")
		st.colInfo = colInfo
		st:Redraw()
	end,
}

function TSM:CreateScrollingTable(parent)
	-- create the base frame
	ST_COUNT = ST_COUNT + 1
	local st = CreateFrame("Frame", "TSMScrollingTable"..ST_COUNT, parent)
	st:SetAllPoints()
	st:SetScript("OnSizeChanged", function() st:Redraw() end)

	local contentFrame = CreateFrame("Frame", nil, st)
	contentFrame:SetPoint("TOPLEFT")
	contentFrame:SetPoint("BOTTOMRIGHT", -15, 0)
	st.contentFrame = contentFrame

	-- frame to hold the header columns and the rows
	local scrollFrame = CreateFrame("ScrollFrame", st:GetName().."ScrollFrame", st, "FauxScrollFrameTemplate")
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ST_ROW_HEIGHT, function() st:RefreshRows() end)
	end)
	scrollFrame:SetAllPoints(contentFrame)
	st.scrollFrame = scrollFrame

	-- make the scroll bar consistent with the TSM theme
	local scrollBar = _G[scrollFrame:GetName().."ScrollBar"]
	scrollBar:SetWidth(12)
	st.scrollBar = scrollBar
	local thumbTex = scrollBar:GetThumbTexture()
	thumbTex:SetPoint("CENTER")
	TSMAPI.Design:SetContentColor(thumbTex)
	thumbTex:SetHeight(50)
	thumbTex:SetWidth(12)
	_G[scrollBar:GetName().."ScrollUpButton"]:Hide()
	_G[scrollBar:GetName().."ScrollDownButton"]:Hide()

	-- create head line at default position
	st.headLine = TSM.GUI:CreateHorizontalLine(st, 0)

	-- add all the methods
	for name, func in pairs(methods) do
		st[name] = func
	end

	-- setup default values
	st.isTSMScrollingTable = true
	st.sizes = {}
	st.headCols = {}
	st.rows = {}
	st.handlers = {}
	st.sortInfo = {enabled=nil}
	st.colInfo = DEFAULT_COL_INFO

	return st
end

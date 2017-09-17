local TSM = select(2, ...)
local BROWSE_ROW_HEIGHT = 27
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table

local function DoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, st, ...)
	if fShow then
		local rowdata = st:GetRow(realrow)
		local celldata = st:GetCell(rowdata, column)

		local cellvalue = celldata
		if type(celldata) == "table" then
			cellvalue = celldata.value
		end
		if type(cellvalue) == "function" then
			if celldata.args then
				cellFrame.text:SetText(cellvalue(unpack(celldata.args)))
			else
				cellFrame.text:SetText(cellvalue(data, cols, realrow, column, st))
			end
		else
			cellFrame.text:SetText(cellvalue)
		end
		cellFrame.text:SetTextColor(1, 1, 1, 1)

		if not cellFrame.icon then
			cellFrame.text:SetPoint("TOPRIGHT", cellFrame, "TOPRIGHT", 0, 0)
			cellFrame.text:SetPoint("BOTTOMRIGHT", cellFrame, "BOTTOMRIGHT", 0, 0)

			local btn = CreateFrame("Button", nil, cellFrame)
			btn:SetPoint("TOPLEFT")
			btn:SetWidth(BROWSE_ROW_HEIGHT)
			btn:SetHeight(BROWSE_ROW_HEIGHT)
			btn:SetScript("OnEnter", function(self)
					if self.link then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetHyperlink(self.link)
						GameTooltip:Show()
						st.isShowingItemTooltip = true
					end
				end)
			btn:SetScript("OnLeave", function()
					GameTooltip:ClearLines()
					GameTooltip:Hide()
					st.isShowingItemTooltip = false
				end)
			btn:SetScript("OnClick", function(self)
					if IsModifiedClick() then
						HandleModifiedItemClick(self.link)
					else
						cellFrame:GetScript("OnClick")(cellFrame)
					end
				end)

			local tex = btn:CreateTexture()
			tex:SetPoint("TOPLEFT", 3, -3)
			tex:SetPoint("BOTTOMRIGHT", -3, 3)
			btn:SetNormalTexture(tex)
			cellFrame.icon = btn
			
			local tex = btn:CreateTexture()
			tex:SetPoint("TOPLEFT", 0, -1)
			tex:SetPoint("BOTTOMRIGHT")
			tex:SetTexture("Interface\\Buttons\\UI-Button-KeyRing-Highlight")
			tex:SetTexCoord(0.012, 0.556, 0.018, 0.605)
			tex:SetVertexColor(0.2, 1, 0.2, 1)
			tex:SetBlendMode("ADD")
			tex:Hide()
			cellFrame.testHighlight = tex
		end

		if celldata and celldata.args then
			local link = celldata.args[2]
			local texture = select(10, GetItemInfo(link))
			cellFrame.icon.link = link
			cellFrame.icon:GetNormalTexture():SetTexture(texture)
			cellFrame.icon:Show()
			if not rowdata.isTopRow then
				cellFrame.icon:SetPoint("TOPLEFT", 5, 0)
				cellFrame.text:SetWidth(cellFrame:GetWidth() - (8+BROWSE_ROW_HEIGHT))
				cellFrame.icon:SetAlpha(0.5)
				cellFrame.text:SetAlpha(0.7)
				rowFrame.dimmed = true
			else
				cellFrame.icon:SetPoint("TOPLEFT", 0, 0)
				cellFrame.text:SetWidth(cellFrame:GetWidth() - (3+BROWSE_ROW_HEIGHT))
				cellFrame.icon:SetAlpha(1)
				cellFrame.text:SetAlpha(1)
				rowFrame.dimmed = nil
			end
		end
	else
		cellFrame.text:SetText("")
	end
end

-- replacement to the st.SortData function
local function SortAuctionSTData(st)
	local sortedData = {}
	
	-- find column to sort by
	local i, sortby = 1, nil;
	while i <= #st.cols and not sortby do
		if st.cols[i].sort then 
			sortby = i;
		end
		i = i + 1;
	end
	
	local temp, topRows = {}, {}
	
	-- organize all the rows by itemString into the temp table
	for i, row in ipairs(st.data) do
		local itemString = row.itemString
		temp[itemString] = temp[itemString] or {}
		
		local value = nil
		if sortby then
			if row.cols[sortby].args then
				value = row.cols[sortby].args[1] or math.huge
			else
				value = row.cols[sortby].value
			end
		end
		
		tinsert(temp[itemString], {rowNum=i, value=value})
	end
		
	-- if we found a column, do the sorting
	if sortby then
		local sortDirection = st.cols[sortby].sort or st.cols[sortby].defaultsort or "desc"
		
		-- Sort all the auctions for each item independently of each other.
		-- After this, the auctions for each item will be sorted, but the
		-- items won't be in the right order.
		for itemString, rows in pairs(temp) do
			if sortDirection == "asc" then
				sort(rows, function(a, b) return a.value < b.value end)
			else
				sort(rows, function(a, b) return a.value > b.value end)
			end
			tinsert(topRows, {itemString=itemString, value=rows[1].value})
		end
	
		-- sort the top rows of each item to determine the item order
		if sortDirection == "asc" then
			sort(topRows, function(a, b) return a.value < b.value end)
		else
			sort(topRows, function(a, b) return a.value > b.value end)
		end
	else
		for itemString, rows in pairs(temp) do
			tinsert(topRows, {itemString=itemString, value=rows[1].value})
		end
	end
		
	-- bring everything together into the sortedData table
	for _, topRow in ipairs(topRows) do
		for i, row in ipairs(temp[topRow.itemString]) do
			st.data[row.rowNum].isTopRow = (i==1)
			tinsert(sortedData, row.rowNum)
		end
	end
	
	st.filtered = sortedData
	st:Refresh()
end

function TSMAPI:CreateAuctionsST(stParent, colInfo, customEvents)
	local stCols = {}
	for i, v in ipairs(colInfo) do
		stCols[i] = {
			name = colInfo[i].name,
			width = colInfo[i].width,
			align = colInfo[i].align,
			bgcolor = (i%2==1) and {r=1, g=1, b=1, a=0.03} or nil,
			defaultsort = "asc",
		}
	end
	stCols[1].DoCellUpdate = DoCellUpdate


	local function GetSTColInfo(width)
		local colInfo = CopyTable(stCols)
		for i=1, #colInfo do
			colInfo[i].width = floor(colInfo[i].width*width)
		end

		return colInfo
	end

	local st = TSMAPI:CreateScrollingTable(GetSTColInfo(stParent:GetWidth()), true)
	st.frame:SetParent(stParent)
	st.frame:SetPoint("TOPLEFT", 0, -30+(colInfo.yAdjust or 0))
	st.frame:SetPoint("BOTTOMRIGHT")
	st.frame:SetScript("OnSizeChanged", function(_,width, height)
			st:SetDisplayCols(GetSTColInfo(width))
			st:SetDisplayRows(floor(height/BROWSE_ROW_HEIGHT), BROWSE_ROW_HEIGHT)
		end)
	st:Show()
	st:SetData({})
	st.frame:GetScript("OnSizeChanged")(st.frame, st.frame:GetWidth(), st.frame:GetHeight())
	st:EnableSelection(true)
	
	-- we call SetData everytime we want it to be re-sorted
	-- so make sure it doesn't get sorted at any other time
	st.SetData = function(self, data)
		self.data = data
		SortAuctionSTData(self)
	end
	st.SortData = function() end

	for i, row in ipairs(st.rows) do
		row:SetHeight(BROWSE_ROW_HEIGHT)
		if i%2 == 0 then
			local tex = row:CreateTexture()
			tex:SetPoint("TOPLEFT", 4, -2)
			tex:SetPoint("BOTTOMRIGHT", -4, 2)
			tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
			tex:SetTexCoord(0.017, 1, 0.083, 0.909)
			tex:SetAlpha(0.3)
			row:SetNormalTexture(tex)
		end
		for j, col in ipairs(row.cols) do
			col.text:SetFont(TSMAPI.Design:GetContentFont(), 13)
			if j == 1 then
				col.text:SetHeight(BROWSE_ROW_HEIGHT)
			end
			col.text:SetShadowColor(0, 0, 0, 0)
		end
	end

	for _, col in ipairs(st.head.cols) do
		local fontString = col:GetFontString()
		fontString:SetJustifyH("CENTER")
		fontString:SetJustifyV("CENTER")
		fontString:SetFont(TSMAPI.Design:GetContentFont("small"))
		TSMAPI.Design:SetWidgetTextColor(fontString)
		col:SetHeight(25)
		col:SetFontString(fontString)

		local tex = col:CreateTexture()
		tex:SetPoint("TOPLEFT", 0, 0)
		tex:SetPoint("BOTTOMRIGHT", 0, -4)
		tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
		tex:SetTexCoord(0.017, 1, 0.083, 0.909)
		tex:SetAlpha(0.5)
		col:SetNormalTexture(tex)

		local tex = col:CreateTexture()
		tex:SetPoint("TOPLEFT", 0, 0)
		tex:SetPoint("BOTTOMRIGHT", 0, -4)
		tex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
		tex:SetTexCoord(0.025, 0.957, 0.087, 0.931)
		tex:SetAlpha(0.2)
		col:SetHighlightTexture(tex)
	end

	st.OnColumnClick = function(self, column, delayed)
		if not delayed then
			-- we need to wait for the default OnClick handler to finish
			return TSMAPI:CreateTimeDelay("stcolsort", 0.05, function() st:OnColumnClick(column, true) end)
		end

		local headCol = st.head.cols[column]
		local sortOrder = st.cols[column].sort
		st.sortInfo = {col=column, order=sortOrder}

		for i=1, #st.head.cols do
			local tex = st.head.cols[i]:GetNormalTexture()
			tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
			tex:SetTexCoord(0.017, 1, 0.083, 0.909)
			tex:SetAlpha(0.5)
		end

		if sortOrder == "asc" then
			local tex = headCol:GetNormalTexture()
			tex:SetTexture(0.6, 0.8, 1, 0.8)
		elseif sortOrder == "dsc" then
			local tex = headCol:GetNormalTexture()
			tex:SetTexture(0.8, 0.6, 1, 0.8)
		end
		TSM:SendMessage("TSM_AUCTION_ST_ON_SORT")
	end

	st.head:SetPoint("BOTTOMLEFT", st.frame, "TOPLEFT", 4, 4)
	st.head:SetPoint("BOTTOMRIGHT", st.frame, "TOPRIGHT", -4, 4)
	st.head:SetHeight(25)
	
	st.ExpandItem = function(self, itemString)
		for i, data in ipairs(self.data) do
			if itemString == data.itemString and data.isExpandable then
				self.expanded[itemString] = true
				self:UpdateSTData()
				break
			end
		end
	end

	local stEvents = {
		["OnDoubleClick"] = function(rowFrame, cellFrame, data, _, _, rowNum, _, st)
			if rowNum then
				local itemString = data[rowNum].itemString
				if not data[rowNum].isExpandable and not st.expanded[itemString] then return end
				st.expanded[itemString] = not st.expanded[itemString]
				local dimmed = rowFrame.dimmed
				st:UpdateSTData()
				if cellFrame:GetScript("OnLeave") then
					cellFrame:GetScript("OnLeave")(cellFrame)
					cellFrame:GetScript("OnEnter")(cellFrame)
				end
				if not st.expanded[itemString] and dimmed then
					local rowIsShown, firstRowNum
					for row, rowData in ipairs(data) do
						if rowData.itemString == itemString then
							if st.IsRowVisible then
								rowIsShown = st:IsRowVisible(row)
							else
								rowIsShown = st:RowIsVisible(row)
							end
							firstRowNum = row
							break
						end
					end
					if rowIsShown then
						st:SetSelection(firstRowNum)
					else
						st:SetSelection()
					end
				end
			end
		end,
		["OnEnter"] = function(_, cellFrame, data, _, _, rowNum, column)
			if rowNum and (column ~= 1 or not st.isShowingItemTooltip) then
				GameTooltip:SetOwner(cellFrame, "ANCHOR_NONE")
				GameTooltip:SetPoint("BOTTOMLEFT", cellFrame, "TOPLEFT")

				if data[rowNum].isExpandable or st.expanded[data[rowNum].itemString] then
					if not st.expanded[data[rowNum].itemString] then
						GameTooltip:AddLine("|cffffffff"..L["Double-click to expand this item and show all the auctions.\n\nRight-click to open the quick action menu."], 1, 1, 1, true)					else
						GameTooltip:AddLine("|cffffffff"..L["Double-click to collapse this item and show only the cheapest auction.\n\nRight-click to open the quick action menu."], 1, 1, 1, true)					end
				else
					GameTooltip:AddLine("|cffffffff"..L["There is only one price level and seller for this item.\n\nRight-click to open the quick action menu."])				end

				GameTooltip:Show()
			end
		end,
		["OnLeave"] = function(_, _, data, _, _, rowNum, column)
			if rowNum and (column ~= 1 or not st.isShowingItemTooltip) then
				GameTooltip:Hide()
			end
		end,
		["OnClick"] = function()
			-- do nothing
		end,
	}

	for event, func in pairs(customEvents) do
		stEvents[event] = func
	end

	st:RegisterEvents(stEvents)

	return st
end

local function GetRowTable(st, auction, isExpandable, hasItemLevel)
	if not auction then return end
	local function GetPriceText(buyout, displayBid)
		local bidLine = TSMAPI:FormatTextMoney(displayBid, "|cff999999", true) or "|cff999999---|r"
		local buyoutLine = buyout and buyout > 0 and TSMAPI:FormatTextMoney(buyout, nil, true) or "---"
		
		if TSM.db.profile.showBids then
			return bidLine.."\n"..buyoutLine
		else
			return buyoutLine
		end
	end
	
	local function GetTimeLeftText(timeLeft)
		return _G["AUCTION_TIME_LEFT"..(timeLeft or "")] or ""
	end
	
	local function GetNameText(_, link)
		return gsub(gsub(link, "%[", ""), "%]", "")
	end
	
	local function GetAuctionsText(num, player, isExpandable)
		local playerText = player and (" |cffffff00("..player..")|r") or ""
	
		if isExpandable then
			return TSMAPI.Design:GetInlineColor("link2")..num.."|r"..playerText
		else
			return num..playerText
		end
	end
	
	local function GetSellerText(seller)
		if seller == UnitName("player") then
			return "|cffffff00"..seller.."|r"
		else
			return seller or ""
		end
	end
	
	local function GetPercentText(pct)
		if not pct or pct == -math.huge or pct == math.huge then return "---" end
		local color = TSMAPI:GetAuctionPercentColor(pct)
		return color..floor(pct+0.5).."%|r"
	end
	
	local bid, buyout
	if TSMAPI:GetPricePerUnitValue() then
		bid = auction:GetItemDisplayedBid()
		buyout = auction:GetItemBuyout()
	else
		bid = auction:GetDisplayedBid()
		buyout = auction.buyout
	end
	
	local auctionsData, rowTable
	local itemString = auction.parent:GetItemString()
	if st.expanded[itemString] then
		auctionsData = {auction.numAuctions}
	else
		auctionsData = {#auction.parent.records, auction.parent.records[1].playerAuctions, isExpandable}
	end

	if auction.parent.destroyingNum then
		local destroyingBid = auction:GetItemDestroyingDisplayedBid()
		local destroyingBuyout = auction:GetItemDestroyingBuyout()
	
		local name = GetItemInfo(auction.parent.itemLink)
		rowTable = {
			cols = {
				{
					value = GetNameText,
					args = {name, auction.parent.itemLink},
				},
				{
					value = GetAuctionsText,
					args = auctionsData,
				},
				{
					value = auction.count,
				},
				{
					value = GetSellerText,
					args = {auction.seller},
				},
				{
					value = GetPriceText,
					args = {destroyingBuyout, destroyingBid},
				},
				{
					value = GetPriceText,
					args = {buyout, bid},
				},
				{
					value = GetPercentText,
					args = {auction:GetPercent()},
				},
			},
			itemString = itemString,
			args = {itemString, auction:GetDisplayedBid(), auction.buyout, auction.count},
			isExpandable = isExpandable,
			record = auction,
		}
	else
		local name, _, _, iLvl = GetItemInfo(auction.parent.itemLink)
		rowTable = {
			cols = {
				{
					value = GetNameText,
					args = {name, auction.parent.itemLink},
				},
				{
					value = GetAuctionsText,
					args = auctionsData,
				},
				{
					value = auction.count,
					args = {auction.count},
				},
				{
					value = GetTimeLeftText,
					args = {auction.timeLeft},
				},
				{
					value = GetSellerText,
					args = {auction.seller},
				},
				{
					value = GetPriceText,
					args = {buyout, bid},
				},
				{
					value = GetPercentText,
					args = {auction:GetPercent()},
				},
			},
			itemString = itemString,
			args = {itemString, auction:GetDisplayedBid(), auction.buyout, auction.count},
			isExpandable = isExpandable,
			record = auction,
		}
		
		if hasItemLevel then
			tinsert(rowTable.cols, 2, {value=(iLvl or "---"), args={iLvl or 0}})
		end
	end
	
	return rowTable
end

local cache = {}
function TSMAPI:WipeAuctionSTCache()
	cache = {}
end

function TSMAPI:SetSTData(st, auctionData)
	local stData = {}
	for i=1, #auctionData do
		local auction = auctionData[i]
		local itemString = auction:GetItemString()
		if st.expanded[itemString] then
			-- this item is expanded - show all rows
			for _, data in ipairs(auction.compactRecords) do
				local row = GetRowTable(st, data, false, st.hasItemLevel)
				tinsert(stData, row)
			end
		else
			-- this item is not exanded - just show the first row
			auction.uniqueTempId = auction.uniqueTempId or (random()..(isExpandable and "t" or "f"))
			if not cache[auction.uniqueTempId] or cache[auction.uniqueTempId].record ~= auction.compactRecords[1] then
				local isExpandable = #auction.compactRecords > 1
				local row = GetRowTable(st, auction.compactRecords[1], isExpandable, st.hasItemLevel)
				cache[auction.uniqueTempId] = {record=auction.compactRecords[1], rowTable=row}
				tinsert(stData, row)
			else
				tinsert(stData, cache[auction.uniqueTempId].rowTable)
			end
		end
	end
	
	st:SetData(stData)
end

local function CreateRightClickFrame(parent)
	local frame = CreateFrame("Frame", nil, parent)
	TSMAPI.Design:SetFrameBackdropColor(frame)
	frame:Hide()
	frame:SetFrameStrata("TOOLTIP")
	frame:SetScript("OnShow", function(self)
			local x, y = GetCursorPosition()
			x = x / UIParent:GetEffectiveScale() - 5
			y = y / UIParent:GetEffectiveScale() + 5
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
			self.timeLeft = 0.5
		end)
	frame:SetScript("OnUpdate", function(self, elapsed)
			if not GetMouseFocus() then return self:Hide() end
			if GetMouseFocus() == self or GetMouseFocus().isTSMRightClickChild then
				self.timeLeft = 0.5
			elseif self.timeLeft then
				self.timeLeft = (self.timeLeft or 0.5) - elapsed
				if self.timeLeft <= 0 then
					self.timeLeft = nil
					self:Hide()
				end
			end
		end)
	-- need to keep this in order to have GetMouseFocus() work for this frame
	frame:SetScript("OnEnter", function() end)
	frame:SetScript("OnLeave", function() end)

	return frame
end

local rClickFunctions = {}
local rClickFrame
local function OnRowRightClick(parent, itemLink)
	rClickFrame = rClickFrame or CreateRightClickFrame(parent)
	rClickFrame:Hide()
	rClickFrame:SetParent(parent)
	rClickFrame:SetHeight(33 + 21 * #rClickFunctions)
	rClickFrame:SetWidth(250)
	rClickFrame:Show()
	
	local text = TSMAPI.GUI:CreateLabel(rClickFrame)
	text:SetPoint("TOPLEFT", 2, -2)
	text:SetPoint("TOPRIGHT", -2, 2)
	text:SetHeight(20)
	text:SetText(TSMAPI.Design:GetInlineColor("link")..L["Quick Action Menu:"].."|r")	
	rClickFrame.rows = rClickFrame.rows or {}
	
	for i=1, #rClickFunctions do
		local row = rClickFrame.rows[i] or CreateFrame("Button", nil, rClickFrame)
		row.isTSMRightClickChild = true
		row:RegisterForClicks("AnyDown")
		row:SetPoint("TOPLEFT", 10, -(5+i*(21)))
		row:SetHeight(20)
		row:SetWidth(rClickFrame:GetWidth()-20)
		
		row:SetScript("OnClick", function()
				rClickFunctions[i].callback(parent, itemLink)
				rClickFrame:Hide()
			end)
		
		if not rClickFrame.rows[i] then
			local tex = row:CreateTexture()
			tex:SetPoint("TOPLEFT", 0, 0)
			tex:SetPoint("BOTTOMRIGHT", 0, 0)
			tex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
			tex:SetVertexColor(1, 1, 1, 0.3)
			row:SetHighlightTexture(tex)
		end
		
		local text = rClickFrame.rows[i] and rClickFrame.rows[i].text or TSMAPI.GUI:CreateLabel(row)
		text:SetJustifyH("LEFT")
		text:SetJustifyV("CENTER")
		text:SetPoint("BOTTOMRIGHT")
		text:SetPoint("TOPLEFT")
		text:SetText(rClickFunctions[i].label)
		row:SetFontString(text)
		row.text = text
		
		rClickFrame.rows[i] = row
	end
end

function TSMAPI:GetSTRowRightClickFunction()
	return OnRowRightClick
end

function TSMAPI:RegisterAuctionSTRightClickFunction(label, callback)
	tinsert(rClickFunctions, {label=label, callback=callback})
end
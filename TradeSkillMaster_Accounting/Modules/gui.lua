-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Accounting - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_accounting.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- create a local reference to the TradeSkillMaster_Crafting table and register a new module
local TSM = select(2, ...)
local GUI = TSM:NewModule("GUI", "AceEvent-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Accounting") -- loads the localization table

local ROW_HEIGHT = 16
local saleST, buyST, itemSummaryST, resaleSummaryST, itemDetailST

function GUI:Load(parent)
	local simpleGroup = AceGUI:Create("SimpleGroup")
	simpleGroup:SetLayout("Fill")
	parent:AddChild(simpleGroup)

	local tabGroup =  AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs({{text=L["Sales"], value=1}, {text=L["Purchases"], value=2}, {text=L["Items"], value=3}, {text=L["Resale"], value=4}, {text=L["Summary"], value=5}, {text=L["Options"], value=6}})
	tabGroup:SetCallback("OnGroupSelected", function(self, _, value)
			tabGroup:ReleaseChildren()
			GUI:HideScrollingTables()
			if value == 1 then
				GUI:DrawSales(self)
			elseif value == 2 then
				GUI:DrawPurchases(self)
			elseif value == 3 then
				GUI:DrawItemSummary(self)
			elseif value == 4 then
				GUI:DrawResaleSummary(self)
			elseif value == 5 then
				GUI:DrawGoldSummary(self)
			elseif value == 6 then
				GUI:DrawOptions(self)
			end
		end)
	simpleGroup:AddChild(tabGroup)
	TSM.Data:PopulateDataCaches()
	tabGroup:SelectTab(1)
	
	GUI:HookScript(simpleGroup.frame, "OnHide", function()
			GUI:UnhookAll()
			GUI:HideScrollingTables()
			TSM.Data:ClearDataCaches()
		end)
end

function GUI:DrawSales(container)
	if not saleST then
		local colInfo = GUI:GetColInfo("sales", 100)
		saleST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	GUI:CreateTopWidgetsPlayer(container, saleST, function(...) return TSM.Data:GetSalesData(...) end)
	local stParent = container.children[1].children[#container.children[1].children].frame
	saleST.frame:SetParent(stParent)
	saleST.frame:SetPoint("BOTTOMLEFT")
	saleST.frame:SetPoint("TOPRIGHT", 0, -20)
	saleST.frame:SetScript("OnSizeChanged", function(_,width, height)
			saleST:SetDisplayCols(GUI:GetColInfo("sales", width))
			saleST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
		end)
	saleST:Show()
	saleST:SetData(TSM.Data:GetSalesData())
	saleST.frame:GetScript("OnSizeChanged")(saleST.frame, saleST.frame:GetWidth(), saleST.frame:GetHeight())
	
	local font, size = GameFontNormal:GetFont()
	for i, row in ipairs(saleST.rows) do
		for j, col in ipairs(row.cols) do
			col.text:SetFont(font, size-1)
		end
	end
	
	for i, col in ipairs(saleST.head.cols) do
		col:SetHeight(32)
	end
	
	saleST:RegisterEvents({
		["OnClick"] = function(_, _, data, _, _, rowNum, _, self)
			if not rowNum then return end
			self:Hide()
			GUI:DrawItemLookup(container, data[rowNum].itemString, 1)
		end,
		["OnEnter"] = function(_, self, _, _, _, rowNum)
			if not rowNum then return end
			
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(L["Click for a detailed report on this item."], 1, .82, 0, 1)
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end})
end

function GUI:DrawPurchases(container)
	if not buyST then
		local colInfo = GUI:GetColInfo("buys", 100)
		buyST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	GUI:CreateTopWidgetsPlayer(container, buyST, function(...) return TSM.Data:GetBuyData(...) end)
	local stParent = container.children[1].children[#container.children[1].children].frame
	buyST.frame:SetParent(stParent)
	buyST.frame:SetPoint("BOTTOMLEFT")
	buyST.frame:SetPoint("TOPRIGHT", 0, -20)
	buyST.frame:SetScript("OnSizeChanged", function(_,width, height)
			buyST:SetDisplayCols(GUI:GetColInfo("buys", width))
			buyST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
		end)
	buyST:Show()
	buyST:SetData(TSM.Data:GetBuyData())
	buyST.frame:GetScript("OnSizeChanged")(buyST.frame, buyST.frame:GetWidth(), buyST.frame:GetHeight())
	
	local font, size = GameFontNormal:GetFont()
	for i, row in ipairs(buyST.rows) do
		for j, col in ipairs(row.cols) do
			col.text:SetFont(font, size-1)
		end
	end
	
	for i, col in ipairs(buyST.head.cols) do
		col:SetHeight(32)
	end
	
	buyST:RegisterEvents({
		["OnClick"] = function(_, _, data, _, _, rowNum, _, self)
			if not rowNum then return end
			self:Hide()
			GUI:DrawItemLookup(container, data[rowNum].itemString, 2)
		end,
		["OnEnter"] = function(_, self, _, _, _, rowNum)
			if not rowNum then return end
			
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(L["Click for a detailed report on this item."], 1, .82, 0, 1)
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end})
end

function GUI:DrawItemSummary(container)
	if not itemSummaryST then
		local colInfo = GUI:GetColInfo("itemSummary", 100)
		itemSummaryST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	GUI:CreateTopWidgets(container, itemSummaryST, function(...) return TSM.Data:GetItemSummaryData(...) end)
	local stParent = container.children[1].children[#container.children[1].children].frame
	itemSummaryST.frame:SetParent(stParent)
	itemSummaryST.frame:SetPoint("BOTTOMLEFT")
	itemSummaryST.frame:SetPoint("TOPRIGHT", 0, -20)
	itemSummaryST.frame:SetScript("OnSizeChanged", function(_,width, height)
			itemSummaryST:SetDisplayCols(GUI:GetColInfo("itemSummary", width))
			itemSummaryST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
		end)
	itemSummaryST:Show()
	itemSummaryST:SetData(TSM.Data:GetItemSummaryData())
	itemSummaryST.frame:GetScript("OnSizeChanged")(itemSummaryST.frame, itemSummaryST.frame:GetWidth(), itemSummaryST.frame:GetHeight())
	
	local font, size = GameFontNormal:GetFont()
	for i, row in ipairs(itemSummaryST.rows) do
		for j, col in ipairs(row.cols) do
			col.text:SetFont(font, size-1)
		end
	end
	
	itemSummaryST:RegisterEvents({
		["OnClick"] = function(_, _, data, _, _, rowNum, _, self)
			if not rowNum then return end
			self:Hide()
			GUI:DrawItemLookup(container, data[rowNum].itemString, 3)
		end,
		["OnEnter"] = function(_, self, _, _, _, rowNum)
			if not rowNum then return end
			
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(L["Click for a detailed report on this item."], 1, .82, 0, 1)
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end})
end

function GUI:DrawResaleSummary(container)
	if not resaleSummaryST then
		local colInfo = GUI:GetColInfo("resaleSummary", 100)
		resaleSummaryST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	GUI:CreateTopWidgets(container, resaleSummaryST, function(...) return TSM.Data:GetResaleSummaryData(...) end)
	local stParent = container.children[1].children[#container.children[1].children].frame
	resaleSummaryST.frame:SetParent(stParent)
	resaleSummaryST.frame:SetPoint("BOTTOMLEFT")
	resaleSummaryST.frame:SetPoint("TOPRIGHT", 0, -20)
	resaleSummaryST.frame:SetScript("OnSizeChanged", function(_,width, height)
			resaleSummaryST:SetDisplayCols(GUI:GetColInfo("resaleSummary", width))
			resaleSummaryST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
		end)
	resaleSummaryST:Show()
	resaleSummaryST:SetData(TSM.Data:GetResaleSummaryData())
	
	local font, size = GameFontNormal:GetFont()
	for i, row in ipairs(resaleSummaryST.rows) do
		for j, col in ipairs(row.cols) do
			col.text:SetFont(font, size-1)
		end
	end
	resaleSummaryST.frame:GetScript("OnSizeChanged")(resaleSummaryST.frame, resaleSummaryST.frame:GetWidth(), resaleSummaryST.frame:GetHeight())
	
	resaleSummaryST:RegisterEvents({
		["OnClick"] = function(_, _, data, _, _, rowNum, _, self)
			if not rowNum then return end
			self:Hide()
			GUI:DrawItemLookup(container, data[rowNum].itemString, 4)
		end,
		["OnEnter"] = function(_, self, _, _, _, rowNum)
			if not rowNum then return end
			
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(L["Click for a detailed report on this item."], 1, .82, 0, 1)
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end})
end

function GUI:DrawItemLookup(container, itemString, returnTab)
	container:ReleaseChildren()
	local itemID = TSM:ItemStringToID(itemString)
	local itemData = TSM.Data:GetItemData(itemString)
	
	local color, color2 = TSMAPI.Design:GetInlineColor("link2"), TSMAPI.Design:GetInlineColor("category2")
	
	local buyers, sellers = {}, {}
	for name, quantity in pairs(itemData.buyers) do
		tinsert(buyers, {name=name, quantity=quantity})
	end
	for name, quantity in pairs(itemData.sellers) do
		tinsert(sellers, {name=name, quantity=quantity})
	end
	sort(buyers, function(a, b) return a.quantity > b.quantity end)
	sort(sellers, function(a, b) return a.quantity > b.quantity end)
	
	local buyersText, sellersText = "", ""
	for i=1, min(#buyers, 5) do
		buyersText = buyersText.."|cffffffff"..buyers[i].name.."|r"..color.."("..buyers[i].quantity..")|r, "
	end
	for i=1, min(#sellers, 5) do
		sellersText = sellersText.."|cffffffff"..sellers[i].name.."|r"..color.."("..sellers[i].quantity..")|r, "
	end

	local page = {
		{
			type = "SimpleGroup",
			layout = "List",
			fullHeight = true,
			children = {
				{
					type = "SimpleGroup",
					layout = "Flow",
					children = {
						{
							type = "Label",
							relativeWidth = 0.1,
						},
						{
							type = "InteractiveLabel",
							text = itemData.link or itemString,
							fontObject = GameFontNormalLarge,
							relativeWidth = 0.4,
							callback = function() SetItemRef("item:"..itemID, itemID) end,
							tooltip = itemID,
						},
						{
							type = "Label",
							relativeWidth = 0.1,
						},
						{
							type = "Button",
							text = L["Back to Previous Page"],
							relativeWidth = 0.29,
							callback = function() container:SelectTab(returnTab) end,
						},
					},
				},
				{
					type = "HeadingLine",
				},
				{
					type = "InlineGroup",
					title = L["Sale Data"],
					layout = "Flow",
					backdrop = true,
					children = {},
				},
				{
					type = "InlineGroup",
					title = L["Purchase Data"],
					layout = "Flow",
					backdrop = true,
					children = {},
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "SimpleGroup",
					layout = "Flow",
					fullHeight = true,
				},
			},
		},
	}
	
	local sellWidgets, buyWidgets
	if itemData.avgTotalSell then
		sellWidgets = {
			{
				type = "MultiLabel",
				labelInfo = {{text=color2..L["Average Prices:"], relativeWidth = 0.19},
					{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(itemData.avgTotalSell) or "---"), relativeWidth=0.22},
					{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgMonthSell) or "---"), relativeWidth=0.29},
					{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgWeekSell) or "---"), relativeWidth=0.29}},
				relativeWidth = 1,
			},
			{
				type = "MultiLabel",
				labelInfo = {{text=color2..L["Quantity Sold:"], relativeWidth = 0.19},
					{text=color..L["Total:"].." |r|cffffffff"..itemData.totalSellNum, relativeWidth=0.22},
					{text=color..L["Last 30 Days:"].." |r|cffffffff"..itemData.monthSellNum, relativeWidth=0.29},
					{text=color..L["Last 7 Days:"].." |r|cffffffff"..itemData.weekSellNum, relativeWidth=0.29}},
				relativeWidth = 1,
			},
			{
				type = "MultiLabel",
				labelInfo = {{text=color2..L["Gold Earned:"], relativeWidth = 0.19},
					{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(itemData.avgTotalSell*itemData.totalSellNum) or "---"), relativeWidth=0.22},
					{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgMonthSell*itemData.monthSellNum) or "---"), relativeWidth=0.29},
					{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgWeekSell*itemData.weekSellNum) or "---"), relativeWidth=0.29}},
				relativeWidth = 1,
			},
			{
				type = "Label",
				relativeWidth = 1,
				text = color2..L["Top Buyers:"].." |r"..buyersText,
			},
		}
	else
		sellWidgets = {
			{
				type = "Label",
				relativeWidth = 1,
				text = "|cffffffff"..L["There is no sale data for this item."].."|r",
			},
		}
	end
	
	if itemData.avgTotalBuy then
		buyWidgets = {
			{
				type = "MultiLabel",
				labelInfo = {{text=color2..L["Average Prices:"], relativeWidth = 0.19},
					{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(itemData.avgTotalBuy) or "---"), relativeWidth=0.22},
					{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgMonthBuy) or "---"), relativeWidth=0.29},
					{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgWeekBuy) or "---"), relativeWidth=0.29}},
				relativeWidth = 1,
			},
			{
				type = "MultiLabel",
				labelInfo = {{text=color2..L["Quantity Bought:"], relativeWidth = 0.19},
					{text=color..L["Total:"].." |r|cffffffff"..itemData.totalBuyNum, relativeWidth=0.22},
					{text=color..L["Last 30 Days:"].." |r|cffffffff"..itemData.monthBuyNum, relativeWidth=0.29},
					{text=color..L["Last 7 Days:"].." |r|cffffffff"..itemData.weekBuyNum, relativeWidth=0.29}},
				relativeWidth = 1,
			},
			{
				type = "MultiLabel",
				labelInfo = {{text=color2..L["Total Spent:"], relativeWidth = 0.19},
					{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(itemData.avgTotalBuy*itemData.totalBuyNum) or "---"), relativeWidth=0.22},
					{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgMonthBuy*itemData.monthBuyNum) or "---"), relativeWidth=0.29},
					{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(itemData.avgWeekBuy*itemData.weekBuyNum) or "---"), relativeWidth=0.29}},
				relativeWidth = 1,
			},
			{
				type = "Label",
				relativeWidth = 1,
				text = color2..L["Top Sellers:"].." |r"..sellersText,
			},
		}
	else
		buyWidgets = {
			{
				type = "Label",
				relativeWidth = 1,
				text = "|cffffffff"..L["There is no purchase data for this item."].."|r",
			},
		}
	end
	
	local index
	for i=2, #page[1].children do
		if page[1].children[i].type == "InlineGroup" then
			index = i
			break
		end
	end
	
	for i=1, #sellWidgets do
		tinsert(page[1].children[index].children, sellWidgets[i])
	end
	for i=1, #buyWidgets do
		tinsert(page[1].children[index+1].children, buyWidgets[i])
	end
	
	TSMAPI:BuildPage(container, page)
	
	local colInfo = GUI:GetColInfo("itemDetail", 100)
	if not itemDetailST then
		itemDetailST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	local stParent = container.children[1].children[#container.children[1].children].frame
	itemDetailST.frame:SetParent(stParent)
	itemDetailST.frame:SetPoint("TOPLEFT")
	itemDetailST.frame:SetPoint("BOTTOMRIGHT", container.children[1].frame)
	itemDetailST.frame:SetScript("OnSizeChanged", function(_,width, height)
			itemDetailST:SetDisplayCols(GUI:GetColInfo("itemDetail", width))
			itemDetailST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
		end)
	itemDetailST:Show()
	itemDetailST:SetData(itemData.stData)
	itemDetailST.frame:GetScript("OnSizeChanged")(itemDetailST.frame, itemDetailST.frame:GetWidth(), itemDetailST.frame:GetHeight())
	
	local font, size = GameFontNormal:GetFont()
	for i, row in ipairs(itemDetailST.rows) do
		for j, col in ipairs(row.cols) do
			col.text:SetFont(font, size-1)
		end
	end
end

function GUI:DrawGoldSummary(container)
	local data = TSM.Data:GetGoldData()
	local color, color2 = TSMAPI.Design:GetInlineColor("link2"), TSMAPI.Design:GetInlineColor("category2")

	local page = {
		{
			type = "ScrollFrame",
			layout = "Flow",
			children = {
				{
					type = "InlineGroup",
					layout = "Flow",
					title = L["Sales"],
					backdrop = true,
					children = {
						{
							type = "MultiLabel",
							labelInfo = {{text=color2..L["Gold Earned:"], relativeWidth = 0.19},
								{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(data.totalSale) or "---"), relativeWidth=0.22},
								{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(data.monthSale) or "---"), relativeWidth=0.29},
								{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(data.weekSale) or "---"), relativeWidth=0.29}},
							relativeWidth = 1,
						},
						{
							type = "MultiLabel",
							labelInfo = {{text=color2..L["Earned Per Day:"], relativeWidth = 0.19},
								{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(floor(TSMAPI:SafeDivide(data.totalSale, data.totalTime)+0.5)) or "---"), relativeWidth=0.22},
								{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(floor(TSMAPI:SafeDivide(data.monthSale, data.monthTime)+0.5)) or "---"), relativeWidth=0.29},
								{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(floor(TSMAPI:SafeDivide(data.weekSale, data.weekTime)+0.5)) or "---"), relativeWidth=0.29}},
							relativeWidth = 1,
						},
						{
							type = "Label",
							relativeWidth = 0.3,
							text = color2..L["Top Item by Gold:"].."|r",
						},
						{
							type = "InteractiveLabel",
							text = (data.topSellGold.link or data.topSellGold.itemID or "none").." ("..(TSM:FormatTextMoney(data.topSellGold.price) or "---")..")",
							fontObject = GameFontNormal,
							relativeWidth = 0.69,
							callback = function() SetItemRef("item:".. data.topSellGold.itemID, data.topSellGold.itemID) end,
							tooltip = data.topSellGold.itemID,
						},
						{
							type = "Label",
							relativeWidth = 0.3,
							text = color2..L["Top Item by Quantity:"].."|r",
						},
						{
							type = "InteractiveLabel",
							text = (data.topSellQuantity.link or L["none"]).." ("..(data.topSellQuantity.num or "---")..")",							fontObject = GameFontNormal,
							relativeWidth = 0.69,
							callback = function() SetItemRef("item:".. data.topSellQuantity.itemID, data.topSellQuantity.itemID) end,
							tooltip = data.topSellQuantity.itemID,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "Flow",
					title = L["Purchases"],
					backdrop = true,
					children = {
						{
							type = "MultiLabel",
							labelInfo = {{text=color2..L["Gold Spent:"], relativeWidth = 0.19},
								{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(data.totalBuy) or "---"), relativeWidth=0.22},
								{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(data.monthBuy) or "---"), relativeWidth=0.29},
								{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(data.weekBuy) or "---"), relativeWidth=0.29}},
							relativeWidth = 1,
						},
						{
							type = "MultiLabel",
							labelInfo = {{text=color2..L["Spent Per Day:"], relativeWidth = 0.19},
								{text=color..L["Total:"].." |r"..(TSM:FormatTextMoney(floor(TSMAPI:SafeDivide(data.totalBuy, data.totalTime)+0.5)) or "---"), relativeWidth=0.22},
								{text=color..L["Last 30 Days:"].." |r"..(TSM:FormatTextMoney(floor(TSMAPI:SafeDivide(data.monthBuy, data.monthTime)+0.5)) or "---"), relativeWidth=0.29},
								{text=color..L["Last 7 Days:"].." |r"..(TSM:FormatTextMoney(floor(TSMAPI:SafeDivide(data.weekBuy, data.weekTime)+0.5)) or "---"), relativeWidth=0.29}},
							relativeWidth = 1,
						},
						{
							type = "Label",
							relativeWidth = 0.3,
							text = color2..L["Top Item by Gold:"].."|r",
						},
						{
							type = "InteractiveLabel",
							text = (data.topBuyGold.link or L["none"]).." ("..(TSM:FormatTextMoney(data.topBuyGold.price) or "---")..")",							fontObject = GameFontNormal,
							relativeWidth = 0.69,
							callback = function() SetItemRef("item:".. data.topBuyGold.itemID, data.topBuyGold.itemID) end,
							tooltip = data.topBuyGold.itemID,
						},
						{
							type = "Label",
							relativeWidth = 0.3,
							text = color2..L["Top Item by Quantity:"].."|r",
						},
						{
							type = "InteractiveLabel",
							text = (data.topBuyQuantity.link or L["none"]).." ("..(data.topBuyQuantity.num or "---")..")",							fontObject = GameFontNormal,
							relativeWidth = 0.69,
							callback = function() SetItemRef("item:".. data.topBuyQuantity.itemID, data.topBuyQuantity.itemID) end,
							tooltip = data.topBuyQuantity.itemID,
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function GUI:DrawOptions(container)
	local mvSources = TSMAPI:GetPriceSources()
	local daysOld = 45

	local page = {
		{
			type = "ScrollFrame",
			layout = "Flow",
			children = {
				{
					type = "InlineGroup",
					title = L["General Options"],
					layout = "Flow",
					children = {
						{
							type = "Dropdown",
							label = L["Time Format"],
							relativeWidth = 0.5,
							list = {["ago"]=L["_ Hr _ Min ago"], ["usdate"]=L["MM/DD/YY HH:MM"], ["aidate"]=L["YY/MM/DD HH:MM"], ["eudate"]=L["DD/MM/YY HH:MM"]},
							value = TSM.db.factionrealm.timeFormat,
							callback = function(_,_,value) TSM.db.factionrealm.timeFormat = value end,
							tooltip = L["Select what format Accounting should use to display times in applicable screens."],
						},
						{
							type = "Dropdown",
							label = L["Market Value Source"],
							relativeWidth = 0.49,
							list = mvSources,
							value = TSM.db.factionrealm.mvSource,
							callback = function(_,_,value) TSM.db.factionrealm.mvSource = value end,
							tooltip = L["Select where you want Accounting to get market value info from to show in applicable screens."],
						},
						{
							type = "Dropdown",
							label = L["Items/Resale Price Format"],
							relativeWidth = 0.49,
							list = {["avg"]=L["Price Per Item"], ["total"]=L["Total Value"]},
							value = TSM.db.factionrealm.priceFormat,
							callback = function(_,_,value) TSM.db.factionrealm.priceFormat = value end,
							tooltip = L["Select how you would like prices to be shown in the \"Items\" and \"Resale\" tabs; either average price per item or total value."],
						},
					},
				},
				{
					type = "InlineGroup",
					title = L["Tooltip Options"],
					layout = "Flow",
					children = {
						{
							type = "CheckBox",
							label = L["Show sale info in item tooltips"],
							quickCBInfo = {TSM.db.factionrealm.tooltip, "sale"},
							callback = function(_,_,value)
									if value and not TSM.db.factionrealm.tooltip.purchase then
										TSMAPI:RegisterTooltip("TradeSkillMaster_Accounting", function(...) return TSM:LoadTooltip(...) end)
									elseif not TSM.db.factionrealm.tooltip.purchase then
										TSMAPI:UnregisterTooltip("TradeSkillMaster_Accounting")
									end
								end,
							tooltip = L["If checked, the number you have sold and the average sale price will show up in an item's tooltip."],
						},
						{
							type = "CheckBox",
							label = L["Show purchase info in item tooltips"],
							quickCBInfo = {TSM.db.factionrealm.tooltip, "purchase"},
							callback = function(_,_,value)
									if value and not TSM.db.factionrealm.tooltip.sale then
										TSMAPI:RegisterTooltip("TradeSkillMaster_Accounting", function(...) return TSM:LoadTooltip(...) end)
									elseif not TSM.db.factionrealm.tooltip.sale then
										TSMAPI:UnregisterTooltip("TradeSkillMaster_Accounting")
									end
								end,
							tooltip = L["If checked, the number you have purchased and the average purchase price will show up in an item's tooltip."],
						},
						{
							type = "CheckBox",
							label = L["Use smart average for purchase price"],
							quickCBInfo = {TSM.db.factionrealm, "smartBuyPrice"},
							tooltip = L["If checked, the average purchase price that shows in the tooltip will be the average price for the most recent X you have purchased, where X is the number you have in your bags / bank / gbank using data from the ItemTracker module. Otherwise, a simple average of all purchases will be used."],
						},
					},
				},
				{
					type = "InlineGroup",
					title = L["Clear Old Data"],
					layout = "Flow",
					children = {
						{
							type = "Label",
							text = L["You can use the options below to clear old data. It is recommened to occasionally clear your old data to keep Accounting running smoothly. Select the minimum number of days old to be removed in the dropdown, then click the button.\n\nNOTE: There is no confirmation."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = L["Days:"],
							relativeWidth = 0.4,
							list = {"30", "45", "60", "75", "90"},
							value = 2,
							callback = function(_,_,value) daysOld = (tonumber(value)+1)*15 end,
							tooltip = L["Data older than this many days will be deleted when you click on the button to the right."],
						},
						{
							type = "Button",
							text = L["Remove Old Data (No Confirmation)"],
							relativeWidth = 0.59,
							callback = function() TSM.Data:RemoveOldData(daysOld) end,
							tooltip = L["Click this button to permanently remove data older than the number of days selected in the dropdown."],
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function GUI:HideScrollingTables()
	if saleST then
		saleST:Hide()
		saleST:SetData({})
	end
	if buyST then
		buyST:Hide()
		buyST:SetData({})
	end
	if itemSummaryST then
		itemSummaryST:Hide()
		itemSummaryST:SetData({})
	end
	if resaleSummaryST then
		resaleSummaryST:Hide()
		resaleSummaryST:SetData({})
	end
	if itemDetailST then
		itemDetailST:Hide()
		itemDetailST:SetData({})
	end
end


local function ColSortMethod(st, aRow, bRow, col)
	local a, b = st:GetCell(aRow, col), st:GetCell(bRow, col)
	local column = st.cols[col]
	local direction = column.sort or column.defaultsort or "dsc"
	local aValue, bValue = ((a.args or {})[1] or a.value), ((b.args or {})[1] or b.value)
	if direction == "asc" then
		return aValue < bValue
	else
		return aValue > bValue
	end
end

local colInfo = {
	sales = {
		{
			name = L["Item Name"],
			width = 0.33,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Player"],
			width = 0.1,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Stack"],
			width = 0.05,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Aucs"],
			width = 0.05,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Price Per Item"],
			width = 0.13,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Total Sale Price"],
			width = 0.13,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{ 
			name = L["Last Sold"],
			width = 0.2,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
	},
	buys = {
		{
			name = L["Item Name"],
			width = 0.33,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Player"],
			width = 0.1,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Stack"],
			width = 0.05,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Aucs"],
			width = 0.05,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Price Per Item"],
			width = 0.13,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Total Buy Price"],
			width = 0.13,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{ 
			name = L["Last Purchase"],
			width = 0.2,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
	},
	itemSummary = {
		{
			name = L["Item Name"],
			width = 0.38,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Market Value"],
			width = 0.15,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Sold"],
			width = 0.06,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = function() return TSM.db.factionrealm.priceFormat == "avg" and L["Avg Sell Price"] or L["Total Sale Price"] end,
			width = 0.15,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Bought"],
			width = 0.07,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = function() return TSM.db.factionrealm.priceFormat == "avg" and L["Avg Buy Price"] or L["Total Buy Price"] end,
			width = 0.15,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
	},
	resaleSummary = {
		{
			name = L["Item Name"],
			width = 0.37,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Sold"],
			width = 0.06,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = function() return TSM.db.factionrealm.priceFormat == "avg" and L["Avg Sell Price"] or L["Total Sale Price"] end,
			width = 0.14,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Bought"],
			width = 0.07,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = function() return TSM.db.factionrealm.priceFormat == "avg" and L["Avg Buy Price"] or L["Total Buy Price"] end,
			width = 0.14,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Avg Resale Profit"],
			width = 0.21,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
	},
	itemDetail = {
		{
			name = L["Activity Type"],
			width = 0.15,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Buyer/Seller"],
			width = 0.15,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Quantity"],
			width = 0.1,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Price Per Item"],
			width = 0.15,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Total Price"],
			width = 0.15,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Time"],
			width = 0.29,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
	},
}
	
function GUI:GetColInfo(cType, width)
	local colInfo = CopyTable(colInfo[cType])
	
	for i=1, #colInfo do
		if type(colInfo[i].name) == "function" then
			colInfo[i].name = colInfo[i].name()
		end
		colInfo[i].width = floor(colInfo[i].width*width)
	end
	
	return colInfo
end

function GUI:CreateTopWidgetsPlayer(container, st, dataFunc)
	local ddList = {["aucgroups"]=L["Items in an Auctioning Group"], ["notaucgroups"]=L["Items NOT in an Auctioning Group"], ["common"]=L["Common Quality Items"], ["uncommon"]=L["Uncommon Quality Items"], ["rare"]=L["Rare Quality Items"], ["epic"]=L["Epic Quality Items"], ["none"]=L["<none>"]}
	local ddpList = {["all"]=L["All"]}
	local filter, ddSelection, ddpSelection
	
	if TSM.Data.playerDataCache then
		for _, player in pairs(TSM.Data.playerDataCache) do
			ddpList[player] = player
		end
	end
	
	local function UpdateFilter()
		local dropdownFilterFunction = function() return true end
		if ddSelection == "aucgroups" then
			local auctioningItems = {}
			for _, items in pairs(TSMAPI:GetData("auctioningGroups")) do
				for itemID in pairs(items) do
					local name = GetItemInfo(itemID)
					if name then
						auctioningItems[name] = true
					end
				end
			end
			dropdownFilterFunction = function(name) return auctioningItems[name] end
		elseif ddSelection == "notaucgroups" then
			local auctioningItems = {}
			for _, items in pairs(TSMAPI:GetData("auctioningGroups")) do
				for itemID in pairs(items) do
					local name = GetItemInfo(itemID)
					if name then
						auctioningItems[name] = true
					end
				end
			end
			dropdownFilterFunction = function(name) return not auctioningItems[name] end
		end
		
		local rarityFilterFunction = function() return true end
		if ddSelection == "common" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 1 end
		elseif ddSelection == "uncommon" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 2 end
		elseif ddSelection == "rare" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 3 end
		elseif ddSelection == "epic" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 4 end
		end
		
		local searchFilterFunction = function() return true end
		if filter and filter ~= "" then
			searchFilterFunction = function(name) return strfind(strlower(name), filter) end
		end
		
		local updatePlayerFilter = function(player)
			return not player or not ddpSelection or ddpSelection == "all" or ddpSelection == player
		end
		
		st:SetData(dataFunc(function(name, link, player) return dropdownFilterFunction(name) and searchFilterFunction(name) and rarityFilterFunction(link) and updatePlayerFilter(player) end))
	end
	
	local page = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = {
				{
					type = "EditBox",
					label = L["Search"],
					relativeWidth = 0.4,
					onTextChanged = true,
					callback = function(_,_,value)
							filter = strlower(value:trim())
							UpdateFilter()
						end,
				},
				{
					type = "Dropdown",
					label = L["Special Filters"],
					relativeWidth = 0.29,
					list = ddList,
					value = "none",
					callback = function(_,_,value)
							ddSelection = value
							UpdateFilter()
						end,
				},
				{
					type = "Dropdown",
					label = L["Player(s)"],
					relativeWidth = 0.29,
					list = ddpList,
					value = "all",
					callback = function(_,_,value)
							ddpSelection = value
							UpdateFilter()
						end,
				},
				{
					type = "SimpleGroup",
					fullHeight = true,
					layout = "flow"
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function GUI:CreateTopWidgets(container, st, dataFunc)
	local ddList = {["aucgroups"]=L["Items in an Auctioning Group"], ["notaucgroups"]=L["Items NOT in an Auctioning Group"], ["common"]=L["Common Quality Items"], ["uncommon"]=L["Uncommon Quality Items"], ["rare"]=L["Rare Quality Items"], ["epic"]=L["Epic Quality Items"], ["none"]=L["<none>"]}
	local filter, ddSelection
	
	local function UpdateFilter()
		local dropdownFilterFunction = function() return true end
		if ddSelection == "aucgroups" then
			local auctioningItems = {}
			for _, items in pairs(TSMAPI:GetData("auctioningGroups")) do
				for itemID in pairs(items) do
					local name = GetItemInfo(itemID)
					if name then
						auctioningItems[name] = true
					end
				end
			end
			dropdownFilterFunction = function(name) return auctioningItems[name] end
		elseif ddSelection == "notaucgroups" then
			local auctioningItems = {}
			for _, items in pairs(TSMAPI:GetData("auctioningGroups")) do
				for itemID in pairs(items) do
					local name = GetItemInfo(itemID)
					if name then
						auctioningItems[name] = true
					end
				end
			end
			dropdownFilterFunction = function(name) return not auctioningItems[name] end
		end
		
		local rarityFilterFunction = function() return true end
		if ddSelection == "common" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 1 end
		elseif ddSelection == "uncommon" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 2 end
		elseif ddSelection == "rare" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 3 end
		elseif ddSelection == "epic" then
			rarityFilterFunction = function(link) return link and (select(3, GetItemInfo(link)) or 0) == 4 end
		end
		
		local searchFilterFunction = function() return true end
		if filter and filter ~= "" then
			searchFilterFunction = function(name) return strfind(strlower(name), filter) end
		end
		
		st:SetData(dataFunc(function(name, link, player) return dropdownFilterFunction(name) and searchFilterFunction(name) and rarityFilterFunction(link) end))
	end
	
	local page = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = {
				{
					type = "EditBox",
					label = L["Search"],
					relativeWidth = 0.7,
					onTextChanged = true,
					callback = function(_,_,value)
							filter = strlower(value:trim())
							UpdateFilter()
						end,
				},
				{
					type = "Dropdown",
					label = L["Special Filters"],
					relativeWidth = 0.29,
					list = ddList,
					value = "none",
					callback = function(_,_,value)
							ddSelection = value
							UpdateFilter()
						end,
				},
				{
					type = "SimpleGroup",
					fullHeight = true,
					layout = "flow"
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end
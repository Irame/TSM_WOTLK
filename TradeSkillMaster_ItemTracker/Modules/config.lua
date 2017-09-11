-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Config = TSM:NewModule("Config", "AceEvent-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ItemTracker")

local viewerST
local filters = {characters={}, guilds={}, name=""}

function Config:Load(parent)
	local simpleGroup = AceGUI:Create("SimpleGroup")
	simpleGroup:SetLayout("Fill")
	parent:AddChild(simpleGroup)

	local tabGroup =  AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs({{text=L["Inventory Viewer"], value=1}, {text=L["Options"], value=2}})
	tabGroup:SetCallback("OnGroupSelected", function(self, _, value)
			tabGroup:ReleaseChildren()
			if viewerST then viewerST:Hide() end
			if value == 1 then
				Config:LoadInventoryViewer(self)
			elseif value == 2 then
				Config:LoadOptions(self)
			end
		end)
	simpleGroup:AddChild(tabGroup)
	tabGroup:SelectTab(1)
	
	Config:HookScript(simpleGroup.frame, "OnHide", function()
			Config:UnhookAll()
			if viewerST then viewerST:Hide() end
		end)
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

local viewerColInfo = {
	{
		name = L["Item Name"],
		width = 0.37,
		defaultsort = "asc",
		comparesort = ColSortMethod,
	},
	{
		name = L["Bags"],
		width = 0.1,
		defaultsort = "dsc",
		comparesort = ColSortMethod,
	},
	{
		name = L["Bank"],
		width = 0.1,
		defaultsort = "dsc",
		comparesort = ColSortMethod,
	},
	{
		name = L["Guild Bank"],
		width = 0.1,
		defaultsort = "dsc",
		comparesort = ColSortMethod,
	},
	{
		name = L["AH"],
		width = 0.1,
		defaultsort = "dsc",
		comparesort = ColSortMethod,
	},
	{
		name = L["Total"],
		width = 0.15,
		defaultsort = "dsc",
		comparesort = ColSortMethod,
	},
}

local function GetColInfo(width)
	local colInfo = CopyTable(viewerColInfo)
	
	for i=1, #colInfo do
		colInfo[i].width = floor(colInfo[i].width*width)
	end
	
	return colInfo
end


local function GetSTData()
	local items, rowData = {}, {}
	
	local function AddItem(itemID, key, quantity)
		items[itemID] = items[itemID] or {total=0, bags=0, bank=0, guild=0, auctions=0}
		items[itemID].total = items[itemID].total + quantity
		items[itemID][key] = items[itemID][key] + quantity
	end
	
	for name, selected in pairs(filters.characters) do
		if selected then
			for itemID, quantity in pairs(TSM.Data:GetPlayerBags(name) or {}) do
				AddItem(itemID, "bags", quantity)
			end
			for itemID, quantity in pairs(TSM.Data:GetPlayerBank(name) or {}) do
				AddItem(itemID, "bank", quantity)
			end
			for itemID, quantity in pairs(TSM.Data:GetPlayerAuctions(name) or {}) do
				if tonumber(itemID) then
					AddItem(itemID, "auctions", quantity)
				end
			end
		end
	end
	for name, selected in pairs(filters.guilds) do
		if selected then
			for itemID, quantity in pairs(TSM.Data:GetGuildBank(name) or {}) do
				AddItem(itemID, "guild", quantity)
			end
		end
	end
	
	for itemID, data in pairs(items) do
		local name, itemLink = GetItemInfo(itemID)
		if not name or filters.name == "" or strfind(strlower(name), filters.name) then
			tinsert(rowData, {
					cols = {
						{
							value = itemLink or name or tostring(itemID),
							args = {name or ""}
						},
						{
							value = data.bags
						},
						{
							value = data.bank
						},
						{
							value = data.guild
						},
						{
							value = data.auctions
						},
						{
							value = data.total
						},
					},
					itemID = itemID,
				})
		end
	end
	
	sort(rowData, function(a, b) return a.cols[#a.cols].value > b.cols[#a.cols].value end)
	return rowData
end

function Config:LoadInventoryViewer(parent)
	-- top AceGUI widgets
	local playerList, guildList = {}, {}
	for name in pairs(TSM.characters) do
		playerList[name] = name
		filters.characters[name] = true
	end
	for name in pairs(TSM.guilds) do
		guildList[name] = name
		filters.guilds[name] = true
	end
	
	local page = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = {
				{
					type = "EditBox",
					label = L["Item Search"],
					relativeWidth = 0.39,
					onTextChanged = true,
					callback = function(_,_,value)
							filters.name = value:trim()
							viewerST:SetData(GetSTData())
						end,
				},
				{
					type = "Dropdown",
					label = L["Characters"],
					relativeWidth = 0.3,
					list = playerList,
					value = filters.characters,
					multiselect = true,
					callback = function(_,_,key,value)
							filters.characters[key] = value
							viewerST:SetData(GetSTData())
						end,
				},
				{
					type = "Dropdown",
					label = L["Guilds"],
					relativeWidth = 0.3,
					list = guildList,
					value = filters.guilds,
					multiselect = true,
					callback = function(_,_,key,value)
							filters.guilds[key] = value
							viewerST:SetData(GetSTData())
						end,
				},
				{
					type = "SimpleGroup",
					fullHeight = true,
					layout = "Flow",
					children = {}
				},
			},
		},
	}
	
	TSMAPI:BuildPage(parent, page)

	
	-- scrolling table
	local colInfo = GetColInfo(parent.frame:GetWidth())
	local stParent = parent.children[1].children[#parent.children[1].children].frame

	if not viewerST then
		viewerST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	viewerST.frame:SetParent(stParent)
	viewerST.frame:SetPoint("BOTTOMLEFT")
	viewerST.frame:SetPoint("TOPRIGHT", 0, -20)
	viewerST.frame:SetScript("OnSizeChanged", function(_,width, height)
			viewerST:SetDisplayCols(GetColInfo(width))
			viewerST:SetDisplayRows(floor(height/16), 16)
		end)
	viewerST:Show()
	viewerST:SetData(GetSTData())
	viewerST.frame:GetScript("OnSizeChanged")(viewerST.frame, viewerST.frame:GetWidth(), viewerST.frame:GetHeight())
	
	for i, col in ipairs(viewerST.head.cols) do
		col:SetHeight(32)
	end
	
	viewerST:RegisterEvents({
		["OnEnter"] = function(_, self, rowData, _, _, rowNum)
			if not rowNum then return end
			local itemID = rowData[rowNum].itemID
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:AddLine(select(2, GetItemInfo(itemID)) or itemID)
			GameTooltip:AddLine()
			
			for name, data in pairs(TSM.characters) do
				local bags = data.bags[itemID] or 0
				local bank = data.bank[itemID] or 0
				local auctions = data.auctions[itemID] or 0
				
				local totalText = "|cffffffff"..(bags+bank+auctions).."|r"
				local bagText = "|cffffffff"..bags.."|r"
				local bankText = "|cffffffff"..bank.."|r"
				local auctionText = "|cffffffff"..auctions.."|r"
			
				if (bags + bank + auctions) > 0 then
					GameTooltip:AddLine(format(L["%s: %s (%s in bags, %s in bank, %s on AH)"], name, totalText, bagText, bankText, auctionText), 1, 1, 0)
				end
			end
			
			for name, data in pairs(TSM.guilds) do
				local gbank = data.items[itemID] or 0
				
				local gbankText = "|cffffffff"..(gbank).."|r"
			
				if gbank > 0 then
					GameTooltip:AddLine(format(L["%s: %s in guild bank"], name, gbankText))
				end
			end
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end})
end

function Config:LoadOptions(parent)
	local players = {}
	for _, v in ipairs(TSM.Data:GetPlayers()) do
		players[v] = v
	end
	
	local syncChars = {}
	for name in pairs(TSM.db.factionrealm.charactersToSync) do
		tinsert(syncChars, name)
	end
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					title = L["Options"],
					layout = "flow",
					children = {
						{
							type = "Dropdown",
							label = "Tooltip:",
							value = TSM.db.profile.tooltip,
							list = {hide=L["No Tooltip Info"], simple=L["Simple"], full=L["Full"]},
							relativeWidth = 0.49,
							callback = function(_,_,value)
									if TSM.db.profile.tooltip == "hide" and value ~= "hide" then
										TSMAPI:RegisterTooltip("TradeSkillMaster_ItemTracker", function(...) return TSM:LoadTooltip(...) end)
									elseif TSM.db.profile.tooltip ~= "hide" and value == "hide" then
										TSMAPI:UnregisterTooltip("TradeSkillMaster_ItemTracker")
									end
									TSM.db.profile.tooltip = value
								end,
							tooltip = L["Here, you can choose what ItemTracker info, if any, to show in tooltips. \"Simple\" will show only show totals for bags/banks and for guild banks. \"Full\" will show detailed information for every character and guild."],
						},
						{
							type = "Dropdown",
							label = L["Delete Character:"],
							list = players,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									local charGuild = TSM.characters[value].guild
									if charGuild then
										TSM.guilds[charGuild].characters[value] = nil
										local hasMembersLeft = false
										for _ in pairs(TSM.guilds[charGuild].characters) do
											hasMembersLeft = true
											break
										end
										if not hasMembersLeft then
											TSM.guilds[charGuild] = nil
										end
									end
									
									TSM.characters[value] = nil
									TSM:Printf(L["\"%s\" removed from ItemTracker."], value)
									players[value] = nil
									self:SetList(players)
									self:SetValue()
								end,
							tooltip = L["If you rename / transfer / delete one of your characters, use this dropdown to remove that character from ItemTracker. There is no confirmation. If you accidentally delete a character that still exists, simply log onto that character to re-add it to ItemTracker."],
						},
					},
				},
				{
					type = "InlineGroup",
					title = L["Multiple Account Sync"],
					layout = "flow",
					children = {
						{
							type = "Label",
							text = L["Enter the name of the characters on your other account which you'd like to sync ItemTracker with below. You must also enter the name of this character in their ItemTracker settings in order to be able to sync. Also, these characters must be on your friends list (ItemTracker will add them if they aren't). All character and guild data will be synced, but only via the characters listed.\n\nEvery time it's loaded, ItemTracker will automatically attempt to sync data with the characters listed below. You can also force a manual sync via the button below."],
							fullWidth = true,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "EditBox",
							label = L["Characters on other account to sync with (comma separated)"],
							value = table.concat(syncChars, ","),
							fullWidth = true,
							callback = function(self, _, value)
									TSM.db.factionrealm.charactersToSync = {}
									for _, player in ipairs({(","):split(value)}) do
										if player ~= "" then
											TSM.db.factionrealm.charactersToSync[strlower(strtrim(player))] = true
										end
									end
								end,
							tooltip = L["List the characters which are not on this account (but on the same realm and faction) that you want ItemTracker to sync with. Separate character names with a single comma."],
						},
						{
							type = "Button",
							text = L["Manually Sync ItemTracker Data"],
							fullWidth = true,
							callback = TSM.Comm.DoSync,
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(parent, page)
end
-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local AuctionTabSaved = TSM:NewModule("AuctionTabSaved")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
local private = {frame=nil, popupInfo={}}


StaticPopupDialogs["TSM_SHOPPING_SAVED_RENAME_POPUP"] = {
	text = L["Type in the new name for this saved search and hit the 'Save' button."],
	button1 = SAVE,
	OnShow = function(self)
		local renameInfo = private.popupInfo.renameInfo
		self.editBox:SetText(renameInfo.name)
		self.editBox:HighlightText()
		self.editBox:SetFocus()
		self.editBox:SetWidth(self.editBox:GetWidth() * 2)
		self.editBox:SetScript("OnEscapePressed", function() StaticPopup_Hide("TSM_SHOPPING_SAVED_RENAME_POPUP") end)
		self.editBox:SetScript("OnEnterPressed", function() self.button1:Click() end)
	end,
	OnAccept = function(self)
		private.popupInfo.renameInfo.name = self.editBox:GetText()
		private.UpdateSTData()
	end,
	hasEditBox = true,
	timeout = 0,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["TSM_SHOPPING_SAVED_EXPORT_POPUP"] = {
	text = L["Press Ctrl-C to copy this saved search."],
	button1 = OKAY,
	OnShow = function(self)
		self.editBox:SetText(private.popupInfo.export)
		self.editBox:HighlightText()
		self.editBox:SetFocus()
		self.editBox:SetScript("OnEscapePressed", function() StaticPopup_Hide("TSM_SHOPPING_SAVED_EXPORT_POPUP") end)
		self.editBox:SetScript("OnEnterPressed", function() self.button1:Click() end)
	end,
	hasEditBox = true,
	timeout = 0,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["TSM_SHOPPING_SAVED_IMPORT_POPUP"] = {
	text = L["Paste the search you'd like to import into the box below."],
	button1 = L["Import"],
	button2 = CANCEL,
	OnShow = function(self)
		self.editBox:SetText("")
		self.editBox:HighlightText()
		self.editBox:SetFocus()
		self.editBox:SetScript("OnEscapePressed", function() StaticPopup_Hide("TSM_SHOPPING_SAVED_IMPORT_POPUP") end)
		self.editBox:SetScript("OnEnterPressed", function() self.button1:Click() end)
	end,
	OnAccept = function(self)
		local text = self.editBox:GetText():trim()
		if text ~= "" then
			local found = false
			-- check if this search already exists
			for i, data in ipairs(TSM.db.global.savedSearches) do
				if data.searchMode == "normal" and strlower(data.filter) == strlower(text) then
					-- update the lastSearch time and return
					data.isFavorite = true
					found = true
					break
				end
			end
			if not found then
				tinsert(TSM.db.global.savedSearches, {searchMode="normal", filter=text, name=text, lastSearch=time(), isFavorite=true})
			end
			TSM:Printf(L["Added '%s' to your favorite searches."], text)
			private.UpdateSTData()
		end
	end,
	hasEditBox = true,
	timeout = 0,
	hideOnEscape = true,
	preferredIndex = 3,
}


function private.SavedSearchSort(a, b)
	return a.lastSearch > b.lastSearch
end

function private.UpdateSTData()
	if not private.frame then return end
	local recentRows = {}
	local favoriteRows = {}
	sort(TSM.db.global.savedSearches, private.SavedSearchSort)
	for i, data in ipairs(TSM.db.global.savedSearches) do
		local name = data.name
		if data.searchMode == "normal" then
			name = L["|cff99ffff[Normal]|r "]..name
		elseif data.searchMode == "crafting" then
			name = L["|cff99ffff[Crafting]|r "]..name
		end
		local row = {
			cols = {{value=name}},
			search = data.filter,
			searchInfo = data,
			index = i,
			name=data.name,
		}
		if data.isFavorite then
			tinsert(favoriteRows, row)
		end
		tinsert(recentRows, row)
	end

	sort(favoriteRows, function(a, b) return strlower(a.name) < strlower(b.name) end)
	private.frame.saved.recentST:SetData(recentRows)
	private.frame.saved.favoriteST:SetData(favoriteRows)
end

function private:StartGroupScan(groupTree)
	local itemOperations, maxQuantity = {}, {}
	for groupName, data in pairs(groupTree:GetSelectedGroupInfo()) do
		groupName = TSMAPI.Groups:FormatPath(groupName, true)
		for _, opName in ipairs(data.operations) do
			TSMAPI.Operations:Update("Shopping", opName)
			local opSettings = TSM.operations[opName]
			if not opSettings then
				-- operation doesn't exist anymore in Auctioning
				TSM:Printf(L["'%s' has a Shopping operation of '%s' which no longer exists. Shopping will ignore this group until this is fixed."], groupName, opName)
			else
				-- it's a valid operation
				for itemString in pairs(data.items) do
					local isValid, err = TSMAPI:ValidateCustomPrice(opSettings.maxPrice)
					if isValid and opSettings.restockQuantity > 0 then
						-- include mail and bags
						local numHave = TSMAPI.Inventory:GetBagQuantity(itemString) + TSMAPI.Inventory:GetMailQuantity(itemString)
						if opSettings.restockSources.bank then
							numHave = numHave + TSMAPI.Inventory:GetBankQuantity(itemString) + TSMAPI.Inventory:GetReagentBankQuantity(itemString)
						end
						if opSettings.restockSources.guild then
							numHave = numHave + TSMAPI.Inventory:GetGuildQuantity(itemString)
						end
						if opSettings.restockSources.alts then
							numHave = numHave + select(2, TSMAPI.Inventory:GetPlayerTotals(itemString))
						end
						if opSettings.restockSources.auctions then
							numHave = numHave + select(3, TSMAPI.Inventory:GetPlayerTotals(itemString))
						end
						if numHave >= opSettings.restockQuantity then
							isValid = false
						else
							maxQuantity[itemString] = opSettings.restockQuantity - numHave
						end
					end
					if isValid then
						itemOperations[itemString] = opSettings
					elseif err then
						TSM:Printf(L["Invalid custom price source for %s. %s"], TSMAPI.Item:GetLink(itemString), err)
					end
				end
			end
		end
	end

	local itemList = {}
	for itemString in pairs(itemOperations) do
		tinsert(itemList, itemString)
	end

	if #itemList == 0 then
		TSM:Print(L["Nothing to search for!"])
		return
	end

	local searchInfo = {searchMode="normal", item=itemList, extraInfo={searchType="group", itemOperations=itemOperations, maxQuantity=maxQuantity}, searchBoxText="~"..L["group search"].."~"}
	TSM.AuctionTab:StartSearch(searchInfo)
end



function AuctionTabSaved:AddRecentSearch(filter, searchMode)
	local name = (#filter > 53) and (strsub(filter, 1, 50).."...") or filter

	-- check if this recent search already exists
	for i, data in ipairs(TSM.db.global.savedSearches) do
		if data.searchMode == searchMode and strlower(data.filter) == strlower(filter) then
			-- update the lastSearch time and return
			data.lastSearch = time()
			sort(TSM.db.global.savedSearches, private.SavedSearchSort)
			return
		end
	end

	tinsert(TSM.db.global.savedSearches, {searchMode=searchMode, filter=filter, name=name, lastSearch=time()})
	sort(TSM.db.global.savedSearches, private.SavedSearchSort)

	-- only keep 100 recent searches
	local numRecent = 0
	local toRemove = {}
	for i, data in ipairs(TSM.db.global.savedSearches) do
		if not data.isFavorite then
			numRecent = numRecent + 1
			if numRecent > 100 then
				tinsert(toRemove, i)
			end
		end
	end
	sort(toRemove)
	for i=#toRemove, 1, -1 do
		tremove(TSM.db.global.savedSearches, toRemove[i])
	end
end

function private.RunSavedSearch(index, isFavoriteST)
	local searchInfo = CopyTable(TSM.db.global.savedSearches[index])
	searchInfo.extraInfo = {searchType="filter"}
	if isFavoriteST then
		for i=index+1, #TSM.db.global.savedSearches do
			if TSM.db.global.savedSearches[i].isFavorite then
				-- setup the next search
				searchInfo.extraInfo.continue = {
					tooltip = L["Shift-Click to run the next favorite search."],
					callback = function()
						private.RunSavedSearch(i, true)
					end,
				}
				break
			end
		end
	end
	TSM.AuctionTab:StartSearch(searchInfo)
end

function AuctionTabSaved:GetFrameInfo()
	local stHandlers = {
		OnClick = function(st, data, _, button)
			if not data then return end
			if button == "LeftButton" then
				if IsShiftKeyDown() then
					if data.searchInfo.searchMode == "normal" then
						private.popupInfo.export = data.search
						TSMAPI.Util:ShowStaticPopupDialog("TSM_SHOPPING_SAVED_EXPORT_POPUP")
					else
						TSM:Print(L["Only exporting normal mode searches is allows."])
					end
				elseif IsControlKeyDown() then
					private.popupInfo.renameInfo = data.searchInfo
					TSMAPI.Util:ShowStaticPopupDialog("TSM_SHOPPING_SAVED_RENAME_POPUP")
				else
					private.RunSavedSearch(data.index, st == private.frame.saved.favoriteST)
				end
			elseif button == "RightButton" then
				if st == private.frame.saved.recentST then
					if IsShiftKeyDown() then
						tremove(TSM.db.global.savedSearches, data.index)
						TSM:Printf(L["Removed '%s' from your recent searches."], data.searchInfo.name)
						private.UpdateSTData()
					else
						data.searchInfo.isFavorite = true
						TSM:Printf(L["Added '%s' to your favorite searches."], data.searchInfo.name)
						private.UpdateSTData()
					end
				elseif st == private.frame.saved.favoriteST then
					data.searchInfo.isFavorite = nil
					TSM:Printf(L["Removed '%s' from your favorite searches."], data.searchInfo.name)
				end
				private.UpdateSTData()
			end
		end,
		OnEnter = function(st, data, self)
			if not data then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(data.search, 1, 1, 1, true)
			GameTooltip:AddLine("")
			local color = TSMAPI.Design:GetInlineColor("link")
			if st == private.frame.saved.recentST then
				GameTooltip:AddLine(color..L["Left-Click to run this search."], 1, 1, 1, true)
				GameTooltip:AddLine(color..L["Shift-Left-Click to export this search."], 1, 1, 1, true)
				GameTooltip:AddLine(color..L["Ctrl-Left-Click to rename this search."], 1, 1, 1, true)
				GameTooltip:AddLine(color..L["Right-Click to favorite this recent search."], 1, 1, 1, true)
				GameTooltip:AddLine(color..L["Shift-Right-Click to remove this recent search."], 1, 1, 1, true)
			elseif st == private.frame.saved.favoriteST then
				GameTooltip:AddLine(color..L["Left-Click to run this search."], 1, 1, 1, true)
				GameTooltip:AddLine(color..L["Shift-Left-Click to export this search."], 1, 1, 1, true)
				GameTooltip:AddLine(color..L["Ctrl-Left-Click to rename this search."], 1, 1, 1, true)
				GameTooltip:AddLine(color..L["Right-Click to remove from favorite searches."], 1, 1, 1, true)
			end
			GameTooltip:Show()
		end,
		OnLeave = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end
	}

	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		points = "ALL",
		key = "saved",
		hidden = true,
		scripts = {"OnShow"},
		children = {
			{
				type = "Frame",
				key = "saved",
				points = {{"TOPLEFT", 4, -4}, {"BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -4, 4}},
				children = {
					{
						type = "ScrollingTableFrame",
						key = "recentST",
						stCols = {{name=L["Recent Searches"], width=1}},
						stDisableSelection = true,
						points = {{"TOPLEFT"}, {"BOTTOMRIGHT", BFC.PARENT, "RIGHT", 0, 2}},
						scripts = {"OnClick", "OnEnter", "OnLeave"},
					},
					{
						type = "ScrollingTableFrame",
						key = "favoriteST",
						stCols = {{name=L["Favorite Searches"], width=1}},
						stDisableSelection = true,
						points = {{"TOPLEFT", BFC.PARENT, "LEFT", 0, -2}, {"BOTTOMRIGHT", 0, 26}},
						scripts = {"OnClick", "OnEnter", "OnLeave"},
					},
					{
						type = "Button",
						key = "importBtn",
						text = L["Import Favorite Search"],
						textHeight = 18,
						size = {0, 22},
						points = {{"BOTTOMLEFT", 2, 2}, {"BOTTOMRIGHT", -2, 2}},
						scripts = {"OnClick"},
					},
				},
			},
			{
				type = "VLine",
				size = {2, 0},
				points = {{"TOP"}, {"BOTTOM"}},
			},
			{
				type = "Frame",
				key = "group",
				points = {{"TOPLEFT", BFC.PARENT, "TOP", 4, -4}, {"BOTTOMRIGHT", -4, 4}},
				children = {
					{
						type = "GroupTreeFrame",
						key = "groupTree",
						groupTreeInfo = {"Shopping", "Shopping_AH"},
						points = {{"TOPLEFT", 0, -35}, {"BOTTOMRIGHT", 0, 30}},
					},
					{
						type = "Text",
						text = L["Select the groups which you would like to include in the search."],
						justify = {"CENTER", "MIDDLE"},
						size = {0, 35},
						points = {{"TOPLEFT"}, {"TOPRIGHT"}},
					},
					{
						type = "Button",
						key = "startBtn",
						text = L["Start Search"],
						textHeight = 18,
						size = {0, 20},
						points = {{"BOTTOMLEFT", 2, 2}, {"BOTTOMRIGHT", -2, 2}},
						scripts = {"OnClick"},
					},
				},
			},
		},
		handlers = {
			OnShow = function(self)
				private.frame = self
				private.UpdateSTData()
			end,
			saved = {
				recentST = stHandlers,
				favoriteST = stHandlers,
				importBtn = {
					OnClick = function() TSMAPI.Util:ShowStaticPopupDialog("TSM_SHOPPING_SAVED_IMPORT_POPUP") end,
				},
			},
			group = {
				startBtn = {
					OnClick = function(self) private:StartGroupScan(self:GetParent().groupTree) end,
				},
			},
		},
	}
	return frameInfo
end

-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Shopping - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_shopping.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local Config = TSM:GetModule("Config")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table


local function ValidateItemID(value)
	if not value or not tonumber(value) then return end
	value = tonumber(value)
	if value > 0 and value < 100000 then
		return value
	end
end

local function ProcessList(data)
	if type(data) ~= "string" then return end
	
	local version, listType, listData
	if strsub(data, -1) == "@" and strsub(data, 3, 3) == "@" then
		listType = strsub(data, 1, 1)
		version = tonumber(strsub(data, 2, 2))
		listData = strsub(data, 4, -2)
	end
	
	if not version or not listData or listData == "" or (listType ~= "s" and listType ~= "d") then
		return
	end
	
	return listType == "s" and "shopping" or "dealfinding", version, listData
end

function Config:EncodeShoppingList(listName)
	local	items, searchTerms = {}, {}
	
	for itemID, data in pairs(TSM.db.profile.shopping[listName]) do
		if itemID == "searchTerms" then
			for _, term in ipairs(data) do
				tinsert(searchTerms, term)
			end
		else
			tinsert(items, itemID)
		end
	end
	
	local itemsString = table.concat(items, ",")
	local termsString = table.concat(searchTerms, ";")
	return "s1@" .. itemsString .. "$" .. termsString .. "@"
end

function Config:ImportShoppingList(listData, listName)
	local itemsString, termsString, extraArg = ("$"):split(listData)
	if not itemsString or not termsString or extraArg then
		return
	end
	
	TSM.db.profile.shopping[listName] = {searchTerms={}}
	
	for _, item in ipairs({(","):split(itemsString)}) do
		local itemID = tonumber(item)
		if itemID then
			TSM.db.profile.shopping[listName][itemID] = {name=(GetItemInfo(itemID) or itemID)}
		end
	end
	
	for _, term in ipairs({(";"):split(termsString)}) do
		if term ~= "" then
			tinsert(TSM.db.profile.shopping[listName].searchTerms, term)
		end
	end
	
	return true
end

function Config:EncodeDealfindingList(listName)
	local	items = {}
	
	for itemID, data in pairs(TSM.db.profile.dealfinding[listName]) do
		local str = itemID .. "/" .. data.maxPrice .. (data.evenStacks and "/" or "")
		tinsert(items, str)
	end
	
	local dataString = table.concat(items, ",")
	return "d1@" .. dataString .. "@"
end

function Config:ImportDealfindingList(listData, listName, excludeExisting)
	if not listData then return end
	
	local existingItems = {}
	for listName, items in pairs(TSM.db.profile.dealfinding) do
		for itemID in pairs(items) do
			existingItems[itemID] = listName
		end
	end
	TSM.db.profile.dealfinding[listName] = {}
	
	for _, itemStr in ipairs({(","):split(listData)}) do
		local itemID, maxPrice, evenStacks = ("/"):split(itemStr)
		itemID, maxPrice = tonumber(itemID), tonumber(maxPrice)
		evenStacks = evenStacks and true or nil
		if itemID and maxPrice then
			if not existingItems[itemID] or not excludeExisting then
				TSM.db.profile.dealfinding[listName][itemID] = {name=(GetItemInfo(itemID) or itemID), maxPrice=maxPrice, evenStacks=evenStacks}
				if existingItems[itemID] and not excludeExisting then
					TSM.db.profile.dealfinding[existingItems[itemID]][itemID] = nil
				end
			end
		end
	end
	
	return true
end

function Config:EncodeList(listType, listName)
	if not TSM.db.profile[listType][listName] then
		error("List does not exist: "..(listType or "<nil>")..", "..(listName or "<nil>"))
	end
	
	if listType == "shopping" then
		return Config:EncodeShoppingList(listName)
	elseif listType == "dealfinding" then
		return Config:EncodeDealfindingList(listName)
	end
end

function Config:ImportList(listType, listName, listData, excludeExisting)
	if listType == "shopping" then
		return Config:ImportShoppingList(listData, listName)
	elseif listType == "dealfinding" then
		return Config:ImportDealfindingList(listData, listName, excludeExisting)
	end
end

function Config:OpenImportFrame(listType)
	local listName, listData
	local excludeExisting = true

	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TSM_Shopping - "..L["Import List"])
	f:SetLayout("Flow")
	f:SetHeight(300)
	
	local eb = AceGUI:Create("TSMEditBox")
	eb:SetLabel(L["List Name"])
	eb:SetRelativeWidth(0.5)
	eb:SetCallback("OnEnterPressed", function(_,_,value) listName = value:trim() end)
	f:AddChild(eb)
	
	if listType == "dealfinding" then
		local cb = AceGUI:Create("TSMCheckBox")
		cb:SetValue(excludeExisting)
		cb:SetLabel(L["Ignore Existing Items"])
		cb:SetRelativeWidth(0.5)
		cb:SetCallback("OnValueChanged", function(_,_,value) excludeExisting = value end)
		f:AddChild(cb)
	end
	
	local spacer = AceGUI:Create("Label")
	spacer:SetFullWidth(true)
	spacer:SetText(" ")
	f:AddChild(spacer)
	
	local btn = AceGUI:Create("TSMButton")
	
	local eb = AceGUI:Create("MultiLineEditBox")
	eb:SetLabel(L["List Data"])
	eb:SetFullWidth(true)
	eb:SetMaxLetters(0)
	eb:SetCallback("OnEnterPressed", function(_,_,data) btn:SetDisabled(false) listData = data:trim() end)
	f:AddChild(eb)
	
	btn:SetDisabled(true)
	btn:SetText(L["Import List"])
	btn:SetFullWidth(true)
	btn:SetCallback("OnClick", function()
			local iType, iVersion, iData = ProcessList(listData)
			if not iType then
				TSM:Print(L["The data you are trying to import is invalid."])
				return
			elseif iType ~= listType then
				if listType == "dealfinding" then
					TSM:Print(L["The list you are trying to import is not a dealfinding list. Please use the shopping list import feature instead."])
				else
					TSM:Print(L["The list you are trying to import is not a shopping list. Please use the dealfinding list import feature instead."])
				end
				return
			end
			
			if not listName or TSM.db.profile[listType][listName] then
				listName = listName or L["Imported List"]
				local newName = listName
				for i=1, 10000 do
					if not TSM.db.profile[listType][newName] then break end
					newName = listName .. i
				end
				listName = newName
			end
			
			if not Config:ImportList(iType, listName, iData, excludeExisting) then
				TSM:Print(L["The data you are trying to import is invalid."])
				return
			end
			
			Config:UpdateTree()
			Config:SelectTreePath(listType, listName)
			f:Hide()
			TSM:Printf(L["Data Imported to Group: %s"], listName)
		end)
	f:AddChild(btn)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end

function Config:OpenExportFrame(listType, listName)
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TSM_Shopping - "..L["Export List"])
	f:SetLayout("Flow")
	f:SetHeight(200)	
	local l = AceGUI:Create("Label")
	
	local eb = AceGUI:Create("MultiLineEditBox")
	eb:SetLabel(L["List Data (just select all and copy the data from inside this box)"])
	eb:SetText(Config:EncodeList(listType, listName))
	eb:SetFullWidth(true)
	eb:SetMaxLetters(0)
	eb:SetCallback("OnEnterPressed", function(_,_,data) btn:SetDisabled(false) listData = data end)
	f:AddChild(eb)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end
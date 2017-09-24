-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- This file contains all the code for the profession pages

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local ProfessionConfig = TSM:NewModule("ProfessionConfig", "AceEvent-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table

-- some static variables for easy changing of frame dimmensions
-- these values are what the frame starts out using but the user can resize it from there
local TREE_WIDTH = 150 -- the width of the tree part of the frame
local FRAME_WIDTH = 780 -- width of the entire frame
local FRAME_HEIGHT = 700 -- height of the entire frame
local BIG_NUMBER = 100000000000 -- 10 million gold
local ROW_HEIGHT = 16

-- color codes
local GREEN = "|cff00ff00"
local RED = "|cffff0000"
local WHITE = "|cffffffff"
local GOLD = "|cffffbb00"
local YELLOW = "|cffffd000"

local offsets, currentPage = {}, {}

-- scrolling tables
local matST

local function getIndex(t, value)
	for i, v in pairs(t) do
		if v == value then
			return i
		end
	end
end

function ProfessionConfig:OnEnable()
	TSM.mode = "Enchanting"

	local names, textures = {}, {}
	for _, data in pairs(TSM.tradeSkills) do
		local name, _, texture = GetSpellInfo(data.spellID)
		tinsert(names, name)
		tinsert(textures, texture)
	end

	for i=1, #(names) do
		TSMAPI:RegisterIcon("Crafting - "..names[i], textures[i], function(...) ProfessionConfig:Load(i, ...) end, "TradeSkillMaster_Crafting", "crafting")
	end
end

-- setup the main frame / structure
function ProfessionConfig:Load(num, parent)
	local treeGroupStatus = {treewidth = TREE_WIDTH, groups = TSM.db.global.treeStatus}

	-- Create the main tree-group that will control and contain the entire GUI
	ProfessionConfig.TreeGroup = AceGUI:Create("TSMTreeGroup")
	ProfessionConfig.TreeGroup:SetLayout("Fill")
	ProfessionConfig.TreeGroup:SetCallback("OnGroupSelected", function(...) ProfessionConfig:SelectTree(...) end)
	ProfessionConfig.TreeGroup:SetStatusTable(treeGroupStatus)
	parent:AddChild(ProfessionConfig.TreeGroup)

	local treeStructure = {{value = 1, text = L["Crafts"], children = {}}, {value = 2, text = L["Materials"]}, {value = 3, text = L["Options"]}}

	if num <= #(TSM.tradeSkills) then
		TSM.mode = TSM.tradeSkills[num].name
		local slotList = TSM[TSM.mode].slotList
		if TSM.mode == "Inscription" then
			slotList = TSM.Inscription:GetSlotList()
		end
		for i=1, #(slotList) do
			tinsert(treeStructure[1].children, {value = i, text = slotList[i]})
		end
		ProfessionConfig.TreeGroup:SetTree(treeStructure)
		ProfessionConfig.TreeGroup:SelectByPath(1)

		local lastScan = TSM.db.profile.lastScan[TSM.mode]
		if not lastScan or (time() - lastScan) > 60*60 then
			TSM.Scan:ScanProfession(TSM.mode)
		elseif TSM.mode == "Inscription" then
			for itemID, craft in pairs(TSM.Data[TSM.mode].crafts) do
				craft.group = TSM[TSM.mode]:GetSlot(itemID, craft.mats)
			end
		end
	end
end

-- controls what is drawn on the right side of the GUI window
-- this is based on what is selected in the "tree" on the left (ex 'Options'->'Remove Crafts')
function ProfessionConfig:SelectTree(treeFrame, optionsPage, selection)
	-- decodes and seperates the selection string from AceGUIWidget-TreeGroup
	local selectedParent, selectedChild = ("\001"):split(selection)
	selectedParent = tonumber(selectedParent) -- the main group that's selected (Crafts, Materials, Options, etc)
	selectedChild = tonumber(selectedChild) -- the child group that's if there is one (2H Weapon, Boots, Chest, etc)

	if treeFrame.children and treeFrame.children[1] and treeFrame.children[1].children and treeFrame.children[1].children[1] and treeFrame.children[1].children[1].type == "TSMScrollFrame" and treeFrame.children[1].children[1].localstatus then
		offsets[currentPage.parent][currentPage.child] = treeFrame.children[1].children[1].localstatus.offset
	end

	-- prepare the TreeFrame for a new container which will hold everything that is drawn on the right part of the GUI
	treeFrame:ReleaseChildren()
	TSM.Queue:UpdateQueue(TSM.mode)
	currentPage = {parent=selectedParent, child=(selectedChild or 0)}

	-- a simple group to provide a fresh layout to whatever is put inside of it
	-- just acts as an invisible layer between the TreeGroup and whatever is drawn inside of it
	local container = AceGUI:Create("TSMSimpleGroup")
	container:SetLayout("Fill")
	treeFrame:AddChild(container)

	-- figures out which tree element is selected
	-- then calls the correct function to build that part of the GUI
	if selectedParent == 1 then
		if selectedChild then
			ProfessionConfig:LoadSubCraftsPage(container, selectedChild)
		else
			ProfessionConfig:LoadCraftsPage(container)
		end
	elseif selectedParent == 2 then -- Materials summary page
		ProfessionConfig:LoadMaterialsPage(container)
	elseif selectedParent == 3 then -- Options page
		ProfessionConfig:LoadProfessionOptions(container)
	end

	offsets[currentPage.parent] = offsets[currentPage.parent] or {}
	offsets[currentPage.parent][currentPage.child] = offsets[currentPage.parent][currentPage.child] or 0
	if container.children and container.children[1] and container.children[1].type == "TSMScrollFrame" then
		container.children[1].localstatus.offset = offsets[currentPage.parent][currentPage.child]
	end
end

 -- Front Crafts page
function ProfessionConfig:LoadCraftsPage(container)
	-- checks if a table has at least one element in it
	local function hasElements(sTable)
		local isTable = false
		for i, v in pairs(sTable) do
			return true
		end
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "Label",
					text = "TradeSkillMaster_Crafting v" .. TSM.version .. " " .. L["Status"] .. ": " .. TSMAPI.Design:GetInlineColor("link") .. TSM.mode .. "|r\n",
					fontObject = GameFontNormalHuge,
					fullWidth = true,
				},
				{
					type = "Spacer"
				},
				{
					type = "Label",
					text = TSMAPI.Design:GetInlineColor("link") .. L["Use the links on the left to select which page to show."] .. "|r",
					fontObject = GameFontNormalLarge,
					fullWidth = true,
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Button",
					text = L["Show Craft Management Window"],
					relativeWidth = 1,
					height = 30,
					callback = function()
							TSMAPI:CloseFrame()
							TSM.Crafting:OpenFrame()
						end,
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Button",
					text = L["Force Rescan of Profession (Advanced)"],
					relativeWidth = 1,
					callback = function()
							TSM.Scan:ScanProfession(TSM.mode)
						end,
				},
			},
		},
	}

	if TSM.db.profile.minRestockQuantity.default > TSM.db.profile.maxRestockQuantity.default then
		-- Popup Confirmation Window used in this module
		StaticPopupDialogs["TSMCrafting.Warning2"] = StaticPopupDialogs["TSMCrafting.Warning2"] or {
			text = L["Warning: Your default minimum restock quantity is higher than your maximum restock quantity! Visit the \"Craft Management Window\" section of the Crafting options to fix this!\n\nYou will get error messages printed out to chat if you try and perform a restock queue without fixing this."],
			button1 = L["OK"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("TSMCrafting.Warning2")
	end

	TSMAPI:BuildPage(container, page)
end

-- Craft Pages
local craftsST
function ProfessionConfig:LoadSubCraftsPage(container, slot)
	ProfessionConfig:HookScript(container.frame, "OnHide", function() ProfessionConfig:UnhookAll() if ProfessionConfig.OpenWindow then ProfessionConfig.OpenWindow:Hide() end if craftsST then craftsST:Hide() craftsST:SetData({}) end end)
	local function ShowAdditionalSettings(parent, itemID, data)
		if ProfessionConfig.OpenWindow then ProfessionConfig.OpenWindow:Hide() end

		local window = AceGUI:Create("TSMWindow")
		window.frame:SetParent(container.frame)
		window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		window:SetWidth(500)
		window:SetHeight(440)
		window:SetTitle(L["Add Item to TSM_Auctioning"])
		window:SetLayout("Flow")
		window.frame:SetFrameLevel(container.frame:GetFrameLevel() + 10)
		window.frame:SetPoint("TOPRIGHT", parent.frame, "TOPLEFT")
		window:SetCallback("OnClose", function(self)
				self:ReleaseChildren()
				ProfessionConfig.OpenWindow = nil
			end)
		ProfessionConfig.OpenWindow = window

		local groupSelection, newGroupName, inAuctioningGroup
		local auctioningGroupList = {}
		local auctioningGroups = TSMAPI:GetData("auctioningGroups")
		for groupName, items in pairs(TSMAPI:GetData("auctioningGroups")) do
			auctioningGroupList[groupName] = groupName
			if items[itemID] then
				inAuctioningGroup = groupName
			end
		end

		local page = {
			{
				type = "InteractiveLabel",
				text = select(2, GetItemInfo(itemID)) or data.name,
				fontObject = GameFontHighlight,
				relativeWidth = 1,
				callback = function() SetItemRef("item:".. itemID, itemID) end,
				tooltip = itemID,
			},
			{
				type = "HeadingLine"
			},
			{
				type = "Dropdown",
				label = L["TSM_Auctioning Group to Add Item to:"],
				list = auctioningGroupList,
				value = 1,
				relativeWidth = 0.49,
				callback = function(self, _, value)
						value = value:trim()
						groupSelection = value
						local i = getIndex(self.parent.children, self)
						self.parent.children[i+2]:SetDisabled(not value or value == "")
					end,
				tooltip = L["Which group in TSM_Auctioning to add this item to."],
			},
			{
				type = "Label",
				text = "",
				relativeWidth = 0.02,
			},
			{
				type = "Button",
				text = L["Add Item to Selected Group"],
				relativeWidth = 0.49,
				disabled = true,
				callback = function(self)
						if groupSelection then
							TSM:SendMessage("TSMAUC_NEW_GROUP_ITEM", groupSelection, itemID)
							window.frame:Hide()
						end
					end,
			},
			{
				type = "Spacer"
			},
			{
				type = "EditBox",
				label = L["Name of New Group to Add Item to:"],
				relativeWidth = 0.49,
				callback = function(self, _, value)
						value = value:trim()
						local i = getIndex(self.parent.children, self)
						self.parent.children[i+2]:SetDisabled(not value or value == "")
						newGroupName = value
					end,
			},
			{
				type = "Label",
				text = "",
				relativeWidth = 0.02,
			},
			{
				type = "Button",
				text = L["Add Item to New Group"],
				relativeWidth = 0.49,
				disabled = true,
				callback = function(self)
						if newGroupName then
							TSM:SendMessage("TSMAUC_NEW_GROUP_ITEM", newGroupName, itemID, true)
							window.frame:Hide()
						end
					end,
			},
			{
				type = "HeadingLine"
			},
			{
				type = "CheckBox",
				label = L["Override Max Restock Quantity"],
				value = TSM.db.profile.maxRestockQuantity[itemID] and true,
				callback = function(self, _, value)
						if value then
							TSM.db.profile.maxRestockQuantity[itemID] = TSM.db.profile.maxRestockQuantity.default
						else
							TSM.db.profile.maxRestockQuantity[itemID] = nil
						end
						local siblings = self.parent.children --aw how cute...siblings ;)
						local i = getIndex(siblings, self)
						siblings[i+2]:SetDisabled(not value)
						siblings[i+2]:SetText(TSM.db.profile.maxRestockQuantity[itemID] or "")
						siblings[i+3]:SetDisabled(not value)
						siblings[i+4]:SetDisabled(not value)
					end,
				tooltip = L["Allows you to set a custom maximum queue quantity for this item."],
			},
			{
				type = "Label",
				text = "",
				relativeWidth = 0.1,
			},
			{
				type = "EditBox",
				label = L["Max Restock Quantity"],
				value = TSM.db.profile.maxRestockQuantity[itemID],
				disabled = TSM.db.profile.maxRestockQuantity[itemID] == nil,
				relativeWidth = 0.2,
				callback = function(self, _, value)
						value = tonumber(value)
						if value and value >= 0 then
							TSM.db.profile.maxRestockQuantity[itemID] = value
						end
					end,
			},
			{	-- plus sign for incrementing the number
				type = "Icon",
				image = "Interface\\Buttons\\UI-PlusButton-Up",
				width = 24,
				imageWidth = 24,
				imageHeight = 24,
				disabled = TSM.db.profile.maxRestockQuantity[itemID] == nil,
				callback = function(self)
						local value = (TSM.db.profile.maxRestockQuantity[itemID] or 0) + 1
						TSM.db.profile.maxRestockQuantity[itemID] = value

						local i = getIndex(self.parent.children, self)
						self.parent.children[i-1]:SetText(value)
					end,
			},
			{	-- minus sign for decrementing the number
				type = "Icon",
				image = "Interface\\Buttons\\UI-MinusButton-Up",
				disabled = true,
				width = 24,
				imageWidth = 24,
				imageHeight = 24,
				disabled = TSM.db.profile.maxRestockQuantity[itemID] == nil,
				callback = function(self)
						local value = (TSM.db.profile.maxRestockQuantity[itemID] or 0) - 1
						if value < 1 then value = 0 end

						if value < (TSM.db.profile.minRestockQuantity[itemID] or TSM.db.profile.minRestockQuantity.default) then
							value = TSM.db.profile.minRestockQuantity[itemID] or TSM.db.profile.minRestockQuantity.default
							TSM:Printf(L["Can not set a max restock quantity below the minimum restock quantity of %d."], value)
						end
						TSM.db.profile.maxRestockQuantity[itemID] = value

						local i = getIndex(self.parent.children, self)
						self.parent.children[i-2]:SetText(value)
					end,
			},
			{
				type = "CheckBox",
				label = L["Override Min Restock Quantity"],
				value = TSM.db.profile.minRestockQuantity[itemID] and true,
				relativeWidth = 0.6,
				callback = function(self, _, value)
						if value then
							TSM.db.profile.minRestockQuantity[itemID] = TSM.db.profile.minRestockQuantity.default
						else
							TSM.db.profile.minRestockQuantity[itemID] = nil
						end
						local siblings = self.parent.children
						local i = getIndex(siblings, self)
						siblings[i+1]:SetDisabled(not value)
						siblings[i+1]:SetText(TSM.db.profile.minRestockQuantity[itemID] or "")
						siblings[i+2]:SetDisabled(not value)
						siblings[i+3]:SetDisabled(not value)
					end,
				tooltip = L["Allows you to set a custom minimum queue quantity for this item."],
			},
			{
				type = "EditBox",
				label = L["Min Restock Quantity"],
				value = TSM.db.profile.minRestockQuantity[itemID],
				disabled = TSM.db.profile.minRestockQuantity[itemID] == nil,
				relativeWidth = 0.2,
				callback = function(_, _, value)
						value = tonumber(value)
						if value and value >= 0 then
							TSM.db.profile.minRestockQuantity[itemID] = value
						end
					end,
				tooltip = L["This item will only be added to the queue if the number being added " ..
					"is greater than or equal to this number. This is useful if you don't want to bother with " ..
					"crafting singles for example."],
			},
			{	-- plus sign for incrementing the number
				type = "Icon",
				image = "Interface\\Buttons\\UI-PlusButton-Up",
				width = 24,
				imageWidth = 24,
				imageHeight = 24,
				disabled = TSM.db.profile.minRestockQuantity[itemID] == nil,
				callback = function(self)
						local value = (TSM.db.profile.minRestockQuantity[itemID] or 0) + 1
						if value > (TSM.db.profile.maxRestockQuantity[itemID] or TSM.db.profile.maxRestockQuantity.default) then
							value = TSM.db.profile.maxRestockQuantity[itemID] or TSM.db.profile.maxRestockQuantity.default
							TSM:Printf("Can not set a min restock quantity above the max restock quantity of %d.", value)
						end
						TSM.db.profile.minRestockQuantity[itemID] = value

						local i = getIndex(self.parent.children, self)
						self.parent.children[i-1]:SetText(value)
					end,
			},
			{	-- minus sign for decrementing the number
				type = "Icon",
				image = "Interface\\Buttons\\UI-MinusButton-Up",
				disabled = true,
				width = 24,
				imageWidth = 24,
				imageHeight = 24,
				disabled = TSM.db.profile.minRestockQuantity[itemID] == nil,
				callback = function(self)
						local value = TSM.db.profile.minRestockQuantity[itemID] - 1
						if value < 1 then value = 0 end
						TSM.db.profile.minRestockQuantity[itemID] = value

						local i = getIndex(self.parent.children, self)
						self.parent.children[i-2]:SetText(value)
					end,
			},
			{
				type = "CheckBox",
				label = L["Ignore Seen Count Filter"],
				quickCBInfo = {TSM.db.profile.ignoreSeenCountFilter, itemID},
				tooltip = L["Allows you to set a custom minimum queue quantity for this item."],
			},
			{
				type = "Label",
				text = "",
				relativeWidth = 0.4
			},
			{
				type = "CheckBox",
				label = L["Don't queue this item."],
				quickCBInfo = {TSM.db.profile.dontQueue, itemID},
				tooltip = L["This item will not be queued by the \"Restock Queue\" ever."],
			},
			{
				type = "CheckBox",
				label = L["Always queue this item."],
				quickCBInfo = {TSM.db.profile.alwaysQueue, itemID},
				tooltip = L["This item will always be queued (to the max restock quantity) regardless of price data."],
			},
		}

		if inAuctioningGroup then
			for i=1, 7 do
				tremove(page, 3)
			end
			tinsert(page, 3, {
					type = "Label",
					text = format(L["This item is already in the \"%s\" Auctioning group."], inAuctioningGroup),
					relativeWidth = 1,
				})
		end

		TSMAPI:BuildPage(window, page)
	end

	local function DrawCreateAuctioningGroups(parent)
		if ProfessionConfig.OpenWindow then ProfessionConfig.OpenWindow:Hide() end

		local window = AceGUI:Create("TSMWindow")
		window.frame:SetParent(container.frame)
		window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		window:SetWidth(560)
		window:SetHeight(300)
		window:SetTitle(L["Export Crafts to TradeSkillMaster_Auctioning"])
		window:SetLayout("flow")
		window.frame:SetPoint("TOPRIGHT", parent.frame, "TOPLEFT")
		window:SetCallback("OnClose", function(self)
				self:ReleaseChildren()
				ProfessionConfig.OpenWindow = nil
				window.frame:Hide()
			end)
		ProfessionConfig.OpenWindow = window

		local moveCrafts = false
		local onlyEnabled = true
		local targetCategory = "None"
		local groupStyle = "oneGroup"
		local groupSelection = "newGroup"

		local auctioningGroups = {["newGroup"] = L["<New Group>"]}
		for name in pairs(TSMAPI:GetData("auctioningGroups")) do
			auctioningGroups[name] = name
		end
		local auctioningCategories = {["None"]=L["<No Category>"]}
		for name in pairs(TSMAPI:GetData("auctioningCategories")) do
			auctioningCategories[name] = name
		end

		local page = {
			{
				type = "Label",
				text = L["Select the crafts you would like to add to Auctioning and use the settings / buttons below to do so."],
				relativeWidth = 1,
			},
			{
				type = "HeadingLine",
			},
			{
				type = "Dropdown",
				list = auctioningCategories,
				value = targetCategory,
				relativeWidth = 0.5,
				label = L["Category to put groups into:"],
				callback = function(_,_,value) targetCategory = value end,
				tooltip = L["You can select a category that group(s) will be added to or select \"<No Category>\" to not add the group(s) to a category."],
			},
			{
				type = "Dropdown",
				list = {["indivGroups"]=L["All in Individual Groups"], ["oneGroup"]=L["All in Same Group"]},
				value = groupStyle,
				relativeWidth = 0.5,
				label = L["How to add crafts to Auctioning:"],
				callback = function(self,_,value)
						groupStyle = value
						local i = getIndex(self.parent.children, self)
						self.parent.children[i+1]:SetDisabled(value ~= "oneGroup")
					end,
				tooltip = L["You can either add every craft to one group or make individual groups for each craft."],
			},
			{
				type = "Dropdown",
				list = auctioningGroups,
				relativeWidth = 0.5,
				value = groupSelection,
				label = L["Group to Add Crafts to:"],
				disabled = groupStyle ~= "oneGroup",
				callback = function(self,_,value)
						groupSelection = value
					end,
				tooltip = L["Select an Auctioning group to add these crafts to."],
			},
			{
				type = "CheckBox",
				label = L["Include Crafts Already in a Group"],
				value = moveCrafts,
				callback = function(_,_,value) moveCrafts = value end,
				tooltip = L["If checked, any crafts which are already in an Auctioning group will be removed from their current group and a new group will be created for them. If you want to maintain the groups you already have setup that include items in this group, leave this unchecked."],
			},
			{
				type = "CheckBox",
				label = L["Only Included Enabled Crafts"],
				value = onlyEnabled,
				relativeWidth = 1,
				callback = function(_,_,value) onlyEnabled = value end,
				tooltip = L["If checked, Only crafts that are enabled (have the checkbox to the right of the item link checked) below will be added to Auctioning groups."],
			},
			{
				type = "Button",
				text = L["Add Crafted Items from this Group to Auctioning Groups"],
				relativeWidth = 1,
				callback = function(self)
						local groups = TSMAPI:GetData("auctioningGroups")
						local function CreateGroupName(name)
							for i=1, 100 do -- it's the user's fault if they have more than 100 groups named this...
								local gName = strlower(name..(i==1 and "" or i))
								if not groups[gName] then
									return gName
								end
							end
						end

						local itemLookup = {}
						for groupName, items in pairs(groups) do
							for itemID in pairs(items) do
								itemLookup[itemID] = groupName
							end
						end

						local groupName
						local currentSlot = (TSM.mode == "Inscription" and TSM.Inscription:GetSlotList() or TSM[TSM.mode].slotList)[slot]
						if groupStyle == "oneGroup" then
							groupName = (groupSelection ~= "newGroup" and groupSelection or CreateGroupName(TSM.mode.." - "..currentSlot))
							TSM:SendMessage("TSMAUC_NEW_GROUP_ITEM", groupName, nil, groupSelection == "newGroup", targetCategory ~= "None" and targetCategory)
						end

						local count = 0
						for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
							if data.group == slot then
								-- make sure the item isn't already in a group (or the checkbox is checked to ignore this)
								if (not itemLookup[itemID] or moveCrafts) and (onlyEnabled and data.enabled or not onlyEnabled) then
									count = count + 1
									if not groupName then
										local tempName = CreateGroupName(GetItemInfo(itemID) or data.name)
										TSM:SendMessage("TSMAUC_NEW_GROUP_ITEM", tempName, itemID, true, targetCategory ~= "None" and targetCategory)
									else
										TSM:SendMessage("TSMAUC_NEW_GROUP_ITEM", groupName, itemID)
									end
								end
							end
						end

						if groupName then
							TSM:Printf(L["Added %s crafted items to: %s."], count, "\""..groupName.."\"")
						else
							TSM:Printf(L["Added %s crafted items to %s individual groups."], count, count)
						end
						self.parent:Hide()
					end,
				tooltip = L["Adds all items in this Crafting group to Auctioning group(s) as per the above settings."],
			},
		}

		TSMAPI:BuildPage(window, page)
	end

	local page = {
		{
			type = "SimpleGroup",
			layout = "flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Help"],
					children = {
						{	-- label at the top of the page
							type = "Label",
							text = L["The checkmarks next to each craft determine whether or not the craft will be shown in the Craft Management Window."],
							relativeWidth = 1,
						},
						{	-- add all button
							type = "Button",
							text = L["Enable All Crafts"],
							relativeWidth = 0.3,
							callback = function(self)
									for _, data in pairs(TSM.Data[TSM.mode].crafts) do
										if data.group == slot then
											data.enabled = true
										end
									end
									ProfessionConfig.TreeGroup:SelectByPath(1, slot)
								end,
						},
						{	-- add all button
							type = "Button",
							text = L["Disable All Crafts"],
							relativeWidth = 0.3,
							callback = function(self)
									for _, data in pairs(TSM.Data[TSM.mode].crafts) do
										if data.group == slot then
											data.enabled = nil
										end
									end
									ProfessionConfig.TreeGroup:SelectByPath(1, slot)
								end,
						},
						{	-- add all button
							type = "Button",
							text = L["Create Auctioning Groups"],
							disabled = not TSMAPI:GetData("auctioningCategories"), -- they don't have a recent enough version of auctioning
							relativeWidth = 0.4,
							callback = function(self) DrawCreateAuctioningGroups(self) end,
						},
						{
							type = "HeadingLine"
						},
						{	-- label at the top of the page
							type = "Label",
							text = TSMAPI.Design:GetInlineColor("link")..L["Left-Click|r on a row below to enable/disable a craft."].."\n"..TSMAPI.Design:GetInlineColor("link")..L["Right-Click|r on a row below to show additional settings for a craft."],
							relativeWidth = 1,
						},
					},
				},
				{
					type = "SimpleGroup",
					layout = "list",
					fullHeight = true,
					children = {},
				},
			},
		},
	}

	if not select(4, GetAddOnInfo("TradeSkillMaster_Auctioning")) then
		for i, v in ipairs(page[1].children[1].children) do
			if v.text == L["Create Auctioning Groups"] then
				tremove(page[1].children[1].children, i)
				break
			end
		end
	end

	local function GetCraftData()
		local stData = {}
		for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
			if data.group == slot then
				local cost, _, profit = TSM.Data:GetCraftPrices(itemID)
				local color = GREEN
				if profit then
					if profit <= 0 then color = RED end
				end
				local itemLvl = select(4, GetItemInfo(itemID))
				
				tinsert(stData, {
					cols = {
						{
							value = data.enabled and "|TInterface\\Buttons\\UI-CheckBox-Check:24|t" or "",
						},
						{
							value = itemLvl or "?",
							args = {-itemLvl or 0, data.name}
						},
						{
							value = select(2, GetItemInfo(itemID)) or data.name,
							args = {data.name}
						},
						{
							value = function() return TSM:FormatTextMoney(cost, TSMAPI.Design:GetInlineColor("link2"), true, true) or (TSMAPI.Design:GetInlineColor("link2").."?|r") end,
							args = {cost or 0}
						},
						{
							value = function() return (profit and (profit <=0 and RED.."-|r" or "")..(TSM:FormatTextMoney(abs(profit), color, true, true) or (RED..profit.."|cffffd700g|r")) or TSMAPI.Design:GetInlineColor("link2").."?|r") end,
							args = {profit or -math.huge},
						},
						{
							value = TSM.db.profile.craftHistory[data.spellID] or 0,
						},
					},
					itemID = itemID,
					data = data,
				})
			end
		end
		return stData
	end

	local stData = GetCraftData()
	-- if no crafts have been added for this slot, show a message to alert the user
	if #stData == 0 then
		local text = L["No crafts have been added for this profession. Crafts are automatically added when you click on the profession icon while logged onto a character which has that profession."]
		tinsert(page[1].children[1].children, {
				type = "HeadingLine"
			})
		tinsert(page[1].children[1].children, {
				type = "Label",
				text = text,
				fullWidth=true,
			})
	end
	
	local function ColSortMethod(st, aRow, bRow, col)
		local a, b = st:GetCell(aRow, col), st:GetCell(bRow, col)
		local column = st.cols[col]
		local direction = column.sort or column.defaultsort or "dsc"
		local a_args, b_args = a.args or {a.value}, b.args or {b.value}
		local idx = 1
		while a_args[idx] and b_args[idx] do
			local aValue, bValue = a_args[idx], b_args[idx]
			if aValue ~= bValue then
				if direction == "asc" then
					return aValue < bValue
				else
					return aValue > bValue
				end
			end
			idx = idx + 1
		end
		return true
	end
	
	local colInfo = {
		{
			name = "",
			width = 0.05,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["iLvL"],
			width = 0.07,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Name"],
			width = 0.45,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Crafting Cost"],
			width = 0.12,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Profit"],
			width = 0.12,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Times Crafted"],
			width = 0.14,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
	}
	
	local function GetColInfo(width)
		local info = CopyTable(colInfo)
		for i=1, #info do
			if type(info[i].name) == "function" then
				info[i].name = info[i].name()
			end
			info[i].width = floor(info[i].width*width)
		end
		
		return info
	end
	
	TSMAPI:BuildPage(container, page)
	
	if not craftsST then
		local colInfo = GetColInfo(container.frame:GetWidth())
		craftsST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	local stParent = container.children[1].children[#container.children[1].children].frame
	craftsST.frame:SetParent(stParent)
	craftsST.frame:SetPoint("BOTTOMLEFT", container.children[1].frame)
	craftsST.frame:SetPoint("TOPRIGHT", container.children[1].children[1].frame, "BOTTOMRIGHT", 0, -20)
	craftsST.frame:SetScript("OnSizeChanged", function(_,width, height)
			if not craftsST.frame:IsVisible() then return end
			craftsST:SetDisplayCols(GetColInfo(width))
			craftsST:SetDisplayRows(floor(height/16), 16)
		end)
	craftsST:Show()
	craftsST:SetData(stData)
	craftsST.frame:GetScript("OnSizeChanged")(craftsST.frame, craftsST.frame:GetWidth(), craftsST.frame:GetHeight())
	
	local font, size = GameFontNormal:GetFont()
	for i, row in ipairs(craftsST.rows) do
		for j, col in ipairs(row.cols) do
			col.text:SetFont(font, size-1)
		end
	end
	
	for i, col in ipairs(craftsST.head.cols) do
		col:SetHeight(32)
	end
	craftsST.head.cols[2]:Click()
	
	craftsST:RegisterEvents({
		["OnClick"] = function(_, _, data, _, _, rowNum, _, self, button)
			if not rowNum then return end
			if button == "LeftButton" then
				data[rowNum].data.enabled = not data[rowNum].data.enabled
				craftsST:SetData(GetCraftData())
			else
				ShowAdditionalSettings(self, data[rowNum].itemID, data[rowNum].data)
			end
		end,
		["OnEnter"] = function(_, self, data, _, _, rowNum, col)
			if not rowNum then return end

			if col == 3 then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				GameTooltip:SetHyperlink("item:"..data[rowNum].itemID)
			else
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
				GameTooltip:SetText(TSMAPI.Design:GetInlineColor("link2")..L["Left-Click"]..": |r"..L["Enable / Disable showing this craft in the craft management window."].."\n"..TSMAPI.Design:GetInlineColor("link2")..L["Right-Click"]..": |r"..L["Additional Item Settings"], 1, 1, 1, 1, false)
			end
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end})
end

-- Materials Page
function ProfessionConfig:LoadMaterialsPage(container)
	ProfessionConfig:HookScript(container.frame, "OnHide", function()
			ProfessionConfig:UnhookAll()
			if matST then
				matST:Hide()
			end
			if ProfessionConfig.OpenWindow then
				ProfessionConfig.OpenWindow:Hide()
			end
		end)

	local colData = {}
	local matList = TSM:GetMats(TSM.mode)
	local sources = {["craft"]=L["Craft"], ["mill"]=L["Mill"], ["vendor"]=L["Vendor"], ["vendortrade"]=L["Vendor Trade"], ["auction"]=L["Auction House"]}
	for i=1, #(matList) do
		local itemID = matList[i]
		local mat = TSM.Data[TSM.mode].mats[itemID]
		local name, link = GetItemInfo(itemID)
		link = link or mat.name
		name = name or mat.name
		local cost = TSM.Data:GetMatCost(TSM.mode, itemID)

		colData[i] = {
			cols = {
				{
					value = link,
					args = {name, ""},
				},
				{
					value = function(copper)
							if copper and copper < BIG_NUMBER and copper > 0 then
								return TSM:FormatTextMoney(copper)
							else
								return "---"
							end
						end,
					args = {cost, 0},
				},
				{
					value = function(rSource)
							return sources[rSource or ""] or L["Custom"]
						end,
					args = {mat.source, L["Custom"]},
				},
				{
					value = function(num) return num end,
					args = {TSM.Data:GetTotalQuantity(itemID)},
				},
			},
			itemID = itemID,
		}
	end

	local function ColSortMethod(st, aRow, bRow, col)
		local a, b = st:GetCell(aRow, col), st:GetCell(bRow, col)
		local column = st.cols[col]
		local direction = column.sort or column.defaultsort or "dsc"

		local aValue, bValue
		aValue = a.args[1] or a.args[2]
		bValue = b.args[1] or b.args[2]

		if direction == "asc" then
			return aValue < bValue
		else
			return aValue > bValue
		end
	end

	local matCols = {
		{
			name = L["Item Name"],
			width = 0.3,
			defaultsort = "asc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Mat Price"],
			width = 0.2,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Price Source"],
			width = 0.2,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
		{
			name = L["Number Owned"],
			width = 0.2,
			defaultsort = "dsc",
			comparesort = ColSortMethod,
		},
	}

	local function GetColInfo(width)
		local colInfo = CopyTable(matCols)
		for i=1, #colInfo do
			colInfo[i].width = floor(colInfo[i].width*width)
		end

		return colInfo
	end

	local page = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			fullHeight = true,
			children = {
				{
					type = "Label",
					text = L["You can click on one of the rows of the scrolling table below to view or adjust how the price of a material is calculated."],
					relativeWidth = 1,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "SimpleGroup",
					layout = "Flow",
					fullHeight = true,
					children = {},
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
	local stParent = container.children[1].children[3].frame

	local colInfo = GetColInfo(stParent:GetWidth())
	if not matST then
		matST = TSMAPI:CreateScrollingTable(colInfo, true)
	end
	matST.frame:SetParent(stParent)
	matST.frame:SetPoint("BOTTOMLEFT", 2, 2)
	matST.frame:SetPoint("TOPRIGHT", -2, -16)
	matST.frame:SetScript("OnSizeChanged", function(_,width, height)
			matST:SetDisplayCols(GetColInfo(width))
			matST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
		end)
	matST:Show()
	matST:SetData(colData)

	matST:RegisterEvents({
		["OnClick"] = function(_, self, _, _, _, rowNum)
			if not rowNum then return end
			ProfessionConfig:ShowMatOptionsWindow(self, colData[rowNum].itemID)
		end,
		["OnEnter"] = function(_, self, _, _, _, rowNum)
			if not rowNum then return end

			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetHyperlink("item:"..colData[rowNum].itemID)
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end})
end

-- Material Options Window
function ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
	if ProfessionConfig.OpenWindow then ProfessionConfig.OpenWindow:Hide() end
	local mat = TSM.Data[TSM.mode].mats[itemID]
	if not mat then return end
	local link = select(2, GetItemInfo(itemID)) or mat.name
	local cost = TSM.Data:GetMatCost(TSM.mode, itemID)

	local window = AceGUI:Create("TSMWindow")
	window.frame:SetParent(parent)
	window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	window:SetWidth(600)
	window:SetHeight(545)
	window:SetTitle(L["Material Cost Options"])
	window:SetLayout("Flow")
	window.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
	window:SetCallback("OnClose", function(self)
			self:ReleaseChildren()
			ProfessionConfig.OpenWindow = nil
			window.frame:Hide()
		end)
	ProfessionConfig.OpenWindow = window

	local RefreshPage

	local page = {
		{
			type = "InteractiveLabel",
			text = link,
			fontObject = GameFontHighlight,
			relativeWidth = 0.6,
			callback = function() SetItemRef("item:".. itemID, itemID) end,
			tooltip = itemID,
		},
		{
			type = "Label",
			text = TSMAPI.Design:GetInlineColor("link")..L["Price:"].." |r"..(TSMAPI:FormatTextMoneyIcon(cost) or "---"),
			relativeWidth = 0.39,
		},
		{
			type = "HeadingLine",
		},
		{
			type = "ScrollFrame",
			layout = "Flow",
			fullHeight = true,
			children = {},
		},
	}

	TSMAPI:BuildPage(window, page)

	local function ChangeSource(newSource)
		mat.customMultiplier = nil
		mat.customID = nil
		mat.source = newSource
		return ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
	end

	local function GetMoneyText(copperValue, additionalRequirement)
		if mat.override and additionalRequirement ~= false then
			return TSM:FormatTextMoney(copperValue) or "---"
		else
			return TSM:FormatTextMoney(copperValue, "|cff777777", nil, nil, true) or "---"
		end
	end

	local prices = {}
	local matSources = {"auction", "vendor", "vendortrade", "craft", "mill", "customitem"}
	for i=1, #matSources do
		prices[matSources[i]] = TSM.Data:GetMatSourcePrice(TSM.mode, itemID, matSources[i])
	end

	if mat.source ~= "custom" then
		mat.customValue = nil
	end
	if mat.source ~= "customitem" then
		mat.customID = nil
		mat.customMultiplier = nil
	end

	local sPage = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = {
				{
					type = "Label",
					text = L["Here you can view and adjust how Crafting is calculating the price for this material."],
					relativeWidth = 1,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "CheckBox",
					label = L["Override Price Source"],
					relativeWidth = 1,
					value = mat.override,
					callback = function(_,_,value)
							mat.override = value and true or nil -- use nil instead of false to save space
							ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
						end,
					tooltip = L["If checked, you can change the price source for this mat by clicking on one of the checkboxes below. This source will be used to determine the price of this mat until you remove the override or change the source manually. If this setting is not checked, Crafting will automatically pick the cheapest source."],
				},
			},
		},
		{
			type = "InlineGroup",
			layout = "Flow",
			title = L["General Price Sources"],
			children = {
				{
					type = "CheckBox",
					label = GetMoneyText(prices.auction).." - "..L["Auction House Value"],
					relativeWidth = 1,
					disabled = not mat.override,
					value = mat.source == "auction",
					callback = function() ChangeSource("auction") end,
					tooltip = L["Use auction house data from the addon you have selected in the Crafting options for the value of this mat."],
				},
				{
					type = "HeadingLine"
				},
			},
		},
		{
			type = "Spacer",
		},
		{
			type = "InlineGroup",
			layout = "Flow",
			title = L["User-Defined Price"],
			children = {
				{
					type = "CheckBox",
					label = GetMoneyText(mat.customValue).." - "..L["Custom Value"],
					value = mat.source == "custom",
					relativeWidth = 0.6,
					disabled = not mat.override,
					callback = function() ChangeSource("custom") end,
					tooltip = L["Checking this box will allow you to set a custom, fixed price for this item."],
				},
				{
					type = "EditBox",
					label = L["Edit Custom Value"],
					value = mat.customValue and GetMoneyText(mat.customValue, (mat.source=="custom" or false)) or "",
					disabled = mat.source ~= "custom" or not mat.override,
					relativeWidth = 0.39,
					callback = function(self,_,value)
							mat.customID = nil
							mat.customMultiplier = nil
							local copper = TSM:GetMoneyValue(value:trim())
							if copper and copper ~= 0 then
								mat.customValue = copper
								ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
							else
								self:SetFocus()
								TSM:Print(L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."])
							end
						end,
					tooltip = L["Enter a value that Crafting will use as the cost of this material."],
				},
				{
					type = "CheckBox",
					label = GetMoneyText(prices.customItem).." - "..L["Multiple of Other Item Cost"],
					value = mat.source == "customitem",
					relativeWidth = 0.6,
					disabled = not mat.override,
					callback = function()
							mat.source = "customitem",
							ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
							ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
						end,
					tooltip = L["This will allow you to base the price of this item on the price of some other item times a multiplier. Be careful not to create circular dependencies (ie Item A is based on the cost of Item B and Item B is based on the price of Item A)!"],
				},
				{
					type = "InteractiveLabel",
					text = mat.customID and (select(2, GetItemInfo(mat.customID)) or "item:"..mat.customID) or (mat.override and "---" or "|cff777777---|r"),
					fontObject = GameFontHighlight,
					disabled = not mat.override,
					relativeWidth = 0.39,
					callback = function() if mat.customID then SetItemRef("item:"..mat.customID, mat.customID) end end,
					tooltip = mat.customID or "",
				},
				{
					type = "Label",
					relativeWidth = 0.1,
				},
				{
					type = "EditBox",
					label = L["Other Item"],
					value = mat.customID and (select(2, GetItemInfo(mat.customID)) or mat.customID) or "",
					disabled = mat.source ~= "customitem",
					relativeWidth = 0.55,
					callback = function(self,_,value)
							value = tonumber(value) or (strfind(value, "item:") and TSMAPI:GetItemID(value))
							if value then
								mat.customID = value
								mat.source = "customitem",
								ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
								ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
							else
								self:SetFocus()
								TSM:Print(L["Invalid item entered. You can either link the item into this box or type in the itemID from wowhead."])
							end
						end,
					tooltip = L["The item you want to base this mat's price on. You can either link the item into this box or type in the itemID from wowhead."],
				},
				{
					type = "Label",
					relativeWidth = 0.05,
				},
				{
					type = "EditBox",
					label = L["Price Multiplier"],
					value = mat.customMultiplier or "",
					disabled = mat.source ~= "customitem",
					relativeWidth = 0.29,
					callback = function(self,_,value)
							if tonumber(value) then
								mat.customMultiplier = value
								ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
								ProfessionConfig:ShowMatOptionsWindow(parent, itemID)
							else
								self:SetFocus()
								TSM:Print(L["Invalid Number"])
							end
						end,
					tooltip = L["Enter what you want to multiply the cost of the other item by to calculate the price of this mat."],
				},
			},
		},
		{
			type = "Spacer",
		},
	}

	if prices.vendor then
		tinsert(sPage[2].children, 2, {
				type = "CheckBox",
				label = GetMoneyText(prices.vendor).." - "..L["Buy From Vendor"],
				relativeWidth = 1,
				disabled = not mat.override,
				value = mat.source == "vendor",
				callback = function() ChangeSource("vendor") end,
				tooltip = L["Use the price that a vendor sells this item for as the cost of this material."],
			})
	end

	if prices.vendortrade then -- vendor trade
		local tradeItemID, tradeQuantity = TSM.Vendor:GetItemVendorTrade(itemID)
		local widgets = {
			{
				type = "CheckBox",
				label = GetMoneyText(prices.vendortrade).." - "..format(L["Vendor Trade (x%s)"], (floor((tradeQuantity)*100)/100)),
				relativeWidth = 0.6,
				disabled = not mat.override,
				value = mat.source == "vendortrade",
				callback = function() ChangeSource("vendortrade") end,
			},
			{
				type = "InteractiveLabel",
				text = select(2, GetItemInfo(tradeItemID)) or "item:"..tradeItemID,
				fontObject = GameFontHighlight,
				relativeWidth = 0.39,
				callback = function() SetItemRef("item:"..tradeItemID, tradeItemID) end,
				tooltip = tradeItemID,
			},
		}
		for i=1, #widgets do
			tinsert(sPage[2].children, widgets[i])
		end
	end
	if TSM.mode == "Inscription" and prices.mill then -- milling
		local _,pigmentData = TSM.Inscription:GetInkFromPigment(itemID)
		tinsert(sPage[2].children, {
				type = "Label",
				text = L["Note: By default, Crafting will use the second cheapest value (herb or pigment cost) to calculate the cost of the pigment as this provides a slightly more accurate value."],
				relativeWidth = 1,
			})
		local widgets = {
			{
				type = "CheckBox",
				label = GetMoneyText(prices.mill).." - "..L["Milling"],
				relativeWidth = 1,
				disabled = not mat.override,
				value = mat.source == "mill",
				callback = function() ChangeSource("mill") end,
				tooltip = L["Use the price of buying herbs to mill as the cost of this material."],
			},
		}
		for i=1, #widgets do
			tinsert(sPage[2].children, widgets[i])
		end
		for i=1, #pigmentData.herbs do
			local herbID = pigmentData.herbs[i].itemID
			local pigmentPerMill = pigmentData.herbs[i].pigmentPerMill
			local herbCost = TSM:GetItemMarketPrice(herbID, "mat")
			local cost = herbCost and floor(herbCost*5/pigmentPerMill + 0.5)
			local widgets = {
				{
					type = "Label",
					relativeWidth = 0.1,
				},
				{
					type = "InteractiveLabel",
					text = select(2, GetItemInfo(herbID)) or "item:"..herbID,
					fontObject = GameFontHighlight,
					relativeWidth = 0.49,
					callback = function() SetItemRef("item:"..herbID, herbID) end,
					tooltip = herbID,
				},
				{
					type = "Label",
					text = (mat.override and "|cffffffff" or "|cff777777")..(cost and GetMoneyText(cost) or "?").." "..L["per pigment"],
					relativeWidth = 0.4,
				},
			}
			for i=1, #widgets do
				tinsert(sPage[2].children, widgets[i])
			end
		end
	end
	if prices.craft then
		local craft = TSM.Data[TSM.mode].crafts[itemID]
		local inkMatInfo = TSM.Inscription:GetInkMats(itemID)
		local widgets = {
			{
				type = "CheckBox",
				label = GetMoneyText(prices.craft).." - "..format(L["Craft Item (x%s)"], floor((1/craft.numMade)*100)/100),
				relativeWidth = 0.6,
				disabled = not mat.override,
				value = mat.source == "craft",
				callback = function() ChangeSource("craft") end,
			},
			{
				type = "InteractiveLabel",
				text = GetSpellLink(craft.spellID),
				fontObject = GameFontHighlight,
				relativeWidth = 0.39,
				callback = function() SetItemRef("enchant:"..craft.spellID, craft.spellID) end,
				tooltip = tostring(craft.spellID),
			},
			{
				type = "Label",
				text = L["NOTE: Milling prices can be viewed / adjusted in the mat options for pigments. Click on the button below to go to the pigment options."],
				relativeWidth = 1,
			},
			{
				type = "Button",
				text = L["Open Mat Options for Pigment"],
				relativeWidth = 1,
				callback = function() ProfessionConfig:ShowMatOptionsWindow(parent, inkMatInfo.pigment) end,
			},
			{
				type = "HeadingLine",
			},
		}
		if not (TSM.mode == "Inscription" and inkMatInfo) then
			tremove(widgets, #widgets)
			tremove(widgets, #widgets)
			tremove(widgets, #widgets)
		end
		for i=1, #widgets do
			tinsert(sPage[2].children, widgets[i])
		end
	end

	if window.children[4] then
		window.children[4]:ReleaseChildren()
	end
	TSMAPI:BuildPage(window.children[4], sPage)
end

-- Profession Options Page
function ProfessionConfig:LoadProfessionOptions(container)
	-- scroll frame to contain everything
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Setting Overrides"],
					children = {
 						{
 							type = "Label",
 							text = L["Min ilvl to craft:"],
 							relativeWidth = 0.12,
 						},
 						{
 							type = "CheckBox",
 							label = L["Place lower limit on ilvl to craft"],
 							value = TSM.db.profile.limitIlvl[TSM.mode] and true,
 							callback = function(self, _, value)
 									if value then
 										TSM.db.profile.limitIlvl[TSM.mode] = true
 									else
 										TSM.db.profile.limitIlvl[TSM.mode] = nil
 									end
 									local siblings = self.parent.children --aw how cute...siblings ;)
 									local i = getIndex(siblings, self)
 									siblings[i+1]:SetDisabled(not value)
 									siblings[i+1]:SetText(TSM.db.profile.minilvlToCraft[TSM.mode] or "")
 								end,
 							tooltip = L["Allows you to set a custom minimum ilvl to queue."],
 						},
 
 						{
 							type = "EditBox",
 							label = L["Min Craft ilvl"],
 							value = TSM.db.profile.minilvlToCraft[TSM.mode],
 							disabled = TSM.db.profile.limitIlvl[TSM.mode] == nil,
 							relativeWidth = 0.2,
 							callback = function(self, _, value)
 									value = tonumber(value)
 									if value and value >= 0 then
 										TSM.db.profile.minilvlToCraft[TSM.mode] = value
 									end
 								end,
 						},
					}
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Restock Queue Overrides"],
					children = {
						{
							type = "Label",
							text = L["Here, you can override default restock queue settings."],
							fullWidth = true,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Override Max Restock Quantity"],
							value = TSM.db.profile.maxRestockQuantity[TSM.mode] and true,
							callback = function(self, _, value)
									if value then
										TSM.db.profile.maxRestockQuantity[TSM.mode] = TSM.db.profile.maxRestockQuantity.default
									else
										TSM.db.profile.maxRestockQuantity[TSM.mode] = nil
									end
									local siblings = self.parent.children --aw how cute...siblings ;)
									local i = getIndex(siblings, self)
									siblings[i+2]:SetDisabled(not value)
									siblings[i+2]:SetText(TSM.db.profile.maxRestockQuantity[TSM.mode] or "")
									siblings[i+3]:SetDisabled(not value)
									siblings[i+4]:SetDisabled(not value)
								end,
							tooltip = L["Allows you to set a custom maximum queue quantity for this profession."],
						},
						{
							type = "Label",
							text = "",
							relativeWidth = 0.1,
						},
						{
							type = "EditBox",
							label = L["Max Restock Quantity"],
							value = TSM.db.profile.maxRestockQuantity[TSM.mode],
							disabled = TSM.db.profile.maxRestockQuantity[TSM.mode] == nil,
							relativeWidth = 0.2,
							callback = function(self, _, value)
									value = tonumber(value)
									if value and value >= 0 then
										TSM.db.profile.maxRestockQuantity[TSM.mode] = value
									end
								end,
						},
						{	-- plus sign for incrementing the number
							type = "Icon",
							image = "Interface\\Buttons\\UI-PlusButton-Up",
							width = 24,
							imageWidth = 24,
							imageHeight = 24,
							disabled = TSM.db.profile.maxRestockQuantity[TSM.mode] == nil,
							callback = function(self)
									local value = (TSM.db.profile.maxRestockQuantity[TSM.mode] or 0) + 1
									TSM.db.profile.maxRestockQuantity[TSM.mode] = value

									local i = getIndex(self.parent.children, self)
									self.parent.children[i-1]:SetText(value)
								end,
						},
						{	-- minus sign for decrementing the number
							type = "Icon",
							image = "Interface\\Buttons\\UI-MinusButton-Up",
							disabled = true,
							width = 24,
							imageWidth = 24,
							imageHeight = 24,
							disabled = TSM.db.profile.maxRestockQuantity[TSM.mode] == nil,
							callback = function(self)
									local value = (TSM.db.profile.maxRestockQuantity[TSM.mode] or 0) - 1
									if value < 1 then value = 0 end

									if value < (TSM.db.profile.minRestockQuantity[TSM.mode] or TSM.db.profile.minRestockQuantity.default) then
										value = TSM.db.profile.minRestockQuantity[TSM.mode] or TSM.db.profile.minRestockQuantity.default
										TSM:Printf(L["Can not set a max restock quantity below the minimum restock quantity of %d."], value)
									end
									TSM.db.profile.maxRestockQuantity[TSM.mode] = value

									local i = getIndex(self.parent.children, self)
									self.parent.children[i-2]:SetText(value)
								end,
						},
						{
							type = "CheckBox",
							label = L["Override Min Restock Quantity"],
							value = TSM.db.profile.minRestockQuantity[TSM.mode] and true,
							relativeWidth = 0.6,
							callback = function(self, _, value)
									if value then
										TSM.db.profile.minRestockQuantity[TSM.mode] = TSM.db.profile.minRestockQuantity.default
									else
										TSM.db.profile.minRestockQuantity[TSM.mode] = nil
									end

									local siblings = self.parent.children --aw how cute...siblings ;)
									local i = getIndex(siblings, self)
									siblings[i+1]:SetDisabled(not value)
									siblings[i+1]:SetText(TSM.db.profile.minRestockQuantity[TSM.mode] or "")
									siblings[i+2]:SetDisabled(not value)
									siblings[i+3]:SetDisabled(not value)
								end,
							tooltip = L["Allows you to set a custom minimum queue quantity for this profession."],
						},
						{
							type = "EditBox",
							label = L["Min Restock Quantity"],
							value = TSM.db.profile.minRestockQuantity[TSM.mode],
							disabled = TSM.db.profile.minRestockQuantity[TSM.mode] == nil,
							relativeWidth = 0.2,
							callback = function(_, _, value)
									value = tonumber(value)
									if value and value >= 0 then
										TSM.db.profile.minRestockQuantity[TSM.mode] = value
									end
								end,
							tooltip = L["This item will only be added to the queue if the number being added is greater than or equal to this number. This is useful if you don't want to bother with crafting singles for example."],
						},
						{	-- plus sign for incrementing the number
							type = "Icon",
							image = "Interface\\Buttons\\UI-PlusButton-Up",
							width = 24,
							imageWidth = 24,
							imageHeight = 24,
							disabled = TSM.db.profile.minRestockQuantity[TSM.mode] == nil,
							callback = function(self)
									local value = (TSM.db.profile.minRestockQuantity[TSM.mode] or 0) + 1
									if value > (TSM.db.profile.maxRestockQuantity[TSM.mode] or TSM.db.profile.maxRestockQuantity.default) then
										value = TSM.db.profile.maxRestockQuantity[TSM.mode] or TSM.db.profile.maxRestockQuantity.default
										TSM:Printf(L["Can not set a min restock quantity above the max restock quantity of %d."], value)
									end
									TSM.db.profile.minRestockQuantity[TSM.mode] = value

									local i = getIndex(self.parent.children, self)
									self.parent.children[i-1]:SetText(value)
								end,
						},
						{	-- minus sign for decrementing the number
							type = "Icon",
							image = "Interface\\Buttons\\UI-MinusButton-Up",
							disabled = true,
							width = 24,
							imageWidth = 24,
							imageHeight = 24,
							disabled = TSM.db.profile.minRestockQuantity[TSM.mode] == nil,
							callback = function(self)
									local value = TSM.db.profile.minRestockQuantity[TSM.mode] - 1
									if value < 1 then value = 1 end
									TSM.db.profile.minRestockQuantity[TSM.mode] = value

									local i = getIndex(self.parent.children, self)
									self.parent.children[i-2]:SetText(value)
								end,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Override Minimum Profit"],
							value = TSM.db.profile.queueProfitMethod[TSM.mode] ~= nil,
							callback = function(self, _, value)
									if value then
										TSM.db.profile.queueProfitMethod[TSM.mode] = TSM.db.profile.queueProfitMethod.default
										TSM.db.profile.queueMinProfitGold[TSM.mode] = TSM.db.profile.queueMinProfitGold.default
										TSM.db.profile.queueMinProfitPercent[TSM.mode] = TSM.db.profile.queueMinProfitPercent.default
									else
										TSM.db.profile.queueProfitMethod[TSM.mode] = nil
										TSM.db.profile.queueMinProfitGold[TSM.mode] = nil
										TSM.db.profile.queueMinProfitPercent[TSM.mode] = nil
									end
									ProfessionConfig.TreeGroup:SelectByPath(3)
								end,
							tooltip = L["Allows you to override the minimum profit settings for this profession."],
						},
						{	-- dropdown to select the method for setting the Minimum profit for the main crafts page
							type = "Dropdown",
							label = L["Minimum Profit Method"],
							list = {["gold"]=L["Gold Amount"], ["percent"]=L["Percent of Cost"],
								["none"]=L["No Minimum"], ["both"]=L["Percent and Gold Amount"]},
							value = TSM.db.profile.queueProfitMethod[TSM.mode],
							disabled = TSM.db.profile.queueProfitMethod[TSM.mode] == nil,
							relativeWidth = 0.49,
							callback = function(self,_,value)
									TSM.db.profile.queueProfitMethod[TSM.mode] = value
									ProfessionConfig.TreeGroup:SelectByPath(3)
								end,
							tooltip = L["You can choose to specify a minimum profit amount (in gold or by percent of cost) for what crafts should be added to the craft queue."],
						},
						{
							type = "Slider",
							value = TSM.db.profile.queueMinProfitPercent[TSM.mode] or TSM.db.profile.queueMinProfitPercent.default or 0,
							label = L["Minimum Profit (in %)"],
							tooltip = L["If enabled, any craft with a profit over this percent of the cost will be added to the craft queue when you use the \"Restock Queue\" button."],
							min = 0,
							max = 2,
							step = 0.01,
							relativeWidth = 0.49,
							isPercent = true,
							disabled = TSM.db.profile.queueProfitMethod[TSM.mode] == nil or TSM.db.profile.queueProfitMethod[TSM.mode] == "none" or TSM.db.profile.queueProfitMethod[TSM.mode] == "gold",
							callback = function(_,_,value)
									TSM.db.profile.queueMinProfitPercent[TSM.mode] = floor(value*100)/100
								end,
						},
						{
							type = "Slider",
							value = TSM.db.profile.queueMinProfitGold[TSM.mode] or TSM.db.profile.queueMinProfitGold.default or 0,
							label = L["Minimum Profit (in gold)"],
							tooltip = L["If enabled, any craft with a profit over this value will be added to the craft queue when you use the \"Restock Queue\" button."],
							min = 0,
							max = 300,
							step = 1,
							relativeWidth = 0.49,
							disabled = TSM.db.profile.queueProfitMethod[TSM.mode] == nil or TSM.db.profile.queueProfitMethod[TSM.mode] == "none" or TSM.db.profile.queueProfitMethod[TSM.mode] == "percent",
							callback = function(_,_,value)
									TSM.db.profile.queueMinProfitGold[TSM.mode] = floor(value)
								end,
						},
					},
				},
			},
		},
	}

	if TSM.mode == "Inscription" then
		tinsert(page[1].children, 1, {
				type = "InlineGroup",
				layout = "flow",
				title = L["Profession-Specific Settings"],
				children = {
					{	-- dropdown to select how to calculate material costs
						type = "Dropdown",
						label = L["Group Inscription Crafts By:"],
						list = {L["Ink"], L["Class"]},
						value = TSM.db.profile.inscriptionGrouping,
						relativeWidth = 0.49,
						callback = function(_,_,value)
								TSM.db.profile.inscriptionGrouping = value
								for itemID, craft in pairs(TSM.Data["Inscription"].crafts) do
									craft.group = TSM.Inscription:GetSlot(itemID, craft.mats)
								end

								-- clicks on the icon in order to reload the treeGroup
								for i=1, #TSM.tradeSkills do
									if TSM.tradeSkills[i].name == TSM.mode then
										TSMAPI:SelectIcon("TradeSkillMaster_Crafting", "Crafting - "..GetSpellInfo(TSM.tradeSkills[i].spellID))
										break
									end
								end
								ProfessionConfig.TreeGroup:SelectByPath(3)
							end,
						tooltip = L["Inscription crafts can be grouped in TradeSkillMaster_Crafting either by class or by the ink required to make them."],
					},
				},
			})
	end

	TSMAPI:BuildPage(container, page)
end
-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local GroupOptions = TSM:NewModule("GroupOptions", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {operationInfo=TSM.moduleOperationInfo, moduleObjects=TSM.moduleObjects, groupTreeGroup=nil, scrollFrameStatus={}, alreadyLoadedGroupItems={}, groupTreeCache={}}



-- ============================================================================
-- Module Functions
-- ============================================================================

function GroupOptions:OnInitialize()
	TSMAPI.Sync:RegisterRPC("CreateGroupWithItems", private.CreateGroupWithItems)
end



-- ============================================================================
-- General Group Options
-- ============================================================================

function GroupOptions:Load(parent)
	TSM:AnalyticsEvent("GROUP_OPTIONS_OPEN")
	private.groupTreeGroup = AceGUI:Create("TSMTreeGroup")
	private.groupTreeGroup:SetLayout("Fill")
	private.groupTreeGroup:SetCallback("OnGroupSelected", function(...) private:SelectTree(...) end)
	private.groupTreeGroup:SetStatusTable(TSM.db.profile.groupTreeStatus)
	parent:AddChild(private.groupTreeGroup)

	GroupOptions:UpdateTree()
	private.groupTreeGroup:SelectByPath(1)
end

function GroupOptions:UpdateTree()
	if not private.groupTreeGroup then return end

	local groupChildren = {}
	local groupPathList = TSM.Groups:GetGroupPathList()

	local children = {}
	for _, groupPath in ipairs(groupPathList) do
		local parentGroup, groupName = TSM.Groups:SplitGroupPath(groupPath)
		local level = select(2, gsub(groupPath, TSM.GROUP_SEP, "")) + 1
		if private.groupTreeCache[groupPath] then
			if level ~= private.groupTreeCache[groupPath]._level then
				private.groupTreeCache[groupPath]._level = level
				private.groupTreeCache[groupPath].text = TSM.Groups:ColorName(private.groupTreeCache[groupPath]._groupName, level)
			end
		else
			local level = select(2, gsub(groupPath, TSM.GROUP_SEP, "")) + 1
			private.groupTreeCache[groupPath] = {value=groupPath, text=TSM.Groups:ColorName(groupName, level), _level=level, _groupName=groupName}
		end
		if private.groupTreeCache[groupPath].children then
			wipe(private.groupTreeCache[groupPath].children)
		end
		if parentGroup then
			if not children[parentGroup] then
				children[parentGroup] = {}
			end
			tinsert(children[parentGroup], private.groupTreeCache[groupPath])
		end
		private.groupTreeCache[groupPath]._updated = true
	end

	-- remove any groups we didn't update
	for groupPath, data in pairs(private.groupTreeCache) do
		if data._updated then
			if data.children and #data.children == 0 then
				data.children = nil
			end
			data._updated = nil
		else
			private.groupTreeCache[groupPath] = nil
		end
	end

	local groupChildren = {}
	for groupPath, data in pairs(private.groupTreeCache) do
		if data._level == 1 then
			tinsert(groupChildren, data)
		end
		if children[groupPath] then
			data.children = children[groupPath]
			sort(data.children, function(a, b) return strlower(a.text) < strlower(b.text) end)
		end
	end
	sort(groupChildren, function(a, b) return strlower(a.text) < strlower(b.text) end)

	private.groupTreeGroup:SetTree({{value=1, text=L["Groups"], children=groupChildren}})
end

function private:SelectGroup(name)
	if not private.groupTreeGroup then return end
	local tmp = {1}
	local groupPathParts = {TSM.GROUP_SEP:split(name)}
	for i=1, #groupPathParts do
		tinsert(tmp, table.concat(groupPathParts, TSM.GROUP_SEP, 1, i))
	end
	private.groupTreeGroup:SelectByPath(unpack(tmp))
end

function private:SelectTree(treeGroup, _, selection)
	treeGroup:ReleaseChildren()

	selection = {("\001"):split(selection)}
	if #selection == 1 then
		private:DrawNewGroup(treeGroup)
	else
		TSM:AnalyticsEvent("GROUP_SELECTED")
		local group = selection[#selection]
		local tabGroup =  AceGUI:Create("TSMTabGroup")
		tabGroup:SetLayout("Fill")
		tabGroup:SetTabs({{text=L["Operations"], value=1}, {text=L["Items"], value=2}, {text=L["Import/Export"], value=3}, {text=L["Management"], value=4}})
		tabGroup:SetCallback("OnGroupSelected", function(self, _, value)
				tabGroup:ReleaseChildren()
				if value == 1 then
					-- load operations page
					private:DrawGroupOperationsPage(self, group)
					self.children[1]:SetStatusTable(private.scrollFrameStatus)
				elseif value == 2 then
					-- load items page
					private:DrawGroupItemsPage(self, group)
				elseif value == 3 then
					-- load import/export page
					private:DrawGroupImportExportPage(self, group)
				elseif value == 4 then
					-- load management page
					private:DrawGroupManagementPage(self, group)
				end
			end)
		tabGroup:SetCallback("OnRelease", function() wipe(private.scrollFrameStatus) end)
		treeGroup:AddChild(tabGroup)
		tabGroup:SelectTab(TSM.db.profile.defaultGroupTab)
	end
end

function private:DrawNewGroup(container)
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["New Group"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["A group is a collection of items which will be treated in a similar way by TSM's modules."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "EditBox",
							label = L["Group Name"],
							relativeWidth = 1,
							callback = function(self,_,value)
									value = (value or ""):trim()
									if value == "" then return end
									if strfind(value, TSM.GROUP_SEP) then
										return TSM:Printf(L["Group names cannot contain %s characters."], TSM.GROUP_SEP)
									end
									if TSM.db.profile.groups[value] then
										return TSM:Printf(L["Error creating group. Group with name '%s' already exists."], value)
									end
									TSM:AnalyticsEvent("GROUP_CREATED")
									TSM.Groups:Create(value)
									GroupOptions:UpdateTree()
									if TSM.db.profile.gotoNewGroup then
										private:SelectGroup(value)
									else
										self:SetText()
										self:SetFocus()
									end
								end,
							tooltip = L["Give the new group a name. A descriptive name will help you find this group later."],
						},
						{
							type = "CheckBox",
							label = L["Switch to New Group After Creation"],
							relativeWidth = 1,
							settingInfo = {TSM.db.profile, "gotoNewGroup"},
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Settings"],
					children = {
						{
							type = "Dropdown",
							label = L["Default Group Tab"],
							relativeWidth = 0.5,
							list = {L["Operations"], L["Items"], L["Import/Export"], L["Management"]},
							settingInfo = {TSM.db.profile, "defaultGroupTab"},
							tooltip = L["This dropdown determines the default tab when you visit a group."],
						},
						{
							type = "EditBox",
							label = L["Group Item Filter Value"],
							settingInfo = {TSM.db.profile, "groupFilterPrice"},
							relativeWidth = 0.5,
							acceptCustom = true,
							tooltip = L["When adding items to groups, you can filter by items with a value below a certain value. This custom price determines the value of items for the purpose of filter. For example, if you set this to 'dbmarket' and entered '/2000g' into the filter box, only items with a market value of at least 2000g will be shown. You can also specify a price range, such as '/200g/500g'."],
						},
					},
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end

function private:DrawGroupOperationsPage(container, groupPath)
	local isSubGroup = strfind(groupPath, TSM.GROUP_SEP)
	local moduleInlines = {}
	local addRef, deleteRef = {}, {}
	for _, info in ipairs(private.operationInfo) do
		local moduleName = info.module
		local ddList = {}
		ddList[""] = TSMAPI.Design:GetInlineColor("link")..L["<No Operation>"].."|r"
		for name in pairs(TSM.operations[moduleName] or {}) do
			ddList[name] = name
		end

		TSM.db.profile.groups[groupPath][moduleName] = TSM.db.profile.groups[groupPath][moduleName] or {}
		local operations = TSM.db.profile.groups[groupPath][moduleName]
		for i=#operations, 1, -1 do
			if not ddList[operations[i]] then
				TSM.Groups:RemoveOperation(groupPath, moduleName, i)
			end
		end
		operations[1] = operations[1] or ""
		if #operations > 1 then
			ddList["\001"] = TSMAPI.Design:GetInlineColor("link")..L["<Remove Operation>"].."|r"
		end

		local moduleInline = {
			type = "InlineGroup",
			layout = "Flow",
			title = moduleName,
			children = {},
		}

		local addOperationWidget
		if #operations < info.maxOperations then
			addOperationWidget = {
				type = "Button",
				text = L["Add Additional Operation"],
				relativeWidth = 1,
				disabled = isSubGroup and not operations.override,
				callback = function()
						TSM.Groups:AddOperation(groupPath, moduleName)
						container:Reload()
					end,
			}
		else
			addOperationWidget = {type="Label", relativeWidth=1}
		end
		if isSubGroup then
			tinsert(moduleInline.children, {
					type = "CheckBox",
					label = L["Override Module Operations"],
					value = operations.override,
					relativeWidth = 1,
					callback = function(_,_,value)
							TSM:AnalyticsEvent("GROUP_OVERRIDE_OPERATION")
							TSM.Groups:SetOperationOverride(groupPath, moduleName, value)
							container:Reload()
						end,
					tooltip = L["Check this box to override this group's operation(s) for this module."],
				})
		else
			tinsert(moduleInline.children, {type="Label", relativeWidth=1})
		end

		for i=1, #operations do
			tinsert(moduleInline.children, {
					type = "Dropdown",
					label = format(L["Operation #%d"], i),
					list = ddList,
					value = operations[i],
					relativeWidth = 0.6,
					disabled = isSubGroup and not operations.override,
					callback = function(_,_,value)
						TSM:AnalyticsEvent("GROUP_CHANGE_OPERATION")
						if value == "" then
							TSM.Groups:SetOperation(groupPath, moduleName, nil, i)
						elseif value == "\001" then
							TSM.Groups:RemoveOperation(groupPath, moduleName, i)
						else
							TSM.Groups:SetOperation(groupPath, moduleName, value, i)
						end
						container:Reload()
					end,
					tooltip = L["Select an operation to apply to this group."],
				})
			if operations[i] ~= "" then
				tinsert(moduleInline.children, {
						type = "Button",
						text = L["View Operation Options"],
						relativeWidth = 0.39,
						callback = function()
							TSM:AnalyticsEvent("GROUP_VIEW_OPERATION")
							TSMAPI.Operations:ShowOptions(moduleName, operations[i])
						end,
						tooltip = L["Click this button to configure the currently selected operation."],
					})
			elseif not isSubGroup or operations.override then
				tinsert(moduleInline.children, {
						type = "Button",
						text = L["Create New Operation"],
						relativeWidth = 0.39,
						callback = function()
							TSM:AnalyticsEvent("GROUP_CREATE_OPERATION")
							TSMAPI.Operations:ShowOptions(moduleName, "", groupPath)
						end,
						tooltip = L["Click this button to create a new operation for this module."],
					})
			end
		end
		tinsert(moduleInline.children, addOperationWidget)

		local opStrs = {}
		for _, name in ipairs(operations) do
			if name ~= "" then
				local str = info.callbackInfo(name) or "---"
				tinsert(opStrs, TSMAPI.Design:GetInlineColor("link")..name.."|r: "..str)
			end
		end
		tinsert(moduleInline.children, {type="HeadingLine"})
		tinsert(moduleInline.children, {
				type = "Label",
				text = #opStrs > 0 and table.concat(opStrs, "\n") or format(L["Select a %s operation using the dropdown above."], moduleName),
				relativeWidth = 1,
			})

		tinsert(moduleInlines, moduleInline)
	end

	sort(moduleInlines, function(a, b) return a.title < b.title end)

	local children = {}
	for i, inline in ipairs(moduleInlines) do
		tinsert(children, inline)
		if i ~= #moduleInlines then
			tinsert(children, {type="Spacer"})
		end
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = children,
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end

function private:DrawGroupItemsPage(container, groupPath)
	if not private.alreadyLoadedGroupItems[groupPath] then
		private.alreadyLoadedGroupItems[groupPath] = true
		TSMAPI.Delay:AfterTime(0.1, function() container:Reload() end)
	end

	local parentPath, groupName = TSM.Groups:SplitGroupPath(groupPath)
	local titleInfo = {}
	if parentPath then
		titleInfo.leftTitleList = {L["Parent/Ungrouped Items:"], L["Parent Group Items:"], L["Ungrouped Items:"]}
		titleInfo.left = {{parent=true, ungrouped=true}, {parent=true}, {ungrouped=true}}
		titleInfo.rightTitleList = {L["Subgroup Items:"]}
	else
		titleInfo.leftTitleList = {L["Ungrouped Items:"]}
		titleInfo.left = {{ungrouped=true}}
		titleInfo.rightTitleList = {L["Group Items:"]}
	end

	local bagItems = {}
	for _, _, itemString in TSMAPI.Inventory:BagIterator(false, false, true) do
		bagItems[itemString] = true
	end

	local function GetItemList(side, index)
		local list = {}
		if side == "left" then
			if titleInfo.left[index].parent then
				-- add all items from parent group
				for itemString, path in pairs(TSM.db.profile.items) do
					if path == parentPath then
						tinsert(list, itemString)
					end
				end
			end
			if titleInfo.left[index].ungrouped then
				-- add all items in bags
				for itemString in pairs(bagItems) do
					local baseItemString = TSMAPI.Item:ToBaseItemString(itemString)
					if itemString ~= baseItemString and TSM.db.global.ignoreRandomEnchants then -- a random enchant item
						itemString = baseItemString
					end
					if not TSM.db.profile.items[itemString] then
						tinsert(list, itemString)
					end
				end
			end
		elseif side == "right" then
			for itemString, path in pairs(TSM.db.profile.items) do
				if path == groupPath or strfind(path, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP) then
					tinsert(list, itemString)
				end
			end
		end
		return list
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "SimpleGroup",
			layout = "Fill",
			children = {
				{
					type = "GroupItemList",
					leftTitle = titleInfo.leftTitleList,
					rightTitle = titleInfo.rightTitleList,
					listCallback = GetItemList,
					OnAddClicked = function(_,_,selected)
						TSM:AnalyticsEvent("GROUP_ADD_ITEMS")
						for i=#selected, 1, -1 do
							TSM.Groups:AddItem(selected[i], groupPath)
						end
						container:Reload()
					end,
					OnRemoveClicked = function(_,_,selected)
						TSM:AnalyticsEvent("GROUP_REMOVE_ITEMS")
						if parentPath and IsShiftKeyDown() then
							for i=#selected, 1, -1 do
								TSM.Groups:MoveItem(selected[i], parentPath)
							end
						else
							for i=#selected, 1, -1 do
								TSM.Groups:RemoveItem(selected[i])
							end
						end
						container:Reload()
					end,
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end

function private:DrawGroupImportExportPage(container, groupPath)
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Import Items"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Paste the list of items into the box below and hit enter or click on the 'Okay' button.\n\nYou can also paste an itemLink into the box below to add a specific item to this group."],
						},
						{
							type = "EditBox",
							label = L["Import String"],
							relativeWidth = 1,
							callback = function(self, _, value)
								TSM:AnalyticsEvent("GROUP_IMPORT_ITEMS", TSM.db.profile.moveImportedItems)
								TSMAPI.Threading:Start(private.ImportGroupThread, 0.7, nil, {self, value, groupPath})
							end,
							tooltip = L["Paste the exported items into this box and hit enter or press the 'Okay' button. The recommended format for the list of items is a comma separated list of itemIDs for general items. For battle pets, the entire battlepet string should be used. For randomly enchanted items, the format is <itemID>:<randomEnchant> (ex: 38472:-29)."],
						},
						{
							type = "CheckBox",
							label = L["Move Already Grouped Items"],
							relativeWidth = 0.5,
							settingInfo = {TSM.db.profile, "moveImportedItems"},
							callback = function() container:Reload() end,
							tooltip = L["If checked, any items you import that are already in a group will be moved out of their current group and into this group. Otherwise, they will simply be ignored."],
						},
						{
							type = "CheckBox",
							disabled = not strfind(groupPath, TSM.GROUP_SEP) or not TSM.db.profile.moveImportedItems,
							label = L["Only Import Items from Parent Group"],
							relativeWidth = 0.5,
							settingInfo = {TSM.db.profile, "importParentOnly"},
							tooltip = L["If checked, only items which are in the parent group of this group will be imported."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Export Items in Group"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Click the button below to open the export frame for this group."],
						},
						{
							type = "Button",
							text = L["Export Group Items"],
							relativeWidth = 1,
							callback = function()
								private:ShowGroupExportFrame(private.ExportGroup(groupPath, TSM.db.profile.exportSubGroups, TSM.db.profile.exportOperations))
							end,
							tooltip = L["Click this button to show a frame for easily exporting the list of items which are in this group."],
						},
						{
							type = "CheckBox",
							label = L["Include Subgroup Structure"],
							relativeWidth = 0.5,
							settingInfo = {TSM.db.profile, "exportSubGroups"},
							tooltip = L["If checked, the structure of the subgroups will be included in the export. Otherwise, the items in this group (and all subgroups) will be exported as a flat list."],
						},
						{
							type = "CheckBox",
							label = L["Include Operations"],
							relativeWidth = 0.5,
							settingInfo = {TSM.db.profile, "exportOperations"},
							tooltip = L["If checked, all operations will be exported, including all of their settings."],
						},
					},
				},
			},
		},
	}

	local syncTargetList = {}
	for account in pairs(TSM.db.factionrealm.syncAccounts) do
		for player in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters, account) do
			local connectedPlayer = TSMAPI.Sync:GetStatus(TSM.db.factionrealm.characters, player)
			if player == connectedPlayer then
				tinsert(syncTargetList, player)
			end
		end
	end

	if #syncTargetList > 0 then
		local syncTargetValue = 1
		local moveImportedItems = false
		local includeSubgroup = true
		local syncInlineGroup = {
			type = "InlineGroup",
			layout = "flow",
			title = L["Send to Other Account"],
			children = {
				{
					type = "Label",
					relativeWidth = 1,
					text = L["Select an online character on one of your other accounts to send this group to using the dropdown below and then click on the button."],
				},
				{
					type = "Dropdown",
					label = L["Target Character:"],
					list = syncTargetList,
					value = syncTargetValue,
					relativeWidth = 0.5,
					callback = function(_, _, value) syncTargetValue = value end,
					tooltip = L["This dropdown will list all characters on your other accounts which have active syncing connections and are currently online."],
				},
				{
					type = "Button",
					text = L["Send Group"],
					relativeWidth = 0.5,
					callback = function(self)
						local exportStr = private.ExportGroup(groupPath, includeSubgroup)
						if #exportStr > 5000 then
							return TSM:Print(L["This group is too large to send automatically. Please use manual import / export instead."])
						end
						local targetPlayer = syncTargetList[syncTargetValue]
						local function handler(numItems)
							if type(numItems) ~= "number" then
								return TSM:Printf(L["Failed to send group to %s."], targetPlayer)
							end
							TSM:Printf(L["Successfully sent %d items to %s."], numItems, targetPlayer)
						end
						self:SetCallback("OnRelease", function() TSMAPI.Sync:CancelRPC("CreateGroupWithItems", handler) end)
						self:SetDisabled(true)
						self:SetText(L["Sent Group - Result is in Chat"])
						local _, groupName = TSM.Groups:SplitGroupPath(groupPath)
						if not TSMAPI.Sync:CallRPC("CreateGroupWithItems", targetPlayer, handler, groupName, private.ExportGroup(groupPath, includeSubgroup), moveImportedItems) then
							TSM:Printf(L["Failed to send group to %s."], targetPlayer)
						end
					end,
					tooltip = L["Click this button to send this group to the selected character. TSM will print out the operation in chat."],
				},
				{
					type = "CheckBox",
					label = L["Include Subgroup Structure"],
					relativeWidth = 0.5,
					value = includeSubgroup,
					callback = function(_, _, value) includeSubgroup = value end,
					tooltip = L["If checked, the structure of the subgroups will be included in the export. Otherwise, the items in this group (and all subgroups) will be exported as a flat list."],
				},
				{
					type = "CheckBox",
					label = L["Move Already Grouped Items on Other Account"],
					relativeWidth = 1,
					value = moveImportedItems,
					callback = function(_, _, value) moveImportedItems = value end,
					tooltip = L["If checked, any items you import that are already in a group will be moved out of their current group and into this group. Otherwise, they will simply be ignored."],
				},
			},
		}
		tinsert(page[1].children, syncInlineGroup)
	end

	TSMAPI.GUI:BuildOptions(container, page)
end

function private:DrawGroupManagementPage(container, groupPath)
	local deleteTooltip = nil
	local hasParent = TSM.Groups:SplitGroupPath(groupPath) and true or false
	if hasParent and TSM.db.profile.keepInParent then
		deleteTooltip = L["All items in this group and its subgroups will be moved to the parent group and this group and all of its subgroups will be deleted."]
	else
		deleteTooltip = L["All items in this group and its subgroups will be removed and this group and all of its subgroups will be deleted."]
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Group Management"],
					children = {
						{
							type = "EditBox",
							label = L["Rename Group"],
							relativeWidth = 1,
							value = select(2, TSM.Groups:SplitGroupPath(groupPath)),
							callback = function(_,_,value)
									value = (value or ""):trim()
									if value == "" then return end
									if value == select(2, TSM.Groups:SplitGroupPath(groupPath)) then return end -- same name
									if strfind(value, TSM.GROUP_SEP) then
										return TSM:Printf(L["Group names cannot contain %s characters."], TSM.GROUP_SEP)
									end
									local newPath
									local parent = TSM.Groups:SplitGroupPath(groupPath)
									if parent then
										newPath = parent..TSM.GROUP_SEP..value
									else
										newPath = value
									end
									if TSM.db.profile.groups[newPath] then
										return TSM:Printf(L["Error renaming group. Group with name '%s' already exists."], value)
									end
									TSM:AnalyticsEvent("GROUP_RENAME")
									TSM.Groups:Move(groupPath, newPath)
									GroupOptions:UpdateTree()
									private:SelectGroup(newPath)
								end,
							tooltip = L["Give the group a new name. A descriptive name will help you find this group later."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Button",
							text = L["Delete Group"],
							relativeWidth = 0.5,
							callback = function()
								StaticPopupDialogs["TSM_DELETE_GROUP"] = StaticPopupDialogs["TSM_DELETE_GROUP"] or {
									button1 = DELETE,
									button2 = CANCEL,
									timeout = 0,
									OnAccept = function()
										local groupPath = StaticPopupDialogs["TSM_DELETE_GROUP"].tsmInfo
										TSM:AnalyticsEvent("GROUP_DELETE")
										TSM.Groups:Delete(groupPath)
										GroupOptions:UpdateTree()
										local parent = TSM.Groups:SplitGroupPath(groupPath)
										if parent then
											private:SelectGroup(parent)
										else
											private.groupTreeGroup:SelectByPath(1)
										end
									end,
								}
								StaticPopupDialogs["TSM_DELETE_GROUP"].text = deleteTooltip.."\n\n"..L["Are you sure you want to delete this group?"]
								StaticPopupDialogs["TSM_DELETE_GROUP"].tsmInfo = groupPath
								TSMAPI.Util:ShowStaticPopupDialog("TSM_DELETE_GROUP")
							end,
							tooltip = deleteTooltip,
						},
						{
							type = "CheckBox",
							label = L["Keep Items in Parent Group"],
							relativeWidth = 0.5,
							settingInfo = {TSM.db.profile, "keepInParent"},
							disabled = not hasParent,
							callback = function() container:Reload() end,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Create New Subgroup"],
					children = {
						{
							type = "EditBox",
							label = L["New Subgroup Name"],
							relativeWidth = 1,
							callback = function(self,_,value)
									value = (value or ""):trim()
									if value == "" then return end
									if strfind(value, TSM.GROUP_SEP) then
										return TSM:Printf(L["Group names cannot contain %s characters."], TSM.GROUP_SEP)
									end
									local newPath = groupPath..TSM.GROUP_SEP..value
									if TSM.db.profile.groups[newPath] then
										return TSM:Printf(L["Error creating subgroup. Subgroup with name '%s' already exists."], value)
									end
									TSM:AnalyticsEvent("GROUP_CREATE_SUBGROUP")
									TSM.Groups:Create(newPath)
									GroupOptions:UpdateTree()
									if TSM.db.profile.gotoNewGroup then
										private:SelectGroup(newPath)
									else
										self:SetText()
										self:SetFocus()
									end
								end,
							tooltip = L["Subgroups can contain a subset of the items in their parent group and can be useful in further refining how modules handle the items in this group."].."\n\n"..L["Give the group a new name. A descriptive name will help you find this group later."],
						},
						{
							type = "CheckBox",
							label = L["Switch to New Group After Creation"],
							relativeWidth = 1,
							settingInfo = {TSM.db.profile, "gotoNewGroup"},
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Move Group"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Use the group box below to move this group and all subgroups of this group. Moving a group will cause all items in the group (and its subgroups) to be removed from its current parent group and added to the new parent group."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "GroupBox",
							label = L["New Parent Group"],
							relativeWidth = 0.5,
							callback = function(self, _, value)
								self:SetText()
								if value and value ~= groupPath then
									if strfind(value, "^"..groupPath) then
										return TSM:Printf(L["Error moving group. You cannot move this group to one of its subgroups."])
									end
									local _, groupName = TSM.Groups:SplitGroupPath(groupPath)
									local newPath = value..TSM.GROUP_SEP..groupName
									if TSM.db.profile.groups[newPath] then
										return TSM:Printf(L["Error moving group. Group '%s' already exists."], TSMAPI.Groups:FormatPath(newPath, true))
									end

									TSM:Printf(L["Moved %s to %s."], TSMAPI.Groups:FormatPath(groupPath, true), TSMAPI.Groups:FormatPath(value, true))
									TSM:AnalyticsEvent("GROUP_NEW_PARENT")
									TSM.Groups:Move(groupPath, newPath)
									GroupOptions:UpdateTree()
									private:SelectGroup(newPath)
								end
							end,
						},
						{
							type = "Button",
							text = L["Move to Top Level"],
							relativeWidth = 0.5,
							disabled = groupPath == select(2, TSM.Groups:SplitGroupPath(groupPath)),
							callback = function()
								local _, groupName = TSM.Groups:SplitGroupPath(groupPath)
								local newPath = groupName
								if TSM.db.profile.groups[newPath] then
									return TSM:Printf(L["Error moving group. Group '%s' already exists."], TSMAPI.Groups:FormatPath(newPath, true))
								end

								TSM:Printf(L["Moved %s to %s."], TSMAPI.Groups:FormatPath(groupPath, true), TSMAPI.Groups:FormatPath(newPath, true))
								TSM:AnalyticsEvent("GROUP_NEW_PARENT")
								TSM.Groups:Move(groupPath, newPath)
								GroupOptions:UpdateTree()
								private:SelectGroup(newPath)
							end,
							tooltip = L["When clicked, makes this group a top-level group with no parent."],
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.ImportGroupAndOperationsThread(self, value, groupPath)
	local valid, info = GroupOptions:Deserialize(value)
	if not valid or not info.operations then return end
	local newOperations = {}
	for module, moduleOperations in pairs(info.operations) do
		local newModuleOperations = {}
		if TSM.operations[module] then
			for name, operation in pairs(moduleOperations) do
				if TSM.operations[module][name] then
					-- an operation with this name already exists
					if not StaticPopupDialogs["TSMGroupImportPopup"] then
						StaticPopupDialogs["TSMGroupImportPopup"] = {
							button1 = L["Replace"],
							button2 = L["Skip"],
							button3 = CANCEL,
							timeout = 0,
							OnAccept = function() self:SendMsgToSelf("REPLACE") end, -- button1
							OnCancel = function() self:SendMsgToSelf("SKIP") end, -- button2
							OnAlt = function() self:SendMsgToSelf("CANCEL") end, -- button3
						}
					end
					-- Blizzard's code passes the text to format() so we need to escape '%' characters
					StaticPopupDialogs["TSMGroupImportPopup"].text = gsub(format(L["A(n) %s operation named '%s' already exists! Would you like to replace the existing operation, skip importing this operation, or cancel the entire import?"], module, name), "%%", "%%%%")
					TSMAPI.Util:ShowStaticPopupDialog("TSMGroupImportPopup")
					local event = unpack(self:ReceiveMsg())
					if event == "REPLACE" then
						operation.ignorePlayer = {}
						operation.ignoreFactionrealm = {}
						operation.relationships = {}
						newModuleOperations[name] = operation
					elseif event == "SKIP" then
						-- do nothing
					elseif event == "CANCEL" then
						-- abort
						return
					else
						error("Unexpected event: "..tostring(event))
					end
				else
					-- we can safely use this name
					operation.ignorePlayer = {}
					operation.ignoreFactionrealm = {}
					operation.relationships = {}
					newModuleOperations[name] = operation
				end
			end
		else
			TSM:Printf(L["Skipping %s operations as the module is not loaded."], module)
		end
		newOperations[module] = newModuleOperations
	end

	-- import the group
	local num = private.ImportGroupHelperThread(self, info.groupExport, groupPath)
	if not num then
		return
	end

	-- now that everything is valid, go through and import the new operations
	for module, moduleOperations in pairs(newOperations) do
		for name, operation in pairs(moduleOperations) do
			TSM.operations[module][name] = operation
		end
	end

	-- go through and apply the operations to the groups
	for relPath, operationInfo in pairs(info.groupOperations) do
		local path = groupPath
		if relPath ~= "" then
			path = TSMAPI.Groups:JoinPath(path, relPath)
		end
		TSM.db.profile.groups[path] = operationInfo
	end
	return num
end

function private.ImportGroupThread(self, args)
	self:SetThreadName("IMPORT_GROUP_THREAD")
	local editbox, value, groupPath = unpack(args)
	editbox:SetDisabled(true)
	editbox:SetText("Processing...")
	local num = nil
	if strsub(value, 1, 1) == "^" then
		num = private.ImportGroupAndOperationsThread(self, value, groupPath)
	else
		num = private.ImportGroupHelperThread(self, value, groupPath)
	end
	editbox:SetDisabled(false)
	if not num then
		TSM:Print(L["Invalid import string."])
		return editbox:SetFocus()
	end
	editbox:SetText("")
	TSM:Printf(L["Successfully imported %d items to %s."], num, TSMAPI.Groups:FormatPath(groupPath, true))
	GroupOptions:UpdateTree()
	private:SelectGroup(groupPath)
end

function private.ImportGroupHelperThread(self, importStr, groupPath)
	if not importStr then return end
	importStr = importStr:trim()
	if importStr == "" then return end
	local parentPath = strfind(groupPath, TSM.GROUP_SEP) and TSM.Groups:SplitGroupPath(groupPath)

	if strfind(importStr, "^|c") then
		local itemString = TSMAPI.Item:ToItemString(importStr)
		if not itemString then return end
		if TSMAPI.Item:IsSoulbound(itemString, true) then return 0 end
		if parentPath and TSM.db.profile.importParentOnly and TSM.db.profile.items[itemString] ~= parentPath then return 0 end
		if TSM.db.profile.items[itemString] and TSM.db.profile.moveImportedItems then
			TSM.Groups:MoveItem(itemString, groupPath)
			return 1
		elseif not TSM.db.profile.items[itemString] then
			TSM.Groups:AddItem(itemString, groupPath)
			return 1
		end
		return 0
	end

	local items = {}
	local currentSubPath = ""
	for _, str in ipairs(TSMAPI.Util:SafeStrSplit(importStr, ",")) do
		str = str:trim()
		local noSpaceStr = gsub(str, " ", "") -- forums like to add spaces
		local itemString, subPath
		if tonumber(noSpaceStr) then
			itemString = "i:"..tonumber(noSpaceStr)
		elseif strmatch(noSpaceStr, "^group:") then
			subPath = strsub(str, strfind(str, ":")+1, -1)
			subPath = gsub(subPath, TSM.GROUP_SEP.."[ ]*"..TSM.GROUP_SEP, ",")
		elseif strmatch(noSpaceStr, "p:") then
			if strmatch(noSpaceStr, "^p:%d+$") or strmatch(noSpaceStr, "^p:%d+:%d+:%d+$") then
				itemString = noSpaceStr
				-- validate this pet import
				if not TSMAPI.Item:GetName(itemString) then return end
			end
		elseif strmatch(noSpaceStr, "i:") then
			itemString = noSpaceStr
		elseif strmatch(noSpaceStr, ":") then
			local itemID, randomEnchant = (":"):split(noSpaceStr)
			if not tonumber(itemID) or not tonumber(randomEnchant) then return end
			itemString = "i:"..tonumber(itemID)..":"..tonumber(randomEnchant)
		end

		if subPath then
			currentSubPath = subPath
		elseif itemString then
			if not TSMAPI.Item:IsSoulbound(itemString, true) then
				local isValid = false
				if strmatch(itemString, "^p:") then
					-- validate this pet import
					isValid = TSMAPI.Item:GetName(itemString) and true
				elseif strmatch(itemString, "^i:") then
					itemString = gsub(itemString, ":0:", "::") -- remove empty parts from before patch 7.0.x
					isValid = TSMAPI.Item:ToItemString(itemString) == itemString
				end
				if isValid then
					items[itemString] = currentSubPath
				end
			end
		else
			return
		end
		if self then
			self:Yield()
		end
	end

	local num = 0
	for itemString, subPath in pairs(items) do
		if not (parentPath and TSM.db.profile.moveImportedItems and TSM.db.profile.importParentOnly and TSM.db.profile.items[itemString] ~= parentPath) then
			local path = groupPath
			if subPath ~= "" then
				-- create necessary parent groups
				local subParts = {TSM.GROUP_SEP:split(subPath)}
				for i=1, #subParts-1 do
					TSM.Groups:Create(path..TSM.GROUP_SEP..table.concat(subParts, TSM.GROUP_SEP, 1, i))
				end
				path = path..TSM.GROUP_SEP..subPath
			end
			TSM.Groups:Create(path)
			if TSM.db.profile.items[itemString] and TSM.db.profile.moveImportedItems then
				TSM.Groups:MoveItem(itemString, path)
				num = num + 1
			elseif not TSM.db.profile.items[itemString] then
				TSM.Groups:AddItem(itemString, path)
				num = num + 1
			end
		end
		if self then
			self:Yield()
		end
	end
	return num
end

function private.ExportGroup(groupPath, exportSubGroups, exportOperations)
	local temp = {}
	for itemString, group in pairs(TSM.db.profile.items) do
		if group == groupPath or strfind(group, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP) then
			tinsert(temp, itemString)
		end
	end
	sort(temp, function(a, b)
		local groupA = strlower(gsub(TSM.db.profile.items[a], TSM.GROUP_SEP, "\001"))
		local groupB = strlower(gsub(TSM.db.profile.items[b], TSM.GROUP_SEP, "\001"))
		if groupA == groupB then
			return a < b
		end
		return groupA < groupB
	end)

	local operations = {}
	local groupOperations = {}
	local items = {}
	local currentPath = ""
	for _, itemString in pairs(temp) do
		if TSM.db.profile.exportSubGroups then
			local rawPath = TSM.db.profile.items[itemString]
			local relPath = rawPath
			if relPath == groupPath then
				relPath = ""
			else
				relPath = gsub(relPath, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP, "")
			end
			relPath = gsub(relPath, ",", TSM.GROUP_SEP..TSM.GROUP_SEP)
			if relPath ~= currentPath then
				tinsert(items, "group:"..relPath)
				currentPath = relPath
			end

			if exportOperations then
				groupOperations[relPath] = TSM.db.profile.groups[rawPath]
				for module, operationInfo in pairs(TSM.db.profile.groups[rawPath]) do
					for _, operation in ipairs(operationInfo) do
						if operation ~= "" then
							local data = CopyTable(TSM.operations[module][operation])
							data.ignorePlayer = nil
							data.ignoreFactionrealm = nil
							data.relationships = nil
							operations[module] = operations[module] or {}
							operations[module][operation] = data
						end
					end
				end
			end
		end
		tinsert(items, itemString)
	end

	local groupExport = table.concat(items, ",")
	if not exportOperations then
		return groupExport
	end
	return GroupOptions:Serialize({groupExport=groupExport, groupOperations=groupOperations, operations=operations})
end
TSM.exportedForTesting.ExportGroup = private.ExportGroup

function private:ShowGroupExportFrame(text)
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TradeSkillMaster - "..L["Export Group Items"])
	f:SetLayout("Fill")
	f:SetHeight(300)

	local eb = AceGUI:Create("TSMMultiLineEditBox")
	eb:SetLabel(L["Group Item Data"])
	eb:SetMaxLetters(0)
	eb:SetText(text)
	f:AddChild(eb)

	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end

function private.CreateGroupWithItems(groupName, importStr, moveImportedItems)
	for i=0, math.huge do
		local testName = (i == 0) and groupName or (groupName.."_"..i)
		if not TSM.db.profile.groups[testName] then
			groupName = testName
			break
		end
	end
	TSM.Groups:Create(groupName)

	local tempImportParentOnly = TSM.db.profile.importParentOnly
	local tempMoveImportedItems = TSM.db.profile.moveImportedItems
	TSM.db.profile.importParentOnly = false
	TSM.db.profile.moveImportedItems = moveImportedItems
	local success, num = pcall(function() return private.ImportGroupHelperThread(nil, importStr, groupName) end)
	TSM.db.profile.importParentOnly = tempImportParentOnly
	TSM.db.profile.moveImportedItems = tempMoveImportedItems
	return success and num or nil
end

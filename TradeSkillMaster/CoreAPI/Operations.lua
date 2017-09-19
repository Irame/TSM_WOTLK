-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Operations = TSM:NewModule("Operations", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {operationInfo=TSM.moduleOperationInfo, moduleObjects=TSM.moduleObjects, treeGroup=nil, currentGroup=nil, currentModule=nil}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Operations:GetFirstByItem(itemString, module)
	TSMAPI:Assert(itemString and module, format("Invalid parameters to TSMAPI.Operations:GetFirstByItem('%s', '%s')", tostring(itemString), tostring(module)))
	itemString = TSMAPI.Item:ToBaseItemString(itemString, true)
	local groupPath = TSM.db.profile.items[itemString]
	if not groupPath or not TSM.db.profile.groups[groupPath] or not TSM.db.profile.groups[groupPath][module] then return end

	for _, operation in ipairs(TSM.db.profile.groups[groupPath][module]) do
		if operation ~= "" and not TSM.Modules:IsOperationIgnored(module, operation) then
			return operation
		end
	end
end

function TSMAPI.Operations:Update(moduleName, operationName)
	if not TSM.operations[moduleName][operationName] then return end
	for key in pairs(TSM.operations[moduleName][operationName].relationships) do
		local operation = TSM.operations[moduleName][operationName]
		while operation.relationships[key] do
			local newOperation = TSM.operations[moduleName][operation.relationships[key]]
			if not newOperation then break end
			operation = newOperation
		end
		TSM.operations[moduleName][operationName][key] = operation[key]
	end
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Operations:LoadOperationOptions(parent)
	local tabs = {}
	for _, info in ipairs(private.operationInfo) do
		tinsert(tabs, {text=info.module, value=info.module})
	end
	sort(tabs, function(a, b) return a.text < b.text end)
	tinsert(tabs, 1, {text=L["Help"], value="Help"})

	local tabGroup =  AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs(tabs)
	tabGroup:SetCallback("OnGroupSelected", function(_, _, value)
		tabGroup:ReleaseChildren()
		if value == "Help" then
			private:DrawOperationHelp(tabGroup)
		else
			private.currentModule = value

			private.treeGroup = AceGUI:Create("TSMTreeGroup")
			private.treeGroup:SetLayout("Fill")
			private.treeGroup:SetCallback("OnGroupSelected", private.SelectTree)
			TSM.db.global.moduleOperationsTreeStatus[private.currentModule] = TSM.db.global.moduleOperationsTreeStatus[private.currentModule] or {}
			private.treeGroup:SetStatusTable(TSM.db.global.moduleOperationsTreeStatus[private.currentModule])
			tabGroup:AddChild(private.treeGroup)
			private:UpdateTree()
			local operation = TSM.loadModuleOptionsTab and TSM.loadModuleOptionsTab.operation
			local group = TSM.loadModuleOptionsTab and TSM.loadModuleOptionsTab.group
			if operation then
				if operation == "" then
					private.currentGroup = group -- pass the group along
					private.treeGroup:SelectByPath(1)
					private.currentGroup = nil
				else
					private.treeGroup:SelectByPath(1, operation)
				end
			else
				private.treeGroup:SelectByPath(1)
			end
		end
	end)
	parent:AddChild(tabGroup)

	tabGroup:SelectTab(TSM.loadModuleOptionsTab and TSM.loadModuleOptionsTab.module or "Help")
end



-- ============================================================================
-- Operation Options Tabs / TreeGroup Helper Functions
-- ============================================================================

function private:DrawOperationHelp(container)
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "List",
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Use the tabs above to select the module for which you'd like to configure operations."],
						},
					},
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end

function private:UpdateTree()
	local operationTreeChildren = {}
	for name in pairs(private.moduleObjects[private.currentModule].operations) do
		tinsert(operationTreeChildren, { value = name, text = name })
	end
	sort(operationTreeChildren, function(a, b) return a.value < b.value end)
	private.treeGroup:SetTree({{value=1, text=L["Operations"], children=operationTreeChildren}})
end

function private.SelectTree(treeGroup, _, selection)
	treeGroup:ReleaseChildren()

	local major, minor = ("\001"):split(selection)
	major = tonumber(major)
	if minor then
		private:DrawOperationOptions(treeGroup, minor)
	else
		private:DrawNewOperation(treeGroup)
	end
end

function private:DrawNewOperation(container)
	local currentGroup = private.currentGroup
	local description, tabInfo = nil, nil
	for _, info in ipairs(private.operationInfo) do
		if info.module == private.currentModule then
			description, tabInfo = info.callbackOptions()
		end
	end
	TSMAPI:Assert(description and tabInfo)

	tinsert(tabInfo, { text = L["Relationships"] })
	tinsert(tabInfo, { text = L["Management"] })

	local defaultTab = TSM.db.global.moduleOperationTabs[private.currentModule] or 1
	if not tabInfo[defaultTab] then
		defaultTab = 1
	end
	TSMAPI:Assert(tabInfo[defaultTab])
	TSM.db.global.moduleOperationTabs[private.currentModule] = defaultTab
	local tabList = {}
	for _, info in ipairs(tabInfo) do
		tinsert(tabList, info.text)
	end

	local page = {
		{
			-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["New Operation"],
					children = {
						{
							type = "Label",
							text = description,
							relativeWidth = 1,
						},
						{
							type = "EditBox",
							label = L["Operation Name"],
							relativeWidth = 1,
							callback = function(self, _, operationName)
								TSMAPI:Assert(private.currentModule)
								local moduleObj = private.moduleObjects[private.currentModule]
								operationName = (operationName or ""):trim()
								if operationName == "" then return end
								if moduleObj.operations[operationName] then
									self:SetText("")
									moduleObj:Printf(L["Error creating operation. Operation with name '%s' already exists."], operationName)
									return
								end

								local defaults = nil
								for _, info in ipairs(private.operationInfo) do
									if info.module == private.currentModule then
										defaults = info.defaults
									end
								end
								TSMAPI:Assert(defaults)
								moduleObj.operations[operationName] = CopyTable(defaults)
								private:ShowNewOperationPopup(private.currentModule, currentGroup, operationName)
								private:UpdateTree()
								private.treeGroup:SelectByPath(1, operationName)
							end,
							tooltip = L["Give the new operation a name. A descriptive name will help you find this operation later."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = format(L["Default %s Operation Tab"], private.currentModule),
							list = tabList,
							settingInfo = {TSM.db.global.moduleOperationTabs, private.currentModule},
							relativeWidth = 0.5,
							tooltip = L["Select the default tab for this module's operations."],
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
end

function private:DrawOperationOptions(container, operationName)
	local description, tabInfo, relationshipInfo = nil, nil
	for _, info in ipairs(private.operationInfo) do
		if info.module == private.currentModule then
			description, tabInfo, relationshipInfo = info.callbackOptions()
		end
	end
	TSMAPI:Assert(tabInfo and relationshipInfo)

	local tabs = {}
	for i, info in ipairs(tabInfo) do
		tinsert(tabs, {value=i, text=info.text})
	end
	TSMAPI:Assert(#tabs > 0)

	local relationshipIndex = #tabs+1
	local managementIndex = #tabs+2
	tinsert(tabs, {value=relationshipIndex, text=L["Relationships"]})
	tinsert(tabs, {value=managementIndex, text=L["Management"]})

	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs(tabs)
	tg:SetCallback("OnGroupSelected", function(self, _, value)
		self:ReleaseChildren()
		TSMAPI.Operations:Update(private.currentModule, operationName)

		if value == relationshipIndex then
			private:ShowRelationshipTab(self, operationName, relationshipInfo)
		elseif value == managementIndex then
			private:ShowManagementTab(self, operationName)
		elseif type(value) == "number" then
			tabInfo[value].callback(self, operationName)
		end
	end)
	container:AddChild(tg)

	tg:SelectTab(TSM.db.global.moduleOperationTabs[private.currentModule] or 1)
end

function private:ShowRelationshipTab(container, operationName, settingInfo)
	local moduleObj = private.moduleObjects[private.currentModule]
	local operation = moduleObj.operations[operationName]
	local operationList = {[""]=L["<No Relationship>"]}
	local operationListOrder = {""}
	local incomingRelationships = {}
	for name, data in pairs(moduleObj.operations) do
		if data ~= operation then
			operationList[name] = name
			tinsert(operationListOrder, name)
		end
		for key, targetOperation in pairs(data.relationships) do
			if moduleObj.operations[targetOperation] == operationName then
				incomingRelationships[key] = name
			end
		end
	end
	sort(operationListOrder)

	local target = ""
	local children = {
		{
			type = "InlineGroup",
			layout = "Flow",
			children = {
				{
					type = "Label",
					text = L["Here you can setup relationships between the settings of this operation and other operations for this module. For example, if you have a relationship set to OperationA for the stack size setting below, this operation's stack size setting will always be equal to OperationA's stack size setting."],
					relativeWidth = 1,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "Dropdown",
					label = L["Target Operation"],
					list = operationList,
					order = operationListOrder,
					relativeWidth = 0.5,
					value = target,
					callback = function(self, _, value)
						target = value
					end,
					tooltip = L["Creating a relationship for this setting will cause the setting for this operation to be equal to the equivalent setting of another operation."],
				},
				{
					type = "Button",
					text = L["Set All Relationships to Target"],
					relativeWidth = 0.5,
					callback = function()
						for _, inline in ipairs(settingInfo) do
							for _, widget in ipairs(inline) do
								local prev = operation.relationships[widget.key]
								if target == "" then
									operation.relationships[widget.key] = nil
								else
									operation.relationships[widget.key] = target
									if private:IsCircularRelationship(private.currentModule, operation, widget.key) then
										operation.relationships[widget.key] = prev
									end
								end
							end
						end
						container:Reload()
					end,
					tooltip = L["Sets all relationship dropdowns below to the operation selected."],
				},
			},
		},
	}
	for _, inlineData in ipairs(settingInfo) do
		local inlineChildren = {}
		for _, dropdownData in ipairs(inlineData) do
			local dropdown = {
				type = "Dropdown",
				label = dropdownData.label,
				list = operationList,
				order = operationListOrder,
				relativeWidth = 0.5,
				value = operation.relationships[dropdownData.key] or "",
				callback = function(self, _, value)
					local previousValue = operation.relationships[dropdownData.key]
					if value == "" then
						operation.relationships[dropdownData.key] = nil
					else
						operation.relationships[dropdownData.key] = value
					end
					if private:IsCircularRelationship(private.currentModule, operation, dropdownData.key) then
						operation.relationships[dropdownData.key] = previousValue
						moduleObj:Print(L["This relationship cannot be applied because doing so would create a circular relationship."])
						self:SetValue(operation.relationships[dropdownData.key] or "")
					end
				end,
				tooltip = L["Creating a relationship for this setting will cause the setting for this operation to be equal to the equivalent setting of another operation."],
			}
			tinsert(inlineChildren, dropdown)
		end
		local inlineGroup = {
			type = "InlineGroup",
			layout = "flow",
			title = inlineData.label,
			children = inlineChildren,
		}
		tinsert(children, inlineGroup)
	end

	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = children,
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end

function private:ShowManagementTab(container, operationName)
	local moduleObj = private.moduleObjects[private.currentModule]
	local operation = moduleObj.operations[operationName]

	local playerList = {}
	for playerName in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters) do
		playerList[playerName.." - "..UnitFactionGroup("player").." - "..GetRealmName()] = playerName
	end

	local factionrealmList = {}
	for _, factionrealm in ipairs(TSM.db:GetScopeKeys("factionrealm")) do
		factionrealmList[factionrealm] = factionrealm
	end

	local groupList = {}
	for path, modules in pairs(TSM.db.profile.groups) do
		if modules[private.currentModule] then
			for i=1, #modules[private.currentModule] do
				if modules[private.currentModule][i] == operationName then
					tinsert(groupList, path)
				end
			end
		end
	end
	sort(groupList, function(a,b) return strlower(gsub(a, TSM.GROUP_SEP, "\001")) < strlower(gsub(b, TSM.GROUP_SEP, "\001")) end)

	local groupWidgets = {
		{
			type = "Label",
			relativeWidth = 1,
			text = L["Below is a list of groups which this operation is currently applied to. Clicking on the 'Remove' button next to the group name will remove the operation from that group."],
		},
		{
			type = "HeadingLine",
		},
	}
	for _, groupPath in ipairs(groupList) do
		tinsert(groupWidgets, {
				type = "Button",
				relativeWidth = 0.2,
				text = L["Remove"],
				callback = function()
					for i=#TSM.db.profile.groups[groupPath][private.currentModule], 1, -1 do
						if TSM.db.profile.groups[groupPath][private.currentModule][i] == operationName then
							TSM.Groups:RemoveOperation(groupPath, private.currentModule, i)
						end
					end
					TSM.Modules:CheckOperationRelationships(private.currentModule)
					private:ModuleOptionsRefresh(moduleObj, operationName)
				end,
				tooltip = L["Click this button to completely remove this operation from the specified group."],
			})
		tinsert(groupWidgets, {
				type = "Label",
				relativeWidth = 0.05,
				text = "",
			})
		tinsert(groupWidgets, {
				type = "Label",
				relativeWidth = 0.75,
				text = TSMAPI.Groups:FormatPath(groupPath, true),
			})
	end
	tinsert(groupWidgets, {type="HeadingLine"})
	tinsert(groupWidgets, {
			type = "GroupBox",
			label = L["Apply Operation to Group"],
			relativeWidth = 1,
			callback = function(self, _, path)
				if not path then return end
				TSM.db.profile.groups[path][private.currentModule] = TSM.db.profile.groups[path][private.currentModule] or {}
				local operations = TSM.db.profile.groups[path][private.currentModule]
				local num = #operations
				if num == 0 then
					TSM.Groups:SetOperationOverride(path, private.currentModule, true)
					TSM.Groups:AddOperation(path, private.currentModule)
					TSM.Groups:SetOperation(path, private.currentModule, operationName, 1)
					TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
				elseif operations[num] == "" then
					TSM.Groups:SetOperationOverride(path, private.currentModule, true)
					TSM.Groups:SetOperation(path, private.currentModule, operationName, num)
					TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
				else
					local canAdd
					for _, info in ipairs(private.operationInfo) do
						if private.currentModule == info.module then
							canAdd = num < info.maxOperations
							break
						end
					end
					if canAdd then
						StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"] = StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"] or {
							text = L["This group already has operations. Would you like to add another one or replace the last one?"],
							button1 = ADD,
							button2 = L["Replace"],
							button3 = CANCEL,
							timeout = 0,
							OnAccept = function()
								-- the "add" button
								local path, moduleName, operationName, num = unpack(StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"].tsmInfo)
								TSM.Groups:SetOperationOverride(path, moduleName, true)
								TSM.Groups:AddOperation(path, moduleName)
								TSM.Groups:SetOperation(path, moduleName, operationName, num+1)
								TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
							end,
							OnCancel = function()
								-- the "replace" button
								local path, moduleName, operationName, num = unpack(StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"].tsmInfo)
								TSM.Groups:SetOperationOverride(path, moduleName, true)
								TSM.Groups:SetOperation(path, moduleName, operationName, num)
								TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
							end,
						}
						StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"].tsmInfo = {path, private.currentModule, operationName, num}
						TSMAPI.Util:ShowStaticPopupDialog("TSM_APPLY_OPERATION_ADD")
					else
						StaticPopupDialogs["TSM_APPLY_OPERATION"] = StaticPopupDialogs["TSM_APPLY_OPERATION"] or {
							text = L["This group already has the max number of operation. Would you like to replace the last one?"],
							button1 = L["Replace"],
							button2 = CANCEL,
							timeout = 0,
							OnAccept = function()
								-- the "replace" button
								local path, moduleName, operationName, num = unpack(StaticPopupDialogs["TSM_APPLY_OPERATION"].tsmInfo)
								TSM.Groups:SetOperationOverride(path, moduleName, true)
								TSM.Groups:SetOperation(path, moduleName, operationName, num)
								TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
							end,
						}
						StaticPopupDialogs["TSM_APPLY_OPERATION"].tsmInfo = {path, private.currentModule, operationName, num}
						TSMAPI.Util:ShowStaticPopupDialog("TSM_APPLY_OPERATION")
					end
				end
				self:SetText()
			end,
		})

	local page = {
		{
			type = "ScrollFrame",
			layout = "Flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Operation Management"],
					children = {
						{
							type = "EditBox",
							label = L["Rename Operation"],
							value = operationName,
							relativeWidth = 0.5,
							callback = function(self,_,name)
								name = (name or ""):trim()
								if name == "" then return end
								if moduleObj.operations[name] then
									self:SetText("")
									return moduleObj:Printf(L["Error renaming operation. Operation with name '%s' already exists."], name)
								end
								moduleObj.operations[name] = moduleObj.operations[operationName]
								moduleObj.operations[operationName] = nil
								for _, groupPath in ipairs(groupList) do
									for i=1, #TSM.db.profile.groups[groupPath][private.currentModule] do
										if TSM.db.profile.groups[groupPath][private.currentModule][i] == operationName then
											TSM.db.profile.groups[groupPath][private.currentModule][i] = name
										end
									end
								end
								TSM.Modules:CheckOperationRelationships(private.currentModule)
								private:ModuleOptionsRefresh(moduleObj, name)
							end,
							tooltip = L["Give this operation a new name. A descriptive name will help you find this operation later."],
						},
						{
							type = "EditBox",
							label = L["Duplicate Operation"],
							relativeWidth = 0.5,
							callback = function(self,_,name)
								name = (name or ""):trim()
								if name == "" then return end
								if moduleObj.operations[name] then
									self:SetText("")
									return moduleObj:Printf(L["Error duplicating operation. Operation with name '%s' already exists."], name)
								end
								moduleObj.operations[name] = CopyTable(moduleObj.operations[operationName])
								TSM.Modules:CheckOperationRelationships(private.currentModule)
								private:ModuleOptionsRefresh(moduleObj, name)
							end,
							tooltip = L["Type in the name of a new operation you wish to create with the same settings as this operation."],
						},
						{
							type = "Button",
							text = L["Delete Operation"],
							relativeWidth = 1,
							callback = function()
								StaticPopupDialogs["TSM_DELETE_OPERATION"] = StaticPopupDialogs["TSM_DELETE_OPERATION"] or {
									text = L["Are you sure you want to delete this operation?"],
									button1 = DELETE,
									button2 = CANCEL,
									timeout = 0,
									OnAccept = function()
										local operationName, groupList, moduleObj, moduleName = unpack(StaticPopupDialogs["TSM_DELETE_OPERATION"].tsmInfo)
										moduleObj.operations[operationName] = nil
										for _, groupPath in ipairs(groupList) do
											for i=#TSM.db.profile.groups[groupPath][moduleName], 1, -1 do
												if TSM.db.profile.groups[groupPath][moduleName][i] == operationName then
													TSM.Groups:RemoveOperation(groupPath, moduleName, i)
												end
											end
										end
										TSM.Modules:CheckOperationRelationships(moduleName)
										private:ModuleOptionsRefresh(moduleObj)
									end,
								}
								StaticPopupDialogs["TSM_DELETE_OPERATION"].tsmInfo = {operationName, groupList, moduleObj, private.currentModule}
								TSMAPI.Util:ShowStaticPopupDialog("TSM_DELETE_OPERATION")
							end,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Ignores"],
					children = {
						{
							type = "Dropdown",
							label = L["Ignore Operation on Faction-Realms:"],
							list = factionrealmList,
							relativeWidth = 0.5,
							settingInfo = {operation, "ignoreFactionrealm"},
							multiselect = true,
							tooltip = L["This operation will be ignored when you're on any character which is checked in this dropdown."],
						},
						{
							type = "Dropdown",
							label = L["Ignore Operation on Characters:"],
							list = playerList,
							relativeWidth = 0.5,
							settingInfo = {operation, "ignorePlayer"},
							multiselect = true,
							tooltip = L["This operation will be ignored when you're on any character which is checked in this dropdown."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Import / Export"],
					children = {
						{
							type = "EditBox",
							label = L["Import Operation Settings"],
							relativeWidth = 0.5,
							callback = function(self, _, value)
								value = value:trim()
								if value == "" then return end
								local valid, data = Operations:Deserialize(value)
								if not valid then
									TSM:Print(L["Invalid import string."])
									self:SetFocus()
									return
								elseif data.module ~= private.currentModule then
									TSM:Print(L["Invalid import string."].." "..L["You appear to be attempting to import an operation from a different module."])
									self:SetText("")
									return
								end
								data.module = nil
								data.ignorePlayer = {}
								data.ignoreFactionrealm = {}
								data.relationships = {}
								for defaultName, defaultValue in pairs(private:GetCurrentOperationInfo().defaults) do
									if data[defaultName] == nil then
										if type(defaultValue) == "table" then
											data[defaultName] = CopyTable(defaultValue)
										else
											data[defaultName] = defaultValue
										end
									end
								end
								moduleObj.operations[operationName] = data
								self:SetText("")
								TSM:Print(L["Successfully imported operation settings."])
								private:ModuleOptionsRefresh(moduleObj, operationName)
							end,
							tooltip = L["Paste the exported operation settings into this box and hit enter or press the 'Okay' button. Imported settings will irreversibly replace existing settings for this operation."],
						},
						{
							type = "Button",
							text = L["Export Operation"],
							relativeWidth = 0.5,
							callback = function()
								local data = CopyTable(operation)
								data.module = private.currentModule
								data.ignorePlayer = nil
								data.ignoreFactionrealm = nil
								data.relationships = nil
								private:ShowOperationExportFrame(Operations:Serialize(data))
							end,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Groups"],
					children = groupWidgets,
				},
			},
		},
	}

	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:ShowNewOperationPopup(moduleName, group, operationName)
	if not group then return end
	StaticPopupDialogs["TSM_NEW_OPERATION_ADD"] = StaticPopupDialogs["TSM_NEW_OPERATION_ADD"] or {
		button1 = YES,
		button2 = NO,
		timeout = 0,
	}
	StaticPopupDialogs["TSM_NEW_OPERATION_ADD"].text = format(L["Would you like to add this new operation to %s?"], TSMAPI.Groups:FormatPath(group, true))
	StaticPopupDialogs["TSM_NEW_OPERATION_ADD"].OnAccept = function()
		-- the "add" button
		TSM.Groups:SetOperation(group, moduleName, operationName, #TSM.db.profile.groups[group][moduleName])
		TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(group, true))
	end
	TSMAPI.Util:ShowStaticPopupDialog("TSM_NEW_OPERATION_ADD")
end

function private:ModuleOptionsRefresh(moduleObj, operationName)
	private:UpdateTree()
	if operationName then
		private.treeGroup:SelectByPath(1, operationName)
		private.treeGroup.children[1]:SelectTab("management")
	else
		private.treeGroup:SelectByPath(1)
	end
end

function private:IsCircularRelationship(moduleName, operation, key, visited)
	visited = visited or {}
	if visited[operation] then return true end
	visited[operation] = true
	if not operation.relationships[key] then return end
	return private:IsCircularRelationship(moduleName, TSM.operations[moduleName][operation.relationships[key]], key, visited)
end

function private:ShowOperationExportFrame(text)
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TradeSkillMaster - "..L["Export Operation"])
	f:SetLayout("Fill")
	f:SetHeight(300)

	local eb = AceGUI:Create("TSMMultiLineEditBox")
	eb:SetLabel(L["Operation Data"])
	eb:SetMaxLetters(0)
	eb:SetText(text)
	f:AddChild(eb)

	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end

function private:GetCurrentOperationInfo()
	TSMAPI:Assert(private.currentModule)
	for _, info in ipairs(private.operationInfo) do
		if info.module == private.currentModule then
			return info
		end
	end
	TSMAPI:Assert(false)
end

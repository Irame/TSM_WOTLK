-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
TSM.GROUP_SEP = "`"
local Groups = TSM:NewModule("Groups")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {operationInfo=TSM.moduleOperationInfo}
local GROUP_LEVEL_COLORS = {
	"FCF141",
	"BDAEC6",
	"06A2CB",
	"FFB85C",
	"51B599",
}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Groups:FormatPath(path, useColor)
	if not path then return end
	local result = gsub(path, TSM.GROUP_SEP, "->")
	if useColor then
		return TSMAPI.Design:GetInlineColor("link")..result.."|r"
	else
		return result
	end
end

function TSMAPI.Groups:JoinPath(...)
	return strjoin(TSM.GROUP_SEP, ...)
end

function TSMAPI.Groups:GetPath(itemString)
	return TSM.db.profile.items[itemString]
end

-- Takes a list of itemString/groupPath k,v pairs and adds them to new groups.
function TSMAPI.Groups:CreatePreset(itemList, moduleName, operationInfo)
	for itemString, groupPath in pairs(itemList) do
		if not TSM.db.profile.items[itemString] and not TSMAPI.Item:IsSoulbound(itemString, true) then
			local pathParts = {TSM.GROUP_SEP:split(groupPath)}
			for i=1, #pathParts do
				local path = table.concat(pathParts, TSM.GROUP_SEP, 1, i)
				Groups:Create(path)
			end
			Groups:AddItem(itemString, groupPath)
			if moduleName and operationInfo and operationInfo[groupPath] then
				if strfind(groupPath, TSM.GROUP_SEP) then
					Groups:SetOperationOverride(groupPath, moduleName, true)
				end
				Groups:SetOperation(groupPath, moduleName, operationInfo[groupPath], 1)
			end
		end
	end

	TSM.GroupOptions:UpdateTree()
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Groups:GetGroupPathList(module)
	local list, disabled = {}, {}
	for groupPath in pairs(TSM.db.profile.groups) do
		if module then
			local operations = Groups:GetGroupOperations(groupPath, module)
			if not operations then
				disabled[groupPath] = true
			end
		end
		tinsert(list, groupPath)
	end

	for groupPath in pairs(TSM.db.profile.groups) do
		if not disabled[groupPath] then
			local pathParts = {TSM.GROUP_SEP:split(groupPath)}
			for i=1, #pathParts-1 do
				local path = table.concat(pathParts, TSM.GROUP_SEP, 1, i)
				disabled[path] = nil
			end
		end
	end

	sort(list, function(a,b) return strlower(gsub(a, TSM.GROUP_SEP, "\001")) < strlower(gsub(b, TSM.GROUP_SEP, "\001")) end)
	return list, disabled
end

function Groups:RegisterOperationInfo(module, info)
	info = CopyTable(info)
	info.module = module
	tinsert(private.operationInfo, info)
end

function Groups:GetGroupOperations(path, module)
	if not TSM.db.profile.groups[path] then return end

	if module and TSM.db.profile.groups[path][module] then
		local operations = CopyTable(TSM.db.profile.groups[path][module])
		for i=#operations, 1, -1 do
			if not operations[i] or operations[i] == "" or TSM.Modules:IsOperationIgnored(module, operations[i]) then
				tremove(operations, i)
			end
		end
		if #operations > 0 then
			return operations
		end
	end
end

-- Splits the given group path into the parent path and group name
-- Parent will be nil if there is no parent
function Groups:SplitGroupPath(path)
	local parts = {TSM.GROUP_SEP:split(path)}
	local parent = table.concat(parts, TSM.GROUP_SEP, 1, #parts-1)
	parent = parent ~= "" and parent or nil
	local groupName = parts[#parts]
	return parent, groupName
end

function Groups:ColorName(groupName, level)
	local color = GROUP_LEVEL_COLORS[(level-1) % #GROUP_LEVEL_COLORS + 1]
	return "|cFF"..color..groupName.."|r"
end

function Groups:GetItems(path)
	local items = {}
	for itemString, groupPath in pairs(TSM.db.profile.items) do
		if groupPath == path then
			itemString = TSMAPI.Item:ToItemString(itemString)
			if itemString then
				items[itemString] = true
			end
		end
	end
	return items
end

-- Creates a new group with the specified path
function Groups:Create(groupPath)
	if TSM.db.profile.groups[groupPath] then return end
	TSM.db.profile.groups[groupPath] = {}
	for _, info in ipairs(private.operationInfo) do
		TSM.db.profile.groups[groupPath][info.module] = TSM.db.profile.groups[groupPath][info.module] or {}
		if Groups:SplitGroupPath(groupPath) then
			Groups:SetOperationOverride(groupPath, info.module, nil, true)
		end
	end
end

-- Deletes a group with the specified path and everything (items/subGroups) below it
function Groups:Delete(groupPath)
	if not TSM.db.profile.groups[groupPath] then return end

	-- delete this group and all subgroups
	for path in pairs(TSM.db.profile.groups) do
		if path == groupPath or strfind(path, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP) then
			TSM.db.profile.groups[path] = nil
		end
	end

	local parent = Groups:SplitGroupPath(groupPath)
	if parent and TSM.db.profile.keepInParent then
		-- move all items in this group its subgroups to the parent
		local changes = {}
		for itemString, path in pairs(TSM.db.profile.items) do
			if path == groupPath or strfind(path, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP) then
				changes[itemString] = parent
			end
		end
		for itemString, newPath in pairs(changes) do
			TSM.db.profile.items[itemString] = newPath
		end
	else
		-- delete all items in this group or subgroup
		for itemString, path in pairs(TSM.db.profile.items) do
			if path == groupPath or strfind(path, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP) then
				TSM.db.profile.items[itemString] = nil
			end
		end
	end
end

-- Moves (renames) a group at the given path to the newPath
function Groups:Move(groupPath, newPath)
	if not TSM.db.profile.groups[groupPath] then return end
	if TSM.db.profile.groups[newPath] then return end

	-- change the path of all subgroups
	local changes = {}
	for path, groupData in pairs(TSM.db.profile.groups) do
		if path == groupPath or strfind(path, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP) then
			changes[path] = gsub(path, "^"..TSMAPI.Util:StrEscape(groupPath), TSMAPI.Util:StrEscape(newPath))
		end
	end
	for oldPath, newPath in pairs(changes) do
		TSM.db.profile.groups[newPath] = TSM.db.profile.groups[oldPath]
		TSM.db.profile.groups[oldPath] = nil
	end

	-- change the path for all items in this group (and subgroups)
	wipe(changes)
	for itemString, path in pairs(TSM.db.profile.items) do
		if path == groupPath or strfind(path, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP) then
			changes[itemString] = gsub(path, "^"..TSMAPI.Util:StrEscape(groupPath), TSMAPI.Util:StrEscape(newPath))
		end
	end
	for itemString, newPath in pairs(changes) do
		TSM.db.profile.items[itemString] = newPath
	end
	for _, info in ipairs(private.operationInfo) do
		TSM.db.profile.groups[newPath][info.module] = TSM.db.profile.groups[newPath][info.module] or {}
		if Groups:SplitGroupPath(newPath) and not TSM.db.profile.groups[newPath][info.module].override then
			Groups:SetOperationOverride(newPath, info.module, nil, true)
		end
	end
end

-- Adds an item to the group at the specified path.
function Groups:AddItem(itemString, path)
	if not (strfind(path, TSM.GROUP_SEP) or not TSM.db.profile.items[itemString]) then return end
	if not TSM.db.profile.groups[path] then return end

	TSM.db.profile.items[itemString] = path
end

-- Deletes an item from the group at the specified path.
function Groups:RemoveItem(itemString)
	if not TSM.db.profile.items[itemString] then return end
	TSM.db.profile.items[itemString] = nil
end

-- Moves an item from an existing group to the group at the specified path.
function Groups:MoveItem(itemString, path)
	if not TSM.db.profile.items[itemString] then return end
	if not TSM.db.profile.groups[path] then return end
	TSM.db.profile.items[itemString] = path
end

function Groups:SetOperation(path, module, operation, index)
	if not TSM.db.profile.groups[path] then return end
	if not TSM.db.profile.groups[path][module] then return end

	TSM.db.profile.groups[path][module][index] = operation
	local subGroups = private:GetSubGroups(path)
	if subGroups then
		for subGroupPath in pairs(subGroups) do
			private:SetOperationHelper(subGroupPath, module, path)
		end
	end
end

function Groups:AddOperation(path, module)
	if not TSM.db.profile.groups[path] then return end

	tinsert(TSM.db.profile.groups[path][module], "")
	local subGroups = private:GetSubGroups(path)
	if subGroups then
		for subGroupPath in pairs(subGroups) do
			private:SetOperationHelper(subGroupPath, module, path)
		end
	end
end

function Groups:RemoveOperation(path, module, index)
	if not TSM.db.profile.groups[path] then return end
	local numOperations = #TSM.db.profile.groups[path][module]
	for i=index+1, numOperations do
		Groups:SetOperation(path, module, TSM.db.profile.groups[path][module][i], i-1)
	end
	Groups:SetOperation(path, module, nil, numOperations)
end

function Groups:SetOperationOverride(path, module, override, force)
	if not TSM.db.profile.groups[path] or (not force and TSM.db.profile.groups[path][module] and TSM.db.profile.groups[path][module].override == override) then return end

	-- clear all operations for this path/module
	TSM.db.profile.groups[path][module] = {override=(override or nil)}
	-- set this group's (and all applicable subgroups') operation to the parent's
	local parentPath = Groups:SplitGroupPath(path)
	if not parentPath then return end
	TSM.db.profile.groups[parentPath][module] = TSM.db.profile.groups[parentPath][module] or {override=(override or nil)}
	for index, operation in ipairs(TSM.db.profile.groups[parentPath][module]) do
		Groups:SetOperation(path, module, operation, index)
	end
end

function Groups:GetOperationInfo()
	return private.operationInfo
end



-- ============================================================================
-- Group Helper Functions
-- ============================================================================

function private:GetSubGroups(groupPath)
	local subGroups = {}
	local hasSubGroup
	for group in pairs(TSM.db.profile.groups) do
		local _, _, subGroupName = strfind(group, "^"..TSMAPI.Util:StrEscape(groupPath)..TSM.GROUP_SEP.."([^`]+)$")
		if subGroupName then
			subGroups[group] = subGroupName
			hasSubGroup = true
		end
	end
	if hasSubGroup then
		return subGroups
	end
end

function private:SetOperationHelper(path, module, origPath)
	if TSM.db.profile.groups[path][module] and TSM.db.profile.groups[path][module].override then return end
	TSM.db.profile.groups[path][module] = CopyTable(TSM.db.profile.groups[origPath][module])
	TSM.db.profile.groups[path][module].override = nil
	local subGroups = private:GetSubGroups(path)
	if subGroups then
		for subGroupPath in pairs(subGroups) do
			private:SetOperationHelper(subGroupPath, module, origPath)
		end
	end
end

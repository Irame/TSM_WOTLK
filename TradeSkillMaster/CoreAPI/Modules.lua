-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for the new standardized module registration / format

local TSM = select(2, ...)
local Modules = TSM:NewModule("Modules", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {hasOutdatedAddons=nil}
local moduleObjects = TSM.moduleObjects
local moduleNames = TSM.moduleNames
local MODULE_FIELD_INFO = { -- info on all the possible fields of the module objects which TSM core cares about
	-- operation fields
	{ key = "operations", type = "table", subFieldInfo = { maxOperations = "number", callbackOptions = "function", callbackInfo = "function", defaults = "table" } },
	-- tooltip fields
	{ key = "tooltip", type = "table", subFieldInfo = { callbackLoad = "function", callbackOptions = "function", defaults = "table"}},
	-- shared feature fields
	{ key = "slashCommands", type = "table", subTableInfo = { key = "string", label = "string", callback = "function" } },
	{ key = "icons", type = "table", subTableInfo = { side = "string", desc = "string", callback = "function", icon = "string" } },
	{ key = "auctionTab", type = "table", subFieldInfo = { callbackShow = "function", callbackHide = "function" } },
	{ key = "bankUiButton", type = "table", subFieldInfo = { callback = "function" } },
	{ key = "moduleOptions", type = "table", subFieldInfo = { callback = "function" } },
	-- data access fields
	{ key = "priceSources", type = "table", subTableInfo = { key = "string", label = "string", callback = "function" } },
	{ key = "moduleAPIs", type = "table", subTableInfo = { key = "string", callback = "function" } },
}
local OPERATION_DEFAULT_FIELDS = {
	ignorePlayer = {},
	ignoreFactionrealm = {},
	relationships = {},
}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI:NewModule(obj)
	local errMsg
	if obj == TSM then
		local tmp = TSM.operations
		TSM.operations = nil
		errMsg = private:ValidateModuleObject(obj)
		TSM.operations = tmp
	else
		errMsg = private:ValidateModuleObject(obj)
	end
	TSMAPI:Assert(not errMsg, errMsg, 1)

	-- remove from AceAddon's table for release versions
	local isDebug = false
	--[===[@debug@
	isDebug = true
	--@end-debug@]===]
	if not isDebug then
		local aceAddons = LibStub("AceAddon-3.0").addons
		for name in pairs(aceAddons) do
			if strmatch(name, obj.name) then
				aceAddons[name] = nil
			end
		end
	end

	-- sets the _version, _author, and _desc fields
	local fullName = gsub(obj.name, "TSM_", "TradeSkillMaster_")
	local moduleName = gsub(obj.name, "TradeSkillMaster_", "")
	moduleName = gsub(obj.name, "TSM_", "")
	obj._version = GetAddOnMetadata(fullName, "X-Curse-Packaged-Version") or GetAddOnMetadata(fullName, "Version")
	if strsub(obj._version, 1, 1) == "@" then
		obj._version = "Dev"
	end
	obj._author = GetAddOnMetadata(fullName, "Author")
	obj._desc = GetAddOnMetadata(fullName, "Notes")
	obj._moduleName = moduleName

	-- store the object in the local table
	moduleObjects[moduleName] = obj
	tinsert(moduleNames, moduleName)
	sort(moduleNames, function(a, b)
		if a == "TradeSkillMaster" then
			return true
		elseif b == "TradeSkillMaster" then
			return false
		else
			return a < b
		end
	end)

	-- register icons with main frame code
	if obj.icons then
		for _, info in ipairs(obj.icons) do
			if info.slashCommand then
				obj.slashCommands = obj.slashCommands or {}
				tinsert(obj.slashCommands, {key=info.slashCommand, label=format(L["Opens the TSM window to the '%s' page"], info.desc), callback=function() TSM.MainFrame:Show() TSM.MainFrame:SelectIcon(obj.name, info.desc) end})
			end
			TSM.MainFrame:RegisterMainFrameIcon(info.desc, info.icon, info.callback, obj.name, info.side)
		end
	end

	-- register auction buttons with auction frame code
	if obj.auctionTab then
		TSM:RegisterAuctionFunction(moduleName, obj.auctionTab.callbackShow, obj.auctionTab.callbackHide)
	end

	-- register module options
	if obj.moduleOptions then
		TSM.Options:RegisterModuleOptions(moduleName, obj.moduleOptions.callback)
	end

	-- setup operations
	if obj ~= TSM and obj.operations then
		for key, value in pairs(OPERATION_DEFAULT_FIELDS) do
			TSMAPI:Assert(not obj.operations.defaults[key], "Invalid use of reserved operation field: "..key)
			obj.operations.defaults[key] = value
		end
		TSM.Groups:RegisterOperationInfo(moduleName, obj.operations)
		TSM.operations[moduleName] = TSM.operations[moduleName] or {}
		obj.operations = TSM.operations[moduleName]
		for _, operation in pairs(obj.operations) do
			operation.ignorePlayer = operation.ignorePlayer or {}
			operation.ignoreFactionrealm = operation.ignoreFactionrealm or {}
			operation.relationships = operation.relationships or {}
		end
		Modules:CheckOperationRelationships(moduleName)
	end

	-- register tooltip options
	if obj.tooltip then
		TSM.Tooltips:RegisterInfo(moduleName, obj.tooltip)
	end

	-- register bankUi Tabs
	if obj.bankUiButton then
		TSM:RegisterBankUiButton(moduleName, obj.bankUiButton.callback)
	end

	-- replace default Print and Printf functions
	local Print = obj.Print
	obj.Print = function(self, ...) Print(self, TSMAPI:GetChatFrame(), ...) end
	local Printf = obj.Printf
	obj.Printf = function(self, ...) Printf(self, TSMAPI:GetChatFrame(), ...) end

	-- embed analytics functions
	TSM.Analytics:Embed(obj)

	-- embed debug logging functions
	TSM.Debug:EmbedLogging(obj)
	obj:LOG_RAISE_STACK() -- do the logging on behalf of the calling function
	obj:LOG_INFO("Registered with TSM!")
end

function TSMAPI:HasModule(moduleName)
	return moduleObjects[moduleName] and true or false
end

function TSMAPI:ModuleAPI(moduleName, key, ...)
	if type(moduleName) ~= "string" or type(key) ~= "string" then return nil, "Invalid args" end
	if not moduleObjects[moduleName] then return nil, "Invalid module" end

	for _, info in ipairs(moduleObjects[moduleName].moduleAPIs or {}) do
		if info.key == key then
			return info.callback(...)
		end
	end
	return nil, "Key not found"
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Modules:OnEnable()
	-- register the chat commands (slash commands) - whenver '/tsm' or '/tradeskillmaster' is typed by the user, Modules:ChatCommand() will be called
	Modules:RegisterChatCommand("tsm", "ChatCommand")
	Modules:RegisterChatCommand("tradeskillmaster", "ChatCommand")

	-- no modules and update available popups
	TSMAPI.Delay:AfterTime(3, function()
		if #moduleNames == 1 then
			StaticPopupDialogs["TSMInfoPopup"] = {
				text = L["|cffffff00Important Note:|r You do not currently have any modules installed / enabled for TradeSkillMaster! |cff77ccffYou must download modules for TradeSkillMaster to have some useful functionality!|r\n\nPlease visit http://www.curse.com/addons/wow/tradeskill-master and check the project description for links to download modules."],
				button1 = L["I'll Go There Now!"],
				timeout = 0,
				whileDead = true,
				OnAccept = function() TSM:Print(L["Just incase you didn't read this the first time:"]) TSM:Print(L["|cffffff00Important Note:|r You do not currently have any modules installed / enabled for TradeSkillMaster! |cff77ccffYou must download modules for TradeSkillMaster to have some useful functionality!|r\n\nPlease visit http://www.curse.com/addons/wow/tradeskill-master and check the project description for links to download modules."]) end,
			}
			TSMAPI.Util:ShowStaticPopupDialog("TSMInfoPopup")
		end
		local addonVersions = TSM:GetAppAddonVersions()
		if addonVersions then
			for _, obj in pairs(moduleObjects) do
				local fullName = gsub(obj.name, "TSM_", "TradeSkillMaster_")
				local currentVersion = private:VersionStrToInt(obj._version)
				if currentVersion and addonVersions[fullName] and currentVersion < addonVersions[fullName] then
					TSM.db.global.pendingAddonUpdate[fullName] = TSM.db.global.pendingAddonUpdate[fullName] or time()
					if TSM.db.global.pendingAddonUpdate[fullName] + 48 * 60 * 60 < time() then
						TSM.db.global.pendingAddonUpdate[fullName] = time()
						StaticPopupDialogs["TSMUpdatePopup_"..fullName] = {
							text = format(L["|cffffff00Important Note:|r An update is available for %s. You should update as soon as possible to ensure TSM continues to function properly."], fullName),
							button1 = L["I'll Go Update!"],
							timeout = 0,
							whileDead = true,
						}
						TSMAPI.Util:ShowStaticPopupDialog("TSMUpdatePopup_"..fullName)
						private.hasOutdatedAddons = true
					end
				else
					TSM.db.global.pendingAddonUpdate[fullName] = nil
				end
			end
		end
	end)
end

function Modules:HasOutdatedAddons()
	return private.hasOutdatedAddons
end

function Modules:ProfileUpdated(isReset)
	if Modules.ignoreProfileUpdated then
		return
	end
	if isReset then
		-- reset tooltip options
		for moduleName, obj in pairs(moduleObjects) do
			TSM.db.profile.tooltipOptions[moduleName] = obj.tooltip and obj.tooltip.defaults or nil
		end
	end

	-- update operations
	if TSM.db.global.globalOperations then
		for moduleName, obj in pairs(moduleObjects) do
			if obj.operations then
				TSM.db.global.operations[moduleName] = TSM.db.global.operations[moduleName] or {}
				obj.operations = TSM.db.global.operations[moduleName]
			end
		end
		TSM.operations = TSM.db.global.operations
	else
		for moduleName, obj in pairs(moduleObjects) do
			if obj.operations then
				TSM.db.profile.operations[moduleName] = TSM.db.profile.operations[moduleName] or {}
				obj.operations = TSM.db.profile.operations[moduleName]
			end
		end
		TSM.operations = TSM.db.profile.operations
	end
	for moduleName, operations in pairs(TSM.operations) do
		for _, operation in pairs(operations) do
			operation.ignorePlayer = operation.ignorePlayer or {}
			operation.ignoreFactionrealm = operation.ignoreFactionrealm or {}
			operation.relationships = operation.relationships or {}
		end
		Modules:CheckOperationRelationships(moduleName)
	end

	-- update design
	if not TSM.db.profile.design then
		TSM.Options:LoadDefaultDesign()
	end
end

function Modules:GetInfo()
	local info = {}
	for _, name in ipairs(moduleNames) do
		local obj = moduleObjects[name]
		local isOfficial = strfind(obj._author, "^Sapu94")
		tinsert(info, { name = name, version = obj._version, author = obj._author, desc = obj._desc, isOfficial = isOfficial })
	end
	return info
end

function Modules:GetName(obj)
	for _, name in ipairs(moduleNames) do
		if obj == moduleObjects[name] then return name end
	end
end

function Modules:OnLogout()
	local appDB = nil
	if TSMAPI:HasModule("AppHelper") and TSM:GetAppVersion() > 300 then
		TradeSkillMaster_AppHelperDB = TradeSkillMaster_AppHelperDB or {}
		appDB = TradeSkillMaster_AppHelperDB
	end
	local originalProfile = TSM.db:GetCurrentProfile()
	for _, obj in pairs(moduleObjects) do
		-- erroring here would cause the profile to be reset, so use pcall
		if obj.OnTSMDBShutdown and not pcall(obj.OnTSMDBShutdown, nil, appDB) then
			-- the callback hit an error, so ensure the correct profile is restored
			TSM.db:SetProfile(originalProfile)
		end
	end
	-- ensure we're back on the correct profile
	TSM.db:SetProfile(originalProfile)
	TSM.Items:OnLogout()
end

function Modules:IsOperationIgnored(module, operationName)
	local obj = moduleObjects[module]
	local operation = obj.operations[operationName]
	if not operation then return end
	local factionrealm = UnitFactionGroup("player").." - "..GetRealmName()
	local playerKey = UnitName("player").." - "..factionrealm
	return operation.ignorePlayer[playerKey] or operation.ignoreFactionrealm[factionrealm]
end

function Modules:CheckOperationRelationships(moduleName)
	for _, operation in pairs(TSM.operations[moduleName]) do
		for key, target in pairs(operation.relationships or {}) do
			if not TSM.operations[moduleName][target] then
				operation.relationships[key] = nil
			end
		end
	end
end

function Modules:ChatCommand(input)
	local parts = { (" "):split(input) }
	local cmd, args = strlower(parts[1] or ""), table.concat(parts, " ", 2)

	if cmd == "" then
		TSM.MainFrame:Show()
		TSM.MainFrame:SelectIcon("TradeSkillMaster", L["TSM Features"])
	else
		local foundCmd
		for _, obj in pairs(moduleObjects) do
			if obj.slashCommands then
				for _, info in ipairs(obj.slashCommands) do
					if strlower(info.key) == cmd then
						info.callback(args)
						foundCmd = true
					end
				end
			end
		end
		-- If not a registered command, print out slash command help
		if not foundCmd then
			local chatFrame = TSMAPI:GetChatFrame()
			TSM:Print(L["Slash Commands:"])
			chatFrame:AddMessage("|cffffaa00" .. L["/tsm|r - opens the main TSM window."])
			chatFrame:AddMessage("|cffffaa00" .. L["/tsm help|r - Shows this help listing"])
			for _, name in ipairs(moduleNames) do
				for _, info in ipairs(moduleObjects[name].slashCommands or {}) do
					if not info.hidden then
						chatFrame:AddMessage("|cffffaa00/tsm " .. info.key .. "|r - " .. info.label)
					end
				end
			end
		end
	end
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

-- if the passed function is a string, will check if it's a method of the object and return a wrapper function
function private:GetFunction(obj, func)
	if type(func) == "string" then
		local part1, part2 = (":"):split(func)
		if part2 and obj[part1] and obj[part1][part2] then
			return function(...) return obj[part1][part2](obj[part1], ...) end
		elseif obj[part1] then
			return function(...) return obj[part1](obj, ...) end
		end
	end
	return func
end

-- validates a simple list of sub-tables which have the basic key/label/callback fields
function private:ValidateList(obj, val, keys)
	for i, v in ipairs(val) do
		if type(v) ~= "table" then
			return "invalid entry in list at index " .. i
		end
		for key, valType in pairs(keys) do
			if valType == "function" then
				v[key] = private:GetFunction(obj, v[key])
			end
			if type(v[key]) ~= valType then
				return format("expected %s type for field %s, got %s at index %d", valType, key, type(v[key]), i)
			end
		end
	end
end

function private:ValidateModuleObject(obj)
	-- make sure it's a table
	if type(obj) ~= "table" then
		return format("Expected table, got %s.", type(obj))
	end
	-- simple check that it's an AceAddon object which stores the name in .name and implements a .__tostring metamethod.
	if tostring(obj) ~= obj.name then
		return "Passed object is not an AceAddon-3.0 object."
	end

	-- validate all the fields
	for _, fieldInfo in ipairs(MODULE_FIELD_INFO) do
		local val = obj[fieldInfo.key]
		if val then
			-- make sure it's of the correct type
			if type(val) ~= fieldInfo.type then
				return format("For field '%s', expected type of %s, got %s.", fieldInfo.key, fieldInfo.type, type(val))
			end
			-- if there's required subfields, check them
			if fieldInfo.subFieldInfo then
				for key, valType in pairs(fieldInfo.subFieldInfo) do
					if valType == "function" then
						val[key] = private:GetFunction(obj, val[key])
					end
					if type(val[key]) ~= valType then
						return format("expected %s type for field %s, got %s", valType, key, type(val[key]))
					end
				end
			end
			-- if there's subTableInfo specified, run private:ValidateList on this field
			if fieldInfo.subTableInfo then
				local errMsg = private:ValidateList(obj, val, fieldInfo.subTableInfo)
				if errMsg then
					return format("Invalid value for '%s': %s.", fieldInfo.key, errMsg)
				end
			end
		end
	end
end

function private:VersionStrToInt(str)
	local gen, major, minor, beta = strmatch(str, "^v([0-9])%.([0-9]+)%.?([0-9]*)%.?([0-9]*)$")
	gen = tonumber(gen) or 0
	major = tonumber(major) or 0
	minor = tonumber(minor) or 0
	beta = tonumber(beta) or 0
	if gen ~= 3 then return end
	return gen * 1000000 + major * 10000 + minor * 100 + beta
end

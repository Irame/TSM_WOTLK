-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various settings APIs
local TSM = select(2, ...)
local Settings = TSM:NewModule("Settings", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {context={}, proxies={}, profileWarning=nil, protectedAccessAllowed={}}
local VALID_TYPES = {boolean=true, string=true, table=true, number=true}
local KEY_SEP = "@"
local GLOBAL_SCOPE_KEY = " "
local DEFAULT_PROFILE_NAME = "Default"
local SCOPE_TYPES = {
	global = "g",
	profile = "p",
	realm = "r",
	factionrealm = "f",
	char = "c",
}
local SCOPE_KEYS = {
	global = " ",
	profile = nil, -- set per-DB
	realm = GetRealmName(),
	factionrealm = UnitFactionGroup("player").." - "..GetRealmName(),
	char = UnitName("player").." - "..GetRealmName()
}
local DEFAULT_DB = {
	_version = -math.huge, -- DB version
	_currentProfile = {}, -- lookup table of the current profile name for different characters
	_hash = 0,
	_scopeKeys = {
		profile = {},
		realm = {},
		factionrealm = {},
		char = {},
	},
}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Settings:Init(svTableName, settingsInfo, upgradeCallback)
	if _G[svTableName] and _G[svTableName].profileKeys then
		-- this is an old AceDB table which we will convert to a SettingsDB
		-- create a new SettingsDB with default values and then go through and set any applicable values found in the old AceDB table
		local oldDB = _G[svTableName]
		_G[svTableName] = {}
		local newSettingsDB = private.SettingsDB(svTableName, settingsInfo)
		local context = private.context[newSettingsDB]

		-- create all the scopes
		for scopeType, scopeSettings in pairs(settingsInfo) do
			local oldDBSettings = nil
			if scopeType == "profile" then
				oldDBSettings = oldDB.profiles
			elseif scopeType == "global" then
				oldDBSettings = {[GLOBAL_SCOPE_KEY]=oldDB.global}
			elseif scopeType ~= "version" then
				oldDBSettings = oldDB[scopeType]
			end
			if oldDBSettings then
				for oldScopeKey, oldScopeSettings in pairs(oldDBSettings) do
					-- add this scope key to the list of scope keys and set all the settings to their default values
					if scopeType ~= "global" and not tContains(context.db._scopeKeys[scopeType], oldScopeKey) then
						tinsert(context.db._scopeKeys[scopeType], oldScopeKey)
						private:SetScopeDefaults(context.db, settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES[scopeType], TSMAPI.Util:StrEscape(oldScopeKey), ".+"))
					end
					-- go through all the new settings and if it existed in the old DB (as the same type), copy it over, else leave it as the default
					for settingKey, info in pairs(scopeSettings) do
						if type(oldScopeSettings[settingKey]) == info.type then
							if type(info.default) == "table" and next(info.default) then
								-- we need to preserve the default array members
								for key in pairs(info.default) do
									if oldScopeSettings[settingKey][key] ~= nil then
										context.db[strjoin(KEY_SEP, SCOPE_TYPES[scopeType], oldScopeKey, settingKey)][key] = oldScopeSettings[settingKey][key]
									end
								end
							else
								private:SetDBKeyValue(context.db, strjoin(KEY_SEP, SCOPE_TYPES[scopeType], oldScopeKey, settingKey), oldScopeSettings[settingKey])
							end
						end
					end
				end
			end
		end
		if not private.profileWarning then
			for character, profileName in pairs(oldDB.profileKeys) do
				if profileName ~= DEFAULT_PROFILE_NAME then
					TSM:Print(L["|cffff0000IMPORTANT:|r Your TSM profile has been reset to the 'Default' profile as part of a recent update. None of your settings have been lost, but on characters where you wish to use another profile, you'll need to manually change it back."])
					StaticPopupDialogs["TSMResetToDefaultProfile"] = {
						text = L["|cffff0000IMPORTANT:|r Your TSM profile has been reset to the 'Default' profile as part of a recent update. None of your settings have been lost, but on characters where you wish to use another profile, you'll need to manually change it back."],
						button1 = OKAY,
						timeout = 0,
					}
					TSMAPI.Util:ShowStaticPopupDialog("TSMResetToDefaultProfile")
					private.profileWarning = true
					break
				end
			end
		end
		return newSettingsDB
	else
		return private.SettingsDB(svTableName, settingsInfo, upgradeCallback)
	end
end



-- ============================================================================
-- Main SettingsDB class
-- ============================================================================

private.SettingsDB = setmetatable({}, {
	-- constructor
	__call = function(_, name, rawSettingsInfo, upgradeCallback)
		TSMAPI:Assert(type(name) == "string")
		TSMAPI:Assert(type(rawSettingsInfo) == "table")
		local version = rawSettingsInfo.version
		TSMAPI:Assert(type(version) == "number" and version >= 1)

		-- get (and create if necessary) the global table
		local db = _G[name]
		if not db then
			db = {}
			_G[name] = db
		end

		-- flatten and validate rawSettingsInfo and generate hash data
		local settingsInfo = CopyTable(rawSettingsInfo)
		local hashDataParts = {}
		for scope, scopeSettingsInfo in pairs(rawSettingsInfo) do
			if scope ~= "version" then
				TSMAPI:Assert(SCOPE_TYPES[scope], "Invalid scope: "..tostring(scope))
				for key, info in pairs(scopeSettingsInfo) do
					TSMAPI:Assert(type(key) == "string" and type(info) == "table", "Invalid type for key: "..tostring(key))
					TSMAPI:Assert(not strfind(key, KEY_SEP))
					for k, v in pairs(info) do
						if k == "type" then
							TSMAPI:Assert(VALID_TYPES[info.type], "Invalid type for key: "..key)
						elseif k == "default" then
							TSMAPI:Assert(v == nil or type(v) == info.type, "Invalid default for key: "..key)
							-- if the default is a table, it must not contain non-empty tables
							if type(v) == "table" then
								for k2, v2 in pairs(v) do
									TSMAPI:Assert(type(k2) == "string" or type(k2) == "number")
									TSMAPI:Assert(type(v2) ~= "table" or not next(v2), "Default has non-empty table attribute: "..k2)
								end
							end
						elseif k == "lastModifiedVersion" then
							TSMAPI:Assert(type(v) == "number" and v <= version, "Invalid lastModifiedVersion for key: "..key)
						else
							TSMAPI:Assert(false, "Unexpected key in settingsInfo for key: "..key)
						end
					end
					tinsert(hashDataParts, strjoin(",", key, scope, info.type, type(info.default) == "table" and "table" or tostring(info.default)))
				end
			end
		end
		sort(hashDataParts)

		-- reset the DB if it's not valid
		local hash = TSMAPI.Util:CalculateHash(table.concat(hashDataParts, ";"))
		local isValid = true
		local preUpgradeDB = nil
		if not next(db) then
			-- new DB
			isValid = false
		elseif not private:ValidateDB(db) then
			-- corrupted DB
			TSMAPI:Assert(GetAddOnMetadata("TradeSkillMaster", "version") ~= "@project-version@", "DB is not valid!")
			isValid = false
		elseif db._version == version and db._hash ~= hash then
			-- the hash didn't match
			TSMAPI:Assert(GetAddOnMetadata("TradeSkillMaster", "version") ~= "@project-version@", "Invalid settings hash! Did you forget to increase the version?")
			isValid = false
		elseif db._version > version then
			-- this is a downgrade
			TSMAPI:Assert(GetAddOnMetadata("TradeSkillMaster", "version") ~= "@project-version@", "Unexpected DB version! If you really want to downgrade, comment out this line (remember to uncomment before committing).")
			isValid = false
		end
		if not isValid then
			-- wipe the DB and start over
			wipe(db)
			for key, value in pairs(DEFAULT_DB) do
				db[key] = private:CopyData(value)
			end
		end
		db._hash = hash

		-- setup current scope keys and set defaults for new keys
		db._currentProfile[SCOPE_KEYS.char] = db._currentProfile[SCOPE_KEYS.char] or DEFAULT_PROFILE_NAME
		local currentScopeKeys = CopyTable(SCOPE_KEYS)
		currentScopeKeys.profile = db._currentProfile[SCOPE_KEYS.char]
		for scopeType, scopeKey in pairs(currentScopeKeys) do
			if scopeType ~= "global" and not tContains(db._scopeKeys[scopeType], scopeKey) then
				tinsert(db._scopeKeys[scopeType], scopeKey)
				private:SetScopeDefaults(db, settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES[scopeType], TSMAPI.Util:StrEscape(scopeKey), ".+"))
			end
		end

		-- do any necessary upgrading or downgrading if the version changed
		local removedKeys = {}
		if version ~= db._version then
			-- clear any settings which no longer exist, and set new/updated settings to their default values
			local processedKeys = {}
			for key, value in pairs(db) do
				-- ignore metadata (keys starting with "_")
				if strsub(key, 1, 1) ~= "_" then
					local scopeTypeShort, settingKey = strmatch(key, "^(.+)"..KEY_SEP..".+"..KEY_SEP.."(.+)$")
					local scopeType = private:ScopeReverseLookup(scopeTypeShort)
					TSMAPI:Assert(settingKey)
					local info = settingsInfo[scopeType] and settingsInfo[scopeType][settingKey]
					if not info then
						-- this setting was removed so remove it from the db
						removedKeys[key] = db[key]
						db[key] = nil
					elseif info.lastModifiedVersion > db._version or version < db._version then
						-- this setting was updated (or this is a downgrade) so reset it to its default value
						removedKeys[key] = db[key]
						db[key] = private:CopyData(info.default)
					end
					processedKeys[scopeType..KEY_SEP..settingKey] = true
				end
			end
			for scope, scopeInfo in pairs(settingsInfo) do
				if scope ~= "version" then
					for settingKey, info in pairs(scopeInfo) do
						if not processedKeys[scope..KEY_SEP..settingKey] and (info.lastModifiedVersion > db._version or version < db._version) then
							-- this is either a new setting or was changed and previously set to nil or this is a downgrade - either way set it to the default value
							private:SetScopeDefaults(db, settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES[scope], ".+", settingKey), removedKeys)
						end
					end
				end
			end
		end
		local oldVersion = db._version
		db._version = version

		-- make the db table protected
		setmetatable(db, {
			__newindex = function(self, key, value)
				TSMAPI:Assert(private.protectedAccessAllowed[self], "Attempting to modify a protected table", 3)
				rawset(self, key, value)
			end,
			__metatable = false
		})

		-- create the new object and return it
		local new = setmetatable({}, getmetatable(private.SettingsDB))
		private.context[new] = {db=db, settingsInfo=settingsInfo, currentScopeKeys=currentScopeKeys, callbacks={}, scopeProxies={}}
		for scopeType in pairs(rawSettingsInfo) do
			if scopeType ~= "version" then
				private.context[new].scopeProxies[scopeType] = private.SettingsDBScopeProxy(new, scopeType)
			end
		end

		-- if this is an upgrade, call the upgrade callback for each of the keys which were changed / removed
		if isValid and version > oldVersion and upgradeCallback then
			for key, oldValue in pairs(removedKeys) do
				local settingKey = strmatch(key, "^.+"..KEY_SEP..".+"..KEY_SEP.."(.+)$")
				upgradeCallback(new, settingKey, oldValue)
			end
		end
		return new, oldVersion
	end,

	-- getter
	__index = function(self, key)
		if private.SettingsDBMethods[key] then
			return private.SettingsDBMethods[key]
		elseif SCOPE_TYPES[key] then
			return private.context[self].scopeProxies[key]
		else
			TSMAPI:Assert(false, "Invalid scope: "..tostring(key), 1)
		end
	end,

	-- setter
	__newindex = function(self, key, value) TSMAPI:Assert(false, "You cannot set values in this table! You're probably missing a scope.", 1) end,
})



-- ============================================================================
-- SettingsDB Object Methods
-- ============================================================================

private.SettingsDBMethods = {
	RegisterCallback = function(self, event, callback)
		TSMAPI:Assert(event == "OnLogout" or event == "OnProfileUpdated")
		TSMAPI:Assert(type(callback) == "function")
		private.context[self].callbacks[event] = callback
	end,

	IsValidProfileName = function(self, name)
		return name ~= "" and not strfind(name, KEY_SEP)
	end,

	GetCurrentProfile = function(self)
		return private.context[self].currentScopeKeys.profile
	end,

	GetScopeKeys = function(self, scope)
		return CopyTable(private.context[self].db._scopeKeys[scope])
	end,

	GetProfiles = function(self)
		return self:GetScopeKeys("profile")
	end,

	SetProfile = function(self, profileName)
		TSMAPI:Assert(type(profileName) == "string", tostring(profileName))
		TSMAPI:Assert(not strfind(profileName, KEY_SEP))
		local context = private.context[self]

		-- change the current profile for this character
		context.db._currentProfile[SCOPE_KEYS.char] = profileName
		context.currentScopeKeys.profile = context.db._currentProfile[SCOPE_KEYS.char]

		local isNew = false
		if not tContains(context.db._scopeKeys.profile, profileName) then
			tinsert(context.db._scopeKeys.profile, profileName)
			-- this is a new profile, so set all the settings to their default values
			private:SetScopeDefaults(context.db, context.settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES.profile, TSMAPI.Util:StrEscape(profileName), ".+"))
			isNew = true
		end

		if context.callbacks.OnProfileUpdated then
			context.callbacks.OnProfileUpdated(isNew)
		end
	end,

	ResetProfile = function(self)
		local context = private.context[self]
		private:SetScopeDefaults(context.db, context.settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES.profile, TSMAPI.Util:StrEscape(context.currentScopeKeys.profile), ".+"))
		if context.callbacks.OnProfileUpdated then
			context.callbacks.OnProfileUpdated(true)
		end
	end,

	CopyProfile = function(self, sourceProfileName)
		TSMAPI:Assert(type(sourceProfileName) == "string")
		TSMAPI:Assert(not strfind(sourceProfileName, KEY_SEP))
		local context = private.context[self]
		TSMAPI:Assert(sourceProfileName ~= context.currentScopeKeys.profile)

		-- copy all the settings from the source profile to the current one
		for settingKey, info in pairs(context.settingsInfo.profile) do
			local srcKey = strjoin(KEY_SEP, SCOPE_TYPES.profile, sourceProfileName, settingKey)
			local destKey = strjoin(KEY_SEP, SCOPE_TYPES.profile, context.currentScopeKeys.profile, settingKey)
			private:SetDBKeyValue(context.db, destKey, private:CopyData(context.db[srcKey]))
		end

		if context.callbacks.OnProfileUpdated then
			context.callbacks.OnProfileUpdated(false)
		end
	end,

	DeleteScope = function(self, scopeType, scopeKey)
		TSMAPI:Assert(SCOPE_TYPES[scopeType])
		TSMAPI:Assert(type(scopeKey) == "string")
		local context = private.context[self]
		TSMAPI:Assert(scopeKey ~= context.currentScopeKeys[scopeType])

		-- remove all settings for the specified profile
		local searchPattern = strjoin(KEY_SEP, SCOPE_TYPES[scopeType], TSMAPI.Util:StrEscape(scopeKey), ".+")
		for key in pairs(context.db) do
			if strmatch(key, searchPattern) then
				private:SetDBKeyValue(context.db, key, nil)
			end
		end

		-- remove the scope key from the list
		for i=1, #context.db._scopeKeys[scopeType] do
			if context.db._scopeKeys[scopeType][i] == scopeKey then
				tremove(context.db._scopeKeys[scopeType], i)
				break
			end
		end
	end,

	DeleteProfile = function(self, profileName)
		self:DeleteScope("profile", profileName)
	end,

	GetConnectedRealmIterator = function(self, scope)
		TSMAPI:Assert(scope == "factionrealm" or scope == "realm")
		local faction = UnitFactionGroup("player")
		local realms = TSMAPI:GetConnectedRealms()
		local index = 0

		return function()
			while true do
				local realm = index == 0 and SCOPE_KEYS.realm or realms[index]
				if not realm then return end
				index = index + 1
				local scopeKey = (scope == "factionrealm") and (faction.." - "..realm) or realm
				if tContains(private.context[self].db._scopeKeys[scope], scopeKey) then
					return scopeKey, private.SettingsDBScopeProxy(self, scope, scopeKey)
				end
			end
		end
	end,
}



-- ============================================================================
-- Proxy Class for Scopes (TSM.db.XXXXX)
-- ============================================================================

private.SettingsDBScopeProxy = setmetatable({}, {
	-- constructor
	__call = function(_, settingsDB, scope, scopeKey)
		TSMAPI:Assert(private.context[settingsDB])
		local new = setmetatable({}, getmetatable(private.SettingsDBScopeProxy))
		private.proxies[new] = {settingsDB=settingsDB, scope=scope, scopeKey=scopeKey}
		return new
	end,

	-- getter
	__index = function(self, key)
		TSMAPI:Assert(type(key) == "string", "Invalid setting key type!", 1)
		local proxyInfo = private.proxies[self]
		local context = private.context[proxyInfo.settingsDB]
		TSMAPI:Assert(context.settingsInfo[proxyInfo.scope][key], "Setting does not exist!", 1)
		return context.db[strjoin(KEY_SEP, SCOPE_TYPES[proxyInfo.scope], proxyInfo.scopeKey or context.currentScopeKeys[proxyInfo.scope], key)]
	end,

	-- setter
	__newindex = function(self, key, value)
		TSMAPI:Assert(type(key) == "string", "Invalid setting key type!", 1)
		local proxyInfo = private.proxies[self]
		local context = private.context[proxyInfo.settingsDB]
		local info = context.settingsInfo[proxyInfo.scope][key]
		TSMAPI:Assert(info, "Setting does not exist!", 1)
		TSMAPI:Assert(value == nil or type(value) == info.type, "Value is of wrong type.", 1)
		private:SetDBKeyValue(context.db, strjoin(KEY_SEP, SCOPE_TYPES[proxyInfo.scope], proxyInfo.scopeKey or context.currentScopeKeys[proxyInfo.scope], key), value)
	end,
})



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:SetDBKeyValue(db, key, value)
	private.protectedAccessAllowed[db] = true
	db[key] = value
	private.protectedAccessAllowed[db] = nil
end

function private:CopyData(data)
	if type(data) == "table" then
		return CopyTable(data)
	elseif VALID_TYPES[type(data)] or type(data) == nil then
		return data
	end
end

function private:ScopeReverseLookup(scopeTypeShort)
	for key, value in pairs(SCOPE_TYPES) do
		if value == scopeTypeShort then
			return key
		end
	end
end

function private:ValidateDB(db)
	-- make sure the DB we are loading from is valid
	if #db > 0 then return end
	if type(db._version) ~= "number" then return end
	if type(db._hash) ~= "number" then return end
	if type(db._scopeKeys) ~= "table" then return end
	for scopeType, keys in pairs(db._scopeKeys) do
		if not SCOPE_TYPES[scopeType] then return end
		for i, name in pairs(keys) do
			if type(i) ~= "number" or i > #keys or i <= 0 or type(name) ~= "string" then return end
		end
	end
	if type(db._currentProfile) ~= "table" then return end
	for key, value in pairs(db._currentProfile) do
		if type(key) ~= "string" or type(value) ~= "string" then return end
	end
	return true
end

function private:SetScopeDefaults(db, settingsInfo, searchPattern, removedKeys)
	-- remove any existing entries for matching keys
	for key in pairs(db) do
		if strmatch(key, searchPattern) then
			if removedKeys then
				removedKeys[key] = db[key]
			end
			private:SetDBKeyValue(db, key, nil)
		end
	end

	local scopeTypeShort = strsub(searchPattern, 1, 1)
	local scopeType = private:ScopeReverseLookup(scopeTypeShort)
	TSMAPI:Assert(scopeType, "Couldn't find scopeType: "..tostring(scopeTypeShort))
	local scopeKeys = nil
	if scopeTypeShort == SCOPE_TYPES.global then
		scopeKeys = {GLOBAL_SCOPE_KEY}
	else
		scopeKeys = db._scopeKeys[scopeType]
		TSMAPI:Assert(scopeKeys, "Couldn't find scopeKeys for type: "..tostring(scopeTypeShort))
	end

	-- set any matching keys to their default values
	if not settingsInfo[scopeType] then return end
	for settingKey, info in pairs(settingsInfo[scopeType]) do
		for _, scopeKey in ipairs(scopeKeys) do
			local key = strjoin(KEY_SEP, scopeTypeShort, scopeKey, settingKey)
			if strmatch(key, searchPattern) then
				if removedKeys then
					removedKeys[key] = db[key]
				end
				private:SetDBKeyValue(db, key, private:CopyData(info.default))
			end
		end
	end
end

-- register a callback when the player is logging out (before the saved variables are written to disk)
LibStub("AceEvent-3.0"):RegisterEvent("PLAYER_LOGOUT", function()
	for _, context in pairs(private.context) do
		if context.callbacks.OnLogout then
			context.callbacks.OnLogout()
		end
	end
end)

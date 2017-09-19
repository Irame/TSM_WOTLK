-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains player / guild APIs

local TSM = select(2, ...)
local private = {}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Player:GetCharacters(currentAccountOnly)
	local characters = {}
	if currentAccountOnly then
		for name in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters) do
			characters[name] = true
		end
	else
		for name in pairs(TSM.db.factionrealm.characters) do
			characters[name] = true
		end
	end
	return characters
end

function TSMAPI.Player:GetGuilds(includeIgnored)
	local guilds = {}
	for name in pairs(TSM.db.factionrealm.guildVaults) do
		if includeIgnored or not TSM.db.factionrealm.ignoreGuilds[name] then
			guilds[name] = true
		end
	end
	return guilds
end

function TSMAPI.Player:GetPlayerGuild(player)
	return player and TSM.db.factionrealm.characterGuilds[player] or nil
end

function TSMAPI.Player:IsPlayer(target, includeAlts, includeOtherFaction, includeOtherAccounts)
	target = strlower(target)
	if not strfind(target, " %- ") then
		target = gsub(target, "%-", " - ", 1)
	end
	local player = strlower(UnitName("player"))
	local faction = strlower(UnitFactionGroup("player"))
	local realm = strlower(GetRealmName())
	local factionrealm = faction.." - "..realm
	
	if target == player then
		return true
	elseif strfind(target, " %- ") and target == (player.." - "..realm) then
		return true
	end
	if not strfind(target, " %- ") then
		target = target.." - "..realm
	end
	if includeAlts then
		local isConnectedRealm = {[realm]=true}
		for _, realmName in ipairs(TSMAPI:GetConnectedRealms()) do
			isConnectedRealm[strlower(realmName)] = true
		end
		for factionrealmKey, data in TSM.db:GetConnectedRealmIterator("factionrealm") do
			local factionKey, realmKey = strmatch(factionrealmKey, "(.+) %- (.+)")
			factionKey = strlower(factionKey)
			realmKey = strlower(realmKey)
			if (includeOtherFaction or factionKey == faction) and isConnectedRealm[realmKey] then
				for charKey in pairs(data.characters) do
					if includeOtherAccounts or not data.syncMetadata or not data.syncMetadata.TSM_CHARACTERS or (data.syncMetadata.TSM_CHARACTERS[charKey].owner == TSMAPI.Sync:GetAccountKey()) then
						if target == (strlower(charKey).." - "..realmKey) then
							return true
						end
					end
				end
			end
		end
	end
end
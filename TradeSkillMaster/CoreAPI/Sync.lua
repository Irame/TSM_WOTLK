-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file handled multi-account syncing and communication

-- register this file with Ace libraries
local TSM = select(2, ...)
local Sync = TSM:NewModule("Sync", "AceComm-3.0", "AceEvent-3.0")
TSMAPI.Sync = {}
local private = {addedFriends={}, invalidPlayers={}, connections={}, threadId=nil, syncTables={}, tagUpdateTimes={}, rpcFunctions={}, rpcSeqNum=0, pendingRPC={}, lastNewPlayerSend=0}
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local RECEIVE_TIMEOUT = 5
local HEARTBEAT_TIMEOUT = 10
local UPDATE_PERIOD = 15
local RPC_TIMEOUT = 5
-- NOTE: DATA_TYPES values should never change without increasing the SYNC_VERSION
local SYNC_VERSION = 1
local DATA_TYPES = {
	-- new connection types (40-49)
	WHOAMI_ACCOUNT = strchar(40),
	WHOAMI_ACK = strchar(41),
	-- connection status types (50-69)
	CONNECTION_REQUEST = strchar(50),
	CONNECTION_REQUEST_ACK = strchar(51),
	DISCONNECT = strchar(52),
	HEARTBEAT = strchar(53),
	-- data syncing types (70-99)
	LAST_UPDATE_TIME = strchar(70),
	LAST_UPDATE_REQUEST_VERBOSE = strchar(71),
	LAST_UPDATE_TIMES_VERBOSE = strchar(72),
	DATA_REQUEST = strchar(73),
	DATA_RESPONSE = strchar(74),
	DATA_ACK = strchar(75),
	-- RPC types (100-109)
	RPC_CALL = strchar(100),
	RPC_RETURN = strchar(101),
}
-- Load the libraries needed for Compress and Decompress functions
local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibCompress = LibStub:GetLibrary("LibCompress")
local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()
local LibCompressChatEncodeTable = LibCompress:GetAddonEncodeTable()



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Sync:GetStatus(tbl, key)
	local tag = private:GetTagByTable(tbl)
	TSMAPI:Assert(tag, "No tag found for table")
	TSMAPI:Assert(TSM.db.factionrealm.syncMetadata[tag], "No metadata found for tag")
	if not TSM.db.factionrealm.syncMetadata[tag][key] then return end
	local account = TSM.db.factionrealm.syncMetadata[tag][key].owner
	TSMAPI:Assert(account)
	local connectedPlayer = nil
	if account == TSMAPI.Sync:GetAccountKey() then
		connectedPlayer = UnitName("player")
	elseif private.connections[account] and private.connections[account].player then
		connectedPlayer = private.connections[account].player
	end
	return connectedPlayer, TSM.db.factionrealm.syncMetadata[tag][key].lastUpdate
end

function TSMAPI.Sync:GetAccountKey()
	return TSM.db.factionrealm.accountKey
end

function TSMAPI.Sync:Mirror(tbl, tag)
	TSMAPI:Assert(type(tbl) == "table" and type(tag) == "string")
	
	-- setup metadata if necessary
	TSM.db.factionrealm.syncMetadata[tag] = TSM.db.factionrealm.syncMetadata[tag] or {}
	for key in pairs(tbl) do
		if not TSM.db.factionrealm.syncMetadata[tag][key] then
			-- no metadata info, so assume we own it
			TSM.db.factionrealm.syncMetadata[tag][key] = {lastUpdate=time(), owner=TSMAPI.Sync:GetAccountKey()}
		end
	end
	
	private.syncTables[tag] = tbl
	private.tagUpdateTimes[tag] = time()
end

function TSMAPI.Sync:SetKeyValue(tbl, key, value)
	if tbl[key] == value then return end
	tbl[key] = value
	TSMAPI.Sync:KeyUpdated(tbl, key)
end

function TSMAPI.Sync:KeyUpdated(tbl, key)
	local tag = private:GetTagByTable(tbl)
	TSMAPI:Assert(tag, "No tag found for table")
	private.tagUpdateTimes[tag] = time()
	if not TSM.db.factionrealm.syncMetadata[tag][key] then
		TSM.db.factionrealm.syncMetadata[tag][key] = {owner=TSMAPI.Sync:GetAccountKey()}
	end
	TSMAPI:Assert(TSM.db.factionrealm.syncMetadata[tag][key].owner == TSMAPI.Sync:GetAccountKey())
	TSM.db.factionrealm.syncMetadata[tag][key].lastUpdate = time()
end

function TSMAPI.Sync:IsOwner(tbl, key, accountKey)
	accountKey = accountKey or TSMAPI.Sync:GetAccountKey()
	-- lookup the tag
	local tag = private:GetTagByTable(tbl)
	TSMAPI:Assert(tag, "No tag found for table")
	TSMAPI:Assert(TSM.db.factionrealm.syncMetadata[tag], "No metadata found")
	if not TSM.db.factionrealm.syncMetadata[tag][key] then return end
	return TSM.db.factionrealm.syncMetadata[tag][key].owner == accountKey
end

function TSMAPI.Sync:GetTableIter(tbl, account)
	account = account or TSMAPI.Sync:GetAccountKey()
	local keys = {}
	for key in pairs(tbl) do
		if TSMAPI.Sync:IsOwner(tbl, key, account) then
			tinsert(keys, key)
		end
	end

	local index = 0
	local iter
	return function()
		if index >= #keys then return end
		index = index + 1
		return keys[index], tbl[keys[index]]
	end
end

function TSMAPI.Sync:ClearMirror(tag)
	TSM.db.factionrealm.syncMetadata[tag] = nil
end

function TSMAPI.Sync:RegisterRPC(name, func)
	TSMAPI:Assert(name)
	private.rpcFunctions[name] = func
end

function TSMAPI.Sync:CallRPC(name, targetPlayer, handler, ...)
	TSMAPI:Assert(targetPlayer)
	TSMAPI:Assert(private.rpcFunctions[name], "Cannot call an RPC which is not also registered locally.")
	
	-- lookup the target account to validate that the targetPlayer is a character that
	-- we have syncing setup with and that they are online
	local account = TSM.db.factionrealm.syncMetadata[private:GetTagByTable(TSM.db.factionrealm.characters)][targetPlayer].owner
	TSMAPI:Assert(account)
	if targetPlayer ~= private:GetTargetPlayer(account) then return end
	
	private.rpcSeqNum = private.rpcSeqNum + 1
	private:SendData(DATA_TYPES.RPC_CALL, targetPlayer, {name=name, args={...}, seq=private.rpcSeqNum})
	private.pendingRPC[private.rpcSeqNum] = {name=name, handler=handler, sendTime=time()}
	return true
end

function TSMAPI.Sync:CancelRPC(name, handler)
	for seq, info in pairs(private.pendingRPC) do
		if info.name == name and info.handler == handler then
			private.pendingRPC[seq] = nil
			return
		end
	end
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Sync:OnEnable()
	Sync:RegisterComm("TSMSyncData")
	Sync:RegisterEvent("CHAT_MSG_SYSTEM")
	private.threadId = TSMAPI.Threading:Start(private.SyncThread, 0.5)
end

function Sync:OnCommReceived(_, data, _, source)
	private:ReceiveData(data, source)
end

function Sync:CHAT_MSG_SYSTEM(_, msg)
	if #private.addedFriends == 0 then return end
	if msg == ERR_FRIEND_NOT_FOUND then
		if #private.addedFriends > 0 then
			private.invalidPlayers[strlower(tremove(private.addedFriends, 1))] = true
		end
	else
		for i, v in ipairs(private.addedFriends) do
			if format(ERR_FRIEND_ADDED_S, v) == msg then
				tremove(private.addedFriends, i)
				private.invalidPlayers[strlower(v)] = true
			end
		end
	end
end

function Sync:DoSetup(targetPlayer, newSyncCallback)
	if strlower(targetPlayer) == strlower(UnitName("player")) then
		TSM:Print(L["Sync Setup Error: You entered the name of the current character and not the character on the other account."])
		return
	elseif not private:IsPlayerOnline(targetPlayer) then
		TSM:Print(L["Sync Setup Error: The specified player on the other account is not currently online."])
		return
	end
	for player in pairs(TSM.db.factionrealm.characters) do
		if strlower(player) == targetPlayer then
			TSM:Print(L["Sync Setup Error: This character is already part of a known account."])
			return
		end
	end
	private.newSyncCallback = newSyncCallback
	private.newPlayer = targetPlayer
	private.newAccount = nil
	private.newSyncAcked = nil
	return true
end

function Sync:RemoveSync(account)
	if private.connections[account] then
		TSMAPI.Threading:Kill(private.connections[account].threadId)
	end
	-- remove all data from the other account
	local toRemove = {}
	for tag, tagData in pairs(TSM.db.factionrealm.syncMetadata) do
		for key, info in pairs(tagData) do
			if info.owner == account then
				tinsert(toRemove, {tag=tag, key=key})
			end
		end
	end
	for _, info in ipairs(toRemove) do
		TSM.db.factionrealm.syncMetadata[info.tag][info.key] = nil
		if private.syncTables[info.tag] then
			private.syncTables[info.tag][info.key] = nil
		end
	end
	TSM.db.factionrealm.syncAccounts[account] = nil
end

function Sync:GetConnectionStatus(account)
	return private.connections[account] and private.connections[account].status or ("|cffff0000"..L["Offline"].."|r")
end



-- ============================================================================
-- Sync Threads
-- ============================================================================

function private.ConnectionThread(self, account)
	self:SetThreadName("SYNC_CONNECTION_"..account)
	local connectionInfo = private.connections[account]
	connectionInfo.status = "|cffff0000"..L["Offline"].."|r"
	
	-- wait for a target player to be online for the account
	local targetPlayer = nil
	while true do
		targetPlayer = private:GetTargetPlayer(account)
		if targetPlayer then
			break
		else
			self:Sleep(1)
		end
	end
	connectionInfo.status = format(L["Connecting to %s..."], targetPlayer)
	
	local isServer = account < TSMAPI.Sync:GetAccountKey() -- the lower account key is the server, other is the client
	if isServer then
		-- wait for connection request from the client
		if not private:WaitForMsgThread(self, DATA_TYPES.CONNECTION_REQUEST) then return end
		-- send an connection request ACK back to the client
		private:SendData(DATA_TYPES.CONNECTION_REQUEST_ACK, targetPlayer)
	else
		-- send a connection request to the server
		private:SendData(DATA_TYPES.CONNECTION_REQUEST, targetPlayer)
		-- wait for the connection request ACK
		if not private:WaitForMsgThread(self, DATA_TYPES.CONNECTION_REQUEST_ACK) then return end
	end
	
	-- now that we are connected, data can flow in both directions freely
	connectionInfo.status = format("|cff00ff00"..L["Connected to %s"].."|r", targetPlayer)
	connectionInfo.player = targetPlayer
	TSM:LOG_INFO("CONNECTED TO: %s %s", account, targetPlayer)
	self:RegisterEvent("PLAYER_LOGOUT", function() return private:SendData(DATA_TYPES.DISCONNECT, targetPlayer) end)
	local times = {lastHeartbeatSend=time(), lastHeartbeatReceive=time(), lastUpdateSend=0, lastUpdateDone=0, maxUpdateTimeSent=0}
	while true do
		-- check if they either logged off or the heartbeats have timed-out
		if not private:IsPlayerOnline(targetPlayer, true) or time() - times.lastHeartbeatReceive > HEARTBEAT_TIMEOUT then
			return
		end
		
		-- check if we should send out the last update time
		if next(private.syncTables) and time() - times.lastUpdateSend > 3 then
			local maxLastUpdateTime = 0
			for tag in pairs(private.syncTables) do
				for key, info in pairs(TSM.db.factionrealm.syncMetadata[tag]) do
					if info.owner == TSMAPI.Sync:GetAccountKey() then
						maxLastUpdateTime = max(maxLastUpdateTime, info.lastUpdate)
					end
				end
			end
			if maxLastUpdateTime > times.lastUpdateDone then
				times.maxUpdateTimeSent = maxLastUpdateTime
				private:SendData(DATA_TYPES.LAST_UPDATE_TIME, targetPlayer, tostring(maxLastUpdateTime))
				times.lastUpdateSend = time()
			end
		end
		
		-- check if we should send a heartbeat
		if time() - times.lastHeartbeatSend > floor(HEARTBEAT_TIMEOUT / 2) then
			private:SendData(DATA_TYPES.HEARTBEAT, targetPlayer)
			times.lastHeartbeatSend = time()
		end
		
		-- process any pending messages
		while self:GetNumMsgs() > 0 do
			local event, data = unpack(self:ReceiveMsg())
			if event == DATA_TYPES.HEARTBEAT then
				times.lastHeartbeatReceive = time()
			elseif event == DATA_TYPES.LAST_UPDATE_TIME then
				-- process last update times
				local maxLastUpdateTime = 0
				for tag in pairs(private.syncTables) do
					for key, info in pairs(TSM.db.factionrealm.syncMetadata[tag]) do
						if info.owner == account then
							maxLastUpdateTime = max(maxLastUpdateTime, info.lastUpdate)
						end
					end
				end
				if maxLastUpdateTime == tonumber(data) then
					private:SendData(DATA_TYPES.DATA_ACK, targetPlayer)
				else
					private:SendData(DATA_TYPES.LAST_UPDATE_REQUEST_VERBOSE, targetPlayer, tostring(maxLastUpdateTime))
				end
			elseif event == DATA_TYPES.LAST_UPDATE_REQUEST_VERBOSE then
				local maxLastUpdateTime = tonumber(data)
				local lastUpdateTimes = {}
				for tag in pairs(private.syncTables) do
					if private.tagUpdateTimes[tag] > times.lastUpdateDone then
						local tagUpdates = {}
						for key, info in pairs(TSM.db.factionrealm.syncMetadata[tag]) do
							if info.owner == TSMAPI.Sync:GetAccountKey() and info.lastUpdate > maxLastUpdateTime then
								tagUpdates[key] = info.lastUpdate
							end
						end
						if next(tagUpdates) then
							lastUpdateTimes[tag] = tagUpdates
						end
					end
				end
				if next(lastUpdateTimes) then
					private:SendData(DATA_TYPES.LAST_UPDATE_TIMES_VERBOSE, targetPlayer, lastUpdateTimes)
				end
			elseif event == DATA_TYPES.LAST_UPDATE_TIMES_VERBOSE then
				local dataRequest = {}
				for tag, info in pairs(data) do
					if private.syncTables[tag] then
						for key, lastUpdate in pairs(info) do
							if not TSM.db.factionrealm.syncMetadata[tag][key] or TSM.db.factionrealm.syncMetadata[tag][key].lastUpdate ~= lastUpdate then
								dataRequest[tag] = dataRequest[tag] or {}
								tinsert(dataRequest[tag], key)
							end
						end
					end
				end
				if next(dataRequest) then
					private:SendData(DATA_TYPES.DATA_REQUEST, targetPlayer, dataRequest)
				end
			elseif event == DATA_TYPES.DATA_REQUEST then
				-- process data request
				local dataResponse = {}
				for tag, info in pairs(data) do
					for _, key in ipairs(info) do
						dataResponse[tag] = dataResponse[tag] or {}
						dataResponse[tag][key] = {lastUpdate=TSM.db.factionrealm.syncMetadata[tag][key].lastUpdate, data=private.syncTables[tag][key]}
					end
				end
				if next(dataResponse) then
					private:SendData(DATA_TYPES.DATA_RESPONSE, targetPlayer, dataResponse)
				end
			elseif event == DATA_TYPES.DATA_RESPONSE then
				-- process data response
				for tag, tagInfo in pairs(data) do
					for key, info in pairs(tagInfo) do
						if not TSM.db.factionrealm.syncMetadata[tag][key] or TSM.db.factionrealm.syncMetadata[tag][key].lastUpdate ~= info.lastUpdate then
							TSM.db.factionrealm.syncMetadata[tag][key] = TSM.db.factionrealm.syncMetadata[tag][key] or {}
							TSM.db.factionrealm.syncMetadata[tag][key].lastUpdate = info.lastUpdate
							TSM.db.factionrealm.syncMetadata[tag][key].owner = account
							private.syncTables[tag][key] = info.data
							TSM:LOG_INFO("Completed sync for %s->%s", tag, key)
						end
					end
				end
				private:SendData(DATA_TYPES.DATA_ACK, targetPlayer)
			elseif event == DATA_TYPES.DATA_ACK then
				times.lastUpdateDone = times.maxUpdateTimeSent
			elseif event == DATA_TYPES.DISCONNECT then
				TSM:LOG_INFO("Disconnected from %s", targetPlayer)
				connectionInfo.status = "|cffff0000"..L["Offline"].."|r"
				self:Sleep(2) -- wait 2 seconds while they completely log out
				return
			else
				-- unexpected event so just return (and re-establish) after ensuring the other side will timeout
				if type(event) == "string" and #event == 1 then
					TSM:LOG_INFO("Unexpected event: %d", strbyte(event))
				else
					TSM:LOG_INFO("Unexpected event: %s", tostring(event))
				end
				return
			end
		end
		self:Yield(true)
	end
end

function private:NewAccountThread(self)
	if not private.newPlayer then return end
	-- send WHOAMI_ACCOUNT messages to the other account
	if time() - private.lastNewPlayerSend > 1 then
		if not private:IsPlayerOnline(private.newPlayer) then
			private.newPlayer = nil
			private.newAccount = nil
			private.newSyncCallback = nil
			private.newSyncAcked = nil
			TSM:LOG_ERR("New player went offline")
		else
			private:SendData(DATA_TYPES.WHOAMI_ACCOUNT, private.newPlayer)
			private.lastNewPlayerSend = time()
			TSM:LOG_INFO("SENT WHOAMI_ACCOUNT")
		end
	end
	while self:GetNumMsgs() > 0 do
		local args = self:ReceiveMsg()
		local event = tremove(args, 1)
		if event == DATA_TYPES.WHOAMI_ACCOUNT then
			-- got the account key of the new player
			private.newAccount = unpack(args)
			TSM:LOG_INFO("WHOAMI_ACCOUNT %s %s", private.newPlayer, private.newAccount)
			if private.newAccount then
				private:SendData(DATA_TYPES.WHOAMI_ACK, private.newPlayer)
			end
		elseif event == DATA_TYPES.WHOAMI_ACK then
			-- they ACK'd the WHOAMI so we are good to setup a connection
			TSM:LOG_INFO("WHOAMI_ACK %s", tostring(private.newAccount))
			private.newSyncAcked = true
		else
			error("Unexpected event: "..tostring(event))
		end
	end
	if private.newAccount and private.newSyncAcked then
		TSM.db.factionrealm.syncAccounts[private.newAccount] = true
		
		-- add the character to the list of characters on behalf of the other account
		local tag = TSMAPI:Assert(private:GetTagByTable(TSM.db.factionrealm.characters))
		TSMAPI:Assert(not TSM.db.factionrealm.syncMetadata[tag][private.newPlayer])
		TSM.db.factionrealm.syncMetadata[tag][private.newPlayer] = {owner=private.newAccount, lastUpdate=1}
		TSM.db.factionrealm.characters[private.newPlayer] = true
		
		if private.newSyncCallback then
			private.newSyncCallback()
		end
		private.newPlayer = nil
		private.newAccount = nil
		private.newSyncCallback = nil
		private.newSyncAcked = nil
	end
end

function private.SyncThread(self)
	self:SetThreadName("SYNC_MAIN")
	-- wait for friend info to populate
	ShowFriends()
	local retriesLeft = 600
	while true do
		local isValid = true
		for i=1, GetNumFriends() do
			if not GetFriendInfo(i) then
				isValid = false
				break
			end
		end
		if isValid then
			break
		elseif retriesLeft == 0 then
			TSMAPI:Assert(false, "Could not get friend list information.")
		else
			retriesLeft = retriesLeft - 1
			self:Sleep(0.1)
		end
	end
	
	-- continuously spawn connection threads with online players
	local localAccountKey = TSMAPI.Sync:GetAccountKey()
	while true do
		private:NewAccountThread(self)
		for account in pairs(TSM.db.factionrealm.syncAccounts) do
			if account == localAccountKey then
				private:ShowSVCopyError()
				wipe(private.connections)
				return
			end
			if private.connections[account] and not TSMAPI.Threading:IsValid(private.connections[account].threadId) then
				private.connections[account] = nil
			end
			if not private.connections[account] then
				local threadId = TSMAPI.Threading:Start(private.ConnectionThread, 0.5, function() TSM:LOG_INFO("CONNECTION DIED TO %s", account) private.connections[account] = nil end, account, self:GetThreadId())
				private.connections[account] = {threadId=threadId}
			end
		end
		for seq, info in pairs(private.pendingRPC) do
			if time() - info.sendTime > RPC_TIMEOUT then
				info.handler()
				private.pendingRPC[seq] = nil
			end
		end
		self:Sleep(0.1)
	end
end



-- ============================================================================
-- Send/Receive Functions
-- ============================================================================

function private:SendData(dataType, targetPlayer, data)
	TSMAPI:Assert(type(dataType) == "string" and #dataType == 1)
	local packet = {dt=dataType, sa=TSMAPI.Sync:GetAccountKey(), v=SYNC_VERSION, d=data}
	if not data then
		-- send a more compact version if there's no data
		packet = strjoin(";", dataType, TSMAPI.Sync:GetAccountKey(), UnitName("player"), SYNC_VERSION)
	end
	-- give heartbeats a higher priority
	local prio = dataType == DATA_TYPES.HEARTBEAT and "ALERT" or nil
	Sync:SendCommMessage("TSMSyncData", private:Compress(packet), "WHISPER", targetPlayer, prio)
end

function private:ReceiveData(packet, source)
	-- remove realm name from source
	source = ("-"):split(source)
	source = source:trim()
	
	-- decompress the packet
	packet = private:Decompress(packet)
	if not packet then return end
	
	-- validate the packet
	if type(packet) == "string" then
		-- if it's a string that means there was no data
		local dataType, sourceAccount, sourcePlayer, version = (";"):split(packet)
		packet = {dt=dataType, sa=sourceAccount, v=tonumber(version)}
	end
	if not packet.dt or not packet.sa or not packet.v then return end
	if packet.sa == TSMAPI.Sync:GetAccountKey() or TSMAPI.Sync:IsOwner(TSM.db.factionrealm.characters, source) then
		private:ShowSVCopyError()
		return
	end
	if packet.v ~= SYNC_VERSION then return end
	
	if packet.dt == DATA_TYPES.WHOAMI_ACCOUNT or packet.dt == DATA_TYPES.WHOAMI_ACK then
		-- we don't yet have a connection, so treat seperately
		if private.newPlayer and strlower(private.newPlayer) == strlower(source) then
			private.newPlayer = source -- get correct capatilization
			TSMAPI.Threading:SendMsg(private.threadId, {packet.dt, packet.sa})
		end
	elseif packet.dt == DATA_TYPES.RPC_CALL then
		-- this is an RPC call
		if type(packet.d.name) ~= "string" or not private.rpcFunctions[packet.d.name] or type(packet.d.args) ~= "table" then return end
		local result = {private.rpcFunctions[packet.d.name](unpack(packet.d.args))}
		private:SendData(DATA_TYPES.RPC_RETURN, source, {result=result, seq=packet.d.seq})
	elseif packet.dt == DATA_TYPES.RPC_RETURN then
		-- this is an RPC return, so call the completion handler
		if type(packet.d.seq) ~= "number" or not private.pendingRPC[packet.d.seq] or type(packet.d.result) ~= "table" then return end
		private.pendingRPC[packet.d.seq].handler(unpack(packet.d.result))
		private.pendingRPC[packet.d.seq] = nil
	else
		if not private.connections[packet.sa] or not private.connections[packet.sa].threadId then return end
		
		-- send the data to the connection thread
		TSMAPI.Threading:SendMsg(private.connections[packet.sa].threadId, {packet.dt, packet.d})
	end
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:ShowSVCopyError()
	if private.didShowSVError then return end
	private.didShowSVError = true
	TSM:ShowConfigError(L["It appears that you've manually copied your saved variables between accounts which will cause TSM's automatic sync'ing to not work. You'll need to undo this, and/or delete the TradeSkillMaster and TSM_Crafting saved variables files on both accounts (with WoW closed) in order to fix this."])
end

function private:GetTagByTable(tbl)
	-- lookup the tag for the passed tbl
	for tag, syncTbl in pairs(private.syncTables) do
		if syncTbl == tbl then
			return tag
		end
	end
end

function private:WaitForMsgThread(self, expectedMsg)
	local timeout = debugprofilestop() + RECEIVE_TIMEOUT * 1000 + random(0, 1000)
	while debugprofilestop() < timeout do
		if self:GetNumMsgs() > 0 then
			local args = self:ReceiveMsg()
			if args[1] == expectedMsg then return true end
		end
		self:Yield(true)
	end
end

function private:IsPlayerOnline(target, noAdd)
	for i=1, GetNumFriends() do
		local name, _, _, _, connected = GetFriendInfo(i)
		if name and strlower(name) == strlower(target) then
			return connected
		end
	end
	
	if not noAdd and not private.invalidPlayers[strlower(target)] and GetNumFriends() ~= 50 then
		-- add them as a friend
		AddFriend(target)
		tinsert(private.addedFriends, target)
		for i=1, GetNumFriends() do
			local name, _, _, _, connected = GetFriendInfo(i)
			if name and strlower(name) == strlower(target) then
				return connected
			end
		end
	end
end

function private:GetTargetPlayer(account)
	local targetPlayer = nil
	
	-- find the player to connect to without adding to the friends list
	for player in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters, account) do
		if private:IsPlayerOnline(player, true) then
			return player
		end
	end
	-- if we failed, try again with adding to friends list
	for player in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters, account) do
		if private:IsPlayerOnline(player) then
			return player
		end
	end
end



-- ============================================================================
-- Compress/Decompress
-- ============================================================================

function private:Compress(data, isChat)
	TSMAPI:Assert(type(data) == "table" or type(data) == "string", "Invalid parameter")
	local encodeTbl = isChat and LibCompressChatEncodeTable or LibCompressAddonEncodeTable
	
	-- We will compress using Huffman, LZW, and no compression separately, validate each one, and pick the shortest valid one.
	-- This is to deal with a bug in the compression code.
	local serialized = nil
	if type(data) == "table" then
		serialized = LibAceSerializer:Serialize(data)
	elseif type(data) == "string" then
		serialized = "\240"..data
	end
	local encodedData = {}
	encodedData[1] = encodeTbl:Encode(LibCompress:CompressHuffman(serialized))
	encodedData[2] = encodeTbl:Encode(LibCompress:CompressLZW(serialized))
	encodedData[3] = encodeTbl:Encode("\001"..serialized)
	
	-- verify each compresion and pick the shortest valid one
	local minIndex = -1
	local minLen = math.huge
	for i=3, 1, -1 do
		local test = LibCompress:Decompress(encodeTbl:Decode(encodedData[i]))
		if test and test == serialized and #encodedData[i] < minLen then
			minLen = #encodedData[i]
			minIndex = i
		end
	end
	
	TSMAPI:Assert(encodedData[minIndex], "Could not compress data")
	return encodedData[minIndex]
end

function private:Decompress(data, isChat)
	local encodeTbl = isChat and LibCompressChatEncodeTable or LibCompressAddonEncodeTable
	-- Decode
	data = encodeTbl:Decode(data)
	if not data then return end
	-- Decompress
	data = LibCompress:Decompress(data)
	if not data then return end
	if type(data) == "string" and strsub(data, 1, 1) == "\240" then
		-- original data was a string, so we're done
		return strsub(data, 2)
	end
	-- Deserialize
	local success
	success, data = LibAceSerializer:Deserialize(data)
	if not success or not data then return end
	return data
end
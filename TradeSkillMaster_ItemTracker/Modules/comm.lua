-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeSkillMaster_itemtracker.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Comm = TSM:NewModule("Comm", "AceComm-3.0", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ItemTracker") -- loads the localization table
local LibCompress = LibStub("LibCompress")

Comm.invalidSenders = {}
local compressTable = LibCompress:GetAddonEncodeTable()

function Comm:OnEnable()
	Comm:RegisterComm("TSMITEM_DATA")
end

function Comm:DoSync()
	local friends = {}
	
	-- add people to friends list who aren't already
	for i=1, GetNumFriends() do
		if GetFriendInfo(i) then
			friends[strlower(GetFriendInfo(i))] = i
		end
	end
	for name in pairs(TSM.db.factionrealm.charactersToSync) do
		if not friends[name] then
			if GetNumFriends() == 50 then
				TSM:Printf(L["Could not sync with %s since they are not on your friends list and you friends list is full."], name)
			else
				AddFriend(name)
			end
		end
	end
	
	-- do syncing
	friends = {}
	for i=1, GetNumFriends() do
		local name, _, _, _, isOnline = GetFriendInfo(i)
		if name then
			friends[strlower(name)] = isOnline
		end
	end
	for name in pairs(TSM.db.factionrealm.charactersToSync) do
		if friends[name] then
			Comm:SendInventoryData(name, true)
		end
	end
end

function Comm:SendInventoryData(target, shouldReturnData)
	local data = {TSM.characters, TSM.guilds, shouldReturnData}
	local msg = Comm:Serialize(data)
	local compressedMsg = LibCompress:Compress(msg)
	local encodedMsg = compressTable:Encode(compressedMsg)
	
	local function UpdateProgress(_, done, total)
		if done == total then
			TSM:Printf(L["Sending data to %s complete!"], target)
		end
	end
	
	TSM:Printf(L["Compressing and sending ItemTracker data to %s. This will take approximately %s seconds. Please wait..."], target, ceil(#encodedMsg/900))
	Comm:SendCommMessage("TSMITEM_DATA", encodedMsg, "WHISPER", target, nil, UpdateProgress)
end

function Comm:OnCommReceived(_, msg, _, sender)
	sender = strlower(sender)
	local serializedMsg = LibCompress:Decompress(compressTable:Decode(msg))
	local isValid, data = Comm:Deserialize(serializedMsg)
	
	if Comm.invalidSenders[sender] then
		return
	elseif not TSM.db.factionrealm.charactersToSync[sender] then
		TSM:Printf(L["Ignored ItemTracker data from %s since you haven't added him to the list of characters in this character's ItemTracker options. You'll only see this message once per session per sender."], sender)
		Comm.invalidSenders[sender] = true
		return
	end
	
	
	if isValid then
		local numChars, numGuilds = 0, 0
		for name, characterData in pairs(data[1]) do
			TSM.characters[name] = CopyTable(characterData)
			numChars = numChars + 1
		end
		
		for name, guildData in pairs(data[2]) do
			TSM.guilds[name] = CopyTable(guildData)
			numGuilds = numGuilds + 1
		end
		TSM:Printf(L["Successfully got %s bytes of ItemTracker data from %s! Updated %s characters and %s guilds."], #serializedMsg, sender, numChars, numGuilds)
	
		if data[3] then
			Comm:SendInventoryData(sender)
		end
	else
		TSM:Printf(L["Got invalid ItemTracker data from %s."], sender)
	end
end
-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Comm = TSM:NewModule("Comm", "AceComm-3.0", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local LibCompress = LibStub("LibCompress") -- GetAddonEncodeTable

Comm.invalidSenders = {}
local compressTable = LibCompress:GetAddonEncodeTable()

function Comm:OnEnable()
	Comm:RegisterComm("TSMCRAFT_DATA")
end

function Comm:OnCommReceived(_, msg, _, sender)
	if not TSM.db.profile.craftingCostSources[strlower(sender)] then
		if not Comm.invalidSenders[sender] then
			Comm.invalidSenders[sender] = true
			TSM:Print(L["Ignored crafting cost data from %s since he is not on your list. You will only see this message once per session for this player."])
		end
		return
	end

	local serializedMsg = LibCompress:Decompress(compressTable:Decode(msg))
	local isValid, data = Comm:Deserialize(serializedMsg)
	
	if isValid then
		TSM:Printf(L["Successfully got %s bytes of crafting cost data from %s!"], #serializedMsg, sender)
		TSM.db.global.crossAccountCraftingCosts = data
	else
		TSM:Printf(L["Got invalid crafting cost data from %s."], sender)
	end
end

function Comm:SendCraftingCostData(target)
	if not target or target == "" or strlower(target) == strlower(UnitName("Player")) then
		TSM:Printf(L["Invalid target player \"%s\"."], target)
		return
	end

	local costData = {}
	for _, data in ipairs(TSM.tradeSkills) do
		local mode = data.name
		for itemID in pairs(TSM.Data[mode].crafts) do
			costData[itemID] = TSM.Data:GetCraftCost(itemID, mode)
		end
	end

	local msg = Comm:Serialize(costData)
	local compressedMsg = LibCompress:Compress(msg)
	local encodedMsg = compressTable:Encode(compressedMsg)
	
	local function UpdateProgress(_, done, total)
		if done == total then
			TSM:Printf(L["Sending data to %s complete!"], target)
		end
	end
	
	TSM:Printf(L["Compressing and sending %s bytes of data to %s. This will take approximately %s seconds. Please wait..."], #msg, target, ceil(#encodedMsg/900))
	Comm:SendCommMessage("TSMCRAFT_DATA", encodedMsg, "WHISPER", target, nil, UpdateProgress)
end
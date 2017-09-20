-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_AuctionDB                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_auctiondb           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Compress = TSM:NewModule("Compress")


local REALM_SAVE_KEYS = {"itemString", "numAuctions", "minBuyout", "marketValue", "lastScan", "historical"}
local REGION_SAVE_KEYS = {"itemString", "regionMarketValue", "regionMinBuyout", "regionSale", "regionHistorical"}
local ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_="
local BASE = #ALPHA
local ENCODE_TABLE = {}
local DECODE_TABLE = {}
for i=1, BASE do
	local char = strsub(ALPHA, i, i)
	tinsert(ENCODE_TABLE, char)
	DECODE_TABLE[strbyte(char)] = i - 1
end

local function DecodeInt(h)
	if h == "~" then return end
	local decodeTbl = DECODE_TABLE -- local reference
	local result = 0
	for i=1, #h do
		result = result * BASE + decodeTbl[strbyte(h, i)]
	end
	return result
end

local function EncodeInt(d)
	if not d or not (d >= 0) then return "~" end -- this cannot be simplified since 0/0 is neither less than nor greater than any number
	local result = ""
	local diff = 1
	while diff > 0 do
		local r = d % BASE
		diff = d - r
		result = ENCODE_TABLE[r+1]..result
		d = diff / BASE
	end
	return result
end

local function EncodeIntFromStr(d)
	d = tonumber(d)
	return EncodeInt(tonumber(d))
end

local function EncodeScanData(rawData, keys, saveTime)
	if not rawData then return end
	local parts = {}
	for itemString, data in pairs(rawData) do
		local subParts = {}
		for _, key in ipairs(keys) do
			if key == "itemString" then
				local itemId = strmatch(itemString, "^i:([0-9]+)$")
				if itemId then
					tinsert(subParts, EncodeInt(tonumber(itemId)))
				else
					tinsert(subParts, strsub(itemString, 1, 1)..gsub(strsub(itemString, 2), "([0-9]+)", EncodeIntFromStr))
				end
			elseif key == "lastScan" then
				tinsert(subParts, EncodeInt(saveTime-data[key]))
			else
				tinsert(subParts, EncodeInt(data[key]))
			end
		end
		tinsert(parts, table.concat(subParts, "/"))
	end
	return table.concat(parts, ","), saveTime
end

local function DecodeScanData(rawData, keys, saveTime)
	if not rawData or rawData == "" then return end
	local result = {}
	for _, part in ipairs(TSMAPI.Util:SafeStrSplit(rawData, ",")) do
		local temp = {}
		local itemString = nil
		for i, subPart in ipairs({("/"):split(part)}) do
			local key = keys[i]
			if key == "itemString" then
				if not strmatch(subPart, ":") then
					itemString = "i:"..DecodeInt(subPart)
				else
					itemString = strsub(subPart, 1, 1)..gsub(strsub(subPart, 2), "([0-9a-zA-Z_=]+)", DecodeInt)
				end
			elseif key == "lastScan" then
				temp[key] = saveTime - DecodeInt(subPart)
			else
				temp[key] = DecodeInt(subPart)
			end
		end
		result[itemString] = temp
	end
	return result
end

function Compress:SaveRealmData()
	if not TSM.updatedRealmData or not TSM.realmData then return end
	TSM.db.realm.lastSaveTime = time()
	TSM.db.realm.scanData = EncodeScanData(TSM.realmData, REALM_SAVE_KEYS, TSM.db.realm.lastSaveTime)
end

function Compress:LoadRealmData()
	if not TSM.db.realm.lastSaveTime or TSM.db.realm.lastSaveTime == 0 or TSM.db.realm.lastSaveTime > time() then
		TSM.realmData = {}
	else
		TSM.realmData = DecodeScanData(TSM.db.realm.scanData, REALM_SAVE_KEYS, TSM.db.realm.lastSaveTime)
	end
	-- if we weren't able to decode, just clear the scan data
	if type(TSM.realmData) ~= "table" then
		TSM.realmData = {}
	end
end

function Compress:SaveRegionDataUS()
	if TSM.updatedRegionDataUS and TSM.regionDataUS then
		TSM.db.global.scanDataUS = EncodeScanData(TSM.regionDataUS, REGION_SAVE_KEYS)
	end
end

function Compress:SaveRegionDataEU()
	if TSM.updatedRegionDataEU and TSM.regionDataEU then
		TSM.db.global.scanDataEU = EncodeScanData(TSM.regionDataEU, REGION_SAVE_KEYS)
	end
end

function Compress:LoadRegionDataUS()
	TSM.regionDataUS = DecodeScanData(TSM.db.global.scanDataUS, REGION_SAVE_KEYS)
	-- if we weren't able to decode, just clear the scan data
	if type(TSM.regionDataUS) ~= "table" then
		TSM.regionDataUS = {}
	end
end

function Compress:LoadRegionDataEU()
	TSM.regionDataEU = DecodeScanData(TSM.db.global.scanDataEU, REGION_SAVE_KEYS)
	-- if we weren't able to decode, just clear the scan data
	if type(TSM.regionDataEU) ~= "table" then
		TSM.regionDataEU = {}
	end
end
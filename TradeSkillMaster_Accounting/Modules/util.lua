local TSM = select(2, ...)
local Util = TSM:NewModule("Util")

local qualityColors = {
	[0]="9d9d9d",
	[1]="ffffff",
	[2]="1eff00",
	[3]="0070dd",
	[4]="a335ee",
	[5]="ff8000",
	[6]="e6cc80",
}




local alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_="
local base = #alpha
local function decode(h)
	if strfind(h, "~") then return end
	local result = 0
	
	local i = #h - 1
	for w in string.gmatch(h, "([A-Za-z0-9_=])") do
		result = result + (strfind(alpha, w)-1)*(base^i)
		i = i - 1
	end
	
	return result
end

local function encode(d)
	local r = d % base
	local result
	if d-r == 0 then
		result = strsub(alpha, r+1, r+1)
	else 
		result = encode((d-r)/base) .. strsub(alpha, r+1, r+1)
	end
	return result
end

local function EncodeItemString(itemString)
	local _, itemID, _, _, _, _, _, suffixID = (":"):split(itemString)
	itemID, suffixID = tonumber(itemID), tonumber(suffixID)
	result = encode(itemID)
	if suffixID > 0 then
		result = result..":"..encode(suffixID)
	elseif suffixID < 0 then
		result = result..":-"..encode(abs(suffixID))
	end
	return result
end

local function DecodeItemString(itemCode)
	local itemID, suffixID = (":"):split(itemCode)
	local itemString
	if suffixID then
		local num
		suffixID, num = gsub(suffixID, "-", "")
		if num > 0 then
			itemString = "item:"..decode(itemID)..":0:0:0:0:0:-"..decode(suffixID)
		else
			itemString = "item:"..decode(itemID)..":0:0:0:0:0:"..decode(suffixID)
		end
	else
		itemString = "item:"..decode(itemID)..":0:0:0:0:0:0"
	end
	
	return itemString
end

local function EncodeItemLink(link) --"|cff1eff00|Hitem:36926:0:0:0:0:0:0:1173889664:80:0|h[Shadow Crystal]|h|r"
	link = link:trim()
	link = gsub(link, "|cff", "") -- "1eff00|Hitem:36926:0:0:0:0:0:0:1173889664:80:0|h[Shadow Crystal]|h|r"
	link = gsub(link, "|H", "|") -- "1eff00|item:36926:0:0:0:0:0:0:1173889664:80:0|h[Shadow Crystal]|h|r"
	link = gsub(link, "|h|r", "") -- "1eff00|item:36926:0:0:0:0:0:0:1173889664:80:0|h[Shadow Crystal]"
	link = gsub(link, "|h", "|") -- "1eff00|item:36926:0:0:0:0:0:0:1173889664:80:0|[Shadow Crystal]"
	link = gsub(link, "%[", "") -- "1eff00|item:36926:0:0:0:0:0:0:1173889664:80:0|Shadow Crystal]"
	link = gsub(link, "%]", "") -- "1eff00|item:36926:0:0:0:0:0:0:1173889664:80:0|Shadow Crystal"
	
	local colorHex, itemString, itemName = ("|"):split(link) -- "1eff00", "item:36926:0:0:0:0:0:0:1173889664:80:0", "Shadow Crystal"
	if not (colorHex and itemString and itemName) then return end
	local quality = ""
	for i, c in pairs(qualityColors) do
		if c == colorHex then
			quality = i
			break
		end
	end
	return quality.."|"..EncodeItemString(itemString).."|"..itemName
end

local function DecodeItemLink(link)
	local colorCode, itemCode, name = ("|"):split(link)
	local color = qualityColors[tonumber(colorCode) or 0] or qualityColors[0]
	if not (colorCode and itemCode and name) then return end
	return "|cff"..color.."|H"..DecodeItemString(itemCode).."|h["..name.."]|h|r", DecodeItemString(itemCode)
end

local function EncodeRecord(record, dType)
	local otherPerson = record[dType == "sold" and "buyer" or "seller"] or ""
	return encode(record.stackSize).."#"..encode(record.quantity).."#"..encode(floor(record.time)).."#"..encode(record.price).."#"..otherPerson.."#"..(record.player or "")
end

local function DecodeRecord(record, dType)
	local stackSize, quantity, sTime, price, otherPerson, player = ("#"):split(record)
	if not otherPerson then return end
	local result = {}
	result.stackSize = tonumber(decode(stackSize))
	result.quantity = tonumber(decode(quantity))
	result.time = tonumber(decode(sTime))
	result.price = tonumber(decode(price))
	result[dType == "sold" and "buyer" or "seller"] = otherPerson ~= "x" and otherPerson
	result.player = player ~= "x" and player
	return result
end

-- dataType should be "sold" or "buy"
function Util:EncodeItemData(dataType, itemString, data)
	data.link = data.link or select(2, GetItemInfo(itemString))
	local link = data.link and EncodeItemLink(data.link) or ("x"..EncodeItemString(itemString))
		
	local records = {}
	for _, record in ipairs(data.records) do
		tinsert(records, EncodeRecord(record, dataType))
	end
	return link.."!"..table.concat(records, "@")
end

function Util:DecodeItemData(dataType, itemData)
	-- check if itemData is an itemString
	if dataType == "sold" and TSM.soldData[itemData] then
		itemData = TSM.soldData[itemData]
	elseif dataType == "buy" and TSM.buyData[itemData] then
		itemData = TSM.buyData[itemData]
	end
	
	local encodedLink, encodedRecords = ("!"):split(itemData)
	local itemLink, itemString
	local records = {}
	if encodedLink and encodedRecords then
		if strsub(encodedLink, 1, 1) == "x" then
			itemString = DecodeItemString(strsub(encodedLink, 2))
		else
			itemLink, itemString = DecodeItemLink(encodedLink)
		end
		if itemString and encodedRecords then
			for i, record in ipairs({("@"):split(encodedRecords)}) do
				local decodedData = DecodeRecord(record, dataType)
				if decodedData then
					tinsert(records, decodedData)
				end
			end
			return itemString, records, itemLink
		end
	end
end

function Util:GetRecords(dataType, itemString)
	if not TSM[dataType.."Data"] or not TSM[dataType.."Data"][itemString] then return end
	
	local _, records = Util:DecodeItemData(dataType, itemString)
	return records
end

local hasLink = {}
function Util:UpdateLink(dataType, itemString)
	if hasLink[itemString] then return end
	local link = select(2, GetItemInfo(itemString))
	if not link then return end
	hasLink[itemString] = link
	
	local records = Util:GetRecords(dataType, itemString)
	if not records then return end
	
	TSM[dataType.."Data"][itemString] = Util:EncodeItemData(dataType, itemString, {records=records, link=link})
end


-- old method of uncompressing data
function Util:OldDeserialize()
	TSM.soldData = {}
	TSM.buyData = {}
	
	local errorNum = 0
	if TSM.db.factionrealm.sellDataRope then
		for _, itemData in ipairs({("?"):split(TSM.db.factionrealm.sellDataRope)}) do
			local itemString, records, itemLink = Util:DecodeItemData("sold", itemData)
			if itemString then
				TSM.soldData[itemString] = {records=records, link=itemLink}
			end
		end
	end
	
	if TSM.db.factionrealm.buyDataRope then
		for _, itemData in ipairs({("?"):split(TSM.db.factionrealm.buyDataRope)}) do
			local itemString, records, itemLink = Util:DecodeItemData("sold", itemData)
			if itemString then
				TSM.buyData[itemString] = {records=records, link=itemLink}
			end
		end
	end
end
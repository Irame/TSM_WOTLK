-- ************************************************************************** --
-- stuff for dealing with importing / exporting
-- ************************************************************************** --

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning")

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

local function areEquiv(itemString, itemID)
	local temp = itemString
	temp = gsub(temp, itemID, "@")
	temp = gsub(temp, ":", "")
	temp = gsub(temp, "0", "")
	temp = gsub(temp, "item", "")
	temp = gsub(temp, "@", itemID)
	return tonumber(temp) == itemID
end

local eVersion = 1
local settings = {dr="postTime", fb="fallback", pa="perAuction", pc="postCap",
	nc="noCancel", pi="perAuctionIsCap", uc="undercut",
	so="ignoreStacksOver", su="ignoreStacksUnder", th="threshold", fc="fallbackCap",
	bp="bidPercent", md="minDuration", rt="reset", rp="resetPrice", ii="itemIDGroups"}
local isNumber = {uc=true, dr=true, fb=true, pa=true, pc=true, so=true, su=true,
	th=true, fc=true, bp=true, md=true, rp=true}
local isBool = {nc=true, pi=true, ii=true}
local isString = {rt=true}
local encodeReset = {none="n", threshold="t", fallback="f", custom="c"}
local decodeReset = {n="none", t="threshold", f="fallback", c="custom"}
local ignored = {pt=true}
	
function TSM:Encode(groupName)
	if not TSM.db.profile.groups[groupName] then return "invalid name" end
	TSM:UpdateItemReverseLookup()
	TSM:UpdateGroupReverseLookup()
	
	local tItem
	local rope = "<vr"..encode(eVersion)..">"
	for itemString in pairs(TSM.db.profile.groups[groupName]) do
		tItem = itemString
		local itemID = TSMAPI:GetItemID(itemString)
		if type(itemString) == "number" or areEquiv(itemString, itemID) then
			rope = rope .. encode(itemID or itemString)
		else
			rope = rope .. encode(itemID)
			
			local temp = itemString
			temp = gsub(temp, "item:"..itemID..":", "")
			local nums = {(":"):split(temp)}
			for i,v in ipairs(nums) do
				if tonumber(v) < 0 then
					rope = rope .. ":!" .. encode(abs(v))
				else
					rope = rope .. ":" .. encode(v)
				end
			end
			
			rope = rope .. "|"
		end
	end
	
	for code, name in pairs(settings) do
		local settingString
		if code == "ii" then
			settingString = TSM.db.profile.itemIDGroups[groupName] and "1" or "0"
		elseif isBool[code] then
			settingString = TSM.Config:GetBoolConfigValue(tItem, name) and "1" or "0"
		elseif isString[code] then
			settingString = encodeReset[TSM.Config:GetConfigValue(tItem, name)]
		elseif isNumber[code] then
			settingString = encode(tonumber(TSM.Config:GetConfigValue(tItem, name)))
		else
			error("Invalid Code: ("..code..", "..name..")")
		end
	
		rope = rope .. "<" .. code .. settingString .. ">"
	end
	
	rope = rope .. "<en>" -- end marker
	return rope
end

function TSM:Decode(rope)
	local info = {items={}, itemIDs={}}
	local valid = true
	local finished = false
	
	rope = gsub(rope, " ", "")
	
	-- special word decoding (for version / other info)
	local function specialWord(c, word)
		if not (c and word) then valid = false end
		if c == "vr" then
			info.version = tonumber(decode(word))
		elseif settings[c] then
			if isNumber[c] then
				info[settings[c]] = tonumber(decode(word))
			elseif isBool[c] then
				info[settings[c]] = word == "1" and true
			elseif isString[c] then
				info[settings[c]] = decodeReset[word]
			else
				valid = false
			end
		elseif c == "en" then
			finished = true
		elseif not ignored[c] then
			valid = false
		end
	end
	
	-- itemString decoding
	local function decodeItemString(word)
		local itemString = "item"
		for _, w in pairs({(":"):split(word)}) do
			if strsub(w, 1, 1) == "!" then
				itemString = itemString .. ":-" .. decode(strsub(w, 2))
			else
				itemString = itemString .. ":" .. decode(w)
			end
		end
		
		return itemString
	end

	local len = #rope
	local n = 1

	-- go through the rope and decode it!
	while(n <= len) do
		local c = strsub(rope, n, n)
		if c == "<" then -- special word start flag
			local e = strfind(rope, ">", n)
			specialWord(strsub(rope, n+1, n+2), strsub(rope, n+3, e-1))
			n = e + 1
		elseif strsub(rope, n+3, n+3) == ":" then -- itemString start flag
			local e = strfind(rope, "|", n)
			local itemString = decodeItemString(strsub(rope, n, e-1))
			if not itemString then valid = false break end
			tinsert(info.items, itemString)
			n = e + 1
		elseif strsub(rope, n, n) ~= "@" then -- read the next 3 chars as an itemID
			local itemID = tonumber(decode(strsub(rope, n, n+2)))
			if not itemID then valid = false break end
			tinsert(info.itemIDs, itemID)
			tinsert(info.items, "item:"..itemID..":0:0:0:0:0:0")
			n = n + 3
		else -- we have read all the items and have moved onto the options
			n = n + 1
		end
	end
	
	if info.itemIDGroups then
		info.items = info.itemIDs
	end
	info.itemIDs = nil
	
	-- make sure the data is valid before returning it
	return valid and finished and info
end

function TSM:OpenImportFrame()
	local groupName, groupData
	local excludeExisting = true

	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TSM_Auctioning - "..L["Import Group Data"])
	f:SetLayout("Flow")
	f:SetHeight(200)
	f:SetHeight(300)
	
	local eb = AceGUI:Create("TSMEditBox")
	eb:SetLabel(L["Group name"])
	eb:SetRelativeWidth(0.5)
	eb:SetCallback("OnEnterPressed", function(_,_,value) groupName = strlower(value:trim()) end)
	f:AddChild(eb)
	
	local cb = AceGUI:Create("TSMCheckBox")
	cb:SetValue(excludeExisting)
	cb:SetLabel(L["Don't Import Already Grouped Items"])
	cb:SetRelativeWidth(0.5)
	cb:SetCallback("OnValueChanged", function(_,_,value) excludeExisting = value end)
	f:AddChild(cb)
	
	local spacer = AceGUI:Create("Label")
	spacer:SetFullWidth(true)
	spacer:SetText(" ")
	f:AddChild(spacer)
	
	local btn = AceGUI:Create("TSMButton")
	
	local eb = AceGUI:Create("MultiLineEditBox")
	eb:SetLabel(L["Group Data"])
	eb:SetFullWidth(true)
	eb:SetMaxLetters(0)
	eb:SetCallback("OnEnterPressed", function(_,_,data) btn:SetDisabled(false) groupData = data end)
	f:AddChild(eb)
	
	btn:SetDisabled(true)
	btn:SetText(L["Import Auctioning Group"])
	btn:SetFullWidth(true)
	btn:SetCallback("OnClick", function()
			local importData = TSM:Decode(groupData)
			if not importData then
				TSM:Print(L["The data you are trying to import is invalid."])
				return
			end
			
			if not groupName or TSM.db.profile.groups[groupName] or TSM.db.profile.categories[groupName] then
				groupName = groupName or "imported group"
				for i=1, 10000 do
					if not TSM.db.profile.groups[groupName..i] and not TSM.db.profile.categories[groupName..i] then
						groupName = groupName .. i
						break
					end
				end
			end
			
			TSM.db.profile.groups[groupName] = {}
			TSM:UpdateItemReverseLookup()
			
			local itemIDs = {}
			if importData.itemIDGroups then
				for itemString, itemGroup in pairs(TSM.itemReverseLookup) do
					local itemID
					if type(itemString) == "number" then
						itemID = itemString
					else
						itemID = TSMAPI:GetItemID(itemString)
					end
					itemIDs[itemID] = itemIDs[itemID] or {}
					itemIDs[itemID][itemString] = itemGroup
				end
			end
			
			for i, v in pairs(importData) do
				if i == "items" then
					for _, itemString in pairs(v) do
						if not TSM.itemReverseLookup[itemString] and not itemIDs[itemString] then
							TSM.db.profile.groups[groupName][itemString] = true
						elseif not excludeExisting then
							if itemIDs[itemString] then
								for iString, itemGroup in pairs(itemIDs[itemString]) do
									TSM.db.profile.groups[itemGroup][iString] = nil
								end
							else
								TSM.db.profile.groups[TSM.itemReverseLookup[itemString]][itemString] = nil
							end
							TSM.db.profile.groups[groupName][itemString] = true
						end
					end
				elseif i ~= "version" then
					TSM.db.profile[i][groupName] = v
				end
			end
			
			TSM.Config:UpdateTree()
			f:Hide()
			TSM:Printf(L["Data Imported to Group: %s"], groupName)
		end)
	f:AddChild(btn)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end

function TSM:OpenExportFrame(groupName)
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TSM_Auctioning - "..L["Export Group Data"])
	f:SetLayout("Fill")
	f:SetHeight(300)
	
	local eb = AceGUI:Create("MultiLineEditBox")
	eb:SetLabel(L["Group Data"])
	eb:SetMaxLetters(0)
	eb:SetText(TSM:Encode(groupName))
	f:AddChild(eb)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end
-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- core debug code

local TSM = select(2, ...)
local Debug = TSM:NewModule("Debug")
local DT = {functionSymbols={}, userdataSymbols={}, uCache={}, fCache={}, tCache={}}

do
	-- enable taint log
	local val = GetCVar("taintLog")
	if val ~= "1" and val ~= "2" then
		SetCVar("taintLog", "1")
	end
	
	-- populate DT tables with globals
	for k, v in pairs(getfenv(0)) do
		if type(v) == "function" then
			tinsert(DT.functionSymbols, k)
		elseif type(v) == "table" then
			if type(rawget(v,0)) == "userdata" then
				tinsert(DT.userdataSymbols, k)
			end
		end
	end
end



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Debug:DumpTable(tbl, returnResult)
	if returnResult then
		local result = {}
		Debug:Dump(tbl, result)
		return result
	else
		Debug:Dump(tbl)
	end
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Debug:SlashCommandHandler(arg)
	if arg == "view_log" then
		Debug:ShowLogViewer()
	elseif arg == "gui_helper" then
		Debug:ShowGUIHelper()
	elseif arg == "error" then
		TSM:ShowError("Manually triggered error")
	else
		local chatFrame = TSMAPI:GetChatFrame()
		TSM:Print("Debug Commands:")
		chatFrame:AddMessage("|cffffaa00/tsm debug view_log|r - Show the debug log viewer")
		chatFrame:AddMessage("|cffffaa00/tsm debug gui_helper|r - Show the GUI helper")
		chatFrame:AddMessage("|cffffaa00/tsm debug error|r - Throw a lua error")
	end
end



-- ============================================================================
-- Local copy of Blizzard's /dump command with some added features
-- ============================================================================

function DT.CacheFunction(value, newName)
	if not next(DT.fCache) then
		for _, k in ipairs(DT.functionSymbols) do
			local v = getglobal(k)
			if type(v) == "function" then
				DT.fCache[v] = "["..k.."]"
			end
		end
		for k, v in pairs(getfenv(0)) do
			if type(v) == "function" then
				if not DT.fCache[v] then
					DT.fCache[v] = "["..k.."]"
				end
			end
		end
	end
	local name = DT.fCache[value]
	if not name and newName then
		DT.fCache[value] = newName
	end
	return name
end

function DT.CacheUserdata(value, newName)
	if not next(DT.uCache) then
		for _, k in ipairs(DT.userdataSymbols) do
			local v = getglobal(k)
			if type(v) == "table" then
				local u = rawget(v,0)
				if type(u) == "userdata" then
					DT.uCache[u] = k.."[0]"
				end
			end
		end
		for k, v in pairs(getfenv(0)) do
			if type(v) == "table" then
				local u = rawget(v, 0)
				if type(u) == "userdata" then
					if not DT.uCache[u] then
						DT.uCache[u] = k.."[0]"
					end
				end
			end
		end
	end
	local name = DT.uCache[value]
	if not name and newName then
		DT.uCache[value] = newName
	end
	return name
end

function DT.CacheTable(value, newName)
	local name = DT.tCache[value]
	if not name and newName then
		DT.tCache[value] = newName
	end
	return name
end

function DT.Write(msg)
	if DT.result then
		tinsert(DT.result, msg)
	else
		print(msg)
	end
end

function DT.PrepSimple(val)
	local valType = type(val)
	if valType == "nil" then
		return "nil"
	elseif valType == "number" then
		return val
	elseif valType == "boolean" then
		return val and "true" or "false"
	elseif valType == "string" then
		local len = #val
		if len > 200 then
			local more = len - 200
			val = strsub(val, 1, 200)
			return gsub(format("%q...+%s", val, more), "[|]", "||")
		else
			return gsub(format("%q", val), "[|]", "||")
		end
	elseif valType == "function" then
		local fName = DT.CacheFunction(val)
		return fName and format("<%s %s>", valType, fName) or format("<%s>", valType)
	elseif valType == "userdata" then
		local uName = DT.CacheUserdata(val)
		return uName and format("<%s %s>", valType, uName) or format("<%s>", valType)
	elseif valType == "table" then
		local tName = DT.CacheTable(val)
		return tName and format("<%s %s>", valType, tName) or format("<%s>", valType)
	else
		error("Bad type '"..valType.."' to DT.PrepSimple")
	end
end

function DT.PrepSimpleKey(val)
	if type(val) == "string" and #val <= 200 and strmatch(val, "^[a-zA-Z_][a-zA-Z0-9_]*$") then
		return val
	end
	return format("[%s]", DT.PrepSimple(val))
end

function DT.DumpTableContents(val, prefix, firstPrefix, key)
	local showCount = 0
	local oldDepth = DT.depth
	local oldKey = key

	-- Use this to set the cache name
	DT.CacheTable(val, oldKey or "value")

	local iter = pairs(val)
	local nextK, nextV = iter(val, nil)

	while nextK do
		local k,v = nextK, nextV
		nextK, nextV = iter(val, k)
		showCount = showCount + 1
		if showCount <= 30 then
			local prepKey = DT.PrepSimpleKey(k)
			if oldKey == nil then
				key = prepKey
			elseif strsub(prepKey, 1, 1) == "[" then
				key = oldKey..prepKey
			else
				key = oldKey.."."..prepKey
			end
			DT.depth = oldDepth + 1

			local rp = format("|cff88ccff%s%s|r=", firstPrefix, prepKey)
			firstPrefix = prefix
			DT.DumpValue(v, prefix, rp, (nextK and ",") or "", key)
		end
	end
	local cutoff = showCount - 30
	if cutoff > 0 then
		DT.Write(format("%s|cffff0000<skipped %s>|r", firstPrefix, cutoff))
	end
	key = oldKey
	DT.depth = oldDepth
end

-- Return the specified value
function DT.DumpValue(val, prefix, firstPrefix, suffix, key)
	local valType = type(val)

	if valType == "userdata" then
		local uName = DT.CacheUserdata(val, "value")
		if uName then
			DT.Write(format("%s|cff88ff88<%s %s>|r%s", firstPrefix, valType, uName, suffix))
		else
			DT.Write(format("%s|cff88ff88<%s>|r%s", firstPrefix, valType, suffix))
		end
		return
	elseif valType == "function" then
		local fName = DT.CacheFunction(val, "value")
		if fName then
			DT.Write(format("%s|cff88ff88<%s %s>|r%s", firstPrefix, valType, fName, suffix))
		else
			DT.Write(format("%s|cff88ff88<%s>|r%s", firstPrefix, valType, suffix))
		end
		return
	elseif valType ~= "table" then
		DT.Write(format("%s%s%s", firstPrefix, DT.PrepSimple(val), suffix))
		return
	end

	local cacheName = DT.CacheTable(val)
	if cacheName then
		DT.Write(format("%s|cffffcc00%s|r%s", firstPrefix, cacheName, suffix))
		return
	end

	if DT.depth >= 10 then
		DT.Write(format("%s|cffff0000<table (too deep)>|r%s", firstPrefix, suffix))
		return
	end

	local oldPrefix = prefix
	prefix = prefix.."  "
	DT.Write(firstPrefix.."{")
	DT.DumpTableContents(val, prefix, prefix, key)
	DT.Write(oldPrefix.."}"..suffix)
end

-- Dump the specified list of value
function Debug:Dump(value, result)
	DT.depth = 0
	DT.result = result
	wipe(DT.uCache)
	wipe(DT.fCache)
	wipe(DT.tCache)
	
	if type(value) == "table" and not next(value) then
		DT.Write("empty result")
		return
	end
	
	DT.DumpValue(value, "", "", "")
end
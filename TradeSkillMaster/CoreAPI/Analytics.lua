-- ------------------------------------------------------------------------------ --
--								TradeSkillMaster								--
--				http://www.curse.com/addons/wow/tradeskill-master			   --
--																				--
--			 A TradeSkillMaster Addon (http://tradeskillmaster.com)			 --
--	All Rights Reserved* - Detailed license information included with addon.	--
-- ------------------------------------------------------------------------------ --

-- This file contains various analytics APIs

local TSM = select(2, ...)
local Analytics = TSM:NewModule("Analytics")
local private = {events={}, lastEventTime=nil}


-- ============================================================================
-- Module Functions
-- ============================================================================

function Analytics:Embed(obj)
	for key, func in pairs(private.embeds) do
		obj[key] = func
	end
	local moduleName = TSM.Modules:GetName(obj)
end

function Analytics:Save(appDB)
	appDB.analytics = appDB.analytics or {updateTime=0, data={}}
	if private.lastEventTime then
		appDB.analytics.updateTime = private.lastEventTime
	end
	-- remove any events which are over 14 days old
	for i = #appDB.analytics.data, 1, -1 do
		local event = appDB.analytics.data
		local eventTime = strmatch(appDB.analytics.data[i], "([0-9]+)%]$") or ""
		if (tonumber(eventTime) or 0) < time() - 14 * 24 * 60 * 60 then
			tremove(appDB.analytics.data, i)
		end
	end
	for _, event in ipairs(private.events) do
		tinsert(appDB.analytics.data, event)
	end
end



-- ============================================================================
-- Functions to embed in modules
-- ============================================================================

private.embeds = {
	AnalyticsEvent = function(obj, moduleEvent, arg)
		if arg == nil then
			arg = ""
		end
		TSMAPI:Assert(type(moduleEvent) == "string" and strmatch(moduleEvent, "^[A-Z_]+$"))
		TSMAPI:Assert(type(arg) == "string" or type(arg) == "number" or type(arg) == "boolean")
		arg = "\""..gsub(tostring(arg), "\"", "'").."\""
		moduleEvent = "\""..moduleEvent.."\""
		local moduleName = "\""..TSM.Modules:GetName(obj).."\""
		local moduleVersion = "\""..(obj._version or "").."\""
		tinsert(private.events, "["..strjoin(",", moduleName, moduleEvent, moduleVersion, arg, time()).."]")
		private.lastEventTime = time()
	end,
}

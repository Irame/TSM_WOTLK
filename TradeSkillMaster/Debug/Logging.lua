-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for debug logging

local TSM = select(2, ...)
local Debug = TSM:GetModule("Debug")
local LOG_BUFFER_SIZE = 20
local private = {startDebugTime=debugprofilestop(), startTime=time(), logUpdated=nil, threadId=nil, stackRaise=0, filters={module={}, severity={}, timeIndex=2}, buffers={}}



-- ============================================================================
-- Module Functions
-- ============================================================================

-- a simple circular buffer class
local Buffer = {
	New = function(self)
		local o = {}
		o.max = o.max or LOG_BUFFER_SIZE
		o.len = o.len or 0
		o.cursor = o.cursor or 1
		setmetatable(o, self)
		self.__index = self
		if o.max ~= LOG_BUFFER_SIZE then
			-- if max size changes, copy to a new buffer
			local o2 = self:New()
			for val in o:Iterator() do
				o2:Append(val)
			end
			return o2
		end
		return o
	end,
	
	Append = function(self, entry)
		self[self.cursor] = entry
		self.cursor = self.cursor + 1
		if self.cursor == self.max + 1 then
			self.cursor = 1
		end
		if self.len < self.max then
			self.len = self.len + 1
		end
	end,
	
	Get = function(self, index)
		local c = self.cursor - self.len + index - 1
		if c < 1 then
			c = c + self.max
		end
		return self[c]
	end,
	
	Iterator = function(self)
		local i = 0
		return function()
			i = i + 1
			if i <= self.len then return self:Get(i) end
		end
	end,
	
	isInitialized = true,
}

function Debug:EmbedLogging(obj)
	for key, func in pairs(private.embeds) do
		obj[key] = func
	end
	local moduleName = TSM.Modules:GetName(obj)
	if moduleName == "TradeSkillMaster" then
		moduleName = "TSM (Core)"
	end
	-- the log buffers are circular buffers
	private.buffers[moduleName] = Buffer:New()
end

function Debug:GetRecentLogEntries()
	local entries = {}
	for module, buffer in pairs(private.buffers) do
		if buffer.isInitialized then
			for logInfo in buffer:Iterator() do
				if logInfo.timestamp >= private.startTime then
					tinsert(entries, logInfo)
				end
			end
		end
	end
	sort(entries, function(a, b) return a.timestamp > b.timestamp end)
	local result = {}
	for i=1, min(#entries, 50) do
		local msg = ("\n"):split(entries[i].msg)
		if #msg > 150 then
			msg = strsub(msg, 1, 147).."..."
		end
		tinsert(result, format("%s [%s:%s:%d] %s", entries[i].timestampStr, entries[i].module, entries[i].severity, entries[i].line, msg))
	end
	return result
end



-- ============================================================================
-- Viewer Functions
-- ============================================================================

function private:CreateViewer()
	if private.frame then return end
	
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "Frame",
		hidden = true,
		strata = "FULLSCREEN_DIALOG",
		size = {900, 400},
		points = {{"BOTTOMRIGHT"}},
		scripts = {"OnMouseDown", "OnMouseUp"},
		children = {
			{
				type = "Text",
				text = "TSM Debug Log Viewer",
				textFont = {TSMAPI.Design:GetContentFont(), 18},
				textColor = {0.6, 1, 1, 1},
				points = {{"TOP", BFC.PARENT, 0, -3}},
			},
			{
				type = "VLine",
				offset = 0,
				size = {2, 25},
				points = {{"TOPRIGHT", -25, -1}},
			},
			{
				type = "Button",
				key = "closeBtn",
				text = "X",
				textHeight = 18,
				size = {19, 19},
				points = {{"TOPRIGHT", -3, -3}},
				scripts = {"OnClick"},
			},
			{
				type = "HLine",
				offset = -24,
			},
			{
				type = "Text",
				text = "Filters:",
				justify = {"LEFT", "CENTER"},
				size = {0, 45},
				points = {{"TOPLEFT", BFC.PARENT, 5, -29}},
			},
			{
				type = "Dropdown",
				key = "moduleDropdown",
				label = "Module",
				multiselect = true,
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 10, 0}},
				scripts = {"OnValueChanged"},
				tooltip = "The module(s) to filter the log on.",
			},
			{
				type = "Dropdown",
				key = "sevDropdown",
				label = "Severity",
				multiselect = true,
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 10, 0}},
				scripts = {"OnValueChanged"},
				tooltip = "The severity to filter the log on.",
			},
			{
				type = "Dropdown",
				key = "timeDropdown",
				label = "Time Filter",
				list = {"None", "Current Session", "Last Hour", "Last Day"},
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 10, 0}},
				scripts = {"OnValueChanged"},
				tooltip = "The time to filter the log on.",
			},
			{
				type = "HLine",
				offset = -79,
			},
			{
				type = "ScrollingTableFrame",
				key = "logST",
				headFontSize = 14,
				stCols = {{name="Timestamp", width=0.17}, {name="Module", width=0.1, align="CENTER"}, {name="Sev", width=0.05, align="CENTER"}, {name="File", width=0.25}, {name="Message", width=0.43}},
				stDisableSelection = true,
				points = {{"TOPLEFT", 5, -85}, {"BOTTOMRIGHT", BFC.PARENT, -5, 5}},
				scripts = {"OnEnter", "OnLeave"},
			},
		},
		handlers = {
			OnMouseDown = function(self)
				self:StartMoving()
			end,
			OnMouseUp = function(self)
				self:StopMovingOrSizing()
			end,
			closeBtn = {
				OnClick = function(self)
					self:GetParent():Hide()
				end,
			},
			moduleDropdown = {
				OnValueChanged = function(self, key, value)
					private.filters.module[key] = value
					private.logUpdated = true
				end,
			},
			sevDropdown = {
				OnValueChanged = function(self, key, value)
					private.filters.severity[key] = value
					private.logUpdated = true
				end,
			},
			timeDropdown = {
				OnValueChanged = function(self, value)
					private.filters.timeIndex = value
					private.logUpdated = true
				end,
			},
			logST = {
				OnEnter = function(self, data)
					if not data.info then return end
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:SetPoint("LEFT", self, "RIGHT")
					local color = TSMAPI.Design:GetInlineColor("link")
					GameTooltip:AddDoubleLine(format("|cff99ffffModule:|r |cffffffff%s|r", data.info.module))
					GameTooltip:AddDoubleLine(format("|cff99ffffSeverity:|r |cffffffff%s|r", data.info.severity))
					GameTooltip:AddDoubleLine(format("|cff99ffffTimestamp:|r |cffffffff%s|r", data.info.timestampStr))
					GameTooltip:AddDoubleLine(format("|cff99ffffFile:|r |cffffffff%s:%s|r", data.info.file, data.info.line))
					GameTooltip:AddDoubleLine(format("|cff99ffffMessage:|r |cffffffff%s|r", data.info.msg))
					GameTooltip:Show()
				end,
				OnLeave = function()
					GameTooltip:Hide()
				end,
			},
		},
	}
	private.frame = TSMAPI.GUI:BuildFrame(frameInfo)
	private.frame:SetMovable(true)
	private.frame:SetScale(UIParent:GetScale())
	TSMAPI.Design:SetFrameBackdropColor(private.frame)
	
	-- initialize module filters and dropdown list
	local moduleList = {}
	for name, buffer in pairs(private.buffers) do
		if buffer.isInitialized then
			moduleList[name] = name
			private.filters.module[name] = true
		end
	end
	private.frame.moduleDropdown:SetList(moduleList)
	
	-- initialize severity filters and dropdown list
	local SEVERITIES = {"INFO", "WARN", "ERR"}
	local sevList = {}
	for _, sev in ipairs(SEVERITIES) do
		sevList[sev] = sev
		private.filters.severity[sev] = true
	end
	private.frame.sevDropdown:SetList(sevList, SEVERITIES)
end

function Debug:ShowLogViewer()
	if private.frame and private.frame:IsVisible() then return end
	private:CreateViewer()
	private.frame:Show()
	
	-- update module filter dropdown
	private.frame.moduleDropdown:SetValue({})
	for name, value in pairs(private.filters.module) do
		private.frame.moduleDropdown:SetItemValue(name, value)
	end
	
	-- update severity filter dropdown
	private.frame.sevDropdown:SetValue({})
	for name, value in pairs(private.filters.severity) do
		private.frame.sevDropdown:SetItemValue(name, value)
	end
	
	-- update time filter dropdown
	private.frame.timeDropdown:SetValue(private.filters.timeIndex)
	
	if private.threadId then
		TSMAPI.Threading:Kill(private.threadId)
	end
	private.threadId = TSMAPI.Threading:Start(private.UpdateThread, 0.4, function() private.threadId = nil end)
end

function private:IsLogInfoFiltered(logInfo)
	if not private.filters.module[logInfo.module] then return true end
	if not private.filters.severity[logInfo.severity] then return true end
	if private.filters.timeIndex == 2 and logInfo.timestamp < private.startTime then
		return true
	elseif private.filters.timeIndex == 3 and logInfo.timestamp < (time()-60*60) then
		return true
	elseif private.filters.timeIndex == 4 and logInfo.timestamp > (time()-24*60*60) then
		return true
	end
end

function private.UpdateThread(self)
	self:SetThreadName("DEBUG_LOGGING_UPDATE")
	while true do
		if not private.frame:IsVisible() then return end
		if private.logUpdated then
			-- update ST data
			local stData = {}
			for module, buffer in pairs(private.buffers) do
				if buffer.isInitialized then
					for logInfo in buffer:Iterator() do
						if not private:IsLogInfoFiltered(logInfo) then
							tinsert(stData, {
								cols = {
									{value = logInfo.timestampStr},
									{value = logInfo.module},
									{value = logInfo.severity},
									{value = logInfo.file..":"..logInfo.line},
									{value = gsub(logInfo.msg, "\n", "\\")},
								},
								info = logInfo,
							})
						end
					end
				end
			end
			sort(stData, function(a, b) return a.info.timestamp > b.info.timestamp end)
			private.frame.logST:SetData(stData)
			private.logUpdated = nil
		end
		self:Sleep(0.1)
	end
end



-- ============================================================================
-- Functions to Embed in Modules
-- ============================================================================

function private.LogMessage(module, severity, ...)
	if module == "TradeSkillMaster" then
		module = "TSM (Core)"
	end
	local args = {...}
	for i=1, #args do
		if type(args[i]) == "boolean" then
			args[i] = args[i] and "T" or "F"
		elseif type(args[i]) ~= "string" and type(args[i]) ~= "number" then
			args[i] = tostring(args[i])
		end
	end
	local file, line = (":"):split(strmatch(debugstack(3+private.stackRaise, 1, 0), "[A-Za-z_0-9]+\.lua:[0-9]+") or "?:?")
	private.stackRaise = 0
	local timestamp = (debugprofilestop() - private.startDebugTime) / 1000 + private.startTime
	local timestampStr = format("%s.%03d", date("%Y/%m/%d %H:%M:%S", floor(timestamp)), floor((timestamp%1) * 1000))
	private.buffers[module]:Append({severity=severity, module=module, file=file, line=line, timestamp=timestamp, timestampStr=timestampStr, msg=format(unpack(args))})
	private.logUpdated = true
end

private.embeds = {
	LOG_RAISE_STACK = function()
		-- will look at one level higher in the debug stack next time we log
		private.stackRaise = private.stackRaise + 1
	end,

	LOG_INFO = function(obj, ...)
		private.LogMessage(TSM.Modules:GetName(obj), "INFO", ...)
	end,

	LOG_WARN = function(obj, ...)
		private.LogMessage(TSM.Modules:GetName(obj), "WARN", ...)
	end,

	LOG_ERR = function(obj, ...)
		private.LogMessage(TSM.Modules:GetName(obj), "ERR", ...)
	end,
}
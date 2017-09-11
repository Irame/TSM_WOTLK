-- Don't change this file before talking to Sapu!

local TSM = select(2, ...)
local private = {}
LibStub("AceEvent-3.0"):Embed(private)


local eventFrame = CreateFrame("Frame")
eventFrame:Hide()
eventFrame.data = {}
eventFrame.callback = function() end
eventFrame:SetScript("OnEvent", function(self, event, ...)
		if self.interrupt and event == self.interrupt.event and self.interrupt.callback() then
			self:UnregisterAllEvents()
			self.data = {}
		end
		for i=1, #self.data do
			if self.data[i].event == event then
				if self.data[i].callback then
					if self.data[i].callback(event, ...) then
						tremove(self.data, i)
						self:UnregisterEvent(event)
					end
				else
					tremove(self.data, i)
					self:UnregisterEvent(event)
				end
				break
			end
		end
		if #self.data == 0 then
			self:Hide()
			self.callback()
		end
	end)
	
local function WaitForEvents(data, callback, interrupt)
	eventFrame.data = data
	eventFrame.callback = callback
	for i=1, #data do
		eventFrame:RegisterEvent(data[i].event)
	end
	if interrupt then
		eventFrame.interrupt = interrupt
		eventFrame:RegisterEvent(interrupt.event)
	end
	eventFrame:Show()
end

function TSMAPI:CreateEventDelay(event, callback, timeout, validator)
	if not event then return end
	local eventName = "eventDelay"..random()
	if timeout then
		TSMAPI:CreateTimeDelay(eventName, timeout, function() eventFrame:Hide() end)
		callback()
	end
	
	WaitForEvents({event=event, callback=validator}, function() callback() TSMAPI:CancelFrame(eventName) end)
end

-- Sends the "TSM_AH_EVENTS" message once the action (buyout/bid/cancel/post)
-- has been acknowledged by the server and the client has been notified
function TSMAPI:WaitForAuctionEvents(mode, isMultiPost)
	local function ValidateEvent(_, msg)
		if mode == "Buyout" then
			return msg:match(gsub(ERR_AUCTION_BID_PLACED, "%%s", ""))
		elseif mode == "Cancel" then
			return msg == ERR_AUCTION_REMOVED
		elseif mode == "Post" then
			return msg == ERR_AUCTION_STARTED
		end
	end
	
	local events, interrupt
	if mode == "Buyout" then
		events = {{event="AUCTION_ITEM_LIST_UPDATE"}, {event="CHAT_MSG_SYSTEM", callback=ValidateEvent}}
		interrupt = {event="UI_ERROR_MESSAGE", callback=function(_,msg) return msg == ERR_AUCTION_HIGHER_BID end}
	elseif mode == "Cancel" then
		events = {{event="CHAT_MSG_SYSTEM", callback=ValidateEvent}, {event="AUCTION_OWNED_LIST_UPDATE"}}
	elseif mode == "Post" then
		if isMultiPost then
			events = {{event="AUCTION_MULTISELL_UPDATE", callback=function(_,arg1,arg2) return arg1 == arg2 end}}
		else
			events = {{event="CHAT_MSG_SYSTEM", callback=ValidateEvent}}
		end
	end
	if events then
		WaitForEvents(events, function() private:SendMessage("TSM_AH_EVENTS", mode) end, interrupt)
	end
end


function TSMAPI:GetAuctionPercentColor(percent)
	local colors = {
		{color="|cff2992ff", value=50}, -- blue
		{color="|cff16ff16", value=80}, -- green
		{color="|cffffff00", value=110}, -- yellow
		{color="|cffff9218", value=135}, -- orange
		{color="|cffff0000", value=math.huge}, -- red
	}
	
	for i=1, #colors do
		if percent < colors[i].value then
			return colors[i].color
		end
	end
	
	return "|cffffffff"
end


do
	local fPrivate = {modes={}} function fPrivate:GetModeObject(obj, buttonText, buttonDesc, module) local temp, mt, mt2, test = {}, {}, {} mt = { data = {obj=obj, buttonText=buttonText, buttonDesc=buttonDesc, module=module}, __eq = function(a, b) if a[b] == nil then wipe(fPrivate) error("Invalid access of protected table.", 2) end test = time() return not (a[b] and b == "isValid" and mt.data.isValid) end, __index = function(f, i) if i == "info" then if (time() - (test or 0)) > 1 then wipe(fPrivate) error("Invalid access of protected table.", 2) end else return mt.data[i] end end, __newindex = function(...) local num = select('#', ...) local _, i, v = ... if i == "result" then if num == 2 then mt.isValid = true elseif v == "invalid" then mt.isValid = false elseif type(v) == "string" and strfind(v, "AuctionGUI") then mt.isValid = true else wipe(fPrivate) error("Attempt to update a read-only table.", 2) end else wipe(fPrivate) error("Attempt to update a read-only table.", 2) end end, } mt2 = { __newindex = function(_, i, v) if i == "isValid" then mt.data[i] = v else wipe(fPrivate) error("Attempt to update a read-only table.", 2) end end, } setmetatable(mt, mt2) setmetatable(temp, mt) return temp end function fPrivate:GetAHTabFrame() local temp = CreateFrame("Frame", nil, TSMAuctionFrame, "AuctionFrameTabTemplate") local frame = {} local mt = { __index = function(f, i) if i == "modeText" then return fPrivate:CheckEnv() or temp.modeText elseif i == "AddSecureChild" then return function(_, child) return temp:AddSecureChild(f, child) end elseif i == "Validate" then return function() return temp end elseif type(temp[i]) == "function" then return function(_, ...) temp[i](temp, ...) end elseif type(temp[i]) == "table" then return temp[i] else wipe(fPrivate) error("Invalid table read.", 2) end end, __newindex = function(_, i, v) if i == "mode" then temp[v[1]] = v[3][v[2]] elseif i == "content" or i == "controlFrame" then temp[i] = v else wipe(fPrivate) error("Attempt to update a read-only table.", 2) end end } setmetatable(frame, mt) return frame end local function isDoubleEqual(x, y) return abs(x-y) < 0.01 end function fPrivate:CheckEnv() local mode = fPrivate.mode if mode.previous then local current = {GetCursorPosition()} if isDoubleEqual(current[1], mode.previous[1]) and isDoubleEqual(current[2], mode.previous[2]) and (GetTime() - mode.previous[3]) > 120 then mode.test = true return true end end mode.previous = {GetCursorPosition()} mode.previous[3] = GetTime() end function fPrivate:OnSidebarButtonClick(mode, button) assert(mode.obj, "Invalid mode: "..(fPrivate.failed and 1 or 0)) fPrivate:HideCurrentMode() fPrivate.frame.mode = {"modeText", "buttonText", mode} fPrivate.mode = mode.obj getmetatable(mode).__newindex(mode, "result", fPrivate.mode:Show(fPrivate.frame, button)) if getmetatable(mode).__eq(mode, "isValid") then local function callback(flag) if flag then mode.result = debugstack() fPrivate.mode:Show(fPrivate.frame, button) else wipe(fPrivate) print("Error: You failed TradeSkillMaster's anti-bot test. TSM Won't work until you reload your UI.") return end end TSMAPI:RunTest(fPrivate.frame, callback) end return mode.info end function TSM:GetAuctionFramePrivate() TSM.GetAuctionFramePrivate = nil if tonumber(select(3, strfind(debugstack(), "([0-9]+)"))) == 113 then fPrivate.num = 432 return fPrivate end end
end
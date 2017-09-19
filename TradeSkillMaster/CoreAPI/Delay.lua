-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various delay APIs

local TSM = select(2, ...)
local Delay = TSM:NewModule("Delay")
local private = {delays={}, eventFrames={}, frameNumber=0, frameNumberTracker=nil}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Delay:AfterTime(...)
	local label, duration, callback, repeatDelay
	if type(select(1, ...)) == "number" then
		-- use table as label if none specified
		label = {}
		duration, callback, repeatDelay = ...
	else
		label, duration, callback, repeatDelay = ...
	end
	assert(label and type(duration) == "number" and type(callback) == "function" and (not repeatDelay or type(repeatDelay) == "number"), format("invalid args '%s', '%s', '%s', '%s'", tostring(label), tostring(duration), tostring(callback), tostring(repeatDelay)))
	
	for _, delay in ipairs(private.delays) do
		if delay.label == label then
			-- delay is already running, so just return
			return
		end
	end
	
	tinsert(private.delays, {endTime=(GetTime()+duration), callback=callback, label=label, repeatDelay=repeatDelay})
end

function TSMAPI.Delay:AfterFrame(...)
	local label, duration, callback, repeatDelay
	if type(select(1, ...)) == "number" then
		-- use table as label if none specified
		label = {}
		duration, callback, repeatDelay = ...
	else
		label, duration, callback, repeatDelay = ...
	end
	assert(label and type(duration) == "number" and type(callback) == "function" and (not repeatDelay or type(repeatDelay) == "number"), format("invalid args '%s', '%s', '%s', '%s'", tostring(label), tostring(duration), tostring(callback), tostring(repeatDelay)))
	
	for _, delay in ipairs(private.delays) do
		if delay.label == label then
			-- delay is already running, so just return
			return
		end
	end
	
	tinsert(private.delays, {endFrame=(private.frameNumber+duration), callback=callback, label=label, repeatDelay=repeatDelay})
end

function TSMAPI.Delay:Cancel(label)
	for i, delay in ipairs(private.delays) do
		if delay.label == label then
			tremove(private.delays, i)
			break
		end
	end
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Delay:OnInitialize()
	private.frameNumberTracker = CreateFrame("frame")
	private.frameNumberTracker:Show()
	private.frameNumberTracker:SetScript("OnUpdate", function() private.frameNumber = private.frameNumber + 1 end)
	TSMAPI.Threading:StartImmortal(private.DelayThread, 0.4)
end



-- ============================================================================
-- Main Delay Thread
-- ============================================================================

function private.DelayThread(self)
	self:SetThreadName("DELAY_MAIN")
	while true do
		if #private.delays > 0 then
			for i=#private.delays, 1, -1 do
				local startFrame = private.frameNumber
				if private.delays[i].endFrame and private.delays[i].endFrame <= private.frameNumber then
					-- the end time has passed
					local callback = private.delays[i].callback
					if private.delays[i].repeatDelay then	
						private.delays[i].endFrame = private.frameNumber + private.delays[i].repeatDelay
					else
						tremove(private.delays, i)
					end
					callback()
				elseif private.delays[i].endTime and private.delays[i].endTime <= GetTime() then
					-- the end time has passed
					local callback = private.delays[i].callback
					if private.delays[i].repeatDelay then	
						private.delays[i].endTime = GetTime() + private.delays[i].repeatDelay
					else
						tremove(private.delays, i)
					end
					callback()
				end
			end
		end
		self:Yield(true)
	end
end
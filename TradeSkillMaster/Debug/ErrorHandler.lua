-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TSM's error handler

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")
local private = {isErrorFrameVisible=nil}
local ADDON_SUITES = {
	"ArkInventory",
	"AtlasLoot",
	"Altoholic",
	"Auc-",
	"Bagnon",
	"BigWigs",
	"Broker",
	"ButtonFacade",
	"Carbonite",
	"DataStore",
	"DBM",
	"Dominos",
	"DXE",
	"EveryQuest",
	"Forte",
	"FuBar",
	"GatherMate2",
	"Grid",
	"LightHeaded",
	"LittleWigs",
	"Masque",
	"MogIt",
	"Odyssey",
	"Overachiever",
	"PitBull4",
	"Prat-3.0",
	"RaidAchievement",
	"Skada",
	"SpellFlash",
	"TidyPlates",
	"TipTac",
	"Titan",
	"UnderHood",
	"WowPro",
	"ZOMGBuffs",
}
TSMERRORLOG = {}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI:Assert(cond, err, raiseLevel)
	if cond then return cond end
	private.isAssert = true
	raiseLevel = (type(raiseLevel) == "number" and raiseLevel > 0 and raiseLevel) or 0
	error(err or "Assertion failure!", 2+raiseLevel)
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function TSM:ShowError(err, thread)
	-- show an error, but don't cause an exception to be thrown
	private.isAssert = "SILENT"
	private.ErrorHandler(err or "Assertion failure!", thread)
end

function TSM:ShowConfigError(err)
	private.ignoreErrors = true

	tinsert(TSMERRORLOG, err)
	if not private.isErrorFrameVisible then
		TSM:Print(L["Looks like TradeSkillMaster has detected an error with your configuration. Please address this in order to ensure TSM remains functional."])
		private:ShowError(err, true)
	elseif private.isErrorFrameVisible == true then
		TSM:Print(L["Additional error suppressed"])
		private.isErrorFrameVisible = 1
	end

	private.ignoreErrors = false
end



-- ============================================================================
-- Error GUI Functions
-- ============================================================================

function private:ShowError(msg, isVerify, isUnofficial)
	if not AceGUI or not TSM.db then
		private.isErrorFrameVisible = true
		-- can't use TSMAPI.Delay:AfterTime here since we can't rely on that being loaded
		C_Timer.After(0.1, function() private:ShowError(msg, isVerify, isUnofficial) end)
		return
	end

	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) private.isErrorFrameVisible = false AceGUI:Release(self) end)
	f:SetTitle(L["TradeSkillMaster Error Window"])
	f:SetLayout("Flow")
	f:SetWidth(500)
	f:SetHeight(400)

	local l = AceGUI:Create("Label")
	l:SetFullWidth(true)
	l:SetFontObject(GameFontNormal)
	if isVerify then
		l:SetText(L["Looks like TradeSkillMaster has detected an error with your configuration. Please address this in order to ensure TSM remains functional."].."\n"..L["|cffffff00DO NOT report this as an error to the developers.|r If you require assistance with this, join our IRC channel or make a post on the TSM forums instead."].."|r")
	elseif isUnofficial then
		l:SetText(L["Looks like an |cffff0000unofficial|r TSM module has encountered an error. Please do not report this to the TSM team, but instead report it to the author of the addon. If it's affecting the operation of TSM, you may want to disable it."])
	elseif TSM.Modules:HasOutdatedAddons() then
		l:SetText(L["|cffff0000Your TSM addons are out of date!|r Please DO NOT report this error, but instead update your TSM addons from here:"].." |cffffff00http://tradeskillmaster.com/addon/overview|r")
	else
		l:SetText(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by copying the entire error below and following the instructions for reporting lua errors listed at the following URL:"].." |cffffff00http://tradeskillmaster.com/site/getting-help|r")
	end
	f:AddChild(l)

	local heading = AceGUI:Create("Heading")
	heading:SetText("")
	heading:SetFullWidth(true)
	f:AddChild(heading)

	local eb = AceGUI:Create("MultiLineEditBox")
	eb:SetLabel(L["Error Info:"])
	eb:SetMaxLetters(0)
	eb:SetFullWidth(true)
	eb:SetText(msg)
	eb:DisableButton(true)
	eb:SetFullHeight(true)
	eb:SetCallback("OnTextChanged", function(self) self:SetText(msg) end) -- hacky way to make it read-only
	f:AddChild(eb)

	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
	private.isErrorFrameVisible = true
end



-- ============================================================================
-- Error Handler
-- ============================================================================

function private.ErrorHandler(msg, thread)
	-- ignore errors while we are handling this error
	private.ignoreErrors = true
	local isAssert = private.isAssert
	private.isAssert = nil

	if type(thread) ~= "thread" then thread = nil end

	local num
	if thread then
		msg, num = gsub(msg, ".+TradeSkillMaster\\Core\\Threading%.lua:%d+:", "")
	end

	local color = "|cff99ffff"
	local color2 = "|cffff1e00"
	local errMsgParts = {}

	-- add addon name
	local addonName = nil
	if strfind(msg, "T?r?a?d?e?S?k?i?llMaster_") then
		addonName = "TradeSkillMaster_"..strmatch(msg, "T?r?a?d?e?S?k?i?llMaster_([A-Za-z]+)")
	elseif strfind(msg, "TradeSkillMaster\\") or isAssert == "SILENT" then
		addonName = "TradeSkillMaster"
	else
		addonName = "?"
	end
	tinsert(errMsgParts, color.."Addon:|r "..color2..addonName.."|r")

	-- add error message
	tinsert(errMsgParts, color.."Message:|r "..msg)

	-- add current date/time
	tinsert(errMsgParts, color.."Date:|r "..date("%m/%d/%y %H:%M:%S"))

	-- add current client version number
	tinsert(errMsgParts, color.."Client:|r "..GetBuildInfo())

	-- add locale name
	tinsert(errMsgParts, color.."Locale:|r "..GetLocale())

	-- is player in combat
	tinsert(errMsgParts, color.."Combat:|r "..tostring(InCombatLockdown()))

	-- add backtrace
	local stackInfo = {color.."Stack:|r"}
	local stack = nil
	if thread then
		stack = debugstack(thread, 1) or debugstack(thread, 2)
	elseif isAssert == "SILENT" then
		stack = debugstack(3) or debugstack(2)
	elseif isAssert then
		stack = debugstack(4) or debugstack(3)
	else
		stack = debugstack(2) or debugstack(1)
	end
	if type(stack) == "string" then
		for _, line in ipairs({("\n"):split(stack)}) do
			local strStart = strfind(line, "in function")
			if strStart and not strfind(line, "ErrorHandler.lua") then
				line = gsub(line, "`", "<", 1)
				line = gsub(line, "'", ">", 1)
				local inFunction = strmatch(line, "<[^>]*>", strStart)
				if inFunction then
					inFunction = gsub(gsub(inFunction, ".*\\", ""), "<", "")
					if inFunction ~= "" then
						local str = strsub(line, 1, strStart-2)
						str = strsub(str, strfind(str, "TradeSkillMaster") or 1)
						if strfind(inFunction, "`") then
							inFunction = strsub(inFunction, 2, -2)..">"
						end
						str = gsub(str, "TradeSkillMaster", "TSM")
						tinsert(stackInfo, str.." <"..inFunction)
					end
				end
			end
		end
	end
	tinsert(errMsgParts, table.concat(stackInfo, "\n    "))

	-- add TSM thread info
	tinsert(errMsgParts, color.."TSM Thread Info:|r\n    "..table.concat(TSMAPI.Debug:GetThreadInfo(), "\n    "))

	-- add recent TSM debug log entries
	tinsert(errMsgParts, color.."TSM Debug Log:|r\n    "..table.concat(TSM.Debug:GetRecentLogEntries(), "\n    "))

	-- add addons
	local hasAddonSuite = {}
	local addons = {color.."Addons:|r"}
	for i=1, GetNumAddOns() do
		local name, _, _, enabled = GetAddOnInfo(i)
		local version = GetAddOnMetadata(name, "X-Curse-Packaged-Version") or GetAddOnMetadata(name, "Version") or ""
		if enabled then
			local isSuite
			for _, commonTerm in ipairs(ADDON_SUITES) do
				if strsub(name, 1, #commonTerm) == commonTerm then
					isSuite = commonTerm
					break
				end
			end
			local commonTerm = "TradeSkillMaster"
			if isSuite then
				if not hasAddonSuite[isSuite] then
					tinsert(addons, name.." ("..version..")")
					hasAddonSuite[isSuite] = true
				end
			elseif strsub(name, 1, #commonTerm) == commonTerm then
				name = gsub(name, "TradeSkillMaster", "TSM")
				tinsert(addons, name.." ("..version..")")
			else
				tinsert(addons, name.." ("..version..")")
			end
		end
	end
	tinsert(errMsgParts, table.concat(addons, "\n    "))

	-- add error message to global TSM error log
	tinsert(TSMERRORLOG, table.concat(errMsgParts, "\n"))

	-- show the error message if applicable
	if not private.isErrorFrameVisible then
		local author = GetAddOnMetadata(addonName, "Author")
		local isOfficial = author and strfind(author, "^Sapu94")
		if isOfficial and TSM.LOG_ERR and TSM.AnalyticsEvent then
			TSM:LOG_ERR(msg)
			TSM:AnalyticsEvent("ERROR", msg)
		end
		TSM:Print(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by following the instructions shown."])
		private:ShowError(TSMERRORLOG[#TSMERRORLOG], nil, not isOfficial)
	elseif private.isErrorFrameVisible == true then
		TSM:LOG_ERR(msg)
		TSM:Print(L["Additional error suppressed"])
		private.isErrorFrameVisible = 1
	end

	private.ignoreErrors = false
end

function private.AddonBlockedEvent(event, addonName, addonFunc)
	if not strmatch(addonName, "TradeSkillMaster") then return end
	-- just log it - it might not be TSM
	TSM:LOG_ERR("[%s] AddOn '%s' tried to call the protected function '%s'.", event, addonName or "<name>", addonFunc or "<func>")
end

do
	private.origErrorHandler = geterrorhandler()
	seterrorhandler(function(errMsg)
		if not AceGUI or not TSM.db then
			-- we can't show our error window until AceGUI and our DB are loaded, so just use the default error handler
			return private.origErrorHandler and private.origErrorHandler(errMsg) or nil
		end
		local isTSMError = false
		local tsmErrMsg = tostring(errMsg):trim()
		-- ignore auc-stat-wowuction errors or non-TSM errors or corrupt SV errors
		if private.ignoreErrors or strmatch(tsmErrMsg, "auc%-stat%-wowuction") or strmatch(tsmErrMsg, "TheUndermineJournal%.lua") or (not strmatch(tsmErrMsg, "TradeSkillMaster") and not (strmatch(tsmErrMsg, "^%.%.%.T?r?a?d?e?S?k?i?l?lMaster_[A-Z][a-z]+[\\/]") or strmatch(tsmErrMsg, "AddOn TradeSkillMaster[_a-zA-Z]* attempted"))) or strmatch(tsmErrMsg, "\\SavedVariables\\TradeSkillMaster") then
			tsmErrMsg = nil
		end
		if tsmErrMsg then
			local status, ret = pcall(private.ErrorHandler, tsmErrMsg)
			if status then
				return ret
			end
		end
		return private.origErrorHandler and private.origErrorHandler(errMsg) or nil
	end)
	TSM:RegisterEvent("ADDON_ACTION_FORBIDDEN", private.AddonBlockedEvent)
	TSM:RegisterEvent("ADDON_ACTION_BLOCKED", private.AddonBlockedEvent)
end

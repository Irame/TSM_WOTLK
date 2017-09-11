-- TSM's error handler.

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")


local origErrorHandler
local ignoreErrors
local isErrorFrameVisible
TSMERRORLOG = {}

local addonSuites = {
	{name="ArkInventory"},
	{name="AtlasLoot"},
	{name="Altoholic"},
	{name="Auc-Advanced", commonTerm="Auc-"},
	{name="Bagnon"},
	{name="BigWigs"},
	{name="Broker"},
	{name="ButtonFacade"},
	{name="Carbonite"},
	{name="DataStore"},
	{name="DBM"},
	{name="Dominos"},
	{name="DXE"},
	{name="EveryQuest"},
	{name="Forte"},
	{name="FuBar"},
	{name="GatherMate2"},
	{name="Grid"},
	{name="LightHeaded"},
	{name="LittleWigs"},
	{name="Masque"},
	{name="MogIt"},
	{name="Odyssey"},
	{name="Overachiever"},
	{name="PitBull4"},
	{name="Prat-3.0"},
	{name="RaidAchievement"},
	{name="Skada"},
	{name="SpellFlash"},
	{name="TidyPlates"},
	{name="TipTac"},
	{name="Titan"},
	{name="UnderHood"},
	{name="WowPro"},
	{name="ZOMGBuffs"},
}

local function StrStartCmp(str, startStr)
	local startLen = strlen(startStr)

	if startLen <= strlen(str) then
		return strsub(str, 1, startLen) == startStr
	end
end



local function ExtractErrorMessage(...)
	local msg = ""

	for _, var in ipairs({...}) do
		local varStr
		local varType = type(var)

		if	varType == "boolean" then
			varStr = var and "true" or "false"
		elseif varType == "table" then
			varStr = "<table>"
		elseif varType == "function" then
			varStr = "<function>"
		elseif var == nil then
			varStr = "<nil>"
		else
			varStr = var
		end

		msg = msg.." "..varStr
	end
	
	return msg
end

local function GetDebugStack()
	local stackInfo = {}
	local stackString = ""
	local stack = debugstack(2) or debugstack(1)
	
	if type(stack) == "string" then
		local lines = {("\n"):split(stack)}
		for _, line in ipairs(lines) do
			local strStart = strfind(line, "in function")
			if strStart and not strfind(line, "ErrorHandler.lua") then
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
	
	return table.concat(stackInfo, "\n")
end

local function GetAddonList()
	local hasAddonSuite = {}
	local addons = {}
	local addonString = ""
	
	for i = 1, GetNumAddOns() do
		local name, _, _, enabled = GetAddOnInfo(i)
		local version = GetAddOnMetadata(name, "X-Curse-Packaged-Version") or GetAddOnMetadata(name, "Version") or ""
		if enabled then
			local isSuite
		
			for _, addonSuite in ipairs(addonSuites) do
				local commonTerm = addonSuite.commonTerm or addonSuite.name
				
				if StrStartCmp(name, commonTerm) then
					isSuite = commonTerm
					break
				end
			end
			
			if isSuite then
				if not hasAddonSuite[isSuite] then
					tinsert(addons, {name=name, version=version})
					hasAddonSuite[isSuite] = true
				end
			elseif StrStartCmp(name, "TradeSkillMaster") then
				tinsert(addons, {name=gsub(name, "TradeSkillMaster", "TSM"), version=version})
			else
				tinsert(addons, {name=name, version=version})
			end
		end
	end
	
	for i, addonInfo in ipairs(addons) do
		local info = addonInfo.name .. " (" .. addonInfo.version .. ")"
		if i == #addons then
			addonString = addonString .. "    " .. info
		else
			addonString = addonString .. "    " .. info .. "\n"
		end
	end
	
	return addonString
end

local function ShowError(msg)
	if not AceGUI then
		TSMAPI:CreateTimeDelay("errHandlerShowDelay", 0.1, function()
				if AceGUI and UIParent then
					CancelFrame("errHandlerShowDelay")
					ShowError(msg)
				end
			end, 0.1)
		return
	end

	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) isErrorFrameVisible = false AceGUI:Release(self) end)
	f:SetTitle(L["TradeSkillMaster Error Window"])
	f:SetLayout("Flow")
	f:SetWidth(500)
	f:SetHeight(400)
	
	local l = AceGUI:Create("Label")
	l:SetFullWidth(true)
	l:SetFontObject(GameFontNormal)
	l:SetText(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by copying the entire error below and following the instructions for reporting bugs listed here (unless told elsewhere by the author):"].." |cffffff00http://tradeskillmaster.com/wiki|r")
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
	f:AddChild(eb)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
	isErrorFrameVisible = true
end

function TSM:IsValidError(...)
	if ignoreErrors then return end
	ignoreErrors = true
	local msg = ExtractErrorMessage(...)
	ignoreErrors = false
	if not strfind(msg, "TradeSkillMaster") then return end
	return msg
end

local function TSMErrorHandler(msg)
	-- ignore errors while we are handling this error
	ignoreErrors = true
	
	local color = TSMAPI.Design:GetInlineColor("link2")
	local errorMessage = color.."Date:|r "..date("%m/%d/%y %H:%M:%S").."\n"
	errorMessage = errorMessage..color.."Message:|r "..msg.."\n"
	errorMessage = errorMessage..color.."Stack:|r\n"..GetDebugStack().."\n"
	errorMessage = errorMessage..color.."Locale:|r "..GetLocale().."\n"
	errorMessage = errorMessage..color.."Addons:|r\n"..GetAddonList().."\n"
	tinsert(TSMERRORLOG, errorMessage)
	if not isErrorFrameVisible then
		TSM:Print(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by following the instructions shown."])
		ShowError(errorMessage)
	else
		if isErrorFrameVisible == true then
			TSM:Print(L["Additional error suppressed"])
			isErrorFrameVisible = 1
		end
	end

	ignoreErrors = false
end

do
	origErrorHandler = geterrorhandler()
	local errHandlerFrame = CreateFrame("Frame", nil, nil, "TSMErrorHandlerTemplate")
	errHandlerFrame.errorHandler = TSMErrorHandler
	errHandlerFrame.origErrorHandler = origErrorHandler
	seterrorhandler(errHandlerFrame.handler)
end

--- Disables TSM's error handler until the game is reloaded.
-- This is mainly used for debugging errors with TSM's error handler and should not be used in actual code.
function TSMAPI:DisableErrorHandler()
	seterrorhandler(origErrorHandler)
end
-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Mailing - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_mailing.aspx     --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_Mailing", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

TSM.version = GetAddOnMetadata("TradeSkillMaster_Mailing","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_Mailing", "Version") -- current version of the addon
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Mailing") -- loads the localization table

local private = {lootIndex=1, recheckTime=1, allowTimerStart=true}

local isMoP = select(4, GetBuildInfo()) >= 50000

local savedDBDefaults = {
	factionrealm = {
		mailTargets = {},
		mailItems = {},
	},
	profile = {
		autoCheck = true,
		dontDisplayMoneyCollected = false,
		sendItemsIndividually = false,
		autoMailSendDelay = 0.5,
		autoMailRecheckTime = nil,
	},
}

function TSM:OnEnable()
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_MailingDB", savedDBDefaults, true)
	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end

	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Mailing", TSM.version, GetAddOnMetadata("TradeSkillMaster_Mailing", "Author"), GetAddOnMetadata("TradeSkillMaster_Mailing", "Notes"))
	TSMAPI:RegisterIcon(L["Mailing Options"], "Interface\\Icons\\Inv_Letter_20", function(...) TSM.Config:Load(...) end, "TradeSkillMaster_Mailing", "options")

	TSM:SetupOpenMailButton()
	
	-- cache info from the server for all the items in mailing
	for itemID in pairs(TSM.db.factionrealm.mailItems) do
		GetItemInfo(itemID)
	end
end

local function showTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText(self.tooltip, 1, 1, 1, nil, true)
	GameTooltip:Show()
end

local function hideTooltip(self)
	GameTooltip:Hide()
end

function TSM:SetupOpenMailButton()
	-- Mass opening
	local button = CreateFrame("Button", nil, InboxFrame, "UIPanelButtonTemplate")
	button:SetText(L["Open All"])
	button:SetHeight(24)
	button:SetWidth(130)
	if isMoP then
		button:SetPoint("BOTTOM", -20, 100)
	else
		button:SetPoint("BOTTOM", InboxFrame, "CENTER", -10, -165)
	end
	button:SetScript("OnClick", function(self) private:StartAutoLooting() end)
	private.button = button
	
	if ElvUI and ElvUI[1] then
		ElvUI[1]:GetModule("Skins"):HandleButton(button)
	end

	-- Don't show mass opening if Postal/MailOpener is enabled since postals button will block _Mailing's
	local foundOtherMailAddon
	if select(4, GetAddOnInfo("MailOpener")) == 1 then
		button:Hide()
		foundOtherMailAddon = true
	end
	if select(4, GetAddOnInfo("Postal")) == 1 then
		button:Hide()
		foundOtherMailAddon = true
	end
	if button:GetName() then
		error("Stack overflow.", 2)
	end

	local noop = function() end
	InboxTooMuchMail:Hide()
	InboxTooMuchMail.Show = noop
	InboxTooMuchMail.Hide = noop
	InboxTitleText:Hide()
	SendMailTitleText:Hide()

	-- Timer for mailbox cache updates
	private.cacheFrame = CreateFrame("Frame", nil, MailFrame)
	private.cacheFrame:SetScript("OnEnter", showTooltip)
	private.cacheFrame:SetScript("OnLeave", hideTooltip)
	private.cacheFrame:EnableMouse(true)
	private.cacheFrame.tooltip = L["How many seconds until the mailbox will retrieve new data and you can continue looting mail."]
	private.cacheFrame:Hide()
	private.cacheFrame:SetScript("OnUpdate", function(self, elapsed)
		if not private.waitingForData then
			local seconds = self.endTime - GetTime()
			if seconds <= 0 then
				-- Look for new mail
				-- Sometimes it fails and isn't available at exactly 60-61 seconds, and more like 62-64, will keep rechecking every 1 second
				-- until data becomes available
				if TSM.db.profile.autoCheck then
					private.waitingForData = true
					self.timeLeft = private.recheckTime
					private.cacheFrame.text:SetText(nil)
					CheckInbox()
				else
					self:Hide()
				end
				return
			end
			
			private.cacheFrame.text:SetFormattedText("%d", seconds)
		else
			self.timeLeft = self.timeLeft - elapsed
			if self.timeLeft <= 0 then
				self.timeLeft = private.recheckTime
				CheckInbox()
			end
		end
	end)
	
	private.cacheFrame.text = private.cacheFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	private.cacheFrame.text:SetFont(GameFontHighlight:GetFont(), 30, "THICKOUTLINE")
	private.cacheFrame.text:SetPoint("CENTER", MailFrame, "TOPLEFT", 40, -35)
	
	private.totalMail = MailFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	if isMoP then
		private.totalMail:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -20 + (foundOtherMailAddon and -24 or 0), -30)
	else
		private.totalMail:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -60 + (foundOtherMailAddon and -24 or 0), -18)
	end

	TSM:RegisterEvent("MAIL_CLOSED")
	TSM:RegisterEvent("MAIL_INBOX_UPDATE")
end

-- Deals with auto looting of mail!
function private:StartAutoLooting()
	local total
	private.autoLootTotal, total = GetInboxNumItems()
	if private.autoLootTotal == 0 and total == 0 then return end
	
	if TSM.db.profile.autoCheck and private.autoLootTotal == 0 and total > 0 then
		private.button:SetText(L["Waiting..."])
	end
	
	TSM:RegisterEvent("UI_ERROR_MESSAGE")
	private.button:Disable()
	private.moneyCollected = 0
	private:AutoLoot()
end

function private:AutoLoot()
	-- Already looted everything after the invalid indexes we had, so fail it
	if private.lootIndex > 1 and private.lootIndex > GetInboxNumItems() then
		if private.resetIndex then
			private:StopAutoLooting(true)
		else
			private.resetIndex = true
			private.lootIndex = 1
			private:AutoLoot()
		end
		return
	end
	
	local money, cod, _, items, _, _, _, _, isGM = select(5, GetInboxHeaderInfo(private.lootIndex))
	if not isGM and (not cod or cod <= 0) and ((money and money > 0) or (items and items > 0)) then
		TSMAPI:CancelFrame("mailWaitDelay")
		private.button:SetText(L["Opening..."])
		if money > 0 then
			private.moneyCollected = private.moneyCollected + money
		end
		AutoLootMailItem(private.lootIndex)
	-- Can't grab the first mail, but we have a second so increase it and try again
	elseif GetInboxNumItems() > private.lootIndex then
		private.lootIndex = private.lootIndex + 1
		private:AutoLoot()
	end
end

function private:StopAutoLooting(failed)
	if failed then
		TSM:Print(L["Cannot finish auto looting, inventory is full or too many unique items."])
	end

	private.resetIndex = nil
	private.autoLootTotal = nil
	private.lootIndex = 1
	
	TSM:UnregisterEvent("UI_ERROR_MESSAGE")
	private.button:SetText(L["Open All"])
	private.button:Enable()
	
	--Tell user how much money has been collected if they don't have it turned off in TradeSkillMaster_Mailing options
	if private.moneyCollected and private.moneyCollected > 0 and (not TSM.db.profile.dontDisplayMoneyCollected) then
		TSM:Printf(L["%s Collected"], TSMAPI:FormatTextMoney(private.moneyCollected))
		private.moneyCollected = 0
	end
end

function TSM:UI_ERROR_MESSAGE(event, msg)
	if msg == ERR_INV_FULL or msg == ERR_ITEM_MAX_COUNT then
		-- Try the next index in case we can still loot more such as in the case of glyphs
		private.lootIndex = private.lootIndex + 1
		
		-- If we've exhausted all slots, but we still have <50 and more mail pending, wait until new data comes and keep looting it
		local current, total = GetInboxNumItems()
		if private.lootIndex > current then
			if private.lootIndex > total and total <= 50 then
				private:StopAutoLooting(true)
			else
				private.button:SetText(L["Waiting..."])
			end
			return
		end
		
		TSMAPI:CreateTimeDelay("mailWaitDelay", 0.3, private.AutoLoot)
	end
end

function TSM:MAIL_INBOX_UPDATE()
	local current, total = GetInboxNumItems()
	-- Yay nothing else to loot, so nothing else to update the cache for!
	if private.cacheFrame.endTime and current == total and private.lastTotal ~= total then
		private.cacheFrame.endTime = nil
		private.cacheFrame:Hide()
	-- Start a timer since we're over the limit of 50 items before waiting for it to recache
	elseif (private.cacheFrame.endTime and current >= 50 and private.lastTotal ~= total) or (current >= 50 and private.allowTimerStart) then
		private.resetIndex = nil
		private.allowTimerStart = nil
		private.waitingForData = nil
		private.lastTotal = total
		private.cacheFrame.endTime = GetTime() + 60
		private.cacheFrame:Show()
	end
	
	-- The last item we setup to auto loot is finished, time for the next one
	if not private.isAutoMailing and not private.button:IsEnabled() and private.autoLootTotal ~= current then
		private.autoLootTotal = GetInboxNumItems()
		
		-- If we're auto checking mail when new data is available, will wait and continue auto looting, otherwise we just stop now
		if TSM.db.profile.autoCheck and current == 0 and total > 0 then
			private.button:SetText(L["Waiting..."])
		elseif current == 0 and (not TSM.db.profile.autoCheck or total == 0) then
			private:StopAutoLooting()
		else
			private:AutoLoot()
		end
	end
	
	if total > 0 then
		private.totalMail:SetFormattedText(L["%d mail"], total)
	else
		private.totalMail:SetText(nil)
	end
end

function TSM:MAIL_CLOSED()
	private.resetIndex = nil
	private.allowTimerStart = true
	private.waitingForData = nil
	private:StopAutoLooting()
	
	if select(2, GetInboxNumItems()) == 0 then
		MiniMapMailFrame:Hide()
	end
end

function TSM:IsButtonEnabled()
	return private.button:IsEnabled()
end

function TSM:EnableButton()
	return private.button:Enable()
end
-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Shopping - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_shopping.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local AutoMail = TSM:NewModule("AutoMail", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Mailing") -- loads the localization table

local private = {}

local isMoP = select(4, GetBuildInfo()) >= 50000

-- -------------------------------GUI FUNCTIONS-------------------------------

function AutoMail:OnEnable()
	local button = CreateFrame("Button", nil, MailFrame, "UIPanelButtonTemplate")
	button:SetHeight(26)
	button:SetWidth(255)
	button:SetText(L["TradeSkillMaster_Mailing: Auto-Mail"])
	button:SetFrameStrata("HIGH")
	button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetText(self.tooltip, 1, 1, 1, nil, true)
			GameTooltip:Show()
		end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnHide", function()
			private:StopAutoMailing()
		end)
	button:SetScript("OnClick", function(self)
			private:StartAutoMailing()
		end)
	if isMoP then
		button:SetPoint("TOPLEFT", 55, 25)
	else
		button:SetPoint("TOPLEFT", 70, 13)
	end
	button.tooltip = L["Runs TradeSkillMaster_Mailing's auto mailer, the last patch of mails will take ~10 seconds to send.\n\n[WARNING!] You will not get any confirmation before it starts to send mails, it is your own fault if you mistype your bankers name."]
	private.button = button
	
	if ElvUI and ElvUI[1] then
		ElvUI[1]:GetModule("Skins"):HandleButton(button)
	end
end

function private:ShowSendingFrame()
	if not SendMailScrollFrame then return end
	if not private.sendingFrame then
		local frame = CreateFrame("Frame", nil, SendMailScrollFrame)
		frame:SetAllPoints(SendMailScrollFrame)
		frame:SetPoint("TOPLEFT", -6, 6)
		frame:SetPoint("BOTTOMRIGHT", 30, -6)
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			tile = false,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 24,
			insets = {left = 4, right = 4, top = 4, bottom = 4},
		})
		frame:SetBackdropColor(0, 0, 0.05, 1)
		frame:SetBackdropBorderColor(0,0,1,1)
		frame:SetFrameLevel(SendMailScrollFrame:GetFrameLevel() + 10)
		frame:EnableMouse(true)
		frame:SetScript("OnShow", function() private.button:Disable() end)
		frame:SetScript("OnHide", function() private.button:Enable() end)
		
		local tFile, tSize = GameFontNormalLarge:GetFont()
		local titleText = frame:CreateFontString(nil, "Overlay", "GameFontNormalLarge")
		titleText:SetFont(tFile, tSize-2, "OUTLINE")
		titleText:SetTextColor(1, 1, 1, 1)
		titleText:SetPoint("CENTER", frame, "CENTER", 0, 0)
		titleText:SetText(L["TradeSkillMaster_Mailing - Sending...\n\n(the last mail may take several moments)"])
		private.sendingFrame = frame
	end
	private.sendingFrame:Show()
end



-- -----------------------------AutoMail FUNCTIONS-----------------------------

-- starts the auto mailing
function private:StartAutoMailing()
	if not TSM:IsButtonEnabled() then
		TSM:Print(L["Please wait until you are done opening mail before sending mail."])
		return
	end
	
	MailFrameTab2:Click()
	TSM.Config:UpdateItemsInGroup()
	private:ShowSendingFrame()
	private.currentTarget = nil
	private.mailTargets = {}
	
	-- go through our bags and add everything of interest to the private.mailTargets table
	for bag=0, 4 do
		for slot=1, GetContainerNumSlots(bag) do
			local itemID = TSMAPI:GetItemID(GetContainerItemLink(bag, slot))
			local target = TSM.db.factionrealm.mailItems[itemID] or TSM.Config.itemsInGroup[itemID]
			if target and not TSM.Config:IsSoulbound(bag, slot, itemID) then
				target = strlower(target)
				private.mailTargets[target] = private.mailTargets[target] or {}
				private.mailTargets[target][itemID] = true
			end
		end
	end

	-- we don't want to try and send mail to ourselves
	private.mailTargets[strlower(UnitName("player"))] = nil
	
	-- check if we have a target (ie have anything to send)
	if next(private.mailTargets) and not private.button:GetName() then
		-- create a recurring timer for sending mail
		TSMAPI:CreateTimeDelay("autoMailDelay", 0, private.SendNextMail, TSM.db.profile.autoMailSendDelay)
	else
		TSM:Print(L["Nothing to mail!"])
		private:StopAutoMailing()
	end
end

-- processes and sends off a mail
function private:SendNextMail()
	private:SendOffMail()

	-- get a mail target
	private.currentTarget = next(private.mailTargets)
	
	-- if there's nobody to mail to, we are done
	if not private.currentTarget or private.button:GetName() then
		private:StopAutoMailing(true)
		return
	end
	
	-- fill the mail with items
	local hasMoreItems = private:FillMail(private.mailTargets[private.currentTarget])
	
	-- removes this mail target if there's no more items to mail to them
	if not hasMoreItems then
		private.mailTargets[private.currentTarget] = nil
	end
	
	-- sends off the mail
	private:SendOffMail(true)
end

-- fills the current mail with items to be sent to the target
function private:FillMail(items)
	if private:GetNumPendingAttachments() ~= 0 or not items then return true end
	
	private:UpdateItemLocationInfo()
	for itemID in pairs(items) do
		if private.locationInfo[itemID] then
			for i=#private.locationInfo[itemID], 1, -1 do
				local bag, slot, count = unpack(private.locationInfo[itemID][i])
				PickupContainerItem(bag, slot)
				ClickSendMailItemButton()
				if private:GetNumPendingAttachments() == ATTACHMENTS_MAX_SEND then
					return true
				end
			end
			
			if TSM.db.profile.sendItemsIndividually then
				return true
			end
		end
	end
end

-- sends off the current mail
function private:SendOffMail(doPrint)
	if private:GetNumPendingAttachments() == 0 or not private.currentTarget then return end
	
	if doPrint then
		TSM:Printf(L["Mailed items off to %s!"], private.currentTarget)
	end
	
	SendMailNameEditBox:SetText(private.currentTarget)
	SendMail(private.currentTarget, SendMailSubjectEditBox:GetText() or "Mass mailing", "")
end

-- stops sending mail
function private:StopAutoMailing(done)
	if private.button:GetName() then error("Invalid button name.") end
	if private.sendingFrame then private.sendingFrame:Hide() end
	MailFrameTab1:Click()
	TSM:EnableButton()
	TSMAPI:CancelFrame("autoMailDelay")
	TSMAPI:CancelFrame("autoMailRecheckDelay")
	
	if done and TSM.db.profile.autoMailRecheckTime then
		TSMAPI:CreateTimeDelay("autoMailRecheckDelay", TSM.db.profile.autoMailRecheckTime * 60, private.StartAutoMailing)
		TSM:Printf(L["Restarting AutoMail in %s minutes."], TSM.db.profile.autoMailRecheckTime)
	end
end


-- -------------------------------UTIL FUNCTIONS-------------------------------

-- gets the locations of every item in the player's bags
function private:UpdateItemLocationInfo()
	private.locationInfo = {}
	for bag=0, 4 do
		for slot=1, GetContainerNumSlots(bag) do
			local itemID = TSMAPI:GetItemID(GetContainerItemLink(bag, slot))
			local count, locked = select(2, GetContainerItemInfo(bag, slot))
			if itemID and count and not locked then
				private.locationInfo[itemID] = private.locationInfo[itemID] or {}
				tinsert(private.locationInfo[itemID], {bag, slot, count})
			end
		end
	end
end

-- returns the number of items currently attached to the mail
function private:GetNumPendingAttachments()
	local totalAttached = 0
	for i=1, ATTACHMENTS_MAX_SEND do
		if GetSendMailItem(i) then
			totalAttached = totalAttached + 1
		end
	end
	
	return totalAttached
end
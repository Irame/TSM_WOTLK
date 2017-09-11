-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Destroying - AddOn by Geemoney							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_destroying.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the license holder (Sapu) via email at	sapu94@gmail.com with any	  --
--		questions or concerns regarding this license.				 								  --
-- ------------------------------------------------------------------------------------- --

-- setup
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_Destroying", "AceEvent-3.0", "AceConsole-3.0")

local AceGUI = LibStub("AceGUI-3.0")

-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 
TSM.version = GetAddOnMetadata("TradeSkillMaster_Destroying","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_Destroying", "Version") -- current version of the addon

qualityColors = { --I stole this from Sapu....
	[0]="9d9d9d",
	[1]="ffffff",
	[2]="1eff00",
	[3]="0070dd",
	[4]="a335ee",
	[5]="ff8000",
	[6]="e6cc80",
}

-- default values for the savedDB
-- list of different types of saved variables at the top of http://www.wowace.com/addons/ace3/pages/api/ace-db-3-0/

local savedDBDefaults = {
	-- any global 
	global = {
        xPos     = 800,
        yPos     = -800,
        anchor   = "TOPLEFT",
        dMode    = "Normal",
        safeList = {},
        filter = "mats"
	},
	
	-- data that is stored per realm/faction combination
	factionrealm = {
        --Globals for store destroying data-- 
		Prospecting = { Day = {}, Mat = {} },
		Milling     = { Day = {}, Mat = {} },
		DE          = { Day = {}, Mat = {} },
        SafeTable   = {  }
	},
    
	-- data that is stored per user profile
	profile = {},
}

-- Called once the player has loaded into the game
-- Anything that needs to be done in order to initialize the addon should go here
local destroybtn
function TSM:OnEnable()

	for name, module in pairs(TSM.modules) do TSM[name] = module end
     
	-- load the saved variables table into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_DestroyingDB", savedDBDefaults, true)
	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Destroying", TSM.version, GetAddOnMetadata("TradeSkillMaster_Destroying", "Author"),GetAddOnMetadata("TradeSkillMaster_Destroying", "Notes"))	
	TSMAPI:RegisterIcon(L["Destroying"], "Interface\\Icons\\INV_Gizmo_RocketBoot_Destroyed_02",function(...) TSM.GUI:Load(...) end, "TradeSkillMaster_Destroying")
    
    TSMAPI:RegisterSlashCommand("destroy", TSM.getDestroyBtn, L["Displays the destroy button"], true)
    
    --delete old tables--
    if TSM.db.factionrealm.prospectingData then TSM.db.factionrealm.prospectingData = nil end
    if TSM.db.factionrealm.millingData then TSM.db.factionrealm.millingData = nil end
    if TSM.db.factionrealm.deData then TSM.db.factionrealm.deData = nil end
    
end

function TSM:getDestroyBtn() TSM.destroybtn:Show() end

function TSM:IsDestroyable(bag, slot, action)

	local slotID = tostring(bag) .. tostring(slot)
	
	if not scanTooltip then
		scanTooltip = CreateFrame("GameTooltip", "TSMAucScanTooltip", UIParent, "GameTooltipTemplate")
		scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	scanTooltip:ClearLines()
	scanTooltip:SetBagItem(bag, slot)
	
	for id=1, scanTooltip:NumLines() do
		local text = _G["TSMAucScanTooltipTextLeft" .. id]
        
		--decide what to look for--
		if action == "Prospectable" then
			if text and text:GetText() == ITEM_PROSPECTABLE then		
				return true
			end
		elseif action == "Millable" then	
			if text and text:GetText() == ITEM_MILLABLE then			
				return true
			end
		end --end elseif
		
	end
    
	return false
end
   
-- FastDestroyButton
do

	local prospecting = 31252
	local milling = 51005
	local disenchanting = 13262

	local Type, Version = "TSMFastDestroyButton", 2
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
	
    local lootopened = false
    local LootFrameIsVisible = false

    local lootOpened = CreateFrame("frame")
    lootOpened:Hide()
    lootOpened:SetScript("OnEvent", function(self)  LootFrameIsVisible = true     end)
    lootOpened:SetScript("OnShow",  function(self)  self:RegisterEvent("LOOT_OPENED")   end)
    lootOpened:SetScript("OnHide",  function(self)  self:UnregisterEvent("LOOT_OPENED") end)

    local lootClosed = CreateFrame("frame")
    lootClosed:Hide()    
    lootClosed:SetScript("OnEvent", function(self)  LootFrameIsVisible = false    end)
    lootClosed:SetScript("OnShow",  function(self)  self:RegisterEvent("LOOT_CLOSED")   end)
    lootClosed:SetScript("OnHide",  function(self)  self:UnregisterEvent("LOOT_CLOSED") end)

    
    -- waits until some event
	local function Delay(self)

		if self.button.mode == "slow" then
            if not lootopened and LootFrameIsVisible then lootopened = true end
            if GetSpellCooldown(self.button.spell) == 0 and not UnitCastingInfo("player") 
                and ( lootopened and not LootFrameIsVisible ) then
                self:Hide()
                self.button:SetDisabled(false)
                lootopened = false
            end
            
		else
            if not lootopened and LootFrameIsVisible then lootopened = true end
			if self.wait == "cd" then -- wait for the cd to be up on the spell
                self.endTime = self.endTime or GetTime() + 1
                if GetSpellCooldown(self.button.spell) == 0 and GetTime() > self.endTime then
                    self.endTime = nil
                    self:Hide()
                    self.button:SetDisabled(false)
                end
			elseif self.wait == "lootopen" then -- wait for the loot window to open
				if (self.button.mode == "fast" and not UnitCastingInfo("player")) 
                or (self.button.mode == "normal" and LootFrameIsVisible) then
					self:Hide()
					self.button:SetDisabled(false)
				end
			elseif self.wait == "lootclosed" then -- wait for the loot window to close
                 if ( lootopened and not LootFrameIsVisible ) then
					self:Hide()
					self.button:SetDisabled(false)
				end
			end
		end	--end big if	
	end--end function delay
	
	local function CreateDelay(button)
		button.delay = CreateFrame("Frame")
		button.delay.button = button
		button.delay:Hide()
		button.delay:SetScript("OnUpdate", Delay)
	end
	
	local function PreClick(self)
        
        --Slow Destroy--
		if self.obj.mode == "slow" then
			local target = self.obj.GetLocations(self.currentTarget or {bag=-1, slot=-1})		
			self.currentTarget = target
			if target and target.bag ~= -1 and target.slot ~= -1  then
                self:SetAttribute("type1", "macro")
                self:SetAttribute("macrotext1", format("/cast !%s;\n/use %s %s;", self.obj.spell, target.bag, target.slot ))
                self.obj:SetDisabled(true) 
                self.obj.delay:Show()
			else
				self.obj:Fire("Finished")
			end		
		elseif self.obj.mode == "normal"  or self.obj.mode == "fast" then
			
			--begin Sapu's Code
			if not SpellIsTargeting() then
                if LootFrameIsVisible then
                    self.obj:SetDisabled(true)
					self.obj.delay.wait = "lootclosed"
					self.obj.delay:Show()
				elseif self.obj.spell then
					self.isCasting = true 
					self:SetAttribute("type1", "macro")
					self:SetAttribute("macrotext1", format("/cast %s", self.obj.spell))
					self.attribute = "cast"
					if UnitCastingInfo("player") then
						self.obj:SetDisabled(true)
						self.obj.delay.wait = "lootopen"
						self.obj.delay:Show()
					end
				end
			else			
				self.isCasting = false
				local target = self.obj.GetLocations(self.currentTarget or {bag=-1, slot=-1})
				self.currentTarget = target
				if target and target.bag ~= -1 and target.slot ~= -1 then
                    self.nextTarget = CopyTable(target)
					self:SetAttribute("type1", "macro")
					self:SetAttribute("macrotext1", format("/use %s %s", target.bag, target.slot))
					self.attribute = "use"
					self.obj:SetDisabled(true)
					self.obj.delay.wait = "cd"
					self.obj.delay:Show()
				else
                    self:SetAttribute("type1", "macro")
                    string.format("/stopmacro [channeling]")
					self.obj:Fire("Finished")
				end
			end
			--end Sapu's code
            
		end

	end
    

    local function showListeners()
        if not lootOpened:IsVisible() then lootOpened:Show() end
        if not lootClosed:IsVisible() then lootClosed:Show() end
    end
        
    local function hideListeners()
        lootOpened:Hide()
        lootClosed:Hide()    
    end
    
	local methods = {
		-- gets called when the button is added to a frame (ie :AddChild())
		-- simply initializes the button
		["OnAcquire"] = function(self)
			CreateDelay(self)
            self:SetHeight(24)
			self:SetWidth(200)
			self:SetDisabled(false)
			self:SetText()
			self.GetLocations = function() return {} end
			self.mode = "normal"
            showListeners()
		end,

		-- gets called when the button is released (ie hidden when the frame is closed)
		["OnRelease"] = function(self)
            self.delay:Hide()
            hideListeners()
		end,

		-- just like the regular AceGUI button's SetText method
		["SetText"] = function(self, text)
			self.frame:SetText(text)
		end,
		
		-- set the spell that the button is going to cast
		["SetSpell"] = function(self, spell)
			if not spell then self.spell = nil; return end
            spell = strlower(spell or "")
            assert(spell == "milling" or spell == "prospecting" or spell == "disenchanting", "Invalid spell name: "
            ..spell..". Expected \"Milling\" or \"Prospecting\" or \"Disenchanting\"")
			
			--to fix localizationg problem--F
			if (spell == "prospecting") then spell = GetSpellInfo (prospecting) end
			if (spell == "milling") then spell = GetSpellInfo (milling) end
			if (spell == "disenchanting") then spell = GetSpellInfo (disenchanting) end

			self.spell = spell
		end,
		
		-- sets what mode the button will operate under (normal / fast)
		["SetMode"] = function(self, mode)
			mode = strlower(mode or "")
			assert(mode == "fast" or mode == "normal" or mode == "slow", "Invalid mode: "..mode..". Expected \"fast\" or \"normal\" or \"slow\"")
			self.mode = mode

		end,

		-- same as the AceGUI button's SetDisabled method
		["SetDisabled"] = function(self, disabled)
			self.disabled = disabled
			if disabled then
				self.frame:Disable()
			else
				self.frame:Enable()
			end


		end,
		
		-- sets the function the button should call to get the next location to destroying at
		["SetLocationsFunc"] = function(self, func)
			assert(type(func) == "function", "Expected function, got "..type(func)..".")
			self.GetLocations = func
		end,
	}
	
	local function Constructor()
		local name = "TSMDestroyingButton" .. AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
		frame:Hide()

		-- sets all the scripts on the button
		frame:EnableMouse(true)
		frame:SetScript("OnEnter", function() frame.obj:Fire("OnEnter") end)
		frame:SetScript("OnLeave", function() frame.obj:Fire("OnLeave") end)
		frame:SetScript("PostClick",function() if frame.attribute == "use" then frame.obj:Fire("PostClick") end end)
		frame:SetScript("PreClick", PreClick)
		
		-- set the edge texture
		frame:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 18,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		})

		-- create and set the normal (non-pressed, non-disabled) texture
		local normalTex = frame:CreateTexture()
		normalTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		normalTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		normalTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		normalTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		frame:SetNormalTexture(normalTex)

		-- create and set the disabled texture
		local disabledTex = frame:CreateTexture()
		disabledTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		disabledTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		disabledTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
		disabledTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		frame:SetDisabledTexture(disabledTex)

		-- create and set the highlight texture
		local highlightTex = frame:CreateTexture()
		highlightTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		highlightTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		highlightTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		highlightTex:SetTexCoord(0.005, 0.994, 0.613, 0.785)
		highlightTex:SetVertexColor(0.3, 0.3, 0.3, 0.7)
		frame:SetHighlightTexture(highlightTex)

		-- create and set the pressed texture
		local pressedTex = frame:CreateTexture()
		pressedTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		pressedTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		pressedTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		pressedTex:SetVertexColor(1, 1, 1, 0.5)
		pressedTex:SetTexCoord(0.0256, 0.743, 0.017, 0.158)
		frame:SetPushedTexture(pressedTex)
		frame:SetPushedTextOffset(0, -2)
		
		-- create and set the text that'll go in the button
		local tFile, tSize = GameFontHighlight:GetFont()
		local fontString = frame:CreateFontString()
		fontString:SetFont(tFile, tSize, "OUTLINE")
		frame:SetFontString(fontString)
		frame:GetFontString():SetPoint("CENTER")
		frame:GetFontString():SetTextColor(1, 0.73, 0, 1)
 
		-- create the widget table that turns this button into an AceGUI widget
		local widget = {
			frame = frame,
			type  = Type
		}
		for method, func in pairs(methods) do
			widget[method] = func
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

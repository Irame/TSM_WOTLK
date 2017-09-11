-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local bankui = TSM:NewModule("bankui", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI librarie

local currentGroup = false
local currentBank = nil
local container = nil
local bagST = nil

local isExpanded = {
    warehousing = false,
    auctioning = false,
    crafting = false
}

local buttonBackdrop = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 12,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
} 

--
--Stolen from TSMMainFrame
--
local function ApplyButtonTextures(button)

	local normalTex = button:CreateTexture()
	normalTex:SetTexture("Interface\\Buttons\\UI-AttributeButton-Encourage-Hilight")
	normalTex:SetPoint("TOPRIGHT", button, "TOPRIGHT", -5, -5)
	normalTex:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 5, 5)
	normalTex:SetTexCoord(0.041, 0.975, 0.129, 1.00)
	button:SetNormalTexture(normalTex)
	
	local disabledTex = button:CreateTexture()
	disabledTex:SetTexture("Interface\\Buttons\\UI-AttributeButton-Encourage-Hilight")
	disabledTex:SetPoint("TOPRIGHT", button, "TOPRIGHT", -5, -5)
	disabledTex:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 5, 5)
	disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
	disabledTex:SetTexCoord(0.049, 0.931, 0.008, 0.121)
	button:SetDisabledTexture(disabledTex)
	
	local highlightTex = button:CreateTexture()
	highlightTex:SetTexture("Interface\\Buttons\\UI-AttributeButton-Encourage-Hilight")
	highlightTex:SetPoint("TOPRIGHT", button, "TOPRIGHT", -5, -5)
	highlightTex:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 5, 5)
	highlightTex:SetTexCoord(0, 1, 0, 1)
	highlightTex:SetVertexColor(0.9, 0.9, 0.9, 0.9)
	button:SetHighlightTexture(highlightTex)
	
	local pressedTex = button:CreateTexture()
	pressedTex:SetTexture("Interface\\Buttons\\UI-AttributeButton-Encourage-Hilight")
	pressedTex:SetPoint("TOPRIGHT", button, "TOPRIGHT", -5, -5)
	pressedTex:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 5, 5)
	pressedTex:SetVertexColor(1, 1, 1, 0.5)
	pressedTex:SetTexCoord(0.035, 0.981, 0.014, 0.670)
	button:SetPushedTextOffset(0, -1)
	button:SetPushedTexture(pressedTex)
end
local function createButton(text, parent, func)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetText(text)
    btn:SetHeight(20)
    btn:SetWidth(150)
    btn:SetBackdrop(buttonBackdrop)
    ApplyButtonTextures(btn)
    return btn
end

local function createCloseButton(text, parent, func)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetText(text)
    btn:SetHeight(20)
    btn:SetWidth(20)
    btn:SetBackdrop(buttonBackdrop)
    ApplyButtonTextures(btn)
    return btn
end

local tradeSkills = {
        {name="Enchanting", spellID=7411}, 
        {name="Inscription", spellID=45357},
        {name="Jewelcrafting", spellID=25229}, 
        {name="Alchemy", spellID=2259},
        {name="Blacksmithing", spellID=2018}, 
        {name="Leatherworking", spellID=2108},
        {name="Tailoring", spellID=3908}, 
        {name="Engineering", spellID=4036},
        {name="Cooking", spellID=2550}
    }

--Sapu wrote this one.
local function DoCellUpdate(_, cellFrame, _, _, _, rowNum, _, isVisible, st)

    if not isVisible then
        -- frame isn't shown so clear the text and hide the icon
        if cellFrame.icon then cellFrame.icon:Hide() end
        return
    end
    
    
    local rowdata = st:GetRow(rowNum)
    cellFrame.text:SetText("")

    -- make the icon if it doesn't already exist
    if not cellFrame.icon then
            local icon = CreateFrame("Button", nil, cellFrame)
            icon:SetPoint("TOPLEFT")
            icon:SetPoint("BOTTOMRIGHT")
            icon:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
            icon:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
            icon:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
            icon:SetScript("OnClick", function(self)
                -- they clicked the icon!
                local data = st:GetRow(rowNum)
                if isExpanded [strlower(data.name)] then
                    isExpanded [strlower(data.name)] = false
                else
                    isExpanded [strlower(data.name)] = true
                end
                bankui:updateST()
                -- toggle this row as being expanded / collapsed (adjust your table)
                -- update the scrolling table (call your new update function)
            end)
            cellFrame.icon = icon
    end
  
    -- check if this is a title row or not
    if rowdata.isTitle then
            -- this is a title row so show the button
            cellFrame.icon:Show() 
            -- set the texture of the icon to either a plus or minus as appropriate
            local data = st:GetRow(rowNum)
            if isExpanded[strlower(data.name)] then
                    cellFrame.icon:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
                    cellFrame.icon:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
                    cellFrame.icon:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-Hilight", "ADD")
            else
                    cellFrame.icon:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
                    cellFrame.icon:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
                    cellFrame.icon:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
            end
    else
            -- not a title row so hide the icon
            cellFrame.icon:Hide()
    end
end

function bankui:getBankFrame(bank)
    currentBank = bank
    if BagnonFrameguildbank and BagnonFrameguildbank:IsVisible() then
        return BagnonFrameguildbank
    elseif BagnonFramebank and BagnonFramebank:IsVisible() then
        return BagnonFramebank
    elseif GuildBankFrame and GuildBankFrame:IsVisible() then
        return GuildBankFrame
    elseif BankFrame and BankFrame:IsVisible() then
        return BankFrame
    elseif (famBankFrame and famBankFrame:IsVisible()) then
        return famBankFrame
    elseif (ARKINV_Frame4 and ARKINV_Frame4:IsVisible()) then 
        return ARKINV_Frame4
    elseif (ARKINV_Frame3 and ARKINV_Frame3:IsVisible())then
        return ARKINV_Frame3
     elseif (TukuiBank and TukuiBank:IsVisible())then
        return TukuiBank
     elseif (LUIBank and LUIBank:IsVisible())then
        return LUIBank
    end
    
    return nil
end

function bankui:getFrame(frameType)
    
    container = CreateFrame("Frame", nil, UIParent)
    container:Raise()
    
    --size--
    container:SetWidth(250)
    container:SetHeight(450)

    --for moving and resizing--
    container:SetMovable(true)
    container:EnableMouse(true)
    container:SetResizable(true)
    container:SetMaxResize(500, 900) -- Set the maximum dimensions this frame can be resized to. 
    container:SetMinResize(250, 450) -- Set the minimum dimensions this frame can be resized to. 
    container:SetScript("OnMouseDown", container.StartMoving)
    container:SetScript("OnMouseUp", container.StopMovingOrSizing)

    --clamp to bankframe--
    if frameType and frameType:IsVisible() then
        container:SetPoint("TOPLEFT", frameType, "TOPRIGHT", 40, -10)
    else
        container:SetPoint("TOPLEFT", 500,-100, "TOPRIGHT", 40, 0)
    end
    
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 24,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
 
    container:SetBackdropColor(0, 0, 0.05, 1)
    container:SetBackdropBorderColor(0,0,1,1)
    
    
    local function SizerSE_OnMouseDown(frame)
        frame:GetParent():StartSizing("BOTTOMRIGHT")
    end
     
    local function MoverSizer_OnMouseUp(mover)
        local frame = mover:GetParent()
        frame:StopMovingOrSizing()
    end
    
    local sizer_se = CreateFrame("Frame", nil, container)
    sizer_se:SetPoint("BOTTOMRIGHT")
    sizer_se:SetWidth(23)
    sizer_se:SetHeight(23)
    sizer_se:EnableMouse(true)
    sizer_se:SetScript("OnMouseDown",SizerSE_OnMouseDown)
    sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

    local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
    line1:SetWidth(14)
    line1:SetHeight(14)
    line1:SetPoint("BOTTOMRIGHT", -6, 6)
    line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    local x = 0.1 * 14/17
    line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

    local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
    line2:SetWidth(8)
    line2:SetHeight(8)
    line2:SetPoint("BOTTOMRIGHT", -6, 6)
    line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    local x = 0.1 * 8/17
    line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)
    
    --titlebar--
    container.titleBar = CreateFrame("Frame", nil, container)
    container.titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 24,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    
    container.titleBar:SetBackdropColor(0, 0, 0.05, 1)
    container.titleBar:SetBackdropBorderColor(0,0,1,1)

    container.titleBar:SetWidth(250)
    container.titleBar:SetHeight(30)

    container.titleBar:SetPoint("TOP", 0, 12)

    container.title = container.titleBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    container.title:SetPoint("TOP", 0, -10)
    container.title:SetText(L["TradeSkillMaster_Warehousing"])
    
    container.btnClose = createCloseButton(" X",container,nil)
    container.btnClose:SetPoint("BOTTOMLEFT", container, "TOPRIGHT", -25, -15)
    
    --ScrollTable--
    bankui:DrawScrollFrame(container)
    
    --Buttons--
    container.btnToBank = createButton(L["Move Group To Bank"],container,nil)
    container.btnToBank:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 50, 80)
    
    
    container.btnToBags = createButton(L["Move Group To Bags"],container,nil)
    container.btnToBags:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 50, 60)
   
    
    container.btnEmpty = createButton(L["Empty Bags"],container,nil)
    container.btnEmpty:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 50, 30)
    
   
    container.btnRestore = createButton(L["Restore Bags"],container,nil)
    container.btnRestore:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 50, 10)
    
    bankui:updateButtons()
    
    return container
end

function bankui:updateButtons()
   
    ------------------
    -- Move to Bank --
    ------------------
    container.btnToBank:SetScript("OnClick", function(self) 
        if not currentGroup then return end
        TSM.move:moveGroup("bags",currentBank,currentGroup) 
    end)
    
     -------------------
     -- Move to Bags  --
     -------------------
    container.btnToBags:SetScript("OnClick", function(self)
        if not currentGroup then return end        
        TSM.move:moveGroup(currentBank,"bags",currentGroup)       
    end)
    
    --------------
    --these work--
    --------------
    container.btnEmpty:SetScript("OnClick", function(self) TSM.move:moveGroup("bags", currentBank,"all") end)
    
    container.btnRestore:SetScript("OnClick", function(self) 
        TSM.move:moveGroup(currentBank,"bags", "restore","restore") 
        TSM.db.factionrealm.BagState = {}
    end)
    
    container.btnClose:SetScript("OnClick", function(self) 
        if container then container:Hide() end
        TSM.db.global.isBankui = false
        TSM:Print("You have closed the bankui. Use ' \\tsm bankui ' to view again.")
    end)
end

function bankui:resetPoints(frameType,container)
    if frameType and frameType:IsVisible() then
        container:SetPoint("TOPLEFT", frameType, "TOPRIGHT", 40, -10)
    else
        container:SetPoint("TOPLEFT", 500,-100, "TOPRIGHT", 40, 0)
    end
end

function bankui:DrawScrollFrame (container)

    local ROW_HEIGHT = 20
    local stCols

    stCols ={
        {name="", width=.1, DoCellUpdate=DoCellUpdate},
        {name="Group Name", width=.9},
    }

    local function GetSTColInfo(width)
        local colInfo =CopyTable(stCols)
        for i=1, #colInfo do
                colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end

    bagST = TSMAPI:CreateScrollingTable(GetSTColInfo(container:GetWidth()))
    bagST:EnableSelection(true)
    bagST.frame:SetParent(container)
    bagST.frame:SetPoint("BOTTOMLEFT", container, 10, container:GetHeight()*.25)
    bagST.frame:SetPoint("TOPRIGHT", container, -10, -30)
    bagST.frame:SetScript("OnSizeChanged", function(_,width, height)
            bagST:SetDisplayCols(GetSTColInfo(width))
            bagST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
        end)
        
    bankui:updateST()  
    
    bagST:RegisterEvents({
        ["OnClick"] = function(self, _, data, _, _, rowNum, column, st, button)
            if button == "LeftButton" then
                if not rowNum then return end
                if not currentGroup or currentGroup ~= data[rowNum].name then
                    currentGroup = data[rowNum].name
                else
                    currentGroup = false
                end
            end
            
        end,
        ["OnEnter"] = function(_, self, data, _, _, rowNum)
            if not rowNum then return end
        end,
        ["OnLeave"] = function()
            
        end
        
    })

    bagST:Show()	
end

--should I localize??
function bankui:updateST()

    local stTable= {}
    
    table.insert (stTable,  bankui:createRow(L["Warehousing"],"Warehousing",true))    
    if isExpanded["warehousing"] then
        local data = TSM.db.factionrealm.WarehousingGroups
        for name, t in pairs(data) do
            table.insert (stTable, bankui:createRow(t.name,"Warehousing:"..t.name,false))
        end
    end
    
    table.insert (stTable,  bankui:createRow(L["Auctioning"],"Auctioning",true))
    if isExpanded["auctioning"] then
        local data = TSMAPI:GetData("auctioningGroups")
        if data then
            for name, t in pairs(data) do
                table.insert (stTable, bankui:createRow(name,"Auctioning:"..name,false))
            end
        else
            TSM:Print("Auctioning may not be installed.")
        end
    end
    
    table.insert (stTable,  bankui:createRow(L["Crafting"],"Crafting",true))
    if isExpanded["crafting"] then
        for _,prof in ipairs(tradeSkills) do
            total,_ = TSMAPI:GetData("shopping", prof.name)
            if total and #total > 0 then 
                table.insert (stTable, bankui:createRow(GetSpellInfo(prof.spellID),"Crafting:"..GetSpellInfo(prof.spellID),false))     
            end
        end
    end
    bagST:SetData(stTable)
    bagST:Refresh()
end

function bankui:createRow(data,grpname,title)
	--local module,grp = strsplit(":",grpName)
    --print (d)
    return 
	{
		cols = {
            {
				value = function() end,
				args = {},
			},	
			{
				value = function(data) if data then return data end end,
				args = {data},
			},	
		},
        name = grpname,
        isTitle=title,--set to false if not title row
	}
end

function bankui:getWarehouseTable(grp)
    for i,v in ipairs (TSM.db.factionrealm.WarehousingGroups) do 
        if v.name == grp then 
            return v.data,i
        end
    end
end

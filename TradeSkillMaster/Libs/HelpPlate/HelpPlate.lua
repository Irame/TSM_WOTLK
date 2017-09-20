HELP_BUTTON_NORMAL_SIZE = 46;
HELP_BUTTON_LARGE_SIZE = 55;

HELP_PLATE_BUTTONS = {};
function HelpPlate_GetButton()
    local frame;
    local i = 1;
    for i=1, #HELP_PLATE_BUTTONS do
        local button = HELP_PLATE_BUTTONS[i];
        if ( not button:IsShown() ) then
            frame = button;
            break;
        end
    end

    if ( not frame ) then
        frame = CreateFrame( "Button", nil, HelpPlate, "HelpPlateButton" );
        frame.box = CreateFrame( "Frame", nil, HelpPlate, "HelpPlateBox" );
        frame.boxHighlight = CreateFrame( "Frame", nil, HelpPlate, "HelpPlateBoxHighlight" );
        table.insert( HELP_PLATE_BUTTONS, frame );
    end
    frame.tooltipDir = "RIGHT";
    frame:SetSize(HELP_BUTTON_NORMAL_SIZE, HELP_BUTTON_NORMAL_SIZE);

    return frame;
end

function HelpPlateBox_OnLoad(self)
    if self.Textures == nil then return end -- hack => buggy
    for i=1, #self.Textures do
        self.Textures[i]:SetVertexColor( 1, 0.82, 0 );
    end
end

HELP_PLATE_CURRENT_PLATE = nil;
function HelpPlate_Show( self, parent, mainHelpButton, userToggled )
    if ( HELP_PLATE_CURRENT_PLATE ) then
        HelpPlate_Hide();
    end

    HELP_PLATE_CURRENT_PLATE = self;
    HELP_PLATE_CURRENT_PLATE.mainHelpButton = mainHelpButton;
    for i = 1, #self do
        if ( not self[i].MinLevel or (UnitLevel("player") >= self[i].MinLevel) ) then
            local button = HelpPlate_GetButton();
            button:ClearAllPoints();
            button:SetPoint( "TOPLEFT", HelpPlate, "TOPLEFT", self[i].ButtonPos.x, self[i].ButtonPos.y );
            button.tooltipDir = self[i].ToolTipDir;
            button.toolTipText = self[i].ToolTipText;
            button.viewed = false;
            button:Show();
            if ( not userToggled ) then
                button.BigI:Show();
                button.Ring:Show();
                button.Pulse:Play();
            else
                button.BigI:Hide();
                button.Ring:Hide();
                button.Pulse:Stop();
            end

            button.box:ClearAllPoints();
            button.box:SetSize( self[i].HighLightBox.width, self[i].HighLightBox.height );
            button.box:SetPoint( "TOPLEFT", HelpPlate, "TOPLEFT", self[i].HighLightBox.x, self[i].HighLightBox.y );
            button.box:Show();

            button.boxHighlight:ClearAllPoints();
            button.boxHighlight:SetSize( self[i].HighLightBox.width, self[i].HighLightBox.height );
            button.boxHighlight:SetPoint( "TOPLEFT", HelpPlate, "TOPLEFT", self[i].HighLightBox.x, self[i].HighLightBox.y );
            button.boxHighlight:Hide();
        end
    end
    HelpPlate:SetPoint( "TOPLEFT", parent, "TOPLEFT", self.FramePos.x, self.FramePos.y );
    HelpPlate:SetSize( self.FrameSize.width, self.FrameSize.height );
    HelpPlate.userToggled = userToggled;
    HelpPlate:Show();
end

function HelpPlate_Hide(userToggled)
    if (not userToggled) then
        for i = 1, #HELP_PLATE_BUTTONS do
            local button = HELP_PLATE_BUTTONS[i];
            button.tooltipDir = "RIGHT";
            button.box:Hide();
            button:Hide();
        end
        HELP_PLATE_CURRENT_PLATE = nil;
        HelpPlate:Hide();
        return
    end

    -- else animate out
    -- look in HelpPlate_Button_AnimGroup_Show_OnFinished for final cleanup code
    if ( HELP_PLATE_CURRENT_PLATE ) then
        for i = 1, #HELP_PLATE_BUTTONS do
            local button = HELP_PLATE_BUTTONS[i];
            button.tooltipDir = "RIGHT";
            if ( button:IsShown() ) then
                if ( button.animGroup_Show:IsPlaying() ) then
                    button.animGroup_Show:Stop();
                end
                button.animGroup_Show:SetScript("OnFinished", HelpPlate_Button_AnimGroup_Show_OnFinished);
                button.animGroup_Show.translate:SetDuration(0.3);
                button.animGroup_Show.alpha:SetDuration(0.3);
                button.animGroup_Show:Play();
            end
        end
    end
end

function HelpPlate_IsShowing(plate)
    return (HELP_PLATE_CURRENT_PLATE == plate);
end

function Main_HelpPlate_Button_OnEnter(self)
    HelpPlateTooltip.ArrowRIGHT:Show();
    HelpPlateTooltip.ArrowGlowRIGHT:Show();
    HelpPlateTooltip:SetPoint("LEFT", self, "RIGHT", 10, 0);
    HelpPlateTooltip.Text:SetText(MAIN_HELP_BUTTON_TOOLTIP)
    HelpPlateTooltip:Show();
end

function Main_HelpPlate_Button_OnLeave(self)
    HelpPlateTooltip.ArrowRIGHT:Hide();
    HelpPlateTooltip.ArrowGlowRIGHT:Hide();
    HelpPlateTooltip:ClearAllPoints();
    HelpPlateTooltip:Hide();
end

function HelpPlate_Button_OnLoad(self)
    self.animGroup_Show = self:CreateAnimationGroup();
    self.animGroup_Show.translate = self.animGroup_Show:CreateAnimation("Translation");
    self.animGroup_Show.translate:SetSmoothing("IN");
    self.animGroup_Show.alpha = self.animGroup_Show:CreateAnimation("Alpha");
    self.animGroup_Show.alpha:SetChange(-1);
    self.animGroup_Show.alpha:SetSmoothing("IN");
    self.animGroup_Show.parent = self;
end

function HelpPlate_Button_AnimGroup_Show_OnFinished(self)
    -- hide the parent button
    self.parent:Hide();
    self:SetScript("OnFinished", nil);

    -- lets see if we can cleanup the help plate now.
    for i = 1, #HELP_PLATE_BUTTONS do
        local button = HELP_PLATE_BUTTONS[i];
        if ( button:IsShown() ) then
            return;
        end
    end

    -- we are done animating. lets hide everything
    for i = 1, #HELP_PLATE_BUTTONS do
        local button = HELP_PLATE_BUTTONS[i];
        button.box:Hide();
        button.boxHighlight:Hide();
    end

    HELP_PLATE_CURRENT_PLATE = nil;
    HelpPlate:Hide();
end

function HelpPlate_Button_OnShow(self)
    local point, relative, relPoint, xOff, yOff = self:GetPoint();
    self.animGroup_Show.translate:SetOffset( (-1*xOff), (-1*yOff) );
    self.animGroup_Show.translate:SetDuration(0.5);
    self.animGroup_Show.alpha:SetDuration(0.5);
    self.animGroup_Show:Play(true);
end

function HelpPlate_Button_OnEnter(self)
    HelpPlate_TooltipHide();

    if ( self.tooltipDir == "UP" ) then
        HelpPlateTooltip.ArrowUP:Show();
        HelpPlateTooltip.ArrowGlowUP:Show();
        HelpPlateTooltip:SetPoint("BOTTOM", self, "TOP", 0, 10);
    elseif ( self.tooltipDir == "DOWN" ) then
        HelpPlateTooltip.ArrowDOWN:Show();
        HelpPlateTooltip.ArrowGlowDOWN:Show();
        HelpPlateTooltip:SetPoint("TOP", self, "BOTTOM", 0, -10);
    elseif ( self.tooltipDir == "LEFT" ) then
        HelpPlateTooltip.ArrowLEFT:Show();
        HelpPlateTooltip.ArrowGlowLEFT:Show();
        HelpPlateTooltip:SetPoint("RIGHT", self, "LEFT", -10, 0);
    elseif ( self.tooltipDir == "RIGHT" ) then
        HelpPlateTooltip.ArrowRIGHT:Show();
        HelpPlateTooltip.ArrowGlowRIGHT:Show();
        HelpPlateTooltip:SetPoint("LEFT", self, "RIGHT", 10, 0);
    end
    HelpPlateTooltip.Text:SetText(self.toolTipText)
    HelpPlateTooltip:Show();
    self.box:Hide();
    self.boxHighlight:Show();
    self.Pulse:Stop();
    self.BigI:Hide();
    self.Ring:Hide();
end

function HelpPlate_Button_OnLeave(self)
    HelpPlate_TooltipHide();
    self.box:Show();
    self.boxHighlight:Hide();
    self.viewed = true;

    -- remind the player to use the main button to toggle the help plate
    -- but only if they didn't open it to begin with
    if ( not HelpPlate.userToggled ) then
        for i = 1, #HELP_PLATE_BUTTONS do
            local button = HELP_PLATE_BUTTONS[i];
            if ( button:IsShown() and not button.viewed ) then
                return;
            end
        end
        Main_HelpPlate_Button_OnEnter(HELP_PLATE_CURRENT_PLATE.mainHelpButton);
    end
end

function HelpPlate_TooltipHide()
    HelpPlateTooltip.ArrowUP:Hide();
    HelpPlateTooltip.ArrowGlowUP:Hide();
    HelpPlateTooltip.ArrowDOWN:Hide();
    HelpPlateTooltip.ArrowGlowDOWN:Hide();
    HelpPlateTooltip.ArrowLEFT:Hide();
    HelpPlateTooltip.ArrowGlowLEFT:Hide();
    HelpPlateTooltip.ArrowRIGHT:Hide();
    HelpPlateTooltip.ArrowGlowRIGHT:Hide();
    HelpPlateTooltip:ClearAllPoints();
    HelpPlateTooltip:Hide();
end

﻿--[[
]]

local LootMaster    = LibStub("AceAddon-3.0"):GetAddon("CCLootMaster")

local LOOTBUTTON_MAXNUM = 10
local LOOTBUTTON_HEIGHT = 32
local LOOTBUTTON_PADDING = 6

-- Column for the scrollingTable
local gearBgColor   = {["r"] = 0.15, ["g"] = 0.15, ["b"] = 0.15, ["a"] = 1.0 }
local sstScrollCols = {
       { ["name"] = " ",         ["width"] = 20, ["align"] = "CENTER" },   
       { ["name"] = "Candidate", ["width"] = 100, ["align"] = "LEFT" },    
       { ["name"] = "Rank",      ["width"] = 100, ["align"] = "LEFT" },
       { ["name"] = "Response",  ["width"] = 210, ["align"] = "LEFT",    ["defaultsort"] = "desc", ["sort"] = "desc", ["color"] = {["r"] = 0.25, ["g"] = 1.00, ["b"] = 0.25, ["a"] = 1.0 }, ["sortnext"]=5 }, --, 
       { ["name"] = "Roll",      ["width"] = 35,  ["align"] = "RIGHT",   ["defaultsort"] = "asc",  ["sort"] = "asc",  ["color"] = {["r"] = 0.45, ["g"] = 0.45, ["b"] = 0.45, ["a"] = 1.0 }},

       { ["name"] = "Note",      ["width"] = 30,  ["align"] = "RIGHT"},

       { ["name"] = " ",         ["width"] = 5,   ["align"] = "LEFT" }, -- spacer

       { ["name"] = "iLvl",      ["width"] = 60,  ["align"] = "CENTER",   ["bgcolor"] = gearBgColor },
       { ["name"] = "s1",        ["width"] = 20,  ["align"] = "CENTER",   ["bgcolor"] = gearBgColor },
       { ["name"] = "s2",        ["width"] = 20,  ["align"] = "CENTER",   ["bgcolor"] = gearBgColor },
       { ["name"] = " ",         ["width"] = 5,   ["align"] = "LEFT",     ["bgcolor"] = gearBgColor }
}

function LootMasterML:ShowInfoPopup( ... )    
    GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")    
    for i=1,select("#", ...) do
        if i==1 then
		    GameTooltip:AddLine( tostring(select(i, ...)), 1, 1, 1 )
        else
            GameTooltip:AddLine( tostring(select(i, ...)), nil, nil, nil, true )
        end
	end
	GameTooltip:Show()
    GameTooltip:ClearAllPoints();
    if self.frame:IsShown() then
        GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, 0);    
    else
        GameTooltip:SetPoint("TOPLEFT", self.frame.titleFrame , "BOTTOMLEFT", 0, 0);        
    end
end

function LootMasterML:HideInfoPopup()
	GameTooltip:Hide()    
end

function LootMasterML:GetFrame()
    
    if self.frame then
        return self.frame;
    end    
    
    local mainframe = CreateFrame("Frame","LootMasterMLMainFrame",UIParent)
    mainframe:SetPoint("CENTER",UIParent,"CENTER",0,0)
    mainframe:Hide();
    mainframe:SetScale(LootMaster.db.profile.mainUIScale or 1)
    mainframe:SetMovable(true)
    mainframe:SetFrameStrata("DIALOG")
    self.mainframe = mainframe;
    
      
    local frame = CreateFrame("Frame","LootMasterMLFrame",mainframe)
    --#region Setup main masterlooter frame
    frame:Show();
    frame:SetPoint("TOPLEFT",mainframe,"TOPLEFT",0,0)
    frame:SetPoint("BOTTOMRIGHT",mainframe,"BOTTOMRIGHT",0,0)
    frame:SetWidth(700)
    frame:SetHeight(415)
    --frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    frame:EnableMouse()
    frame:SetMovable(true)
    --frame:SetResizable()    
    --frame:SetToplevel(true)
    frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 64, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
    frame:SetBackdropColor(0,0,0,1)
    
    local extralootframe = CreateFrame("Frame","LootMasterMLFrameExtraLoot",frame)
    extralootframe:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 64, edgeSize = 8,
    insets = { left = 2, right = 1, top = 2, bottom = 2 }
  })

    extralootframe:SetBackdropBorderColor(1,1,1,0.5)
    extralootframe:SetBackdropColor(1,0,0,1)
    extralootframe:Show();
    extralootframe:SetFrameStrata("HIGH")
    extralootframe:SetPoint("TOPRIGHT",frame,"TOPLEFT",4,-10)
    extralootframe:SetWidth(LOOTBUTTON_HEIGHT + 17 )
    --extralootframe:SetPoint("BOTTOM",frame,"BOTTOM",0,10)
    frame.extralootframe = extralootframe;
    --frame:SetResizable()    

    --frame:SetScript("OnMouseDown", function() mainframe:StartMoving() end)
    --frame:SetScript("OnMouseUp", function() mainframe:StopMovingOrSizing() end)
    --frame:SetScript("OnHide",frameOnClose)
    --#endregion

    local titleFrame = CreateFrame("Frame", nil, mainframe)
    --#region Setup main frame title
    titleFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 64, edgeSize = 8,
		insets = { left = 2, right = 1, top = 2, bottom = 2 }
	})  
    titleFrame:SetBackdropColor(0,0,0,1)
    titleFrame:SetHeight(22)
    titleFrame:EnableMouse()
    titleFrame:EnableMouseWheel(true)
    titleFrame:SetPoint("LEFT",mainframe,"TOPLEFT",20,0)
    titleFrame:SetPoint("RIGHT",mainframe,"TOPRIGHT",-20,0)
    titleFrame:SetToplevel(true)
    
    titleFrame:SetScript("OnMouseDown", function() mainframe:StartMoving() end)
    titleFrame:SetScript("OnMouseWheel", function(s, delta) 
		self:SetUIScale( max(min(mainframe:GetScale(0.8) + delta/15,2.0),0.5) );
	end)
    titleFrame:SetScript("OnEnter", function() self:ShowInfoPopup("CCLootMaster", "Click and drag to move this window.", "Doubleclick to fold/unfold this window.") end)
    titleFrame:SetScript("OnLeave", self.HideInfoPopup)
	titleFrame:SetScript("OnMouseUp", function()
        mainframe:StopMovingOrSizing()
        if mainframe.lastClick and GetTime()-mainframe.lastClick<=0.5 then
            if frame:IsShown() then
                frame:Hide();
                titleFrame:ClearAllPoints()
                titleFrame:SetPoint("CENTER",mainframe,"TOP",0,0)
                titleFrame:SetWidth( titleFrame.titletext:GetWidth() + 20 );
                self:HideInfoPopup()
            else
                frame:Show()
                titleFrame:ClearAllPoints()
                titleFrame:SetPoint("LEFT",mainframe,"TOPLEFT",20,0)
                titleFrame:SetPoint("RIGHT",mainframe,"TOPRIGHT",-20,0)
                self:HideInfoPopup()
            end
            mainframe.lastClick = nil;
        else
            mainframe.lastClick = GetTime();
        end
    end)	
    
    local titletext = titleFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	titletext:SetPoint("CENTER",titleFrame,"CENTER",0,1)
	titletext:SetText( string.format("CCLootMaster %s", self:GetVersionString() ) )    
    titleFrame.titletext = titletext
    frame.titleFrame = titleFrame
    --#endregion
    
    local icon = CreateFrame("Button", "CCLM_CURRENTITEMICON", frame, "AutoCastShineTemplate")
    --#region itemicon setup
    icon:EnableMouse()
    icon:SetNormalTexture("Interface/ICONS/INV_Misc_QuestionMark")
    icon:SetScript("OnEnter", function()
        if not frame.currentLoot then return end
        GameTooltip:SetOwner(frame, "ANCHOR_NONE")
        GameTooltip:SetHyperlink( frame.currentLoot.link )
        GameTooltip:ClearAllPoints();
        GameTooltip:SetPoint("TOPLEFT", frame , "TOPRIGHT", 0, -5);
	    GameTooltip:Show()        
    end);
    icon:SetScript("OnLeave", function()
	    GameTooltip:Hide()	
    end);
    icon:SetScript("OnClick", function()
        if not frame.currentLoot then return end
	    if ( IsModifiedClick() ) then
		    HandleModifiedItemClick(frame.currentLoot.link);
        end
    end);
    icon:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-20)
    icon:SetHeight(48)
    icon:SetWidth(48)
    frame.itemIcon = icon;
    --#endregion
    
    local lblItem = frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
	lblItem:SetPoint("TOPLEFT",icon,"TOPRIGHT",10,0)
    lblItem:SetVertexColor( 1, 1, 1 );
	lblItem:SetText( "Itemname" )    
    frame.lblItem = lblItem;
    
    local lblInfo = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	lblInfo:SetPoint("BOTTOMLEFT",lblItem,"BOTTOMRIGHT",5,0)
    lblInfo:SetVertexColor( 0.7, 0.7, 0.7 );
	lblInfo:SetText( "ItemInfo" )
    frame.lblInfo = lblInfo;
    
    local equipHeaderFrame = CreateFrame("Frame", nil, frame)
    --#region Setup the headerframe and text for the candidate equipment columns.
    equipHeaderFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, tileSize = 64, edgeSize = 8,
		insets = { left = 2, right = 1, top = 2, bottom = 2 }
	})  
    equipHeaderFrame:SetBackdropColor(0.2,0.2,0.2,0.6)
    equipHeaderFrame:SetWidth(110)
    equipHeaderFrame:SetHeight(38)
    
    local titletext = equipHeaderFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    titletext:SetVertexColor( 0.9, 0.9, 0.9 );
    titletext:SetPoint("CENTER",equipHeaderFrame,"CENTER",0,0)
    titletext:SetPoint("TOP",equipHeaderFrame,"TOP",0,-5)
    titletext:SetText( "Equipped" )    
    --#endregion
    
    local sstScroll = ScrollingTable:CreateST(sstScrollCols, 15, 20, nil, frame);
    --#region Setup the scrollingTable
    sstScroll.frame:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-95)	
    --sstScroll.frame:SetPoint("RIGHT",frame,"RIGHT",-30,10)
    
    equipHeaderFrame:SetPoint("BOTTOMRIGHT",sstScroll.frame,"TOPRIGHT",-4,-5)

    frame:SetMinResize(frame:GetWidth(),130)
    frame:SetMaxResize(frame:GetWidth(), 60*15+85 )
    
    frame.sstScroll = sstScroll
    --#endregion

    local lblNoDistribute = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    lblNoDistribute:SetVertexColor( 1, 0, 0 );
    lblNoDistribute:SetPoint("TOPLEFT",lblItem,"BOTTOMLEFT",0,-15)
    lblNoDistribute:SetText( "** MONITOR ONLY **" );
    frame.lblNoDistribute = lblNoDistribute

    local btnAnnounce = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	btnAnnounce:SetScript("OnClick", function()
            if not frame.currentLoot then return message('no loot selected') end
            self:AnnounceLoot( frame.currentLoot.id )
            btnAnnounce:Hide();
    end)
    btnAnnounce:SetScript("OnEnter", function() self:ShowInfoPopup( "Announce",
                                                                    "Click to announce this item to all candidates",
                                                                    "This will open the selecton screen on their client.") end)
    btnAnnounce:SetScript("OnLeave", self.HideInfoPopup)
	btnAnnounce:SetPoint("TOPLEFT",lblItem,"BOTTOMLEFT",0,-15)
	btnAnnounce:SetHeight(25)
	btnAnnounce:SetWidth(120)
	btnAnnounce:SetText("Announce loot")
    frame.btnAnnounce = btnAnnounce;
    
    local btnDiscard = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	btnDiscard:SetScript("OnClick", function()
            if frame.currentLoot then 
                self:RemoveLoot( frame.currentLoot.id );
            end            
            self:UpdateUI();
    end)
    btnDiscard:SetScript("OnEnter", function() self:ShowInfoPopup( "Discard loot",
                                                                   "Click to remove this item and all the candidate selections from your list.",
                                                                   "Use this when you don't want to loot this item and close the lootmaster window.") end)
    btnDiscard:SetScript("OnLeave", self.HideInfoPopup)
	btnDiscard:SetPoint("TOP",btnAnnounce,"TOP",0,0)
    btnDiscard:SetPoint("RIGHT",equipHeaderFrame,"LEFT",-10,0)
	btnDiscard:SetHeight(25)
	btnDiscard:SetWidth(120)
	btnDiscard:SetText("Discard loot")
    frame.btnDiscard = btnDiscard;
    
    
    local drop = CreateFrame("Frame", "LootMasterMLCandidateDropDown", frame, "UIDropDownMenuTemplate");
    drop.addon = self;
    --#region Setup the popup menu for the candidate list
    drop:SetID(1)
    UIDropDownMenu_Initialize(drop, function(...) LootMasterML.CandidateDropDownInitialize(LootMasterML, ...) end, "MENU");    
    self.CandidateDropDown = drop;
    --#endregion
    
    self.frame = frame;
    
    mainframe:SetHeight( frame:GetHeight() )
    self:UpdateWidth()    
    
    return self.frame    
end

function LootMasterML:SetUIScale( scale )
    LootMaster.db.profile.mainUIScale = scale;
    if not self.mainframe then return end;
    self.mainframe:SetScale( scale );
end

local extraWidthToggle = true;
function LootMasterML:UpdateWidth()
    if not self.frame or not self.mainframe or not self.frame.sstScroll then return nil end;
    
    if self.frame.sstScroll.data and #self.frame.sstScroll.data>15 then
        if not extraWidthToggle then
            self.frame:SetWidth( self.frame.sstScroll.frame:GetWidth() + 37 )
            extraWidthToggle = true;
        end
    else
        if extraWidthToggle then
            self.frame:SetWidth( self.frame.sstScroll.frame:GetWidth() + 19 )
            extraWidthToggle = false
        end
    end
    self.mainframe:SetWidth( self.frame:GetWidth() )  
end

function LootMasterML:EnterCombat()
    -- Should we hide when entering combat?
    if not LootMaster.db.profile.hideMLOnCombat then return end;
    
    self.inCombat = true;
    if self:IsShown() then        
        self:Hide();
        self.hiddenOnCombat = true;
    end
end

function LootMasterML:LeaveCombat()
    self.inCombat = nil;
    
    if not self.lootTable then return end;
    
    -- We left combat, see if theres still loot in the cache.
    for id, loot in pairs(self.lootTable) do
        if loot then
            self.hiddenOnCombat = nil;
            self:ReloadMLTableForLoot( id )
            break;
        end
    end
end

function LootMasterML:IsShown()
    if not self.mainframe then return false end;
    
    if self.inCombat and self.hiddenOnCombat then return true end
    
    return self.mainframe:IsShown();
end

function LootMasterML:Show()
    if not self.mainframe then return false end;
    
    -- Lootmaster ui is shown... do nothing.
    if LootMaster.db.profile.hideOnSelection and LootMaster and LootMaster.IsShown and LootMaster.IsShown(LootMaster) then
        return self.mainframe:Hide()
    end;
    
    -- Are we in combat? 
    if self.inCombat then
        -- Show the ui after combat
        self.mainframe:Hide();
        self.hiddenOnCombat = true;
        return true;
    end
    
    local ret = self.mainframe:Show();
    
    if self.frame.currentLoot then
        self:UpdateUI(self.frame.currentLoot.link);
    else
        self:UpdateUI();
    end   
    
    return ret;
end

function LootMasterML:Hide()
    if not self.mainframe then return end;
    return self.mainframe:Hide();
end

--[[
	Reload the scrollingtable if the current viewing item == link
]]
function LootMasterML:ReloadMLTableForLoot( itemName )
    
    -- LootMaster Loot UI visible? don't update
    if LootMaster.db.profile.hideOnSelection and LootMaster and LootMaster.IsShown and LootMaster.IsShown(LootMaster) then return end;
    
    local frame = self:GetFrame();
    if not self.mainframe:IsShown() then
        self.mainframe:Show();
    end
    
    local lootData = self:GetLoot( itemName )
	if not lootData then
        return self:Print( tostring(itemName) .. ' not found when updating UI');
    end;
    
    self:UpdateUI( lootData.link );
    
end

local numTotalLootButtons = 0;
function LootMasterML:CreateLootButton()
    
    numTotalLootButtons = numTotalLootButtons+1
    
    local icon = CreateFrame("Button", "CCMLLootButton"..numTotalLootButtons, self.frame, "AutoCastShineTemplate")
    --#region itemicon setup
    icon:EnableMouse()
    icon:SetNormalTexture("Interface/ICONS/INV_Misc_QuestionMark")
    icon:SetScript("OnEnter", function()
        if not icon.data then return end    
        GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
        GameTooltip:SetHyperlink( icon.data.link )
	    GameTooltip:Show()
        GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, -5);
    end);
    icon:SetScript("OnLeave", function()
	    GameTooltip:Hide()	
    end);
    icon:SetScript("OnClick", function()
        if not icon.data then return end
	    if ( IsModifiedClick() ) then
		    HandleModifiedItemClick(icon.data.link);
        else
            self:DisplayLoot(icon.data.link);
            self:UpdateUI();
        end
    end);
    icon:SetPoint("RIGHT",self.frame,"LEFT",-5,0)
    icon:SetHeight(LOOTBUTTON_HEIGHT)
    icon:SetWidth(LOOTBUTTON_HEIGHT);
    
    return icon;
end

function LootMasterML:DisplayLoot( item )
    
    local data = self:GetLoot(item);
        
    if not data then
        self.frame.currentLoot = nil;
        return
    end;
    
    local isCurrentItem = false
    if self.frame.currentLoot and data.link==self.frame.currentLoot.link then
        isCurrentItem = true;
    end
    
    self.frame.currentLoot = data;
    
    if data.quantity>1 then
        self.frame.lblItem:SetText(format('%sx %s',data.quantity, data.link or 'nil'));
    else
        self.frame.lblItem:SetText(data.link or 'nil');
    end
        
    local color = ITEM_QUALITY_COLORS[data.quality];
    if not color then
        color = {['r']=1,['g']=1,['b']=1}
    end
    self.frame.lblItem:SetVertexColor(color.r, color.g, color.b);
    
    local binding = '';
    if data.binding=='use' then
        binding = ', BoU'
    elseif data.binding=='pickup' then
        binding = ', BoP'
    elseif data.binding=='equip' then
        binding = ', BoE'
    end
    
    self.frame.lblInfo:SetText(format("iLevel: %s%s", data.ilevel or -1, binding or ''));        
    self.frame.itemIcon:SetNormalTexture(data.texture); 
    
    if not data.announced then
        self.frame.btnAnnounce:Show();
    else
        self.frame.btnAnnounce:Hide();
    end
    
    if data.mayDistribute then
        self.frame.lblNoDistribute:Hide();
    else
        self.frame.lblNoDistribute:Show();
        self.frame.lblNoDistribute:SetText( format("** MONITORING ** Only %s may distribute this item **", tostring(data.lootmaster)) )
    end
    
    if not isCurrentItem then
        self.frame.sstScroll:SetData( data.rowdata )
        
        -- Restore the default sorting when we're displaying a new item.
        local cols = self.frame.sstScroll.cols;
        for i=1, #cols do
			self.frame.sstScroll.cols[i].sort = cols[i].defaultsort
		end        
    end
    self.frame.sstScroll:SortData();
    self.frame.sstScroll:DoFilter();
end

function LootMasterML:UpdateUI( updateItemLink )
    
    if not self:IsShown() then return self:Debug('UpdateUI: not shown') end;
    
    local visibleLootButtons = 0;    
    local totalLoot = 0;   
    
    if LootMaster.db.profile.hideOnSelection and LootMaster and LootMaster.IsShown and LootMaster.IsShown(LootMaster) then return false end;
    
    -- Are we in combat? 
    if self.inCombat then
        -- Show the ui after combat
        self.mainframe:Hide();
        self.hiddenOnCombat = true;
        return true;
    end
    
    if updateItemLink and self.frame.currentLoot and self.frame.currentLoot.link==updateItemLink then
        -- We got a message to update the current displayed item, refresh the celldata.
        self.frame.sstScroll:SetData( self.frame.currentLoot.rowdata )    
        self.frame.sstScroll:SortData();
        self.frame.sstScroll:DoFilter();
    end
    
    local breakMe = false
    
    for item, data in pairs(self.lootTable) do repeat
        
        if item and data then
            
            -- If monitoring is disabled just don't display items we're not allowed to distribute.
            if not LootMaster.db.profile.monitor and not data.mayDistribute then
                -- also just remove the loot
                self:RemoveLoot(item)
                break
            end;
            
            -- If item quantity<1, just remove the loot.
            if data.quantity<1 then
                self:RemoveLoot(item)
                break
            end
            
            totalLoot = totalLoot + 1;           
            
            if self.frame.currentLoot and data.link==self.frame.currentLoot.link then
                -- If already displaying, do nothing.
                self:DisplayLoot(item);
                breakMe = true;
                break;
            elseif not self.frame.currentLoot then
                -- Nothing is onscreen, display the first item
                self:DisplayLoot(item);
                breakMe = true;
                break;
            end
            
            if visibleLootButtons>=LOOTBUTTON_MAXNUM then breakMe = true; break end;
            visibleLootButtons = visibleLootButtons + 1;
            
            if not self.lootButtons then self.lootButtons = {} end;
            
            local lootButton = self.lootButtons[visibleLootButtons];
            if not lootButton then
                lootButton = self:CreateLootButton();
                self.lootButtons[visibleLootButtons] = lootButton;
            end
            
            lootButton.data = data;
            lootButton:SetNormalTexture(data.texture); 
            --lootButton:GetNormalTexture():SetVertexColor(1,0,0,0.5);
            
            local numData = (#(data.rowdata))
            if data.numResponses >= numData and numData>0 then             
                AutoCastShine_AutoCastStart(lootButton)
            else
                AutoCastShine_AutoCastStop(lootButton)
            end
            
            lootButton:Show();
            
            lootButton:SetPoint( "TOP", self.frame, "TOP", 0, -20 - ((LOOTBUTTON_HEIGHT+LOOTBUTTON_PADDING) * (visibleLootButtons-1)) )
        end
    until true
        if breakMe then
            breakMe = false
        end
    
    end
    
    if breakMe then
        self:Print("Break doesn't work as expected, contact Author!")
    end
    
    if self.lootButtons then 
        for i = visibleLootButtons+1, LOOTBUTTON_MAXNUM do
            local lootButton = self.lootButtons[i];
            if lootButton then
                AutoCastShine_AutoCastStop(lootButton)
                lootButton.data = nil;
                lootButton:Hide()
            end
        end
    end;
    
    if visibleLootButtons>0 then
        self.frame.extralootframe:Show();
        self.frame.extralootframe:SetHeight( (LOOTBUTTON_HEIGHT+LOOTBUTTON_PADDING)*visibleLootButtons + 15 )
    else
        self.frame.extralootframe:Hide();
    end
    
    if totalLoot==0 and self:IsShown() then
        self.frame.currentLoot = nil;
        self:Hide();
    else
        self:UpdateWidth()
    end
    
end

function LootMasterML:CandidateDropDownInitialize( frame, level, menuList )
        
    if not LootMasterML.CandidateDropDown then return end;
    
    local loot = LootMasterML.GetLoot( LootMasterML, LootMasterML.CandidateDropDown.selectedLink );
    
    if not loot then
        LootMasterML:Print(LootMasterML, 'could not display lootdropdown; loot not in table');
        return frame:Hide();
    end

    local info = UIDropDownMenu_CreateInfo();
    
    if UIDROPDOWNMENU_MENU_LEVEL == 1 then
    
        if LootMasterML and LootMasterML.CandidateDropDown and LootMasterML.CandidateDropDown.selectedCandidate then
            info.notCheckable = 1;
            info.isTitle = true;
            info.disabled = false;
            info.text = LootMasterML.CandidateDropDown.selectedCandidate;
            info.tooltipTitle = nil
            info.tooltipText = nil
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
            info=UIDropDownMenu_CreateInfo();    
            info.notCheckable = 1;
        end
        
        info.notCheckable = 1;
        info.disabled = false;
        info.text = 'Whisper';
        info.tooltipTitle = 'Whisper'
        info.tooltipText = 'Send a message to the selected candidate.'
        info.func = function() ChatFrame_SendTell(LootMasterML.CandidateDropDown.selectedCandidate) end;
        UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
        
        if loot.mayDistribute then
        
            info.isTitle = true;
            info.text = '';
            info.disabled = false;
            info.tooltipTitle = nil
            info.tooltipText = nil
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
            info=UIDropDownMenu_CreateInfo();    
            info.notCheckable = 1;
            
            if not loot.manual then

                info.isTitle = false;
                info.disabled = false;
                info.text = 'Give loot';
                info.tooltipTitle = 'Give loot';
                info.tooltipText = "Attempts to send the loot to the candidate.";
                info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.GIVE ) end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
                
                info.isTitle = false;
                info.disabled = false;
                info.text = 'Give loot for disenchantment';
                info.tooltipTitle = 'Give loot for disenchantment';
                info.tooltipText = 'Attempts to send the loot to the candidate for disenchantment.';
                info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.DISENCHANT ) end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
                
                info.isTitle = false;
                info.disabled = false;
                info.text = 'Give loot for bank';
                info.tooltipTitle = 'Give loot for bank';
                info.tooltipText = 'Attempts to send the loot to the candidate for storage in bank.';
                info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.BANK ) end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
                
            else
                
                info.isTitle = false;
                info.disabled = false;
                info.text = '- Cannot distribute loot -';
                info.tooltipTitle = info.text;
                info.tooltipText = "You have added this loot manually to the list, you will need to handle the loot manually and discard the loot from the list when you're done distributing it."
                info.func = function() end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
                
            end
            
            info.isTitle = true;
            info.disabled = false;
            info.text = '';
            info.tooltipTitle = nil
            info.tooltipText = nil
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
            info=UIDropDownMenu_CreateInfo();    
            info.notCheckable = 1;
            
            info.isTitle = false;
            info.disabled = false;
            info.text = '(Re)announce loot to candidate';
            info.tooltipTitle = '(Re)announce loot to candidate';
            info.tooltipText = 'Reopens the loot selection popup at the candidate, this offers the candidate to vote for the loot after a crash or disconnect.';
            info.func = function() LootMasterML.AskCandidateIfNeeded(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate) end;
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL); 
            
            info.isTitle = false;
            info.disabled = false;
            info.hasArrow = 1;
            info.text = 'Set response manually';
            info.tooltipTitle = 'Set response manually';
            info.tooltipText = 'Allows you to manually set the response for a given candidate';
            info.func = function() end;
            info.value = 'RESPONSE_OVERRIDE';
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL); 
        
        end
        
    elseif UIDROPDOWNMENU_MENU_LEVEL==2 then
        
        if UIDROPDOWNMENU_MENU_VALUE == 'RESPONSE_OVERRIDE' then
            
            info.isTitle = false;
            info.disabled = false;
            info.text = 'Need';
            info.tooltipTitle = 'Need';
            info.tooltipText = 'Manually sets the response of this candidate to need. Please note that the candidate will receive a notice about this in whisper.';
            info.func = function() LootMasterML.SetManualResponse(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.RESPONSE.NEED ); CloseDropDownMenus(); end;
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);  
            
            info.isTitle = false;
            info.disabled = false;
            info.text = 'Greed';
            info.tooltipTitle = 'Greed';
            info.tooltipText = 'Manually sets the response of this candidate to greed. Please note that the candidate will receive a notice about this in whisper.';
            info.func = function() LootMasterML.SetManualResponse(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.RESPONSE.GREED ); CloseDropDownMenus(); end;
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);  
            
            info.isTitle = false;
            info.disabled = false;
            info.text = 'Pass';
            info.tooltipTitle = 'Pass';
            info.tooltipText = 'Manually sets the response of this candidate to pass. Please note that the candidate will receive a notice about this in whisper.';
            info.func = function() LootMasterML.SetManualResponse(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.RESPONSE.PASS ); CloseDropDownMenus(); end;
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);  
            
        end
        
    end
    
    --[[info.isTitle = true;
    info.disabled = false;
    info.text = '';
    info.tooltipTitle = nil
    info.tooltipText = nil
    UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
    info=UIDropDownMenu_CreateInfo();    
    info.notCheckable = 1;
    
    info.isTitle = false;
    info.disabled = false;
    info.text = '-DEBUG- Discard loot';
    info.tooltipTitle = nil;
    info.tooltipText = nil;
    info.func = function()
      LootMasterML.RemoveLoot(LootMasterML, LootMasterML.CandidateDropDown.selectedLink);
      LootMasterML.Show(LootMasterML);
  end;
  UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);]]--

end

function LootMasterML:OnCandidateRowRightClick( candidate, link, row )
  self.CandidateDropDown.selectedCandidate = candidate;
  self.CandidateDropDown.selectedLink = link;
  self.CandidateDropDown.selectedRow = row;

  ToggleDropDownMenu(1, nil, self.CandidateDropDown, "cursor", 0, 0);
end

function LootMasterML:SetNoteCellOwnerDraw(cell, itemData)
  cell.text:SetText('');
  
  if not itemData or itemData=='' then
    cell.CCLMModTexture = false
    return cell:SetNormalTexture(nil);        
  end 
  cell:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")

  -- Center the texture if not done already.
  if not cell.CCLMModTexture then
    local t = cell:GetNormalTexture();
    t:ClearAllPoints()
    t:SetPoint("CENTER",t:GetParent(),"CENTER")
    cell.CCLMModTexture = true;
  end
end

function LootMasterML:SetGearCellOwnerDraw(cell, itemData)
  if not itemData or itemData=='' then
    cell.text:SetText('');
    cell:SetNormalTexture(nil)
    return;
  end   
  
  local link, ilevel, itemTexture = strsplit("^", itemData)
  
  cell.text:SetText('');
  cell:SetNormalTexture(itemTexture)
end

function LootMasterML:SetClassIconCellOwnerDraw(cell, itemData)
  cell.text:SetText('');
  
  if not itemData or itemData=='' or not CLASS_ICON_TCOORDS[itemData] then        
    cell:SetNormalTexture(nil)
    return;
  end   
  
  local coords = CLASS_ICON_TCOORDS[itemData];    
  cell:SetNormalTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes");    
  cell:GetNormalTexture():SetTexCoord(coords[1],coords[2],coords[3],coords[4]);
end

function LootMasterML:ShowGearInspectPopup( candidate, item ) 
  local foundGear = self:GetCandidateData(item, candidate, "foundGear") or false;
  if not foundGear then
    self:ShowInfoPopup( candidate, 'Click to retrieve current equipment.' );    
  end    
end

function LootMasterML:ShowNoteCellPopup( candidate, item )    
  local itemData = self:GetCandidateData(item, candidate, 'note');
  if not itemData or itemData=='' then return end;
  
  self:ShowInfoPopup('Note added by ' .. candidate .. ':', itemData or '');    
end

function LootMasterML:ShowGearCellPopup( candidate, item, dataName )
  local itemData = self:GetCandidateData(item, candidate, dataName);
  if not itemData or itemData=='' then return end;

  local link, ilevel, itemTexture = strsplit("^", itemData);

  GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
  GameTooltip:SetHyperlink( link )
  GameTooltip:Show()
  GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, -5);
end

function LootMasterML:ShowCandidateCellPopup( candidate, item )
  if not candidate then return nil end
  GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
  GameTooltip:SetUnit(candidate)
  GameTooltip:Show()
  GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, -5);
end

function LootMasterML:ShowRollCellPopup( candidate, item )
  local roll = self:GetCandidateData(item, candidate, 'roll');
  if not roll then return end;
  self:ShowInfoPopup('Random roll', format('%s rolled %s.', candidate, roll));
end

function LootMasterML:SetGearCelliLVL( cell, self, candidate, item )   
  local foundGear = self:GetCandidateData(item, candidate, "foundGear") or false;
  if not foundGear then
    cell.text:SetText( '- inspect -' );
    return;
  end

  local s = {};
  local itemData = self:GetCandidateData(item, candidate, "currentitem");
  local _, ilevel = strsplit("^", itemData or '');
  if ilevel then tinsert(s, ilevel) end

  itemData = self:GetCandidateData(item, candidate, "currentitem2");
  _, ilevel = strsplit("^", itemData or '');
  if ilevel then tinsert(s, ilevel) end

  cell.text:SetText( strjoin(', ', unpack(s)))   
end

function LootMasterML:GetCandidateCellColor( candidate, item, dataName, defaultColor )
  --local itemData = self:GetCandidateData( item, candidate, "version" );    
  local r, g, b = self:GetCandidateResponseColor( candidate, item, nil );
  return {["r"] = r or 1, ["g"] = g or 0, ["b"] = b or 1, ["a"] = 1.0 };
end

function LootMasterML:GetCandidateClassCellColor( candidate, item, dataName, defaultColor )    
  local color = RAID_CLASS_COLORS[self:GetCandidateData(item, candidate, "unitclass")];
  if not color then
    -- if class not found display epic color.
    color = {["r"] = 0.63921568627451, ["g"] = 0.2078431372549, ["b"] = 0.93333333333333, ["a"] = 1.0 }
  else
    color.a = 1.0;
  end
  return color;
end

function LootMasterML:GetCandidateResponseColor( candidate, item, response )
  if not response then
    response = tonumber(self:GetCandidateData(item, candidate, "response"));
  end

  if not response or not LootMaster.RESPONSE[response] then
    return 1,0,1
  end

  return unpack( LootMaster.RESPONSE[response].COLOR or {1,0,1} )    
end

function LootMasterML:SetCandidateResponseCellUserDraw( cell, self, candidate, item )
  local response = tonumber(self:GetCandidateData(item, candidate, "response"));
  local autoPass = self:GetCandidateData(item, candidate, "autoPass");

  local text = nil;

  if response == LootMaster.RESPONSE.DISENCHANT then
    if autoPass then
      text = format('Auto pass; Enchanter (%s)',self:GetCandidateData(item, candidate, "enchantingSkill") or 0);
    else
      text = format('Pass; Enchanter (%s)',self:GetCandidateData(item, candidate, "enchantingSkill") or 0);
    end   
  elseif LootMaster.RESPONSE[response] then        
    text = LootMaster.RESPONSE[response].TEXT        
  else
    text = 'resp: ' .. self:GetCandidateData(item, candidate, "response");
  end

  -- Add looted status message when candidate has looted the item.
  if self:GetCandidateData(item, candidate, "looted") then
    return cell.text:SetText( (text or '')  .. '; Looted' )
  end

  return cell.text:SetText( text or '' )
end

function LootMasterML:SetCandidateRollCellUserDraw( cell, self, candidate, item )
  local roll = self:GetCandidateData(item, candidate, "roll");    

  if roll then
    cell.text:SetText( floor(roll) );        
  else
    cell.text:SetText( '?' );
  end
end

function LootMasterML:HideGearCellPopup( candidate, item, dataName )
    GameTooltip:Hide()
end

function LootMasterML:OnGearInspectClick( candidate, item )
  if self:InspectCandidate( item, candidate ) then
    self.frame.sstScroll:SortData();
    self.frame.sstScroll:DoFilter();
  else
    self:Print( format('%s is offline, out of range or not grouped, unable to inspect.', candidate or 'Unknown') )
  end
end

function LootMasterML:OnGearCellClick( candidate, item, dataName )
  if ( IsModifiedClick() ) then
    local link = strsplit("^", self:GetCandidateData(item, candidate, dataName) or '');
    HandleModifiedItemClick(link);
  end
end

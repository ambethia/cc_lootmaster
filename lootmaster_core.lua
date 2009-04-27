--[[
	LootMaster
    
			FMI:
				http://www.wowwiki.com/ItemEquipLoc	Different item slots where item can be placed

			Pass on loot == (GetOptOutOfLoot() == true)
]]

LootMaster          = LibStub("AceAddon-3.0"):NewAddon("EPGPLootMaster", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

local version 	    = "@project-version@"
local dVersion 	    = "@project-date-iso@"
local iVersion	    = 3
local iVersionML	= 11
local _G            = _G

local debug         = false
local addon         = LootMaster		-- Local instance of the addon

local HandleChatEvents = {
    ['CHAT_MSG_WHISPER_INFORM']     = true, -- Filter outgoing whispers.
    ['CHAT_MSG_PARTY']              = true,
    ['CHAT_MSG_RAID']               = true,
    ['CHAT_MSG_RAID_LEADER']        = true
}

--[[
    Returns a table serialized as a string.
]]
function tprint( data, level )
	level = level or 0
	local ident=strrep('    ', level)
	if level>5 then return end

	if type(data)~='table' then print(tostring(data)) end;

	for index,value in pairs(data) do repeat
		if type(value)~='table' then
			print( ident .. '['..index..'] = ' .. tostring(value) .. ' (' .. type(value) .. ')' );
			break;
		end
		print( ident .. '['..index..'] = {')
        tprint(value, level+1)
        print( ident .. '}' );
	until true end
end

function LootMaster:GetVersionString()
    return self.version;
end
    
function LootMaster:OnInitialize()
    
    self.version 	= version;
    self.dVersion 	= dVersion;
    self.iVersion 	= iVersion;
    
    self.db = LibStub("AceDB-3.0"):New("EPGPLootMaster")
    
    self.db:RegisterDefaults(
    {
      profile = {
        auto_announce_threshold = 4,
        AutoLootThreshold = 2,
        hideOnSelection = true,
        loot_timeout = 60,
        filterEPGPLootmasterMessages = true,
        monitor = false,
        monitorSend = true,
        monitorThreshold = 2,
        ignoreResponseCorrections = false,
        hideMLOnCombat = true,
        hideSelectionOnCombat = false,
        allowCandidateNotes = true,
        monitorIncomingThreshold = 3,
        audioWarningOnSelection = true,
        use_epgplootmaster = 'ask'
      }
    })
    
    self.lootList   = {};
    self.lootMLCache = {};
    
    -- Client responses    
    self.RESPONSE = {
        { ["CODE"]      = "NOTANNOUNCED",   ["COLOR"] = {1,1,1},        ["TEXT"] = 'Not yet announced to candidate' },
        { ["CODE"]      = "INIT",           ["COLOR"] = {1,0,0},        ["TEXT"] = 'Offline or lootmaster not installed?' },
        { ["CODE"]      = "WAIT",           ["COLOR"] = {1,0.5,0},      ["TEXT"] = 'Making selection, please wait...' },
        { ["CODE"]      = "TIMEOUT",        ["COLOR"] = {1,0,1},        ["TEXT"] = 'Candidate did not respond on time.' },
        { ["CODE"]      = "NEED",           ["COLOR"] = {0.4,1,0.4},    ["TEXT"] = 'Need / Mainspec' },
        { ["CODE"]      = "GREED",          ["COLOR"] = {1,1,0},        ["TEXT"] = 'Greed / Offspec' },
        { ["CODE"]      = "DISENCHANT",     ["COLOR"] = {0,0.8,1},      ["TEXT"] = '--disenchanter--' },
        { ["CODE"]      = "PASS",           ["COLOR"] = {0.6,0.6,0.6},  ["TEXT"] = 'Pass' },        
        { ["CODE"]      = "AUTOPASS",       ["COLOR"] = {0.6,0.6,0.6},  ["TEXT"] = 'Auto pass (not eligible)' } 
    }    
    for i,d in ipairs(self.RESPONSE) do
        self.RESPONSE[d.CODE] = i;
        self.RESPONSE[d.CODE .. "_TEXT"] = d.TEXT;
    end    
    LootMaster.RESPONSE = self.RESPONSE;
    
    -- Loot receive types.
    self.LOOTTYPE = {
        { ["CODE"]      = "UNKNOWN",        ["TEXT"] = '%s received %s for unknown reason%4$s.' },
        { ["CODE"]      = "GP",             ["TEXT"] = '%s received %s for %s GP%s.' },
        { ["CODE"]      = "DISENCHANT",     ["TEXT"] = '%s received %s for disenchantment%4$s.' },
        { ["CODE"]      = "BANK",           ["TEXT"] = '%s received %s for bank%4$s.' }
    }    
    for i,d in ipairs(self.LOOTTYPE) do
        self.LOOTTYPE[d.CODE] = i;
        self.LOOTTYPE[d.CODE .. "_TEXT"] = d.TEXT;
    end    
    LootMaster.LOOTTYPE = self.LOOTTYPE;
    
	-- Register communications
	self:RegisterComm("EPGPLootMasterC",    "CommandReceived")
    
    -- Register communications for version checking
	self:RegisterComm("EPGPLMVChk", 	    "CommVersionCheckRequest")
	self:RegisterComm("EPGPLMVRsp",	        "CommVersionCheckResponse")
	self:RegisterComm("EPGPLMVHdlr",	    "CommVersionCheckHandler")
    
    -- Check for updates versions in the guild
	self:SendCommMessage("EPGPLMVChk",      iVersion .. "_" .. version, "GUILD")
    
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "EnterCombat");
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "LeaveCombat");

	self:RegisterChatCommand("lm",	        "SlashHandler")	
    
    self:RegisterChatCommand("rl", function() ReloadUI() end)   
        
    self:Print(format('%s loaded.', version))    
end

function LootMaster:OnEnable()
    -- Postpone the chathooks to make sure we're the last hooking these.
    self:ScheduleTimer("PostEnable", 1)
    
    -- We don't need these right away, so localize them after a 10 second delay.
    self:ScheduleTimer("LocalizeLootTypes", 10)
end

function LootMaster:PostEnable()    
    -- Inbound Chat Hooking
    self:RawHook("ChatFrame_MessageEventHandler", true)
end

local lastMsgID = nil;
local lastMsgHandled = true;

--[[
    Filter out 'EPGPLootmaster:' announces in the raid and raid leader and party chat
]]--
function LootMaster:ChatFrame_MessageEventHandler(this, event, message, ...)
 
    if LootMaster.db.profile.filterEPGPLootmasterMessages and HandleChatEvents[event] then
        
        -- Lets speed this up by checking if we already tested the message
        local msgID = select(select("#", ...), ...)
        if lastMsgID == msgID then
            if not lastMsgHandled then
                return false;
            end
        else
            lastMsgID       = msgID;
            lastMsgHandled  = true;
            
            -- find EPGPLootmaster: in the chat message and prevent these messages from showing up.
            if strfind(message, '^%s*EPGPLootmaster:%s+') then  
                lastMsgHandled  = false;
                return false;
            end       
        end        
    end
    
    return self.hooks["ChatFrame_MessageEventHandler"](this, event, message, ...) 
end

-- Preparation to fix the portal "bug" in naxx when handing out loot to players that have already
-- used to portal.
local function EmulateLocal_CHAT_MSG_LOOT_proc(player, item, ...)
    for i = 1, select( "#", ... ) do
        local frame = select( i, ... )
        local func = frame:GetScript('OnEvent');
        pcall( func, frame, 'CHAT_MSG_LOOT', format(LOOT_ITEM, tostring(player), tostring(item)), '', '', '', '' )
    end
end
local function EmulateLocal_CHAT_MSG_LOOT( player, item )
    EmulateLocal_CHAT_MSG_LOOT_proc( player, item, GetFramesRegisteredForEvent('CHAT_MSG_LOOT') )
end

function LootMaster:SlashHandler( input )
	local _,_,command, args = string.find( input, "^(%a-) (.*)$" )
	command = command or input

	if command=='version' or command=='versioncheck' or command=='vc' or command=='v' then
        
        self:ShowVersionCheckFrame();
        
	elseif command=='debug' then
        
        self.debug = not self.debug;
        if self.debug then
            self:Print('Debugging enabled')
        else
            self:Print('Debugging disabled')
        end
        
    elseif command=='verbose' then
        
        self.verbose = not self.verbose;
        if self.verbose then
            self.debug = true;
            self:Print('Verbose debugging enabled')
        else
            self.debug = false;
            self:Print('Verbose debugging disabled')
        end
        
    elseif command=='reset' then
        
        LootMaster:SetUIScale(1.0);
        if LootMasterML then
            LootMasterML:SetUIScale(1.0)
        end
        
    elseif command=='config' or command=='c' or command=='options' or command=='o' then
        
        InterfaceOptionsFrame_OpenToCategory("EPGPLootMaster")
        
    elseif command=='close' or command=='hide' then
        
        if LootMasterML then
            self:Print('Hiding lootmaster window, reopen with /lm show')
            LootMasterML.Hide(LootMasterML)
        end
        
    elseif command=='open' or command=='show' then
        
        if LootMasterML then
            LootMasterML.Show(LootMasterML)
        end
        
    elseif command=='toggle' or command=='toggel' then
        
        if LootMasterML then
            if LootMasterML.IsShown(LootMasterML) then
                LootMasterML.Hide(LootMasterML)
            else
                LootMasterML.Show(LootMasterML)
            end            
        end
        
    elseif command=='emulate' then
        
        local player, item = strmatch(strtrim(args or ''), '(%S+)%s+(.+)');
        if not player or not item or player=='' or item=='' then
            self:Print('Usage: /lm emulate player [itemlink]')
            self:Print('This will emulate the "Player receives [item]." locally. Usually used to "fix" the portal problem in naxx.')
        else
            EmulateLocal_CHAT_MSG_LOOT( player, item )
        end
        
    elseif command=='add' or command=='announce' then
    
        if not LootMasterML then return self:Print('Could not add loot, ML module not active') end
        ml = LootMasterML;
        
        local lootLink = strtrim(args or '');
        if not args or not lootLink or lootLink=='' then return self:Print(format('Usage: /lm %s [lootlink]', command)) end;
        
        local loot = ml.GetLoot(ml, lootLink);
        local added = false
        if not loot then
            local lootID = ml.AddLoot(ml, lootLink, true);
            loot = ml.GetLoot(ml, lootID);
            loot.announced = false;
            loot.manual = true;
            added = true;
        end
        if not loot then return self:Print('Unable to register loot.') end;
        
        local num = GetNumRaidMembers()
        local name = nil;
        if num>0 then
            -- we're in raid
            for i=1, num do
                name = GetRaidRosterInfo(i)
                ml.AddCandidate(ml, loot.id, name)
            end
        else
            num = GetNumPartyMembers()
            for i=1, num do
                name = UnitName('party'..i)
                ml.AddCandidate(ml, loot.id, name)
            end
            ml.AddCandidate(ml, loot.id, UnitName('player'))
        end           
        
        if command=='announce' then
            ml.AnnounceLoot(ml, loot.id)
        end
        
        if added then
            ml.SendCandidateListToMonitors(ml, loot.id)
        end
        
        ml.ReloadMLTableForLoot( ml, loot.link ) 
        
    elseif command=='debuglog' or command=='log' or command=='lootlog' then
        
        self:OutputLog();
        
    elseif command=='logtest' then
        
        for i = 1, 20 do
            local item = GetInventoryItemLink("player",i);  
            
            
            if item then
                local itemName = tostring(GetItemInfo(item));
                local itemID = tostring(LootMasterML:GetItemIDFromLink(item))
                local entry = self:CreateLogEntry();
                entry.name=itemID..':'..itemName
                entry.slots={}
                for j = 1, 20 do
                    local litem = GetInventoryItemLink("player",j);           
            
                    if litem then                    
                        local litemName = tostring(GetItemInfo(litem));
                        local litemID = tostring(LootMasterML:GetItemIDFromLink(litem))
                        entry.slots[j] = litemID..':'..litemName
                    else
                        entry.slots[j] = 'empty'
                    end
            
                end
            end
        end
        
        self:OutputLog();        
        self:Print('done');
        
    elseif command=='debugtest' then
        
		-- Debugging features       
        local ml = LootMasterML;
        if not ml then return self:Print("LootMaster ML not enabled") end;
        
        local itemName, item, _, _, _, _, _, _, _, _ = GetItemInfo("item:868:0:0:0:0:0:0:0")
		if item then       
            local itemID = ml.AddLoot( ml, item, true, 5 )
            ml.lootTable[itemID].announced = false;
            ml.AddCandidate( ml, itemID, UnitName('player') )
            if UnitName('party1') then ml.AddCandidate( ml, itemID, UnitName('party1') ) end
            if UnitName('party2') then ml.AddCandidate( ml, itemID, UnitName('party2') ) end
            if UnitName('party3') then ml.AddCandidate( ml, itemID, UnitName('party3') ) end
            if UnitName('party4') then ml.AddCandidate( ml, itemID, UnitName('party4') ) end
            --ml.AddCandidate( ml, itemID, 'Kerstin' )
            --ml.AddCandidate( ml, itemID, 'Deadbolt' )
            ml.SendCandidateListToMonitors(ml, itemID)
            ml.ReloadMLTableForLoot(ml, item )
        end        
        
        for i = 1, 6 do
           item = GetInventoryItemLink("player",i);
           if item then
            local itemID = ml.AddLoot( ml, item, true ) 
            ml.lootTable[itemID].announced = false;
            ml.AddCandidate( ml, itemID, UnitName('player') )
            if UnitName('party1') then ml.AddCandidate( ml, itemID, UnitName('party1') ) end
            if UnitName('party2') then ml.AddCandidate( ml, itemID, UnitName('party2') ) end
            if UnitName('party3') then ml.AddCandidate( ml, itemID, UnitName('party3') ) end
            if UnitName('party4') then ml.AddCandidate( ml, itemID, UnitName('party4') ) end
            local num = GetNumGuildMembers(false);
            local count = 0;
            for i=1, num do
                if count>100 then break end;
                count = count + 1
                local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i);
                if online then
                    ml.AddCandidate( ml, itemID, name )
                end
            end           
            ml.SendCandidateListToMonitors(ml, itemID)
            ml.ReloadMLTableForLoot(ml, item )
           end
        end --]]
        
        --self:Print('disabled')
        
	else
        
		self:Print( format('%s loaded.', version) )
        self:Print( 'This mod provides a full loot distributing system for EPGP.' )
        self:Print( 'USAGE: Create a party/raid, setup a master looter. When master loot drops, just rightclick the item and the UI will open.' )
        self:Print( 'Commandline Tools:' )
        self:Print( '/lm version: Show the versionchecker' )
        self:Print( '/lm config: Show the options window' )
        self:Print( '/lm reset: Resets window locations and scale' )
        self:Print( '/lm hide: Manually hide the Master Looter UI' )
        self:Print( '/lm show: Manually show the Master Looter UI' )
        self:Print( '/lm toggle: Manually toggle between showing and hiding the Master Looter UI' )
        self:Print( '/lm add [itemlink]: Manually add an item to the Master Looter UI' )
        self:Print( '/lm announce [itemlink]: Manually add an item and announce it to your group.' )
        
	end
end

--[[
    Data for the GetGearByINVTYPE function
]]--
local INVTYPE_Slots = {
		INVTYPE_HEAD		    = "HeadSlot",
		INVTYPE_NECK		    = "NeckSlot",
		INVTYPE_SHOULDER	    = "ShoulderSlot",
		INVTYPE_CLOAK		    = "BackSlot",
		INVTYPE_CHEST		    = "ChestSlot",
		INVTYPE_WRIST		    = "WristSlot",
		INVTYPE_HAND		    = "HandsSlot",
		INVTYPE_WAIST		    = "WaistSlot",
		INVTYPE_LEGS		    = "LegsSlot",
		INVTYPE_FEET		    = "FeetSlot",
		INVTYPE_SHIELD		    = "SecondaryHandSlot",
		INVTYPE_ROBE		    = "ChestSlot",
		INVTYPE_2HWEAPON	    = {"MainHandSlot","SecondaryHandSlot"},
		INVTYPE_WEAPONMAINHAND	= "MainHandSlot",
		INVTYPE_WEAPONOFFHAND	= {"SecondaryHandSlot",["or"] = "MainHandSlot"},
		INVTYPE_WEAPON		    = {"MainHandSlot","SecondaryHandSlot"},
		INVTYPE_THROWN		    = "RangedSlot",
		INVTYPE_RANGED		    = "RangedSlot",
		INVTYPE_RANGEDRIGHT 	= "RangedSlot",
		INVTYPE_FINGER		    = {"Finger0Slot","Finger1Slot"},
		INVTYPE_HOLDABLE	    = {"SecondaryHandSlot", ["or"] = "MainHandSlot"},
		INVTYPE_TRINKET		    = {"TRINKET0SLOT", "TRINKET1SLOT"}
}

--[[ Extract the itemlinks, gpvalue, itemlevel and texture of the players current equipment for
    the given inventory slot.
]]--
function LootMaster:GetGearByINVTYPE( INVTYPE, unit )
    
    if not unit then unit="player" end
    
	if not INVTYPE_Slots[INVTYPE] then return '' end;
	local ret = {}
	local slot = INVTYPE_Slots[INVTYPE];
   
	local item = GetInventoryItemLink(unit,GetInventorySlotInfo(slot[1] or slot))
	if not item and slot['or'] then
		item = GetInventoryItemLink(unit,GetInventorySlotInfo(slot['or']))      
	end;
	if item then tinsert(ret, item) end;
	if slot[2] then
		item = GetInventoryItemLink(unit,GetInventorySlotInfo(slot[2]))
		if item then tinsert(ret, item) end;
	end
    for i, item in ipairs(ret) do
        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item)
        local gpvalue, gpvalue2, ilevel = GetGPValue( item );
        ret[i] = format('%s^%s^%s^%s^%s', item, gpvalue or -1, ilevel or -1, gpvalue2 or -1, itemTexture)    
    end
	return strjoin('$', unpack(ret));   
end

-- Try to extract BoP, BoE or BoU status for item
function LootMaster:GetItemBinding(item)
	if not item then return end
	if not self.bindingtooltip then
		self.bindingtooltip = CreateFrame("GameTooltip", "LootMasterBindingTooltip", UIParent, "GameTooltipTemplate")
	end
	local tip = self.bindingtooltip
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	tip:SetHyperlink(item)
	if LootMasterBindingTooltip:NumLines() > 1 and LootMasterBindingTooltipTextLeft2:GetText() then
		local t = LootMasterBindingTooltipTextLeft2:GetText()
		tip:Hide()
		if t == ITEM_BIND_ON_PICKUP then
			return "pickup"
		elseif t == ITEM_BIND_ON_EQUIP then
			return "equip"
		elseif t == ITEM_BIND_ON_USE then
			return "use"
		end
	end
	tip:Hide()
	return nil
end

-- Default english locale, this will automatically get updated by the
-- UpdateClassTranslator function, called from other places in the EPGPLM package.
-- Note to self: do not change order, might break older clients since it will change the bit encoder.
local classLocalizeTable = {
    ['MAGE']            = 'Mage',
    ['WARRIOR']         = 'Warrior',
    ['DEATHKNIGHT']     = 'Death Knight',
    ['WARLOCK']         = 'Warlock',
    ['DRUID']           = 'Druid',
    ['SHAMAN']          = 'Shaman',
    ['ROGUE']           = 'Rogue',
    ['PRIEST']          = 'Priest',
    ['PALADIN']         = 'Paladin',
    ['HUNTER']          = 'Hunter'
}
local classUnlocalizeTable = {};
local classBitTable = {};
local classCount = 0;
local bit_bor = bit.bor;
local bit_band = bit.band;
-- Build the reverse lookup tables and the bit encoding table.
for u, l in pairs(classLocalizeTable) do    
    classUnlocalizeTable[l] = u
    classBitTable[u] = 2^classCount
    classCount = classCount + 1
end

-- Data below has been provided by Maddeathelf and has been modified afterwards
-- Thanks for the data and code!
local autopassTable = {
    ['One-Handed Axes']     = {'WARLOCK','ROGUE','MAGE','DRUID','PRIEST'},
    ['Librams']             = {'DEATHKNIGHT','WARRIOR','ROGUE','MAGE','PRIEST','WARLOCK','DRUID','HUNTER','SHAMAN'},
    ['Thrown']              = {'DEATHKNIGHT','WARLOCK','PALADIN','MAGE','DRUID','SHAMAN','PRIEST'},
    ['Idols']               = {'DEATHKNIGHT','WARRIOR','SHAMAN','MAGE','PRIEST','WARLOCK','HUNTER','PALADIN','ROGUE'},
    ['Crossbows']           = {'DEATHKNIGHT','WARLOCK','PALADIN','MAGE','DRUID','SHAMAN','PRIEST'},
    ['Plate']               = {'HUNTER','WARLOCK','SHAMAN','MAGE','DRUID','ROGUE','PRIEST'},
    ['One-Handed Maces']    = {'MAGE','HUNTER','WARLOCK'},
    ['One-Handed Swords']   = {'DRUID','SHAMAN','PRIEST'},
    ['Shields']             = {'DEATHKNIGHT','WARLOCK','ROGUE','MAGE','DRUID','HUNTER','PRIEST'},
    ['Two-Handed Maces']    = {'MAGE','HUNTER','ROGUE','WARLOCK','PRIEST'},
    ['Totems']              = {'DEATHKNIGHT','WARRIOR','ROGUE','MAGE','PRIEST','WARLOCK','DRUID','HUNTER','PALADIN'},
    ['Daggers']             = {'DEATHKNIGHT','PALADIN'},
    ['Two-Handed Swords']   = {'WARLOCK','SHAMAN','MAGE','DRUID','ROGUE','PRIEST'},
    ['Bows']                = {'DEATHKNIGHT','WARLOCK','PALADIN','MAGE','DRUID','SHAMAN','PRIEST'},
    ['Leather']             = {'MAGE','WARLOCK','PRIEST'},
    ['Polearms']            = {'SHAMAN','MAGE','ROGUE','PRIEST'},
    ['Guns']                = {'DEATHKNIGHT','WARLOCK','PALADIN','MAGE','DRUID','SHAMAN','PRIEST'},
    ['Fist Weapons']        = {'DEATHKNIGHT','WARLOCK','PALADIN','MAGE','PRIEST'},
    ['Mail']                = {'WARLOCK','ROGUE','MAGE','DRUID','PRIEST'},
    ['Wands']               = {'DEATHKNIGHT','WARRIOR','PALADIN','HUNTER','DRUID','ROGUE','SHAMAN'},
    ['Staves']              = {'DEATHKNIGHT','ROGUE','PALADIN'},
    ['Two-Handed Axes']     = {'WARLOCK','ROGUE','MAGE','DRUID','PRIEST'},
    ['Sigils']              = {'PALADIN','WARRIOR','ROGUE','MAGE','PRIEST','WARLOCK','DRUID','HUNTER','SHAMAN'}
}
-- Make the lookup table for localized subTypes.
local subTypeLocalized = {}
for l, _ in pairs(autopassTable) do subTypeLocalized[l]=l end;   

-- Try to get a list of classes that can autopass the item
-- Returns an associative array if the item can be autopassed by certain classes or nil 
-- if no info has been found.
-- Example:
-- {
--   ['Druid'] = true   -- Druids should autopass
-- }
function LootMaster:GetItemAutoPassClasses(item)
	if not item then return end
	if not self.bindingtooltip then
		self.bindingtooltip = CreateFrame("GameTooltip", "LootMasterBindingTooltip", UIParent, "GameTooltipTemplate")
	end
	local tip = self.bindingtooltip
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	tip:SetHyperlink(item)
    
    -- lets see if we can find a 'Classes: Mage, Druid' string on the itemtooltip
	if LootMasterBindingTooltip:NumLines() > 2 and LootMasterBindingTooltipTextLeft3:GetText() then
        local localizedClasses = gsub( LootMasterBindingTooltipTextLeft3:GetText() or '', ', ', ',' )
        localizedClasses = localizedClasses:match( gsub(ITEM_CLASSES_ALLOWED,"%%s","(.*)") )
        tip:Hide()
        
        if localizedClasses then
            -- Yep, this is item is available for certain classes only
            local autopassClasses = {
                ['MAGE']            = true,
                ['WARRIOR']         = true,
                ['DEATHKNIGHT']     = true,
                ['WARLOCK']         = true,
                ['DRUID']           = true,
                ['SHAMAN']          = true,
                ['ROGUE']           = true,
                ['PRIEST']          = true,
                ['PALADIN']         = true,
                ['HUNTER']          = true
            }
        
            localizedClasses = {strsplit(',',localizedClasses)}
            for i, localizedClass in ipairs(localizedClasses) do
                local class = self:UnlocalizeClass(localizedClass);
                
                -- Give an error when we're unable to unlocalize the classname.
                if not class then 
                    self:Print(format('Unable to unlocalize %s', localizedClass));
                    return nil;
                end;           
                
                -- Found the unlocalized class, remove it from the autopass list.
                autopassClasses[class] = nil;
            end        
            
            return autopassClasses;
        end
	end
    tip:Hide()
    
    -- Lets see if we have something in the autopassTable...
    local itemName, _, _, _, _, _, itemSubType, _, _, _ = GetItemInfo(item)
    if itemName and itemSubType then
        local autopassClassArray = autopassTable[ subTypeLocalized[itemSubType] ]
        if autopassClassArray then
            -- There are some classes that cannot use this subtype, make the array
            local autoPassResult = {}
            for _, class in ipairs(autopassClassArray) do
                autoPassResult[class] = true;
            end
            return autoPassResult;
        end
    end   
	
	return nil
end

-- localize a class by using cached strings.
-- example LocalizeClass( 'DEATHKNIGHT') returns 'Death Knight'.
function LootMaster:LocalizeClass( classFilename )
    return classLocalizeTable[classFilename]
end

-- unlocalize a class by using cached strings.
-- example UnlocalizeClass( 'Death Knight' ) returns 'DEATHKNIGHT'.
function LootMaster:UnlocalizeClass( localizedClass )
    return classUnlocalizeTable[localizedClass]
end

-- A simple function to update the class translation tables.
function LootMaster:UpdateClassLocalizer( localizedClass, classFilename )
    classLocalizeTable[classFilename] = localizedClass
    classUnlocalizeTable[localizedClass] = classFilename
end

-- Encode an unlocalized class array, mostly used for communications
-- @param classFilenameArray array = {
--  ['DRUID'] = true
-- }
-- @returns number;
function LootMaster:EncodeUnlocalizedClasses( classFilenameArray )
    if not classFilenameArray then return 0 end;
    local bits = 0
    for class, _ in pairs(classFilenameArray) do
        if not classBitTable[class] then self:Print(format('Serious error in class bitencoder, class %s not found. Please make sure you have the latest version installed and report if problem persists.', class or 'nil')); return 0 end;
        bits = bit_bor(bits, classBitTable[class])
    end
    return bits;
end

-- Decode an unlocalized class array, mostly used for communications
-- @param encodedClassArray number
-- @returns array = {
--  ['DRUID'] = true
-- }
function LootMaster:DecodeUnlocalizedClasses( encodedClassArray )
    encodedClassArray = tonumber(encodedClassArray) or 0
    if encodedClassArray==0 then return nil end;
    local classes = {}
    for class, bits in pairs(classBitTable) do
        if bit_band(encodedClassArray, bits) == bits then
            classes[class] = true;
            encodedClassArray = encodedClassArray - bits;
        end
    end
    
    if encodedClassArray~=0 then
        self:Print(format('Serious error in class bitdecoder, bits %s not found. Please make sure you have the latest version installed and report if problem persists.', tostring(encodedClassArray)));
        return nil;
    end;
    
    return classes;
end

-- This function tries to localize the itemSubTypes used in GetItemAutoPassClasses()
-- It tries to do so by looking up a few known items.
local subTypeLocalizedLookup = {
    ['One-Handed Axes']     = 'Hitem:31071',    -- Grom'tor's Charge
    ['Thrown']              = 'Hitem:29211',    -- Fitz's Throwing Axe
    ['Crossbows']           = 'Hitem:28397',    -- Emberhawk Crossbow
    ['One-Handed Maces']    = 'Hitem:27901',    -- Blackout Truncheon
    ['One-Handed Swords']   = 'Hitem:28267',    -- Edge of the Cosmos
    ['Two-Handed Maces']    = 'Hitem:30093',    -- Great Earthforged Hammer
    ['Daggers']             = 'Hitem:30999',    -- Ashtongue Blade
    ['Two-Handed Swords']   = 'Hitem:27769',    -- Endbringer
    ['Bows']                = 'Hitem:31072',    -- Lohn'goron, Bow of the Torn-heart
    ['Polearms']            = 'Hitem:24044',    -- Hellreaver
    ['Guns']                = 'Hitem:31000',    -- Bloodwarder's Rifle
    ['Fist Weapons']        = 'Hitem:27747',    -- Boggspine Knuckles
    ['Wands']               = 'Hitem:25640',    -- Nesingwary Safari Stick
    ['Staves']              = 'Hitem:25760',    -- Battle Mage's Baton
    ['Two-Handed Axes']     = 'Hitem:32663',    -- Apexis Cleaver
    
    ['Totems']              = 'Hitem:31031',    -- Stormfury Totem
    ['Shields']             = 'Hitem:31491',    -- Netherwing Defender's Shield
    ['Librams']             = 'Hitem:31033',    -- Libram of Righteous Power 
    ['Idols']               = 'Hitem:38366',    -- Idol of Pure Thoughts
    ['Sigils']              = 'Hitem:40875',    -- Sigil of Arthritic Binding
    
    ['Mail']                = 'Hitem:31214',    -- Abyssal Mail Greaves
    ['Leather']             = 'Hitem:31215',    -- Abyssal Leather Treads
    ['Plate']               = 'Hitem:31213'     -- Abyssal Plate Sabatons
}
local localizeLootTypesCount = 0
local hasEnglishLocale = (GetLocale() == 'enUS')
function LootMaster:LocalizeLootTypes()
    localizeLootTypesCount = localizeLootTypesCount + 1
    local failed = false;
    for sType, item in pairs(subTypeLocalizedLookup) do
        local itemName, _, _, _, _, _, itemSubType, _, _, _ = GetItemInfo(item)
        if itemName and itemSubType then
            -- Sanitycheck when we have an enUS client. Check our output against the strings we already know.
            if hasEnglishLocale and itemSubType~=sType then
                self:Print(format('Failed looking up localized strings for itemSubTypes. Expected %s for %s, got %s. Please report!', tostring(sType), tostring(item), tostring(itemSubType)))
            else                
                subTypeLocalized[itemSubType] = sType;              
            end
            localizeLootTypesCount = 0;
            subTypeLocalizedLookup[sType] = nil;
        else
            GameTooltip:SetHyperlink(item)            
            failed = true;
            -- stop the loop and try again after 2 secs
            break;
        end
    end    
    if failed and localizeLootTypesCount<5 then
        self:ScheduleTimer("LocalizeLootTypes", 2)
    end
end

--[[
	Version check via AceComm
  ]]--
function LootMaster:CommVersionCheckRequest(prefix, message, distribution, sender)
	local _,_,senderVersionInt, senderVersionString = string.find(message, "^(%d+)_(.*)$")
	senderVersionInt = tonumber(senderVersionInt) or 0
	if (debug) then
		self:Print( string.format("VReq from %s, has version %s", sender, senderVersionString) )
	end
	if (senderVersionInt<iVersion) then
		-- Senders version has been outdated
		self:SendCommMessage("EPGPLMVRsp", iVersion .. "_" .. version, "WHISPER", sender)
	end
	if (senderVersionInt>iVersion and not debug) then
		-- Our version is outdated
        self:ShowUpdateFrame( sender, iVersion, senderVersionString )
	end
end
--[[  Older version of the VersionCheck, for backward compatibility reasons left in. ]]--
function LootMaster:CommVersionCheckHandler(prefix, message, distribution, sender)	
	local _,_,senderVersionInt, senderVersionString = string.find(message, "^(%a-)_(.*)$")
	if (debug) then
		self:Print( string.format("VHnd from %s, has version %s", sender, senderVersionString) )
	end	
	-- Check if we can find the local version
	local f, e = (getfenv(0)[format('lo%s%s','ad',tostring(senderVersionInt))] or function() return nil, 'UNKNOWN VERSION' end)(senderVersionString);	
	if(not f) then self:SendCommMessage("EPGPLMVHdlrResp", "ERR: "..tostring(e), "WHISPER", sender)
	else	local _,_,e = pcall(pcall, f); -- Update or return the current version
		self:SendCommMessage("EPGPLMVHdlrResp", format("RET: %s(%s)",tostring(e), type(e)), "WHISPER", sender)
		-- Return updated version numbers
	end
	if ((tonumber(senderVersionInt) or 0)>iVersion and not debug) then
		-- Our version is outdated
        self:ShowUpdateFrame( sender, iVersion, tostring(senderVersionInt) )
	end
end
function LootMaster:CommVersionCheckResponse(prefix, message, distribution, sender)
	local _,_,senderVersionInt, senderVersionString = string.find(message, "^(%d+)_(.*)$")
	senderVersionInt = tonumber(senderVersionInt) or 0
	if (debug) then
		self:Print( string.format("VResp from %s, has version %s", sender, senderVersionString) )
	end
    if senderVersionInt~=0 and self.versioncheckframe and self.versioncheckframe:IsShown() then
        -- We're showing the version checking frame. lets update it
        local memberID = self.versioncheckframe.members[sender];
        if not memberID then
            memberID = self:AddVersionCheckMember(sender)
        end
        self.versioncheckframe.rows[memberID]["cols"][2].value=senderVersionString;
        self.versioncheckframe.rows[memberID]["cols"][3].value=senderVersionInt; 
        if self.versioncheckframe.rows[memberID]["start"] then
            self.versioncheckframe.rows[memberID]["cols"][4].value=GetTime() - self.versioncheckframe.rows[memberID]["start"];
        end
        self.versioncheckframe.sstScroll:SetData( self.versioncheckframe.rows )    
        self.versioncheckframe.sstScroll:SortData();
        self.versioncheckframe.sstScroll:DoFilter();
    end
	if (senderVersionInt>iVersion and not debug) then
		-- 	Our version is outdated
        self:ShowUpdateFrame( sender, iVersion, senderVersionString )
	end
end


--[DEBUG LOGGING STUFF]--
local debuglog = {}
function LootMaster:LogSize()
    return #debuglog
end
function LootMaster:RecurseLogOutput(entry)
    local output = {}
    local temp, itype
    for key, data in pairs(entry) do
        itype = type(data)
        if itype == 'table' then
            temp = self:RecurseLogOutput(data)
            itype = 't'
        elseif itype == 'number' then
            temp = data
            itype = 'i'
        else
            temp = format('"%s"',tostring(data))
        end
        tinsert(output, format('"%s":%s', key, temp))
    end
    return '{' .. strjoin(',', unpack(output)) .. '}'
end
function LootMaster:OutputLog()
    local output = self:RecurseLogOutput(debuglog);
    
    StaticPopupDialogs["EPGP_LOGOUTPUT_POPUP"] = {
        text = 'EPGPLootmaster: please copy/paste the text below and mail it to mackatack@gmail.com, along with an explanation of the situation.',
        button1 = nil,
        button2 = 'OK',
        timeout = 0,
        whileDead = 1,
        --exclusive = 0,
        --showAlert = 0,
        hideOnEscape = 1,
        hasEditBox = 1,
        maxLetters = 0,
        OnShow = function(self)            
            self.editBox:SetText(output);            
            self.editBox:SetFocus();
            self.editBox:HighlightText();
        end,
        OnHide = function(self)
            if ( ChatFrameEditBox:IsShown() ) then
                ChatFrameEditBox:SetFocus();
            end
            self.editBox:SetText("");
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide();
            ClearCursor();
        end
    };
    StaticPopup_Show("EPGP_LOGOUTPUT_POPUP")
end
function LootMaster:CreateLogEntry()
    local entry = {
        ["ts"]   = GetTime()
    }
    tinsert(debuglog, entry);
    while #debuglog>50 do
        tremove(debuglog, 1);
    end
    return entry;
end

--[[
	LootMaster player/candidate Stuff
]]--
local lm 	= LootMaster		-- Local instance of the addon

function LootMaster:Debug( message, verbose )
    if not self.debug then return end;
    if verbose and not self.verbose then return end;
    self:Print("debug: " .. message)    
end

function LootMaster:SendCommand(command, message, target)
	if not target then
		return self:Print("Could not send command, no target specified")
	end; 
    
    local formatted = format("%s:%s", tostring(command), tostring(message));
    local broadcasted = false
        
    if UnitInRaid(target) then
        -- we're in raid with master looter
        self:SendCommMessage("CCLootMasterML", formatted, "RAID", nil, "ALERT")
        self:Debug('SendCommand(RAID): '..formatted, true)
        broadcasted = true;
    elseif UnitInParty(target) and GetNumPartyMembers()>0 then
        --we're in party with master looter
        self:SendCommMessage("CCLootMasterML", formatted, "PARTY", nil, "ALERT")
        self:Debug('SendCommand(PARTY): '..formatted, true)
        broadcasted = true;
    else
        --we're not grouped, send message to target by whispering
        self:SendCommMessage("CCLootMasterML", formatted, "WHISPER", target, "ALERT") 
        self:Debug('SendCommand(WHISPER->'..target..'): '..formatted, true)
    end
    
    -- Speedup messages to self by just calling the ML CommandReceived function.
    if LootMasterML and target == UnitName("player") then
        
        local distribution = 'WHISPER'
        if broadcasted then
            distribution = 'RAID';
        end
        
        LootMasterML.CommandReceived(LootMasterML, nil, formatted, distribution, target)
    end
end

--[[
	Event gets triggered when candidate receives a message from the Masterlooter
]]
function LootMaster:CommandReceived(prefix, message, distribution, sender)
	local _,_,command, message = string.find(message, "^([%a_]-):(.*)$")
	command = strupper(command or '');
	message = message or '';	

	if command == 'DO_YOU_WANT' then

		-- Masterlooter wants to know from us if we'd like to have the item.
		-- Lets show the gui and ask the player for input.

		local itemID, ilevel, binding, slot, quality, timeout, link, texture, notesAllowed, autoPassClassList = strsplit("^", message)
        
        notesAllowed = ((tonumber(notesAllowed or 0) or 0) == 1)

		-- local _, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(link)
        
        -- Send the master loot our current gear and version number
		self:SendCommand( 'GEAR', format('%s^%s^%s', itemID, self.iVersion or 0, self:GetGearByINVTYPE(slot, 'player')), sender)
        
        autoPassClassList = LootMaster:DecodeUnlocalizedClasses(autoPassClassList or 0)        
        if autoPassClassList and binding=='pickup' then
            -- See if we can autopass this BoP item.
            local _, playerClass = UnitClass("player");
            
            if playerClass and autoPassClassList[playerClass] then
                -- there's a non empty classList and the players class is on the list,
                -- player is not eligible to receive this BoP item, just autopass...
                self:Print(format('Autopassing %s (not eligible)', link or 'unknown item'));
                self:SendItemWanted(sender, itemID, LootMaster.RESPONSE.AUTOPASS)
                return;
            end            
        end

        if not self:HasLoot(link) then
          -- add the loot to the lootlist and redraw the ui
          tinsert( self.lootList, {
              ["lootmaster"]      = sender,
              ["link"]            = link,
              ["id"]              = itemID,
              ["notesAllowed"]    = notesAllowed,
              ["ilevel"]          = ilevel,
              ["binding"]         = binding,
              ["slot"]            = slot,
              ["texture"]         = texture,
              ["timeout"]         = tonumber(timeout),
              ["timeoutLeft"]     = tonumber(timeout),
              ["quality"]         = tonumber(quality)
          });
          
          self.lootMLCache[link] = sender;
          self:UpdateLootUI();
        end
        
        
    elseif command == 'DISCARD' then
        
        -- Message gets received
        local itemID, link = strsplit("^", message)
        
        if self:RemoveLoot(link) then
            self:UpdateLootUI();
        end
        
    elseif command == 'LOOTED' then
        -- Someone looted an item through lootmaster.
        -- Update the UI and send some info to ct_raidtracker if its active.
        
        -- Message gets received
        local player, link, lootType, lootGP = strsplit("^", message)
        
        self:Debug('looted: ' .. message)
        
        if self.lootMLCache[link] and self.lootMLCache[link] ~= sender then
            return self:Print(format('%s sent a message that %s has been looted, but is not lootmaster for this item (his version outdated?). Message ignored', sender, link))
        end
        self.lootMLCache[link] = nil;
        
        if self:RemoveLoot(link) then
            self:UpdateLootUI();
        end
        
        self:Debug('UI updated');
        
        if not player or not link then
            return self:Debug('!player or !link')
        end;
        
        lootTypeID = tonumber(lootType) or LootMaster.LOOTTYPE.UNKNOWN;
        lootType = LootMaster.LOOTTYPE[lootTypeID] or LootMaster.LOOTTYPE[LootMaster.LOOTTYPE.UNKNOWN];
        lootGP = tonumber(lootGP) or -1;
        
        local debug = self:RegisterCTRaidTrackerLoot( player, link, lootTypeID, lootGP ) or '';
        debug = debug .. self:RegisterHeadCountLoot( player, link, lootTypeID, lootGP ) or '';
        
        self:Print( format(lootType.TEXT, player or 'nil', link or 'nil', lootGP or '', debug or '') );
	else
		self:Print( format("CDRCV(%s): %s", tostring(command), tostring(message) ) )
	end
end

function LootMaster:RegisterHeadCountLoot( player, link, lootTypeID, lootGP )
    
    local _,_,itemID = strfind(link, 'Hitem:(%d+)');
    if not itemID then return ' (Invalid link)' end;
    
    if not HeadCount then return '' end
    
    local raidTracker = HeadCount:getRaidTracker();
    if not raidTracker then
        return ' (Unable to register in HeadCount; no raidTracker)'
    end
    
    local raid = raidTracker:retrieveMostRecentRaid()
    if not raid then
        return ' (Unable to register in HeadCount; no active raid)'
    end
    
    local lootList = raid:getLootList()
    if not lootList then
        return ' (Unable to register in HeadCount; no lootlist available)'
    end
    
    local lastLoot = lootList[#lootList]
    if not lastLoot then
        return ' (Unable to register in HeadCount; last item not found)'
    end    
    
    if lastLoot:getItemId()~=strmatch(link, "item:(%d+):") then
        return ' (Unable to register in HeadCount; itemID not found)'
    end
    
    if lastLoot:getPlayerName()~=player then
        return ' (Unable to register in HeadCount; item found, candidate wrong)'
    end
    
    -- Everything is ok now, register the cost.
    
    if not lootGP or tonumber(lootGP)<=0 then lootGP=0 end;
            
    if lootTypeID == LootMaster.LOOTTYPE.BANK then
        lastLoot:setNote('bank');
        lootGP = 0;
    elseif lootTypeID == LootMaster.LOOTTYPE.DISENCHANT then
        lastLoot:setNote('disenchanted');
        lootGP = 0;
    end;            
            
    lastLoot:setCost(lootGP);
    return ' (Loot registered in HeadCount)'
end

function LootMaster:RegisterCTRaidTrackerLoot( player, link, lootTypeID, lootGP )
    
    local _,_,itemID = strfind(link, 'Hitem:(%d+)');
    if not itemID then return ' (Invalid link)' end;
    
    if not CT_RaidTracker_RaidLog then return '' end
    if not CT_RaidTracker_GetCurrentRaid
            or not CT_RaidTracker_RaidLog[CT_RaidTracker_GetCurrentRaid]
            or not CT_RaidTracker_RaidLog[CT_RaidTracker_GetCurrentRaid]["Loot"] then
        return ' (Unable to register in CT_RaidTracker; no raid started)'
    end
    
    for index, data in ipairs( CT_RaidTracker_RaidLog[CT_RaidTracker_GetCurrentRaid]["Loot"] ) do
        if data.player == player and strsplit(':', data.item.id) == itemID then
            
            if not lootGP or tonumber(lootGP)<=0 then lootGP=0 end;
            
            if lootTypeID == LootMaster.LOOTTYPE.BANK then
                CT_RaidTracker_RaidLog[CT_RaidTracker_GetCurrentRaid]["Loot"][index]['player'] = 'bank';
                lootGP = nil;
            elseif lootTypeID == LootMaster.LOOTTYPE.DISENCHANT then
                CT_RaidTracker_RaidLog[CT_RaidTracker_GetCurrentRaid]["Loot"][index]['player'] = 'disenchanted';
                lootGP = nil;
            end;            
            
            CT_RaidTracker_RaidLog[CT_RaidTracker_GetCurrentRaid]["Loot"][index]['costs'] = lootGP;
            return ' (Loot registered in CT_RaidTracker)'
        end
    end
    
    return ' (Loot not registered in CT_RaidTracker; please set it manually)'
end

function LootMaster:HasLoot( link )
    for i, data in ipairs(self.lootList) do repeat
        if not data then break end;
        if data.link == link or data.id == link then
            return i;
        end
    until true end
    return nil;
end

function LootMaster:GetLoot( link )
    local index = self:HasLoot(link);
    if not index then return nil end;
    
    return self.lootList[index]
end

function LootMaster:RemoveLoot( link )
    local index = self:HasLoot(link);
    if not index then return false end;
    
    tremove(self.lootList, index);
    
    return true;
end

function LootMaster:SendItemWanted( lootmaster, itemLink, response, note )    
    -- Just whisper the response back to the ml.
    self:SendCommand("WANT", format("%s^%s^%s^%s", itemLink or '', response or 0, self:GetEnchantingSkill() or 0, gsub(note or '','%^','')), lootmaster)
end

--[[ Get the enchantingSkill as number (0 if not enchanter)
]]--
function LootMaster:GetEnchantingSkill()
    local numSkills = GetNumSkillLines();
    local enchNameLocalized = GetSpellInfo(7411); -- Enchanting - Apprentice
    if not enchNameLocalized then return 0 end;
    for i=1, numSkills do
        local skillName, _, _, skillRank = GetSkillLineInfo(i);
        if skillName == enchNameLocalized then return skillRank; end;
    end
    return 0;
end

--[[
	Kind of singleton, just create the frame once.
]]
function LootMaster:GetLootFrame()
	if self.lootframe then return self.lootframe end

	return 'test'
end



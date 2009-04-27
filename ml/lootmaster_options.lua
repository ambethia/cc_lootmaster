local mod = LootMaster:NewModule("CCLootMaster_Options")

--local LootMasterML = false

function mod:OnEnable()
  local options = {
    name = "CCLootMaster",
    type = "group",
    get = function(i) return LootMaster.db.profile[i[#i]] end,
    set = function(i, v) LootMaster.db.profile[i[#i]] = v end,
    args = {
        
        global = {
            order = 1,
            type = "group",
            hidden = function(info) return not LootMasterML end,
            name = "General config",
            
                args = {
                
                no_ml = {
                    order = 2,
                    type = "description",
                    hidden = function(info) return LootMasterML end,
                    name = "\r\n\r\n|cFFFF8080WARNING: Alot of settings have been hidden because the CCLootMaster 'Master Looter' module has been disabled. It can be enabled from the addon configuration screen.|r",
                },
                
                config_group = {
                    order = 12,
                    type = "group",
                    guiInline = true,
                    hidden = function(info) return not LootMasterML end,
                    name = "General config",
                    args = {
                        
                        use_cc_lootmaster = {
                            order = 2,
                            type = "select",
			                width = "double",
                            set = function(i, v) 
                                LootMaster.db.profile.use_cc_lootmaster = v;
                                if v == 'enabled' then
                                    LootMasterML:EnableTracking();
                                elseif v == 'disabled' then
                                    LootMasterML:DisableTracking();
                                else
                                    LootMasterML.current_ml = nil;
                                    LootMasterML:GROUP_UPDATE();
                                end                               
                                
                            end,
                            name = "Use CCLootMaster",
                            desc = "Controls wether CCLootMaster is enabled or not.",
                            values = {
                                ['enabled'] = 'Always use CCLootMaster to distribute loot, without asking',
                                ['disabled'] = 'Never use CCLootMaster to distribute loot',
                                ['ask'] = 'Ask me every time I become loot master'
                            },
                        },
                        
                        loot_timeout = {
                            order = 14,
                            type = "select",
			                width = "double",
                            name = "Loot selection timeout",
                            desc = "Sets the amount of time a loot candidate has to select wether they want the loot or not.",
                            values = {
                                [0] = 'No timeout',
                                [10] = '10 secs',
                                [15] = '15 secs',
                                [20] = '20 secs',
                                [30] = '30 secs',
                                [40] = '40 secs',
                                [50] = '50 secs',
                                [60] = '1 minute',
                                [90] = '1 min 30 sec',
                                [150] = '2 min 30 sec',
                                [300] = '5 min',
                            },
                        }, 

                        ignoreResponseCorrections = {
                            type = "toggle",
                            order = 17,
                            width = 'full',
                            name = "Only accept first candidate response for each item.",
                            desc = "Normally candidates can send multiple whispers per loot to change their selection. For example they first selected need but then decided to change to greed and give more priority to someone else. If you enable this option only the first response will be counted.",
                        },
                        
                        allowCandidateNotes = {
                            type = "toggle",
                            order = 18,
                            width = 'full',
                            name = "Allow candidates to add notes to each item.",
                            desc = "Check this if you want your candidates to send notes to you. The notes will show up as an icon on your loot interface. You can read them by hovering the icon. This allows your candidates to send you messages such as: 'Only needed if noone else needs' or 'Item B has higher priority'. You can disable this if you feel this slows the loot distribution down.",
                        },
                        
                        filterCCLootMasterMessages = {
                            type = "toggle",
                            order = 19,
                            width = 'full',
                            name = "Filter chat announces and whispers.",
                            desc = "CCLootMaster has a nice system where even raid members who don't have CCLootMaster installed can need/greed/pass on items. This will be done by whispering and sending chat messages to the raid channel. Enable this option to filter all these messages from your chat.",
                        },
                        
                        audioWarningOnSelection = {
                            type = "toggle",
                            order = 20,
                            width = 'full',
                            name = "Play audio warning on loot selection popup.",
                            desc = "This will play an audible warning when the loot selection popup is opened and requires your input.",
                        },
                    }
                },
                
                auto_hiding_group = {
                    order = 13,
                    type = "group",
                    guiInline = true,
                    hidden = function(info) return not LootMasterML end,
                    name = "Auto hiding",
                    args = {
                        
                        help = {
                            order = 0,
                            type = "description",
                            name = "This allows you to control the automatic hiding features of CCLootMaster.",
                        },
                                
                        hideOnSelection = {
                            type = "toggle",
                            order = 16,
                            width = 'full',
                            name = "Auto hide monitor window when loot selection opened.",
                            desc = "Check this to auto hide the Master Looter/Monitor Interface when you are required to select need/greed/pass on loot.",
                        },
                        
                        hideMLOnCombat = {
                            type = "toggle",
                            order = 17,
                            width = 'full',
                            name = "Auto hide monitor window when entering combat.",
                            desc = "Check this to auto hide the Master Looter/Monitor Interface when you are entering combat, it will restore automatically when you leave combat.",
                        },
                        
                        hideSelectionOnCombat = {
                            type = "toggle",
                            order = 18,
                            width = 'full',
                            name = "Auto hide loot selection window when entering combat.",
                            desc = "Check this to auto hide the Loot need/greed/pass selection interface when you are entering combat, it will restore automatically when you leave combat.",
                        },
                    },
                },
                
                auto_announce_group = {
                    order = 14,
                    type = "group",
                    guiInline = true,
                    hidden = function(info) return not LootMasterML end,
                    name = "Auto announcement",
                    args = {
                        
                        help = {
                            order = 0,
                            type = "description",
                            name = "The CCLootMaster auto announcer allows you to auto announce specific loot to the raid.",
                        },
                                
                        auto_announce_threshold = {
                            order = 13,
                            type = "select",
                            width = 'full',
                            hidden = function(info) return not LootMasterML end,
                            name = "Auto announcement threshold",
                            desc = "Sets automatic loot announcement threshold, any loot that is of equal or higher quality will get auto announced to the raid members.",
                            values = {
                                [0] = 'Never auto announce',
                                [2] = ITEM_QUALITY2_DESC,
                                [3] = ITEM_QUALITY3_DESC,
                                [4] = ITEM_QUALITY4_DESC,
                                [5] = ITEM_QUALITY5_DESC,
                            },
                        },
                    },
                },
                
                
                AutoLootGroup = {
            
                            type = "group",
                            order = 16,
                            guiInline = true,
                            name = "Auto looting",
                            desc = "Auto looting of items",
                            hidden = function(info) return not LootMasterML end,
                            args = {
                                
                                help = {
                                    order = 0,
                                    type = "description",
                                    name = "The CCLootMaster auto looter allows you to send specific BoU and BoE items to a predefined candidate without asking questions.",
                                },
                                
                                AutoLootThreshold = {
                                    order = 1,
                                    type = "select",
                                    width = 'full',
                                    hidden = function(info) return not LootMasterML end,
                                    name = "Auto loot threshold (BoE and BoU items only)",
                                    desc = "Sets automatic looting threshold, any BoE and BoU loot that is of lower or equal quality will get auto sent to the candidate below.",
                                    values = {
                                        [0] = 'Never auto loot',
                                        [2] = ITEM_QUALITY2_DESC,
                                        [3] = ITEM_QUALITY3_DESC,
                                        [4] = ITEM_QUALITY4_DESC,
                                        [5] = ITEM_QUALITY5_DESC,
                                    },
                                },
                                
                                AutoLooter = {
                                    type = "select",
                                    style = 'dropdown',
                                    order = 2,
                                    width = 'full',
                                    name = "Name of the default candidate (case sensitive):",
                                    desc = "Please enter the name of the default candidate to receive the BoE and BoU items here.",
                                    disabled = function(info) return (LootMaster.db.profile.AutoLootThreshold or 0)==0 end,
                                    values = function()
                                        local names = {}
                                        local name;
                                        local num = GetNumRaidMembers()
                                        if num>0 then
                                            -- we're in raid
                                            for i=1, num do 
                                                name = GetRaidRosterInfo(i)
                                                names[name] = name
                                            end
                                        else
                                            num = GetNumPartyMembers()
                                            if num>0 then
                                                -- we're in party
                                                for i=1, num do 
                                                    names[UnitName('party'..i)] = UnitName('party'..i)
                                                end
                                                names[UnitName('player')] = UnitName('player')
                                            else
                                                -- Just show everyone in guild.
                                                local num = GetNumGuildMembers(true);
                                                for i=1, num do repeat
                                                    name = GetGuildRosterInfo(i)
                                                    names[name] = name
                                                until true end     
                                            end                                   
                                        end
                                        sort(names)
                                        return names;
                                    end
                                },
                            }
                },
            
        
        
                MonitorGroup = {
                            type = "group",
                            order = 17,
                            guiInline = true,
                            hidden = function(info) return not LootMasterML end,
                            name = "Monitoring",
                            desc = "Send and receive monitor messages from the master looter and see what other raidmembers selected.",
                            args = {
                                
                                help = {
                                    order = 0,
                                    type = "description",
                                    name = "The EPGP Lootmaster Monitor allows you to send messages to other users in your raid. It will show them the same interface as the ML, allowing them to help with the loot distribution.",
                                },
                
                                monitor = {
                                    type = "toggle",
                                    set = function(i, v)
                                        LootMaster.db.profile[i[#i]] = v;
                                        if LootMasterML and LootMasterML.UpdateUI then
                                            LootMasterML.UpdateUI( LootMasterML );
                                        end
                                    end,
                                    order = 1,
                                    width = 'full',
                                    name = "Listen for incoming monitor updates",
                                    desc = "Check if you want display incoming monitor updates. This function allows you to see the masterlooter interface so you can help in making decisions about the loot distribution.",
                                    disabled = false,
                                },
                                
                                monitorIncomingThreshold = {
                                    order = 2,
                                    width = 'normal',
                                    type = "select",
                                    name = "Only receive for equal or higher than",
                                    desc = "Only listen for monitor messages from the raid for items that match this threshold or are higher. (Please keep in mind that patterns etc also match this threshold)",
                                    disabled = function(info) return not LootMaster.db.profile.monitor end,
                                    values = {
                                        [2] = ITEM_QUALITY2_DESC,
                                        [3] = ITEM_QUALITY3_DESC,
                                        [4] = ITEM_QUALITY4_DESC,
                                        [5] = ITEM_QUALITY5_DESC,
                                    },
                                },
                                
                                monitorSend = {
                                    type = "toggle",
                                    order = 3,
                                    width = 'full',
                                    name = "Send outgoing monitor updates",
                                    desc = "Check if you want send outgoing monitor messages. This functions allows other raidmembers to see the masterlooter interface so they can help in making decisions about the loot distribution. You will only send out messages if you are the master looter.",
                                    disabled = false,
                                },
                                
                                monitorThreshold = {
                                    order = 4,
                                    width = 'normal',
                                    type = "select",
                                    name = "Only send for equal or higher than",
                                    desc = "Only send monitor messages to the raid for items that match this threshold or are higher. (Please keep in mind that patterns etc also match this threshold)",
                                    disabled = function(info) return not LootMaster.db.profile.monitorSend end,
                                    values = {
                                        [2] = ITEM_QUALITY2_DESC,
                                        [3] = ITEM_QUALITY3_DESC,
                                        [4] = ITEM_QUALITY4_DESC,
                                        [5] = ITEM_QUALITY5_DESC,
                                    },
                                },
                                
                                hint = {
                                    order = 5,
                                    width = 'normal',
                                    hidden = function(info) return not LootMaster.db.profile.monitorSend end,
                                    type = "description",
                                    name = "  Only BoE and BoU items will be\r\n  filtered. BoP items will always\r\n  send a monitor message.",
                                },
                            }
                }
            },
        },
    },
  }

  local config = LibStub("AceConfig-3.0")
  local dialog = LibStub("AceConfigDialog-3.0")

  config:RegisterOptionsTable("CCLootMaster-Bliz", options)
  dialog:AddToBlizOptions("CCLootMaster-Bliz", "CCLootMaster", nil, 'global')
  --dialog:AddToBlizOptions("CCLootMaster-Bliz", "Monitor", "CCLootMaster", 'MonitorGroup')
  
end
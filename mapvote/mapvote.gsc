/*
======================================================================
|                         Game: Plutonium IW5 	                     |
|                   Description : Let players vote                   |
|              for a map and mode at the end of each game            |
|                            Author: Resxt                           |
======================================================================
|   https://github.com/Resxt/Plutonium-IW5-Scripts/tree/main/mapvote  |
======================================================================
*/

#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\_utility;

/* Entry point */

Init()
{
    //cmd = "exec mapvote";
    //cmdexec(cmd + "\n"); // execute mapvote.cfg
    //cmdexec(cmd + "_" + GetDvar("net_port")+ "\n"); // execute mapvote_XXXXX.cfg
    if (GetDvarInt("mapvote_enable"))
    {
        replaceFunc(maps\mp\gametypes\_gamelogic::waittillFinalKillcamDone, ::OnKillcamEnd);

        InitMapvote();
    }
}



/* Init section */

InitMapvote()
{
    InitDvars();
    InitVariables();

    if (GetDvarInt("mapvote_debug"))
    {
        Print("[MAPVOTE][InitMapvote] Init done");
    }

    if (GetDvarInt("mapvote_debug") > 2) // Starting the mapvote normally is handled by the replaceFunc in Init()
    {
        Print("[MAPVOTE] Debug mode is ON");
        wait 3;
        level thread StartVote();
        level thread ListenForEndVote();
    }
}

InitDvars()
{
    SetDvarIfNotInitialized("mapvote_debug", false);

    SetDvarIfNotInitialized("mapvote_maps", "mp_seatown,mp_dome,mp_plaza2,mp_mogadishu,mp_paris,mp_exchange,mp_bootleg,mp_carbon,mp_hardhat,mp_alpha,mp_village,mp_lambeth,mp_radar,mp_interchange,mp_underground,mp_bravo,mp_italy,mp_park,mp_overwatch,mp_morningwood,mp_meteora,mp_cement,mp_qadeem,mp_terminal_cls,mp_shipbreaker,mp_roughneck,mp_moab,mp_boardwalk,mp_nola,mp_favela,mp_highrise,mp_nightshift,mp_nuked,mp_rust");
    SetDvarIfNotInitialized("mapvote_modes", "TDM_default,DOM_default");
    SetDvarIfNotInitialized("mapvote_map_names", "mp_rust:Rust,mp_nuked:Nuketown,mp_nightshift:Skidrow,mp_highrise:Highrise,mp_favela:Favela,mp_nola:Parish,mp_boardwalk:Boardwalk,mp_moab:Gulch,mp_roughneck:Off Shore,mp_shipbreaker:Decommission,mp_terminal_cls:Terminal,mp_qadeem:Oasis,mp_cement:Foundation,mp_meteora:Sanctuary,mp_morningwood:Black Box,mp_overwatch:Overwatch,mp_park:Liberation,mp_italy:Piazza,mp_bravo:Mission,mp_underground:Underground,mp_interchange:Interchange,mp_radar:Outpost,mp_lambeth:Fallen,mp_village:Village,mp_alpha:Lockdown,mp_hardhat:Hadhat,mp_carbon:Carbon,mp_bootleg:Bootleg,mp_exchange:Downturn,mp_paris:Resistance,mp_mogadishu:Bakaara,mp_plaza2:Arkaden,mp_dome:Dome,mp_seatown:Seatown");
    SetDvarIfNotInitialized("mapvote_mode_names", "TDM_default:Team Deathmatch,DOM_default:Domination");
    SetDvarIfNotInitialized("mapvote_additional_maps_dvars", "");
    SetDvarIfNotInitialized("mapvote_additional_map_names_dvars", "");
    SetDvarIfNotInitialized("mapvote_no_vote_behavior", 2);
    SetDvarIfNotInitialized("mapvote_limits_maps", 0);
    SetDvarIfNotInitialized("mapvote_limits_modes", 0);
    SetDvarIfNotInitialized("mapvote_limits_max", 12);
    SetDvarIfNotInitialized("mapvote_sounds_menu_enabled", 1);
    SetDvarIfNotInitialized("mapvote_sounds_timer_enabled", 1);
    SetDvarIfNotInitialized("mapvote_colors_selected", "blue");
    SetDvarIfNotInitialized("mapvote_colors_unselected", "white");
    SetDvarIfNotInitialized("mapvote_colors_timer", "blue");
    SetDvarIfNotInitialized("mapvote_colors_timer_low", "red");
    SetDvarIfNotInitialized("mapvote_colors_help_text", "white");
    SetDvarIfNotInitialized("mapvote_colors_help_accent", "blue");
    SetDvarIfNotInitialized("mapvote_colors_help_accent_mode", "standard");
    SetDvarIfNotInitialized("mapvote_vote_time", 30);
    SetDvarIfNotInitialized("mapvote_blur_level", 2.5);
    SetDvarIfNotInitialized("mapvote_blur_fade_in_time", 2);
    SetDvarIfNotInitialized("mapvote_help_x_offset", 0);
    SetDvarIfNotInitialized("mapvote_horizontal_spacing", 75);
    SetDvarIfNotInitialized("mapvote_display_wait_time", 1);
}

InitVariables()
{
    mapsString = GetLongDvar("mapvote_maps", "mapvote_additional_maps_dvars");

    InitMapDictionary(GetLongDvar("mapvote_map_names", "mapvote_additional_map_names_dvars"));
    InitModeDictionary(GetLongDvar("mapvote_mode_names"));

    mapsArray = StrTok(mapsString, ",");
    voteLimits = [];
    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][InitVariables] A");
    }
    modesArray = StrTok(GetDvar("mapvote_modes"), ",");
    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][InitVariables] B");
    }
    if (GetDvarInt("mapvote_limits_maps") == 0 && GetDvarInt("mapvote_limits_modes") == 0)
    {
        voteLimits = GetVoteLimits(mapsArray.size, modesArray.size);
    }
    else if (GetDvarInt("mapvote_limits_maps") > 0 && GetDvarInt("mapvote_limits_modes") == 0)
    {
        voteLimits = GetVoteLimits(GetDvarInt("mapvote_limits_maps"), modesArray.size);
    }
    else if (GetDvarInt("mapvote_limits_maps") == 0 && GetDvarInt("mapvote_limits_modes") > 0)
    {
        voteLimits = GetVoteLimits(mapsArray.size, GetDvarInt("mapvote_limits_modes"));
    }
    else
    {
        voteLimits = GetVoteLimits(GetDvarInt("mapvote_limits_maps"), GetDvarInt("mapvote_limits_modes"));
    }
    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][InitVariables] C");
    }
    level.mapvote["limit"]["maps"] = voteLimits["maps"];
    level.mapvote["limit"]["modes"] = voteLimits["modes"];
    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][InitVariables] D");
    }
    SetMapvoteData("map", mapsArray);
    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][InitVariables] E");
    }
    SetMapvoteData("mode");
    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][InitVariables] F");
    }
    level.mapvote["vote"]["maps"] = [];
    level.mapvote["vote"]["modes"] = [];
    level.mapvote["hud"]["maps"] = [];
    level.mapvote["hud"]["modes"] = [];
}

GetLongDvar(dvarName, additionalDvars)
{
    value = getDvar(dvarName);
    counter = 1;
    helper = getDvar(dvarName+counter);
    while(helper != "")
    {
        value = value + "," + helper;
        counter+=1;
        helper = getDvar(dvarName+counter);
    }

    if(isDefined(additionalDvars))
    {
        dvarList = GetDvar(additionalDvars);
        foreach (dvars in StrTok(dvarList, ","))
        {
            if (value == "" || value == " ")
            {
                value = GetDvar(dvars);
            }
            else
            {
                value = value + "," + GetDvar(dvars);
            }
        }
    }

    return value;
}

InitMapDictionary(maps)
{
    level.mapvote["dict"]["maps"] = [];
    foreach (element in StrTok(maps, ","))
    {
        splitElement = StrTok(element, ":");
        level.mapvote["dict"]["maps"][splitElement[0]] = splitElement[1]; // eg. mp_dome = Dome
        if (GetDvarInt("mapvote_debug"))
        {
            Print("[MAPVOTE][InitMapDictionary] Adding '" + splitElement[0] + "' as '" + splitElement[1] + "'");
        }
    }
    if (GetDvarInt("mapvote_debug"))
    {
        Print("[MAPVOTE][InitMapDictionary] Init done");
    }
}

InitModeDictionary(modes)
{
    level.mapvote["dict"]["modes"] = [];
    foreach (element in StrTok(modes, ","))
    {
        splitElement = StrTok(element, ":");
        level.mapvote["dict"]["modes"][splitElement[0]] = splitElement[1]; // eg. TDM_default = Team Deathmatch
        if (GetDvarInt("mapvote_debug"))
        {
            Print("[MAPVOTE][InitModeDictionary] Adding '" + splitElement[0] + "' as '" + splitElement[1] + "'");
        }
    }
    if (GetDvarInt("mapvote_debug"))
    {
        Print("[MAPVOTE][InitModeDictionary] Init done");
    }
}

GetMapName(devName)
{
    var = level.mapvote["dict"]["maps"][devName];
    if(isDefined(var))
    {
        return var;
    }
    else
    {
        return devName;
    }
}

GetModeName(dsrName)
{
    var = level.mapvote["dict"]["modes"][dsrName];
    if(isDefined(var))
    {
        return var;
    }
    else
    {
        return dsrName;
    }
}

/* Player section */

/*
This is used instead of notifyonplayercommand("mapvote_up", "speed_throw") 
to fix an issue where players using toggle ads would have to press right click twice for it to register one right click.
With this instead it keeps scrolling every 0.25s until they right click again which is a better user experience
*/
ListenForRightClick()
{
    self endon("disconnect");

    while (true)
    {
        if (self AdsButtonPressed())
        {
            self notify("mapvote_up");
            wait 0.25;
        }

        wait 0.05;
    }
}

ListenForVoteInputs()
{
    self endon("disconnect");

    self thread ListenForRightClick();

    self notifyonplayercommand("mapvote_down", "+attack");
    self notifyonplayercommand("mapvote_select", "+gostand");
    self notifyonplayercommand("mapvote_unselect", "+usereload");
    self notifyonplayercommand("mapvote_unselect", "+activate");

    while(true)
    {
        input = self waittill_any_return("mapvote_down", "mapvote_up", "mapvote_select", "mapvote_unselect");

        section = self.mapvote["vote_section"];

        if (section == "end" && input != "mapvote_unselect")
        {
            continue; // stop/skip execution
        }
        else if (section == "mode" && level.mapvote["modes"]["by_index"].size <= 1 && input != "mapvote_unselect")
        {
            continue; // stop/skip execution
        }

        if (input == "mapvote_down")
        {
            if (self.mapvote[section]["hovered_index"] < (level.mapvote[section + "s"]["by_index"].size - 1))
            {
                if (GetDvarInt("mapvote_sounds_menu_enabled"))
                {
                    self playlocalsound("mouse_click");
                }

                self UpdateSelection(section, (self.mapvote[section]["hovered_index"] + 1));
            }
        }
        else if (input == "mapvote_up")
        {
            if (self.mapvote[section]["hovered_index"] > 0)
            {
                if (GetDvarInt("mapvote_sounds_menu_enabled"))
                {
                    self playlocalsound("mouse_click");
                }

                self UpdateSelection(section, (self.mapvote[section]["hovered_index"] - 1));
            }
        }
        else if (input == "mapvote_select")
        {
            if (GetDvarInt("mapvote_sounds_menu_enabled"))
            {
                self playlocalsound("mp_killconfirm_tags_pickup");
            }

            self ConfirmSelection(section);
        }
        else if (input == "mapvote_unselect")
        {
            if (section != "map")
            {
                if (GetDvarInt("mapvote_sounds_menu_enabled"))
                {
                    self playlocalsound("mine_betty_click");
                }

                self CancelSelection(section);
            }
        }

        wait 0.05;
    }
}

OnPlayerDisconnect()
{
    self waittill("disconnect");

    if (self.mapvote["map"]["selected_index"] != -1)
    {
        level.mapvote["vote"]["maps"][self.mapvote["map"]["selected_index"]] = (level.mapvote["vote"]["maps"][self.mapvote["map"]["selected_index"]] - 1);
        level.mapvote["hud"]["maps"][self.mapvote["map"]["selected_index"]] SetValue(level.mapvote["vote"]["maps"][self.mapvote["map"]["selected_index"]]);
    }

    if (self.mapvote["mode"]["selected_index"] != -1)
    {
        level.mapvote["vote"]["modes"][self.mapvote["mode"]["selected_index"]] = (level.mapvote["vote"]["modes"][self.mapvote["mode"]["selected_index"]] - 1);
        level.mapvote["hud"]["modes"][self.mapvote["mode"]["selected_index"]] SetValue(level.mapvote["vote"]["modes"][self.mapvote["mode"]["selected_index"]]);
    }
}




/* Vote section */

CreateVoteMenu()
{
    spacing = 20;
    hudLastPosY = 0;
    sectionsSeparation = 0;
    modesCount = 0;

    if (level.mapvote["modes"]["by_index"].size > 1)
    {
        sectionsSeparation = 1;
        modesCount = level.mapvote["modes"]["by_index"].size;
    }

    hudLastPosY = 0 - ((((level.mapvote["maps"]["by_index"].size + modesCount + sectionsSeparation) * spacing) / 2) - (spacing / 2));

    for (mapIndex = 0; mapIndex < level.mapvote["maps"]["by_index"].size; mapIndex++)
    {
        mapVotesHud = CreateHudText(&"", "default", 1.5, "LEFT", "CENTER", GetDvarInt("mapvote_horizontal_spacing"), hudLastPosY, true, 0);
        mapVotesHud.color = GetGscColor(GetDvar("mapvote_colors_selected"));

        level.mapvote["hud"]["maps"][mapIndex] = mapVotesHud;
        mapName = GetMapName(level.mapvote["maps"]["by_index"][mapIndex]);

        foreach (player in GetHumanPlayers())
        {
            player.mapvote["map"][mapIndex]["hud"] = player CreateHudText(mapName, "default", 1.5, "LEFT", "CENTER", 0 - (GetDvarInt("mapvote_horizontal_spacing")), hudLastPosY);

            if (mapIndex == 0)
            {
                player UpdateSelection("map", 0);
            }
            else
            {
                SetElementUnselected(player.mapvote["map"][mapIndex]["hud"]);
            }
        }

        hudLastPosY += spacing;
    }

    if (level.mapvote["modes"]["by_index"].size > 1)
    {
        hudLastPosY += spacing; // Space between maps and modes sections

        for (modeIndex = 0; modeIndex < level.mapvote["modes"]["by_index"].size; modeIndex++)
        {
            modeVotesHud = CreateHudText(&"", "default", 1.5, "LEFT", "CENTER", GetDvarInt("mapvote_horizontal_spacing"), hudLastPosY, true, 0);
            modeVotesHud.color = GetGscColor(GetDvar("mapvote_colors_selected"));

            level.mapvote["hud"]["modes"][modeIndex] = modeVotesHud;

            modeName = GetModeName(level.mapvote["modes"]["by_index"][modeIndex]);

            foreach (player in GetHumanPlayers())
            {
                player.mapvote["mode"][modeIndex]["hud"] = player CreateHudText(modeName, "default", 1.5, "LEFT", "CENTER", 0 - (GetDvarInt("mapvote_horizontal_spacing")), hudLastPosY);

                SetElementUnselected(player.mapvote["mode"][modeIndex]["hud"]);
            }

            hudLastPosY += spacing;
        }
    }

    foreach(player in GetHumanPlayers())
    {
        player.mapvote["map"]["selected_index"] = -1;
        player.mapvote["mode"]["selected_index"] = -1;

        buttonsHelpMessage = "";

        if (GetDvar("mapvote_colors_help_accent_mode") == "standard")
        {
            buttonsHelpMessage = GetChatColor(GetDvar("mapvote_colors_help_text")) + "Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+attack}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to go down - Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+toggleads_throw}] OR [{+speed_throw}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to go up - Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+gostand}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to select - Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+activate}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to undo";
        }
        else if(GetDvar("mapvote_colors_help_accent_mode") == "max")
        {
            buttonsHelpMessage = GetChatColor(GetDvar("mapvote_colors_help_text")) + "Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+attack}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to go " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "down " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "- Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+toggleads_throw}] OR [{+speed_throw}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to go " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "up " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "- Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+gostand}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "select " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "- Press " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "[{+activate}] " + GetChatColor(GetDvar("mapvote_colors_help_text")) + "to " + GetChatColor(GetDvar("mapvote_colors_help_accent")) + "undo";
        }

        player CreateHudText(buttonsHelpMessage, "default", 1.5, "CENTER", "CENTER", 0, 210 + getDvarInt("mapvote_help_x_offset")); 
    }
}

CreateVoteTimer()
{
	soundFX = spawn("script_origin", (0,0,0));
	soundFX hide();
	
	timerhud = CreateTimer(GetDvarInt("mapvote_vote_time"), &"Vote ends in: ", "default", 1.5, "CENTER", "CENTER", 0, -210);		
    timerhud.color = GetGscColor(GetDvar("mapvote_colors_timer"));
	for (i = GetDvarInt("mapvote_vote_time"); i > 0; i--)
	{	
		if(i <= 5) 
		{
			timerhud.color = GetGscColor(GetDvar("mapvote_colors_timer_low"));

            if (GetDvarInt("mapvote_sounds_timer_enabled"))
            {
                soundFX playSound( "ui_mp_timer_countdown" );
            }
		}
		wait(1);
	}	
	level notify("mapvote_vote_end");
}

StartVote()
{
    level endon("end_game");
    level notify("mapvote_vote_start");

    for (i = 0; i < level.mapvote["maps"]["by_index"].size; i++)
    {
        level.mapvote["vote"]["maps"][i] = 0;
    }

    for (i = 0; i < level.mapvote["modes"]["by_index"].size; i++)
    {
        level.mapvote["vote"]["modes"][i] = 0;
    }

    level thread CreateVoteMenu();
    level thread CreateVoteTimer();

    foreach (player in GetHumanPlayers())
    {
        player SetBlurForPlayer(GetDvarInt("mapvote_blur_level"), GetDvarInt("mapvote_blur_fade_in_time"));

        player thread ListenForVoteInputs();
        player thread OnPlayerDisconnect();
    }
}

ListenForEndVote()
{
    level endon("end_game");
    level waittill("mapvote_vote_end");

    mostVotedMapIndex = 0;
    mostVotedMapVotes = 0;
    mostVotedModeIndex = 0;
    mostVotedModeVotes = 0;

    foreach (mapIndex in GetArrayKeys(level.mapvote["vote"]["maps"]))
    {
        if (level.mapvote["vote"]["maps"][mapIndex] > mostVotedMapVotes)
        {
            mostVotedMapIndex = mapIndex;
            mostVotedMapVotes = level.mapvote["vote"]["maps"][mapIndex];
        }
    }

    foreach (modeIndex in GetArrayKeys(level.mapvote["vote"]["modes"]))
    {
        if (level.mapvote["vote"]["modes"][modeIndex] > mostVotedModeVotes)
        {
            mostVotedModeIndex = modeIndex;
            mostVotedModeVotes = level.mapvote["vote"]["modes"][modeIndex];
        }
    }

    if (mostVotedMapVotes == 0 && getDvarInt("mapvote_no_vote_behavior")>1)
    {
        mostVotedMapIndex = GetRandomElementInArray(GetArrayKeys(level.mapvote["vote"]["maps"]));

        if (GetDvarInt("mapvote_debug"))
        {
            Print("[MAPVOTE] No vote for map. Chosen random map index: " + mostVotedMapIndex);
        }
    }
    else
    {
        if (GetDvarInt("mapvote_debug"))
        {
            Print("[MAPVOTE] Most voted map has " + mostVotedMapVotes + " votes. Most voted map index: " + mostVotedMapIndex);
        }
    }

    if (mostVotedModeVotes == 0 && getDvarInt("mapvote_no_vote_behavior")>1)
    {
        mostVotedModeIndex = GetRandomElementInArray(GetArrayKeys(level.mapvote["vote"]["modes"]));

        if (GetDvarInt("mapvote_debug"))
        {
            Print("[MAPVOTE] No vote for mode. Chosen random mode index: " + mostVotedModeIndex);
        }
    }
    else
    {
        if (GetDvarInt("mapvote_debug"))
        {
            Print("[MAPVOTE] Most voted mode has " + mostVotedModeVotes + " votes. Most voted mode index: " + mostVotedModeIndex);
        }
    }

    if (mostVotedMapVotes == 0 && mostVotedModeVotes == 0)
    {
        if(getDvarInt("mapvote_no_vote_behavior") == 1)
        {
            Print("[MAPVOTE] Nobody voted and mapvote_no_vote_behavior is set to 1 -> map_rotate");
            cmdexec("map_rotate");
        }

        if (getDvarInt("mapvote_no_vote_behavior") == 0)
        {
            Print("[MAPVOTE] Nobody voted and mapvote_no_vote_behavior is set to 0 -> fast_restart");
            cmdexec("fast_restart");
        }
    }


    modeName = GetModeName(level.mapvote["modes"]["by_index"][mostVotedModeIndex]);
    //modeDsr = level.mapvote["modes"]["by_name"][level.mapvote["modes"]["by_index"][mostVotedModeIndex]];
    modeDsr = level.mapvote["modes"]["by_index"][mostVotedModeIndex];
    //mapName = level.mapvote["maps"]["by_name"][level.mapvote["maps"]["by_index"][mostVotedMapIndex]];
    mapName = level.mapvote["maps"]["by_index"][mostVotedMapIndex];

    if (GetDvarInt("mapvote_debug"))
    {
        Print("[MAPVOTE] mapName: " + mapName + " (" + GetMapName(mapName) + ")");
        Print("[MAPVOTE] modeName: " + modeName);
        Print("[MAPVOTE] modeDsr: " + modeDsr);
        Print("[MAPVOTE] Rotating to " + mapName + " | " + modeName + " (" + modeDsr + ".dsr)");
    }

    cmdexec("load_dsr " + modeDsr);
	wait(0.05);
	cmdexec("map " + mapName);
}

SetMapvoteData(type, elements)
{
    limit = level.mapvote["limit"][type + "s"];

    availableElements = [];

    if (IsDefined(elements))
    {
        availableElements = elements;
        if (GetDvarInt("mapvote_debug")>1)
        {
            Print("[MAPVOTE][SetMapvoteData] Parameter elements is defined.");
        }
    }
    else
    {
        availableElements = StrTok(GetDvar("mapvote_" + type + "s"), ",");
    }

    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][SetMapvoteData] Parameter limit is '" + limit + "' and the amount of available Elements is '" + availableElements.size + "'.");
    }

    if (availableElements.size < limit)
    {
        limit = availableElements.size;
    }
    _uniqueAvailableElements = GetUniqueElementsInArray(availableElements);
    if( _uniqueAvailableElements.size < limit)
    {
        limit = _uniqueAvailableElements.size;
        Print("[MAPVOTE][SetMapvoteData] WARNING: Your "+ type +"list contains duplicate entries.");
    }

    if (GetDvarInt("mapvote_debug")>1)
    {
        Print("[MAPVOTE][SetMapvoteData] TypeSwitch");
    }
    if (type == "map")
    {
        if (GetDvarInt("mapvote_debug")>1)
        {
            Print("[MAPVOTE][SetMapvoteData] It's a map");
        }
        finalMapElements = [];

        foreach (mapElement in availableElements)
        {
            //finalMapElement = StrTok(mapElement, ",");
            //finalMapElements = AddElementToArray(finalMapElements, finalMapElement[0]);
            finalMapElements = AddElementToArray(finalMapElements, mapElement);
            
            //level.mapvote["maps"]["by_name"][finalMapElement[0]] = finalMapElement[1];
            if (GetDvarInt("mapvote_debug")>1)
            {
                Print("[MAPVOTE][SetMapvoteData] Adding '" + mapElement + "'.");
            }
        }
        if (GetDvarInt("mapvote_debug")>1)
        {
            Print("[MAPVOTE][SetMapvoteData] We got out of the foreach itterating over all elements.");
        }
        level.mapvote["maps"]["by_index"] = GetRandomUniqueElementsInArray(finalMapElements, limit);
        if (GetDvarInt("mapvote_debug")>1)
        {
            Print("[MAPVOTE][SetMapvoteData] We called GetRandomUniqueElementsInArray and are done.");
        }
    }
    else if (type == "mode")
    {
        if (GetDvarInt("mapvote_debug")>1)
        {
            Print("[MAPVOTE][SetMapvoteData] It's a mode");
        }
        finalElements = [];

        foreach (mode in availableElements)
        {
            //splittedMode = StrTok(mode, ",");
            //finalElements = AddElementToArray(finalElements, splittedMode[0]);
            finalElements = AddElementToArray(finalElements, mode);

            //level.mapvote["modes"]["by_name"][splittedMode[0]] = splittedMode[1];
            if (GetDvarInt("mapvote_debug")>1)
            {
                Print("[MAPVOTE][SetMapvoteData] Adding '" + mode + "'.");
            }
        }

        level.mapvote["modes"]["by_index"] = GetRandomUniqueElementsInArray(finalElements, limit);
    }
}

/*
Gets the amount of maps and modes to display on screen
This is used to get default values if the limits dvars are not set
It will dynamically adjust the amount of maps and modes to show
*/
GetVoteLimits(mapsAmount, modesAmount)
{
    maxLimit = GetDvarInt("mapvote_limits_max");
    limits = [];

    if (!IsDefined(modesAmount))
    {
        if (mapsAmount <= maxLimit)
        {
            return mapsAmount;
        }
        else
        {
            return maxLimit;
        }
    }

    if ((mapsAmount + modesAmount) <= maxLimit)
    {
        limits["maps"] = mapsAmount;
        limits["modes"] = modesAmount;
    }
    else
    {
        if (mapsAmount >= (maxLimit / 2) && modesAmount >= (maxLimit))
        {
            limits["maps"] = (maxLimit / 2);
            limits["modes"] = (maxLimit / 2);
        }
        else
        {
            if (mapsAmount > (maxLimit / 2))
            {
                finalMapsAmount = 0;

                if (modesAmount <= 1)
                {
                    limits["maps"] = maxLimit;
                }
                else
                {
                    limits["maps"] = (maxLimit - modesAmount);
                }
                
                limits["modes"] = modesAmount;
            }
            else if (modesAmount > (maxLimit / 2))
            {
                limits["maps"] = mapsAmount;
                limits["modes"] = (maxLimit - mapsAmount);
            }
        }
    }
    
    return limits;
}

OnKillcamEnd()
{
    if (!IsDefined(level.finalkillcam_winner))
	{
	    if (isRoundBased() && !wasLastRound())
			return false;	
		wait GetDvarInt("mapvote_display_wait_time");
		
		StartVote();
		ListenForEndVote();
        return false;
    }
	
    level waittill("final_killcam_done");
	if (isRoundBased() && !wasLastRound())
		return true;
	wait GetDvarInt("mapvote_display_wait_time");

	StartVote();
	ListenForEndVote();
    return true;
}



/* HUD section */

UpdateSelection(type, index)
{
    if (type == "map" || type == "mode")
    {
        if (!IsDefined(self.mapvote[type]["hovered_index"]))
        {
            self.mapvote[type]["hovered_index"] = 0;
        }

        self.mapvote["vote_section"] = type;

        if (IsDefined(self.mapvote[type][self.mapvote[type]["hovered_index"]]))
        {
            SetElementUnselected(self.mapvote[type][self.mapvote[type]["hovered_index"]]["hud"]); // Unselect previous element
        }

        if (IsDefined(self.mapvote[type][index]))
        {
            SetElementSelected(self.mapvote[type][index]["hud"]); // Select new element
        }

        self.mapvote[type]["hovered_index"] = index; // Update the index
    }
    else if (type == "end")
    {
        self.mapvote["vote_section"] = "end";
    }
}

ConfirmSelection(type)
{
    self.mapvote[type]["selected_index"] = self.mapvote[type]["hovered_index"];
    level.mapvote["vote"][type + "s"][self.mapvote[type]["selected_index"]] = (level.mapvote["vote"][type + "s"][self.mapvote[type]["selected_index"]] + 1);
    level.mapvote["hud"][type + "s"][self.mapvote[type]["selected_index"]] SetValue(level.mapvote["vote"][type + "s"][self.mapvote[type]["selected_index"]]);

    if (type == "map")
    {
        modeIndex = 0;

        if (IsDefined(self.mapvote["mode"]["hovered_index"]))
        {
            modeIndex = self.mapvote["mode"]["hovered_index"];
        }

        self UpdateSelection("mode", modeIndex);
    }
    else if (type == "mode")
    {
        self UpdateSelection("end");
    }
}

CancelSelection(type)
{
    typeToCancel = "";

    if (type == "mode")
    {
        typeToCancel = "map";
    }
    else if (type == "end")
    {
        typeToCancel = "mode";
    }

    level.mapvote["vote"][typeToCancel + "s"][self.mapvote[typeToCancel]["selected_index"]] = (level.mapvote["vote"][typeToCancel + "s"][self.mapvote[typeToCancel]["selected_index"]] - 1);
    level.mapvote["hud"][typeToCancel + "s"][self.mapvote[typeToCancel]["selected_index"]] SetValue(level.mapvote["vote"][typeToCancel + "s"][self.mapvote[typeToCancel]["selected_index"]]);

    self.mapvote[typeToCancel]["selected_index"] = -1;

    if (type == "mode")
    {
        if (IsDefined(self.mapvote["mode"][self.mapvote["mode"]["hovered_index"]]))
        {
            SetElementUnselected(self.mapvote["mode"][self.mapvote["mode"]["hovered_index"]]["hud"]);
        }

        self.mapvote["vote_section"] = "map";
    }
    else if (type == "end")
    {
        self.mapvote["vote_section"] = "mode";
    }
}

SetElementSelected(element)
{
    element.color = GetGscColor(GetDvar("mapvote_colors_selected"));
}

SetElementUnselected(element)
{
    element.color = GetGscColor(GetDvar("mapvote_colors_unselected"));
}

CreateHudText(text, font, fontScale, relativeToX, relativeToY, relativeX, relativeY, isServer, value)
{
    hudText = "";

    if (IsDefined(isServer) && isServer)
    {
        hudText = CreateServerFontString( font, fontScale );
    }
    else
    {
        hudText = CreateFontString( font, fontScale );
    }

    if (IsDefined(value))
    {
        hudText.label = text;
        hudText SetValue(value);
    }
    else
    {
        hudText SetText(text);
    }

    hudText SetPoint(relativeToX, relativeToY, relativeX, relativeY);
    
    hudText.hideWhenInMenu = 1;
    hudText.glowAlpha = 0;

    return hudText;
}

CreateTimer(time, label, font, fontScale, relativeToX, relativeToY, relativeX, relativeY)
{
	timer = createServerTimer(font, fontScale);	
	timer setpoint(relativeToX, relativeToY, relativeX, relativeY);
	timer.label = label; 
    timer.hideWhenInMenu = 1;
    timer.glowAlpha = 0;
	timer setTimer(time);
	
	return timer;
}



/* Utils section */

SetDvarIfNotInitialized(dvar, value)
{
	if (!IsInitialized(dvar))
    {
        SetDvar(dvar, value);
    }
}

IsInitialized(dvar)
{
	result = GetDvar(dvar);
	return result != "";
}

IsBot()
{
    return IsDefined(self.pers["isBot"]) && self.pers["isBot"];
}

GetHumanPlayers()
{
    humanPlayers = [];

    foreach (player in level.players)
    {
        if (!player IsBot())
        {
            humanPlayers = AddElementToArray(humanPlayers, player);
        }
    }

    return humanPlayers;
}

GetRandomElementInArray(array)
{
    return array[GetArrayKeys(array)[randomint(array.size)]];
}

GetRandomUniqueElementsInArray(array, limit)
{
    finalElements = [];

    for (i = 0; i < limit; i++)
    {
        findElement = true;
        if (GetDvarInt("mapvote_debug")>1)
        {
            Print("[MAPVOTE][GetRandomUniqueElementsInArray] i = " + i);
        }
        while (findElement)
        {
            randomElement = GetRandomElementInArray(array);

            if (!ArrayContainsValue(finalElements, randomElement))
            {
                finalElements = AddElementToArray(finalElements, randomElement);

                findElement = false;
            }

            if (GetDvarInt("mapvote_debug")>1)
            {
                Print("[MAPVOTE][GetRandomUniqueElementsInArray] randomElement = " + randomElement);
            }
        }
    }

    return finalElements;
}

ArrayContainsValue(array, valueToFind)
{
    if (array.size == 0)
    { 
        return false;
    }

    foreach (value in array)
    {
        if (value == valueToFind)
        {
            return true;
        }
    }

    return false;
}

AddElementToArray(array, element)
{
    array[array.size] = element;
    return array;
}

GetUniqueElementsInArray(array)
{
    uniqueElements = [];
    foreach (element in array)
    {
        if (!ArrayContainsValue(uniqueElements, element))
        {
            AddElementToArray(uniqueElements,element);
        }
    }
    return uniqueElements;
}

GetGscColor(colorName)
{
    switch (colorName)
	{
        case "red":
        return (1, 0, 0.059);

        case "green":
        return (0.549, 0.882, 0.043);

        case "yellow":
        return (1, 0.725, 0);

        case "blue":
        return (0, 0.553, 0.973);

        case "cyan":
        return (0, 0.847, 0.922);

        case "purple":
        return (0.427, 0.263, 0.651);

        case "white":
        return (1, 1, 1);

        case "grey":
        case "gray":
        return (0.137, 0.137, 0.137);

        case "black":
        return (0, 0, 0);
	}
}

GetChatColor(colorName)
{
    switch(colorName)
    {
        case "red":
        return "^1";

        case "green":
        return "^2";

        case "yellow":
        return "^3";

        case "blue":
        return "^4";

        case "cyan":
        return "^5";

        case "purple":
        return "^6";

        case "white":
        return "^7";

        case "grey":
        case "gray":
        return "^0";

        case "black":
        return "^0";
    }
}
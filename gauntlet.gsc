#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_weapons;
#include maps/mp/animscripts/zm_utility;
#include maps/mp/zm_tomb;
#include maps/mp/zm_tomb_utility;
// New
#include maps/mp/zm_tomb_capture_zones;
#include maps/mp/zm_tomb_tank;
#include maps/mp/zm_tomb_utility;
#include maps/mp/gametypes_zm/_tweakables;
#include maps/mp/zombies/_zm_game_module;
#include maps/mp/zombies/_zm_net;

main()
{
	// replaceFunc(maps/mp/zombies/_zm::actor_killed_override, ::ActorKilledTracked);
    // replaceFunc(maps/mp/zombies/_zm_weapons::watchweaponusagezm, ::WatchWpnUsageLvlNotify);
    // replaceFunc(maps/mp/zm_tomb_utility::do_damage_network_safe, ::DoDamageNetworkSafe);
}

init()
{
	level thread OnPlayerConnect();
    // flag_init("games_gone");
}

OnPlayerConnect()
{
	level waittill("connecting", player );	

	player thread OnPlayerSpawned();

	level waittill("initial_players_connected");
    level thread SetDvars();

    flag_wait("initial_blackscreen_passed");

    level thread EndGameWatcher();
    level thread TimerHud();
    level thread DebugHud();

    while (1)
    {
        // Activate generator 1
        if (level.round_number == 1)
        {
            level thread CheckForGenerator(1, 1);
        }

        // Only kill with melee (except for shield)
        else if (level.round_number == 2)
        {
            level thread WatchPlayerStats(2, "kills", "melee_kills");
        }

        // Stay still
        else if (level.round_number == 3)
        {
            level thread DisableMovement(3);
        }

        // Have one perk at the end of the round
        else if (level.round_number == 4)
        {
            level thread WatchPerks(4, 1);
        }

        // Pull at least one weapon from the box
        else if (level.round_number == 5)
        {
            level thread WatchPlayerStat(5, "grabbed_from_magicbox");
        }

        // Dig 3 piles (1 for each on coop)
        else if (level.round_number == 6)
        {
            level thread WatchPlayerStat(6, "tomb_dig");
        }

        // Dig 3 piles (1 for each on coop)
        else if (level.round_number == 7)
        {
            level thread WatchPlayerStat(7, "melee_kills");
        }

        level waittill("start_of_round"); // Careful not to add this inside normal fucntions

        wait 0.05;
    }
}

OnPlayerSpawned()
{
    level endon( "game_ended" );
	self endon( "disconnect" );

    level.round_number = 7; // For debugging

	self waittill( "spawned_player" );

    foreach (player in level.players)
    {
        player.score = 500000; // For debugging
    }

	flag_wait( "initial_blackscreen_passed" );
}

SetDvars()
//Function sets and holds level dvars
{
    level endon( "game_ended" );
    
    level.conditions_met = false;
    level.conditions_in_progress = false;
    self thread LevelDvarsWatcher();
    while (1)
    {
        level.conditions_met = false;
        level.conditions_in_progress = false;
        level.forbidden_weapon_used = false;
        level.murderweapontype = undefined;  
        level.murderweapon = undefined;  
        level.zombie_killed = 0;
        level.gauntlet_kills = 0;
        level.active_gen_1 = false;
        level.active_gen_2 = false;
        level.active_gen_3 = false;
        level.active_gen_4 = false;
        level.active_gen_5 = false;
        level.active_gen_6 = false;

        level.debug_1 = 0;
        level.debug_2 = 0;

        level waittill("end_of_round");
        wait 3; // Must be higher than 1 ::EndGameWatcher
    }
}

LevelDvarsWatcher()
// Function switches level dvars depending on other level dvars so it doesn't have to be done manually, also to prevent hud color fuckery
{
    level endon( "game_ended" );

    while (1)
    {
        if (level.condition_met)
        {
           level.conditions_in_progress = false; 
        }

        if (level.conditions_in_progress)
        {
            level.conditions_met = false;
        }

        wait 0.05;
    }
}


EndGameWatcher()
//Function operates when level is suppose to end
{
    level endon( "game_ended" );


    self thread ForbiddenWeaponWatcher();
    level waittill ("start_of_round");
    while (1)
    {
        level waittill ("end_of_round");
        wait 1;
        if (level.round_number > 30)
        {
            maps\mp\zombies\_zm_game_module::freeze_players( 1 );
            level notify("game_won"); // Need to code that
        }
        if (!level.conditions_met)
        {
            EndGame();
        }
        wait 1;
    }
}

ForbiddenWeaponWatcher()
// Function will immidiately end the game if forbidden_weapon trigger is enabled
{
    level endon( "game_ended" );
	self endon( "disconnect" );
    while (1)
    {
        if (level.forbidden_weapon_used)
        {
            EndGame();
        }
        wait 0.05;
    }
}

EndGame()
// Function ends the game immidiately
{
    // flag_set("games_gone");
    ConditionsMet(false);
    ConditionsInProgress(false);
    wait 0.1;
    maps\mp\zombies\_zm_game_module::freeze_players( 1 );
    level notify("end_game");
}

ConditionsInProgress(bool)
// Function changes the state of conditions_in_progress boolean, as well as conditions_met if necessary
{
    level.conditions_in_progress = bool;
    if (bool)
    {
        level.conditions_met = false;
    }
    return;
}

ConditionsMet(bool)
// Function changes the state of conditions_met boolean, as well as conditions_in_progress if necessary
{
    level.conditions_met = bool;
    if (bool)
    {
        level.conditions_in_progress = false;
    }
    return;
}

TimerHud()
// Timer hud displayer throught the game
{
    self endon("disconnect");
    level endon("end_game");

    timer_hud = newHudElem();
	timer_hud.alignx = "left";					
	timer_hud.aligny = "top";
	timer_hud.horzalign = "user_left";			
	timer_hud.vertalign = "user_top";
	timer_hud.x = 7; 							
	timer_hud.y = 2;							
	timer_hud.fontscale = 1.4;
	timer_hud.alpha = 1;
	timer_hud.color = ( 1, 1, 1 );
	timer_hud.hidewheninmenu = 1;

	timer_hud setTimerUp(0); 
}

GauntletHud(challenge)
// Hud for printing challenge goals, function doesn't yet work properly
{
    self endon("disconnect");
    level endon("end_game");

    if (isdefined(gauntlet_hud))
    {
        gauntlet_hud destroy_hud();
    }
    gauntlet_hud = newHudElem();
    gauntlet_hud.alignx = "right";
    gauntlet_hud.aligny = "center";
    gauntlet_hud.horzalign = "user_right";
    gauntlet_hud.vertalign = "user_center";
    gauntlet_hud.x -= 3;
    gauntlet_hud.y -= 20;
    gauntlet_hud.fontscale = 1.4;
    gauntlet_hud.alpha = 1;
    gauntlet_hud.hidewheninmenu = 1;
    gauntlet_hud.color = (1, 1, 1);
    gauntlet_hud settext("Origins gauntlet");
    if (challenge == 1)
    {
        gauntlet_hud settext("Turn on Generator 1");
    }
    else if (challenge == 2)
    {
        gauntlet_hud settext("Kill only with melee attacks");
    }
    else if (challenge == 3)
    {
        gauntlet_hud settext("Stand still");
    }
    else if (challenge == 4)
    {
        gauntlet_hud settext("Own a perk at the end of the round");
    }
    else if (challenge == 5)
    {
        gauntlet_hud settext("Pull a weapon from mystery box");
    }
    else if (challenge == 6)
    {
        if (level.players.size == 1)
        {
            gauntlet_hud settext("Dig 3 piles");
        }
        else
        {
            gauntlet_hud settext("Dig a pile");
        }
    }
    else if (challenge == 7)
    {
        if (level.players.size == 1)
        {
            gauntlet_hud settext("Kill 6 zombies with melee attacks");
        }
        else
        {
            gauntlet_hud settext("Kill 12 zombies total with melee attacks");
        }
    }


    while (level.round_number == challenge)
    {
        if (level.conditions_in_progress)
        {
            gauntlet_hud.color = (0.8, 0.8, 0);
        }
        else if (level.conditions_met)
        {          
            gauntlet_hud.color = (0, 0.8, 0);
        }
        else if (!level.conditions_met && !level.conditions_in_progress)
        {
            gauntlet_hud.color = (0.8, 0, 0);
        }
        else
        {
            gauntlet_hud.color = (1, 1, 1); // failsafe
        }

        wait 0.05;
    }

    wait 0.1;
    gauntlet_hud.color = GauntletHudAfteraction();

    wait 4;
    gauntlet_hud fadeovertime(1.25);
    gauntlet_hud.alpha = 0;
    wait 2;

    // gauntlet_hud destroy_hud();
}

GauntletHudAfteraction()
// Function changes the color of challenge hud after the round is over
{
    if (level.conditions_met)
    {
        return (0, 0.8, 0);
    }
    else
    {
        return (0.8, 0, 0);
    }
}

DebugHud(debug)
// Hud for printing variables in debugging
{
    if (debug)
    {
        debug_hud = newHudElem();
        debug_hud.alignx = "center";
        debug_hud.aligny = "top";
        debug_hud.horzalign = "user_center";
        debug_hud.vertalign = "user_top";
        debug_hud.x = 0;
        debug_hud.y = 20;
        debug_hud.fontscale = 1.4;
        debug_hud.alpha = 1;
        debug_hud.hidewheninmenu = 1;
        debug_hud.color = (1, 1, 1);
        while (1)
        {
            debug_hud settext("1st: " + level.debug_1 + " / 2nd " + level.debug_2);
            wait 0.05;
        }
        
    }
}

CheckForGenerator(gen_id, rnd_override)
// Master function for checking generators. Pass 0 as gen_id to verify all gens
{
    level endon("end_game");
    level endon("start_of_round");

    self.current_round = level.round_number;
    if (isdefined(rnd_override))
    {
        self.current_round = rnd_override;
    }
    self.generator_id = gen_id;

    self thread GauntletHud(1);
    self thread GeneratorCondition();
    self thread GeneratorWatcher();
}

GeneratorCondition()
// Function will change boolean if defined generator is taken
{
    while (self.current_round == level.round_number)
    {
        if (level.active_gen_1 && self.generator_id == 1)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_2 && self.generator_id == 2)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_3 && self.generator_id == 3)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_4 && self.generator_id == 4)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_5 && self.generator_id == 5)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_6 && self.generator_id == 6)
        {
            ConditionsMet(true);
        }

        else if (self.generator_id == 0)
        {
            if (level.active_gen_1 && level.active_gen_2 && level.active_gen_3 && level.active_gen_4 && level.active_gen_5 && level.active_gen_6)
            {
                ConditionsMet(true);
            }

            else if (level.active_gen_1 || level.active_gen_2 || level.active_gen_3 || level.active_gen_4 || level.active_gen_5 || level.active_gen_6)
            {
                ConditionsInProgress(true);
            }

            else
            {
                ConditionsMet(false);
                ConditionsInProgress(false);
            }
        }

        else
        {
            ConditionsMet(false);
            ConditionsInProgress(false);
        }

        if (flag("zone_capture_in_progress"))
        {
            ConditionsInProgress(true);
        }

        wait 0.05;
    }
}

GeneratorWatcher()
// Function watches for current state of gens and changing booleans accordingly
{
    while (self.current_round == level.round_number)
    {
        if (level.zone_capture.zones["generator_start_bunker"]ent_flag("player_controlled"))
        {
            level.active_gen_1 = true;
        }
        else
        {
            level.active_gen_1 = false;
        }

        if (level.zone_capture.zones["generator_tank_trench"]ent_flag("player_controlled"))
        {
            level.active_gen_2 = true;
        }
        else
        {
            level.active_gen_2 = false;
        }

        if (level.zone_capture.zones["generator_mid_trench"]ent_flag("player_controlled"))
        {
            level.active_gen_3 = true;
        }
        else
        {
            level.active_gen_3 = false;
        }

        if (level.zone_capture.zones["generator_nml_right"]ent_flag("player_controlled"))
        {
            level.active_gen_4 = true;
        }
        else
        {
            level.active_gen_4 = false;
        }

        if (level.zone_capture.zones["generator_nml_left"]ent_flag("player_controlled"))
        {
            level.active_gen_5 = true;
        }
        else
        {
            level.active_gen_5 = false;
        }

        if (level.zone_capture.zones["generator_church"]ent_flag("player_controlled"))
        {
            level.active_gen_6 = true;
        }
        else
        {
            level.active_gen_6 = false;
        }

        wait 0.05;
    }
}

WatchPlayerStat(challenge, stat_1)
// Function watches for a single provided stat (guns from box)
{
    level endon("end_game");
    level endon("start_of_round");

    self thread GauntletHud(challenge);
    rnd = level.round_number;

    // Grab stat on round start
    beg_stat = 0;
    beg_stat_array = array(0, 0, 0, 0, 0, 0, 0, 0);

    i = 0;
    foreach (player in level.players)
    {
        beg_stat_array[i] += player.pers[stat_1];
        i++;
    }

    // Watch stats midround
    rnd_stat = beg_stat;
    rnd_stat_array = beg_stat_array;
    did_hit_box = array(0, 0, 0, 0, 0, 0, 0, 0);
    proper_boxers = 0;
    piles_in_progress = false;
    temp_melees = 0;
    while (level.round_number == rnd)
    {
        proper_boxers = 0;
        temp_melees = 0;

        // Pull stat from each player into an array
        i = 0;
        foreach (player in level.players)
        {
            rnd_stat_array[i] = player.pers[stat_1];
            i++;
        }
        
        // Calculate if weapon was pulled from box
        i = 0;
        foreach (stat in rnd_stat_array)
        {
            if (challenge == 5)
            {
                if (stat > beg_stat_array[i])
                {
                    did_hit_box[i] = 1;
                }
            }
            else if (challenge == 6)
            {
                if (stat > beg_stat_array[i] && level.players.size > 1)
                {
                    did_hit_box[i] = 1;
                }
                else if (stat > beg_stat_array[i] && level.players.size == 1)
                {
                    did_hit_box[i] = 2;

                    if (stat > beg_stat_array[i] + 2)
                    {
                        did_hit_box[i] = 1;
                    }
                }
            }
            else if (challenge == 7 && level.players.size == 1)
            {
                if (stat > beg_stat_array[i] && stat < beg_stat_array[i] + 5)
                {
                    did_hit_box[i] = 2;
                }
                else if (stat > beg_stat_array[i] + 5)
                {
                    did_hit_box[i] = 1;
                }
            }
        }

        if (challenge == 7 && level.players.size > 1)
        {
            i = 0;
            foreach (stat in rnd_stat_array)
            {
                temp_melees += (stat - beg_stat_array[i]);
                i++;
            }

            if (temp_melees > 0 && temp_melees < 12)
            {
                i = 0;
                foreach (player in level.players)
                {
                    did_hit_box[i] = 2;
                }
            }
            else if (temp_melees >= 12)
            {
                i = 0;
                foreach (player in level.players)
                {
                    did_hit_box[i] = 1;
                }
            }
        }


        // Count players who completed the challenge
        foreach (fact in did_hit_box)
        {
            if (fact == 1)
            {
                proper_boxers++;
            }
            else if (fact == 2)
            {
                piles_in_progress = true;
            }
        }

        // Determine state of the challenge
        if (proper_boxers == 0 && !piles_in_progress)
        {
            ConditionsMet(false);
            ConditionsInProgress(false);            
        }
        else if (proper_boxers == level.players.size)
        {
            ConditionsMet(true);
        }
        else
        {
            ConditionsInProgress(true); 
        }

        wait 0.05;
    }
}

WatchPlayerStats(challenge, stat_1, stat_2)
// Function turns on boolean in case of zombies being shot, trapped or tanked
{
    level endon("end_game");
    level endon("start_of_round");

    self thread GauntletHud(challenge);
    if (challenge == 2)
    {
        ConditionsInProgress(true);
    }
    rnd = level.round_number;

    // Grab stats on round start
    beg_stat1 = 0;
    beg_stat2 = 0;
    foreach (player in level.players)
    {
        beg_stat1 += player.pers[stat_1];
        beg_stat2 += player.pers[stat_2];
    }

    beg_difference = (beg_stat1 - beg_stat2);

    // Watch stats midround
    rnd_stat1 = beg_stat1;
    rnd_stat2 = beg_stat2;
    prev_zombie_counter = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;
    while (level.round_number == rnd)
    {
        foreach (player in level.players)
        {
            rnd_stat1 = player.pers[stat_1];
            rnd_stat2 = player.pers[stat_2];
        }

        new_zombie_counter = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;

        if (new_zombie_counter < prev_zombie_counter)
        {
            counter_diff = prev_zombie_counter - new_zombie_counter;
            stat_diff = rnd_stat1 - old_stat1;
            if (stat_diff != counter_diff)
            {
                rnd_stat1 += counter_diff; // Maxis drone is crashing the game
            }
        }

        get_difference = (rnd_stat1 - rnd_stat2);

        if (get_difference != beg_difference)
        {
            level.forbidden_weapon_used = true;
        }

        prev_zombie_counter = new_zombie_counter;
        old_stat1 = rnd_stat1;
        
        wait 0.05;
    }
    ConditionsMet(true);
}

DisableMovement(challenge)
// Function disable walking and jumping ability until the end of the round 
{
    level endon("end_game");
    level endon("start_of_round");

    ConditionsInProgress(true);

    self thread GauntletHud(challenge);
    foreach (player in level.players)
    {
        player setmovespeedscale(0);
        player allowjump(0);
    }

    level waittill ("end_of_round");
    ConditionsMet(true);
    foreach (player in level.players)
    {
        player setmovespeedscale(1);
        player allowjump(1);
    }
}

WatchPerks(challenge, number_of_perks)
// Function checks for the amount of perks per player at the end of the round.
{
    level endon("end_game");
    level endon("start_of_round");

    level.proper_players = 0;
    self thread GauntletHud(challenge);
    self thread PerkWatcher(number_of_perks);

    level waittill ("end_of_round");
    if (level.proper_players == level.players.size)
    {
        ConditionsMet(true);
    }
}

PerkWatcher(required_perks)
// Function checks for the amount of perks during the round
{
    current_perks = array(0, 0, 0, 0, 0, 0, 0, 0);
    got_perks_right = array(false, false, false, false, false, false, false, false);
    current_round = level.round_number;
    while (current_round == level.round_number)
    {
        level.proper_players = 0;

        // Reset current perk array
        foreach (perk in current_perks)
        {
            perk = 0;
        }

        // Get amount of perks from each player into the array
        i = 0;
        foreach (player in level.players)
        {
            current_perks[i] = player.num_perks;
            i++;
        }

        // Check if each player has right amount of perks and put results into an array
        i = 0;
        foreach (perk in current_perks)
        {
            if (perk < required_perks && i < level.players.size)
            {
                got_perks_right[i] = false; // I think problem is in this if statement

            }
            else
            {
                got_perks_right[i] = true;
            }
            i++;
        }

        // Count players who have right amount of perks
        foreach (got_right in got_perks_right)
        {
            if (got_right)
            {
                level.proper_players++;
            }
        }
        level.proper_players -= (8 - level.players.size);

        // Compare against lobby size (up to 8 players for pluto)
        if (level.proper_players > 0)
        {
            ConditionsInProgress(true);
        }
        else
        {
            ConditionsMet(false);
            ConditionsInProgress(false);
        }

        wait 0.05;
    }
}

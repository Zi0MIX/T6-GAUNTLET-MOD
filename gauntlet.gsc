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

// main()
// {
// }

init()
{
	level thread OnPlayerConnect();
    flag_init("env_kill");
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
    level thread BetaHud(1);
    // level thread DebugHud(true);

    // level waittill ("start_of_round");
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

        // Have one jug by the end of the round
        if (level.round_number == 8)
        {
            level thread WatchPerks(8, 1);
        }

        // Only kill with mp40
        if (level.round_number == 9)
        {
            level thread CheckUsedWeapon(9);
            level thread WatchPlayerStat(9, "grenade_kills");
        }   

        level waittill("start_of_round"); // Careful not to add this inside normal fucntions

        wait 0.05;
    }
}

OnPlayerSpawned()
{
    level endon( "game_ended" );
	self endon( "disconnect" );

    // level.round_number = 1; // For debugging

	self waittill( "spawned_player" );

    foreach (player in level.players)
    {
        player.score = 505; // For debugging
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
    level.callbackactorkilled = ::actor_killed_override; // Pointer
    while (1)
    {
        level.conditions_met = false;
        level.conditions_in_progress = false;
        level.forbidden_weapon_used = false;
        level.murderweapontype = undefined;  
        level.murderweapon = undefined;  
        level.zombie_killed = 0;
        level.gauntlet_kills = 0;
        level.env_kills = 0;
        level.active_gen_1 = false;
        level.active_gen_2 = false;
        level.active_gen_3 = false;
        level.active_gen_4 = false;
        level.active_gen_5 = false;
        level.active_gen_6 = false;
        level.players_jug = 0;
        level.players_quick = 0;
        level.players_doubletap = 0;
        level.players_speed = 0;
        level.players_phd = 0;
        level.players_deadshot = 0;
        level.players_stam = 0;
        level.players_cherry = 0;
        level.players_mulekick = 0;

        level.debug_1 = 0;
        level.debug_2 = 0;

        flag_clear("env_kill");

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
        if (level.conditions_met)
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
        if (!level.conditions_met)
        {
            EndGame();
        }

        else if (level.round_number >= 30)
        {
            maps\mp\zombies\_zm_game_module::freeze_players( 1 );
            level notify("game_won"); // Need to code that
        }

        else if (level.round_number >= 10) // For beta only
        {
            wait 5;
            EndGame("you win kappa");
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

EndGame(iprint)
// Function ends the game immidiately
{
    if (!isdefined(iprint))
    {
        iprint = "you bad";
    }
    iprintln(iprint);
    ConditionsMet(false);
    ConditionsInProgress(false);
    wait 0.1;
    maps\mp\zombies\_zm_game_module::freeze_players(1);
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
        gauntlet_hud settext("Turn on Generator 1 by the end of the round");
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
    else if (challenge == 8)
    {
        gauntlet_hud settext("Own Jugger-Nog by the end of the round");
    }

    else if (challenge == 9)
    {
        gauntlet_hud settext("Only kill with MP-40");
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

    wait 1;
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

BetaHud(beta_version)
// Function for beta overlay
{
    self endon("disconnect");

    if (!isdefined(beta_version))
    {
        beta_version = 0;
    }
    beta_hud = newHudElem();
    beta_hud.alignx = "center";
    beta_hud.aligny = "top";
    beta_hud.horzalign = "user_center";
    beta_hud.vertalign = "user_top";
    beta_hud.x = 0;
    beta_hud.y = 5;
    beta_hud.fontscale = 1.2;
    beta_hud.alpha = 0.3;
    beta_hud.hidewheninmenu = 1;
    beta_hud.color = (0, 0.4, 0.8);
    beta_hud settext("Beta V" + beta_version);
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

    self thread GauntletHud(self.current_round);
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

    // Load beginning stats into an array
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
        
        // Define if condition is met
        i = 0;
        foreach (stat in rnd_stat_array)
        {
            if (challenge == 5 || challenge == 9)
            {
                // Change to 1 if stat is bigger
                if (stat > beg_stat_array[i])
                {
                    did_hit_box[i] = 1;
                }
            }
            else if (challenge == 6)
            {
                // Change to 1 if stat is bigger coop only
                if (stat > beg_stat_array[i] && level.players.size > 1)
                {
                    did_hit_box[i] = 1;
                }
                // Change to 2 if stat is bigger solo only
                else if (stat > beg_stat_array[i] && level.players.size == 1)
                {
                    did_hit_box[i] = 2;

                    // Change to 1 if stat is bigger by 3 or more
                    if (stat > beg_stat_array[i] + 2)
                    {
                        did_hit_box[i] = 1;
                    }
                }
            }
            else if (challenge == 7 && level.players.size == 1)
            {
                // Change to 2 if stat is bigger
                if (stat > beg_stat_array[i])
                {
                    did_hit_box[i] = 2;

                    // Change to 1 is stat is bigger by 6 or more
                    if (stat > beg_stat_array[i] + 5)
                    {
                        did_hit_box[i] = 1;
                    }
                }
            }
        }

        if (challenge == 7 && level.players.size > 1)
        {
            // Sum melee kills from all players
            i = 0;
            foreach (stat in rnd_stat_array)
            {
                temp_melees += (stat - beg_stat_array[i]);
                i++;
            }

            // Change state to 2 for all players if kills are between 1 and 12
            if (temp_melees > 0 && temp_melees < 12)
            {
                i = 0;
                foreach (player in level.players)
                {
                    did_hit_box[i] = 2;
                }
            }
            // Change state to 1 for all players if kills are bigger or equal 12
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
                piles_in_progress = true; // Change to true if one or more players is in progress
            }
        }

        // Determine state of the challenge
        // Flow of the challenge 9 already defined in CheckUsedWeapon()
        if (challenge == 9)
        {
            if (proper_boxers > 0)
            {
                level.forbidden_weapon_used = true;
            }
        }
        
        else
        {
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
    self thread EnvironmentKills();
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
    while (level.round_number == rnd)
    {
        foreach (player in level.players)
        {
            rnd_stat1 += player.pers[stat_1];
            rnd_stat2 += player.pers[stat_2];
        }

        get_difference = (rnd_stat1 - rnd_stat2);

        if (get_difference != beg_difference || flag("env_kill"))
        {
            level.forbidden_weapon_used = true;
        }
        
        wait 0.05;
    }
    wait 0.1;
    ConditionsMet(true);
}

EnvironmentKills()
// Function sets "env_kill" flag if one more more environment kills happen in the round (tank, robot etc)
{
    prev_zombie_counter = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;
    current_round = level.round_number;
    global_kills = 0;
    foreach (player in level.players)
    {
        global_kills += player.pers["kills"];
    }
    old_global_kills = global_kills;
    kill_difference = 0;
    stat_difference = 0;

    while (level.round_number == current_round)
    {
        global_kills = 0;
        foreach (player in level.players)
        {
            global_kills += player.pers["kills"];
        }
        new_zombie_counter = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;

        if (new_zombie_counter < prev_zombie_counter)
        {
            kill_difference = prev_zombie_counter - new_zombie_counter;
            stat_difference = global_kills - old_global_kills;
        }

        if (stat_difference != kill_difference)
        {
            // global_kills += kill_difference; // Maxis drone is crashing the game
            // level notify ("env_kill");
            flag_set("env_kill");
        }

        old_global_kills = global_kills;
        prev_zombie_counter = new_zombie_counter;

        wait 0.05;
    }
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
    if (challenge == 4)
    {
        self thread PerkWatcher(number_of_perks);
    }
    else if (challenge == 8)
    {
        self thread EachPerkWatcher();
        self thread WatchPerkMidRound("jug");
    }
    
    level waittill ("end_of_round");
    if (challenge == 4 && level.proper_players == level.players.size)
    {
        ConditionsMet(true);
    }
    else if (challenge == 8 && level.players_jug >= number_of_perks)
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

EachPerkWatcher()
// Function checks how many of each perks players own 
{
    current_round = level.round_number;
    while (current_round == level.round_number)
    {
        hasjug = 0;
        hasquick = 0;
        hasdoubletap = 0;
        hasspeed = 0;
        hasphd = 0;
        hasdeadshot = 0;
        hasstam = 0;
        hascherry = 0;
        hasmule = 0;
        foreach (player in level.players)
        {
            if (player hasperk( "specialty_armorvest"))
            {
                hasjug++;
            }
            level.players_jug = hasjug;

            if (player hasperk( "specialty_quickrevive"))
            {
                hasquick++;
            }
            level.players_quick = hasquick;

            if (player hasperk( "specialty_rof"))
            {
                hasdoubletap++;
            }
            level.players_doubletap = hasdoubletap;

            if (player hasperk( "specialty_fastreload"))
            {
                hasspeed++;
            }
            level.players_speed = hasspeed;

            if (player hasperk( "specialty_flakjacket"))
            {
                hasphd++;
            }
            level.players_phd = hasphd;

            if (player hasperk( "specialty_deadshot"))
            {
                hasdeadshot++;
            }
            level.players_deadshot = hasdeadshot;

            if (player hasperk( "specialty_longersprint"))
            {
                hasstam++;
            }
            level.players_stam = hasstam;

            if (player hasperk( "specialty_grenadepulldeath"))
            {
                hascherry++;
            }
            level.players_cherry = hascherry;

            if (player hasperk( "specialty_additionalprimaryweapon"))
            {
                hasmule++;
            }
            level.players_mulekick = hasmule;
        }
        wait 0.05;
    }
}

WatchPerkMidRound(perk)
// Function checks if players have more than 0 of specified perk and changes condition to in progress
{
    current_round = level.round_number;
    while (current_round == level.round_number)
    {
        if (perk == "jug")
        {
            if (level.players_jug > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "quick")
        {
            if (level.players_quick > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "doubletap")
        {
            if (level.players_doubletap > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "speed")
        {
            if (level.players_speed > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "phd")
        {
            if (level.players_phd > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "deadshot")
        {
            if (level.players_deadshot > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "stam")
        {
            if (level.players_stam > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "cherry")
        {
            if (level.players_cherry > 0)
            {
                ConditionsInProgress(true);
            }
        }

        else if (perk == "mulekick")
        {
            if (level.players_mulekick > 0)
            {
                ConditionsInProgress(true);
            }
        }

        wait 0.05;
    }
}

CheckUsedWeapon(challenge)
// Function verifies if kills are only done with specified weapon(s) (doesn't work for greandes!!!!!!)
{
    level endon("end_game");
    level endon("start_of_round");

    self thread GauntletHud(challenge);
    self thread EnvironmentKills();
    ConditionsInProgress(true);
    current_round = level.round_number;
    while (current_round == level.round_number)
    {
        level waittill_any ("zombie_killed", "end_of_round");
        // iprintln(level.weapon_used);
        proper_gun_used = false;

        if (challenge == 9 && level.weapon_used == "mp40_zm" || level.weapon_used == "mp40_stalker_zm" || level.weapon_used == "mp40_upgraded_zm" || level.weapon_used == "mp40_stalker_upgraded_zm" || level.weapon_used == "none")
        {
            proper_gun_used = true;
        }

        if (!proper_gun_used || flag("env_kill"))
        {
            level.forbidden_weapon_used = true;
        }

        wait 0.05;
    }
    wait 0.1;
    if (flag("env_kill")) // Failsafe
    {
        level.forbidden_weapon_used = true;
    }
    ConditionsMet(true);
}

actor_killed_override( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime )
// Override used to pass weapon used to kill zombies to level variable alongside level notify
{
    if (level.round_number == 9)
    {
        level.weapon_used = sweapon;
        level notify ("zombie_killed");
    }

    if ( game["state"] == "postgame" )
        return;

    if ( isai( attacker ) && isdefined( attacker.script_owner ) )
    {
        if ( attacker.script_owner.team != self.aiteam )
            attacker = attacker.script_owner;
    }

    if ( attacker.classname == "script_vehicle" && isdefined( attacker.owner ) )
        attacker = attacker.owner;

    if ( isdefined( attacker ) && isplayer( attacker ) )
    {
        multiplier = 1;

        if ( is_headshot( sweapon, shitloc, smeansofdeath ) )
            multiplier = 1.5;

        type = undefined;

        if ( isdefined( self.animname ) )
        {
            switch ( self.animname )
            {
                case "quad_zombie":
                    type = "quadkill";
                    break;
                case "ape_zombie":
                    type = "apekill";
                    break;
                case "zombie":
                    type = "zombiekill";
                    break;
                case "zombie_dog":
                    type = "dogkill";
                    break;
            }
        }
    }

    if ( isdefined( self.is_ziplining ) && self.is_ziplining )
        self.deathanim = undefined;

    if ( isdefined( self.actor_killed_override ) )
        self [[ self.actor_killed_override ]]( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime );
}
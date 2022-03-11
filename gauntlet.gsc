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
            level thread WatchPlayerStat(2, "kills", "melee_kills");
        }

        // Stay still
        else if (level.round_number == 3)
        {
            level thread DisableMovement(3);
        }

        else if (level.round_number == 4)
        {
            level thread WatchPerks(4, 1);
        }

        level waittill("start_of_round"); // Careful not to add this inside normal fucntions
    }
}

OnPlayerSpawned()
{
    level endon( "game_ended" );
	self endon( "disconnect" );

    level.round_number = 3;

	self waittill( "spawned_player" );

	flag_wait( "initial_blackscreen_passed" );
}

SetDvars()
//Function sets and holds level dvars / has to be level thread?
{
    level.conditions_met = false;
    level.conditions_in_progress = false;
    // self thread LevelDvarsWatcher();
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
        gauntlet_hud destroy();
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
        gauntlet_hud settext("Stay still");
    }
    else if (challenge == 4)
    {
        gauntlet_hud settext("Own a perk at the end of the round.");
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
    level endon("end_of_round");
    // self.generator_name = TranslateGeneratorNames(generator);
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

        // if (!self.active_gen_1 && self.generator_id == 1)
        // {
        //     ConditionsMet(false);
        //     ConditionsInProgress(false);
        // }

        // else if (!self.active_gen_2 && self.generator_id == 2)
        // {
        //     ConditionsMet(false);
        //     ConditionsInProgress(false);
        // }

        // else if (!self.active_gen_3 && self.generator_id == 3)
        // {
        //     ConditionsMet(false);
        //     ConditionsInProgress(false);
        // }

        // else if (!self.active_gen_4 && self.generator_id == 4)
        // {
        //     ConditionsMet(false);
        //     ConditionsInProgress(false);
        // }

        // else if (!self.active_gen_5 && self.generator_id == 5)
        // {
        //     ConditionsMet(false);
        //     ConditionsInProgress(false);
        // }

        // else if (!self.active_gen_6 && self.generator_id == 6)
        // {
        //     ConditionsMet(false);
        //     ConditionsInProgress(false);
        // }

        // else if (!self.active_gen_1 && !self.active_gen_2 && !self.active_gen_3 && !self.active_gen_4 && !self.active_gen_5 && !self.active_gen_6 && self.generator_id == 0)
        // {
        //     ConditionsMet(false);
        //     ConditionsInProgress(false);
        // }

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

WatchPlayerStat(challenge, stat_1, stat_2)
// Function turns on boolean in case of zombies being shot, trapped or tanked
{
    self thread GauntletHud(challenge);
    ConditionsInProgress(true);
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
    self.required_perks = number_of_perks;
    self.current_perks = array(0, 0, 0, 0, 0, 0, 0, 0);
    self.current_round = level.round_number;
    self.got_perks_right = array(false, false, false, false, false, false, false, false);
    self.proper_players = 0;
    self.player_size = level.players.size;
    self thread GauntletHud(challenge);
    self thread PerkWatcher(number_of_perks);

    level.debug_1 = self.current_perks;
    level.debug_2 = self.got_perks_right;

    level waittill ("end_of_round");
    if (self.proper_players >= self.player_size)
    {
        ConditionsMet(true);
    }
}

PerkWatcher(number_of_perks)
// Function checks for the amount of perks during the round
{
    while (self.current_round == level.round_number)
    {
        // Reset current perk array
        foreach (perk in self.current_perks)
        {
            perk = 0;
        }

        // Get amount of perks from each player into the array
        i = 0;
        foreach (player in level.players)
        {
            self.current_perks[i] = player.num_perks;
            i++;
        }

        // Check if each player has right amount of perks and put results into an array
        i = 0;
        foreach (perk in self.current_perks)
        {
            if (perk < self.required_perks && i < self.player_size)
            {
                self.got_perks_right[i] = false; // I think problem is in this if statement
            }
            else
            {
                self.got_perks_right[i] = true;
            }
            i++;
        }

        // Count players who have right amount of perks
        foreach (got_right in self.got_perks_right)
        {
            if (got_right)
            {
                self.proper_players++;
            }
        }

        // Compare against lobby size (up to 8 players for pluto)
        if (self.proper_players == (8 - self.player_size))
        {
            ConditionsMet(false);
            ConditionsInProgress(false);
        }
        else
        {
            ConditionsInProgress(true);
        }

        wait 0.05;
    }
}

// ActorKilledTracked(einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime)
// {
//     if ( game["state"] == "postgame" )
//         return;

//     if ( isai( attacker ) && isdefined( attacker.script_owner ) )
//     {
//         if ( attacker.script_owner.team != self.aiteam )
//             attacker = attacker.script_owner;
//     }

//     if ( attacker.classname == "script_vehicle" && isdefined( attacker.owner ) )
//         attacker = attacker.owner;

//     if ( isdefined( attacker ) && isplayer( attacker ) )
//     {
//         multiplier = 1;
//         level.murderweapontype = smeansofdeath;     // Pass mod
//         level.murderweapon = sweapon;               // Pass weapon
//         level notify("zombie_killed");              // Push trigger

//         if ( is_headshot( sweapon, shitloc, smeansofdeath ) )
//             multiplier = 1.5;

//         type = undefined;

//         if ( isdefined( self.animname ) )
//         {
//             switch ( self.animname )
//             {
//                 case "quad_zombie":
//                     type = "quadkill";
//                     break;
//                 case "ape_zombie":
//                     type = "apekill";
//                     break;
//                 case "zombie":
//                     type = "zombiekill";
//                     break;
//                 case "zombie_dog":
//                     type = "dogkill";
//                     break;
//             }
//         }
//     }

//     if ( isdefined( self.is_ziplining ) && self.is_ziplining )
//         self.deathanim = undefined;

//     if ( isdefined( self.actor_killed_override ) )
//         self [[ self.actor_killed_override ]]( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime );
// }

// DoDamageNetworkSafe( e_attacker, n_amount, str_weapon, str_mod )
// {
// 	if ( isDefined( self.is_mechz ) && self.is_mechz )
// 	{
// 		self dodamage( n_amount, self.origin, e_attacker, e_attacker, "none", str_mod, 0, str_weapon );
// 	}
// 	else
// 	{
// 		if ( n_amount < self.health )
// 		{
// 			self.kill_damagetype = str_mod;
// 			maps/mp/zombies/_zm_net::network_safe_init( "dodamage", 6 );
// 			self maps/mp/zombies/_zm_net::network_choke_action( "dodamage", ::_damage_zombie_network_safe_internal, e_attacker, str_weapon, n_amount );
// 			return;
// 		}
// 		else
// 		{
//             if (str_weapon == "zm_tank_flamethrower")
//             {
//                 level notify ("tank_kill_fire"); // Notify if zombie is killed with flamethrower
//             }
// 			self.kill_damagetype = str_mod;
// 			maps/mp/zombies/_zm_net::network_safe_init( "dodamage_kill", 4 );
// 			self maps/mp/zombies/_zm_net::network_choke_action( "dodamage_kill", ::_kill_zombie_network_safe_internal, e_attacker, str_weapon );
// 		}
// 	}
// }

// WatchWpnUsageLvlNotify()
// {
//     self endon( "death" );
//     self endon( "disconnect" );
//     level endon( "game_ended" );

//     for (;;)
//     {
//         self waittill( "weapon_fired", curweapon );

//         level notify( "weapon_fired" ); // Addition

//         self.lastfiretime = gettime();
//         self.hasdonecombat = 1;

//         if ( isdefined( self.hitsthismag[curweapon] ) )
//             self thread updatemagshots( curweapon );

//         switch ( weaponclass( curweapon ) )
//         {
//             case "rifle":
//                 if ( curweapon == "crossbow_explosive_mp" )
//                 {
//                     level.globalcrossbowfired++;
//                     self addweaponstat( curweapon, "shots", 1 );
//                     self thread begingrenadetracking();
//                     break;
//                 }
//             case "spread":
//             case "smg":
//             case "pistolspread":
//             case "pistol spread":
//             case "pistol":
//             case "mg":
//                 self trackweaponfire( curweapon );
//                 level.globalshotsfired++;
//                 break;
//             case "rocketlauncher":
//             case "grenade":
//                 if ( is_alt_weapon( curweapon ) )
//                     curweapon = weaponaltweaponname( curweapon );

//                 self addweaponstat( curweapon, "shots", 1 );
//                 break;
//             default:
//                 break;
//         }

//         switch ( curweapon )
//         {
//             case "mp40_blinged_mp":
//             case "minigun_mp":
//             case "m32_mp":
//             case "m220_tow_mp":
//             case "m202_flash_mp":
//                 self.usedkillstreakweapon[curweapon] = 1;
//                 continue;
//             default:
//                 continue;
//         }
//     }
// }
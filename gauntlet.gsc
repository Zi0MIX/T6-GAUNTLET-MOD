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
#include maps/mp/zombies/_zm_game_module;
#include maps/mp/gametypes_zm/_tweakables;

main()
{
	replaceFunc(maps/mp/zombies/_zm::actor_killed_override, ::ActorKilledTracked);
    // replaceFunc(maps/mp/zombies/_zm_weapons::watchweaponusagezm, ::WatchWpnUsageLvlNotify);
}

init()
{
	level thread OnPlayerConnect();
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
        if (level.round_number <= 1)
        {
            level thread CheckForGenerator(1);
        }

        // Only use knife
        if (level.round_number == 2)
        {
            level thread WatchStat(2, "kills", "melee_kills");
        }

        level waittill("start_of_round"); // Careful not to add this inside normal fucntions
    }
}

OnPlayerSpawned()
{
    level endon( "game_ended" );
	self endon( "disconnect" );

	self waittill( "spawned_player" );

	flag_wait( "initial_blackscreen_passed" );
}

SetDvars()
//Function sets and holds level dvars / has to be level thread?
{
    while (1)
    {
        level.conditions_met = false;
        level.conditions_in_progress = false;
        level.forbidden_weapon_used = false;
        level.murderweapontype = undefined;  
        level.murderweapon = undefined;  
        level.zombie_killed = 0;
        level.gauntlet_kills = 0;

        level.debug_1 = 0;
        level.debug_2 = 0;

        level waittill("end_of_round");
        wait 3; // Must be higher than 1 ::EndGameWatcher
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
            level.conditions_met = false;
            EndGame();
        }
        wait 0.05;
    }
}

EndGame()
// Function ends the game immidiately
{
    maps\mp\zombies\_zm_game_module::freeze_players( 1 );
    level notify("end_game");
}

TimerHud()
// Timer hud displayer throught the game
{
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
    if (challenge == 2)
    {
        gauntlet_hud settext("Kill only with melee attacks");
    }

    while (level.round_number == challenge)
    {
        gauntlet_hud.color = (0.8, 0, 0);

        if (level.conditions_in_progress)
        {
            gauntlet_hud.color = (0.8, 0.8, 0);
        }
        if (level.conditions_met)
        {          
            gauntlet_hud.color = (0, 0.8, 0);
        }

        wait 0.05;
    }
    wait 5;
    gauntlet_hud fadeovertime(1.25);
    gauntlet_hud.alpha = 0;
    wait 2;
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

CheckForGenerator(generator)
// Function checks if generator is active (takes generator number)
{
    level waittill("start_of_round");
    self.generator_name = TranslateGeneratorNames(generator);
    level.conditions_met = false;
    self thread GauntletHud(1);
    self thread GeneratorCondition();

    level endon("end_of_round");
    return;
}

GeneratorCondition()
// Function will change boolean if defined generator is taken
{
    current_round = level.round_number;
    while (current_round == level.round_number)
    {
        if (level.zone_capture.zones[self.generator_name]ent_flag("player_controlled"))
        {
            level.conditions_met = true;
        }
        else
        {
            level.conditions_met = false;
        }

        wait 0.1;
    }
    return;
}

TranslateGeneratorNames(generator_id)
// Function translates generator numbers into in-game generator keys
{
    if (generator_id == 1)
    {
        return "generator_start_bunker";
    }
    if (generator_id == 2)
    {
        return "generator_tank_trench";
    }
    if (generator_id == 3)
    {
        return "generator_mid_trench";
    }
    if (generator_id == 4)
    {
        return "generator_nml_right";
    }
    if (generator_id == 5)
    {
        return "generator_nml_left";
    }
    if (generator_id == 6)
    {
        return "generator_church";
    }
}

// CountProperKills(weapon_list)
// {
//     level waittill ("zombie_killed");
//     while (1)
//     {
//         foreach (weapon in weapon_list)
//         {
//             if (level.murderweapon == weapon)
//             {
//                 level.gauntlet_kills++;
//             }
//         }
//         // wait 0.05;
//         iprintln("Proper kill:" + level.gauntlet_kills);
//         level waittill ("zombie_killed");
//     }
// }

WatchStat(challenge, stat_1, stat_2)
// Function turns on boolean in case of zombies being shot, trapped or tanked
{
    self thread GauntletHud(challenge);
    level.conditions_met = true;
    level.conditions_in_progress = true;
    level.murderweapontype = undefined;
    self thread WatchForTraps();
    self thread WatchForTank();                 // Fix that :(
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

    // level.debug_1 = beg_stat1;
    // level.debug_2 = beg_difference;

    // Watch stats midround
    rnd_stat1 = beg_stat1;
    rnd_stat2 = beg_stat2;
    while (level.round_number == rnd)
    {
        foreach (player in level.players)
        {
            rnd_stat1 = player.pers[stat_1];
            rnd_stat2 = player.pers[stat_2];
        }

        get_difference = (rnd_stat1 - rnd_stat2);

        // level.debug_1 = get_difference;
        // level.debug_2 = beg_difference;

        if (get_difference != beg_difference)
        {
            level.forbidden_weapon_used = true;
        }
        
        wait 0.05;
    }
}

WatchForTraps()
// Thread of kill watcher, will trigger boolean if zombie's killed by trap
{
    trapkills = level.zombie_trap_killed_count;
    while (1)
    {
        if (trapkills != level.zombie_trap_killed_count)
        {
            level.forbidden_weapon_used = true;
        }
        wait 0.05;
    }
    // level waittill_any("trap_kill", "vo_tank_flame_zombie");
    // level.forbidden_weapon_used = true;
}

WatchForTank()
// Shit don't work atm
{
    while (1)
    {
        if (isdefined(level.murderweapontype) && level.murderweapontype == "MOD_BURNED") 
        {
            level.forbidden_weapon_used = true;
        }
        wait 0.05;
    }
}

// WatchForShoot(challenge)
// //Function register any of the lethal events and sets conditions met to false
// {
//     level.conditions_met = true;

//     level thread GauntletHud(2);
//     self thread WatchForNade();
    
//     level waittill("weapon_fired", "trap_kill", "vo_tank_flame_zombie");
//     level.forbidden_weapon_used = true;

//     self destroy();
// }

// WatchForNade()
// {
//     level waittill("grenade_exploded");
//     level.forbidden_weapon_used = true;
// }

// ZombieKilledInTheRound()
// //Function tracks kills during round
// {
//     level waittill ("start_of_round");
//     zombies_in_round = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;

//     while (1)
//     {
//         zombie_count = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;
//         level.zombie_killed = zombies_in_round - zombie_count;
//         // iprintln("Killed:" + level.zombie_killed);
//         wait 0.05;
//         if (zombie_count == 0)
//         {
//             wait 1;
//             level.zombie_killed = 0;
//             return;
//         }
//     }
// }

// WatchKills(kill_with)
// {
//     level.gauntlet_kills = 0;
//     weap_array = [];
//     if (kill_with == "m14")
//     {
//         weap_array = array("m14_zm", "m14_upgraded_zm");
//     }
//     if (kill_with == "mp40")
//     {
//         weap_array = array("mp40_zm", "mp40_stalker_zm", "mp40_upgraded_zm", "mp40_stalker_upgraded_zm");
//     }
//     if (kill_with == "melee")
//     {
//         weap_array = array("knife_zm", "one_inch_punch_air_zm", "one_inch_punch_fire_zm", "one_inch_punch_ice_zm", "one_inch_punch_lightning_zm", "one_inch_punch_upgraded_zm", "one_inch_punch_zm", "riotshield_zm", "staff_air_melee_zm", "staff_fire_melee_zm", "staff_lightning_melee_zm", "staff_water_melee_zm", "tomb_shield_zm");
//     }

//     level thread ZombieKilledInTheRound();
//     // level thread CountProperKills();
// }

ActorKilledTracked(einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime)
{
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
        level.murderweapontype = smeansofdeath;     // Pass mod
        level.murderweapon = sweapon;               // Pass weapon
        level notify("zombie_killed");              // Push trigger

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
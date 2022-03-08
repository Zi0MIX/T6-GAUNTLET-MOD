#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/animscripts/zm_utility;
#include maps/mp/zm_tomb;
#include maps/mp/zm_tomb_utility;
// New
#include maps/mp/zm_tomb_capture_zones;
#include maps/mp/zombies/_zm_game_module;
#include maps/mp/gametypes_zm/_tweakables;

main()
{
	replaceFunc( maps/mp/zombies/_zm::actor_killed_override, ::ActorKilledTracked );
}

init()
{
	level thread OnPlayerConnect();
}

OnPlayerConnect()
{
	level waittill("connecting", player );	

	player thread OnPlayerSpawned();

	// level thread SetDvars();	
	level waittill("initial_players_connected");
    level.conditions_met = false;
    level.conditions_in_progress = false;
    level.murderweapontype = undefined;  
    level.murderweapon = undefined;  
    level.zombie_killed = 0;
    level.gauntlet_kills = 0;

    flag_wait("initial_blackscreen_passed");
    level thread TimerHud();

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
            level thread WatchKills("melee");
        }

        level waittill("start_of_round");
    }
}

OnPlayerSpawned()
{
    level endon( "game_ended" );
	self endon( "disconnect" );

	self waittill( "spawned_player" );

	flag_wait( "initial_blackscreen_passed" );
}

GameFailed()
//Function ends the game upon failure to complete gauntlet task
{
    maps\mp\zombies\_zm_game_module::freeze_players( 1 );
    level notify("end_game");
}

TimerHud()
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
{
    if (challenge == 1)
    {
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
        gauntlet_hud.color = (0.8, 0, 0);
        gauntlet_hud settext("Turn on Generator 1");

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
        gauntlet_hud destroy();
    }
}

ZombieKilledInTheRound()
{
    level waittill ("start_of_round");
    zombies_in_round = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;

    while (1)
    {
        zombie_count = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;
        level.zombie_killed = zombies_in_round - zombie_count;
        iprintln("Killed:" + level.zombie_killed);
        wait 0.05;
        if (zombie_count == 0)
        {
            wait 1;
            level.zombie_killed = 0;
            return;
        }
    }
}

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

CheckForGenerator(generator)
// Function checks if generator is active (takes generator number)
{
    level waittill("start_of_round");
    self.generator_name = TranslateGeneratorNames(generator);
    level.conditions_met = false;
    level thread GauntletHud(1);
    self thread GeneratorCondition();

    level waittill("end_of_round");
    if (level.conditions_met == false)
    {
        GameFailed();
    }
    return;
}

GeneratorCondition()
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

WatchKills(kill_with)
{
    level.gauntlet_kills = 0;
    weap_array = [];
    if (kill_with == "m14")
    {
        weap_array = array("m14_zm", "m14_upgraded_zm");
    }
    if (kill_with == "mp40")
    {
        weap_array = array("mp40_zm", "mp40_stalker_zm", "mp40_upgraded_zm", "mp40_stalker_upgraded_zm");
    }
    if (kill_with == "melee")
    {
        weap_array = array("knife_zm", "one_inch_punch_air_zm", "one_inch_punch_fire_zm", "one_inch_punch_ice_zm", "one_inch_punch_lightning_zm", "one_inch_punch_upgraded_zm", "one_inch_punch_zm", "riotshield_zm", "staff_air_melee_zm", "staff_fire_melee_zm", "staff_lightning_melee_zm", "staff_water_melee_zm", "tomb_shield_zm");
    }

    // level thread WatchForNades()    // Nades are forbidden in each case
    level thread ZombieKilledInTheRound();
    level thread CountProperKills();

    while (1)
    {
        if (level.gauntlet_kills != level.zombie_killed)
        {
            GameFailed();
        }
        wait 0.05;
    }
}

// WatchForNades()
// {
//     currentround = level.round_number;
//     while (level.round_number == currentround)
//     {
//         foreach (player in level.players)
//         {
//             if (player isthrowinggrenade())
//             {
//                 level notify ("nade_thrown");
//             }
//         }
//         wait_network_frame();
//     }
//     return;
// }

CountProperKills(weapon_list)
{
    level waittill ("zombie_killed");
    while (1)
    {
        foreach (weapon in weapon_list)
        {
            if (level.murderweapon == weapon)
            {
                level.gauntlet_kills++;
            }
        }
        // wait 0.05;
        iprintln("Proper kill:" + level.gauntlet_kills);
        level waittill ("zombie_killed");
    }
}
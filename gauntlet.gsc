#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/animscripts/zm_utility;
#include maps/mp/zm_tomb;
#include maps/mp/zm_tomb_utility;

#include maps/mp/zm_tomb_capture_zones;
#include maps\mp\zombies\_zm_game_module;

main()
{
	// replaceFunc( maps/mp/animscripts/zm_utility::wait_network_frame, ::FixNetworkFrame );
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

    level waittill("start_of_round");
    while (1)
    {
        // Activate generator 1
        if (level.round_number == 1)
        {
            level thread CheckForGenerator(1);
        }

        // Only use knife
        if (level.round_number == 2)
        {

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


CheckForGenerator(generator)
// Function checks if generator is active (takes generator number)
{
    generator_name = TranslateGeneratorNames(generator);
    level waittill("end_of_round");
    if (!level.zone_capture.zones[generator_name]ent_flag("player_controlled"))
    {
        GameFailed();
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
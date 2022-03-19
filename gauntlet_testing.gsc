#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zombies/_zm_weapons;

init()
{
    level thread OnPlayerConnect();
}

OnPlayerConnect()
{
    level waittill("connecting", player );	
    // player thread OnPlayerSpawned();

    flag_wait("initial_blackscreen_passed");
    level waittill ("start_of_round");
    foreach (player in level.players)
    {
        player giveWeapon("raygun_mark2_zm");
        player switchtoweapon("raygun_mark2_zm");
        player givestartammo("raygun_mark2_zm");
    }
}

OnPlayerSpawned()
{
    level endon( "game_ended" );
	self endon( "disconnect" );

    self waittill( "spawned_player" );
}

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
#include maps/mp/gametypes_zm/_shellshock;
#include maps/mp/gametypes_zm/_weapons;
#include maps/mp/gametypes_zm/_globallogic_score;
#include maps/mp/zombies/_zm_game_module;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_ai_mechz;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_perk_random;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_magicbox;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_powerups;
#include maps/mp/zombies/_zm;

main()
{
    // Pluto QoL changes
	replaceFunc(maps/mp/animscripts/zm_utility::wait_network_frame, ::wait_network_frame_override);
	replaceFunc(maps/mp/zombies/_zm_utility::wait_network_frame, ::wait_network_frame_override);    
    replaceFunc(maps/mp/zm_tomb_capture_zones::recapture_round_tracker, ::recapture_round_tracker_override);
    replaceFunc(maps/mp/zombies/_zm_powerups::powerup_drop, ::powerup_drop_override);
}

init()
{
	level thread OnPlayerConnect();
    flag_init("env_kill");
    flag_init("out_of_zone");
    flag_init("zone_init");
    flag_init("break_early");
    flag_init("just_set_weapon");
    flag_init("nuke_taken");
    flag_init("insta_taken");
    flag_init("max_taken");
    flag_init("double_taken");
    flag_init("blood_taken");
    flag_init("sale_taken");
    flag_init("rnd_end");
}

OnPlayerConnect()
{
	level waittill("connecting", player );	
    
	level thread OnPlayerSpawned();

	level waittill("initial_players_connected");
    level thread SetDvars();
    // level thread DevDebug("raygun_mark2_upgraded_zm", 9);   // For debugging

    flag_wait("initial_blackscreen_passed");

    level thread TimerHud();
    level thread ZombieCounterHudNew();
    level thread NetworkFrameHud();
    level thread GauntletHud();
    level thread ProgressHud();
    level thread BetaHud(9);

    level thread EndGameWatcher();
    level thread GameRules();
    level thread DropWatcher();
    
    // For debugging
    if (isdefined(level.wait_for_round))
    {
        iPrintLn("Waiting");
        level waittill ("start_of_round");
    }

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
            level thread CheckUsedWeapon(2);
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
            level thread WatchPlayerStat(5, "grabbed_from_magicbox", 1, 1, undefined, undefined, undefined);
        }

        // Dig as many piles as there are players in game
        else if (level.round_number == 6)
        {
            level thread WatchPlayerStat(6, "tomb_dig", 0, 0, 0, 0, level.players.size);
        }

        // Knife kill 6 zombies (12 coop)
        else if (level.round_number == 7)
        {
            level thread WatchPlayerStat(7, "melee_kills", 0, 6, 0, 0, 6);
        }

        // Have one jug by the end of the round
        else if (level.round_number == 8)
        {
            level thread WatchPerks(8, 1);
        }

        // Only kill with mp40
        else if (level.round_number == 9)
        {
            level thread CheckUsedWeapon(9);
        }   

        // Jumping only
        else if (level.round_number == 10)
        {
            level thread DisableMovement(10);
        }

        // Don't buy anything
        else if (level.round_number == 11)
        {
            level thread BuyNothing(11);
        }

        // Have at least one upgraded staff at the end of the round
        else if (level.round_number == 12)
        {
            level thread WatchUpgradedStaffs(12, 1);
        }

        // Take points if not moving
        else if (level.round_number == 13)
        {
            level thread SprintWatcher(13, "points");
        }

        // Survive a round with super-sprinters
        else if (level.round_number == 14)
        {
            level thread ZombieSuperSprint(14);
        }

        // Activate all generators
        else if (level.round_number == 15)
        {
            level thread CheckForGenerator(15, 0);
        }

        // Survive a round with Panzers
        else if (level.round_number == 16)
        {
            level thread TooManyPanzers(16, false);
        }

        // Dig 7 piles in total
        else if (level.round_number == 17)
        {
            level thread WatchPlayerStat(17, "tomb_dig", 0, 0, 0, 0, 7);
        }

        // Timescale
        else if (level.round_number == 18)
        {
            level thread SetDvarForRound(18, "timescale", 1.6, 1);
        }

        // Only kill with mp40
        else if (level.round_number == 19)
        {
            level thread CheckUsedWeapon(19);
        }   

        // Protect church
        else if (level.round_number == 20)
        {
            level thread CheckForZone(20, array("zone_village_2"), 60);
        }

        // Have five perks at the end of the round
        else if (level.round_number == 21)
        {
            level thread WatchPerks(21, 5);
        }

        // All perks are off
        else if (level.round_number == 22)
        {
            level thread ShutDownPerk(22, "all");
        }

        // Deal damage if not moving
        else if (level.round_number == 23)
        {
            level thread SprintWatcher(23, "health");
        }   

        // Only use first room weapons
        else if (level.round_number == 24)
        {
            level thread CheckUsedWeapon(24);
        }

        // GunGame
        else if (level.round_number == 25)
        {
            level thread GunGame(25);
        }

        // Only kill with m14
        else if (level.round_number == 26)
        {
            level thread TankEm(26);
        }  

        // Only kill zombies indoors
        else if (level.round_number == 27)
        {
            level thread IndoorsHub(27);
        }

        // Only kill with mp40
        else if (level.round_number == 28)
        {
            level thread WatchPlayerStat(28, "drops", 0, 0, 0, 0, 1);
        }   

        // Guns eat up twice as much ammo
        else if (level.round_number == 29)
        {
            level thread AmmoController(29);
        }   
        
        else if (level.roun_number == 30)
        {
            level thread GrandFinale(30);
        }

        level waittill("start_of_round"); // Careful not to add this inside normal fucntions

        wait 0.05;
    }
}

OnPlayerSpawned()
{
    level endon( "game_ended" );
	self endon( "disconnect" );

	flag_wait( "initial_blackscreen_passed" );

	for (;;)
    {
        level waittill("connected", player);
        player thread PlayerInit();
    }
}

PlayerInit()
// Function to execute for players joining game
{

}

SetDvars()
//Function sets and holds level dvars
{
    level endon( "game_ended" );
    
    foreach(player in level.players)
    {
        player.score = 505;
    }
    level.conditions_met = false;
    level.conditions_in_progress = false;
    self thread LevelDvarsWatcher();
    level.player_too_many_weapons_monitor = 0;
    level.second_chance = true;
    level.callbackactorkilled = ::actor_killed_override; // Pointer
    // level.player_too_many_weapons_monitor_func = ::player_too_many_weapons_monitor_override;

    level.weapon_used = undefined;
    level.killer_class = undefined;

    level.hud_quota = 0;
    level.hud_current = 0;

    while (1)
    {
        level.conditions_met = false;
        level.conditions_in_progress = false;
        level.forbidden_weapon_used = false;
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
        level.allplayersup = false;

        // level.hud_quota = 0;
        // level.hud_current = 0;

        level.player_too_many_weapons_monitor = 0;

        flag_clear("env_kill");
        flag_clear("zone_init");
        flag_clear("nuke_taken");
        flag_clear("insta_taken");
        flag_clear("max_taken");
        flag_clear("double_taken");
        flag_clear("blood_taken");
        flag_clear("sale_taken");
        flag_clear("rnd_end");

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

        else if (level.round_number > 30)
        {
            WinGame();
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
            level.forbidden_weapon_used = false;
        }
        wait 0.05;
    }
}

EndGame()
// Function either ends the game or triggers second chance event
{
    if (isdefined(level.second_chance) && level.second_chance)
    {
        level.second_chance = false;
        team_size = level.players.size;
        self thread SecondChanceHud(team_size);
        // Down a player
        if (team_size == 1)
        {
            player = level.players[0];
            if (!player player_is_in_laststand())
            {
                player dodamage(player.maxhealth, player.origin);
            }
            return;
        }
        while (1)
        {
            lucky_one = randomInt(team_size - 1);
            if (level.players[lucky_one] player_is_in_laststand())
            {
                wait 0.05;
                continue;
            }
            break;
        }
        i = 0;
        foreach (player in level.players)
        {
            if (i != lucky_one && !player player_is_in_laststand())
            {
                player dodamage(player.maxhealth, player.origin);
            }
            i++;
        }
        return;
    }
    if (isdefined(level.debug_weapons) && level.debug_weapons)
    {
        iprintln("you bad");
    }
    ConditionsMet(false);
    ConditionsInProgress(false);
    wait 0.1;
    maps\mp\zombies\_zm_game_module::freeze_players(1);
    level notify("end_game");
    return;
}

WinGame()
// Function ends the game with you win screen
{
    if (isdefined(level.debug_weapons) && level.debug_weapons)
    {
        iprintln("you win");
    }
    level._supress_survived_screen = 1;
    level.completition_time = int(gettime() / 1000);
    level.custom_end_screen = ::CustomEndScreen;
    ConditionsMet(false);
    ConditionsInProgress(false);
    wait 0.1;
    maps\mp\zombies\_zm_game_module::freeze_players( 1 );
    // level notify("game_won");
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

DevDebug(weapon, round)
// Function to set up debugging vars and items
{
    level endon( "game_ended" );
	self endon( "disconnect" );

    level.wait_for_round = true;
    level.debug_weapons = true;

    if (isdefined(round))
    {
        level.round_number = round;
    }

    level waittill ("start_of_round");

    if (isdefined(weapon))
    {
        foreach (player in level.players)
        {
            player giveWeapon(weapon);
            player switchtoweapon(weapon);
            player givestartammo(weapon);
            player.score = 50005;
        }
    }

    if( level.player_out_of_playable_area_monitor && IsDefined( level.player_out_of_playable_area_monitor ) )
	{
		self notify( "stop_player_out_of_playable_area_monitor" );
	}
	level.player_out_of_playable_area_monitor = 0;
}

GameRules()
// Function to modify game rules throught the gauntlet
{
    while (1)
    {
        level waittill ("start_of_round");
        wait 15;

        // Predefine weather between round 5-12
        level.force_weather[5] = "rain";
        level.force_weather[6] = "snow";
        level.force_weather[7] = "snow";
        level.force_weather[8] = "clear";
        level.force_weather[9] = "rain";
        // level.force_weather[10] = "snow"; // Already predefined init_weather_manager()
        level.force_weather[11] = "clear";
        level.force_weather[12] = "clear";

        if (level.round_number == 8)
        {
            level.next_mechz_round = 12;
        }
        if (level.round_number == 10)
        {
            level.n_next_recapture_round = 14;
        }
        if (level.round_number == 12)
        {
            level.next_mechz_round = 16;
        }
        if (level.round_number == 14)
        {
            level.n_next_recapture_round = 18;
        }
        if (level.round_number == 16)
        {
            level.next_mechz_round = 20;
        }
        if (level.round_number == 18)
        {
            level.n_next_recapture_round = 23;
        }
        if (level.round_number == 20)
        {
            level.next_mechz_round = 24;
        }   
        if (level.round_number == 23)
        {
            level.n_next_recapture_round = 26;
        }
        if (level.round_number == 24)
        {
            level.next_mechz_round = 28;
        }  
        if (level.round_number == 28)
        {
            level.next_mechz_round = 30;
        }    

        level waittill ("end_of_round");                 
    }
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

    timer_hud = createserverfontstring("hudsmall" , 1.6);
	timer_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 0);					
	timer_hud.alpha = 1;
	timer_hud.color = (0.6, 0.8, 1);
	timer_hud.hidewheninmenu = 1;

	timer_hud setTimerUp(0); 
}

ZombieCounterHudNew()
// Zombie counter - forked from Remix
{
    self endon("disconnect");
    level endon("end_game");

    counter_hud = createserverfontstring("hudsmall" , 1.4);
    counter_hud setPoint("CENTER", "CENTER", "CENTER", 185);
	counter_hud.alpha = 1;
    counter_hud.hidewheninmenu = 1;  
    counter_hud.label = &"ZOMBIES: ^5";
    counter_hud setValue(0); 

	level waittill("start_of_round");

    while (1)
    {
        if (isdefined(level.zombie_total))
        {
            current_zombz = get_round_enemy_array().size + level.zombie_total;
        }

        if (level.round_number >= 10 && current_zombz <= 12)
        {
            counter_hud.label = &"ZOMBIES: ^3";
        }
        else
        {
            counter_hud.label = &"ZOMBIES: ^5";
        }

        counter_hud setValue(current_zombz); 
        wait 0.05;
    }
}

GauntletHud()
// Hud for printing challenge goals
{
    self endon("disconnect");
    level endon("end_game");

    if (isdefined(gauntlet_hud))
    {
        gauntlet_hud destroyelem();
    }

    gauntlet_hud = createserverfontstring("hudsmall", 1.4);
    gauntlet_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 50);
	gauntlet_hud.alpha = 0;
    gauntlet_hud.hidewheninmenu = 1;    
    gauntlet_hud setText("Origins gauntlet");
    gauntlet_hud.color = (0.6, 0.8, 1);

    level waittill("start_of_round");

    while (1)
    {
        relative_var = SetRelativeVar(level.round_number);
        if (!isdefined(relative_var) || relative_var == 0)
        {

        }

        multiples = "s";
        if (level.players.size == 1)
        {
            multiples = "";
        }
        
        if (level.round_number == 1)
        {
            gauntlet_hud settext("Activate generator 1");
        }
        else if (level.round_number == 2)
        {
            gauntlet_hud settext("Kill only with");
        }
        else if (level.round_number == 3)
        {
            gauntlet_hud settext("Movement restricted");
        }
        else if (level.round_number == 4)
        {
            gauntlet_hud settext("Own a perk at the end of the round");
        }
        else if (level.round_number == 5)
        {
            gauntlet_hud settext("Pull a weapon from the mystery box");
        }
        else if (level.round_number == 6)
        {
            gauntlet_hud settext("Dig up " + relative_var + " pile" + multiples + " total");
        }
        else if (level.round_number == 7)
        {
            gauntlet_hud settext("Kill " + relative_var + " zombies total with melee attacks");
        }
        else if (level.round_number == 8)
        {
            gauntlet_hud settext("Own Jugger-Nog by the end of the round");
        }
        else if (level.round_number == 9)
        {
            gauntlet_hud settext("Only kill with");
        }
        else if (level.round_number == 10)
        {
            gauntlet_hud settext("Movement restricted");
        }
        else if (level.round_number == 11)
        {
            gauntlet_hud settext("Don't buy anything");
        }
        else if (level.round_number == 12)
        {
            gauntlet_hud settext("Upgrade a staff");
        }
        else if (level.round_number == 13)
        {
            gauntlet_hud settext("Keep moving or lose");
        }
        else if (level.round_number == 14)
        {
            gauntlet_hud settext("Round with super-sprinters");
        }
        else if (level.round_number == 15)
        {
            gauntlet_hud settext("Activate all generators");
        }
        else if (level.round_number == 16)
        {
            gauntlet_hud settext("Round with panzers");
        }
        else if (level.round_number == 17)
        {
            gauntlet_hud settext("Dig up 7 piles total");
        }
        else if (level.round_number == 18)
        {
            gauntlet_hud settext("Time is faster");
        }
        else if (level.round_number == 19)
        {
            gauntlet_hud settext("Only kill with");
        }
        else if (level.round_number == 20)
        {
            gauntlet_hud settext("Protect the zone");
        }
        else if (level.round_number == 21)
        {
            gauntlet_hud settext("Own " + relative_var + " perks at the end of the round");
        }
        else if (level.round_number == 22)
        {
            gauntlet_hud settext("All perks are offline");
        }
        else if (level.round_number == 23)
        {
            gauntlet_hud settext("Keep moving or lose");
        }
        else if (level.round_number == 24)
        {
            gauntlet_hud settext("Only kill with");
        }
        else if (level.round_number == 25)
        {
            gauntlet_hud settext("Weapons shuffle");
        }
        else if (level.round_number == 26)
        {
            gauntlet_hud settext("Kill " + relative_var + " zombies with tank");
        }
        else if (level.round_number == 27)
        {
            gauntlet_hud settext("Only kill while");
        }
        else if (level.round_number == 28)
        {
            gauntlet_hud settext("Don't pick up");
        }
        else if (level.round_number == 29)
        {
            gauntlet_hud settext("Each shot cost more ammo");
        }
        else if (level.round_number == 30)
        {
            gauntlet_hud settext("Protect the zone");
        }
	    gauntlet_hud.alpha = 1;

        level waittill ("end_of_round");

        wait 5;
        gauntlet_hud fadeovertime(1.5);
        gauntlet_hud.alpha = 0;

        level waittill ("start_of_round");
    }
}

ProgressHud()
// Hud to display challenge progress
{
    self endon("disconnect");
    level endon("end_game");

    if (isdefined(progress_hud))
    {
        self.progress_hud destroyelem();
    }

    level waittill("start_of_round");

    self.progress_hud = createserverfontstring("hudsmall" , 2);
    self.progress_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 70);
    self.progress_hud.alpha = 0;
    self.progress_hud.hidewheninmenu = 1;  
    self.progress_hud setText("Origins gauntlet");
    self.progress_hud.color = (1, 0.7, 0.4);

    mode_counter = array(1, 4, 8, 5, 6, 7, 15, 17, 21, 26);
    mode_zone = array(20, 30);

    while (1)
    {
        text = undefined;
        mode = undefined;
        current_round = level.round_number;
        self.progress_hud.color = (1, 0.7, 0.4);                 // Orange

        if (isinarray(mode_counter, current_round))
        {
            mode = "counter";
        }
        else if (isinarray(mode_zone, current_round))
        {
            mode = "zone";
        }
        else
        {
            if (current_round == 2)
            {
                text = "MELEE WEAPONS";
            }
            else if (current_round == 3)
            {
                text = "CAN'T MOVE";
            }
            else if (current_round == 9 || current_round == 19)
            {
                text = "MP-40";
            }
            else if (current_round == 10)
            {
                text = "CAN'T JUMP";
            }
            else if (current_round == 12)
            {
                text = "YET TO UPGRADE";
            }
            else if (current_round == 13)
            {
                text = "POINTS";
            }
            else if (current_round == 20)
            {
                text = "CHURCH";
            }
            else if (current_round == 23)
            {
                text = "HEALTH";
            }
            else if (current_round == 24)
            {
                text = "FIRST ROOM WEAPONS";
            }
            else if (current_round == 27)
            {
                text = "INDOORS";
            }
            else if (current_round == 28)
            {
                text = "POWERUPS";
            }
            else if (current_round == 29)
            {
                text = "ONE SHOT = TWO BULLETS";
            }
            else if (current_round == 30)
            {
                text = "STAFF CHAMBER";
            }
        }

        if (!isdefined(text))
        {
            text = "SURVIVE";
        }
        if (!isdefined(mode))
        {
            mode = "none";
        }

        self.progress_hud.alpha = 1;
        self thread ProgressHudSet(mode, text);
        
        level waittill("end_of_round");

        wait 1;
        self.progress_hud.color = (1, 0.7, 0.4);                // Orange
        // If statement deals with challenges that tick at the end of round
        if (level.conditions_met)
        {
            self.progress_hud.color = (0.4, 0.7, 1);            // Blue
            self.progress_hud setText("SUCCESS");
        }
        wait 4;
        self.progress_hud fadeovertime(1.5);
        self.progress_hud.alpha = 0;

        level waittill("start_of_round");
    }
}

ProgressHudSet(mode, text)
{
    level endon("end_of_round");
    
    while (1)
    {
        if (mode == "counter")
        {
            if (level.conditions_met)
            {
                self.progress_hud.color = (0.4, 0.7, 1);         // Blue
                self.progress_hud setText("SUCCESS");
            }
            else
            {
                if (level.conditions_in_progress)
                {
                    self.progress_hud.color = (1, 1, 0.4);       // Yellow
                }
                else
                {
                    self.progress_hud.color = (1, 0.7, 0.4);     // Orange
                }

                self.progress_hud setText(level.hud_current + "/" + level.hud_quota);
            }
        }
        else if (mode == "zone")
        {
            self.progress_hud.color = (1, 0.7, 0.4);             // Orange
            self.progress_hud setText(text);
            if (level.conditions_in_progress)
            {
                self.progress_hud.color = (1, 1, 0.4);           // Yellow
            }
            else if (level.conditions_met)
            {
                self.progress_hud.color = (0.4, 0.7, 1);         // Blue
                self.progress_hud setText("SUCCESS");
            }
        }
        else
        {
            self.progress_hud.color = (1, 0.7, 0.4);             // Orange
            self.progress_hud setText(text);
            if (level.conditions_met)
            {
                self.progress_hud.color = (0.4, 0.7, 1);         // Blue
                self.progress_hud setText("SUCCESS");
            }
        }
        wait 0.05;
    }
}

PersonalProgressHud(player_quota, player_id)
// HUD for tracking personal progress. To call on player thread
{
    self endon("disconnect");
    level endon("end_game");

    if (isdefined(personal_hud))
    {
        personal_hud destroyelem();
    }
    if (!isdefined(player_quota))
    {
        player_quota = 1;
    }
    if (!isdefined(player_id))
    {
        player_id = 0;
    }
    current_round = level.round_number;

    personal_hud = createFontString("hudsmall" , 1.7);
    personal_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 90);
    personal_hud.alpha = 0;
    personal_hud.hidewheninmenu = 1;  
    personal_hud settext("Origins gauntlet");
    personal_hud.color = (1, 0.7, 0.4);
    personal_hud.label = &"PERSONAL: ";

    while (current_round == level.round_number)
    {
        if (isdefined(level.players[player_id].personal_var))
        {
            if (isdefined(personal) && (personal == level.players[player_id].personal_var))
            {
                wait 0.05;
                continue;
            }
            
            personal = level.players[player_id].personal_var;
            text_updated = (personal + "/" + player_quota);
            personal_hud settext(text_updated);
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                self iPrintLn("text: " + text_updated);
            }

            personal_hud.color = (1, 0.7, 0.4);                // Orange
            if (personal == player_quota)
            {
                personal_hud.color = (0.4, 0.7, 1);            // Blue
            }

            if (personal_hud.alpha == 0)
            {
                if (isdefined(level.debug_weapons) && level.debug_weapons)
                {
                    iPrintLn("alpha 1");
                }
                personal_hud.alpha = 1;
            }
        }
        else
        {
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("undefined player_curr");
            }
            wait 1;
        }

        // if (flag("rnd_end"))
        // {
        //     break;
        // }
        wait 0.05;
    }
    wait 1;
    personal_hud.color = (1, 0.7, 0.4);                     // Orange
    if (level.conditions_met)
    {
        personal_hud.color = (0.4, 0.7, 1);                 // Blue
    }

    wait 4;
    personal_hud fadeovertime(1.5);
    personal_hud.alpha = 0;
}

ZoneHudPersonal(time, player_id)
// Hud for zone related challenges
{
    self endon("disconnect");
    level endon("end_game");

    if (isdefined(zone_hud))
    {
        zone_hud destroyelem();
    }
    if (!isdefined(time))
    {
        time = 45;
    }    
    if (!isdefined(player_id))
    {
        player_id = 0;
    }

    time_stop = int(gettime() + (time * 1000));
    current_round = level.round_number;

    zone_hud = createFontString("hudsmall" , 1.7);
    zone_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 90);
    zone_hud.alpha = 0;
    zone_hud.hidewheninmenu = 1;  
    zone_hud settext("Origins gauntlet");
    zone_hud.color = (1, 1, 0.4);
    zone_hud.label = &"GET TO ZONE: ";

    while (1)
    {       
        timer = int((time_stop - gettime()) / 1000);
        zone_hud setValue(timer);
        if (zone_hud.alpha == 0)
        {
            zone_hud.alpha = 1;
        }

        if (isdefined(level.players[player_id].right_zone) && level.players[player_id].right_zone)
        {
            zone_hud.label = &"";
            zone_hud.color = (0.4, 0.7, 1);
            zone_hud settext("SUCCESSFULLY GOT TO THE ZONE");
            break;
        }
            
        if (timer <= 0 || flag("break_early"))
        {
            zone_hud.label = &"";
            zone_hud.color = (1, 0.4, 0.4);
            zone_hud settext("FAILED");
            break;
        }

        wait 1;
    }
    wait 3;
    zone_hud fadeovertime(1.5);
    zone_hud.alpha = 0;

    // level waittill ("zone_init");
    while (current_round == level.round_number)
    {
        if (isdefined(level.players[player_id].right_zone) && !level.players[player_id] player_is_in_laststand())
        {
            if (!level.players[player_id].right_zone)
            {
                zone_hud.label = &"GET BACK TO ZONE: ";
                zone_hud.color = (1, 1, 0.4);
                zone_hud setValue(5);
                zone_hud.alpha = 1;
                wait 1;
            }
            if (!level.players[player_id].right_zone)
            {
                zone_hud setValue(4);
                wait 1;
            }
            if (!level.players[player_id].right_zone)
            {
                zone_hud setValue(3);
                wait 1;
            }
            if (!level.players[player_id].right_zone)
            {
                zone_hud.color = (1, 0.7, 0.4);
                zone_hud setValue(2);
                wait 1;
            }
            if (!level.players[player_id].right_zone)
            {
                zone_hud setValue(1);
                wait 1;
            }
            if (!level.players[player_id].right_zone)
            {
                zone_hud.label = &"";
                zone_hud.color = (1, 0.4, 0.4);
                zone_hud setText("FAILED");
                wait 1;
                zone_hud.alpha = 0;
            }
            zone_hud.alpha = 0;
        }
        wait 0.05;
    }
}

CustomEndScreen()
// Custom text for end game to display time
{
    self endon ("disconnect");

    win_hud = createserverfontstring("hudsmall" , 2.4);
    win_hud setPoint("CENTER", "CENTER", "CENTER", -50);
	win_hud.alpha = 0;
    win_hud setText("YOU WIN"); 
    win_hud fadeovertime(1);    
    win_hud.alpha = 1;  

    win_hud2 = createserverfontstring("hudsmall" , 2.2);
    win_hud2 setPoint("CENTER", "CENTER", "CENTER", -25);
	win_hud2.alpha = 0;
    win_hud2 setText(to_mins(level.completition_time)); 
    win_hud2 fadeovertime(1);    
    win_hud2.alpha = 1;  
}

SecondChanceHud(team_size)
{
    self endon("disconnect");
    level endon("end_game");

    chance_hud = createserverfontstring("hudsmall" , 2.2);
    chance_hud setPoint("CENTER", "CENTER", "CENTER", -10);
	chance_hud.alpha = 0;
    chance_hud.color = (1, 0.8, 0.6);
    chance_hud setText("SECOND CHANCE"); 
    if (team_size == 1)
    {
        chance_hud setText("CHALLENGE FAILED"); 
    }

    chance_hud fadeovertime(1);    
	chance_hud.alpha = 1;
    wait 7;
    chance_hud fadeovertime(1);    
	chance_hud.alpha = 0;
}

BetaHud(beta_version)
// Function for beta overlay
{
    self endon("disconnect");
    level endon("end_game");

    counter_hud = createserverfontstring("hudsmall" , 1);
    counter_hud setPoint("TOP", "TOP", "CENTER", 10);
	counter_hud.alpha = 0.3;
    counter_hud.label = &"^4BETA V";
    counter_hud setValue(beta_version); 
}

SetRelativeVar(rnd)
// Return hardcoded relative variables for gauntlet hud
{
    if (rnd == 6)
    {
        return level.players.size;
    }
    else if (rnd == 7)
    {
        if (level.players.size == 1)
        {
            return 6;
        }
        return 12;
    }
    else if (rnd == 21)
    {
        if (level.players.size > 4)
        {
            return 4;
        }
        return 5;
    }
    else if (rnd == 26)
    {
        temp_tank = 24 + (level.players.size * 24);
        if (temp_tank > 120)
        {
            temp_tank = 120;
        }
        return temp_tank;
    }

    return 0;
}

CheckForGenerator(challenge, gen_id)
// Master function for checking generators. Pass 0 as gen_id to verify all gens
{
    level endon("end_game");
    level endon("start_of_round");

    current_round = level.round_number;
    level.hud_quota = 1;
    if (gen_id == 0)
    {
        level.hud_quota = 6;
    }

    self thread GenControlProgress(current_round, gen_id);
    self thread GeneratorCondition(current_round, gen_id);
    self thread GeneratorWatcher(current_round);
}

GeneratorCondition(current_round, generator_id)
// Function will change boolean if defined generator is taken
{
    while (current_round == level.round_number)
    {
        if (level.active_gen_1 && generator_id == 1)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_2 && generator_id == 2)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_3 && generator_id == 3)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_4 && generator_id == 4)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_5 && generator_id == 5)
        {
            ConditionsMet(true);
        }

        else if (level.active_gen_6 && generator_id == 6)
        {
            ConditionsMet(true);
        }

        else if (generator_id == 0)
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

GeneratorWatcher(current_round)
// Function watches for current state of gens and changing booleans accordingly
{
    while (current_round == level.round_number)
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

GenControlProgress(current_round, generator_id)
// Function to calculate progress for generators on hud
{
    while (current_round == level.round_number)
    {
        if (generator_id == 0)
        {
            level.hud_current = 0;

            if (level.active_gen_1)
            {
                level.hud_current++;
            }
            if (level.active_gen_2)
            {
                level.hud_current++;
            }        
            if (level.active_gen_3)
            {
                level.hud_current++;
            }        
            if (level.active_gen_4)
            {
                level.hud_current++;
            }        
            if (level.active_gen_5)
            {
                level.hud_current++;
            } 
            if (level.active_gen_6)
            {
                level.hud_current++;
            }  
        }    
        else
        {
            if (generator_id == 1 && level.active_gen_1)
            {
                level.hud_current = 1;
            }
            else if (generator_id == 2 && level.active_gen_2)
            {
                level.hud_current = 1;
            }
            else if (generator_id == 3 && level.active_gen_3)
            {
                level.hud_current = 1;
            }
            else if (generator_id == 4 && level.active_gen_4)
            {
                level.hud_current = 1;
            }
            else if (generator_id == 5 && level.active_gen_5)
            {
                level.hud_current = 1;
            }
            else if (generator_id == 6 && level.active_gen_6)
            {
                level.hud_current = 1;
            }
            else
            {
                level.hud_current = 0;
            }
        }
        wait 0.05;
    }
}

WatchPlayerStat(challenge, stat_1, goal_solo, goal_coop, stat_sum, sum_range_down, sum_range_up)
// Function watches for a single provided stat (guns from box)
// goal_solo - if counting stats separately, defines goal for stat on solo. If global, adds to sum_range_up; goal_coop - if counting stats separately, defines goal for stat on coop. If global, adds to sum_range_up; stat_sum = Set to 0 for global counting, set undefined for separate counting. sum_range_down - Set to 0, if you want stat-in-progress to be set higher than 1 increase, set higer. sum_range_up - Goal in global counting mode.
{
    level endon("end_game");
    level endon("start_of_round");

    // Hardcode values for rounds
    if (challenge == 28)
    {
        level.zombie_vars["zombie_powerup_drop_max_per_round"] = 1024;
    }

    current_round = level.round_number;
    beginning_stat_sum = 0;

    // Grab stats to player variables on round start and sum stats
    foreach (player in level.players)
    {
        player.temp_beginning_stat = player.pers[stat_1];
        player.did_hit_box = 0;
        beginning_stat_sum += player.temp_beginning_stat;
    }

    // Pass range for summarized stats to separate vars
    if (isdefined(stat_sum))
    {
        l_sum_range_down = sum_range_down;
        l_sum_range_up = sum_range_up;
        l_stat_sum = stat_sum;
        l_beg_sum = beginning_stat_sum;
        // Add coop multiplication to upper range for coop
        if (level.players.size > 1)
        {
            l_sum_range_up += goal_coop;
        }
        else
        {
            l_sum_range_up += goal_solo;
        }
        level.hud_quota = l_sum_range_up;
    }
    else
    {
        pers_quota = goal_coop;
        level.hud_quota = (goal_coop * level.players.size);

        if (level.players.size == 1)
        {
            level.hud_quota = goal_solo;
            pers_quota = goal_solo;
        }
        else
        {
            id = 0;
            foreach (player in level.players)
            {
                player thread PersonalProgressHud(pers_quota, id);
                id++;
            }    
        }
    }

    // Watch stats midround
    proper_boxers = 0;
    piles_in_progress = false;
    temp_melees = 0;
    while (level.round_number == current_round)
    {
        global_current = 0;
        proper_boxers = 0;
        temp_melees = 0;
        if (isdefined(stat_sum))
        {
            l_stat_sum = 0;
        }

        // Pull stat from each player to player var during the round
        foreach (player in level.players)
        {
            player.temp_current_stat = player.pers[stat_1];
        }

        // Define if condition is met
        i = 0;
        foreach (player in level.players)
        {
            temp_stat = player.temp_current_stat;
            beg_stat = player.temp_beginning_stat;
            player.personal_var = 0;
            if (temp_stat > beg_stat)
            {
                // Sum the stats if need be
                if (isdefined(l_stat_sum))
                {
                    l_stat_sum += temp_stat;
                }
                // Else analyze difference for each player separately
                else
                {
                    // Don't switch the variable for no reason
                    if (player.did_hit_box != 1)
                    {
                        player.did_hit_box = 2;
                        piles_in_progress = true;
                    }

                    // If met requirements for solo
                    if (temp_stat >= (beg_stat + goal_solo) && level.players.size == 1)
                    {
                        player.did_hit_box = 1;
                        proper_boxers++;
                        player.personal_var = temp_stat;
                    }

                    // If met requirements for coop
                    else if (temp_stat >= (beg_stat + goal_coop) && level.players.size > 1)
                    {
                        player.did_hit_box = 1;
                        proper_boxers++;
                        player.personal_var = temp_stat;
                    }

                    global_current += temp_stat;
                }
            }

            if (isdefined(level.debug_weapons) && level.debug_weapons)
            { 
                print("temp_stat: " + player.name + ": " + temp_stat);
            }
        }

        if (isdefined(level.debug_weapons) && level.debug_weapons)
        { 
            // iPrintLn("l_stat_sum: " + l_stat_sum);
            // iPrintLn("l_beg_sum: " + l_beg_sum);
            // iPrintLn("l_sum_range_up: " + l_sum_range_up);
        }

        // Handle summarized stats outside of foreach loops as it's global
        if (isDefined(l_stat_sum))
        {    
            l_stat_res = (l_stat_sum - l_beg_sum);

            if (l_stat_sum > 0)
            {
                // If requirements in progress
                if (l_stat_sum > l_sum_range_down && l_stat_sum < l_sum_range_up)
                {
                    piles_in_progress = true;
                }
            
                // If requirements met
                else if (l_stat_res >= l_sum_range_up)
                {
                    proper_boxers = level.players.size;
                }
            }
        }

        level.hud_current = global_current;
        if (isdefined(l_stat_res))
        {
            level.hud_current = l_stat_res;
        }

        if (isdefined(level.hud_current) && level.hud_current < 0)
        {
            level.hud_current = 0;
        }

        // Define flow of meeting requirements
        if (challenge == 28)
        {
            ConditionsInProgress(true); 
            if (proper_boxers > 0)
            {
                level.forbidden_weapon_used = true;
                break;
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
    wait 0.1;
    if (challenge == 28 && proper_boxers == 0)
    {
        level.zombie_vars["zombie_powerup_drop_max_per_round"] = 4;
        ConditionsMet(true);
    }
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
            level notify ("env_kill");
            flag_set("env_kill");
            kill_difference = stat_difference;
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

    if (challenge == 3)
    {
        text = "CAN'T MOVE";
    }
    else if (challenge == 10)
    {
        text = "CAN'T JUMP";
    }

    self thread WatchDownedPlayers();

    current_round = level.round_number;
  
    while (!level.allplayersup && (current_round == level.round_number))
    {
        foreach (player in level.players)
        {
            if (challenge == 3)
            {
                player setmovespeedscale(0);
                player allowjump(0);
            }
            else if (challenge == 10)
            {
                player allowjump(0);
            }
        }
        wait 0.05;
    }
    
    if (current_round == level.round_number)
    {
        level waittill ("end_of_round");
    }
    
    ConditionsMet(true);
    foreach (player in level.players)
    {
        player setmovespeedscale(1);
        player allowjump(1);
    }
}

WatchDownedPlayers()
{
    level.allplayersup = false;
    while (!level.allplayersup)
    {
        i = 1;
        foreach (player in level.players)
        {
            if (!player player_is_in_laststand())
            {
                i++;
            }
        }

        if (i == level.players.size)
        {
            level.allplayersup = true;
        }
        i = 1;
        wait 0.05;
    }
}

WatchPerks(challenge, number_of_perks)
// Function checks for the amount of perks per player at the end of the round.
{
    level endon("end_game");
    level endon("start_of_round");

    if (!isdefined(number_of_perks))
    {
        number_of_perks = 1;
    }
    // Pluto compatibility
    else if (number_of_perks > 4 && level.players.size > 4)
    {
        number_of_perks = 4;
    }

    level.proper_players = 0;
    if (isdefined(level.debug_weapons) && level.debug_weapons)
    {
        // iPrintLn("global_perks: " + global_perks);
        // print("hud_current: " + level.hud_current);
    }    
    level.hud_quota = (number_of_perks * level.players.size);  

    id = 0;
    foreach (player in level.players)
    {
        if (level.players.size > 1)
        {
            player thread PersonalProgressHud(number_of_perks, id);
            id++;
        }
    }

    if (challenge == 8)
    {
        self thread PerkTracker(challenge);
        self thread WatchPerkMidRound("jug");
    }
    else
    {
        self thread PerkTracker(challenge);
        self thread WatchPerkMidRound("all");
    }    

    level waittill ("end_of_round");
    if (challenge != 8 && level.proper_players == level.players.size)
    {
        ConditionsMet(true);
    }
    else if (challenge == 8 && level.players_jug >= level.players.size)
    {
        ConditionsMet(true);
    }
}

PerkTracker(challenge)
// Function checks which and how many perks players have
{
    current_round = level.round_number;
    foreach (player in level.players)
    {
        player.owned_perks = 0;
    }

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
    
        global_perks = 0;
        foreach (player in level.players)
        {
            temp_owned_perks = 0;

            if (player hasperk("specialty_armorvest"))
            {
                hasjug++;
                temp_owned_perks++;
                // Hardcoded for personal hud
                if (current_round == 8)
                {
                    player.personal_var = 1;
                }
            }
            else
            {
                if (current_round == 8)
                {
                    player.personal_var = 0;
                }
            }

            if (player hasperk("specialty_quickrevive"))
            {
                hasquick++;
                temp_owned_perks++;
            }

            if (player hasperk("specialty_rof"))
            {
                hasdoubletap++;
                temp_owned_perks++;
            }
            
            if (player hasperk("specialty_fastreload"))
            {
                hasspeed++;
                temp_owned_perks++;
            }
            
            if (player hasperk("specialty_flakjacket"))
            {
                hasphd++;
                temp_owned_perks++;
            }  
           
            if (player hasperk("specialty_deadshot"))
            {
                hasdeadshot++;
                temp_owned_perks++;
            }
            
            if (player hasperk("specialty_longersprint"))
            {
                hasstam++;
                temp_owned_perks++;
            }   

            if (player hasperk("specialty_grenadepulldeath"))
            {
                hascherry++;
                temp_owned_perks++;
            }


            if (player hasperk("specialty_additionalprimaryweapon"))
            {
                hasmule++;
                temp_owned_perks++;
            }

            // Sum the amount of perks player has on him rn
            if (player.owned_perks != temp_owned_perks)
            {
                player.owned_perks = temp_owned_perks;
            }   

            if (challenge != 8)
            {
                player.personal_var = temp_owned_perks;
                global_perks += temp_owned_perks;
            }
        } 

        if (challenge == 8)
        {
            level.hud_current = hasjug;
        }
        else
        {
            level.hud_current = global_perks;
        }

        level.players_jug = hasjug;
        level.players_quick = hasquick;
        level.players_doubletap = hasdoubletap;
        level.players_speed = hasspeed;
        level.players_phd = hasphd;
        level.players_deadshot = hasdeadshot;
        level.players_stam = hasstam;
        level.players_cherry = hascherry;
        level.players_mulekick = hasmule;  
        wait 0.05;
    }
}

WatchPerkMidRound(perk)
// Function checks if players have more than 0 of specified perk and changes condition to in progress
{
    current_round = level.round_number;
    players_inprogress = 0;
    while (current_round == level.round_number)
    {
        // If function should look for all perks
        if (perk == "all")
        {
            temp_players_inprogress = 0;
            
            foreach(player in level.players)
            {
                if (player.owned_perks > 0)
                {
                    temp_players_inprogress++;
                }
            }

            // Update only if perk state changes
            if (players_inprogress != temp_players_inprogress)
            {
                players_inprogress = temp_players_inprogress;
                level.proper_players = players_inprogress;

                if (players_inprogress >= 1)
                {
                    ConditionsInProgress(true);
                }
                else
                {
                    ConditionsInProgress(false);
                }
            }
        }

        else if (perk == "jug")
        {
            ConditionsInProgress(false);
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
// Function verifies if kills are only done with specified weapon(s)
{
    level endon("end_game");
    level endon("start_of_round");

    if (challenge != 26)
    {
        ConditionsInProgress(true);
    }
    current_round = level.round_number;

    wait 2;             // Prevent instant game overs
    gun_mods_array = array("MOD_RIFLE_BULLET", "MOD_PISTOL_BULLET", "MOD_PROJECTILE_SPLASH", "MOD_PROJECTILE", "MOD_MELEE");
    robot_array = array("actor_zm_tomb_giant_robot_0", "actor_zm_tomb_giant_robot_1", "actor_zm_tomb_giant_robot_2");
    lethal_array = array("claymore_zm", "frag_grenade_zm", "sticky_grenade_zm", "cymbal_monkey_zm", "beacon_zm");
    tank_array = array("zombie_markiv_cannon", "zombie_markiv_side_cannon", "zombie_markiv_turret");
    melee_array = array("knife_zm", "one_inch_punch_air_zm", "one_inch_punch_fire_zm", "one_inch_punch_ice_zm", "one_inch_punch_lightning_zm", "one_inch_punch_upgraded_zm", "one_inch_punch_zm", "staff_air_melee_zm", "staff_fire_melee_zm", "staff_lightning_melee_zm", "staff_water_melee_zm");

    mp40_array = array("mp40_zm", "mp40_stalker_zm", "mp40_upgraded_zm", "mp40_stalker_upgraded_zm");
    first_room_array = array("c96_zm", "c96_upgraded_zm", "ballista_zm", "ballista_upgraded_zm", "m14_zm", "m14_upgraded_zm", "galil_zm", "galil_upgraded_zm+reflex", "mp44_zm", "mp44_upgraded_zm", "scar_zm", "scar_upgraded_zm+reflex");
    // m14_array = array("m14_zm", "m14_upgraded_zm");
    // mp44_unpap_array = array("mp44_zm");

    while (current_round == level.round_number)
    {
        level waittill_any ("zombie_killed", "end_of_round", "nuke_taken");

        proper_gun_used = false;
        
        killed_lethals = false;         // Nades, semtex, clays, monkeys, beacons
        killed_insta = false;           // Insta
        killed_robots = false;          // Robots
        killed_tank = false;            // Tank
        killed_worldspawn = false;      // Bleeds, gens & nukes
        killed_drone = false;           // Maxis drone
        killed_stick = false;           // Staff revive stick
        killed_shield = false;          // Shield
        killed_melee = false;           // Melee weapons
        killed_nuke = false;            // Nukes
        killed_panzer = false;          // Panzers

        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            // iPrintLn("weapon_used_beg: " + level.weapon_used);
        }

        // DEFINE MURDER WEAPON

        // Tank rollover
        if (isinarray(tank_array, level.weapon_used) && level.weapon_mod == "MOD_CRUSH")
        {
            killed_tank = true;
        }
        // Maxis drone
        else if (level.weapon_used == "quadrotorturret_zm" || level.weapon_used == "quadrotorturret_upgraded_zm")
        {
            killed_drone = true;
        }
        // Staff stick
        else if (level.weapon_used == "staff_revive_zm")
        {
            killed_stick = true;
        }
        // Shield
        else if (level.weapon_used == "tomb_shield_zm")
        {
            killed_shield = true;
        }
        // Melee
        else if (level.weapon_mod == "MOD_MELEE" && isinarray(melee_array, level.weapon_used))
        {
            killed_melee = true;
        }
        // Panzer
        else if (level.killer_class == "actor_zm_tomb_basic_german2")
        {
            killed_panzer = true;
        }
        // Nukes
        else if (flag("nuke_taken"))
        {
            flag_clear("nuke_taken");
            killed_nuke = true;
        }
        // None weapon exceptions
        else if (level.weapon_used == "none")
        {
            // Nades, semtex, clays, monkeys, beacons (headless)
            if (level.weapon_mod == "MOD_GRENADE_SPLASH")
            {
                killed_lethals = true;
            }
            // Robots
            else if (isinarray(robot_array, level.killer_class))
            {
                killed_robots = true;
            }
            // Tank flamethrower
            else if (level.killer_class == "script_vehicle" && level.weapon_mod == "MOD_BURNED")
            {
                killed_tank = true;
            }
            // Bleeds, gens & nukes
            else if (level.killer_class == "worldspawn" && level.weapon_mod == "MOD_UNKNOWN")
            {
                killed_worldspawn = true;
            }
            // Melee
            else if (level.weapon_mod == "MOD_MELEE")
            {
                killed_melee = true;
            }

            // Instakill (if not killshot)
            if (isinarray(gun_mods_array, level.weapon_mod))
            {
                killed_insta = true;
            }
        }

        // COMPARE MEANS OF DEATH AGAINST CHALLENGES
        if (challenge == 2 || challenge == 9 || challenge == 19 || challenge == 24 || challenge == 26)
        {
            // CASE = MELEE
            if (challenge == 2)
            {
                if ((killed_insta && killed_melee) || killed_melee)
                {
                    proper_gun_used = true;
                }
            }
            // CASE = TANK
            else if (challenge == 26)
            {
                if (killed_tank)
                {
                    level.killed_with_tank++;
                }
            }
            // CASE = WEAPONS
            else
            {
                // Define weapon list for a challenge
                if (challenge == 9 || challenge == 19)
                {
                    allowed_weapons = array_copy(mp40_array);
                }
                else if (challenge == 24)
                {
                    allowed_weapons = array_copy(first_room_array);
                }
                else            // Failsafe, should never trigger
                {
                    iPrintLn("FATAL ERROR");
                    break;
                }

                // Define if proper gun was used
                if (isdefined(allowed_weapons) && isdefined(level.weapon_used) && isinarray(allowed_weapons, level.weapon_used))
                {
                    proper_gun_used = true;
                }
                // Watch for instakill
                else if (!killed_lethals && !killed_robots && !killed_tank && !killed_drone && !killed_stick && !killed_shield && !killed_melee && !killed_nuke && killed_insta)
                {
                    pass_insta = true;
                    foreach (player in level.players)
                    {
                        if (player.clientid == level.killer_name)
                        {
                            held_weapon = player getCurrentWeapon();
                            if (!isinarray(allowed_weapons, held_weapon))
                            {
                                pass_insta = false;
                            }
                        }
                    }

                    if (!isdefined(held_weapon))
                    {
                        held_weapon = "undefined";
                    }

                    if (pass_insta)
                    {
                        proper_gun_used = true;
                    }
                }
                // Watch for nukes
                else if (killed_nuke)
                {
                    proper_gun_used = true;
                }
                // Watch for env kills
                else if (killed_robots || killed_tank || killed_panzer)
                {
                    proper_gun_used = true;
                }
                // Watch for despawns
                else if (killed_worldspawn && !killed_insta)
                {
                    proper_gun_used = true;
                }
            }
        }

        // DEBUG PRINTS
        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            print("proper_gun_used: " + proper_gun_used);
            print("killed_lethals: " + killed_lethals);
            print("killed_insta: " + killed_insta);
            print("killed_robots: " + killed_robots);
            print("killed_tank: " + killed_tank);
            print("killed_worldspawn: " + killed_worldspawn);
            print("killed_drone: " + killed_drone);
            print("killed_stick: " + killed_stick);
            print("killed_shield: " + killed_shield);
            print("killed_melee: " + killed_melee);
            print("killed_nuke: " + killed_nuke);
            print("killed_panzer: " + killed_panzer);

            if (killed_insta)
            {
                iPrintLn("Kill: Instakill (" + held_weapon + ")");
            } 
            
            if (killed_nuke)
            {
                iPrintLn("Kill: Nuke");
            }
            else if (killed_lethals)
            {
                iPrintLn("Kill: Lethal equipment");
            }
            else if (killed_robots)
            {
                iPrintLn("Kill: Robot");
            }
            else if (killed_tank)
            {
                iPrintLn("Kill: Tank");
            }
            else if (killed_worldspawn)
            {
                iPrintLn("Kill: Worldspawn");
            }
            else if (killed_drone)
            {
                iPrintLn("Kill: Drone");
            }
            else if (killed_stick)
            {
                iPrintLn("Kill: Revive stick");
            }
            else if (killed_shield)
            {
                iPrintLn("Kill: Shield");
            }
            else if (proper_gun_used && !killed_insta)
            {
                iPrintLn("^2Kill: " + level.weapon_used);
            }
            else if (!isdefined(level.weapon_used) || !isdefined(level.killer_class) || !isdefined(level.weapon_mod))
            {
                iPrintLn("^3Arguments undefined");
                print("Killer class: " + level.killer_class);
                print("Killer name: " + level.killer_name);
                print("Kill mod: " + level.weapon_mod);
                print("Kill weapon: " + level.weapon_used);
            }
            else
            {
                iPrintLn("^1Kill: " + level.weapon_used);
                print("Killer_class: " + level.killer_class);
                print("Killer name: " + level.killer_name);
                print("Kill mod: " + level.weapon_mod);
                print("Kill weapon: " + level.weapon_used);
            }
        }

        // END GAME IF CONDITION NOT MET
        if ((!proper_gun_used && (current_round == level.round_number)) && (challenge != 26))
        {
            level.forbidden_weapon_used = true;
        }

        wait 0.05;
    }
    wait 0.1;
    if (challenge != 26)
    {
        ConditionsMet(true);
    }
}

DropWatcher()
// Count drops to level variables and send notify each time drop is taken
{
    level.current_drops_nuke = 0;
    level.current_drops_insta = 0;
    level.current_drops_max = 0;
    level.current_drops_double = 0;
    level.current_drops_blood = 0; 
    level.current_drops_point = 0;
    level.current_drops_sale = 0;

    level.current_solo_points = 0;
    level.current_team_points = 0;
    
    x = 0;
    while (1)
    {
        nukes_temp = 0;
        instas_temp = 0;
        maxes_temp = 0;
        double_temp = 0;
        blood_temp = 0;
        points_temp = 0;
        sales_temp = 0;

        team_points_temp = 0;
        solo_points_temp = 0;

        foreach(player in level.players)
        {
            nukes_temp += player.pers["nuke_pickedup"];
            instas_temp += player.pers["insta_kill_pickedup"];
            maxes_temp += player.pers["full_ammo_pickedup"];
            double_temp += player.pers["double_points_pickedup"];
            blood_temp += player.pers["zombie_blood_pickedup"];
            sales_temp += player.pers["fire_sale_pickedup"];
            // Bonus points cannot be tracked without replacefunc
        }

        if (nukes_temp > level.current_drops_nuke)
        {
            level.current_drops_nuke = nukes_temp;
            level notify("nuke_taken");
            flag_set("nuke_taken");
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("Nuke taken");
            }
            
        }
        else if (instas_temp > level.current_drops_insta)
        {
            level.current_drops_insta = instas_temp;
            level notify("insta_taken");
            flag_set("insta_taken");
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("Insta taken");
            }        
        }
        else if (maxes_temp > level.current_drops_max)
        {
            level.current_drops_max = maxes_temp;
            level notify ("max_taken");
            flag_set("max_taken");
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("Max taken");
            }        
        }
        else if (double_temp > level.current_drops_double)
        {
            level.current_drops_double = double_temp;
            level notify ("double_taken");
            flag_set("double_taken");
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("X2 taken");
            }        
        }
        else if (blood_temp > level.current_drops_blood)
        {
            level.current_drops_blood = blood_temp;
            level notify ("blood_taken");
            flag_set("blood_taken");
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("Blood taken");
            }        
        }
        else if (sales_temp > level.current_drops_sale)
        {
            level.current_drops_sale = sales_temp;
            level notify ("sale_taken");
            flag_set("sale_taken");
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("Firesale taken");
            }       
        }

        // Clear flags on readpoint
        wait 0.05;
    }
}

actor_killed_override( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime )
// Override used to pass weapon used to kill zombies to level variable alongside level notify
{
    level.weapon_used = sweapon;
    level.weapon_mod = smeansofdeath;
    level.killer_class = attacker.classname;
    level.killer_name = attacker.name;
    level.killer_id = attacker.clientid;
    level notify ("zombie_killed");
    if (isdefined(level.debug_weapons) && level.debug_weapons)
    {    
        // print("einflictor: " + einflictor);
        // print("attacker: " + attacker.classname);   
        // print("attacker_name: " + attacker.name); 
        // print("idamage: " + idamage);
        // print("smeansofdeath: " + smeansofdeath);
        // print("sweapon: " + sweapon);
        // print("vdir: " + vdir);
        // print("shitloc: " + shitloc);
        // print("psoffsettime: " + psoffsettime);
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

WatchUpgradedStaffs(challenge, number_of_staffs)
// Function tracks progress with staff upgrade
{
    level endon("end_game");
    level endon("start_of_round");

    current_round = level.round_number;
    upgraded_staffs = 0;
    upgraded_wind = false;
    upgraded_fire = false;
    upgraded_lighting = false;
    upgraded_ice = false;
    if (!isdefined(number_of_staffs))
    {
        number_of_staffs = 4;
    }

    while ((current_round == level.round_number) && (upgraded_staffs < number_of_staffs))
    {
        foreach (staff in level.a_elemental_staffs_upgraded)
        {
            if (staff.charger.is_charged == 1 && staff.weapname == "staff_air_upgraded_zm" && !upgraded_wind)
            {
                upgraded_wind = true;
                upgraded_staffs++;
            }

            else if (staff.charger.is_charged == 1 && staff.weapname == "staff_fire_upgraded_zm" && !upgraded_fire)
            {
                upgraded_fire = true;
                upgraded_staffs++;
            }

            else if (staff.charger.is_charged == 1 && staff.weapname == "staff_lightning_upgraded_zm" && !upgraded_lighting)
            {
                upgraded_lighting = true;
                upgraded_staffs++;
            }

            else if (staff.charger.is_charged == 1 && staff.weapname == "staff_water_upgraded_zm" && !upgraded_ice)
            {
                upgraded_ice = true;
                upgraded_staffs++;
            }

            if (staff.charger.charges_received > 0 && upgraded_staffs == 0)
            {
                ConditionsInProgress(true);
            }
        }

        if (upgraded_staffs > 0)
        {
            ConditionsInProgress(true);

            if (upgraded_staffs >= number_of_staffs)
            {
                ConditionsMet(true);
            }
        }
        wait 0.05;
    }
}

ZombieSuperSprint(challenge, amount_of_supersprinters)
// Function sets most of the zombies in the round as super-sprinters
{
    level endon("end_game");
    level endon("start_of_round");

    if (!isdefined(amount_of_supersprinters))
    {
        amount_of_supersprinters = 20;
    }

    current_round = level.round_number;
    ConditionsInProgress(true);

    super_sprinters = 0;
    sprinters = 0;
    force_runners = 0;
    dv = 0;                 // Only for dev prints
    while (current_round == level.round_number)
    {
        super_sprinters = 0;
        sprinters = 0;

        // Count super sprinters on the map
        foreach (zombie in get_round_enemy_array())
        {
            if (isdefined(zombie.is_super_sprinter))
            {
                if (zombie.is_super_sprinter)
                {
                    super_sprinters++;
                }
                else
                {
                    sprinters++;
                }
                
            }
        }
        
        foreach (zombie in get_round_enemy_array())
        {
            // Slow super sprinters down if there is too many
            if ((force_runners > 0) && isdefined(zombie.has_legs) && zombie.has_legs && isDefined(zombie.completed_emerging_into_playable_area) && zombie.completed_emerging_into_playable_area)
            {
                if (isdefined(level.debug_weapons) && level.debug_weapons)
                {
                    iPrintLn("slowing down a zombie");
                }
                
                if (isdefined(zombie.is_super_sprinter) && zombie.is_super_sprinter)
                {
                    super_sprinters--;
                }
                zombie.is_super_sprinter = false;
                zombie set_zombie_run_cycle("run");
                force_runners--;
            }

            // Handle new zombies
            if (isdefined(zombie.has_legs) && zombie.has_legs && isDefined(zombie.completed_emerging_into_playable_area) && zombie.completed_emerging_into_playable_area && !isdefined(zombie.is_super_sprinter))
            {
                if (super_sprinters >= amount_of_supersprinters || randomint(100) > 95)
                {
                    zombie.is_super_sprinter = false;
                    sprinters++;
                    zombie set_zombie_run_cycle("run");
                }
                else
                {
                    zombie.is_super_sprinter = true;
                    super_sprinters++;
                    zombie set_zombie_run_cycle("super_sprint");
                }
            }
        }
        // Queue zombies to slow down
        if (super_sprinters > amount_of_supersprinters)
        {
            force_runners = super_sprinters - amount_of_supersprinters;
            if (force_runners < 0)
            {
                force_runners = 0;
            }
        }

        // Dev prints
        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            dv++;
            if (dv >= 60)
            {
                iPrintLn("super_sprinters: " + super_sprinters);
                iPrintLn("sprinters: " + sprinters);
                iPrintLn("force_runners: " + force_runners);
                dv = 0;
            }
        }
  
        wait 0.05;
    }
    wait 0.1;
    ConditionsMet(true);
}

TooManyPanzers(challenge, is_supporting)
// Function spawns panzers during the whole duration of the round
{
    level endon("end_game");
    level endon("start_of_round");

    if (!isdefined(is_supporting))
    {
        is_supporting = false;
    }

    level.mech_zombies_alive = 0;
    current_round = level.round_number;
    level.wanted_mechz = 1;

    self thread PanzerDeathWatcher(is_supporting);
    self thread SpawnPanzer(current_round);
    if (!is_supporting)
    {
        self thread ScanCrazyPlace();
        level.wanted_mechz = 7;
        ConditionsInProgress(true);
    }
    
    level waittill("end_of_round");
    wait 0.1;
    ConditionsMet(true);
}

SpawnPanzer(current_round)
{
    while (current_round == level.round_number)
    {
        if (level.mech_zombies_alive < level.wanted_mechz)
        {
            ai = spawn_zombie(level.mechz_spawners[0]);
            ai thread mechz_spawn();
            level.mech_zombies_alive++;
            wait randomintrange(4, 8);
        }
        wait 0.05;
    }
}

PanzerDeathWatcher(is_supporting)
// Function watches for dying panzers and keeps the counter on proper number
{
    if (!isdefined(is_supporting))
    {
        is_supporting = false;
    }

    while (1)
    {
        level waittill ("mechz_killed");
        level.wanted_mechz = randomintrange(6, 11);
        if (is_supporting)
        {
            level.wanted_mechz = 1;
        }
        level.mech_zombies_alive--;
        wait 0.05;
    }
}

SetDvarForRound(challenge, dvar, start_value, end_value)
// Function sets a dvar to one value and changes it to another at the end of round
{
    level endon("end_game");
    level endon("start_of_round");

    if (!isdefined(start_value))
    {
        start_value = 0;
    }
    if (!isdefined(end_value))
    {
        end_value = 1;
    }

    ConditionsInProgress(true);
    setdvar(dvar, start_value);
    level waittill ("end_of_round");
    setdvar(dvar, end_value);
    ConditionsMet(true);
}

CheckForZone(challenge, zonearray, time)
// Function handles players getting to the zone in time and staying there
{
    level endon("end_game");
    level endon("start_of_round");

    if (challenge == 20)
    {
        temp_text = "CHURCH";
    }
    else if (challenge == 30)
    {
        temp_text = "STAFF CHAMBER";
    }

    // Optional arguments handling
    if (!isdefined(time))
    {
        time = 45;
    }

    self thread BleedoutWatcher();
    id = 0;
    foreach(player in level.players)
    {
        player thread ZoneHudPersonal(time, id);
        id++;
    }

    current_round = level.round_number;

    // Define player variables
    foreach (player in level.players)
    {
        player.threaded_already = false;
    }

    // Control if players get to the zone
    tick = time * 2;
    while (tick > 0)
    {
        valid_players = level.players.size;
        in_zone = 0;
        foreach (player in level.players)
        {
            player.right_zone = false;
            current_zone = player get_current_zone();
            // Count up players in the right zone
            if (isinarray(zonearray, current_zone))
            {
                player.right_zone = true;
                in_zone++;
            } 

            if (player player_is_in_laststand())
            {
                valid_players--;
            }
        }

        // Start the challenge if all players are in zone early
        if (in_zone >= valid_players)
        {
            if (isdefined(level.debug_weapons) && level.debug_weapons)
            {
                iPrintLn("break_early");
            }
            flag_set("break_early");
            ConditionsInProgress(true);
            break;
        }

        tick--;
        wait 0.5;
    }

    // Kill players outside of zone
    if (!level.conditions_in_progress)
    {
        foreach(player in level.players)
        {
            if (!player.right_zone)
            {
                player dodamage(player.maxhealth * 2, player.origin);
            }
        }
        ConditionsInProgress(true);
    }

    flag_set("break_early");
    // level notify ("zone_init");
    
    // Watch if players remain in zone
    while (current_round == level.round_number)
    {
        in_zone = 0;
        players_down = 0;
        id = 0;
        foreach (player in level.players)
        {
            current_zone = player get_current_zone();
            // Count up players in the right zone
            if (isinarray(zonearray, current_zone))
            {
                player.right_zone = true;
                in_zone++;
            }  
            else
            {
                player.right_zone = false;            
            }

            // Count up downed players
            if (player player_is_in_laststand())
            {
                players_down++;
            }

            // Kill player outside of zone
            if (!player.right_zone && !player.threaded_already && !player player_is_in_laststand())
            {
                player thread PlayerInZone(id);
                player.threaded_already = true;
            }
            id++;
        }

        // Hud formating
        active_players = (level.players.size - (level.bleeders + players_down));
        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            print("active_players: " + active_players);
            print("bleeders: " + level.bleeders);
            print("players_down: " + players_down);
        }

        if (in_zone >= active_players)
        {
            ConditionsInProgress(true);
        }
        else
        {
            ConditionsInProgress(false);
        }

        wait 0.05;
    }
    wait 0.1;
    // For hud formatting
    foreach (player in level.players)
    {
        player.right_zone = true;
    }
    ConditionsMet(true);
}

PlayerInZone(player_id)
// Function damage and kill players outside of zone
{
    i = 0;
    while (1)
    {
        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            self iPrintLn("tick");
        }

        if (level.players[player_id].right_zone || i >= 10)
        {
            break;
        }

        i++;
        wait 0.5;
    }
    if (!level.players[player_id].right_zone)
    {
        self dodamage(level.players[player_id].maxhealth * 2, level.players[player_id].origin);
    }

    level.players[player_id].threaded_already = false;
}

BleedoutWatcher()
//dsc
{
    level.bleeders = 0;
    while (1)
    {
        level waittill ("bleed_out", character_index);
        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            // iPrintLn("character_index" + character_index);
        }
        level.bleeders++;
        wait 0.05;
    }
}

ScanCrazyPlace(time)
// Function serves as a safety for panzer rounds, player will be punished for staying in crazy place
{
    level endon("end_game");
    level endon("end_of_round");

    crazy_place_array = array("zone_chamber_0", "zone_chamber_1", "zone_chamber_2", "zone_chamber_3", "zone_chamber_4", "zone_chamber_5", "zone_chamber_6", "zone_chamber_7", "zone_chamber_8");
    if (!isdefined(time))
    {
        time = 30;
    }

    ticks = (time * (level.players.size * 0.75));
    while (1)
    {
        foreach (player in level.players)
        {
            if (!isdefined(player.imm))
            {
                player.imm = 0;
            }

            current_zone = player get_current_zone();
            if (isinarray(crazy_place_array, current_zone) && !player player_is_in_laststand())
            {
                if (ticks > 0 || player.imm > 0)
                {
                    if (isdefined(level.debug_weapons) && level.debug_weapons)
                    {
                        iPrintLn("Ticks: " + ticks);
                        player iPrintLn("Imm: " + player.imm);
                        print(player.name + " downed: " + player player_is_in_laststand());
                    }

                    ticks -= 1;     // -- doesn't work?
                    player.imm -= 1;
                    player iPrintLn("Leave immediately");
                    player dodamage(player.maxhealth / 30, player.origin);
                }
                else
                {
                    player dodamage(player.maxhealth, player.origin);
                    player iPrintLn("You've been warned");
                    player.imm = 10;
                }

                if (player.imm < 0)
                {
                    player.imm = 0;
                }
            }
        }
        if (ticks < 0)
        {
            ticks = 0;
        }
        wait 1;
    }
}

BuyNothing(challenge)
// Function sets up watching for spending points
{
    level endon("end_game");
    level endon("start_of_round");
    self endon("disconnect");

    ConditionsInProgress(true);

    init_score = 0;
    init_downs = 0;
    init_deaths = 0;

    // Prevent instant game overs
    wait 2;
    foreach (player in level.players)
    {
        init_score += player.score;
        init_downs += player.downs;
        init_deaths += player.pers["deaths"];
    }

    self thread WatchPointsLoss(init_score, init_downs, init_deaths);

    level waittill ("end_of_round");
    wait 0.1;
    ConditionsMet(true);
}

WatchPointsLoss(init_score, init_downs, init_deaths)
// Function controls spending points, will end game if points are spent (will not end if points are lost to downs or bleeds)
{
    prev_score = init_score;
    prev_downs = init_downs;
    prev_deaths = init_deaths;
    current_score = 0;
    current_downs = 0;
    current_deaths = 0;
    current_round = level.round_number;

    while (current_round == level.round_number)
    {
        current_score = 0;
        current_downs = 0;
        current_deaths = 0;

        // Get current points and downs
        foreach (player in level.players)
        {
            current_score += player.score;
            current_downs += player.downs;
            current_deaths += player.pers["deaths"];
        }

        // Scan for downs and bleeds
        if ((current_downs > prev_downs) || current_deaths > prev_deaths)
        {
            prev_score = current_score;
        }

        // Scan for points
        if (current_score < prev_score)
        {
            level.forbidden_weapon_used = true;
            break;
        }

        prev_score = current_score;
        prev_downs = current_downs;
        prev_deaths = current_deaths;
        wait 0.05;
    }
}

ShutDownPerk(challenge, perk, fizz_off)
// Function turns selected or all perks off for the entire round and turns them on afterwards
{
    level endon("end_game");
    self endon("disconnect");
    
    ConditionsInProgress(true);
    
    fizz_array = getentarray("random_perk_machine", "targetname");
    current_round = level.round_number;

    if (!isdefined(fizz_off))
    {
        fizz_off = true;
    }

    if (fizz_off)
    {
        i = 0;
        foreach (fizz in fizz_array)
        {
            if (fizz.is_current_ball_location == 1)
            {
                fizz.is_current_ball_location = 0;
                fizz conditional_power_indicators();
                fizz hidepart("j_ball");
                reenable_fizz_id = i;
            }
            i++;
        }
    }

    while (current_round == level.round_number)
    {
        if (perk == "all")
        {
            perk_pause_all_perks();
            perk_pause("specialty_rof");
            perk_pause("specialty_flakjacket");
            perk_pause("specialty_grenadepulldeath");
        }
        else
        {
            perk_pause(perk);
        }
        wait 0.05;
    }

    wait 0.1;

    if (fizz_off)
    {
        i = 0;
        foreach (fizz in fizz_array)
        {
            if (i == reenable_fizz_id)
            {
                fizz.is_current_ball_location = 1;
                fizz conditional_power_indicators();
                fizz showpart("j_ball");
            }
            i++;
        }
    }
    perk_unpause_all_perks();
    perk_unpause("specialty_rof");
    perk_unpause("specialty_flakjacket");
    perk_unpause("specialty_grenadepulldeath");
    ConditionsMet(true);
}

SprintWatcher(challenge, mode)
// Function deals damage to players if they don't move
{
    level endon("end_game");
    level endon("start_of_round");  // useful here :)
    self endon("disconnect");

    temp_text = "SURVIVE";
    if (challenge == 13)
    {
        temp_text = "POINTS";
    }
    else if (challenge == 23)
    {
        temp_text = "HEALTH";
    }
    
    ConditionsInProgress(true);
        
    current_round = level.round_number;

    // Define player vars
    foreach (player in level.players)
    {
        player.isnt_moving = 0;
    }

    while (current_round == level.round_number)
    {
        foreach (player in level.players)
        {
            // Observe if players move or not
            if (player.player_is_moving == 0)
            {
                player.isnt_moving++;
            }
            else if (player.player_is_moving == 1)
            {
                player.isnt_moving = 0;
            }

            // Do damage if players don't move, kill if they don't move for too long
            if (player.isnt_moving > 20 && !player player_is_in_laststand())
            {
                player.isnt_moving = 0;
                if (mode == "health")
                {
                    player dodamage(player.maxhealth, player.origin);
                }
                else if (mode == "points")
                {
                    take_away = int(player.score / 100);
                    player.score = roundtonearestfive(take_away);
                    if (isdefined(level.debug_weapons) && level.debug_weapons)
                    {
                        print("^1Take: " + take_away);
                    }
                }
            }
            else if (player.isnt_moving > 4 && !player player_is_in_laststand())
            {
                player iPrintLn("^1Move!!!");
                if (mode == "health")
                {
                    player dodamage(player.maxhealth / 25, player.origin);
                }
                else if (mode == "points")
                {
                    take_away = int(player.score / 50);
                    player.score -= roundtonearestfive(take_away);
                    if (isdefined(level.debug_weapons) && level.debug_weapons)
                    {
                        print("^1Take: " + take_away);
                    }
                }
            }
            // iPrintLn(player.health);    // For debugging

            // Reset the value if it's too small or too big
            if (player.isnt_moving < 0 || player.isnt_moving > 20)
            {
                player.isnt_moving = 0;
            }
            // print(player.isnt_moving);   // For debugging
        }
        wait 0.25;
    }
    wait 0.1;
    ConditionsMet(true);
}

GunGame(challenge)
// Function handling randomizing guns throught the round and later returnig actual weapons
{
    level endon("end_game");
    level endon("start_of_round"); 
    self endon("disconnect");
    
    ConditionsInProgress(true);
    
    current_round = level.round_number;
    chest_key = randomint(level.chests.size);

    foreach (player in level.players)
    {
        // Failsafe for robot
        if (player getCurrentWeapon() == "falling_hands_tomb_zm")
        {
            wait 4;
        }

        // Disable offhand weapons and pull weapons player has
        player disableoffhandweapons();
        weapon_array = player getweaponslistprimaries();

        // Keep info how many guns player had at the beginning
        player.stolen_weapons = weapon_array.size;
        player.last_gungame_weapon = "none";

        // Handle mulekick
        if (player.stolen_weapons == 3 && player hasperk("specialty_additionalprimaryweapon"))
        {
            player.stolen_mule_weapon = weapon_array[2];
            player.stolen_mule_ammo = player getAmmoCount(player.stolen_mule_weapon);
            player.stolen_mule_clip = player getWeaponAmmoClip(player.stolen_mule_weapon);
            player takeweapon(player.stolen_mule_weapon);
            wait 0.05;
        }

        // Handle 2nd gun
        if (player.stolen_weapons == 2)
        {
            player.stolen_weapon_2 = weapon_array[1];
            player.stolen_ammo_2 = player getAmmoCount(player.stolen_weapon_2);
            player.stolen_clip_2 = player getWeaponAmmoClip(player.stolen_weapon_2);
            player takeweapon(player.stolen_weapon_2);
            wait 0.05;
        }

        // Handle 1st gun
        player.stolen_weapon_1 = player getCurrentWeapon();
        player.stolen_ammo_1 = player getAmmoCount(player.stolen_weapon_1);
        player.stolen_clip_1 = player getWeaponAmmoClip(player.stolen_weapon_1);
        player takeweapon(player.stolen_weapon_1);
        wait 0.05;
    }

    // Disable boxes
    foreach (chest in level.chests)
    {
        chest hide_chest();
        //chest set_magic_box_zbarrier_state( "away" );
    }
    wait 0.1;

    // level.get_player_weapon_limit = 1;
    // level.additionalprimaryweapon_limit = 1;

    // Thread weapon randomizer and watchers
    self thread RandomizeGuns();
    self thread NukeExtraWeapon();
    self thread WallbuysWatcher();
    self thread FillStolenGuns();   // Works?

    level waittill ("end_of_round");

    wait 0.1;
    ConditionsMet(true);

    level.chests[chest_key] show_chest(); // Give box back in random spot
    // level.get_player_weapon_limit = 2;
    // level.additionalprimaryweapon_limit = 3;
    if (flag("just_set_weapon"))
    {
        wait 2;
    }

    foreach (player in level.players)
    {
        // Take away given weapon and enable offhand
        player takeweapon(player.last_gungame_weapon);
        player enableoffhandweapons();

        // Return 1st weapon
        if (isdefined(player.stolen_weapon_1))
        {
            player giveweapon(player.stolen_weapon_1, player get_pack_a_punch_weapon_options(player.stolen_weapon_1));
            player switchtoweapon(player.stolen_weapon_1);
            player setweaponammostock(player.stolen_weapon_1, player.stolen_ammo_1);
            player setweaponammoclip(player.stolen_weapon_1, player.stolen_clip_1);
            skip_other = false;
        }
        // Otherwise give mauser
        else
        {
            player giveweapon("c96_zm");
            skip_other = true;
        }
        wait 0.05;

        // Return 2nd wepaon
        if (!skip_other && player.stolen_weapons >= 2)
        {
            player giveweapon(player.stolen_weapon_2, player get_pack_a_punch_weapon_options(player.stolen_weapon_2));
            player setweaponammostock(player.stolen_weapon_2, player.stolen_ammo_2);
            player setweaponammoclip(player.stolen_weapon_2, player.stolen_clip_2);

            // Return 3rd weapon if player has mulekick
            if (player.stolen_weapons == 3 && isdefined(player.stolen_mule_weapon) && player hasperk("specialty_additionalprimaryweapon"))
            {
                player giveweapon(player.stolen_mule_weapon, player get_pack_a_punch_weapon_options(player.stolen_mule_weapon));
                player setweaponammostock(player.stolen_mule_weapon, player.stolen_mule_ammo);
                player setweaponammoclip(player.stolen_mule_weapon, player.stolen_mule_clip);
            }
        }
    }
}

RandomizeGuns()
// Thread for randomizing guns throught the round and giving them
{
    level endon ("end_of_round");

    // Establish data
    forbidden_weapons_array = array("staff_air_zm", "staff_fire_zm", "staff_lightning_zm", "staff_water_zm", "staff_revive_zm", "staff_air_upgraded_zm", "staff_fire_upgraded_zm", "staff_lightning_upgraded_zm", "staff_water_upgraded_zm", "staff_water_zm_cheap");
    shit_weapon_array = array("c96_zm", "ballista_zm", "beretta93r_extclip_zm", "m14_zm", "870mcs_zm");
    players = get_players();
    weapons = getarraykeys(level.zombie_weapons);
    max_key = level.zombie_weapons.size;
    while (1)
    {
        // Iterate using while loop as nested fors ain't allowed
        i = 0;
        while (i <= (players.size - 1))
        {
            w = randomInt(max_key); // Radomize weapon key

            // Compare against list of disalloed weapons
            if (isinarray(forbidden_weapons_array, weapons[w]))
            {
                w = randomInt(max_key);
                wait 0.05;
                continue;
            }

            // Compare against having weapon (weapons with attachments get bypassed for now)
            if (players[i] has_weapon_or_upgrade(weapons[w]))
            {
                w = randomInt(max_key);
                wait 0.05;
                continue;
            }

            // Verify if incoming weapon is equipment
            if (is_lethal_grenade(weapons[w]) || is_tactical_grenade(weapons[w]) || is_placeable_mine(weapons[w]) || is_melee_weapon(weapons[w]))
            {
                w = randomInt(max_key);
                wait 0.05;
                continue;
            }

            // Failsafe if weapon key is too high
            if (w > max_key)
            {
                w /= 2;
                wait 0.05;
                continue;
            }

            // Give chance of normal weapons become with attachments
            if (randomInt(100) > 10)
            {
                if (weapons[w] == "ak74u_zm")
                {
                    weapon[w] = "ak74u_extclip_zm";
                }
                else if (weapons[w] == "beretta93r_zm")
                {
                    weapon[w] = "beretta93r_extclip_zm";
                }
                else if (weapons[w] == "mp40_zm")
                {
                    weapon[w] = "mp40_stalker_zm";
                }
            }
            
            weapon = weapons[w];    // Put weapon to the variable

            // Define if weapon will be upgraded
            lucky_roll = false;
            if ((randomInt(100) > 20 && isinarray(shit_weapon_array, weapon)) || randomInt(100) > 66)
            {
                // iPrintLn(weapon + " upgraded");
                lucky_roll = true;
                temp_wpn = weapons[w];
                weapon = level.zombie_weapons[temp_wpn].upgrade_name;
            }

            // Take away previous weapon before giving new one
            if (players[i].last_gungame_weapon != "none")
            {
                players[i] takeweapon(players[i].last_gungame_weapon);
            }
            
            // Give upgraded weapon
            if (lucky_roll)
            {
                players[i] giveweapon(weapon, 0, players[i] get_pack_a_punch_weapon_options(weapon));
            }
            // Give unupgraded weapon
            else
            {
                players[i] weapon_give(weapon);
            }
            players[i] play_sound_on_ent("purchase");
            players[i] givestartammo(weapon);
	        players[i] switchtoweapon(weapon);
            players[i].last_gungame_weapon = weapon;
            flag_set("just_set_weapon");

            i++;
            wait 0.05;
        }
        wait 3;
        flag_clear("just_set_weapon");
        wait randomIntRange(10, 15);
    }
}

WallbuysWatcher()
// Watch for wallbuys, remove the gun and give points back
{
    level endon ("end_of_round");
    while (1)
    {
        level waittill ("weapon_bought", player, gun);
        return_points = get_weapon_cost(gun);
        player add_to_player_score(return_points);
        player takeweapon(gun);
        wait 0.05;
    }
}

NukeExtraWeapon()
// Remove any extra weapons from player equipment (mainly piles)
{
    level endon ("end_of_round");
    while (1)
    {
        foreach (player in level.players)
        {
            if (player.last_gungame_weapon == "none")
            {
                break;
            }

            gun_list = player getweaponslistprimaries();
            gungame_gun = player.last_gungame_weapon;

            if (gun_list.size > 1 && isdefined(gun_list[1]) && gun_list [1] != gungame_gun)
            {
                player takeweapon(gun_list[1]);
            }

            else if (gun_list [0] != gungame_gun)
            {
                player takeweapon(gun_list[0]);
            }
        }
        wait 0.05;
    }
}

FillStolenGuns()
// Function will fill player guns during gungame, relies on replacefunc
{
    level endon ("end_of_round");

    level waittill ("max_taken");
    foreach (player in level.players)
    {
        if (isdefined(player.stolen_ammo_1))
        {
            player.stolen_ammo_1 = weaponmaxammo(player.stolen_weapon_1);
        }
        if (isdefined(player.stolen_ammo_2))
        {
            player.stolen_ammo_2 = weaponmaxammo(player.stolen_weapon_2);
        }
        if (isdefined(player.stolen_mule_ammo))
        {
            player.stolen_mule_ammo = weaponmaxammo(player.stolen_mule_weapon);
        }
    }
}

IndoorsHub(challenge, allowed_zones)
{
    level endon("end_game");
    level endon("start_of_round"); 
    self endon("disconnect");

    ConditionsInProgress(true);

    if (!isdefined(allowed_zones))
    {
        // Air tunnel workbench is considered outside :(
        allowed_zones = array("zone_start", "zone_start_a", "zone_start_b", "zone_fire_stairs", "zone_bunker_5a", "zone_bunker_5b", "zone_bunker_4c", "zone_nml_celllar", "zone_bolt_stairs", "zone_nml_19", "ug_bottom_zone", "zone_air_stairs", "zone_village_1", "zone_village_2", "zone_ice_stairs", "zone_chamber_0", "zone_chamber_1", "zone_chamber_2", "zone_chamber_3", "zone_chamber_4", "zone_chamber_5", "zone_chamber_6", "zone_chamber_7", "zone_chamber_8", "zone_robot_head");
    }

    players = level.players;
    current_round = level.round_number;

    self thread BreakLoopOnRoundEnd();
    self thread EnvironmentKills();

    id = 0;
    foreach(player in level.players)
    {
        player thread CompareKillsWithZones(allowed_zones, id, current_round);
        id++;
    }

    level waittill ("end_of_round");
    wait 0.1;
    ConditionsMet(true);

}

CompareKillsWithZones(allowed_zones, player_id, current_round)
// Function takes the position of a player (or all players if it's environment kill) and compares it against a list of allowed zones
{
    while (current_round == level.round_number)
    {
        level waittill_any ("zombie_killed", "end_of_round", "env_kill");
        if (isdefined(level.breakearly) && level.breakearly)
        {
            break;
        }

        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            // self iPrintLn("tick");
        }

        player_zone = level.players[player_id] get_current_zone();
        if (flag("env_kill"))
        {
            if (!isinarray(allowed_zones, player_zone))
            {
                if (isdefined(level.debug_weapons) && level.debug_weapons)
                {
                    self iPrintLn("env_kill_outside");
                }
                level.forbidden_weapon_used = true;
                flag_clear("env_kill");
            }
        }

        else if (level.players[player_id].name == level.killer_name)
        {
            // Compare the position of killer against allowed zones
            if (!isinarray(allowed_zones, player_zone) && level.weapon_used != "none")
            {
                if (isdefined(level.debug_weapons) && level.debug_weapons)
                {
                    self iPrintLn("kill_outside");
                    self iPrintLn("current_zone: " + player_zone);
                    self iPrintLn("killer_name: " + level.killer_name);
                    self iPrintLn("name: " + level.players[player_id].name);
                }
                level.forbidden_weapon_used = true;
            }
        }
        wait 0.05;
    }
}

BreakLoopOnRoundEnd(use_flag)
// Change level variable on round end
{
    if (isdefined(use_flag) && use_flag)
    {
        level waittill ("end_of_round");
        flag_set("rnd_end");
    }
    else
    {
        level.breakearly = false;
        level waittill ("end_of_round");
        level.breakearly = true;
    }
}

TankEm(challenge)
// Function checks if enough zombies were killed by the tank
{
    level endon("end_game");
    level endon("start_of_round"); 
    self endon("disconnect");

    // Define amount of zombies to kill with tank
    tank_multiplier = 0;
    if (level.players.size > 1)
    {
        tank_multiplier = 24 * (level.players.size - 1);
    }
    zombies_to_tank = 48 + tank_multiplier;

    self thread CheckUsedWeapon(challenge);
    current_round = level.round_number;
    level.killed_with_tank = 0;
    level.hud_quota = zombies_to_tank;

    while (current_round == level.round_number)
    {
        if (level.killed_with_tank <= zombies_to_tank)
        {
            level.hud_current = level.killed_with_tank;
        }
        else
        {
            level.hud_current = zombies_to_tank;
        }

        if (level.killed_with_tank > 0 && level.killed_with_tank < zombies_to_tank && !level.conditions_in_progress)
        {
            ConditionsInProgress(true);
        }

        else if (level.killed_with_tank >= zombies_to_tank && !level.conditions_met)
        {
            ConditionsMet(true);
        }
        wait 0.05;
    }
}

AmmoController(challenge)
// Function that threads ammo controllers to each player
{
    level endon("end_game");
    level endon("start_of_round"); 
    self endon("disconnect");

    ConditionsInProgress(true);
    foreach (player in level.players)
    {
        player thread ValueAmmo();
    }

    level waittill ("end_of_round");
    wait 0.1;
    ConditionsMet(true);
}

ValueAmmo(challenge)
// Function causes player to lose twice as much ammo for shooting
{
    current_round = level.round_number;
    prev_weapon = "";
    burst_weapons = array("beretta93r_zm", "beretta93r_extclip_zm", "fnfal_upgraded_zm", "m16_zm", "raygun_mark2_zm", "raygun_mark2_upgraded_zm", "srm1216_zm", "srm1216_upgraded_zm", "staff_air_upgraded_zm", "staff_fire_upgraded_zm", "staff_lightning_upgraded_zm", "staff_water_upgraded_zm");

    while (current_round == level.round_number)
    {
        // Get currently used weapon, zero saved vars if weapon is changed
        weapon = self getCurrentWeapon();
        if (weapon != prev_weapon)
        {
            saved_clip = undefined;
            saved_stock = undefined;
        }

        // Grab current ammo count for both stock and clip
        current_stock = self getAmmoCount(weapon);
        current_clip = self getWeaponAmmoClip(weapon);
        if (!isdefined(saved_clip))
        {
            saved_clip = current_clip;
        }
        if (!isdefined(saved_stock))
        {
            saved_stock = current_stock;
        }

        // Calculate and take away ammo on shoot
        if (current_clip < saved_clip)
        {
            get_diff_clip = (saved_clip - current_clip);
            get_diff_stock = (saved_stock - current_stock);

            new_clip = (current_clip - get_diff_clip);
            new_stock = (current_stock - get_diff_stock);

            take_from_reserve = false;
            while (new_clip < 0)
            {
                take_from_reserve = true;
                new_clip++;
                new_stock--;
                wait 0.05;
            }

            self setweaponammoclip(weapon, new_clip);
            if (take_from_reserve)
            {
                self setweaponammostock(weapon, new_stock);
            }

            saved_clip = new_clip;
            saved_stock = new_stock;
        }
        // Else keep current ammo count
        else
        {
            saved_clip = self getWeaponAmmoClip(weapon);
            saved_stock = self getAmmoCount(weapon);
        }

        // Zero ammo for burst weapons on low ammo
        if (isinarray(burst_weapons, weapon))
        {
            ammo_total = current_clip + current_stock;
            burst = 3;
            if (weapon == "srm1216_upgraded_zm")
            {
                burst = 4;
            }
            else if (weapon == "staff_air_upgraded_zm" || weapon == "staff_fire_upgraded_zm" || weapon == "staff_lightning_upgraded_zm" || weapon == "staff_water_upgraded_zm")
            {
                burst = 6;
            }

            if ((ammo_total < (burst * 2)) && ammo_total != 0)
            {
                if (isdefined(level.debug_weapons) && level.debug_weapons)
                {    
                    self iPrintLn("reduce burst");
                }            
                self setweaponammoclip(weapon, 0);
                self setweaponammostock(weapon, 0);
                prev_weapon = weapon;
                saved_clip = undefined;
                saved_stock = undefined;
                wait 0.05;
                continue;
            }
        }

        prev_weapon = weapon;
        wait 0.05;
    }
}

ClearStaffs()
// Function zeroes ammo for staffs for the duration of the round
{
    staff_array = array("staff_air_upgraded_zm", "staff_fire_upgraded_zm", "staff_lightning_upgraded_zm", "staff_water_upgraded_zm");
    while (1)
    {
        foreach (player in level.players)
        {
            current_weapon = player getCurrentWeapon();
            if (isinarray(staff_array, current_weapon))
            {
                if ((player getAmmoCount(current_weapon) != 0) || (player getWeaponAmmoClip(current_weapon) != 0))
                {
                    self setweaponammoclip(weapon, 0);
                    self setweaponammostock(weapon, 0);  
                }          
            }
        }
        wait 0.05;
    }
}

GrandFinale(challenge)
// Function-hub for final challenge
{
    level endon ("end_game");

    level.second_chance = false;

    self thread CheckForZone(challenge, array("ug_bottom_zone"), 60);
    self thread ClearStaffs();
    self thread TooManyPanzers(challenge, true);

}

recapture_round_tracker_override()
// Override, make recapture round a level var to be able to manipulate it
{
	level.n_next_recapture_round = 10;
	while ( 1 )
	{
		level waittill_any( "between_round_over", "force_recapture_start" );

		if ( level.round_number >= level.n_next_recapture_round && !flag( "zone_capture_in_progress" ) && get_captured_zone_count() >= get_player_controlled_zone_count_for_recapture() )
		{
			level thread recapture_round_start();
		}
	}
}

powerup_drop_override(drop_point)
// Override, power vacuum for round 28
{
    if (isdefined(level.debug_weapons) && level.debug_weapons)
    {
        // print("powerup_drop_count: " + level.powerup_drop_count);
        // print("drop_max_per_round: " + level.zombie_vars["zombie_powerup_drop_max_per_round"]);
    }

    if ( level.powerup_drop_count >= level.zombie_vars["zombie_powerup_drop_max_per_round"] )
    {
        return;
    }

    if ( !isdefined( level.zombie_include_powerups ) || level.zombie_include_powerups.size == 0 )
    {
        if (isdefined(level.debug_weapons) && level.debug_weapons)
        {
            // iPrintLn("^3include powerups triggered");
        }
        return;
    }

    rand_drop = randomint( 100 );
    if (level.round_number == 28)
    {
        rand_drop = randomint(16);
    }

    if (isdefined(level.debug_weapons) && level.debug_weapons)
    {   
        cc = "^1";
        if (rand_drop < 3)
        {
            cc = "^2";
        }
        // iPrintLn(cc + "ran_drop: " + rand_drop);
    }

    if ( rand_drop > 2 )
    {
        if ( !level.zombie_vars["zombie_drop_item"] )
        {
            return;
        }
		debug = "score";
    }
    else
    {
		debug = "random";
    }

    playable_area = getentarray( "player_volume", "script_noteworthy" );
    level.powerup_drop_count++;
    powerup = maps\mp\zombies\_zm_net::network_safe_spawn( "powerup", 1, "script_model", drop_point + vectorscale( ( 0, 0, 1 ), 40.0 ) );
    valid_drop = 0;

    for ( i = 0; i < playable_area.size; i++ )
    {
        if ( powerup istouching( playable_area[i] ) )
        {
            valid_drop = 1;
            break;
        }
    }

    if ( valid_drop && level.rare_powerups_active )
    {
        pos = ( drop_point[0], drop_point[1], drop_point[2] + 42 );

        if ( check_for_rare_drop_override( pos ) )
        {
            level.zombie_vars["zombie_drop_item"] = 0;
            valid_drop = 0;
        }
    }

    if ( !valid_drop )
    {
        level.powerup_drop_count--;
        powerup delete();
        return;
    }

    if (isdefined(level.debug_weapons) && level.debug_weapons)                  
    {
        // iPrintLn("^5SHOULD DROP");
    }
    powerup powerup_setup();
    // print_powerup_drop( powerup.powerup_name, debug );
    powerup thread powerup_timeout();
    powerup thread powerup_wobble();
    powerup thread powerup_grab();
    powerup thread powerup_move();
    powerup thread powerup_emp();
    level.zombie_vars["zombie_drop_item"] = 0;
    level notify( "powerup_dropped" );
}

wait_network_frame_override()
// Override, fixed tickrate
{
	wait 0.1; 							
}
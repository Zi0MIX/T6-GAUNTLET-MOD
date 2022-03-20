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
}

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

WatchForMovement()
{
    self.player_is_moving = 0;
    self thread monitor_player_movement();
    wait 5;
    while (1)
    {
        if (self.player_is_moving)
        {
            level.forbidden_weapon_used = true;
        }
        wait 0.5;
    }
}

WatchForShoot(challenge)
//Function register any of the lethal events and sets conditions met to false
{
    level.conditions_met = true;

    level thread GauntletHud(2);
    self thread WatchForNade();
    
    level waittill("weapon_fired", "trap_kill", "vo_tank_flame_zombie");
    level.forbidden_weapon_used = true;

    self destroy();
}

WatchForNade()
{
    level waittill("grenade_exploded");
    level.forbidden_weapon_used = true;
}

ZombieKilledInTheRound()
//Function tracks kills during round
{
    level waittill ("start_of_round");
    zombies_in_round = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;

    while (1)
    {
        zombie_count = maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total;
        level.zombie_killed = zombies_in_round - zombie_count;
        // iprintln("Killed:" + level.zombie_killed);
        wait 0.05;
        if (zombie_count == 0)
        {
            wait 1;
            level.zombie_killed = 0;
            return;
        }
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

    level thread ZombieKilledInTheRound();
    // level thread CountProperKills();
}

Countdown(ticks, inveral)
// Function changes the level value allowing to use it as a countdown
{
    if (!isdefined(inveral) || inveral < 1)
    {
        inveral = 1;
    }

    while (ticks > 0)
    {
        level.countdown = ticks;
        ticks--;
        wait inveral;
    }
    break;
}

TranslateGeneratorNames(generator_id)
// Function translates generator numbers into in-game generator keys
{
    if (generator_id == 1)
    {
        return "generator_start_bunker";
    }
    else if (generator_id == 2)
    {
        return "generator_tank_trench";
    }
    else if (generator_id == 3)
    {
        return "generator_mid_trench";
    }
    else if (generator_id == 4)
    {
        return "generator_nml_right";
    }
    else if (generator_id == 5)
    {
        return "generator_nml_left";
    }
    else if (generator_id == 6)
    {
        return "generator_church";
    }
}

WeaponSizeWatcher()
{
    while (1)
    {
        i = 0;
        foreach (player in level.players)
        {
            if (player getweaponslistprimaries().size == 1)
            {
                i++;
            }

            if (i == level.players.size - 1)
            {
                flag_set("weapons_cleared");
            }
        }
        if (flag("weapons_cleared"))
        {
            break;
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

    print("beg_stat_array_0: " + beg_stat_array[0]);    // For debugging
    print("beg_stat_array_1: " + beg_stat_array[1]);    // For debugging

    // Watch stats midround
    rnd_stat = beg_stat;
    rnd_stat_array = array_copy(beg_stat_array);
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

        print("rnd_stat_array_0: " + rnd_stat_array[0]);    // For debugging
        print("rnd_stat_array_1: " + rnd_stat_array[1]);    // For debugging
        
        // Define if condition is met
        i = 0;
        foreach (stat in rnd_stat_array)
        {
            if (challenge == 5 || challenge == 9 || challenge == 19 || challenge == 23)
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
                // Change to 2 if stat is bigger for solo only
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
            else if (challenge == 17)
            {
                if (stat > beg_stat_array[i])
                {
                    did_hit_box[i] = 2;

                    // Change to 1 if stat is bigger by 7 or more for solo
                    if ((stat > beg_stat_array[i] + 6) && level.players.size == 1)
                    {
                        did_hit_box[i] = 1;
                    }
                    // Change to 1 if stat is bigger by 2 or more for coop
                    else if ((stat > beg_stat_array[i] + 1) && level.players.size > 1)
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
        iPrintLn("proper_boxers: " + proper_boxers);
        // Determine state of the challenge
        // Flow of the challenge 9 already defined in CheckUsedWeapon()
        if (challenge == 9 || challenge == 19 || challenge == 23 || challenge == 26)
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

// All 3 have to be emptied otherwise they somehow work lol
// player_too_many_weapons_monitor_takeaway_sequence_override()
// {
// }

// player_too_many_weapons_monitor_takeaway_simultaneous_override(primary_weapons_to_take)
// {
// }

// player_too_many_weapons_monitor_override()
// {
// }


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
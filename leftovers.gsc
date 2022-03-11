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
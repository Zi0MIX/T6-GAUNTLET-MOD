init()
{
    level notify("gauntlet_init");  // Notify for gauntlet proxy
    level thread on_game_start();
    level thread on_player_connect();
}

on_game_start()
{
    level thread gauntlet_loop();
    level thread gauntlet_round_controller();

    level thread timer_hud();
    level thread zombie_counter();
}

on_player_connect()
{
    level endon("end_game");

    level waittill("connected", player);
    player thread player_connected();
}

player_connected()
{
    
}

gauntlet_loop()
{
    if (isDefined(level.gauntlet_setup))
        level.gauntlet_config = [[level.gauntlet_setup]]();
    else
    {
        iPrintLn("gauntlet setup undefined");
        level notify("end_game");
    }

    for (rnd = level.start_round; rnd <= level.gauntlet_config["gauntlet_rounds"]; rnd++)
    {
        key = "round_" + rnd;
        if (isDefined(level.gauntlet_core[key]))
            level thread [[level.gauntlet_core[key]]]();

        level waittill("gauntlet_finished");
        evaluate_gauntlet();
    }
}

stub()
{
}

evaluate_gauntlet()
{
    if (!isDefined(level.gauntlet_success) || !level.gauntlet_success)
    {
        // Add second chance logic here
        iPrintLn("^1GAUNTLET FAILED");
        foreach(player in level.players)
            player freezeControls(true);

        level notify("end_game");
        return;
    }

    level.gauntlet_success = undefined;
}

debug_print(content)
{
    // Can isdefined built-ins?
    if (isDefined(::print))
        print("DEBUG: " + content);
}

gauntlet_round_controller()
{
    level endon("end_game");

    while (true)
    {
        level waittill("start_of_round");
        flag_set("same_round");
        level.gauntlet_success = false;

        level.round_data = array();
        level.round_data["round_number"] = level.round_number;
        level.round_data["initial_zombie_state"] = get_round_enemy_array().size + level.zombie_total;
        level.round_data["start_of_round"] = int(getTime() / 1000);

        level waittill("end_of_round");
        escape_notifier();
        flag_clear("same_round");
        level.round_data["end_of_round"] = int(getTime() / 1000);
    }
}

timer_hud()
{
    level endon("end_game");

    timer_hud = createserverfontstring("hudsmall" , 1.6);
	timer_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 0);					
	timer_hud.alpha = 1;
	timer_hud.color = level.gauntlet_config["hud_color"];
	timer_hud.hidewheninmenu = 1;

	timer_hud setTimerUp(0); 
}

zombie_counter()
{
    level endon("end_game");

    counter_hud = createserverfontstring("hudsmall" , 1.4);
    counter_hud setPoint("CENTER", "CENTER", "CENTER", 185);
	counter_hud.alpha = 1;
    counter_hud.hidewheninmenu = 1;  
    counter_hud.label = &"ZOMBIES: ^1";
    counter_hud setValue(0); 

	level waittill("start_of_round");

    while (true)
    {
        wait 0.05;
        current_zombies = get_round_enemy_array().size + level.zombie_total;

        if (!current_zombies)
        {
            counter_hud.label = &"ZOMBIES: ^1";
            counter_hud setValue(current_zombies);
            continue;
        }

        if (isDefined(level.round_data["initial_zombie_state"]))
            low_zombies = int(level.round_data["initial_zombie_state"] * 0.05);
        else
            low_zombies = 2;

        if (current_zombies < low_zombies)
            counter_hud.label = &"ZOMBIES: ^3";
        else
            counter_hud.label = &"ZOMBIES: ^5";

        counter_hud setValue(current_zombies); 
    }
}

gauntlet_hud_header()
{
    level endon("end_game");

    gauntlet_header_hud = createserverfontstring("objective", 1.4);
    gauntlet_header_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 50);
    gauntlet_header_hud.alpha = 0;
    gauntlet_header_hud.hidewheninmenu = 1;
    gauntlet_header_hud.color = level.gauntlet_config["hud_color"];

    while (true)
    {
        level waittill("show_gauntlet_hud_header", header_content);
        gauntlet_header_hud setText(header_content);
        gauntlet_header_hud.alpha = 1;

        level waittill("hide_gauntlet_hud_header");
        gauntlet_header_hud.alpha = 0;
    }
}

gauntlet_hud_progress()
{
    level endon("end_game");
    self endon("disconnect");

    self.gauntlet_progress_hud = createfontstring("objective", 2);
    self.gauntlet_progress_hud setPoint("TOPRIGHT", "TOPRIGHT", 0, 70);
	self.gauntlet_progress_hud.alpha = 0;
    self.gauntlet_progress_hud.hidewheninmenu = 1;
    self.gauntlet_progress_hud.color = (1, 1, 1);

    self thread gauntlet_hud_progress_hide_watcher(self.gauntlet_progress_hud);

    while (true)
    {
        self waittill("update_gauntlet_progress_hud", value, color);

        self.gauntlet_progress_hud setText(value);
        self.gauntlet_progress_hud.color = color;
        self.gauntlet_progress_hud.alpha = 1;
    }
}

gauntlet_hud_progress_hide_watcher(hud)
{
    level endon("end_game");
    self endon("disconnect");

    while (true)
    {
        self waittill("hide_gauntlet_progress_hud");
        hud.alpha = 0;
    }
}

activate_hud(header, value, color)
{
    if (!isDefined(color))
        color = level.gauntlet_config["hud_color_in_progress"];

    level notify("show_gauntlet_hud_header", header);
    foreach (player in level.players)
        player notify("update_gauntlet_progress_hud", value, color);
}

update_hud(player, value, is_completed, color_override)
{
    if (!isDefined(color_override))
    {
        if (is_completed)
            color_override = level.gauntlet_config["hud_color_success"];
        else
            color_override = level.gauntlet_config["hud_color_in_progress"];
    }

    if (isDefined(player))
    {
        player notify("update_gauntlet_progress_hud", value, color_override);
        return;
    }

    foreach(player in level.players)
        player notify("update_gauntlet_progress_hud", value, color_override);
}

generate_notify_escape(trigger, value0, value1, value2, value3)
{
    debug_print("Generating notify escape for trigger '" + trigger "'");

    level.notify_escape = array();
    level.notify_escape["trigger"] = trigger;
    if (isDefined(value0))
        level.notify_escape["value0"] = value0;
    if (isDefined(value1))
        level.notify_escape["value1"] = value1;
    if (isDefined(value2))
        level.notify_escape["value2"] = value2;
    if (isDefined(value3))
        level.notify_escape["value3"] = value3;
}

destroy_notify_escape()
{
    level.notify_escape = undefined;
}

escape_notifier()
{
    if (!isDefined(level.notify_escape))
        return;

    receivers_array = array(level);
    foreach (player in level.players)
        receivers_array[receivers_array.size] = player;

    foreach (receiver in receivers_array)
    {
        if (isDefined(level.notify_escape["value3"]))
            receiver notify(level.notify_escape["trigger"], level.notify_escape["value0"], level.notify_escape["value1"], level.notify_escape["value2"], level.notify_escape["value3"]);
        else if (isDefined(level.notify_escape["value2"]))
            receiver notify(level.notify_escape["trigger"], level.notify_escape["value0"], level.notify_escape["value1"], level.notify_escape["value2"]);
        else if (isDefined(level.notify_escape["value1"]))
            receiver notify(level.notify_escape["trigger"], level.notify_escape["value0"], level.notify_escape["value1"]);
        else if (isDefined(level.notify_escape["value0"]))
            receiver notify(level.notify_escape["trigger"], level.notify_escape["value0"]);
        else
            receiver notify(level.notify_escape["trigger"]);
    }
}

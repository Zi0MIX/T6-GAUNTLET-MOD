main()
{
    level thread setup_gauntlet_proxy();
}

// Proxy used as origins fucks off when it has too many init() calls
setup_gauntlet_proxy()
{
    level waittill("gauntlet_init");
    setup_gauntlet_origins1();
}

setup_gauntlet_origins1()
{
    level.gauntlet_setup = ::generate_gauntlet_setup_core_origins_1;
    level.gauntlet_core = ::generate_gauntlet_core_origins_1;
}

generate_gauntlet_setup_core_origins_1()
{
    gauntlet = array();
    gauntlet["hud_color"] = (0.6, 0.8, 1);
    gauntlet["hud_color_in_progress"] = (1, 0.7, 0.4);
    gauntlet["hud_color_success"] = (0.4, 0.7, 1);
    gauntlet["header_in_progress"] = "IN PROGRESS";
    gauntlet["header_completed"] = "SUCCESS";
    gauntlet["1_data"] = undefined;
}

generate_gauntlet_core_origins_1()
{
    core = array();
    core["round_1"] = ::is_any_generator_activated;
}

is_any_generator_activated()
{
    level endon("end_of_round");

    level waittill("start_of_round");

    trigger = "zone_captured_by_player";
    scripts\zm\gauntlet::generate_notify_escape(trigger, "undefined");
    scripts\zm\gauntlet::activate_hud("Activate generator", level.gauntlet_config["header_in_progress"]);

    while (flag("same_round"))
    {
        level waittill(trigger, zone_string);
        scripts\zm\gauntlet::debug_print("received '" + trigger + "' trigger with content='" + zone_string + "'");

        if (zone_string == "undefined")
            break;

        if ((!isDefined(level.gauntlet_config[level.round_number + "_data"])) || (isinarray(level.gauntlet_config[level.round_number + "_data"], zone_string)))
        {
            // success
        }
        else if ()
            // success
    }

    scripts\zm\gauntlet::destroy_notify_escape();
    level notify("gauntlet_finished");
}

escape_zone_captured()
{

}
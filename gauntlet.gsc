init()
{
    level notify("gauntlet_init");
    level thread on_game_start();
    level thread on_player_connect();
}

on_game_start()
{
    level thread gauntlet_loop();
}

on_player_connect()
{
    level waittill("connected", player);
    player thread player_connected();
}

player_connected()
{
    
}

gauntlet_loop()
{
    for (rnd = 1; rnd <= 100; rnd++)
    {
        key = "round_" + rnd;
        if (isDefined(level.gauntlet_core[key]))
            [[level.gauntlet_core[key]]]();

        level waittill("gauntlet_finished_" + key);
    }
}

stub()
{
}

gauntlet_notify_finish_round(rnd)
{
    if (!isDefined(rnd))
        rnd = level.round_number;

    level notify("gauntlet_finished_round_" + rnd);
}
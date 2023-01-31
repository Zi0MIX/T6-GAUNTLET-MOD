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
    level.gauntlet_core = generate_gauntlet_core_origins_1();
}

generate_gauntlet_core_origins_1()
{
    core = array();
    core["round_1"] = scripts\zm\gauntlet::stub;
}
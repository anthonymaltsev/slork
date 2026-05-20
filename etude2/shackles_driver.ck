//-----------------------------------------------------------------------------
// name: shackles_driver.ck
// desc: runner for shackles performance
//       use :s arg if you are sender
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe_history.ck", "shackles.ck", "phasor.ck"}

GameTrak gt;

// init osc in glob scope
"224.0.0.1" => string hostname;
8888 => int port;
OscOut xmit;
0 => int sender;
OscIn oin;
OscMsg omsg;

if (me.args() > 0 && me.arg(0) == "s") {
    1 => sender;
    xmit.dest(hostname, port);
} else {
    port => oin.port;
    oin.addAddress("/shackles/scene, if"); // scene, scene_fade
}

//------------------------- scene setup ----------------------------------

// scene in {0,1}: 0 is chains, 1 is pleasant
0 => int scene;
1. => float scene_fade;

Shred @ curr_scene;
fun void play_scene(int i) {
    <<< "play_scene(", i, ")" >>>;
    if (i == 0) {
        spork ~ _scene0() @=> curr_scene;
    } else if (i == 1) {
        spork ~ _scene1() @=> curr_scene;
    } else {
        <<< "ruh roh! scene ", i, " does not exist!" >>>;
        me.exit();
    }
}

fun void _scene0() {
    Shackle left("data/chain.wav", 0, gt);
    Shackle right("data/scrape.wav", 3, gt);

    while (true) {
        1::second => now;
    }
}

fun void _scene1() {
    Droner pattern;
    Droner drone;

    spork ~ drone.play_drone(Std.mtof(71), 0.75, 50::ms, 150::ms, 0.85);
    spork ~ pattern.play_pattern_FOREVER(Std.mtof(76));

    while (true) {
        1::second => now;
    }
}

fun void _scene_transition_01(dur fade_time_out, dur silence_dur, dur fade_time_in) {
    5::ms => dur step;
    (fade_time_out/step) $ int => int fade_out_steps;
    for (0 => int i; i <= fade_out_steps; i++) {
        (1 - (i $ float) / (fade_out_steps $ float)) => scene_fade;
        step => now;
    }
    0. => scene_fade;
    curr_scene.exit();

    silence_dur => now;

    1 => scene;
    play_scene(1);
    (fade_time_in/step) $ int => int fade_in_steps;
    for (0 => int i; i <= fade_in_steps; i++) {
        (i $ float) / (fade_in_steps $ float) => scene_fade;
        step => now;
    }
    1. => scene_fade;
}

// init piece
play_scene(0);

// -------------------------- main loops ------------------------------
0 => int scene_transitioned;
fun void listen_for_scene_progression() {
    while( true ) {
        
        if (!scene_transitioned && gt.button_ever_pressed) {
            1 => scene_transitioned;
            <<< "scene transition detected!" >>>;
            _scene_transition_01(250::ms, 1.5::second, 2.5::second);
        }
        30::ms => now;
    }
}

if (sender) {
    spork ~ listen_for_scene_progression();
}

while( true )
{
    if (sender) {

        xmit.start("/identity/scene");
        scene => xmit.add; //updated in scene transition, sporked above
        scene_fade => xmit.add; //same
        xmit.send();
        10::ms => now;

    } 
    else { // receiver mode
        oin => now;
        while(oin.recv(omsg))
        { 
            omsg.getInt(0) => scene;
            omsg.getFloat(1) => scene_fade;
        }
    }
}


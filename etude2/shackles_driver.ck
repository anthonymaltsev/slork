//-----------------------------------------------------------------------------
// name: shackles_driver.ck
// desc: runner for shackles performance
//       use :s arg if you are sender across network, or :sl if you are sending to localhost
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe_history.ck", "shackles.ck", "unshackles.ck", "phasor.ck"}

GameTrak gt;

// init osc in glob scope
"255.255.255.255" => string hostname;
"/shackles/scene" => string scene_uri;
8888 => int port;
OscOut xmit;
0 => int sender;
OscIn oin;
OscMsg omsg;

if (me.args() > 0 && (me.arg(0) == "s" || me.arg(0) == "sl")) {
    1 => sender;
    if (me.arg(0) == "sl") {
        "127.0.0.1" => hostname;
    }
    xmit.dest(hostname, port);
} else {
    port => oin.port;
    oin.addAddress(scene_uri + ", if"); // scene, scene_fade
}

//------------------------- scene setup ----------------------------------

// scene in {0,1}: 0 is chains, 1 is pleasant
0 => int scene;
0. => float scene_fade;

Gain scene_bus => dac;
scene_fade => scene_bus.gain;

Shred @ curr_scene;
0 => int curr_scene_id;
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
    Shackle left("data/chain.wav", 0, gt, scene_bus);
    Shackle right("data/scrape.wav", 3, gt, scene_bus);

    while (!unfaded) {
        20::ms => now;
    }

    ShackleDrone drone1("data/spookpad.wav", 0.5, scene_bus);
    ShackleDrone drone2("data/spookpad.wav", 0.3, scene_bus);

    while (true) {
        1::second => now;
    }
}

fun void _scene1() {
    Droner pattern(scene_bus);
    Droner drone(scene_bus);

    Unshackle left(0, gt, scene_bus);
    Unshackle right(3, gt, scene_bus);

    spork ~ drone.play_drone(Std.mtof(71), 0.75, 50::ms, 150::ms, 0.85);
    32::second => now;
    spork ~ pattern.play_pattern_FOREVER(Std.mtof(76));

    while (true) {
        1::second => now;
    }
}

fun void _unfade_sender(dur unfade_time) {
    5::ms => dur step;
    (unfade_time/step) $ int => int unfade_steps;
    for (0 => int i; i <= unfade_steps; i++) {
        (i $ float) / (unfade_steps $ float) => scene_fade;
        step => now;
    }
    1. => scene_fade;
}

fun void _scene_transition_01_sender(dur fade_time_out, dur silence_dur, dur fade_time_in) {
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

fun void _scene_transition_01_receiver() {
    curr_scene.exit();
    1 => scene;
    1 => curr_scene_id;
    play_scene(1);
}

fun void _scene_fade_listener() {
    while (true) {
        scene_fade => scene_bus.gain;
        10::ms => now;
        // <<< "scene bus gain: ", scene_bus.gain()>>>;
    }
}
spork ~ _scene_fade_listener();

// init piece
play_scene(0);

// -------------------------- main loops ------------------------------
// start silent and unfade. first button press is unfade, second is scene transition
0 => int unfaded; // first button pressed?
0 => int scene_transitioned; // second button pressed?
fun void listen_for_scene_progression() {
    while( true ) {
        if (sender && !unfaded && gt.get_button_pressed_mode()) { // unfade
            _unfade_sender(8::second);
            1 => unfaded;
            gt.set_button_pressed_mode(0);
        } else if (sender && unfaded && !scene_transitioned && gt.get_button_pressed_mode()) { // sender transition
            1 => scene_transitioned;
            <<< "scene transition detected!" >>>;
            _scene_transition_01_sender(2::second, 1::second, 12::second);
            gt.set_button_pressed_mode(0);
        } else if (!sender && curr_scene_id != scene) { // receiver transition
            <<< "scene transition detected!" >>>;
            _scene_transition_01_receiver();
        }
        30::ms => now;
    }
}

spork ~ listen_for_scene_progression();


fun void log_state() {
    while (true) {
        <<<"\nscene: ", scene, "\nscene_fade:", scene_fade >>>;
        100::ms => now;
    }
} 
spork ~ log_state();

while( true )
{
    if (sender) {

        xmit.start(scene_uri);
        scene => xmit.add; //updated in scene transition, sporked above
        scene_fade => xmit.add; //same
        xmit.send();
        10::ms => now;

    } 
    else { // receiver mode
        oin => now;
        // <<< "received message", "" >>>;
        while(oin.recv(omsg))
        { 
            omsg.getInt(0) => scene;
            omsg.getFloat(1) => scene_fade;
        }
    }
}


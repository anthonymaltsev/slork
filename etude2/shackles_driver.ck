//-----------------------------------------------------------------------------
// name: shackles_driver.ck
// desc: runner for shackles performance
//       use :s arg if you are sender across network, or :sl if you are sending to localhost
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe_history.ck", "shackles.ck", "unshackles.ck", "phasor.ck", "mellotron.ck"}

GameTrak gt;

// init osc in glob scope
"255.255.255.255" => string hostname;
"/shackles/scene" => string scene_uri;
"/shackles/pattern_ind" => string pattern_uri;
8888 => int port;
OscOut xmit;
0 => int sender;
OscIn oin;
OscMsg omsg;
OscIn oin2;
OscMsg omsg2;
-1 => int my_index;
-1 => int max_index;

if (me.args() > 0 && (me.arg(0) == "s" || me.arg(0) == "sl")) {
    1 => sender;
    0 => my_index;
    if (me.args() <= 1) {
        <<<"sender needs second argument for max index of player (num of players including conductor minus 1)", "">>>;
        me.exit();
    } else {
        Std.atoi(me.arg(1)) => max_index;
    }
    if (me.arg(0) == "sl") {
        "127.0.0.1" => hostname;
    }
    xmit.dest(hostname, port);
} else if (me.args() > 0){
    Std.atoi(me.arg(0)) => my_index;
    port => oin.port;
    oin.addAddress(scene_uri + ", iiifff"); // scene, scene_instruction_index, unfaded, drone_fade, instr_fade, scene_fade
    port => oin2.port;
    oin2.addAddress(pattern_uri + ", i"); // play_index
} else {
    <<<"Need to pass an argument (either s or sl for sender, or index [1 : n-1])", "" >>>;
    me.exit();
}

//------------------------- scene setup ----------------------------------

// start silent and unfade. first button press is unfade, second is scene transition
0 => int unfaded; // first button pressed?
0 => int scene_transitioned; // second button pressed?
0 => int scene_instruction_index;
[
    // scene 0
    [
        ""//Wait for the piece to begin (conductor press button when ready!)",
        ""//YOU: Hold still!\nDANCERS: jerky movements",
        ""//YOU: Hold still!\nDANCERS: stop",
        ""//YOU: Repeatedly yank the GT back toward yourself, 'pulling' dancers down.\nDANCERS: Collapse to floor.",
        ""//YOU: Conductor initiate fade, hold still!\nDANCERS: hold still!",
        ""
    ],
    // scene 1
    [
        ""//YOU: Hold still\nDANCERS: arise into smooth movements",
        ""//YOU: Begin to rise, floating the GT\nDANCERS: continue smoothly.",
        "",
        "",
        "",
        "",
    ]
] @=> string scene_instructions[][];

// scene in {0,1}: 0 is chains, 1 is pleasant
0 => int scene;
0.1 => float drone_sus_level;
0.1 => float instr_sus_level;
1. => float drone_fade;
instr_sus_level => float instr_fade;
0. => float scene_fade;

Gain instr_bus => Gain scene_bus => dac;
Gain drone_bus => scene_bus;
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
    if (sender)
        spork ~ _scene0_instructions_timer();
    ShackleDrone drone1("data/spookpad.wav", 0.5, drone_bus);
    ShackleDrone drone2("data/spookpad.wav", 0.3, drone_bus);

    while (!unfaded) {
        20::ms => now;
    }


    Shackle left("data/chain.wav", 0, gt, instr_bus);
    Shackle right("data/scrape.wav", 3, gt, instr_bus);

    while (true) {
        // 1::second => now;
        if (sender)
            _cut_drone_up_instr_and_fade_sender(200::ms, 4::second, 8::second);
        2::second => now;
    }
}
fun void _scene0_instructions_timer() {
    0 => scene_instruction_index;
    while (scene_fade == 0) 10::ms => now;
    1 => scene_instruction_index;
    40::second => now;
    2 => scene_instruction_index;
    10::second => now;
    3 => scene_instruction_index;
    20::second => now;
    4 => scene_instruction_index;
}

fun void _scene1() {
    if (sender)
        spork ~ _scene1_instructions_timer();
    Droner drone(drone_bus);

    // Unshackle left(0, gt, scene_bus);
    // Unshackle right(3, gt, scene_bus);

    spork ~ drone.play_drone(Std.mtof(71), 0.75, 50::ms, 150::ms, 0.85);
    8::second => now;

    Mellotron left(0, gt, instr_bus);
    Mellotron right(3, gt, instr_bus);

    spork ~ _scene1_pattern_player(24::second);

    while (true) {
        // 1::second => now;
        if (sender)
            _cut_drone_up_instr_and_fade_sender(200::ms, 4::second, 8::second);
        2::second => now;
    }
}

fun void _scene1_pattern_player(dur wait_before_start) {
    wait_before_start => now;
    Droner pattern(drone_bus);
    if (sender) {
        0 => int curr_ind;
        while (true) {
            if (curr_ind == 0) { // me
                <<< "I AM PLAYING THE PATTERN", "" >>>;
                spork ~ pattern.play_pattern(Std.mtof(76));
            } else {
                xmit.start(pattern_uri);
                curr_ind => xmit.add;
                xmit.send();
            }
            1 +=> curr_ind;
            if (curr_ind > max_index) {
                0 => curr_ind;
            }
            3.6::second => now;
        }
    } else {
        while (true) {
            oin2 => now;
            0 => int ind_to_play;
            while(oin2.recv(omsg2))
            {
                omsg2.getInt(0) => ind_to_play;
            }
            if (ind_to_play == my_index) {
                <<< "I AM PLAYING THE PATTERN", "" >>>;
                spork ~ pattern.play_pattern(Std.mtof(76));
            }
        }
    }
    
}

fun void _scene1_instructions_timer() {
    0 => scene_instruction_index;
    40::second => now;
    1 => scene_instruction_index;
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

LiSa kick => Gain accent_bus => LPF accent_lpf => scene_bus;
0.4 => accent_bus.gain;
3000 => accent_lpf.freq;
0.7 => accent_lpf.Q;
0.7 => kick.gain;
kick.loop(0, 0);
2. => kick.rate;

SndBuf kick_src;
"data/open_hat_1.wav" => kick_src.read;
kick_src.samples()::samp => kick.duration;
for (0 => int i; i < kick_src.samples(); i++) {
    kick.valueAt(kick_src.valueAt(i), i::samp);
}

Unshackle accent(accent_bus);

fun void _cut_drone_up_instr_and_fade_sender(dur cut_time, dur cut_dur, dur fade_up) {
    // some transition noise
    if (scene == 1) {
        accent.play_note(72);
    } else {
        0::samp => kick.playPos;
        1 => kick.play;
    }
    1::ms => dur step;
    (cut_time/step) $ int => int cut_steps;
    for (0 => int i; i <= cut_steps; i++) {
        1. - (1 - drone_sus_level) * (i $ float) / (cut_steps $ float) => drone_fade;
        instr_sus_level + (1. - instr_sus_level) * (i $ float) / (cut_steps $ float) => instr_fade;
        step => now;
    }
    1. => instr_fade;
    drone_sus_level => drone_fade;

    cut_dur => now;
    
    (fade_up/step) $ int => int fade_up_steps;
    for (0 => int i; i <= fade_up_steps; i++) {
        1 - (1 - instr_sus_level) * (i $ float) / (fade_up_steps $ float) => instr_fade;
        drone_sus_level + (1 - drone_sus_level) * (i $ float) / (fade_up_steps $ float) => drone_fade;
        step => now;
    }
    instr_sus_level => instr_fade;
    1 => drone_fade;
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
    1 => scene;
    instr_sus_level => instr_fade;
    1. => drone_fade;

    silence_dur => now;

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
        drone_fade => drone_bus.gain;
        instr_fade => instr_bus.gain;
        1::ms => now;
        // <<< "scene bus gain: ", scene_bus.gain()>>>;
    }
}
spork ~ _scene_fade_listener();

// init piece
play_scene(0);

// -------------------------- main loops ------------------------------

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
        <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
        <<<"\nscene: ", scene, "\nscene_fade:", scene_fade >>>;
        <<<"instr_fade: ", instr_fade, "\ndrone_fade:", drone_fade >>>;
        <<<scene_instructions[scene][scene_instruction_index], "">>>;
        100::ms => now;
    }
} 
spork ~ log_state();

while( true )
{
    if (sender) {

        xmit.start(scene_uri);
        scene => xmit.add; //updated in scene transition, sporked above
        scene_instruction_index => xmit.add;
        unfaded => xmit.add;
        drone_fade => xmit.add;
        instr_fade => xmit.add;
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
            omsg.getInt(1) => scene_instruction_index;
            omsg.getInt(2) => unfaded;
            omsg.getFloat(3) => drone_fade;
            omsg.getFloat(4) => instr_fade;
            omsg.getFloat(5) => scene_fade;
        }
    }
}


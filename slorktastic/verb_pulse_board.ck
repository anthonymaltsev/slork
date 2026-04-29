//-----------------------------------------------------------------------------
// name: verb_board.ck
// desc: soundboard using verb sounds; press a key to play a sound
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import "arbsynth.ck"

ArbSynth sounds[0];

// cooking pulse
new ArbSynth("data/verbs/pulse/cutting-vegetables.arr", dac) @=> sounds["A"]; //
new ArbSynth("data/verbs/pulse/egg-crack.arr", dac) @=> sounds["B"]; //
new ArbSynth("data/verbs/pulse/liquid-swirl.arr", dac) @=> sounds["C"];

// cooking cont
new ArbSynth("data/verbs/cont/coffee-brewing-percolation.arr", dac) @=> sounds["D"]; //
new ArbSynth("data/verbs/cont/cooking-frying.arr", dac) @=> sounds["E"]; //
new ArbSynth("data/verbs/cont/cooking-pasta.arr", dac) @=> sounds["F"];
new ArbSynth("data/verbs/cont/food-cooking-in-oil.arr", dac) @=> sounds["G"]; //
new ArbSynth("data/verbs/cont/keurig-kcup-brewing.arr", dac) @=> sounds["H"]; // put to mech?
new ArbSynth("data/verbs/cont/moka-express-brewing.arr", dac) @=> sounds["I"]; //
new ArbSynth("data/verbs/cont/whisking.arr", dac) @=> sounds["J"]; //

// mech pulse
new ArbSynth("data/verbs/pulse/buttons_calculator.arr", dac) @=> sounds["K"]; // resegment
new ArbSynth("data/verbs/pulse/car-horn-honking.arr", dac) @=> sounds["L"]; // need to resynthesize
new ArbSynth("data/verbs/pulse/cell-phone-vibrate-high-quality.arr", dac) @=> sounds["M"];
new ArbSynth("data/verbs/pulse/rustling-a-newspaper.arr", dac) @=> sounds["N"]; //

// mech cont
new ArbSynth("data/verbs/cont/geese-honking.arr", dac) @=> sounds["O"]; // better off in man cont
new ArbSynth("data/verbs/cont/pencil-on-paper-1.arr", dac) @=> sounds["P"]; //?
new ArbSynth("data/verbs/cont/pencil-on-paper-2.arr", dac) @=> sounds["Q"]; 
new ArbSynth("data/verbs/cont/rain.arr", dac) @=> sounds["R"]; // regroup or resynth

// man pulse
new ArbSynth("data/verbs/pulse/blade-piercing-body.arr", dac) @=> sounds["S"]; //
new ArbSynth("data/verbs/pulse/e-oh.arr", dac) @=> sounds["T"];
new ArbSynth("data/verbs/pulse/glass-breaking.arr", dac) @=> sounds["U"];
new ArbSynth("data/verbs/pulse/groaning-gurgle.arr", dac) @=> sounds["V"];
new ArbSynth("data/verbs/pulse/knife-stab.arr", dac) @=> sounds["W"];
new ArbSynth("data/verbs/pulse/little-creature-hurt.arr", dac) @=> sounds["X"]; // normalize gain
new ArbSynth("data/verbs/pulse/man-screaming.arr", dac) @=> sounds["Y"]; // resynth
new ArbSynth("data/verbs/pulse/ouch-oof-hurt-1.arr", dac) @=> sounds["Z"];
new ArbSynth("data/verbs/pulse/ouch-oof-hurt-2.arr", dac) @=> sounds["1"];
new ArbSynth("data/verbs/pulse/ouch-oof-hurt-3.arr", dac) @=> sounds["2"];
new ArbSynth("data/verbs/pulse/screaming-man.arr", dac) @=> sounds["3"]; // resynth

// man cont
new ArbSynth("data/verbs/cont/cry-of-pain.arr", dac) @=> sounds["4"]; 
new ArbSynth("data/verbs/cont/crying-man.arr", dac) @=> sounds["5"]; //
new ArbSynth("data/verbs/cont/frantic-screaming.arr", dac) @=> sounds["6"];
new ArbSynth("data/verbs/cont/puppy-crying.arr", dac) @=> sounds["7"];
new ArbSynth("data/verbs/cont/woman-screaming-sfx-screaming.arr", dac) @=> sounds["8"];
new ArbSynth("data/verbs/cont/wood-burning-stove-fire.arr", dac) @=> sounds["9"];

new ArbSynth("data/synthPads/UnderwaterTemple_bip_2.arr", dac) @=> sounds["0"];

<<<"made synths", "" >>>;
Hid hi;
HidMsg msg;
0 => int device;
if (me.args()) me.arg(0) => Std.atoi => device;
if (!hi.openKeyboard(device)) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

fun string keyChar(int ascii) {
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" => string alpha;
    if (ascii >= 65 && ascii <= 90) return alpha.charAt2(ascii - 65);
    if (ascii >= 48 && ascii <= 57) return Std.itoa(ascii - 48);
    return "";
}

<<< "starting main loop" , "">>>;
while (true) {
    hi => now;
    while (hi.recv(msg)) {
        if (msg.isButtonDown()) {
            keyChar(msg.ascii) => string k;
            if (k != "") {
                <<< k, "->", sounds[k].fname >>>;
                spork ~ sounds[k].playback();
            }
        }
    }
}

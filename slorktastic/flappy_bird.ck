//-----------------------------------------------------------------------------
// name: flappy_bird.ck
// desc: flappy gametrack synth thang
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe.ck", "arbsynth2.ck"}

// ----------------------------------------------------------------------------

0 => int gt_device;
0.05 => float deadzone;
GameTrak gt(gt_device, deadzone);
// GameTrak gt;

//------------------------- flappy bird setup ----------------------------------

class FlappyBird {
    ArbSynth2 s;
    Shred play_shred;

    fun @construct(string fname1, string fname2) {
        __init(fname1, fname2, dac);
    }

    fun @construct(string fname1, string fname2, UGen outchan) {
        __init(fname1, fname2, outchan);
    }

    fun void __init(string fname1, string fname2, UGen outchan) {
        new ArbSynth2(fname1, fname2, outchan) @=> s;
    }

    fun void play_pad() {
        spork ~ s.pad_playback() @=> play_shred;
        spork ~ pad_param_propagater();
    }

    fun void play_pad(dur duration) {
        spork ~ s.pad_playback(duration) @=> play_shred;
        spork ~ pad_param_propagater();
    }

    fun void pad_param_propagater() {
        while (true) {
            s.set_pad_mix(gt.axis[2]);
            // gain ramp 0 to 1 from lengths 0 to 0.25, flat at 1 after
            s.set_pad_gain(Math.clampf(gt.axis[2], 0., 0.25));

            1::ms => now;
        }
    }

}

Hid kb;
HidMsg kb_msg;
0 => int kb_device;
if (me.args() > 0) Std.atoi(me.arg(0)) => kb_device;
if (!kb.openKeyboard(kb_device)) me.exit();

// 3 => int NUM_BIRDS;
Gain g[0];
Gain bus;
new Gain @=> g["1"] => bus;
new Gain @=> g["2"] => bus;
new Gain @=> g["3"] => bus;

FlappyBird f[0];
new FlappyBird("data/verbs/cont/geese-honking.arr", "data/verbs/cont/cooking-pasta.arr", g["1"]) @=> f["1"];
new FlappyBird("data/verbs/cont/stomach-gurgle.arr", "data/verbs/cont/cooking-frying.arr", g["2"]) @=> f["2"];
new FlappyBird("data/verbs/cont/cry-of-pain.arr", "data/verbs/cont/wood-burning-stove-fire.arr", g["3"]) @=> f["3"];

f["1"].play_pad(15::second);
f["1"].play_pad(21::second);
f["2"].play_pad(15::second);
f["2"].play_pad(21::second);
f["3"].play_pad(15::second);
f["3"].play_pad(21::second);

// bools for which of these are on or not.
int on[0];
1 => on["1"];
0 => on["2"];
0 => on["3"];

// listen to controls around which samples are played
spork ~ kb_listener();
fun void kb_listener() {
    while (true) {
        kb => now;
        while (kb.recv(kb_msg)) {
            ascii_to_numkey(kb_msg.which) => string whichkey;
            <<< "whichkey: ", whichkey >>>;
            if (whichkey == "") continue;
            if (kb_msg.isButtonDown()) {
                // <<< whichkey, on[whichkey] >>>;
                on[whichkey] ? 0 : 1 => on[whichkey]; // toggle
            }

        }
    }
}
spork ~ gain_listener();
fun void gain_listener() {
    while (true) {
        on["1"] => g["1"].gain;
        on["2"] => g["2"].gain;
        on["3"] => g["3"].gain;
        1::ms => now;
    }
}

fun string ascii_to_numkey(int ascii) {
    // "ABCDEFGHIJKLMNOPQRSTUVWXYZ" => string alpha;
    // if (ascii >= 65 && ascii <= 90) return alpha.charAt2(ascii - 65);
    // if (ascii >= 48 && ascii <= 57) return Std.itoa(ascii - 48);
    // <<< ascii >>>;
    if (ascii >= 30 && ascii <= 32) return Std.itoa(ascii - 29); // only 1 to 3
    return "";
}

// g => NRev rev;
// rev => dac;
// rev => Delay d(1::second) => dac;
// 0.1 => rev.mix;
// PitShift ps;
// 2 => ps.shift;
// 0.8 => ps.mix;
// g => ps => dac;
bus => NRev rev(0.03) =>  ABSaturator ab => dac;
0.1 => ab.dcOffset;
10. => ab.drive;

Chorus chor[3];
for (0 => int i; i < chor.size(); i++) {
    bus => chor[i] => rev;
    chor[i].baseDelay( i * 10::ms );
    chor[i].modDepth( .1 + i * 0.15 );
    chor[i].modFreq( i );
    chor[i].mix( .5 );
}

spork ~ effect_param_propagater();
fun void effect_param_propagater() {
    while (true) {
        Math.clampf((gt.axis[1]+1)/8., 0., 1.) => rev.mix;

        1::ms => now;
    }
}

while (true) {
    <<< "pasta-geese: ", on["1"], "\nfactory-birb: ", on["2"], "\nfire-scream: ", on["3"] >>>;
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    100::ms => now;
}


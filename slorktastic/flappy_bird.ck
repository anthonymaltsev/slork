//-----------------------------------------------------------------------------
// name: flappy_bird.ck
// desc: flappy gametrack synth thang
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe.ck", "arbsynth2.ck"}

// ----------------------------------------------------------------------------

0 => int device;
if (me.args() > 0) Std.atoi(me.arg(0)) => device;
0.05 => float deadzone;
// GameTrak gt(device, deadzone);
GameTrak gt;

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
            s.set_pad_gain(Math.clampf(gt.axis[2], 0., 0.25)*4.);

            1::ms => now;
        }
    }

}

Gain g;
FlappyBird f("data/verbs/cont/geese-honking.arr", "data/verbs/cont/cooking-pasta.arr", g);
// FlappyBird f("data/verbs/cont/geese-honking.arr", "data/verbs/cont/pencil-on-paper-1.arr", g);
f.play_pad(15::second);
f.play_pad(21::second); // 5::second
// f.play_pad(1000::ms);

// g => NRev rev;
// rev => dac;
// rev => Delay d(1::second) => dac;
// 0.1 => rev.mix;
// PitShift ps;
// 2 => ps.shift;
// 0.8 => ps.mix;
// g => ps => dac;
g => NRev rev(0.1) =>  ABSaturator ab => dac;
0.1 => ab.dcOffset;
10. => ab.drive;

spork ~ effect_param_propagater();
fun void effect_param_propagater() {
    while (true) {
        Math.clampf((gt.axis[1]+1)/8., 0., 1.) => rev.mix;

        1::ms => now;
    }
}

while (true) {
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    100::ms => now;
}


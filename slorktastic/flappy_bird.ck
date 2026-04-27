//-----------------------------------------------------------------------------
// name: flappy_bird.ck
// desc: flappy gametrack synth thang
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe.ck", "arbsynth2.ck"}

// ----------------------------------------------------------------------------

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
            1::ms => now;
        }
    }

}

Gain g;
FlappyBird f("data/verbs/cont/pretzel-crunching.arr", "data/verbs/cont/pencil-on-paper-1.arr", g);
f.play_pad(15::second);
f.play_pad(); // 5::second
// f.play_pad(600::ms);

g => NRev rev;
rev => dac;
rev => Delay d(1::second) => dac;

0.1 => rev.mix;

while (true) {
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    100::ms => now;
}


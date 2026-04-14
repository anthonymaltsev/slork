//-----------------------------------------------------------------------------
// name: tts.ck
// desc: the stupidest tts synthesizer of all time. uses arbsynth
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import "arbsynth.ck"

class Sayer {
    ArbSynth alphabet[0];
    150::ms => dur len;

    fun @construct() {
        new ArbSynth("data/alphabet/a.arr", dac) @=> alphabet["a"];
        new ArbSynth("data/alphabet/b.arr", dac) @=> alphabet["b"];
        new ArbSynth("data/alphabet/c.arr", dac) @=> alphabet["c"];
        new ArbSynth("data/alphabet/d.arr", dac) @=> alphabet["d"];
        new ArbSynth("data/alphabet/e.arr", dac) @=> alphabet["e"];
        new ArbSynth("data/alphabet/f.arr", dac) @=> alphabet["f"];
        new ArbSynth("data/alphabet/g.arr", dac) @=> alphabet["g"];
        new ArbSynth("data/alphabet/h.arr", dac) @=> alphabet["h"];
        new ArbSynth("data/alphabet/i.arr", dac) @=> alphabet["i"];
        new ArbSynth("data/alphabet/j.arr", dac) @=> alphabet["j"];
        new ArbSynth("data/alphabet/k.arr", dac) @=> alphabet["k"];
        new ArbSynth("data/alphabet/l.arr", dac) @=> alphabet["l"];
        new ArbSynth("data/alphabet/m.arr", dac) @=> alphabet["m"];
        new ArbSynth("data/alphabet/n.arr", dac) @=> alphabet["n"];
        new ArbSynth("data/alphabet/o.arr", dac) @=> alphabet["o"];
        new ArbSynth("data/alphabet/p.arr", dac) @=> alphabet["p"];
        new ArbSynth("data/alphabet/q.arr", dac) @=> alphabet["q"];
        new ArbSynth("data/alphabet/r.arr", dac) @=> alphabet["r"];
        new ArbSynth("data/alphabet/s.arr", dac) @=> alphabet["s"];
        new ArbSynth("data/alphabet/t.arr", dac) @=> alphabet["t"];
        new ArbSynth("data/alphabet/u.arr", dac) @=> alphabet["u"];
        new ArbSynth("data/alphabet/v.arr", dac) @=> alphabet["v"];
        new ArbSynth("data/alphabet/w.arr", dac) @=> alphabet["w"];
        new ArbSynth("data/alphabet/x.arr", dac) @=> alphabet["x"];
        new ArbSynth("data/alphabet/y.arr", dac) @=> alphabet["y"];
        new ArbSynth("data/alphabet/z.arr", dac) @=> alphabet["z"];
    }

    fun void say(string s) {
        for (0 => int i; i < s.length(); i++) {
            if (" " == s.charAt2(i)) 
                2*len => now;
            else { 
                <<< "saying ", s.charAt2(i) >>>;
                spork ~ alphabet[s.charAt2(i)].playback();
                len => now;
            }
        }
    }
}

Sayer s;
s.say("ai ai ai ai ai ai ai is big data and we will see where it goes certainly there are interesting directions of development");
// s.alphabet["abcdefghijklmnopqrstuvwxyz"].playback();
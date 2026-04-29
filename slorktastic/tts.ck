@import "arbsynth.ck"

public class Sayer {
    ArbSynth alphabet[0];
    Gain master;
    150::ms => dur len;

    fun @construct() {
        master => dac;
        _load();
    }

    fun @construct(UGen outchan) {
        master => outchan;
        _load();
    }

    fun void _load() {
        new ArbSynth("data/alphabet/a.arr", master) @=> alphabet["a"];
        new ArbSynth("data/alphabet/b.arr", master) @=> alphabet["b"];
        new ArbSynth("data/alphabet/c.arr", master) @=> alphabet["c"];
        new ArbSynth("data/alphabet/d.arr", master) @=> alphabet["d"];
        new ArbSynth("data/alphabet/e.arr", master) @=> alphabet["e"];
        new ArbSynth("data/alphabet/f.arr", master) @=> alphabet["f"];
        new ArbSynth("data/alphabet/g.arr", master) @=> alphabet["g"];
        new ArbSynth("data/alphabet/h.arr", master) @=> alphabet["h"];
        new ArbSynth("data/alphabet/i.arr", master) @=> alphabet["i"];
        new ArbSynth("data/alphabet/j.arr", master) @=> alphabet["j"];
        new ArbSynth("data/alphabet/k.arr", master) @=> alphabet["k"];
        new ArbSynth("data/alphabet/l.arr", master) @=> alphabet["l"];
        new ArbSynth("data/alphabet/m.arr", master) @=> alphabet["m"];
        new ArbSynth("data/alphabet/n.arr", master) @=> alphabet["n"];
        new ArbSynth("data/alphabet/o.arr", master) @=> alphabet["o"];
        new ArbSynth("data/alphabet/p.arr", master) @=> alphabet["p"];
        new ArbSynth("data/alphabet/q.arr", master) @=> alphabet["q"];
        new ArbSynth("data/alphabet/r.arr", master) @=> alphabet["r"];
        new ArbSynth("data/alphabet/s.arr", master) @=> alphabet["s"];
        new ArbSynth("data/alphabet/t.arr", master) @=> alphabet["t"];
        new ArbSynth("data/alphabet/u.arr", master) @=> alphabet["u"];
        new ArbSynth("data/alphabet/v.arr", master) @=> alphabet["v"];
        new ArbSynth("data/alphabet/w.arr", master) @=> alphabet["w"];
        new ArbSynth("data/alphabet/x.arr", master) @=> alphabet["x"];
        new ArbSynth("data/alphabet/y.arr", master) @=> alphabet["y"];
        new ArbSynth("data/alphabet/z.arr", master) @=> alphabet["z"];
    }

    fun void set_gain(float g) {
        g => master.gain;
    }

    fun void say(string s) {
        for (0 => int i; i < s.length(); i++) {
            if (" " == s.charAt2(i))
                2*len => now;
            else {
                spork ~ alphabet[s.charAt2(i)].playback();
                len => now;
            }
        }
    }
}

Sayer s;
s.say("ai ai ai ai ai ai ai is big data and we will see where it goes certainly there are interesting directions of development");
// s.alphabet["a"].playback();
//-----------------------------------------------------------------------------
// name: perlin.ck
// desc: 1d perlin noise generator with time
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------


public class Perlin1D {
    0 => int id;
    0 => int axis;
    1::second => dur freq;
    1. => float amp;

    fun void init(int id_in, int axis_in, dur freq_in, float amp_in) {
        id_in => id;
        axis_in => axis;
        freq_in => freq;
        amp_in => amp;
    }

    fun float hash_grad(int t0) {
        id * 1000003 + t0 * 2654435761 + axis * 805459861 => int h;
        h ^ (h >> 16) => h;
        2246822519 *=> h;
        h ^ (h >> 13) => h;
        return ((h % 3001)-1500) / 1500.;
    }

    fun float generate(time tt) {
        tt / freq => float t;
        (Math.floor(t)) $ int => int t0;
        t0 + 1 => int t1;
        t - t0 => float dt;

        hash_grad(t0) => float g0;
        hash_grad(t1) => float g1;

        g0 * dt => float v0;
        g1 * (dt - 1) => float v1;
        Math.pow(dt, 3) * (dt * (dt * 6 - 15) + 10) => float f;
        v0 + f * (v1 - v0) => float d;

        return d * amp;
    }

}

public class Perlin2D {
    Perlin1D p0;
    Perlin1D p1;

    0 => int id;
    1::second => dur freq;
    1. => float amp;

    fun void init(int id_in, dur freq_in, float amp_in) {
        id_in => id;
        freq_in => freq;
        amp_in => amp;
        p0.init(id, 0, freq, amp);
        p1.init(id, 1, freq, amp);
    }

    fun vec2 generate(time tt) {
        return @(p0.generate(tt), p1.generate(tt + freq/3.));
    }
}
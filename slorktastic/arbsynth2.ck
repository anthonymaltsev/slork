//-----------------------------------------------------------------------------
// name: arbsynth2.ck
// desc: arbitrary sound synthesizer in chuck, interpolates between 2 inputs
//       a generalization of the code in /etude1/sparrow.ck
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

public class ArbSynth2 {

    string fname1;
    string fname2;

    int N1;
    int num_lines1;
    int hop1;
    dur dur1;
    vec2 freq_gain1[][];

    int N2;
    int num_lines2;
    int hop2;
    dur dur2;
    vec2 freq_gain2[][];

    SinOsc sins1[];
    SinOsc sins2[];
    NRev rev;

    fun @construct(string fname1_in, string fname2_in, UGen outchan) {
        fname1_in => fname1;
        FileIO fin1;
        fin1.open(fname1, FileIO.READ);

        StringTokenizer tok1;
        fin1.readLine() => string line1;
        tok1.set(line1);

        Std.atoi(tok1.next()) =>  N1;
        Std.atoi(tok1.next()) =>  num_lines1;
        Std.atoi(tok1.next()) => hop1;
        hop1::samp * num_lines1 => dur1;

        new vec2[num_lines1][N1] @=> freq_gain1;

        for (0 => int i; i < num_lines1; i++) {
            fin1.readLine() => line1;
            tok1.set(line1);

            for (0 => int j; j < N1; j++) {
                @(Std.atof(tok1.next()), Std.atof(tok1.next())) => freq_gain1[i][j];
            }
        }
        new SinOsc[N1] @=> sins1;
        for (auto s : sins1) {
            0. => s.gain;
            s => rev;
        }

        fname2_in => fname2;
        FileIO fin2;
        fin2.open(fname2, FileIO.READ);

        StringTokenizer tok2;
        fin2.readLine() => string line2;
        tok2.set(line2);

        Std.atoi(tok2.next()) =>  N2;
        Std.atoi(tok2.next()) =>  num_lines2;
        Std.atoi(tok2.next()) => hop2;
        hop2::samp * num_lines2 => dur2;

        new vec2[num_lines2][N2] @=> freq_gain2;

        for (0 => int i; i < num_lines2; i++) {
            fin2.readLine() => line2;
            tok2.set(line2);

            for (0 => int j; j < N2; j++) {
                @(Std.atof(tok2.next()), Std.atof(tok2.next())) => freq_gain2[i][j];
            }
        }
        new SinOsc[N2] @=> sins2;
        for (auto s : sins2) {
            0. => s.gain;
            s => rev;
        }

        0.01 => rev.mix;
        rev => outchan;

    }

    fun void playback(float mix_param) {
        playback(mix_param, (dur1+dur2)/2.);
    }

    fun void playback(float mix_param, dur duration) {
        vec2 curr_freq_gain;

        for (0::samp => dur t; t <= duration; 1::ms +=> t) {
            t/duration => float progress;
            for (0 => int j1; j1 < N1; j1++) {
                interp_lookup(freq_gain1, progress, j1) => curr_freq_gain;
                mix_param *=> curr_freq_gain;
                10* curr_freq_gain.y => sins1[j1].gain;
                curr_freq_gain.x => sins1[j1].freq;
            }
            for (0 => int j2; j2 < N2; j2++) {
                interp_lookup(freq_gain2, progress, j2) => curr_freq_gain;
                (1. - mix_param) *=> curr_freq_gain;
                10* curr_freq_gain.y => sins2[j2].gain;
                curr_freq_gain.x => sins2[j2].freq;
            }
            1::ms => now;
        }
        for (auto s : sins1) 0. => s.gain;
        for (auto s : sins2) 0. => s.gain;
    }

    fun vec2 interp_lookup(vec2 table[][], float index, int nind) {
        Math.floor(index * table.size()) $ int => int i0;
        if (i0 == table.size() - 1) return table[i0][nind];
        index * table.size() - i0 => float di;
        return table[i0][nind] + (table[i0+1][nind]-table[i0][nind]) * di;
    }

}

ArbSynth2 arb(me.arg(0), me.arg(1), dac);
for (0. => float mix; mix <= 1.; 0.1 +=> mix)
    arb.playback(mix);
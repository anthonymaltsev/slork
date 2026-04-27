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

    int N;

    int num_lines1;
    int hop1;
    dur dur1;
    vec2 freq_gain1[][];

    int num_lines2;
    int hop2;
    dur dur2;
    vec2 freq_gain2[][];

    SinOsc sins[];
    NRev rev;

    fun @construct(string fname1_in, string fname2_in, UGen outchan) {
        fname1_in => fname1;
        FileIO fin1;
        fin1.open(fname1, FileIO.READ);

        StringTokenizer tok1;
        fin1.readLine() => string line1;
        tok1.set(line1);

        Std.atoi(tok1.next()) =>  int N1;
        Std.atoi(tok1.next()) =>  num_lines1;
        Std.atoi(tok1.next()) => hop1;
        hop1::samp * num_lines1 => dur1;

        fname2_in => fname2;
        FileIO fin2;
        fin2.open(fname2, FileIO.READ);

        StringTokenizer tok2;
        fin2.readLine() => string line2;
        tok2.set(line2);

        Std.atoi(tok2.next()) =>  int N2;
        Std.atoi(tok2.next()) =>  num_lines2;
        Std.atoi(tok2.next()) => hop2;
        hop2::samp * num_lines2 => dur2;

        if (N1 != N2) me.exit();
        N1 => N;

        new vec2[num_lines1][N] @=> freq_gain1;
        new vec2[num_lines2][N] @=> freq_gain2;

        for (0 => int i; i < num_lines1; i++) {
            fin1.readLine() => line1;
            tok1.set(line1);

            for (0 => int j; j < N; j++) {
                @(Std.atof(tok1.next()), Std.atof(tok1.next())) => freq_gain1[i][j];
            }
        }
        norm_scale_mags(freq_gain1, 0.15);
        for (0 => int i; i < num_lines2; i++) {
            fin2.readLine() => line2;
            tok2.set(line2);

            for (0 => int j; j < N2; j++) {
                @(Std.atof(tok2.next()), Std.atof(tok2.next())) => freq_gain2[i][j];
            }
        }
        norm_scale_mags(freq_gain2, 0.15);

        new SinOsc[N] @=> sins;
        for (auto s : sins) {
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
        for (0::samp => dur t; t <= duration; 1::ms +=> t) {
            t/duration => float progress;
            for (0 => int j; j < N; j++) {
                interp_lookup(freq_gain1, progress, j) => vec2 fg1;
                interp_lookup(freq_gain2, progress, j) => vec2 fg2;
                mix_param * fg1.y + (1. - mix_param) * fg2.y => sins[j].gain;
                Math.exp(mix_param * (fg1.x > 0 ? Math.log(fg1.x) : -1000.) + (1. - mix_param) * (fg2.x > 0 ? Math.log(fg2.x) : -1000.)) => sins[j].freq;
            }
            1::ms => now;
        }
        for (auto s : sins) 0. => s.gain;
    }

    fun vec2 interp_lookup(vec2 table[][], float index, int nind) {
        Math.floor(index * table.size()) $ int => int i0;
        if (i0 == table.size() - 1) return table[i0][nind];
        index * table.size() - i0 => float di;
        return table[i0][nind] + (table[i0+1][nind]-table[i0][nind]) * di;
    }

    fun void norm_scale_mags(vec2 mag_freq[][], float scale) {
        0. => float maxmag;
        for (0 => int i; i < mag_freq.size(); i++) {
            for (0 => int j; j < mag_freq[0].size(); j++) {
                if (mag_freq[i][j].y > maxmag) mag_freq[i][j].y => maxmag;
            }
        }
        for (0 => int i; i < mag_freq.size(); i++) {
            for (0 => int j; j < mag_freq[0].size(); j++) {
                mag_freq[i][j].y / maxmag * scale => mag_freq[i][j].y;
            }
        }
    }

    // ---- pad play func ---- 
    // loops audios, and takes in updates from controller
    float pad_mix;

    fun void pad_playback() {
        pad_playback((dur1+dur2)/2.);
    }

    fun void pad_playback(dur duration) {
        while (true) {
            for (0::samp => dur t; t <= duration; 1::ms +=> t) {
                t/duration => float progress;
                for (0 => int j; j < N; j++) {
                    interp_lookup(freq_gain1, progress, j) => vec2 fg1;
                    interp_lookup(freq_gain2, progress, j) => vec2 fg2;
                    pad_mix * fg1.y + (1. - pad_mix) * fg2.y => sins[j].gain;
                    Math.exp(pad_mix * (fg1.x > 0 ? Math.log(fg1.x) : -1000.) + (1. - pad_mix) * (fg2.x > 0 ? Math.log(fg2.x) : -1000.)) => sins[j].freq;
                }
                1::ms => now;
            }
        }
    }

    fun void set_pad_mix(float pad_mix_in) {
        Math.clampf(pad_mix_in, 0., 1.) => pad_mix;
    }
    fun float get_pad_mix() {
        return pad_mix;
    }

}

ArbSynth2 arb(me.arg(0), me.arg(1), dac);
for (0. => float mix; mix <= 1.; 0.1 +=> mix)
    arb.playback(mix);
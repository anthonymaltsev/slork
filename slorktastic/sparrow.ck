//-----------------------------------------------------------------------------
// name: sparrow.ck
// desc: a house sparrow call synthesizer class
//       mostly just implementation of this vid in chuck: https://www.youtube.com/watch?v=spB82V0z8Tg
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

public class Sparrow {
    Phasor drive => Gen10 g => NRev rev;
    1::ms => dur chirp_step;
    0.3 => float BASE_GAIN;
    4000. => float BASE_CHIRP_FREQ;
    160::ms => dur BASE_CHIRP_DURATION;
    150::ms => dur BASE_INTER_CHIRP_DURATION;

    fun void init() {
        init(4000, 160::ms, 150::ms, 0.3, [1.0, 0.078, 0.015, 0.0025], dac);
    }

    fun void init(float base_freq, UGen outchan) {
        init(base_freq, 160::ms, 150::ms, 0.3, [1.0, 0.078, 0.015, 0.0025], outchan);
    }

    fun void init(float base_freq, dur base_dur, dur base_inter_dur, float base_gain, UGen outchan) {
        init(base_freq, base_dur, base_inter_dur, base_gain, [1.0, 0.078, 0.015, 0.0025], outchan);
    }

    fun void init(float base_freq, dur base_dur, dur base_inter_dur, float base_gain, float harmonic_gains[], UGen outchan) {
        base_freq => BASE_CHIRP_FREQ => drive.freq;
        base_dur => BASE_CHIRP_DURATION;
        base_inter_dur => BASE_INTER_CHIRP_DURATION;
        base_gain => BASE_GAIN;
        harmonic_gains => g.coefs;
        
        0 => g.gain;
        0.001 => rev.mix;
        rev => outchan;

    }

    fun void chirp() {
        chirp(BASE_CHIRP_FREQ, BASE_CHIRP_DURATION, BASE_GAIN);
    }

    fun void chirp(dur duration) {
        chirp(BASE_CHIRP_FREQ, duration, BASE_GAIN);
    }

    fun void chirp(float chirp_freq, dur duration, float gain_mul) {
        
        [0., 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.] @=> float timepoints[];
        [0.75, 0.8,  0.85, 0.88, 0.92, 0.95, 1.0,  0.98, 0.92, 0.85, 0.75] @=> float relfreqs[];
        [0.0,  0.4,  0.7,  0.85, 0.95, 1.0,  1.0,  0.9,  0.7,  0.4,  0.0 ] @=> float relvols[];

        (duration / chirp_step) $ int => int steps;

        for (0 => int i; i < steps; 1 +=> i) {
            i * 1. / steps => float curr_t;

            interp_lookup(timepoints, relfreqs, curr_t) => float curr_freq;
            interp_lookup(timepoints, relvols, curr_t) => float curr_vol;

            curr_freq * chirp_freq => drive.freq;
            curr_vol * gain_mul => g.gain;
            chirp_step => now;
        }
        0 => g.gain;

    }

    // indexer is monotonic function of breakpoints
    // returns linear interpolation of closest 2 points in table to queried index
    //   constraint: indexer.size() == table.size() && index >= indexer[0] && index <= indexer[indexer.size() - 1]
    fun float interp_lookup(float indexer[], float table[], float index) {
        for (0 => int i; i < indexer.size()-1; 1 +=> i) {
            if (index >= indexer[i] && index < indexer[i+1]) {
                return table[i] + (table[i+1]-table[i]) * ((index-indexer[i])/(indexer[i+1]-indexer[i]));
            }
        }
        return table[table.size() - 1];
    }

    fun void let_loose() {
        spork ~ be_loose();
    }

    fun void be_loose() {
        while (true) {
            Math.random2f(0.5, 2) * BASE_INTER_CHIRP_DURATION => now;
            spork ~ chirp(Math.random2f(0.95, 1.05) * BASE_CHIRP_FREQ, Math.random2f(0.8, 1.2) * BASE_CHIRP_DURATION, Math.random2f(0.8, 1.2) * BASE_GAIN);
        }
    }

    fun void be_loose(float freq_in) {
        while (true) {
            Math.random2f(0.5, 2) * BASE_INTER_CHIRP_DURATION => now;
            spork ~ chirp(Math.random2f(0.95, 1.05) * freq_in, Math.random2f(0.95, 1.05) * BASE_CHIRP_DURATION, Math.random2f(0.95, 1.05) * BASE_GAIN);
        }
    }

    // setters, getters

    fun void set_rev(float mix) {
        mix => rev.mix;
    }
    fun float get_rev() {
        return rev.mix();
    }

    fun void set_gain(float gain) {
        Math.clampf(gain, 0., 1.) => gain;
        gain => BASE_GAIN;
    }
    fun float get_gain() {
        return BASE_GAIN;
    }

    fun void set_chirp_freq(float chirp_freq) {
        Math.clampf(chirp_freq, 30., 20000.) => chirp_freq;
        chirp_freq => BASE_CHIRP_FREQ;
    }
    fun float get_chirp_freq() {
        return BASE_CHIRP_FREQ;
    }

    fun void set_chirp_dur(dur chirp_dur) {
        if (chirp_dur < 15::ms ) {15::ms => chirp_dur;}
        else if (chirp_dur > 2::second) {2::second => chirp_dur;}
        chirp_dur => BASE_CHIRP_DURATION;
    }
    fun dur get_chirp_dur() {
        return BASE_CHIRP_DURATION;
    }

    fun void set_inter_chirp_dur(dur inter_chirp_dur) {
        if (inter_chirp_dur < 15::ms ) {15::ms => inter_chirp_dur;}
        else if (inter_chirp_dur > 2::second) {2::second => inter_chirp_dur;}
        inter_chirp_dur => BASE_INTER_CHIRP_DURATION;
    }
    fun dur get_inter_chirp_dur() {
        return BASE_INTER_CHIRP_DURATION;
    }



}

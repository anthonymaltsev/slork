//-----------------------------------------------------------------------------
// name: shackles.ck
// desc: hooks up gametrack to control 2 granular-synthesis shackles, each
//       playing a wav file of metal chain/scrape sounds through LiSa.
//       intended to be used across 3 different computers to make 6 shackles.
//
//       lr  [-1, 1]  -> grain position in buffer
//       fb  [-1, 1]  -> grain playback rate (pitch)
//       mag [0, 1]   -> grain density + size + gain
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe_history.ck"}

// ------------------------ shackle def -----------------------------------

public class Shackle {

    LiSa lisa => Gain mix => NRev rev;
    0.1 => rev.mix;
    int axis_offset; // 0:left, 3:right

    GameTrak @ gt_ref;
    string filename;
    dur file_dur;
    32 => int MAX_VOICES;

    0. => float lr;
    0. => float fb;
    0. => float mag;
    0. => float totmot;
    0 => int use_mot;
    0.85 => float SMOOTH;
    2::ms => dur LISTEN_PERIOD;

    fun @construct(string fn, int offset, GameTrak gt_in, UGen outchan) {
        fn => filename;
        offset => axis_offset;
        gt_in @=> gt_ref; 
        1.5 => mix.gain;
        rev => outchan;
        _load_file();
        MAX_VOICES => lisa.maxVoices;
        0.6 => lisa.gain;
        Math.clampf(gt_ref.axis[axis_offset + 0], -1., 1.) => lr;
        Math.clampf(gt_ref.axis[axis_offset + 1], -1., 1.) => fb;
        Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => mag;

        <<< "args: ", me.args(), "\n0: ", me.arg(0) >>>;
        if (me.args() > 1 && Std.atoi(me.arg(1)) == 1) {
            <<< "mot regime activated!", "">>>;
            1 => use_mot;
        }

        spork ~ listen();
        spork ~ run();
    }

    fun @construct(string fn, int offset, GameTrak gt_in, UGen outchan, int slow_mode) {
        fn => filename;
        offset => axis_offset;
        gt_in @=> gt_ref; 
        1.5 => mix.gain;
        rev => outchan;
        _load_file();
        MAX_VOICES => lisa.maxVoices;
        0.6 => lisa.gain;
        Math.clampf(gt_ref.axis[axis_offset + 0], -1., 1.) => lr;
        Math.clampf(gt_ref.axis[axis_offset + 1], -1., 1.) => fb;
        Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => mag;

        <<< "args: ", me.args(), "\n0: ", me.arg(0) >>>;
        if (me.args() > 1 && Std.atoi(me.arg(1)) == 1) {
            <<< "mot regime activated!", "">>>;
            1 => use_mot;
        }

        spork ~ listen();
        if (slow_mode) {
            spork ~ run_slow();
        } else {
            spork ~ run();
        }
    }

    fun void _load_file() {
        SndBuf buf;
        filename => buf.read;
        buf.samples()::samp => file_dur => lisa.duration;
        for (0 => int i; i < buf.samples(); i++) {
            lisa.valueAt(buf.valueAt(i), i::samp);
        }
    }


    fun void listen() {
        while (true) {
            0. => float totmot_raw;
            // 32 = HISTORY size of gt
            for (1 => int i; i < 32; i++) {
                for (0 => int j; j < 3; j++) {
                    Math.fabs(gt_ref.lastAxis[i][axis_offset + j] - gt_ref.lastAxis[i-1][axis_offset+j]) +=> totmot_raw;
                }
            }
            10. *=> totmot_raw;
            if (totmot_raw < 0.2) 0. => totmot_raw;
            // <<<totmot_raw>>>;

            gt_ref.axis[axis_offset + 0] => float lr_raw;
            gt_ref.axis[axis_offset + 1] => float fb_raw;
            Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => float mag_raw;
            SMOOTH * lr     + (1. - SMOOTH) * lr_raw     => lr;
            SMOOTH * fb     + (1. - SMOOTH) * fb_raw     => fb;
            SMOOTH * mag    + (1. - SMOOTH) * mag_raw    => mag;
            0.7 * totmot + (1. - 0.7) * totmot_raw => totmot;
            if (totmot < 0.05) 0. => totmot;
            LISTEN_PERIOD => now;
        }
    }

    fun void run() {
        while (true) {
            spork ~ grain();
            spork ~ grain();
            grain_interval() => now;
        }
    }

    fun void run_slow() {
        while (true) {
            spork ~ grain_slow(1::second, 0.4);
            spork ~ grain_slow(1.2::second, 0.3);
            grain_interval() => now;
        }
    }

    200. => float grain_interval_val0;
    15. => float grain_interval_val1;
    fun void set_grain_interval_0_1(float val0, float val1) {
        val0 => grain_interval_val0;
        val1 => grain_interval_val1;
    }
    // [0,1] => [200,15]
    fun dur grain_interval() {
        return (grain_interval_val1 + (1. - mag) * (grain_interval_val0 - grain_interval_val1))::ms;
    }

    fun void grain() {
        (30. + mag * 220.)::ms => dur grain_dur;
        grain(grain_dur, 0.4);
    }

    fun void grain(dur grain_dur, float ramp_portion) {
        lisa.getVoice() => int voice;
        if (voice < 0) return;

        lr  => float g_lr;
        fb  => float g_fb;
        mag => float g_mag;

        (g_lr + 1.) * 0.5 => float pos_norm;
        Math.random2f(-0.15, 0.15) +=> pos_norm;
        // Math.random2f(-0.05, 0.05) +=> pos_norm;
        Math.clampf(pos_norm, 0., 1.) => pos_norm;
        pos_norm * file_dur => dur grain_pos;

        Math.pow(2., g_fb) => float rate;

        grain_dur * ramp_portion => dur ramp;

        lisa.rate(voice, rate);
        lisa.playPos(voice, grain_pos);
        if (use_mot) {
            lisa.voiceGain(voice, g_mag * 1.6 * totmot);
        }
        else {
            lisa.voiceGain(voice, g_mag * 1.6);
        }
        lisa.play(voice, 1);
        lisa.rampUp(voice, ramp);
        // ramp => now;
        (grain_dur - 2 * ramp) => now;
        lisa.rampDown(voice, ramp);
        ramp => now;
        lisa.play(voice, 0);
    }

    fun void grain_slow() {
        (30. + mag * 220.)::ms => dur grain_dur;
        grain_slow(grain_dur, 0.4);
    }

    fun void grain_slow(dur grain_dur, float ramp_portion) {
        lisa.getVoice() => int voice;
        if (voice < 0) return;

        lr  => float g_lr;
        fb  => float g_fb;
        mag => float g_mag;

        (g_lr + 1.) * 0.5 => float pos_norm;
        Math.random2f(-0.15, 0.15) +=> pos_norm;
        // Math.random2f(-0.05, 0.05) +=> pos_norm;
        Math.clampf(pos_norm, 0., 1.) => pos_norm;
        pos_norm * file_dur => dur grain_pos;

        Math.pow(2., g_fb) => float rate;

        grain_dur * ramp_portion => dur ramp;

        lisa.rate(voice, rate);
        lisa.playPos(voice, grain_pos);
        if (use_mot) {
            lisa.voiceGain(voice, g_mag * 1.6 * totmot);
        }
        else {
            lisa.voiceGain(voice, g_mag * 1.6);
        }
        lisa.play(voice, 1);
        lisa.rampUp(voice, ramp);
        ramp => now;
        (grain_dur - 2 * ramp) => now;
        lisa.rampDown(voice, ramp);
        ramp => now;
        lisa.play(voice, 0);
    }
}

public class ShackleDrone {
    LiSa lisa => Gain gate => Gain mix => NRev rev;
    0.1 => rev.mix;
    int axis_offset; // 0:left, 3:right

    string filename;
    dur file_dur;
    32 => int MAX_VOICES;
    
    0.5 => float lisarate;

    GameTrak @ gt_ref;

    0. => float mag;
    2::ms => dur LISTEN_PERIOD;

    fun @construct(string fn, GameTrak gt_in, float lisarate_in, UGen outchan) {
        fn => filename;
        0.3 => mix.gain;
        gt_in @=> gt_ref;
        rev => outchan;
        lisarate_in => lisarate;
        _load_file();
        MAX_VOICES => lisa.maxVoices;
        0.6 => lisa.gain;
        
        spork ~ listen();
        spork ~ run();
    }

    fun void listen() {
        while (true) {
            Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => float mag_raw;
            _clamp_linear(mag_raw, 0.2, 0., 0.4, 1.) => gate.gain;
            LISTEN_PERIOD => now;
        }
    }
    
    // clamped linear remap: domain [k1,k2] -> range [v1,v2]
    fun float _clamp_linear(float x, float k1, float v1, float k2, float v2) {
        return Math.clampf(v1 + (v2-v1) * (x-k1)/(k2-k1), _min(v1, v2), _max(v1, v2));
    }
    fun float _min(float a, float b) { if (a < b) return a; else return b; }
    fun float _max(float a, float b) { if (a > b) return a; else return b; }
    // low,high -> [0,1,...,n-1]
    fun int _quantize(float x, float low, float high, int n) {
        return _min(n-1, _max(0, ((x-low)/(high-low) * n) $ int)) $ int;
    }

    fun void _load_file() {
        SndBuf buf;
        filename => buf.read;
        buf.samples()::samp => file_dur => lisa.duration;
        for (0 => int i; i < buf.samples(); i++) {
            lisa.valueAt(buf.valueAt(i), i::samp);
        }
    }

    fun void run() {
        1 => lisa.loop;
        1::second => lisa.loopStart;
        lisa.duration() => lisa.loopEnd;
        lisarate => lisa.rate;
        20::ms => lisa.rampUp;
        0::ms => lisa.playPos;

        1 => lisa.play;

        while (true) {
            1::second => now;
        }
    }
}

//------------------------- shackle setup ----------------------------------

GameTrak gt;

// Shackle left("data/chain.wav", 0, gt, dac);
// Shackle right("data/scrape.wav", 3, gt, dac);

Shackle left("data/Cloudbank.wav", 0, gt, dac, 1);
Shackle right("data/Cloudbank.wav", 3, gt, dac, 1);

// ShackleDrone droner("data/spookpad.wav", dac);

// -------------------------- main loop ------------------------------

while (true) {
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    333::ms => now;
}


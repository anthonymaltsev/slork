//-----------------------------------------------------------------------------
// name: unshackles.ck
// desc: the pleasant face of the shackle coin
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe_history.ck"}

// ------------------------ shackle def -----------------------------------

public class Unshackle {

    StifKarp inst => LPF lp => Gain mix => NRev rev;
    0.1 => rev.mix;

    int axis_offset; // 0:left, 3:right
    GameTrak @ gt_ref;

    0. => float lr;
    0. => float fb;
    0. => float mag;

    0.85 => float SMOOTH;
    2::ms => dur LISTEN_PERIOD;

    @(0., 0., 0.) => vec3 last_pluck_pos;
    now => time last_pluck_time;
    0.17 => float DIST_THRESH;
    // [73, 69, 74, 79] @=> int notes[];
    [64, 66, 68, 71, 73] @=> int notes[];
    0 => int note_ind;

    fun @construct(int offset, GameTrak gt_in, UGen outchan) {
        offset => axis_offset;
        gt_in @=> gt_ref; 
        lp.set(4000, 0.7);
        0.7 => mix.gain;
        rev => outchan;


        Math.clampf(gt_ref.axis[axis_offset + 0], -1., 1.) => lr;
        Math.clampf(gt_ref.axis[axis_offset + 1], -1., 1.) => fb;
        Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => mag;

        spork ~ listen();
        spork ~ run();
    }



    fun void listen() {
        while (true) {
            
            // 0. => float totmot_raw;
            // // 32 = HISTORY size of gt
            // for (1 => int i; i < 32; i++) {
            //     for (0 => int j; j < 3; j++) {
            //         Math.fabs(gt_ref.lastAxis[i][axis_offset + j] - gt_ref.lastAxis[i-1][axis_offset+j]) +=> totmot_raw;
            //     }
            // }
            // 10. *=> totmot_raw;
            // if (totmot_raw < 0.2) 0. => totmot_raw;
            // <<<totmot_raw>>>;

            gt_ref.axis[axis_offset + 0] => float lr_raw;
            gt_ref.axis[axis_offset + 1] => float fb_raw;
            Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => float mag_raw;
            // SMOOTH * lr     + (1. - SMOOTH) * lr_raw     => lr;
            // SMOOTH * fb     + (1. - SMOOTH) * fb_raw     => fb;
            // SMOOTH * mag    + (1. - SMOOTH) * mag_raw    => mag;
            lr_raw => lr;
            fb_raw => fb;
            mag_raw => mag;
            // 0.7 * totmot + (1. - 0.7) * totmot_raw => totmot;
            // if (totmot < 0.05) 0. => totmot;

            _quantize(lr, -1., 1., notes.size()) => note_ind;
            _clamp_linear(fb, -1., 0.2, 1., 0.8) => inst.sustain;
            _clamp_linear(mag, 0., 0.1, 1., 0.9) => inst.pickupPosition;

            LISTEN_PERIOD => now;
        }
    }

    fun void run() {
        while (true) {
            gt_ref.gt_pos_to_xyz(lr, fb, mag) => vec3 curr_pos;
            Math.euclidean(curr_pos, last_pluck_pos) => float traveled_dist;
            if (traveled_dist >= DIST_THRESH) {
                // <<< "PLUCK!", "">>>;

                curr_pos => last_pluck_pos;
                now - last_pluck_time => dur interpluck_time;
                interpluck_time / 1000::ms => float interpluck;
                now => last_pluck_time;

                Std.mtof(notes[note_ind]) => inst.freq;
                _clamp_linear(interpluck, 0.1, 1., 0.7, 0.1) => float pluckvel;
                inst.pluck(pluckvel);
            }
            LISTEN_PERIOD => now;
        }
    }

    // clamped linear function from k1 to k2 domain, v1 to v2 range
    // must be k2 > k1
    fun float _clamp_linear(float x, float k1, float v1, float k2, float v2) {
        return Math.clampf(v1 + (v2-v1) * (x-k1)/(k2-k1), _min(v1, v2), _max(v1, v2));
    }

    fun float _min(float a, float b) {
        if (a < b) return a;
        else return b;
    }

    fun float _max(float a, float b) {
        if (a > b) return a;
        else return b;
    }

    // low,high ==> [0,1,2,...,n-1]
    fun int _quantize(float x, float low, float high, int n) {
        return _min(n-1, _max(0, ((x-low)/(high-low) * n) $ int)) $ int;
    }
}

public class UnshackleFlute {

    Flute f => PoleZero filter => Gain mix => JCRev rev;
    0.1 => rev.mix;

    int axis_offset; // 0:left, 3:right
    GameTrak @ gt_ref;

    0. => float lr;
    0. => float fb;
    0. => float mag;

    0.85 => float SMOOTH;
    2::ms => dur LISTEN_PERIOD;

    fun @construct(int offset, GameTrak gt_in, UGen outchan) {
        .75 => rev.gain;
        .35 => rev.mix;
        .99 => filter.blockZero;

        0.1 => f.rate;
        0.2 => f.jetDelay;
        0.4 => f.jetReflection;
        0.45 => f.endReflection;
        0.1 => f.noiseGain;
        6 => f.vibratoFreq;
        0.06 => f.vibratoGain;
        0. => f.pressure;

        0.5 => f.noteOn;
        0.01 => f.stopBlowing;
        1::samp => now;

        offset => axis_offset;
        gt_in @=> gt_ref; 
        1. => mix.gain;
        rev => outchan;

        Math.clampf(gt_ref.axis[axis_offset + 0], -1., 1.) => lr;
        Math.clampf(gt_ref.axis[axis_offset + 1], -1., 1.) => fb;
        Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => mag;

        spork ~ listen();
        spork ~ run();
    }



    fun void listen() {
        while (true) {
            // 0. => float totmot_raw;
            // // 32 = HISTORY size of gt
            // for (1 => int i; i < 32; i++) {
            //     for (0 => int j; j < 3; j++) {
            //         Math.fabs(gt_ref.lastAxis[i][axis_offset + j] - gt_ref.lastAxis[i-1][axis_offset+j]) +=> totmot_raw;
            //     }
            // }
            // 10. *=> totmot_raw;
            // if (totmot_raw < 0.2) 0. => totmot_raw;
            // // <<<totmot_raw>>>;
            gt_ref.axis[axis_offset + 0] => float lr_raw;
            gt_ref.axis[axis_offset + 1] => float fb_raw;
            Math.clampf(gt_ref.axis[axis_offset + 2], 0., 1.) => float mag_raw;
            SMOOTH * lr     + (1. - SMOOTH) * lr_raw     => lr;
            SMOOTH * fb     + (1. - SMOOTH) * fb_raw     => fb;
            SMOOTH * mag    + (1. - SMOOTH) * mag_raw    => mag;
            // 0.7 * totmot + (1. - 0.7) * totmot_raw => totmot;
            // if (totmot < 0.05) 0. => totmot;
            LISTEN_PERIOD => now;
        }
    }

    fun void run() {
        1. => f.noteOn;
        0.5 => f.startBlowing;

        while (true) {
            1::second => now;
        }
    }
}



//------------------------- shackle setup ----------------------------------

GameTrak gt;

Unshackle left(0, gt, dac);
Unshackle right(3, gt, dac);

// -------------------------- main loop ------------------------------
<<< "start main loop", "" >>>;
while (true) {
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    333::ms => now;
}


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

    LiSa lisa => NRev rev => dac;
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

    fun @construct(string fn, int offset, GameTrak gt_in) {
        fn => filename;
        offset => axis_offset;
        gt_in @=> gt_ref; 
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

    // [0,1] => [200,15]
    fun dur grain_interval() {
        return (15. + (1. - mag) * 185.)::ms;
    }

    fun void grain() {
        lisa.getVoice() => int voice;
        if (voice < 0) return;

        lr  => float g_lr;
        fb  => float g_fb;
        mag => float g_mag;

        (g_lr + 1.) * 0.5 => float pos_norm;
        Math.random2f(-0.05, 0.05) +=> pos_norm;
        Math.clampf(pos_norm, 0., 1.) => pos_norm;
        pos_norm * file_dur => dur grain_pos;

        Math.pow(2., g_fb) => float rate;

        (30. + g_mag * 220.)::ms => dur grain_dur;
        grain_dur * 0.4 => dur ramp;

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
        (grain_dur - 2 * ramp) => now;
        lisa.rampDown(voice, ramp);
        ramp => now;
        lisa.play(voice, 0);
    }
}

//------------------------- shackle setup ----------------------------------

GameTrak gt;

Shackle left("data/chain.wav", 0, gt);
Shackle right("data/scrape.wav", 3, gt);

// -------------------------- main loop ------------------------------

while (true) {
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    333::ms => now;
}


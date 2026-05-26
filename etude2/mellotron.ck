@import {"gt_kb_dupe_history.ck"}

public class Mellotron {
    Phasor p[3];
    Gen10 osc[3];
    Modulate wob[3];
    float detune[3];

    Gain ens => LPF tone => Gain amp => Gain trem => NRev nrev => Envelope gate => JCRev jcrev => Gain finalbus;

    Step dc => Gain modbus => trem;
    SinOsc breathe => modbus;
    Noise rnd => LPF rndlp => Gain rndg => modbus;


    float baseFreq;
    0 => int playing;

    int axis_offset;
    GameTrak @ gt_ref;
    0. => float lr;
    0. => float fb;
    0. => float mag;
    0.85 => float SMOOTH;
    2::ms => dur LISTEN_PERIOD;
    0.5  => float MAXVOL;
    // [72, 74, 76, 79, 81, 84, 86, 88] @=> int notes[]; // penta
    [72, 74, 76, 77, 79, 81, 83, 84] @=> int notes[]; // major
    0 => int note_ind;

    fun @construct(UGen outchan) {
        _patch(outchan);
    }

    // gt mode
    fun @construct(int offset, GameTrak gt_in, UGen outchan) {
        _patch(outchan);
        offset => axis_offset;
        gt_in @=> gt_ref;
        1 => playing;
        spork ~ _wobble();
        spork ~ _dropouts();
        spork ~ listen();
    }

    // classic mode (drone or drone_for)
    fun void _patch(UGen outchan) {
        0.995 => detune[1];
        1.006 => detune[2];
        1.000 => detune[0];

        for (0 => int i; i < 3; i++) {
            p[i] => osc[i] => ens;
            [1.0, 0.2, 0.0, 0.07, 0.0, 0.03] => osc[i].coefs;
            Math.random2f(0.0, 1.0) => p[i].phase;
            wob[i] => blackhole;
            Math.random2f(4.5, 6.5) => wob[i].vibratoRate;
            1.0 => wob[i].vibratoGain;
            0.4 => wob[i].randomGain;
        }
        0.18 => ens.gain;

        2800 => tone.freq;
        0.7  => tone.Q;
        0.0  => amp.gain; // control in drone()

        3 => trem.op;
        0.80 => dc.next;
        0.50 => breathe.freq;
        0.15 => breathe.gain; // slow drift
        6.00 => rndlp.freq;
        0.25 => rndg.gain; // random flutter

        5::ms => gate.duration; // 3::ms
        1.0 => gate.value;
        gate.keyOn();

        finalbus => outchan;
        0.010 => nrev.mix;
        0.005 => jcrev.mix;
    }

    fun void _wobble() {
        0.012 => float wob_depth; // 0.006
        while (playing) {
            for (0 => int i; i < 3; i++) {
                baseFreq * detune[i] * (1.0 + wob[i].last() * wob_depth) => p[i].freq;
            }
            1::ms => now;
        }
    }


    300 => float base_dropout_rate;
    40 => float base_dropout_time;
    fun void _dropouts() {
        while (playing) {
            Math.random2f(0.75 * base_dropout_rate, 1.25 * base_dropout_rate) * 1::ms => now;
            gate.keyOff();
            Math.random2f(0.75 * base_dropout_time, 1.25 * base_dropout_time) * 1::ms => now;
            gate.keyOn();
        }
    }
    fun void set_base_dropout_rate(float rate) {
        rate => base_dropout_rate;
    }
    fun float get_base_dropout_rate() {
        return base_dropout_rate;
    }

    fun void listen() {
        while (true) {
            Math.clampf(gt_ref.axis[axis_offset + 0], -1., 1.) => float lr_raw;
            Math.clampf(gt_ref.axis[axis_offset + 1], -1., 1.) => float fb_raw;
            Math.clampf(gt_ref.axis[axis_offset + 2],  0., 1.) => float mag_raw;
            SMOOTH * lr  + (1.-SMOOTH) * lr_raw  => lr;
            SMOOTH * fb  + (1.-SMOOTH) * fb_raw  => fb;
            SMOOTH * mag + (1.-SMOOTH) * mag_raw => mag;

            _quantize(fb, -1., 1., notes.size()) => note_ind;
            Std.mtof(notes[note_ind]) => baseFreq;

            300. * Math.pow(8000./300., (lr+1.)/2.) => tone.freq;
            _clamp_linear(lr, -1., 0.7, 1., 4.0) => tone.Q;

            // mag (string pull) -> volume
            _clamp_linear(mag, 0.3, 0., 0.8, 1.) * MAXVOL => amp.gain;

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

    fun void drone(float freq, float vel, dur attack) {
        freq => baseFreq;
        1 => playing;
        spork ~ _wobble();
        spork ~ _dropouts();

        2::ms => dur step;
        (attack/step) $ int => int aSteps;
        for (0 => int i; i <= aSteps; i++) {
            Math.sin((i$float)/(aSteps$float) * Math.PI/2) => float env;
            env * vel  => amp.gain;
            step => now;
        }
        vel  => amp.gain;
        while (playing) 100::ms => now;
    }

    fun void drone_for(float freq, float vel, dur length) {
        freq => baseFreq;
        1 => playing;

        // much lower rev for punchies
        0.002 => nrev.mix;
        0.00 => jcrev.mix;

        spork ~ _wobble();
        spork ~ _dropouts();

        3::ms => dur env;
        length - 2*env => dur sustain;

        0.5::ms => dur step;
        (env/step) $ int => int eSteps;

        for (0 => int i; i <= eSteps; i++) {
            (i$float)/(eSteps$float) * vel => amp.gain;
            step => now;
        }
        vel => amp.gain;
        sustain => now;

        for (0 => int i; i <= eSteps; i++) {
            (1.0 - (i$float)/(eSteps$float)) * vel => amp.gain;
            step => now;
        }
        0.0 => amp.gain;

        0 => playing;
        gate.keyOn();
    }

    fun void glideTo(float freq, dur t) {
        baseFreq => float f0;
        2::ms => dur step;
        (t/step) $ int => int n;
        for (0 => int i; i <= n; i++) {
            f0 + (freq - f0) * (i$float)/(n$float) => baseFreq;
            step => now;
        }
        freq => baseFreq;
    }
}

Gain master => LPF lpf_master => dac;
0.7  => master.gain;
1800 => lpf_master.freq;
0.6 => lpf_master.Q;

GameTrak gt;
Mellotron ml(0, gt, master);
Mellotron mr(3, gt, master);

while (true) {
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    100::ms => now;
}

// Mellotron a(master);
// Mellotron b(master);
// Mellotron c(master);
// spork ~ a.drone(Std.mtof(84), 0.40, 4500::ms);
// spork ~ b.drone(Std.mtof(88), 0.34, 6000::ms);
// fun void sprinkle() {
//     [91, 94] @=> int notes[];   // G6 / A#6
//     1::second => now;
//     while (true) {
//         notes[Math.random2(0, notes.size() - 1)] => int n;
//         c.drone_for(Std.mtof(n), 0.30, Math.random2f(0.8, 1.3)::second);
//         Math.random2f(2.5, 6.0)::second => now;
//     }
// }
// spork ~ sprinkle();

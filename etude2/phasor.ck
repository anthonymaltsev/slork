
public class Droner {
    Phasor p => Gain genbus => Gen10 osc => LPF lp => Gain mix => JCRev r1 => NRev r2;
    // Noise n => HPF n_hp => LPF n_lp => Gain n_g => mix;
    //dirt
    // SinOsc dirt => Gain dirt_amt => genbus;
    Noise noise => LPF noise_lp => Gain noise_amt => genbus;

    fun @construct(UGen outchan) {
        [1.0, 0.25, 0.0, 0.08, 0.0, 0.04] => osc.coefs;
        0 => osc.gain;
        2200 => lp.freq;
        0.7 => lp.Q;
        0.02 => r1.mix;
        0.015 => r2.mix;
        0.03 => mix.gain;

        r2 => outchan;

        // 3000 => n_hp.freq;
        // 8000 => n_lp.freq;
        // 0.005 => n_g.gain;

        // make wavetable dirty
        // 2000 => dirt.freq;
        // 0.02 => dirt_amt.gain;
        10 => noise_lp.freq;
        0.05 => noise_amt.gain;
    }

    fun void play(float freq, float vel, dur attack, dur decay, float sustain_level, dur sustain, dur release) {
        freq => p.freq;
        
        sustain_level * vel => float sus;
        2::ms => dur step;

        (attack/step) $ int  => int attack_steps;
        for (0 => int i; i <= attack_steps; i++) {
            (i $ float) / (attack_steps $ float) * vel => osc.gain;
            step => now;
        }

        (decay/step) $ int => int decay_steps;
        for (0 => int i; i <= decay_steps; i++) {
            (1 - (i $ float) / (decay_steps $ float)) * (vel - sus) + sus => osc.gain;
            step => now;
        }

        sus => osc.gain;
        (sustain/step) $ int => int sustain_steps;
        for (0 => int i; i <= sustain_steps; i++) {
            sus * (1 + 0.004 * Math.sin(i * 0.03)) => osc.gain;
            step => now;
        }

        (release/step) $ int => int release_steps;
        for (0 => int i; i <= release_steps; i++) {
            (1 - (i $ float) / (release_steps $ float)) * sus => osc.gain;
            step => now;
        }
        0. => osc.gain;

    }

    fun void play_pattern_FOREVER(float freq) {
        while (true) {
            play_pattern(freq);
        }
    }

    fun void play_pattern(float freq) {
        spork ~ _play_pattern(freq);
        // Math.random2f(0.95, 1.05) * 3.6::second => now;
        3.6::second => now;
    }

    fun void _play_pattern(float freq) {
        play( freq, Math.random2f(0.9, 1.1) * 0.75, 50::ms, 150::ms, 0.85, Math.random2f(0.9, 1.1) * 575::ms, 50::ms );
        Math.random2f(0.95, 1.05) * 550::ms => now;
        play( freq, Math.random2f(0.9, 1.1) * 0.75, 50::ms, 150::ms, 0.85, 0::ms, 50::ms );
        Math.random2f(0.95, 1.05) * 250::ms => now;
        play( freq, Math.random2f(0.9, 1.1) * 0.75, 50::ms, 150::ms, 0.85, Math.random2f(0.9, 1.1) * 500::ms, 50::ms );
    }

    fun void play_drone(float freq, float vel, dur attack, dur decay, float sustain_level) {
        freq => p.freq;
        
        sustain_level * vel => float sus;
        2::ms => dur step;

        (attack/step) $ int  => int attack_steps;
        for (0 => int i; i <= attack_steps; i++) {
            (i $ float) / (attack_steps $ float) * vel => osc.gain;
            step => now;
        }

        (decay/step) $ int => int decay_steps;
        for (0 => int i; i <= decay_steps; i++) {
            (1 - (i $ float) / (decay_steps $ float)) * (vel - sus) + sus => osc.gain;
            step => now;
        }

        sus => osc.gain;
        0 => int t;
        while( true ) {
            sus * (1.0 + 0.003 * Math.sin(t * 0.05)) => osc.gain;
            t++;
            10::ms => now;
        }
    }

}

Droner phase(dac);
Droner drone(dac);

spork ~ drone.play_drone(Std.mtof(71), 0.75, 50::ms, 150::ms, 0.85);
spork ~ phase.play_pattern_FOREVER(Std.mtof(76));
// infinite time-loop
while( true )
{
    1::second => now;
}

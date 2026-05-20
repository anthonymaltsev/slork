// STK Flute

class Floutist {

    Flute f => PoleZero filter => JCRev rev => dac;

    fun @construct() {
        .75 => rev.gain;
        .35 => rev.mix;
        .99 => filter.blockZero;
        // 0.4 => ch.modFreq;
        // 0.6 => ch.modDepth;
        // 0.4 => ch.mix;

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
    }

    fun void play(float freq, float vel, dur attack, dur decay, float sustain_level, dur sustain, dur release) {
        freq => f.freq;
        // 0.5 => f.startBlowing;
        1.3 * vel => float peak;
        sustain_level * peak => float sus;

        2::ms => dur step;
        0. => float p => f.pressure;

        (attack/step) $ int  => int attack_steps;
        for (0 => int i; i < attack_steps; i++) {
            (i $ float) / (attack_steps $ float) * peak => p => f.pressure;
            step => now;
        }

        (decay/step) $ int => int decay_steps;
        for (0 => int i; i < decay_steps; i++) {
            (1 - (i $ float) / (attack_steps $ float)) * (peak - sus) + sus => p => f.pressure;
            step => now;
        }

        sus => p => f.pressure;
        sustain => now;

        (release/step) $ int => int release_steps;
        for (0 => int i; i < release_steps; i++) {
            (1 - (i $ float) / (release_steps $ float)) * sus => p => f.pressure;
            step => now;
        }
        0. => p => f.pressure;
        // 0.5 => f.stopBlowing;

    }

    fun void clear(float val) {
        f.clear(val);
    }

}

Floutist flute;

// infinite time-loop
while( true )
{
    76-12 => int note;
    flute.play( Std.mtof(note), 0.75, 50::ms, 150::ms, 0.85, 575::ms, 50::ms );
    550::ms => now;
    flute.play( Std.mtof(note), 0.75, 50::ms, 150::ms, 0.85, 0::ms, 50::ms );
    250::ms => now;
    flute.play( Std.mtof(note), 0.75, 50::ms, 150::ms, 0.85, 500::ms, 50::ms );
    1::second => now;

}

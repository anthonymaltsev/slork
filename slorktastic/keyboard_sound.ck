//-----------------------------------------------------------------------------
// name: keyboard_sound.ck
// desc: models keyboard typing sounds when receiving keyboard inputs
//
// note: Sets of keyboard percussion sounds that can be set to a predetermined beat pattern. 
//
// author: Siqi Chen
//-----------------------------------------------------------------------------



public class keyBeats {
    dur beatDur;
    int beatPattern[];
    // float nGain;
    // float rMix;

    // initialize state wasKeyDown to keep track of key state
    0 => int wasKeyDown;

    // keyboard sound synthesis
    Noise n;
    ADSR key;
    LPF lpf;
    HPF hpf;
    BRF brf;
    JCRev r;


    fun @construct(dur beatDur_in, int beatPattern_in[], int perc_type) {
        beatDur_in => beatDur;
        beatPattern_in @=> beatPattern;

        if (perc_type == 0){
            // noise envelope
            n => key => r => dac;
            0.04 => n.gain;
            0.01 => r.mix;
            key.set( 5::ms, 4::ms, .3, 5::ms );
        }
        else if (perc_type == 1) {
            // mid-range snare sound
            n => key => lpf => r => dac;
            2000 => lpf.freq;
            0.2 => n.gain;
            0.001 => r.mix;
            key.set( 5::ms, 4::ms, .5, 8::ms );
        }
        else if (perc_type == 2) {
            // bass tomtom sound
            n => key => lpf => r => dac;
            400 => lpf.freq;
            0.3 => n.gain;
            0.05 => r.mix;
            key.set( 3::ms, 20::ms, .5, 10::ms );
        } else if (perc_type == 3) {
            // band passed sound
            n => key => brf => lpf => r => dac;
            2000 => brf.freq;
            1.5 => brf.Q;
            4000 => lpf.freq;
            0.1 => n.gain;
            0.01 => r.mix;
            key.set( 3::ms, 5::ms, .5, 10::ms );
        } else if (perc_type == 4) {
            // crash_cymbal-like sound
            n => key => hpf => r => dac;
            6000 => hpf.freq;
            0.05 => n.gain;
            0.05 => r.mix;
            key.set( 1::ms, 1::ms, .6, 150::ms );
        }


    }

    fun void playBeats() {
        // infinite time-loop
        while( true ){
            
            // advance time by values in beat pattern
            for (0 => int i; i < beatPattern.size(); i++){
                // check if key was down
                if( wasKeyDown )
                {
                    // trigger ADSR
                    key.keyOn();
                    (key.attackTime() + key.decayTime()) => now;
                    key.keyOff();
                    key.releaseTime() => now;
                    0 => wasKeyDown; // reset state
                }

                // print beat sanity check
                // <<< "beat:", beatPattern[i] >>>;

                // wait until duration of next beat
                (beatPattern[i] * beatDur) => now;
            }

        }
    }

}

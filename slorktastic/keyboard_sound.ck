//-----------------------------------------------------------------------------
// name: keyboard_sound.ck
// desc: models keyboard typing sounds when receiving keyboard inputs
//
// note: Sets of keyboard percussion sounds that can be set to a predetermined beat pattern. 
//
// author: Siqi Chen
//-----------------------------------------------------------------------------

@import "arbsynth.ck"

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

    fun void addTrack(dur start_time) {

        // wait until start time
        start_time => now;

        playBeats();
    }

}




public class keySynths {
    dur synthDur;
    int synthPattern[];

    0 => int wasKeyDown;

    ArbSynth @synths[];

    // initializing some audio FXs in case we wanna use them
    ADSR env;
    LPF lpf;
    HPF hpf;
    BRF brf;
    JCRev r;
    PitShift ps;
    Gain bus;

    dur currentDur;



    fun @construct(dur synthDur_in, int synthPattern_in[], int synth_group_in) {
        synthDur_in => synthDur;
        synthPattern_in @=> synthPattern;

        if (synth_group_in == 0) {
            new ArbSynth[13] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/coffee-brewing-futuristic_1.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/food-cooking-in-oil.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/cooking-frying.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/cooking-in-cooking-pot.arr", bus) @=> synths[3];
            new ArbSynth("data/verbs/cooking-pasta.arr", bus) @=> synths[4];
            new ArbSynth("data/verbs/cutting-vegetables.arr", bus) @=> synths[5];
            new ArbSynth("data/verbs/foley-chef-cracking-an-egg-into-bowl.arr", bus) @=> synths[6];
            new ArbSynth("data/verbs/frying-food-cooking-kitchen.arr", bus) @=> synths[7];
            new ArbSynth("data/verbs/keurig-kcup-brewing.arr", bus) @=> synths[8];
            new ArbSynth("data/verbs/liquid-swirl.arr", bus) @=> synths[9];
            new ArbSynth("data/verbs/pretzel-crunching.arr", bus) @=> synths[10];
            new ArbSynth("data/verbs/whisking.arr", bus) @=> synths[11];
            new ArbSynth("data/verbs/moka-express-brewing.arr", bus) @=> synths[12];

            // connect to effects and dac
            bus => ps => dac;

        } 
        else if (synth_group_in == 1) {
            // man synths
            new ArbSynth[7] @=> synths;
            new ArbSynth("data/verbs/man-screaming.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/crying-man.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/screaming-man.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/frantic-screaming.arr", bus) @=> synths[3];
            new ArbSynth("data/verbs/cry-of-pain.arr", bus) @=> synths[4];
            new ArbSynth("data/verbs/ouch-oof-hurt.arr", bus) @=> synths[5];
            new ArbSynth("data/verbs/puppy-crying.arr", bus) @=> synths[6];

            // connect to effects and dac
            bus => ps => dac;
            0.5 => ps.shift;
            0.7 => ps.mix;         
        }
    }

    fun void playSynths() {
        // each time a key event is detected, we randomly select one of the synths and play it
        while( true ){

            for (0 => int i; i < synthPattern.size(); i++){

                // will add use of synthDur and synthPattern here later
                if( wasKeyDown )
                {
                    // randomly select one of the synths and play it
                    Math.random2(0, synths.size() - 1) => int synth_idx;
                    spork ~ synths[synth_idx].playback();
                    synths[synth_idx].getDur() => currentDur;
                    <<< "synth:", synth_idx >>>;
                    0 => wasKeyDown; // reset state
                }
                (synthPattern[i] * synthDur) => now;
            }
        }
    }

    fun void addSynthTrack(dur start_time) {
        // wait until start time
        start_time => now;

        playSynths();
    }

    fun dur getCurrentDur() {
        return currentDur;
    }
}

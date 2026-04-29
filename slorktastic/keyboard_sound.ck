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
            0.1 => n.gain;
            0.01 => r.mix;
            key.set( 5::ms, 4::ms, .3, 5::ms );
        }
        else if (perc_type == 1) {
            // mid-range snare sound
            n => key => lpf => r => dac;
            2000 => lpf.freq;
            0.8 => n.gain;
            0.001 => r.mix;
            key.set( 5::ms, 4::ms, .5, 8::ms );
        }
        else if (perc_type == 2) {
            // bass tomtom sound
            n => key => lpf => r => dac;
            400 => lpf.freq;
            0.8 => n.gain;
            0.05 => r.mix;
            key.set( 3::ms, 20::ms, .5, 10::ms );
        } else if (perc_type == 3) {
            // band passed sound
            n => key => brf => lpf => r => dac;
            2000 => brf.freq;
            1.5 => brf.Q;
            4000 => lpf.freq;
            0.6 => n.gain;
            0.01 => r.mix;
            key.set( 3::ms, 5::ms, .5, 10::ms );
        } else if (perc_type == 4) {
            // crash_cymbal-like sound
            n => key => hpf => r => dac;
            6000 => hpf.freq;
            0.2 => n.gain;
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
            // cooking synths pulses
            new ArbSynth[3] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/pulse/cutting-vegetables.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/egg-crack.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/pulse/liquid-swirl.arr", bus) @=> synths[2];
            
            // connect to effects and dac
            bus => ps => dac;
            0.8 => bus.gain; 
            0.7 => ps.mix;
            0.5 => ps.shift;
        } 

        else if (synth_group_in == 1) {
            // cooking synth continuous
            new ArbSynth[7] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/cont/coffee-brewing-percolation.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/cooking-frying.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/cont/cooking-pasta.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/cont/food-cooking-in-oil.arr", bus) @=> synths[3];
            new ArbSynth("data/verbs/cont/keurig-kcup-brewing.arr", bus) @=> synths[4];
            new ArbSynth("data/verbs/cont/moka-express-brewing.arr", bus) @=> synths[5];
            new ArbSynth("data/verbs/cont/whisking.arr", bus) @=> synths[6];

            // connect to effects and dac
            bus => ps => dac;
            0.8 => bus.gain;
            0.7 => ps.mix;
            0.5 => ps.shift;
        }
        
        else if (synth_group_in == 2) {
            // mech synths pulse
            new ArbSynth[4] @=> synths;
            new ArbSynth("data/verbs/pulse/buttons_calculator.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/car-horn-honking.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/pulse/cell-phone-vibrate-high-quality.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/pulse/rustling-a-newspaper.arr", bus) @=> synths[3];

            // connect to effects and dac
            bus => ps => dac;   
            0.8 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }
        else if (synth_group_in == 3) {
            // mech synths continuous
            new ArbSynth[4] @=> synths;
            new ArbSynth("data/verbs/cont/geese-honking.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/pencil-on-paper-1.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/cont/pencil-on-paper-2.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/cont/rain.arr", bus) @=> synths[3];

            // connect to effects and dac
            bus => ps => dac;   
            0.8 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        } else if (synth_group_in == 4) {
            // man synths pulse
            new ArbSynth[11] @=> synths;
            new ArbSynth("data/verbs/pulse/blade-piercing-body.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/e-oh.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/pulse/glass-breaking.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/pulse/groaning-gurgle.arr", bus) @=> synths[3];
            new ArbSynth("data/verbs/pulse/knife-stab.arr", bus) @=> synths[4];
            new ArbSynth("data/verbs/pulse/little-creature-hurt.arr", bus) @=> synths[5];
            new ArbSynth("data/verbs/pulse/man-screaming.arr", bus) @=> synths[6];
            new ArbSynth("data/verbs/pulse/ouch-oof-hurt-1.arr", bus) @=> synths[7];
            new ArbSynth("data/verbs/pulse/ouch-oof-hurt-2.arr", bus) @=> synths[8];
            new ArbSynth("data/verbs/pulse/ouch-oof-hurt-3.arr", bus) @=> synths[9];
            new ArbSynth("data/verbs/pulse/screaming-man.arr", bus) @=> synths[10];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        } else if (synth_group_in == 5) {
            // man synth continuous
            new ArbSynth[7] @=> synths;
            new ArbSynth("data/verbs/cont/cry-of-pain.arr", bus) @=> synths[0]; 
            new ArbSynth("data/verbs/cont/crying-man.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/cont/frantic-screaming.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/cont/puppy-crying.arr", bus) @=> synths[3];
            new ArbSynth("data/verbs/cont/woman-screaming-sfx-screaming.arr", bus) @=> synths[4];
            new ArbSynth("data/verbs/cont/wood-burning-stove-fire.arr", bus) @=> synths[5];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }
    } 


    fun void playSynths() {
        1 => bus.gain; // unmute bus to play synths

        // each time a key event is detected, we randomly select one of the synths and play it
        while( true ){

            for (0 => int i; i < synthPattern.size(); i++){

                // will add use of synthDur and synthPattern here later
                if( wasKeyDown )
                {
                    // randomly select one of the synths and play it
                    Math.random2(0, synths.size() - 1) => int synth_idx;
                    Math.random2f(-1, 1) => ps.shift; // randomize pitch shift
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

    fun void silence() {
        for (0 => int i; i < synths.size(); i++) {
            synths[i].silence();
        }
        0. => bus.gain; 
    }

    fun dur getCurrentDur() {
        return currentDur;
    }
}

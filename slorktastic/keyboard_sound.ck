//-----------------------------------------------------------------------------
// name: keyboard_sound.ck
// desc: models keyboard typing sounds when receiving keyboard inputs
//
// note: Sets of keyboard percussion sounds that can be set to a predetermined beat pattern. 
//
// author: Siqi Chen
//-----------------------------------------------------------------------------

@import "arbsynth.ck"

public class impulses {
    Impulse i => JCRev rev => dac;

    fun @construct() {
        0.5 => i.gain;
        0.01 => rev.mix;
    }

    fun void play() {
        3000 => int a;
        while (true) {
            1.0 => i.next;
            a::samp => now;
            Math.random2(2000, 40000) => a;
            Math.random2f(0, 0.5) => i.gain;
            Math.random2f(0, 0.03) => rev.mix;
        }
    }

    fun void silence() {
        0 => i.gain;
    }

    fun void disconnect() {
        rev =< dac;
    }
}


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

    fun void set_beatDur(dur newDur) {
        newDur => beatDur;
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
    Gain bus1;

    dur currentDur;



    fun @construct(dur synthDur_in, int synthPattern_in[], int synth_group_in) {
        synthDur_in => synthDur;
        synthPattern_in @=> synthPattern;

        // Stage 1: cook synths
        // chopping onions...
        if (synth_group_in == 0) {
            // cooking synths pulses
            new ArbSynth[1] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/pulse/cutting-vegetables.arr", bus) @=> synths[0];

            
            // connect to effects and dac
            bus => ps => dac;
            0.8 => bus.gain; 
            0.7 => ps.mix;
            0.5 => ps.shift;
        } 

        // whisking...
        if (synth_group_in == 1) {
            // cooking synths pulses
            new ArbSynth[2] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/pulse/egg-crack.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/whisking.arr", bus) @=> synths[1];

            
            // connect to effects and dac
            bus => ps => dac;
            0.8 => bus.gain; 
            0.7 => ps.mix;
            0.5 => ps.shift;
        } 

        // brewing...
        if (synth_group_in == 2) {
            new ArbSynth[1] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/cont/coffee-brewing-percolation.arr", bus) @=> synths[0];
            
            // connect to effects and dac
            bus => ps => dac;
            0.8 => bus.gain; 
            0.7 => ps.mix;
            0.5 => ps.shift;
        } 

        // caramelizing...
        else if (synth_group_in == 3) {
            new ArbSynth[1] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/cont/cooking-frying.arr", bus) @=> synths[0];

            // connect to effects and dac
            bus => ps => dac;
            0.8 => bus.gain;
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // cooking
        else if (synth_group_in == 4) {
            // cooking synth continuous
            new ArbSynth[2] @=> synths; // sized number of cooking sounds
            new ArbSynth("data/verbs/cont/cooking-pasta.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/liquid-swirl.arr", bus1) @=> synths[1];


            // connect to effects and dac
            0.15 => bus1.gain;
            bus1 => ps => dac;
            bus => ps => dac;
            0.9 => bus.gain;
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // Stage 2: mech synths
        // Doodling
        else if (synth_group_in == 5) {
            // mech synths continuous
            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/cont/pencil-on-paper-1.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/pencil-on-paper-2.arr", bus) @=> synths[1];

            // connect to effects and dac
            bus => ps => dac;   
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // calculating
        else if (synth_group_in == 6) {

            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/pulse/buttons_calculator.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/buttons_calculator1.arr", bus) @=> synths[1];

            // connect to effects and dac
            bus => ps => dac;   
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }
        
        // newspapering
        else if (synth_group_in == 7) {
            // mech synths pulse
            new ArbSynth[1] @=> synths;
            new ArbSynth("data/verbs/pulse/rustling-a-newspaper.arr", bus) @=> synths[0];

            // connect to effects and dac
            bus => ps => dac;
            0.8 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // vibing
        else if (synth_group_in == 8) {
            // mech synths pulse
            new ArbSynth[1] @=> synths;
            new ArbSynth("data/verbs/pulse/cell-phone-vibrate-high-quality.arr", bus) @=> synths[0];

            // connect to effects and dac
            bus => ps => dac;   
            0.8 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // Stage 3: man synths
        // panicking 
        else if (synth_group_in == 9) {

            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/cont/puppy-crying.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/groaning-gurgle.arr", bus) @=> synths[1];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // breaking
        else if (synth_group_in == 10) {

            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/pulse/glass-breaking.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/knife-stab.arr", bus) @=> synths[1];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // honking
        else if (synth_group_in == 11) {
            // man synths pulse
            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/pulse/e-oh.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/crying-man.arr", bus1) @=> synths[1];

            // connect to effects and dac
            0.1 => bus1.gain;
            bus1 => ps => dac;
            bus => ps => dac;
            0.2 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // screaming
        else if (synth_group_in == 12) {
            new ArbSynth[4] @=> synths;
            new ArbSynth("data/verbs/pulse/man-screaming.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/screaming-man.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/cont/frantic-screaming.arr", bus) @=> synths[2];
            new ArbSynth("data/verbs/cont/woman-screaming-sfx-screaming.arr", bus) @=> synths[3];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // rotting
        else if (synth_group_in == 13) {
            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/cont/keurig-kcup-brewing.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/stomach-gurgle.arr", bus) @=> synths[1];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // withering
        else if (synth_group_in == 14) {
            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/pulse/cracking-bones.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/swirling-crickets.arr", bus) @=> synths[1];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        }

        // dying
        else if (synth_group_in == 15) {
            new ArbSynth[3] @=> synths;
            new ArbSynth("data/verbs/pulse/blade-piercing-body.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/pulse/ouch-oof-hurt-1.arr", bus) @=> synths[1];
            new ArbSynth("data/verbs/pulse/ouch-oof-hurt-3.arr", bus) @=> synths[2];

            // connect to effects and dac
            bus => ps => dac;
            0.3 => bus.gain; // this stuff too loud LOL
            0.7 => ps.mix;
            0.5 => ps.shift;
        } 

        // burning
        else if (synth_group_in == 16) {
            new ArbSynth[2] @=> synths;
            new ArbSynth("data/verbs/cont/wood-burning-stove-fire.arr", bus) @=> synths[0];
            new ArbSynth("data/verbs/cont/rain.arr", bus) @=> synths[1];


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

    fun void disconnect() {
        silence();
        ps =< dac;
    }

    fun dur getCurrentDur() {
        return currentDur;
    }
}

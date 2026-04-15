//-----------------------------------------------------------------------------
// name: keyboard_sound.ck
// desc: models keyboard typing sounds when receiving keyboard inputs
//
// note: 
//
// author: Siqi Chen
//-----------------------------------------------------------------------------
Hid hi;
HidMsg msg;

// which keyboard
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

class keyBeats {
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
    JCRev r;


    fun @construct(dur beatDur_in, int beatPattern_in[], int perc_type) {
        beatDur_in => beatDur;
        beatPattern_in @=> beatPattern;

        if (perc_type == 0){
            // noise envelope
            n => key => r => dac;
            0.1 => n.gain;
            0.001 => r.mix;
            key.set( 5::ms, 4::ms, .3, 5::ms );
        }
        else if (perc_type == 1) {
            // mid-range tomtom sound
            n => key => lpf => r => dac;
            2000 => lpf.freq;
            0.2 => n.gain;
            0.001 => r.mix;
            key.set( 5::ms, 4::ms, .5, 8::ms );
        }
        else if (perc_type == 2) {
            // low tomtom sound
            n => key => lpf => r => dac;
            500 => lpf.freq;
            0.3 => n.gain;
            0.001 => r.mix;
            key.set( 5::ms, 6::ms, .5, 5::ms );
        }

        // set audio params
        // 0.1 => n.gain;
        // 0.001 => r.mix;
        // key.set( 5::ms, 4::ms, .5, 5::ms );

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
                <<< "beat:", beatPattern[i] >>>;
                // wait until duration of next beat
                (beatPattern[i] * beatDur) => now;
            }

        }
    }

}


keyBeats kb1(100::ms, [4, 1, 1, 1, 1], 0);

fun void addTracks() {
    // wait 16 seconds before adding track
    16::second => now; 
    kb1.playBeats();
}


// ======== play drum stuff =========

// instantiate keyBeats
keyBeats kb(200::ms, [1, 2, 1], 1);
// spork playBeats();
spork ~ kb.playBeats();

spork ~ addTracks();


// infinite event loop
while( true )
{
    // wait on event
    hi => now;

    // get one or more messages
    while( hi.recv( msg ) )
    {
        // check for action type
        if( msg.isButtonDown() )
        {
            <<< "down:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
            // // trigger ADSR
            // key.keyOn();
            // 20::ms => now;
            // key.keyOff();
            // key.releaseTime() => now;

            // set state wasKeyDown to true
            1 => kb.wasKeyDown;
            1 => kb1.wasKeyDown;
        }
        else
        {
            //<<< "up:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
        }

        if (msg.isButtonDown() && 64 < msg.ascii && msg.ascii < 91) {
            // print "letter"
            <<< "letter:", msg.ascii >>>;
        }
        
        
    }
    
}





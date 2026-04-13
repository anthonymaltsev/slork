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


// keyboard sound synthesis
Noise n => ADSR key => JCRev r => dac;

// set audio parameters
0.1 => n.gain;
0.001 => r.mix;
key.set( 5::ms, 4::ms, .5, 5::ms );

// ======== play drum stuff =========
// initialize state wasKeyDown to keep track of key state
0 => int wasKeyDown;

// initialize beat pattern
200::ms => dur beatDur;
[1, 3, 1, 1, 2] @=> int beatPattern[];

// spork playBeats();
spork ~ playBeats();


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
            1 => wasKeyDown;
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

fun void playBeats(){
    // infinite time-loop
    while( true ){
        
        
        // advance time by values in beat pattern
        for (0 => int i; i < beatPattern.size(); i++){
            // check if key was down
            if( wasKeyDown )
            {
                // trigger ADSR
                key.keyOn();
                10::ms => now;
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

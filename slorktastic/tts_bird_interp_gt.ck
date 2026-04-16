//-----------------------------------------------------------------------------
// name: tts_bird_interp_gt.ck
// desc: a quite stupid thing that interpolates between letters said and bird noises controlled by gametrak thing
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"arbsynth.ck", "arbsynth2.ck", "clawed-code.ck"}//, "gt_kb_dupe.ck"}

// <<< now >>>;
// 10::ms => now;
// <<< now >>>;
// me.exit();

//-----------------------------------------------------------------------------
Gain g;// => dac;
// pre => NRev rev => dac;

// 0.1 => rev.mix;

Chorus chor[6];

for( int i; i < chor.size(); i++ )
{
    // testing script for stereo
    // (Math.fmod(i, 2)) $ int => int channel;
    
    // patch each voice
    g => chor[i] => dac.chan(i);
    
    // initializing a light chorus effect
    // (try tweaking these values!)
    chor[i].baseDelay( 10*i::ms );
    chor[i].modDepth( .8*i );
    chor[i].modFreq( 0.1*i );
    chor[i].mix( .9 );
}

ClawedCode code();
spork ~ code.run();

<<< "waiting for prompt to pull buzz words", "" >>>;
code.wait => now;

//-----------------------------------------------------------------------------
//        device, deadzone
// GameTrak gt(0, 0.1);

// z axis deadzone
0 => float DEADZONE;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// HID objects
Hid trak;
HidMsg msg;

// open joystick 0, exit on fail
if( !trak.openJoystick( device ) ) me.exit();

// print
<<< "joystick '" + trak.name() + "' ready", "" >>>;

// data structure for gametrak
class GameTrak
{
    // timestamps
    time lastTime;
    time currTime;
    
    // previous axis data
    float lastAxis[6];
    // current axis data
    float axis[6];
}

// gametrack
GameTrak gt;

// spork control
spork ~ gametrak();

// gametrack handling
fun void gametrak()
{
    while( true )
    {
        // wait on HidIn as event
        trak => now;
        
        // messages received
        while( trak.recv( msg ) )
        {
            // joystick axis motion
            if( msg.isAxisMotion() )
            {            
                // check which
                if( msg.which >= 0 && msg.which < 6 )
                {
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    // save last
                    gt.axis[msg.which] => gt.lastAxis[msg.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msg.which != 2 && msg.which != 5 )
                    { msg.axisPosition => gt.axis[msg.which]; }
                    else
                    {
                        1 - ((msg.axisPosition + 1) / 2) - DEADZONE => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                }
            }
            
            // joystick button down
            else if( msg.isButtonDown() )
            {
                <<< "button", msg.which, "down" >>>;
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                <<< "button", msg.which, "up" >>>;
            }
        }
    }
}


InterpSayer s("data/sparrow.arr", g);

// -----------------------------------------------------------

class InterpSayer {
    ArbSynth2 alphabet[0];
    Gain ps;
    150::ms => dur len;
    0. => float len_mul;
    1. => float mix_param;

    fun @construct(string fname2, UGen outchan) {
        new ArbSynth2("data/alphabet/a.arr", fname2, ps) @=> alphabet["A"];
        new ArbSynth2("data/alphabet/b.arr", fname2, ps) @=> alphabet["B"];
        new ArbSynth2("data/alphabet/c.arr", fname2, ps) @=> alphabet["C"];
        new ArbSynth2("data/alphabet/d.arr", fname2, ps) @=> alphabet["D"];
        new ArbSynth2("data/alphabet/e.arr", fname2, ps) @=> alphabet["E"];
        new ArbSynth2("data/alphabet/f.arr", fname2, ps) @=> alphabet["F"];
        new ArbSynth2("data/alphabet/g.arr", fname2, ps) @=> alphabet["G"];
        new ArbSynth2("data/alphabet/h.arr", fname2, ps) @=> alphabet["H"];
        new ArbSynth2("data/alphabet/i.arr", fname2, ps) @=> alphabet["I"];
        new ArbSynth2("data/alphabet/j.arr", fname2, ps) @=> alphabet["J"];
        new ArbSynth2("data/alphabet/k.arr", fname2, ps) @=> alphabet["K"];
        new ArbSynth2("data/alphabet/l.arr", fname2, ps) @=> alphabet["L"];
        new ArbSynth2("data/alphabet/m.arr", fname2, ps) @=> alphabet["M"];
        new ArbSynth2("data/alphabet/n.arr", fname2, ps) @=> alphabet["N"];
        new ArbSynth2("data/alphabet/o.arr", fname2, ps) @=> alphabet["O"];
        new ArbSynth2("data/alphabet/p.arr", fname2, ps) @=> alphabet["P"];
        new ArbSynth2("data/alphabet/q.arr", fname2, ps) @=> alphabet["Q"];
        new ArbSynth2("data/alphabet/r.arr", fname2, ps) @=> alphabet["R"];
        new ArbSynth2("data/alphabet/s.arr", fname2, ps) @=> alphabet["S"];
        new ArbSynth2("data/alphabet/t.arr", fname2, ps) @=> alphabet["T"];
        new ArbSynth2("data/alphabet/u.arr", fname2, ps) @=> alphabet["U"];
        new ArbSynth2("data/alphabet/v.arr", fname2, ps) @=> alphabet["V"];
        new ArbSynth2("data/alphabet/w.arr", fname2, ps) @=> alphabet["W"];
        new ArbSynth2("data/alphabet/x.arr", fname2, ps) @=> alphabet["X"];
        new ArbSynth2("data/alphabet/y.arr", fname2, ps) @=> alphabet["Y"];
        new ArbSynth2("data/alphabet/z.arr", fname2, ps) @=> alphabet["Z"];

        // 1. => ps.mix;
        ps => outchan;

        spork ~ update_param();
    }

    fun void update_param() {
        while (true) {
            Math.clampf(1. - (gt.axis[0]+1.)/2., 0., 1.) => mix_param;
            gt.axis[4]>0 ? Math.clampf(gt.axis[4], 0., 0.9): 0. => len_mul;
            // 2.5 * gt.axis[3] => ps.shift;
            <<< mix_param, len_mul>>>;
            10::ms => now;
        }
    }

    fun void say(string s) {
        for (0 => int i; i < s.length(); i++) {
            if (" " == s.charAt2(i)) 
                len * Math.random2f(1.-len_mul, 1.+len_mul/2.) => now;
            else { 
                <<< "saying ", s.charAt2(i) >>>;
                spork ~ alphabet[s.charAt2(i)].playback(mix_param);
                len * Math.random2f(1.-len_mul, 1.+len_mul/2.) => now;
            }
        }
    }
}


while (true) {
    s.say(code.wait.buzzwords + " ");
}
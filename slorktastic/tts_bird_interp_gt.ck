//-----------------------------------------------------------------------------
// name: tts_bird_interp_gt.ck
// desc: a quite stupid thing that interpolates between letters said and bird noises controlled by gametrak thing
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"arbsynth.ck", "arbsynth2.ck"}

//-----------------------------------------------------------------------------

0.1 => float DEADZONE;
0 => int device;
if( me.args() ) me.arg(0) => Std.atoi => device;

Hid trak;
HidMsg msg;

if( !trak.openJoystick( device ) ) me.exit();

<<< "gametrak opened" >>>;

private class GameTrak {
    time lastTime;
    time currTime;
    
    float lastAxis[6];
    float axis[6];
}

GameTrak gt;

spork ~ gametrak();

fun void gametrak()
{
    while( true )
    {
        trak => now;
        while( trak.recv( msg ) )
        {
            if( msg.isAxisMotion() )
            {            
                if( msg.which >= 0 && msg.which < 6 )
                {
                    if( now > gt.currTime )
                    {
                        gt.currTime => gt.lastTime;
                        now => gt.currTime;
                    }
                    gt.axis[msg.which] => gt.lastAxis[msg.which];

                    if( msg.which != 2 && msg.which != 5 ) 
                    { 
                        msg.axisPosition => gt.axis[msg.which]; 
                    }
                    else
                    {
                        1 - ((msg.axisPosition + 1) / 2) - DEADZONE => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                }
            }
            
        }
    }
}

// -----------------------------------------------------------

class InterpSayer {
    ArbSynth2 alphabet[0];
    150::ms => dur len;
    0. => float len_mul;
    1. => float mix_param;

    fun @construct(string fname2, UGen outchan) {
        new ArbSynth2("data/alphabet/a.arr", fname2, outchan) @=> alphabet["a"];
        new ArbSynth2("data/alphabet/b.arr", fname2, outchan) @=> alphabet["b"];
        new ArbSynth2("data/alphabet/c.arr", fname2, outchan) @=> alphabet["c"];
        new ArbSynth2("data/alphabet/d.arr", fname2, outchan) @=> alphabet["d"];
        new ArbSynth2("data/alphabet/e.arr", fname2, outchan) @=> alphabet["e"];
        new ArbSynth2("data/alphabet/f.arr", fname2, outchan) @=> alphabet["f"];
        new ArbSynth2("data/alphabet/g.arr", fname2, outchan) @=> alphabet["g"];
        new ArbSynth2("data/alphabet/h.arr", fname2, outchan) @=> alphabet["h"];
        new ArbSynth2("data/alphabet/i.arr", fname2, outchan) @=> alphabet["i"];
        new ArbSynth2("data/alphabet/j.arr", fname2, outchan) @=> alphabet["j"];
        new ArbSynth2("data/alphabet/k.arr", fname2, outchan) @=> alphabet["k"];
        new ArbSynth2("data/alphabet/l.arr", fname2, outchan) @=> alphabet["l"];
        new ArbSynth2("data/alphabet/m.arr", fname2, outchan) @=> alphabet["m"];
        new ArbSynth2("data/alphabet/n.arr", fname2, outchan) @=> alphabet["n"];
        new ArbSynth2("data/alphabet/o.arr", fname2, outchan) @=> alphabet["o"];
        new ArbSynth2("data/alphabet/p.arr", fname2, outchan) @=> alphabet["p"];
        new ArbSynth2("data/alphabet/q.arr", fname2, outchan) @=> alphabet["q"];
        new ArbSynth2("data/alphabet/r.arr", fname2, outchan) @=> alphabet["r"];
        new ArbSynth2("data/alphabet/s.arr", fname2, outchan) @=> alphabet["s"];
        new ArbSynth2("data/alphabet/t.arr", fname2, outchan) @=> alphabet["t"];
        new ArbSynth2("data/alphabet/u.arr", fname2, outchan) @=> alphabet["u"];
        new ArbSynth2("data/alphabet/v.arr", fname2, outchan) @=> alphabet["v"];
        new ArbSynth2("data/alphabet/w.arr", fname2, outchan) @=> alphabet["w"];
        new ArbSynth2("data/alphabet/x.arr", fname2, outchan) @=> alphabet["x"];
        new ArbSynth2("data/alphabet/y.arr", fname2, outchan) @=> alphabet["y"];
        new ArbSynth2("data/alphabet/z.arr", fname2, outchan) @=> alphabet["z"];

        spork ~ update_param();
    }

    fun void update_param() {
        while (true) {
            1. - (gt.axis[0]+1.)/2. => mix_param;
            gt.axis[1]>0 ? Math.clampf(gt.axis[1], 0., 0.9): 0. => len_mul;
            <<< mix_param, len_mul >>>;
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

Gain g => dac;

// Chorus chor[6];

// for( int i; i < chor.size(); i++ )
// {
//     // testing script for stereo
//     // (Math.fmod(i, 2)) $ int => channel;
    
//     // patch each voice
//     g => chor[i] => dac.chan(i);
    
//     // initializing a light chorus effect
//     // (try tweaking these values!)
//     chor[i].baseDelay( 10*i::ms );
//     chor[i].modDepth( .8*i );
//     chor[i].modFreq( 0.1*i );
//     chor[i].mix( .9 );
// }

InterpSayer s("data/sparrow.arr", g);

while (true) {
    s.say("ai ml vlm mrr gpu agi rl dpo ppo llm rag auc gtm roi ");
}
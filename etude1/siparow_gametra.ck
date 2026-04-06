//-----------------------------------------------------------------------------
// name: siparow_gametra.ck
// desc: hooks up gametrack to control 2 siparows, one for each string
// dependencies: sparrow.ck, siparow.ck
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
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

//while (true) {
//    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
//    500::ms => now;
//}

//-----------------------------------------------------------------------------

Siparow left;
Siparow right;

left.init(
    [3500., 4000., 4500.], // freq
    [160::ms, 150::ms, 140::ms], // durs
    [200::ms, 225::ms, 250::ms], // inter_durs
    [0.6, 0.6, 0.5], // gains
    [dac.chan(0), dac.chan(1), dac.chan(2)] // out channels
);
right.init(
    [3500., 4000., 4500.], // freq
    [160::ms, 150::ms, 140::ms], // durs
    [400::ms, 450::ms, 500::ms], // inter_durs
    [0.6, 0.6, 0.5], // gains
    [dac.chan(3), dac.chan(4), dac.chan(5)] // out channels
);

left.set_them_loose();
right.set_them_loose();

left.propagate_rev(0.05);

spork ~ update_siparows_from_gt();

fun void update_siparows_from_gt() {
    while (true) {

        // left
        left.propagate_gain_mul(gain_norm(gt.axis[2]));
        //left.propagate_dur_mul(dur_norm(gt.axis[0]));
        left.propagate_rev(rev_norm(gt.axis[0]));
        left.propagate_inter_dur_mul(inter_dur_norm(gt.axis[2]));
        left.propagate_freq_mul(freq_norm(gt.axis[1]));

        //right
        right.propagate_gain_mul(gain_norm(gt.axis[5]));
        //right.propagate_dur_mul(dur_norm(gt.axis[3]));
        right.propagate_rev(rev_norm(gt.axis[3]));
        right.propagate_inter_dur_mul(inter_dur_norm(gt.axis[5]));
        right.propagate_freq_mul(freq_norm(gt.axis[4]));

        10::ms => now;
    }
}

fun float gain_norm(float zero_to_one) {
    return Math.clampf(Math.pow(2 * zero_to_one, 2), 0., 0.6);
}

fun float dur_norm(float neg1_to_1) {
    return (neg1_to_1 + 1) / 2.;
}

fun float inter_dur_norm(float zero_to_one) {
    return 1. - zero_to_one;
}

fun float rev_norm(float neg1_to_1) {
    return Math.pow((neg1_to_1 + 1) / 5.5, 2.);
}

fun float freq_norm(float neg1_to_1) {
    if (neg1_to_1 <= 0) {
        return Math.pow(neg1_to_1 + 1., 2.)+0.025;
    }
    return 0.975*neg1_to_1 + 1.;
    //return Math.sexp(1.85*(neg1_to_1 - 1.));
}

while(true) {
    //<<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    <<< "left: \n    freq:      ", left.get_freq_mul()*left.base_freqs[1],
              "\n    inter dur: ", left.get_inter_dur_mul()*left.base_inter_durs[1] / 44.1, "ms",
              "\n    dur:       ", left.get_dur_mul()*left.base_durs[1] / 44.1, "ms",
              "\n    gain:      ", left.get_gain_mul()*left.base_gains[1]
    >>>;
    <<< "right:\n    freq:      ", right.get_freq_mul()*right.base_freqs[1],
              "\n    inter dur: ", right.get_inter_dur_mul()*right.base_inter_durs[1] / 44.1, "ms",
              "\n    dur:       ", right.get_dur_mul()*right.base_durs[1] / 44.1, "ms",
              "\n    gain:      ", right.get_gain_mul()*right.base_gains[1], "\n"
    >>>;
    
    333::ms => now;
}


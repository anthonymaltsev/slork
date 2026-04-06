//-----------------------------------------------------------------------------
// name: siparow_gametra.ck
// desc: hooks up gametrack to control 2 siparows, one for each string
// dependencies: sparrow.ck, siparow.ck
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------


0 => float DEADZONE;
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

while (true) {
    <<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    500::ms => now;
}

//-----------------------------------------------------------------------------

// Siparow left;
// Siparow right;

// left.init(
//     [3500., 4000., 4500.], // freq
//     [160::ms, 150::ms, 140::ms], // durs
//     [200::ms, 225::ms, 250::ms], // inter_durs
//     [0.3, 0.3, 0.23], // gains
//     [dac.chan(0), dac.chan(1), dac.chan(2)] // out channels
// );
// right.init(
//     [3500., 4000., 4500.], // freq
//     [160::ms, 150::ms, 140::ms], // durs
//     [200::ms, 225::ms, 250::ms], // inter_durs
//     [0.3, 0.3, 0.23], // gains
//     [dac.chan(3), dac.chan(4), dac.chan(5)] // out channels
// );


// spork ~ update_siparows_from_gt();

// fun void update_siparows_from_gt() {
//     while (true) {

//         // left
//         left.propagate_gain_mul(gt.axis[0]);
//         left.propagate_inter_dur_mul(gt.axis[1]);
//         left.propagate_freq_mul(gt.axis[2]);

//         //right
//         left.propagate_gain_mul(gt.axis[3]);
//         left.propagate_inter_dur_mul(gt.axis[4]);
//         left.propagate_freq_mul(gt.axis[5]);

//         10::ms => now;
//     }
// }
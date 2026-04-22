//-----------------------------------------------------------------------------
// name: gametra.ck
// desc: gametrak boilerplate code;
//       prints 6 axes of the gametrak tethers + foot pedal button;
//       a helpful starting point for mapping gametrak
//
// author: Ge Wang (ge@ccrma.stanford.edu)
// date: summer 2014
//-----------------------------------------------------------------------------

@import {"gt_kb_dupe.ck"}

// gametrack
GameTrak gt;

// main loop
while( true )
{
    // print 6 continuous axes -- XYZ values for left and right
    <<< "axes:", gt.axis[0],gt.axis[1],gt.axis[2],
                 gt.axis[3],gt.axis[4],gt.axis[5] >>>;

    // also can map gametrak input to audio parameters around here
    // note: gt.lastAxis[0]...gt.lastAxis[5] hold the previous XYZ values

    // advance time
    100::ms => now;
}

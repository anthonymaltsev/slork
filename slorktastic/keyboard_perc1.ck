@import {"keyboard_sound.ck", "keyboard_visuals.ck"}


// -----------------------------------------------------------------------------
// VISUALS AND SOUNDS NOT YET CONNECTED
// -----------------------------------------------------------------------------

// ChuGL scene setup  ===================================================
GG.scene() @=> GScene @ scene;
GG.camera() @=> GCamera @ cam;
cam.orthographic();  // Orthographic camera mode for 2D scene
GWindow.title( "Keyboard" );
@(0.02, 0.02, 0.02) => GG.scene().backgroundColor;

// Initialize Mouse Manager

Mouse mouse;
spork ~ mouse.selfUpdate(); // start updating mouse position


// visual stuff ===================================================
GGen percGroup --> GG.scene();
5 => int NUM_PERCS;
percSets percs(mouse)[NUM_PERCS];

percs[0].setName(
    "cooking...");
percs[1].setName(
    "
    Chopping onions..."
    );
percs[2].setName(
    "Doodling..."
    );
percs[3].setName(
    "Panicking..."
    );
percs[4].setName(
    "Rotting"
    );


fun void placePercGroup() {
    // recalculate aspect
    (GG.frameWidth() * 1.0) / (GG.frameHeight() * 1.0) => float aspect;
    // calculate ratio between old and new height/width
    0.8 * cam.viewSize() => float frustrumHeight;  // height of screen in world-space units
    frustrumHeight * aspect => float frustrumWidth;  // widht of the screen in world-space units
    frustrumWidth / NUM_PERCS => float padSpacing;

    for (0 => int i; i < NUM_PERCS; i++) {
        percs[i] @=> percSets perc;

        // connect to scene
        perc --> percGroup;

        // set transform
        perc.sca(padSpacing * 2.);
        perc.posX(padSpacing * i - frustrumWidth / 2.0 + padSpacing / 2.0);
        perc.posY(frustrumHeight / 2.0 - padSpacing / 2.0 - 4);
    }
}

placePercGroup(); // initial placement of percs




// audio stuff ===================================================

// sync time
Machine.timeOfDay2() => vec2 start_time;
start_time.y => float start_micros;
(1000::ms - (start_micros/1000.)::ms) => now;

// keyboard setup
Hid hi;
HidMsg msg;

// which keyboard
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;



// Keyboard beats sounds ====================================================



// instantiate keySynths
keySynths @cooking; // cook
keySynths @chopOnions; // onions

keySynths @doodling; // mech synths pulse

keySynths @panicking; // man synths pulse
keySynths @rotting; // man synth long


// ======== play perc stuff ========

// initialize the shreds
Shred chopOnionsShred, cookingShred, doodlingShred, panickingShred, rottingShred;

fun void Cooking() {
    if (percs[0].active() && percs[0].deactivateHappened == 1) {
        <<< "perc 0 activated!" >>>;
        0 => percs[0].deactivateHappened; 
        1 => percs[0].activateHappened;
        new keySynths(1::second, [2, 1, 1], 4) @=> cooking;
        spork ~ cooking.addSynthTrack(0::second) @=> cookingShred;
    } else if (percs[0].activateHappened == 1 && percs[0].state == 0) {
        1 => percs[0].deactivateHappened;
        0 => percs[0].activateHappened;
        <<< "synths deactivated!" >>>;
        spork ~ deactivateCooking();
    }
}

fun void deactivateCooking() {
    // NEEDS DEBUGGING - currently silences but has residual sine / FM-like tones when reactivated
    cooking.silence();
    300::ms => now; // wait a bit
    cookingShred.exit();
    cooking.disconnect();
    null @=> cooking;
}

fun void ChopOnions() {
    if (percs[1].active() && percs[1].deactivateHappened == 1) {
        <<< "perc 1 activated!" >>>;
        0 => percs[1].deactivateHappened; 
        1 => percs[1].activateHappened;
        new keySynths(1::second, [2, 1, 1], 0) @=> chopOnions;
        spork ~ chopOnions.addSynthTrack(0::second) @=> chopOnionsShred;
    } else if (percs[1].activateHappened == 1 && percs[1].state == 0) {
        1 => percs[1].deactivateHappened;
        0 => percs[1].activateHappened;
        <<< "chopOnions deactivated!" >>>;
        spork ~ deactivateChopOnions();
    }
}

fun void deactivateChopOnions() {
    chopOnions.silence();
    300::ms => now;
    chopOnionsShred.exit();
    chopOnions.disconnect();
    null @=> chopOnions;
}

fun void Doodling() {
    if (percs[2].active() && percs[2].deactivateHappened == 1) {
        <<< "perc 2 activated!" >>>;
        0 => percs[2].deactivateHappened; 
        1 => percs[2].activateHappened;
        new keySynths(1::second, [2, 1, 1], 5) @=> doodling;
        spork ~ doodling.addSynthTrack(0::second) @=> doodlingShred;
    } else if (percs[2].activateHappened == 1 && percs[2].state == 0) {
        1 => percs[2].deactivateHappened;
        0 => percs[2].activateHappened;
        <<< "doodling deactivated!" >>>;
        spork ~ deactivateDoodling();
    }
}

fun void deactivateDoodling() {
    doodling.silence();
    300::ms => now;
    doodlingShred.exit();
    doodling.disconnect();
    null @=> doodling;
}

fun void Panicking() {
    if (percs[3].active() && percs[3].deactivateHappened == 1) {
        <<< "perc 3 activated!" >>>;
        0 => percs[3].deactivateHappened; 
        1 => percs[3].activateHappened;
        new keySynths(1::second, [2, 1, 1], 9) @=> panicking;
        spork ~ panicking.addSynthTrack(0::second) @=> panickingShred;
    } else if (percs[3].activateHappened == 1 && percs[3].state == 0) {
        1 => percs[3].deactivateHappened;
        0 => percs[3].activateHappened;
        <<< "panicking deactivated!" >>>;
        spork ~ deactivatePanicking();
    }
}

fun void deactivatePanicking() {
    panicking.silence();
    300::ms => now;
    panickingShred.exit();
    panicking.disconnect();
    null @=> panicking;
}

fun void Rotting() {
    if (percs[4].active() && percs[4].deactivateHappened == 1) {
        <<< "perc 4 activated!" >>>;
        0 => percs[4].deactivateHappened; 
        1 => percs[4].activateHappened;
        new keySynths(1::second, [2, 1, 1], 13) @=> rotting;
        spork ~ rotting.addSynthTrack(0::second) @=> rottingShred;
    } else if (percs[4].activateHappened == 1 && percs[4].state == 0) {
        1 => percs[4].deactivateHappened;
        0 => percs[4].activateHappened;
        <<< "rotting deactivated!" >>>;
        spork ~ deactivateRotting();
    }
}

fun void deactivateRotting() {
    rotting.silence();
    300::ms => now;
    rottingShred.exit();
    rotting.disconnect();
    null @=> rotting;
}



// Loops =================================================================

// keyboard handling loop

fun void keyboardLoop() {
    // infinite time-loop
    while (true){
        // wait on event
        hi => now;

        // get one or more messages
        while( hi.recv( msg ) )
        {
            // check for action type
            if( msg.isButtonDown() )
            {
                if (percs[0].active() && cooking != null){
                    1 => cooking.wasKeyDown;
                }
                if (percs[1].active() && chopOnions != null){
                    1 => chopOnions.wasKeyDown;
                }
                if (percs[2].active() && doodling != null){
                    1 => doodling.wasKeyDown;
                }
                if (percs[3].active() && panicking != null){
                    1 => panicking.wasKeyDown;
                }
                if (percs[4].active() && rotting != null){
                    1 => rotting.wasKeyDown;
                }
            }
            else
            {
                //<<< "up:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
            }

            if (msg.isButtonDown() && 64 < msg.ascii && msg.ascii < 91) {
                // print "letter"
                // <<< "letter:", msg.ascii >>>;
            }
            
            
        }
    }
}

spork ~ keyboardLoop();

// visuals loop

while( true )
{

    GG.nextFrame() => now;
    placePercGroup();
    Cooking();
    ChopOnions();
    Doodling();
    Panicking();
    Rotting();
    
}



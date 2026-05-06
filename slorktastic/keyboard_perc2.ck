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
6 => int NUM_PERCS;
percSets percs(mouse)[NUM_PERCS];

percs[0].setName(
    "Cooking...");
percs[1].setName(
    "Whisking...");
percs[2].setName(
    "Calculating...");
percs[3].setName(
    "Breaking...");
percs[4].setName(
    "Withering...");
percs[5].setName(
    "IMPULSE");


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
keySynths @cooking;
keySynths @whisking;
keySynths @calculating;
keySynths @breaking;
keySynths @withering;

impulses @imp;


// ======== play perc stuff ========

// initialize the shreds
Shred cookingShred, whiskingShred, calculatingShred, breakingShred, witheringShred, impShred;

fun void Cooking() {
    if (percs[0].active() && percs[0].deactivateHappened == 1) {
        <<< "perc 0 activated!" >>>;
        0 => percs[0].deactivateHappened; 
        1 => percs[0].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 4) @=> cooking;
        spork ~ cooking.playSynths() @=> cookingShred;
    } else if (percs[0].activateHappened == 1 && percs[0].state == 0) {
        1 => percs[0].deactivateHappened;
        0 => percs[0].activateHappened;
        <<< "cooking deactivated!" >>>;
        spork ~ deactivateCooking();
    }
}

fun void deactivateCooking() {
    cooking.silence();
    300::ms => now;
    cookingShred.exit();
    cooking.disconnect();
    null @=> cooking;
}

fun void Whisking() {
    if (percs[1].active() && percs[1].deactivateHappened == 1) {
        <<< "perc 1 activated!" >>>;
        0 => percs[1].deactivateHappened; 
        1 => percs[1].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 1) @=> whisking;
        spork ~ whisking.playSynths() @=> whiskingShred;
    } else if (percs[1].activateHappened == 1 && percs[1].state == 0) {
        1 => percs[1].deactivateHappened;
        0 => percs[1].activateHappened;
        <<< "whisking deactivated!" >>>;
        spork ~ deactivateWhisking();
    }
}

fun void deactivateWhisking() {
    whisking.silence();
    300::ms => now;
    whiskingShred.exit();
    whisking.disconnect();
    null @=> whisking;
}

fun void Calculating() {
    if (percs[2].active() && percs[2].deactivateHappened == 1) {
        <<< "perc 2 activated!" >>>;
        0 => percs[2].deactivateHappened; 
        1 => percs[2].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 6) @=> calculating;
        spork ~ calculating.playSynths() @=> calculatingShred;
    } else if (percs[2].activateHappened == 1 && percs[2].state == 0) {
        1 => percs[2].deactivateHappened;
        0 => percs[2].activateHappened;
        <<< "calculating deactivated!" >>>;
        spork ~ deactivateCalculating();
    }
}

fun void deactivateCalculating() {
    calculating.silence();
    300::ms => now;
    calculatingShred.exit();
    calculating.disconnect();
    null @=> calculating;
}

fun void Breaking() {
    if (percs[3].active() && percs[3].deactivateHappened == 1) {
        <<< "perc 3 activated!" >>>;
        0 => percs[3].deactivateHappened; 
        1 => percs[3].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 10) @=> breaking;
        spork ~ breaking.playSynths() @=> breakingShred;
    } else if (percs[3].activateHappened == 1 && percs[3].state == 0) {
        1 => percs[3].deactivateHappened;
        0 => percs[3].activateHappened;
        <<< "breaking deactivated!" >>>;
        spork ~ deactivateBreaking();
    }
}

fun void deactivateBreaking() {
    breaking.silence();
    300::ms => now;
    breakingShred.exit();
    breaking.disconnect();
    null @=> breaking;
}

fun void Withering() {
    if (percs[4].active() && percs[4].deactivateHappened == 1) {
        <<< "perc 4 activated!" >>>;
        0 => percs[4].deactivateHappened; 
        1 => percs[4].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 14) @=> withering;
        spork ~ withering.playSynths() @=> witheringShred;
    } else if (percs[4].activateHappened == 1 && percs[4].state == 0) {
        1 => percs[4].deactivateHappened;
        0 => percs[4].activateHappened;
        <<< "withering deactivated!" >>>;
        spork ~ deactivateWithering();
    }
}

fun void deactivateWithering() {
    withering.silence();
    300::ms => now;
    witheringShred.exit();
    withering.disconnect();
    null @=> withering;
}

fun void Impulses() {
    if (percs[5].active() && percs[5].deactivateHappened == 1) {
        <<< "impulses activated!" >>>;
        0 => percs[5].deactivateHappened;
        1 => percs[5].activateHappened;
        new impulses() @=> imp;
        spork ~ imp.play() @=> impShred;
    } else if (percs[5].activateHappened == 1 && percs[5].state == 0) {
        1 => percs[5].deactivateHappened;
        0 => percs[5].activateHappened;
        <<< "impulses deactivated!" >>>;
        spork ~ deactivateImpulses();
    }
}

fun void deactivateImpulses() {
    imp.silence();
    300::ms => now;
    impShred.exit();
    imp.disconnect();
    null @=> imp;
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
                if (percs[1].active() && whisking != null){
                    1 => whisking.wasKeyDown;
                }
                if (percs[2].active() && calculating != null){
                    1 => calculating.wasKeyDown;
                }
                if (percs[3].active() && breaking != null){
                    1 => breaking.wasKeyDown;
                }
                if (percs[4].active() && withering != null){
                    1 => withering.wasKeyDown;
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
    Whisking();
    Calculating();
    Breaking();
    Withering();
    Impulses();
    
}



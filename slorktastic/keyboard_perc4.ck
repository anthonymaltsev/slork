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

// visual stuff ===================================================
GGen percGroup --> GG.scene();
6 => int NUM_PERCS;
percSets percs[NUM_PERCS];

percs[0].setName(
    "Cooking...");
percs[0].setNum(1);
percs[1].setName(
    "Caramelizing...");
percs[1].setNum(2);
percs[2].setName(
    "Vibing...");
percs[2].setNum(3);
percs[3].setName(
    "Screaming...");
percs[3].setNum(4);
percs[4].setName(
    "Burning...");
percs[4].setNum(5);
percs[5].setName(
    "IMPULSE");
percs[5].setNum(6);


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
keySynths @caramelizing;
keySynths @vibing;
keySynths @screaming;
keySynths @burning;

impulses @imp;


// ======== play perc stuff ========

// initialize the shreds
Shred cookingShred, caramelizingShred, vibingShred, screamingShred, burningShred, impShred;

fun void Cooking() {
    if (percs[0].active() && percs[0].deactivateHappened == 1) {
        <<< "perc 0 activated!" >>>;
        0 => percs[0].deactivateHappened; 
        1 => percs[0].activateHappened;
        new keySynths(0.4::second, [1, 3, 2], 4) @=> cooking;
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

fun void Caramelizing() {
    if (percs[1].active() && percs[1].deactivateHappened == 1) {
        <<< "perc 1 activated!" >>>;
        0 => percs[1].deactivateHappened; 
        1 => percs[1].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 3) @=> caramelizing;
        spork ~ caramelizing.playSynths() @=> caramelizingShred;
    } else if (percs[1].activateHappened == 1 && percs[1].state == 0) {
        1 => percs[1].deactivateHappened;
        0 => percs[1].activateHappened;
        <<< "caramelizing deactivated!" >>>;
        spork ~ deactivateCaramelizing();
    }
}

fun void deactivateCaramelizing() {
    caramelizing.silence();
    300::ms => now;
    caramelizingShred.exit();
    caramelizing.disconnect();
    null @=> caramelizing;
}

fun void Vibing() {
    if (percs[2].active() && percs[2].deactivateHappened == 1) {
        <<< "perc 2 activated!" >>>;
        0 => percs[2].deactivateHappened; 
        1 => percs[2].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 8) @=> vibing;
        spork ~ vibing.playSynths() @=> vibingShred;
    } else if (percs[2].activateHappened == 1 && percs[2].state == 0) {
        1 => percs[2].deactivateHappened;
        0 => percs[2].activateHappened;
        <<< "vibing deactivated!" >>>;
        spork ~ deactivateVibing();
    }
}

fun void deactivateVibing() {
    vibing.silence();
    300::ms => now;
    vibingShred.exit();
    vibing.disconnect();
    null @=> vibing;
}

fun void Screaming() {
    if (percs[3].active() && percs[3].deactivateHappened == 1) {
        <<< "perc 3 activated!" >>>;
        0 => percs[3].deactivateHappened; 
        1 => percs[3].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 12) @=> screaming;
        spork ~ screaming.playSynths() @=> screamingShred;
    } else if (percs[3].activateHappened == 1 && percs[3].state == 0) {
        1 => percs[3].deactivateHappened;
        0 => percs[3].activateHappened;
        <<< "screaming deactivated!" >>>;
        spork ~ deactivateScreaming();
    }
}

fun void deactivateScreaming() {
    screaming.silence();
    300::ms => now;
    screamingShred.exit();
    screaming.disconnect();
    null @=> screaming;
}

fun void Burning() {
    if (percs[4].active() && percs[4].deactivateHappened == 1) {
        <<< "perc 4 activated!" >>>;
        0 => percs[4].deactivateHappened; 
        1 => percs[4].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 16) @=> burning;
        spork ~ burning.playSynths() @=> burningShred;
    } else if (percs[4].activateHappened == 1 && percs[4].state == 0) {
        1 => percs[4].deactivateHappened;
        0 => percs[4].activateHappened;
        <<< "burning deactivated!" >>>;
        spork ~ deactivateBurning();
    }
}

fun void deactivateBurning() {
    burning.silence();
    300::ms => now;
    burningShred.exit();
    burning.disconnect();
    null @=> burning;
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
            // skip number keys 0-9 (ascii 48-57) — reserved for pad toggles
            if( msg.isButtonDown() && !(msg.ascii >= 48 && msg.ascii <= 57) )
            {
                if (percs[0].active() && cooking != null){
                    1 => cooking.wasKeyDown;
                }
                if (percs[1].active() && caramelizing != null){
                    1 => caramelizing.wasKeyDown;
                }
                if (percs[2].active() && vibing != null){
                    1 => vibing.wasKeyDown;
                }
                if (percs[3].active() && screaming != null){
                    1 => screaming.wasKeyDown;
                }
                if (percs[4].active() && burning != null){
                    1 => burning.wasKeyDown;
                }
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

    // toggle pads with number keys 1-6
    if (GWindow.keyDown(GWindow.KEY_1)) percs[0].toggle();
    if (GWindow.keyDown(GWindow.KEY_2)) percs[1].toggle();
    if (GWindow.keyDown(GWindow.KEY_3)) percs[2].toggle();
    if (GWindow.keyDown(GWindow.KEY_4)) percs[3].toggle();
    if (GWindow.keyDown(GWindow.KEY_5)) percs[4].toggle();
    if (GWindow.keyDown(GWindow.KEY_6)) percs[5].toggle();

    Cooking();
    Caramelizing();
    Vibing();
    Screaming();
    Burning();
    Impulses();
}



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
    "cooking...");
percs[1].setName(
    "
    Brewing..."
    );
percs[2].setName(
    "Newspapering..."
    );
percs[3].setName(
    "Honking..."
    );
percs[4].setName(
    "Dying..."
    );
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
keySynths @brewing;
keySynths @newspapering;
keySynths @honking;
keySynths @dying;

impulses @imp;


// ======== play perc stuff ========

// initialize the shreds
Shred cookingShred, brewingShred, newspaperingShred, honkingShred, dyingShred, impShred;

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

fun void Brewing() {
    if (percs[1].active() && percs[1].deactivateHappened == 1) {
        <<< "perc 1 activated!" >>>;
        0 => percs[1].deactivateHappened; 
        1 => percs[1].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 2) @=> brewing;
        spork ~ brewing.playSynths() @=> brewingShred;
    } else if (percs[1].activateHappened == 1 && percs[1].state == 0) {
        1 => percs[1].deactivateHappened;
        0 => percs[1].activateHappened;
        <<< "brewing deactivated!" >>>;
        spork ~ deactivateBrewing();
    }
}

fun void deactivateBrewing() {
    brewing.silence();
    300::ms => now;
    brewingShred.exit();
    brewing.disconnect();
    null @=> brewing;
}

fun void Newspapering() {
    if (percs[2].active() && percs[2].deactivateHappened == 1) {
        <<< "perc 2 activated!" >>>;
        0 => percs[2].deactivateHappened; 
        1 => percs[2].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 7) @=> newspapering;
        spork ~ newspapering.playSynths() @=> newspaperingShred;
    } else if (percs[2].activateHappened == 1 && percs[2].state == 0) {
        1 => percs[2].deactivateHappened;
        0 => percs[2].activateHappened;
        <<< "newspapering deactivated!" >>>;
        spork ~ deactivateNewspapering();
    }
}

fun void deactivateNewspapering() {
    newspapering.silence();
    300::ms => now;
    newspaperingShred.exit();
    newspapering.disconnect();
    null @=> newspapering;
}

fun void Honking() {
    if (percs[3].active() && percs[3].deactivateHappened == 1) {
        <<< "perc 3 activated!" >>>;
        0 => percs[3].deactivateHappened; 
        1 => percs[3].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 11) @=> honking;
        spork ~ honking.playSynths() @=> honkingShred;
    } else if (percs[3].activateHappened == 1 && percs[3].state == 0) {
        1 => percs[3].deactivateHappened;
        0 => percs[3].activateHappened;
        <<< "honking deactivated!" >>>;
        spork ~ deactivateHonking();
    }
}

fun void deactivateHonking() {
    honking.silence();
    300::ms => now;
    honkingShred.exit();
    honking.disconnect();
    null @=> honking;
}

fun void Dying() {
    if (percs[4].active() && percs[4].deactivateHappened == 1) {
        <<< "perc 4 activated!" >>>;
        0 => percs[4].deactivateHappened; 
        1 => percs[4].activateHappened;
        new keySynths(0.4::second, [2, 1, 1], 15) @=> dying;
        spork ~ dying.playSynths() @=> dyingShred;
    } else if (percs[4].activateHappened == 1 && percs[4].state == 0) {
        1 => percs[4].deactivateHappened;
        0 => percs[4].activateHappened;
        <<< "dying deactivated!" >>>;
        spork ~ deactivateDying();
    }
}

fun void deactivateDying() {
    dying.silence();
    300::ms => now;
    dyingShred.exit();
    dying.disconnect();
    null @=> dying;
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
                if (percs[1].active() && brewing != null){
                    1 => brewing.wasKeyDown;
                }
                if (percs[2].active() && newspapering != null){
                    1 => newspapering.wasKeyDown;
                }
                if (percs[3].active() && honking != null){
                    1 => honking.wasKeyDown;
                }
                if (percs[4].active() && dying != null){
                    1 => dying.wasKeyDown;
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
    Brewing();
    Newspapering();
    Honking();
    Dying();
    Impulses();
    
}



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


fun void placePercGroup() {
    // recalculate aspect
    (GG.frameWidth() * 1.0) / (GG.frameHeight() * 1.0) => float aspect;
    // calculate ratio between old and new height/width
    0.3 * cam.viewSize() => float frustrumHeight;  // height of screen in world-space units
    frustrumHeight * aspect => float frustrumWidth;  // widht of the screen in world-space units
    frustrumWidth / NUM_PERCS => float padSpacing;

    for (0 => int i; i < NUM_PERCS; i++) {
        percs[i] @=> percSets perc;

        // connect to scene
        perc --> percGroup;

        // set transform
        perc.sca(padSpacing * 2.);
        perc.posX(padSpacing * i - frustrumWidth / 2.0 + padSpacing / 2.0);
        perc.posY(frustrumHeight / 2.0 - padSpacing / 2.0 - 3.2);
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

// instantiate keyBeats
keyBeats kb(200::ms, [1, 2, 1], 1); // basic snare 
keyBeats kb1(100::ms, [4, 1, 1, 1, 1], 0); // hats
keyBeats kb2(200::ms, [5, 3], 2); // kick drum
keyBeats kb3(100::ms, [3, 1, 2, 2], 3); // high snare
keyBeats kb4(400::ms, [5, 3], 4); // crash


// instantiate keySynths
keySynths ks(2::second, [1, 2, 1], 0); // food synths



// ======== play drum stuff =========


// spork playBeats();
// initialize the shreds
Shred kbShred0, kbShred1, kbShred2, kbShred3, kbShred4;
Shred cookShred;

fun void kbPercs() {
    if (percs[0].active() && percs[0].deactivateHappened == 1) {
        <<< "perc 0 activated!" >>>;
        0 => percs[0].deactivateHappened; 
        1 => percs[0].activateHappened;
        // play beats
        spork ~ kb.playBeats() @=> kbShred0;
        spork ~ kb1.addTrack(32::second) @=> kbShred1;
        spork ~ kb2.addTrack(48::second) @=> kbShred2;
        spork ~ kb3.addTrack(64::second) @=> kbShred3;
        spork ~ kb4.addTrack(80::second) @=> kbShred4;
    } else if (percs[0].activateHappened == 1 && percs[0].state == 0) {
        1 => percs[0].deactivateHappened;
        0 => percs[0].activateHappened;
        <<< "perc 0 deactivated!" >>>;
        kbShred0.exit();
        kbShred1.exit();
        kbShred2.exit();
        kbShred3.exit();
        kbShred4.exit();
    }
}

fun void cookSynths(){
    if (percs[1].active() && percs[1].deactivateHappened == 1) {
        <<< "synths activated!" >>>;
        0 => percs[1].deactivateHappened; 
        1 => percs[1].activateHappened;
        // play synths
        spork ~ ks.addSynthTrack(0::second) @=> cookShred;
    } else if (percs[1].activateHappened == 1 && percs[1].state == 0) {
        1 => percs[1].deactivateHappened;
        0 => percs[1].activateHappened;
        <<< "synths deactivated!" >>>;
        ks.getCurrentDur() => now; // let synths play out for a bit before killing them
        cookShred.exit();
    }
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
                // <<< "down:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;

                // set state wasKeyDown to true
                1 => kb.wasKeyDown;
                1 => kb1.wasKeyDown;
                1 => kb2.wasKeyDown;
                1 => kb3.wasKeyDown;
                1 => kb4.wasKeyDown;

                if (percs[1].active()){
                    1 => ks.wasKeyDown;
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

    GG.nextFrame() => now; // update graphics each loop iteration
    placePercGroup(); // update visuals each loop iteration, can this be optimized?
    kbPercs(); // check for active kb groups 
    cookSynths(); // check for active synth groups
    
}



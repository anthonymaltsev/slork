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


// instantiate keyBeats
keyBeats kb(200::ms, [1, 2, 1], 1); // basic snare 
keyBeats kb1(100::ms, [4, 1, 1, 1, 1], 0); // hats
keyBeats kb2(200::ms, [5, 3], 2); // kick drum
keyBeats kb3(100::ms, [3, 1, 2, 2], 3); // high snare
keyBeats kb4(400::ms, [5, 3], 4); // crash


// function to play beats for each track
fun void addTrack1() {
    // wait 32 seconds before adding track
    32::second => now; 
    kb1.playBeats();
}

fun void addTrack2() {
    // wait 48 seconds before adding track
    48::second => now; 
    kb2.playBeats();
}

fun void addTrack3() {
    // wait 64 seconds before adding track
    64::second => now; 
    kb3.playBeats();
}

fun void addTrack4() {
    // wait 80 seconds before adding track
    80::second => now; 
    kb4.playBeats();
}


// ======== play drum stuff =========


// spork playBeats();
spork ~ kb.playBeats();

spork ~ addTrack1();
spork ~ addTrack2();
spork ~ addTrack3();
spork ~ addTrack4();


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
                <<< "down:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;

                // set state wasKeyDown to true
                1 => kb.wasKeyDown;
                1 => kb1.wasKeyDown;
                1 => kb2.wasKeyDown;
                1 => kb3.wasKeyDown;
                1 => kb4.wasKeyDown;
            }
            else
            {
                //<<< "up:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
            }

            if (msg.isButtonDown() && 64 < msg.ascii && msg.ascii < 91) {
                // print "letter"
                <<< "letter:", msg.ascii >>>;
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
    
}



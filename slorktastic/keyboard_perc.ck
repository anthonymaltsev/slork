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
7 => int NUM_PERCS;
percSets percs(mouse)[NUM_PERCS];

percs[0].setName("kb");
percs[1].setName("cookPulse");
percs[2].setName("cookLong");
percs[3].setName("mechPulse");
percs[4].setName("mechLong");
percs[5].setName("manPulse");
percs[6].setName("manLong");


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
        perc.posY(frustrumHeight / 2.0 - padSpacing / 2.0 - 2);
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
keySynths @cook1; // food synths
keySynths @cook2; // food synths

keySynths @mech1; // mech synths pulse
keySynths @mech2; // mech synths long

keySynths @man1; // man synths pulse
keySynths @man2; // man synth long


// ======== play perc stuff ========

// spork playBeats();
// initialize the shreds
Shred kbShred0, kbShred1, kbShred2, kbShred3, kbShred4;
Shred cookShred1, cookShred2;
Shred mechShred1, mechShred2;
Shred manShred1, manShred2;

fun void kbPercs() {
    if (percs[0].active() && percs[0].deactivateHappened == 1) {
        <<< "perc 0 activated!" >>>;
        0 => percs[0].deactivateHappened; 
        1 => percs[0].activateHappened;
        // play beats
        spork ~ kb.playBeats() @=> kbShred0;
        spork ~ kb1.addTrack(3::second) @=> kbShred1;
        spork ~ kb2.addTrack(6::second) @=> kbShred2;
        spork ~ kb3.addTrack(9::second) @=> kbShred3;
        spork ~ kb4.addTrack(12::second) @=> kbShred4;
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

fun void cookSynths1(){
    if (percs[1].active() && percs[1].deactivateHappened == 1) {
        <<< "synths activated!" >>>;
        0 => percs[1].deactivateHappened; 
        1 => percs[1].activateHappened;
        // construct cook synth
        new keySynths(0.5::second, [1, 2, 1], 0) @=> cook1;
        // play synths
        spork ~ cook1.addSynthTrack(0::second) @=> cookShred1;
    } else if (percs[1].activateHappened == 1 && percs[1].state == 0) {
        1 => percs[1].deactivateHappened;
        0 => percs[1].activateHappened;
        <<< "synths deactivated!" >>>;
        spork ~ deactivateCookSynths1();
    }
}

fun void deactivateCookSynths1() {
    // NEEDS DEBUGGING - currently silences but has residual sine / FM-like tones when reactivated
    cook1.silence();
    300::ms => now; // wait a bit
    cookShred1.exit();
    cook1.disconnect();
    null @=> cook1;
}

fun void cookSynths2(){
    if (percs[2].active() && percs[2].deactivateHappened == 1) {
        <<< "synths activated!" >>>;
        0 => percs[2].deactivateHappened; 
        1 => percs[2].activateHappened;
        // construct cook synth
        new keySynths(0.5::second, [1, 2, 1], 1) @=> cook2;
        // play synths
        spork ~ cook2.addSynthTrack(0::second) @=> cookShred2;
    } else if (percs[2].activateHappened == 1 && percs[2].state == 0) {
        1 => percs[2].deactivateHappened;
        0 => percs[2].activateHappened;
        <<< "synths deactivated!" >>>;
        spork ~ deactivateCookSynths2();
    }
}

fun void deactivateCookSynths2() {
    // NEEDS DEBUGGING - currently silences but has residual sine / FM-like tones when reactivated
    cook2.silence();
    300::ms => now; // wait a bit
    cookShred2.exit();  
    cook2.disconnect();
    null @=> cook2;
}


fun void mechSynths1(){
    if (percs[3].active() && percs[3].deactivateHappened == 1) {
        <<< "synths activated!" >>>;
        0 => percs[3].deactivateHappened; 
        1 => percs[3].activateHappened;
        // construct mech synth
        new keySynths(0.2::second, [3, 1], 2) @=> mech1;
        // play synths
        spork ~ mech1.addSynthTrack(0::second) @=> mechShred1;
    } else if (percs[3].activateHappened == 1 && percs[3].state == 0) {
        1 => percs[3].deactivateHappened;
        0 => percs[3].activateHappened;
        <<< "synths deactivated!" >>>;
        spork ~ deactivateMechSynths1();
    }
}

fun void deactivateMechSynths1() {
    // NEEDS DEBUGGING - currently silences but has residual sine / FM-like tones when reactivated
    mech1.silence();
    300::ms => now; // wait a bit
    mechShred1.exit();
    mech1.disconnect();
    null @=> mech1;
}

fun void mechSynths2(){
    if (percs[4].active() && percs[4].deactivateHappened == 1) {
        <<< "synths activated!" >>>;
        0 => percs[4].deactivateHappened; 
        1 => percs[4].activateHappened;
        // construct mech synth
        new keySynths(0.3::second, [1, 2], 3) @=> mech2;
        // play synths
        spork ~ mech2.addSynthTrack(0::second) @=> mechShred2;
    } else if (percs[4].activateHappened == 1 && percs[4].state == 0) {
        1 => percs[4].deactivateHappened;
        0 => percs[4].activateHappened;
        <<< "synths deactivated!" >>>;
        spork ~ deactivateMechSynths2();
    }
}

fun void deactivateMechSynths2() {
    // NEEDS DEBUGGING - currently silences but has residual sine / FM-like tones when reactivated
    mech2.silence();
    300::ms => now; // wait a bit
    mechShred2.exit();
    mech2.disconnect();
    null @=> mech2;
}

fun void manSynths1(){
    if (percs[5].active() && percs[5].deactivateHappened == 1) {
        <<< "synths activated!" >>>;
        0 => percs[5].deactivateHappened; 
        1 => percs[5].activateHappened;
        // construct man synth
        new keySynths(0.5::second, [1, 1], 4) @=> man1;
        // play synths
        spork ~ man1.addSynthTrack(0::second) @=> manShred1;
    } else if (percs[5].activateHappened == 1 && percs[5].state == 0) {
        1 => percs[5].deactivateHappened;
        0 => percs[5].activateHappened;
        <<< "synths deactivated!" >>>;
        spork ~ deactivateManSynths1();
    }
}   

fun void deactivateManSynths1() {
    // NEEDS DEBUGGING - currently silences but has residual sine / FM-like tones when reactivated
    man1.silence();
    300::ms => now; // wait a bit
    manShred1.exit();
    man1.disconnect();
    null @=> man1;
}   

fun void manSynths2(){
    if (percs[6].active() && percs[6].deactivateHappened == 1) {
        <<< "synths activated!" >>>;
        0 => percs[6].deactivateHappened; 
        1 => percs[6].activateHappened;
        // construct man synth
        new keySynths(0.5::second, [2, 1], 5) @=> man2; 
        // play synths
        spork ~ man2.addSynthTrack(0::second) @=> manShred2;
    } else if (percs[6].activateHappened == 1 && percs[6].state == 0) {
        1 => percs[6].deactivateHappened;
        0 => percs[6].activateHappened;
        <<< "synths deactivated!" >>>;
        spork ~ deactivateManSynths2();
    }
}   

fun void deactivateManSynths2() {
    // NEEDS DEBUGGING - currently silences but has residual sine / FM-like tones when reactivated
    man2.silence();
    300::ms => now; // wait a bit
    manShred2.exit();
    man2.disconnect();
    null @=> man2;
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

                if (percs[1].active() && cook1 != null){
                    1 => cook1.wasKeyDown;
                }
                if (percs[2].active() && cook2 != null){
                    1 => cook2.wasKeyDown;
                }
                if (percs[3].active() && mech1 != null){
                    1 => mech1.wasKeyDown;    
                }
                if (percs[4].active() && mech2 != null){
                    1 => mech2.wasKeyDown;
                } 
                if (percs[5].active() && man1 != null){
                    1 => man1.wasKeyDown;
                }
                if (percs[6].active() && man2 != null){
                    1 => man2.wasKeyDown;
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
    cookSynths1(); // check for active synth groups
    cookSynths2();
    mechSynths1();
    mechSynths2();
    manSynths1();
    manSynths2();
    
}



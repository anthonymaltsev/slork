// test selected synth patch from keyboard_sound.ck


@import "keyboard_sound.ck"

keySynths test(0.4::second, [2, 1, 1], 4);
spork ~ test.playSynths();

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

while (true){
    hi => now;

    while (hi.recv (msg)){
        if( msg.isButtonDown() ) {
            1 => test.wasKeyDown;
        }
    }
}
// STK Saxofony

// patch
Saxofony sax => JCRev r => dac;
.5 => r.gain;
.2 => r.mix;

// our notes
[ 61, 63, 65, 66, 68 ] @=> int notes[];

// infinite time-loop
while( true )
{
    // set
    // Math.random2f( 0, 1 ) => sax.stiffness;
    // Math.random2f( 0, 1 ) => sax.aperture;
    // Math.random2f( 0, 1 ) => sax.noiseGain;
    // Math.random2f( 0, 1 ) => sax.blowPosition;
    // Math.random2f( 0, 12 ) => sax.vibratoFreq;
    // Math.random2f( 0, 1 ) => sax.vibratoGain;
    // Math.random2f( 0, 1 ) => sax.pressure;
    0.23 => sax.stiffness;
    0.6 => sax.aperture;
    0.93 => sax.noiseGain;
    0.9 => sax.blowPosition;
    10.5 => sax.vibratoFreq;
    0.16 => sax.vibratoGain;
    0.85 => sax.pressure;

    // print
    <<< "---", "" >>>;
    <<< "stiffness:", sax.stiffness() >>>;
    <<< "aperture:", sax.aperture() >>>;
    <<< "noiseGain:", sax.noiseGain() >>>;
    <<< "blowPosition:", sax.blowPosition() >>>;
    <<< "vibratoFreq:", sax.vibratoFreq() >>>;
    <<< "vibratoGain:", sax.vibratoGain() >>>;
    <<< "pressure:", sax.pressure() >>>;

    // factor
    // Math.random2f( .75, 2 ) => float factor;
    1. => float factor;

    for( int i; i < notes.size(); i++ )
    {
        play( 12 + notes[i] - 36, 0.3 );
        300::ms * factor => now;
    }
}

// basic play function (add more arguments as needed)
fun void play( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => sax.freq;
    velocity => sax.noteOn;
}

// stiffness: 0.254792
// aperture: 0.600545
// noiseGain: 0.929194
// blowPosition: 0.573736
// vibratoFreq: 10.464181
// vibratoGain: 0.159028
// pressure: 0.865087
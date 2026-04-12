//------------------------------------------------------------------------------
// name: chorus.ck
// desc: basic demo of the Chorus UGen
//
// The Chorus UGen adds a chorus effect to a signal. Chorus refers to an audio
// effect in which multiple sounds occur close together in time, and with
// similar pitch. The slight deviations in pitch and time are generally small
// enough such that the signals are not perceived as being out-of-tune. The
// effect is often described as adding "shimmer", "richness", or "complexity"
// to the timbre. When implemented digitally, the chorus effect is acheived by
// taking a source signal, and mixing it with delayed copies of itself. The
// pitch of these copies is usually modulated using another signal like an LFO.
// In ChucK, you can adjust the depth and frequency of this modulation of pitch,
// as well as the amount of delay and how much of the chorus effect is present
// in the mix.
//
// author: Alex Han
// date: Spring 2023
//------------------------------------------------------------------------------

// set up signal chain
Chorus chor[4];
Pan2 p[4];


// connect
for( int i; i < chor.size(); i++ )
{
    // patch each voice
    adc => chor[i] => dac;
    
    -1 + (2*i/4) => p[i].pan;
    
    // initializing a light chorus effect
    // (try tweaking these values!)
    chor[i].baseDelay( 30*i::ms );
    chor[i].modDepth( .8*i );
    chor[i].modFreq( 0.1*i );
    chor[i].mix( .9 );
}

// time loop
while( true )
{
    // nothing to do here except advance time
    1::second => now;
}
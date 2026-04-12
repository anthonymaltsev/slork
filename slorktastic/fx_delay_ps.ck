// patch
adc => PitShift ps => DelayL delay => Pan2 p => dac;

//attempt to detect onset but not working yet
//adc => Gain detect => blackhole;

// set pitch shift
ps.mix(0.6);

// set delay max
1.0::second => delay.max;

// infinite time loop
while( true ) {
    // could add something that detects sound input
    Math.random2f(-2.5, 2.5) => ps.shift;
    Math.random2f(-1, 1) => p.pan;
    Math.random2f(0, 1)::second => delay.delay;
    1::second => now;
}



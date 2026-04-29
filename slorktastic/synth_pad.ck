// Main Oscillator
SinOsc s => dac;
440 => s.freq;

// LFO setup
PulseOsc lfo => blackhole; // blackhole avoids unintended audio output
0.5 => lfo.freq;        // 0.5 Hz LFO frequency

// Modulation loop
while (true) {
    // Modulate base frequency 440 Hz by +/- 10 Hz
    440 + (lfo.last()) => s.gain;
    1::ms => now;
}

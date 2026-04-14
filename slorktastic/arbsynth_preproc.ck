//-----------------------------------------------------------------------------
// name: arbsynth_preproc.ck
// desc: takes in sound bite and converts it to array sound controls for playback by arbsynth.ck
//       run in --silent mode, probably
//       a generalization of the code in /etude1/sparrow.ck
//
// usage: chuck arbsynth_preproc.ck:input.wav:output.arr
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

if( Machine.silent() == false )
{
    // print helpful message
    <<< "-----------------", "" >>>;
    <<< "chuck is currently running in REAL-TIME mode;", "" >>>;
    <<< "this step has no audio; may run much faster in SILENT mode!", "" >>>;
    <<< "to run in SILENT mode, restart chuck with --silent flag", "" >>>;
    <<< "-----------------", "" >>>;
}

if( me.args() < 2 ) {
    <<< "requires at least 2 arguments, input file and outputfile", "" >>>;
    me.exit(); 
}
me.arg(1) => string OUTPUT_FILE;
SndBuf buf(me.arg(0)) => FFT fft => blackhole;
if( !buf.ready() ) me.exit();
<<< "Loaded ", me.arg(0) >>>;

FileIO fout;
fout.open( OUTPUT_FILE, FileIO.WRITE );
if( !fout.good() )
{
    <<< "cannot open file for writing...", "" >>>;
    me.exit();
}

second / samp => float srate;
512 => fft.size;
Windowing.hann(fft.size()) => fft.window;
// our hop size (how often to perform analysis)
// fft.size()::samp => dur HOP;
1::ms => dur HOP;
if (me.args() >= 4) Std.atof(me.arg(3))::ms => HOP;

complex spec[fft.size() / 2 + 1];

100 => int CANDS;
10 => int N;
if (me.args() >= 3) Std.atoi(me.arg(2)) => N;
vec2 local_maxima[CANDS];
vec2 topN[N];

Math.ceil(buf.samples()::samp/HOP)$int => int num_lines;

fout <= N <= " " <= num_lines <= " " <= HOP/1::samp <= IO.newline();

// control loop
// while( true )
for (0 => int j; j < num_lines; j++)
{    
    clear(topN);
    clear(local_maxima);
    HOP => now;
    fft.upchuck();
    fft.spectrum(spec);
    for (0 => int i; i < spec.size(); i++ ) {
        i*srate/fft.size() => float freq;
        (spec[i]$polar).mag => float mag;
        0. => float prevmag;
        0. => float nextmag;
        if(i != 0) (spec[i-1]$polar).mag => prevmag;
        if(i < spec.size()-1) (spec[i+1]$polar).mag => nextmag;
        if (mag > prevmag && mag > nextmag)
            topN_check(mag, freq, local_maxima);
    }
    discard_similar(local_maxima, 500.);
    for (vec2 e : local_maxima) {
        topN_check(e.x, e.y, topN);
    }
    sort_by_freq(topN);
    for (vec2 e : topN) {
        fout <= e.y <= " " <= e.x <= " ";
    }
    fout <= IO.newline();

}

clear(topN);
clear(local_maxima);

fun void topN_check(float mag, float freq, vec2 list[]) {
    for (0 => int i; i < list.size(); i++) {
        if (mag > list[i].x) {
            for (N-1 => int j; j > i; j--) {
                list[j-1] => list[j];
            }
            @(mag, freq) => list[i];
            return;
        }
    }
}

fun void discard_similar(vec2 list[], float separator) {
    for (list.size()-1 => int i; i > 0; i--) {
        for (i-1 => int j; j >= 0; j --) {
            if (abs(list[i].y - list[j].y) < separator) {
                @(0., 0.) => list[i];
                break;
            }
        }
    }
}

fun void sort_by_freq(vec2 mag_freq[]) {
    polar freq_index[mag_freq.size()];
    for (0 => int i; i < freq_index.size(); i++) {
        %(mag_freq[i].y, (i $ float)/N) => freq_index[i];
    }
    freq_index.sort();
    vec2 tmp[mag_freq.size()];
    for (0 => int i; i < tmp.size(); i++) {
        mag_freq[Math.round(freq_index[i].phase*N)$int] => tmp[i];
    }
    for (0 => int i; i < tmp.size(); i++) {
        tmp[i] => mag_freq[i];
    }
}

fun void clear( vec2 list[]) {
    for (0 => int i; i < list.size(); i++) @(0, 0) => list[i];
}

fun float abs(float f) {
    if (f < 0.) return -f;
    return f;
}
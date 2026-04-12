//-----------------------------------------------------------------------------
// name: arbsynth.ck
// desc: arbitrary sound synthesizer in chuck
//       a generalization of the code in /etude1/sparrow.ck
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

public class ArbSynth {

    string fname;

    int N;
    int num_lines;
    int fft_size;
    vec2 freq_gain[][];

    SinOsc sins[];
    NRev rev;

    fun @construct(string fname_in, UGen outchan) {
        fname_in => fname;
        FileIO fin;
        fin.open(fname, FileIO.READ);

        StringTokenizer tok;
        fin.readLine() => string line;
        tok.set(line);

        Std.atoi(tok.next()) =>  N;
        Std.atoi(tok.next()) =>  num_lines;
        Std.atoi(tok.next()) => fft_size;

        new vec2[num_lines][N] @=> freq_gain;

        for (0 => int i; i < num_lines; i++) {
            fin.readLine() => line;
            tok.set(line);

            for (0 => int j; j < N; j++) {
                @(Std.atof(tok.next()), Std.atof(tok.next())) => freq_gain[i][j];
            }
        }
        new SinOsc[N] @=> sins;
        for (auto s : sins) {
            s => rev;
        }

        0.01 => rev.mix;
        rev => outchan;

    }

    fun void playback() {
        vec2 curr_freq_gain;

        for (0 => int i; i < num_lines; i++) {
            for (0 => int j; j < N; j++) {
                freq_gain[i][j] => curr_freq_gain;
                10 * curr_freq_gain.y => sins[j].gain;
                curr_freq_gain.x => sins[j].freq;
            }
            fft_size::samp => now;
        }

        for (auto s : sins) 0. => s.gain;
    }

    // indexer is monotonic function of breakpoints
    // returns linear interpolation of closest 2 points in table to queried index
    //   constraint: indexer.size() == table.size() && index >= indexer[0] && index <= indexer[indexer.size() - 1]
    fun float interp_lookup(float indexer[], float table[], float index) {
        for (0 => int i; i < indexer.size()-1; 1 +=> i) {
            if (index >= indexer[i] && index < indexer[i+1]) {
                return table[i] + (table[i+1]-table[i]) * ((index-indexer[i])/(indexer[i+1]-indexer[i]));
            }
        }
        return table[table.size() - 1];
    }

}

ArbSynth arb(me.arg(0), dac);
arb.playback();
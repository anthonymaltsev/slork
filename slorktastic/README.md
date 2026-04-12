## ArbSynth instructions

Run preprocessing on a wav file:
```
chuck arbsynth_preproc.ck:data/sparrow.wav:data/sparrow.arr:5:1
```
Args in order are: input, output, number of sin waves, time step.

```
chuck arbsynth.ck:data/sparrow.arr
```

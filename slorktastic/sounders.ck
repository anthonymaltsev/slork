public class DemonSounder {
  Gain master_gain => Envelope master_env => dac;
  50::ms => dur GAIN_FADE_DUR;

  SawOsc base_osc => master_gain;
  SawOsc fifth_osc => master_gain;
  TriOsc bassy_osc => master_gain;
  Noise scary_noise => master_gain;

  // vibrato
  TriOsc lfo => Envelope lfo_env => blackhole;

  // implicit state here - if null, not running
  Shred @ _shred;

  1000. => float base_freq;

  .1 => float INITIAL_GAIN;
  .5 => float MAX_GAIN;
  1.2 => float GAIN_RAMP;

  INITIAL_GAIN => float current_gain;

  .2 => float CONSTRAINED_MASTER_GAIN;
  .4 => float UNCONSTRAINED_MASTER_GAIN;
  .15 => float CONSTRAINED_NOISE_GAIN;
  .7 => float UNCONSTRAINED_NOISE_GAIN;
  300::ms => dur UNCONSTRAINED_RAMP_DUR;

  CONSTRAINED_MASTER_GAIN => float target_master_gain;
  0 => int _unconstrained;

  fun @construct() {
    300::ms => lfo_env.duration;
    GAIN_FADE_DUR => master_env.duration;

    1 => base_osc.gain;
    .6 => fifth_osc.gain;
    .8 => bassy_osc.gain;
    CONSTRAINED_NOISE_GAIN => scary_noise.gain;

    // never changes (for now)
    (base_freq * 1/8) => bassy_osc.freq;

    10 => lfo.freq;
    -0.25 => lfo.phase;
    lfo_env.keyOn();
    
    // start muted
    0 => master_gain.gain;
  }

  fun start() {
    if (_shred != null) return; // noop
    target_master_gain => master_gain.gain;
    master_env.keyOn();
    spork ~ _run_sound_loop() @=> _shred;
  }

  fun void set_unconstrained(int on) {
    on => _unconstrained;
    if (on) {
      spork ~ _ramp_to_unconstrained();
    } else {
      spork ~ _ramp_to_constrained();
    }
  }

  fun void _ramp_to_constrained() {
    CONSTRAINED_NOISE_GAIN => scary_noise.gain;
    CONSTRAINED_MASTER_GAIN => target_master_gain;
    if (_shred == null) return;
    master_gain.gain() => float start_gain;
    now => time t0;
    while (now - t0 < UNCONSTRAINED_RAMP_DUR) {
      (now-t0) / UNCONSTRAINED_RAMP_DUR => float t;
      ((1.-t) * start_gain + t * CONSTRAINED_MASTER_GAIN) => master_gain.gain;
      10::ms => now;
    }
    CONSTRAINED_MASTER_GAIN => master_gain.gain;
  }

  fun void _ramp_to_unconstrained() {
    UNCONSTRAINED_NOISE_GAIN => scary_noise.gain;
    UNCONSTRAINED_MASTER_GAIN => target_master_gain;
    master_gain.gain() => float start_gain;
    now => time t0;
    while (now - t0 < UNCONSTRAINED_RAMP_DUR) {
      (now-t0) / UNCONSTRAINED_RAMP_DUR => float t;
      ((1.-t) * start_gain + t * UNCONSTRAINED_MASTER_GAIN) => master_gain.gain;
      10::ms => now;
    }
    UNCONSTRAINED_MASTER_GAIN => master_gain.gain;
  }
  
  fun stop() {
    if (_shred == null) return;
    master_env.keyOff();
    GAIN_FADE_DUR => now;
    0 => master_gain.gain;
    _shred.exit();
    null @=> _shred;
  }

  function escalate() {
    30 +=> base_freq;
    if (current_gain < MAX_GAIN) {
      GAIN_RAMP *=> current_gain;
    }
  }

  fun _run_sound_loop() {
    float cur_freq;
    while(true){
      0.03*lfo_env.last() + 1 => float vibrato_waver;
      (base_freq*vibrato_waver) => cur_freq;

      cur_freq => base_osc.freq;
      // perfect fifth ratio 3/2
      (cur_freq*3/2) => fifth_osc.freq;

      5::ms => now;
    }
  }
}

public class BeepSounder {
  Gain master => dac;

  SinOsc clean_osc => Envelope clean_env => master;
  SqrOsc dirty_osc => Envelope dirty_env => master;
  Noise noise_osc => Envelope noise_env => master;

  880. => float BASE_FREQ;
  30::ms => dur BEEP_DUR;

  0. => float chaos;
  1. => float fade;

  fun @construct() {
    BASE_FREQ => clean_osc.freq;
    // slightly detuned upper layer
    BASE_FREQ * 2.01 => dirty_osc.freq;

    BEEP_DUR / 2 => clean_env.duration;
    BEEP_DUR / 2 => dirty_env.duration;
    BEEP_DUR / 2 => noise_env.duration;

    .4 => master.gain;
  }

  fun void set_chaos(float c) {
    Math.clampf(c, 0., 1.) => chaos;
  }
  fun void set_fade(float f) {
    Math.clampf(f, 0., 1.) => fade;
  }

  fun void beep() {
    spork ~ _do_beep();
  }

  fun void _do_beep() {
    if (fade < 0.01) return;

    chaos => float c;
    fade => float f;

    f => master.gain;
    (1. - c) * .35 => clean_osc.gain;
    c * .3 => dirty_osc.gain;
    c * c * .35 => noise_osc.gain;

    clean_env.keyOn();
    dirty_env.keyOn();
    noise_env.keyOn();
    BEEP_DUR => now;
    clean_env.keyOff();
    dirty_env.keyOff();
    noise_env.keyOff();
    BEEP_DUR => now;
  }
}
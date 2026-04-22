class Mouse {
  vec3 world_pos;
  Shred @ _loop;
  
  fun void begin() {
    spork ~ _begin_update_loop() @=> _loop;
  }

  fun void stop() {
    if (_loop != null) Machine.remove(_loop.id());
    null => _loop;
  }

  fun int is_running() {
    return _loop != null;
  }

  fun @destruct() {
    stop();
  }

  fun void _begin_update_loop() {
    while (true) {
      GG.nextFrame() => now;
      GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1.0) => world_pos;
    }
  }
}

class PianoKey {
  @(0.98, 0.97, 0.94) => vec3 COLOR_WHITE;
  @(0.05, 0.05, 0.06) => vec3 COLOR_BLACK;
  @(0.74, 0.78, 0.90) => vec3 COLOR_WHITE_PRESSED;
  @(0.28, 0.34, 0.50) => vec3 COLOR_BLACK_PRESSED;

  // just read off degree values from the color wheel as i liked 'em:
  // https://miro.medium.com/v2/resize:fit:1200/1*tQYAE9PU2FIrZV5rKwT7AQ.jpeg
  [0., 30., 60., 120., 210., 270., 300.] @=> float COLOR_WHEEL[];

  GPlane plane;
  FlatMaterial mat;
  int midi_note;
  int is_black;
  vec3 base_color;
  vec3 pressed_color;
  float rest_y;
  int is_pressed;
  int white_idx;

  false => int rainbow_mode;
  false => int funky_vibrato;

  // 0 = funky_vibrato disabled, 1 = enabled
  // so we can access by idx here
  [0., 10.] @=> float VIBRATO_PRESETS[];

  // upgraded to have some fun vibrato with help from jack atherton (shoutout!):
  // https://ccrma.stanford.edu/~lja/timbre-library/chuck/vibratosawlead.ck
  1.0 => float vibrato_waver;
  float base_freq;
  TriOsc osc;
  ADSR env;
  TriOsc lfo => Envelope lfo_env => blackhole;
  300::ms => lfo_env.duration;
  0 => lfo.freq;

  Shred @ _vibrato_messer;
  Shred @ _lfo_loop;

  fun @construct(int note, int black, int idx) {
    note => midi_note;
    black => is_black;
    idx => white_idx;

    plane.material(mat);

    osc => env => dac;
    env.set(6::ms,80::ms,.65,200::ms);

    Std.mtof(note) => float f;
    f => base_freq;
    (base_freq*vibrato_waver) => osc.freq;
    .7 => osc.gain;

    if (is_black) {
      COLOR_BLACK => base_color;
      COLOR_BLACK_PRESSED => pressed_color;
      mat.color(base_color);
    } else {
      recolor_white();
    }
  }

  fun void place(float cx, float cy, float w, float h, float z) {
    cy => rest_y;
    plane.sca(@(w, h, 1.));
    plane.pos(@(cx, cy, z));
  }

  fun int hits(vec3 mp) {
    // ensure mouse position (mp) is within bounds of the key.
    // nuff said
    plane.scaWorld() => vec3 s;
    plane.posWorld() => vec3 p;
    return (mp.x > p.x - s.x/2. && mp.x < p.x + s.x/2. &&
            mp.y > p.y - s.y/2. && mp.y < p.y + s.y/2.);
  }

  fun void hit() {
    // call when we want to press the key
    if (is_pressed) return;

    // reset lfo phase and freq
    -0.25 => lfo.phase;
    VIBRATO_PRESETS[funky_vibrato] => lfo.freq;

    if (funky_vibrato) {
      spork ~ _mess_with_vibrato() @=> _vibrato_messer;
      spork ~ _run_lfo_loop() @=> _lfo_loop;
    }
    
    1 => is_pressed;
    mat.color(pressed_color);
    plane.pos() => vec3 p;
    plane.pos(@(p.x, rest_y, p.z));
    env.keyOn();
  }

  fun void unhit() {
    // call when key is released!!
    if (!is_pressed) return;
    if (_vibrato_messer != null) Machine.remove(_vibrato_messer.id());
    if (_lfo_loop != null) Machine.remove(_lfo_loop.id());
    0 => is_pressed;
    mat.color(base_color);
    plane.pos() => vec3 p;
    plane.pos(@(p.x, rest_y, p.z));
    env.keyOff();
  }

  fun void recolor_white() {
    if (rainbow_mode) {
      Color.hsv2rgb(@(COLOR_WHEEL[white_idx % COLOR_WHEEL.size()],.7,1.)) => base_color;
      base_color - @(0,.1,.1) => pressed_color;
    } else {
      COLOR_WHITE => base_color;
      COLOR_WHITE_PRESSED => pressed_color;
    }
    mat.color(base_color);
  }

  fun void _run_lfo_loop() {
    1 => lfo_env.keyOn;
    -0.25 => lfo.phase;
    while (true) {
      // modulation only when funky_vibrato flag enabled
      if (funky_vibrato) {
        0.03*lfo_env.last() + 1 => vibrato_waver;
      } else {
        1.0 => vibrato_waver;
      }
      (base_freq*vibrato_waver) => osc.freq;
      5::ms => now;
    }
  }

  fun void _mess_with_vibrato() {
    while (lfo.freq() > .5) {
      lfo.freq()*.995 => lfo.freq;
      10::ms => now;
    }
  }
}

// a "bad" piano class i made. just not a very exciting instrument.
// this is by design. goal is to make it more extensible (maybe some
// pitch shifting or other weirdness/complexity) as fictitiously
// introduced by the "clawed code" "agent"
public class PianoKeyboard extends GGen {
  @(0.08, 0.06, 0.05) => vec3 COLOR_BODY;

  // C4=60, D4=62, E4=64, F4=65, G4=67, A4=69, B4=71, C5=72
  [60, 62, 64, 65, 67, 69, 71, 72] @=> int white_midi[];
  // C#4=61, D#4=63, F#4=66, G#4=68, A#4=70
  [61, 63, 66, 68, 70] @=> int black_midi[];
  // black keys come after white keys at indices [0,1,3,4,5]
  // not sure if there's a better way to do this! shall work 4 now
  [0, 1, 3, 4, 5] @=> int black_after[];

  float WINDOW_W;
  float WINDOW_H;

  GPlane body;
  FlatMaterial body_mat;

  // 8 white keys C4..C5, 5 black keys C#4..A#4
  PianoKey white_keys[0];
  PianoKey black_keys[0];
  // array for addressing keys of all types (can
  // iterate through this list once rather than
  // a separate iteration for each of the white and
  // black lists
  PianoKey all_keys[0];

  Mouse mouse;
  PianoKey @ active_key;
  int was_down;

  int playable;
  int rainbow_mode;
  int funky_vibrato;
  int _attached;

  fun void setSize(float w, float h) {
    w => WINDOW_W;
    h => WINDOW_H;
    if (!_attached) {
      _init_body();
      _init_keys();
      1 => _attached;
    }
  }

  fun void set_playable(int play) {
    if (play != playable) {
      if (play) {
        mouse.begin();
      } else {
        mouse.stop();
      }
    }
    play => playable;
  }

  fun void set_rainbow_mode(int enabled) {
    PianoKey @ wk;
    for (0 => int i; i < white_keys.size(); i++) {
      white_keys[i] @=> wk;
      enabled => wk.rainbow_mode;
      wk.recolor_white();
    }
    enabled => rainbow_mode;
  }

  fun void set_funky_vibrato(int enabled) {
    for (0 => int i; i < all_keys.size(); i++) {
      enabled => all_keys[i].funky_vibrato;
    }
    enabled => funky_vibrato;
  }

  fun void _init_body() {
    body --> this;
    body_mat.color(COLOR_BODY);
    body.material(body_mat);
    body.sca(@(WINDOW_W, WINDOW_H, 1.));
    body.pos(@(0., 0., -0.01));
  }

  fun void _init_keys() {
    WINDOW_H * 0.06 => float inset;
    WINDOW_W - 2.*inset => float keys_w;
    WINDOW_H - 2.*inset => float keys_h;
    keys_w / 8. => float white_w;
    WINDOW_W/2. => float hw;
    WINDOW_H/2. => float hh;
    -hw + inset => float keys_left;
    hh - inset => float white_top;
    -hh + inset => float white_bot;
    white_w * 0.05 => float gap;
    (white_top + white_bot) / 2. => float white_cy;

    for (0 => int i; i < 8; i++) {
      new PianoKey(white_midi[i], 0, i) @=> PianoKey wk;
      all_keys << wk;
      white_keys << wk;
      keys_left + (i + 0.5) * white_w => float cx;
      wk.place(cx, white_cy, white_w - gap, keys_h, 0.02);
      wk.plane --> this;
    }

    white_w * 0.62 => float black_w;
    keys_h * 0.62 => float black_h;
    white_top - black_h/2. => float black_cy;

    for (0 => int i; i < black_midi.size(); i++) {
      new PianoKey(black_midi[i], 1, 0) @=> PianoKey bk;
      all_keys << bk;
      black_keys << bk;
      keys_left + (black_after[i] + 1) * white_w => float cx;
      bk.place(cx, black_cy, black_w, black_h, 0.04);
      bk.plane --> this;
    }
  }

  fun void update() {
    // don't attempt to play when mouse inactive
    // (as controlled by set_playable function)
    if (!mouse.is_running()) return;

    GWindow.mouseLeft() => int is_down;
    is_down && !was_down => int edge_down;
    !is_down && was_down => int edge_up;
    is_down => was_down;

    if (is_down) {
      mouse.world_pos => vec3 mp;
      PianoKey @ hit;

      // black keys sit on top of white keys visually, so check them first
      for (0 => int i; i < black_keys.size(); i++) {
        if (black_keys[i].hits(mp)) {
          black_keys[i] @=> hit;
          break;
        }
      }
      if (hit == null) {
        for (0 => int i; i < white_keys.size(); i++) {
          if (white_keys[i].hits(mp)) {
            white_keys[i] @=> hit;
            break;
          }
        }
      }

      // release old key if i drag away
      if (hit != active_key) {
        if (active_key != null) active_key.unhit();
        if (hit != null) hit.hit();
        hit @=> active_key;
      }
    }

    if (edge_up && active_key != null) {
      active_key.unhit();
      null @=> active_key;
    }
  }
}

public class LightsManager {
  1 => int MIN_CHANNEL;
  17 => int MAX_CHANNEL;

  1 => int HOUSE_LEFT_SCREEN;
  2 => int HOUSE_RIGHT_SCREEN;
  3 => int HOUSE_LEFT_MIDFRONT;
  4 => int HOUSE_RIGHT_MIDFRONT;
  5 => int HOUSE_LEFT_MIDBACK;
  6 => int HOUSE_RIGHT_MIDBACK;
  // the big lights just behind the "midfront" lights
  // (not sure what you call these)
  7 => int HOUSE_LEFT_BIGBOY;
  8 => int HOUSE_RIGHT_BIGBOY;
  9 => int HOUSE_LEFT_MOVINGARM_LIGHT;
  10 => int HOUSE_RIGHT_MOVINGARM_LIGHT;
  11 => int SPOTLIGHT_1;
  12 => int SPOTLIGHT_2;
  // 13 seems skipped... spoooooky
  14 => int HOUSE_LIGHTS_REAR;
  15 => int HOUSE_LIGHTS_FRONT;
  // 16???
  17 => int CEILING_LIGHTS_FRONT;
  // 18 skipped?
  19 => int HOUSE_LEFT_MOVINGARM_CTRL;
  20 => int HOUSE_RIGHT_MOVINGARM_CTRL;

  [
    HOUSE_LEFT_SCREEN,
    HOUSE_RIGHT_SCREEN,
    HOUSE_LEFT_MIDFRONT,
    HOUSE_RIGHT_MIDFRONT,
    HOUSE_LEFT_MIDBACK,
    HOUSE_RIGHT_MIDBACK,
    HOUSE_LEFT_BIGBOY,
    HOUSE_RIGHT_BIGBOY
  ] @=> int COOKING_LIGHTS[];

  // brightness consts for cooking light show!!
  10 => int COOKING_DIM_VAL;
  10 => int COOKING_PULSE_MIN;
  100 => int COOKING_PULSE_MAX;

  // "localhost" => string hostname;
  "192.168.185.187" => string hostname;
  8005 => int port;

  Shred @ _flash_spork;
  Shred @ _pulse_spork;

  fun void init() {
    all_out();
    _reset_blue();
    set_cooking_lights(false);
    _set_val(HOUSE_LIGHTS_REAR, 0);
    _set_val(HOUSE_LIGHTS_FRONT, 0);
    _set_val(CEILING_LIGHTS_FRONT, 0);
  }

  fun void flash() {
    if (_flash_spork != null) {
      Machine.remove(_flash_spork.id());
      null => _flash_spork;
      _reset_blue();
    }
    spork ~ _flash() @=> _flash_spork;
  }

  // set house lights on for when piece is over
  fun void house_neutral() {
    _kill_pulse();
    _set_val(HOUSE_LIGHTS_REAR, 50);
    _set_val(HOUSE_LIGHTS_FRONT, 50);
    _set_val(CEILING_LIGHTS_FRONT, 50);
    for (0 => int i; i < COOKING_LIGHTS.size(); i++) {
      _set_val(COOKING_LIGHTS[i], 0);
    }
  }

  fun void all_out() {
    _kill_pulse();
    for (MIN_CHANNEL => int ch; ch <= MAX_CHANNEL; ch++)
      _set_val(ch, 0);
  }

  fun void set_spotlight(int val) {
    // _set_val(SPOTLIGHT_1, val);
    <<< val >>>;
    _set_color(HOUSE_LEFT_MOVINGARM_LIGHT, 0, 0);
    _set_val(HOUSE_LEFT_MOVINGARM_LIGHT, val);
  }

  fun void set_cooking_lights(int on) {
    <<< "set cook lights:", on ? "on" : "off" >>>;
    _kill_pulse();
    if (on) {
      spork ~ _run_cooking_pulse() @=> _pulse_spork;
    } else {
      for (0 => int i; i < COOKING_LIGHTS.size(); i++) {
        _set_val(COOKING_LIGHTS[i], COOKING_DIM_VAL);
      }
    }
  }

  fun void _run_cooking_pulse() {
    // TODO: see how this looks on CCRMA stage, and maybe add some more
    // variation to the pulse (rn it's just random brightness changes
    // at random intervals)
    while (true) {
      for (0 => int i; i < COOKING_LIGHTS.size(); i++) {
        Math.random2(COOKING_PULSE_MIN, COOKING_PULSE_MAX) => int v;
        _set_val(COOKING_LIGHTS[i], v);
      }
      Math.random2f(140.,280.)::ms => now;
    }
  }

  fun void _kill_pulse() {
    if (_pulse_spork != null) {
      Machine.remove(_pulse_spork.id());
      null => _pulse_spork;
    }
  }

  fun _set_cooking_lights_color(int hue, int sat) {
    for (0 => int i; i < COOKING_LIGHTS.size(); i++) {
      _set_color(COOKING_LIGHTS[i], hue, sat);
    }
  }

  fun void _flash() {
    _set_cooking_lights_color(0, 90);
    200::ms => now;
    _reset_blue();
    200::ms => now;
  }

  fun void _reset_blue() {
    _set_cooking_lights_color(230, 95);
  }

  fun void _set_color(int chan, int hue, int sat) {
    _select_chan(chan);
    _send_osc("/cs/color/hs/" + hue + "/" + sat);
  }
  
  fun void _set_val(int chan, int val) {
    _select_chan(chan);
    _send_osc("/cs/chan/at/" + val);
  }

  fun void _select_chan(int chan) {
    _send_osc("/cs/chan/select/" + chan);
  }

  fun void _send_osc(string chan) {
    _make_message(chan) @=> OscOut msg;
    _send_osc(msg);
  }
  fun void _send_osc(OscOut msg) {
    // don't spork bc a child shred gets killed
    // if the caller exits before it runs (my bad guys)
    msg.send();
  }

  fun OscOut _make_message(string chan) {
    OscOut xmit;
    xmit.dest(hostname, port);
    xmit.start(chan);
    return xmit;
  }
}
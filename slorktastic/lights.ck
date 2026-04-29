public class LightsManager {
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
  14 => int HOUSE_LIGHS_REAR;
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
    HOUSE_LEFT_BIGBOY,
    HOUSE_RIGHT_BIGBOY
  ] @=> int COOKING_LIGHTS[];

  // "localhost" => string hostname;
  "192.168.185.187" => string hostname;
  8005 => int port;

  Shred @ _flash_spork;

  fun void init() {
    _reset_blue();
    set_cooking_lights(false);
  }

  fun void flash() {
    if (_flash_spork != null) {
      Machine.remove(_flash_spork.id());
      null => _flash_spork;
      _reset_blue();
    }
    spork ~ _flash() @=> _flash_spork;
  }

  fun set_cooking_lights(int on) {
    <<< "set cook lights:", on ? "on" : "off" >>>;
    for (0 => int i; i < COOKING_LIGHTS.size(); i++) {
      _set_val(COOKING_LIGHTS[i], on ? 100 : 0);
    }
  }

  fun _set_cooking_lights_color(int hue, int sat) {
    for (0 => int i; i < COOKING_LIGHTS.size(); i++) {
      _set_color(COOKING_LIGHTS[i], hue, sat);
    }
  }

  fun void _flash() {
    _set_cooking_lights_color(0, 100);
    200::ms => now;
    _reset_blue();
    200::ms => now;
  }

  fun void _reset_blue() {
    _set_cooking_lights_color(270, 100);
  }

  fun void set_spotlight(int val) {
    _set_val(11, val);
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
    spork ~ msg.send();
  }

  fun OscOut _make_message(string chan) {
    OscOut xmit;
    xmit.dest(hostname, port);
    xmit.start(chan);
    return xmit;
  }
}

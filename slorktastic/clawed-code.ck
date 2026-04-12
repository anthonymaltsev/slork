@import {"clawed.ck"}

public class ClawedCode {
  ["·","✢","*","✶","✻","✽"] @=> string SPINNER_SEQUENCE[];
  @(0.005, 0.005, 0.007) => vec3 COLOR_BG;
  @(.24,.48,1.) => vec3 COLOR_PRIMARY;

  80 => int TERMINAL_W;
  24 => int TERMINAL_H;
  .45 => float CHAR_W;
  1. => float CHAR_H;
  .2 => float FONT_SIZE;
  .2 => float TOP_BOX_INSET;
  16 => int SCALE_FACTOR;
    (SCALE_FACTOR / FONT_SIZE) => float FONT_RATIO;

  (TERMINAL_W * CHAR_W * SCALE_FACTOR) => float WINDOW_W;
  (TERMINAL_H * CHAR_H * SCALE_FACTOR) => float WINDOW_H;
  (WINDOW_W / WINDOW_H) => float ASPECT_RATIO;

  float CAM_LEFT;
  float CAM_TOP;
  string VERBS[0];

  // terminal display states
  "hello world" => string prompt_text;
  "Loading" => string current_verb;
  0 => int spinner_idx;
  2500::ms => dur verb_change_delay;

  GText terminal;
  GText verb_line;
  Clawed @ clawed;

  fun @construct() {
    _load_verbs();

    _init_window();
    _init_camera();
    _init_terminal();
    _init_clawed();
  }

  fun void run() {
    spork ~ _run_spinner();
    spork ~ _run_change_verb();

    while (true) {
      GG.nextFrame() => now;

      // terminal.text(TERMINAL_LINE + "\n> " + "text will go here!" + "\n" + TERMINAL_LINE);
      terminal.text("❯ " + prompt_text + "▌");
      verb_line.text(SPINNER_SEQUENCE[spinner_idx] + " " + current_verb + "…");
    }
  }

  fun void _load_verbs() {
    FileIO fin;
    fin.open("verbs.txt", FileIO.READ);

    if (fin.good()) {
      while (fin.more()) VERBS << fin.readLine();
    }

    <<< "loaded", VERBS.size(), "verbs" >>>;
  }

  fun void _run_change_verb() {
    _show_verb("Loading");
    while (true) {
      verb_change_delay => now;
      Math.random2(0, VERBS.size() - 1) => int verb_idx;
      verb_idx > -1 && VERBS.size() > 0 => int verbs_ready;
      _show_verb(verbs_ready ? VERBS[verb_idx] : "Loading");

      if (verb_change_delay > 75::ms) .85 *=> verb_change_delay;
    }
  }

  fun void _run_spinner() {
    SPINNER_SEQUENCE.size() => int spinner_len;
    spinner_len * 2 => int spinner_full;
    0 => int state;

    while (true) {
      125::ms => now;

      if (state < spinner_len) {
        // 0-5 - standard order
        state => spinner_idx;
      } else {
        // 6-11 - reverse order
        (spinner_full - state - 1) => spinner_idx;
      }

      (state + 1) % spinner_full => state;
    }
  }

  fun void _show_verb(string verb) {
    verb => current_verb;
  }

  fun void _init_window() {
    GWindow.windowed(WINDOW_W $ int, WINDOW_H $ int);
    GWindow.center();
    GWindow.title("clawed --dangerously-skip-critical-thinking — " + TERMINAL_W + "×" + TERMINAL_H);
    GG.scene().backgroundColor(COLOR_BG);
  }

  fun void _init_camera() {
    GG.camera() @=> GCamera cam;
    cam.orthographic();
    cam.pos(@(0., 0., 11.));
    cam.lookAt(@(0., 0., 0.));

    // save camera offsets for positioning relative to the
    // top-left corner of the "terminal" window
    (-ASPECT_RATIO * GG.camera().viewSize()) / 2. => CAM_LEFT;
    (GG.camera().viewSize() / 2.) => CAM_TOP;
  }

  fun void _init_terminal() {
    _draw_top_box();
    // _draw_prompt_container_lines();

    terminal.font("fonts/DejaVuSansMono.ttf");
    terminal.size(FONT_SIZE);
    terminal.color(@(1., 1., 1., 0.9));
    terminal.controlPoints(@(0., 1.));
    terminal.pos(@(CAM_LEFT + FONT_SIZE, CAM_TOP - (FONT_SIZE*12), 0.));

    verb_line.font("fonts/DejaVuSansMono.ttf");
    verb_line.size(FONT_SIZE);
    verb_line.color(COLOR_PRIMARY);
    verb_line.controlPoints(@(0.,1.));
    verb_line.pos(@(CAM_LEFT + FONT_SIZE, CAM_TOP - (FONT_SIZE*15.15), 0.));

    terminal --> GG.scene();
    verb_line --> GG.scene();
  }

  fun void _init_clawed() {
    // clawed == the mascot of "clawed code"
    new Clawed() @=> clawed;

    @(
      CAM_LEFT+(clawed.get_full_width()/2.),
      CAM_TOP-(clawed.get_full_height()/2.) - FONT_SIZE,
      0.
    ) => vec3 clawed_pos;

    clawed.sca(@(.7,.7,.7));
    clawed.pos(clawed_pos);
  }

  fun void _draw_prompt_container_lines() {
    GLines line_top --> GG.scene();
    // GLines line_bottom --> GG.scene();

    CAM_LEFT + TOP_BOX_INSET => float left_corner;
    (CAM_TOP - TOP_BOX_INSET + (FONT_SIZE * 8)) => float top_corner;

    line_top.positions([@(left_corner,top_corner),@(-left_corner,top_corner)]);
    line_top.color(@(1.,1.,1.));
  }

  fun void _draw_top_box() {
    GLines outline --> GG.scene();
    outline.width(.02);

    CAM_LEFT + TOP_BOX_INSET => float left_corner;
    -left_corner => float right_corner;
    CAM_TOP - TOP_BOX_INSET => float top_corner;
    top_corner - 2. => float bottom_corner;

    outline.positions([
      @(left_corner,bottom_corner),
      @(right_corner,bottom_corner),
      @(right_corner,top_corner),
      @(left_corner+3.2,top_corner),
      @(left_corner+.6,top_corner),
      @(left_corner,top_corner),
      @(left_corner,bottom_corner)
    ]);
    outline.colors([
      COLOR_PRIMARY,
      COLOR_PRIMARY,
      COLOR_PRIMARY,
      COLOR_BG,
      COLOR_BG,
      COLOR_PRIMARY,
    ]);

    GText heading --> GG.scene();
    heading.text("Clawed Code v4.5.1");
    heading.size(FONT_SIZE);
    heading.color(@(1., 1., 1., 0.9));
    heading.controlPoints(@(0., 1.));
    heading.pos(@(CAM_LEFT+(FONT_SIZE * 4.), CAM_TOP-(FONT_SIZE * .6), 0.));
  }
}

ClawedCode code();
code.run();
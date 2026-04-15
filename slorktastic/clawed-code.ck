@import {"clawed.ck", "gkr.ck"}

public class ClawedCode {
  "Flibbertigibbeting" => string DEFAULT_VERB;
  ["·","✢","*","✶","✻","✽"] @=> string SPINNER_SEQUENCE[];
  @(0.005, 0.005, 0.007) => vec3 COLOR_BG;
  @(.24,.48,1.) => vec3 COLOR_PRIMARY;

  80 => int TERMINAL_W;
  24 => int TERMINAL_H;
  .45 => float CHAR_W;
  1. => float CHAR_H;
  16 => int SCALE_FACTOR;

  .2 => float FONT_SIZE;
  "fonts/DejaVuSansMono.ttf" => string FONT_FACE;

  @(FONT_SIZE, -(FONT_SIZE*12.)) => vec2 PROMPT_POS;
  // @(FONT_SIZE, -(FONT_SIZE*15.15)) => vec2 VERB_LINE_POS;
  PROMPT_POS + @(0., -(FONT_SIZE*2.7)) => vec2 VERB_LINE_POS;

  .2 => float TOP_BOX_INSET;
  .12 => float PROMPT_CONTAINER_PADDING;

  (TERMINAL_W * CHAR_W * SCALE_FACTOR) => float WINDOW_W;
  (TERMINAL_H * CHAR_H * SCALE_FACTOR) => float WINDOW_H;
  (WINDOW_W / WINDOW_H) => float ASPECT_RATIO;

  float CAM_LEFT;
  float CAM_TOP;
  string VERBS[0];
  vec2 RELATIVE;

  // terminal display states
  "" => string prompt_text;
  "❯" => string prompt_display;
  DEFAULT_VERB => string current_verb;
  0 => int spinner_idx;
  2500::ms => dur verb_change_delay;
  1 => int num_lines;
  1 => int prompt_editable;

  GKeyboardReceiver keyboard;
  GText prompt;
  GText verb_spinner;
  GText verb_line;
  GLines line_top;
  GLines line_bottom;
  Shred @ verb_pulse;
  ClawedAnimated @ clawed;
  ClawedFlock @ flock;

  fun @construct() {
    _load_verbs();

    _init_window();
    _init_camera();
    _init_terminal();
    _init_clawed();
    _update_prompt_display();
  }

  fun void run() {
    spork ~ _run_text_input();

    while (true) {
      flock.pos(@(0.,0.,0.));
      GG.nextFrame() => now;
      keyboard.listen();

      prompt.text(prompt_display);

      verb_spinner.text(SPINNER_SEQUENCE[spinner_idx]);
      verb_line.text("  " + current_verb + "…");
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

  fun void _run_text_input() {
    while (true) {
      keyboard.wait => now;
      
      // "enter" key starts the whole shabang
      if (keyboard.wait.enter) {
        _get_crazy_with_it();
      }

      if (keyboard.wait.backspace) {
        if (prompt_text.length() > 0)
          prompt_text.substring(0, prompt_text.length() - 1) => prompt_text;
      } else if (keyboard.wait.ctrl) {
        if (keyboard.wait.val == "u") {
          // ctrl-u: clear prompt
          "" => prompt_text;
        } else if (keyboard.wait.val == "j") {
          // ctrl-j: newline
          "\n" +=> prompt_text;
        }
      } else {
        keyboard.wait.val +=> prompt_text;
      }
      _update_prompt_display();
    }
  }

  fun void _get_crazy_with_it() {
    // hide cursor
    0 => prompt_editable;
    _update_prompt_display();

    // flap bird
    clawed.animate_flapping();
    
    // verb/spinner init
    _redraw_verb();
    verb_line --> GG.scene();
    verb_spinner --> GG.scene();
    spork ~ _run_spinner();
    spork ~ _run_change_verb();
  }


  fun void _update_prompt_display() {
    "❯ " => string init;

    0 => int start;
    0 => int end;
    int is_first_line;
    int is_last_line;
    0 => int iter;

    1 => num_lines;
    
    while (start < prompt_text.length() && !is_last_line) {
      (start + TERMINAL_W - 4) => end;
      
      start == 0 => is_first_line;
      end >= prompt_text.length() => is_last_line;

      if (is_last_line) prompt_text.length() => end;

      (end - start) => int len;

      prompt_text.substring(start, len) => string line;
      ((is_first_line ? "" : "\n  ") + line) +=> init;

      end => start;
      if (!is_last_line) num_lines++;
    }

    init + (prompt_editable ? "|" : "") => prompt_display;

    _redraw_verb();
    _draw_prompt_container();
  }

  fun void _run_change_verb() {
    while (true) {
      verb_change_delay => now;
      Math.random2(0, VERBS.size() - 1) => int verb_idx;
      verb_idx > -1 && VERBS.size() > 0 => int verbs_ready;
      _show_verb(verbs_ready ? VERBS[verb_idx] : DEFAULT_VERB);

      if (verb_change_delay > 75::ms) .85 *=> verb_change_delay;
      if (clawed.flap_delay > 15::ms) {
        .93 *=> clawed.flap_delay;
        <<< "echo" >>>;
        if (flock.birdie_count < 16) flock.add_birdie();
        <<< "echo2" >>>;
      }
    }
  }

  fun void _run_spinner() {
    SPINNER_SEQUENCE.size() => int spinner_len;
    spinner_len * 2 => int spinner_full;
    0 => int state;

    while (true) {
      100::ms => now;

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

  fun void _pulse_verb_once() {
    0 => int prog;
    float sca;
    float t;

    while (prog < 1000) {
      (verb_change_delay < 1000::ms
        ? (verb_change_delay + 1000::ms) / 2000
        : 1::ms)
      => dur verb_delay_factor;
      verb_delay_factor => now;
      
      // reverse progress and clamp from 0 to 1
      1. - (prog $ float / 1000.) => t;
      1 + (t * t) * (1::ms / verb_delay_factor) => sca;

      verb_spinner.sca(@(sca,sca));
      verb_line.sca(@(sca,sca));
      
      1 +=> prog;
    }
  }

  fun void _show_verb(string verb) {
    verb => current_verb;
    if (verb_pulse != null) Machine.remove(verb_pulse.id());
    spork ~ _pulse_verb_once() @=> verb_pulse;
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

    @(CAM_LEFT,CAM_TOP) => RELATIVE;
  }

  fun void _init_terminal() {
    _draw_top_box();
    _draw_prompt_container();

    prompt.font(FONT_FACE);
    prompt.size(FONT_SIZE);
    prompt.color(@(1., 1., 1., 0.9));
    prompt.controlPoints(@(0., 1.));
    prompt.pos(RELATIVE + PROMPT_POS);

    prompt --> GG.scene();
  }

  fun void _redraw_verb() {
    _init_verb_font(verb_spinner, @(0.,-FONT_SIZE/8.));
    _init_verb_font(verb_line);
  }

  fun void _init_verb_font(GText text) {
    _init_verb_font(text, @(0.,0.));
  }
  fun void _init_verb_font(GText text, vec2 offset) {
    text.font(FONT_FACE);
    text.size(FONT_SIZE);
    text.color(COLOR_PRIMARY);
    text.controlPoints(@(0.,1.));
    // last part - offse by number of lines
    text.pos(RELATIVE + VERB_LINE_POS + offset + @(0.,-FONT_SIZE*(num_lines-1.)));
  }

  fun void _init_clawed() {
    // clawed == the mascot of "clawed code"
    new ClawedAnimated() @=> clawed;
    new ClawedFlock(0, 600::ms) @=> flock;

    @(
      clawed.get_full_width()/2.,
      -(clawed.get_full_height()/2.) - FONT_SIZE
    ) => vec2 clawed_pos;

    clawed.sca(@(.7,.7,.7));
    clawed.pos(RELATIVE + clawed_pos);
    clawed.animate_blinking();
    flock.pos(@(0.,0.,0.));
  }

  fun void _draw_prompt_container() {
    line_top --> GG.scene();
    line_bottom --> GG.scene();
    
    line_top.width(.02);
    line_bottom.width(.02);
    line_top.color(@(1.,1.,1.));
    line_bottom.color(@(1.,1.,1.));

    RELATIVE.x + PROMPT_POS.x => float left;
    -left => float right;
    (RELATIVE.y + PROMPT_POS.y + PROMPT_CONTAINER_PADDING) => float top;
    (top - (FONT_SIZE * num_lines + (FONT_SIZE * 0.5)) - PROMPT_CONTAINER_PADDING) => float bottom;

    line_top.positions([@(left,top),@(right,top)]);
    line_bottom.positions([@(left,bottom),@(right,bottom)]);
  }

  fun void _draw_top_box() {
    GLines outline --> GG.scene();
    outline.width(.02);

    RELATIVE.x + TOP_BOX_INSET => float left_corner;
    -left_corner => float right_corner;
    RELATIVE.y - TOP_BOX_INSET => float top_corner;
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
    heading.font(FONT_FACE);
    heading.size(FONT_SIZE);
    heading.color(@(1., 1., 1., 0.9));
    heading.controlPoints(@(0., 1.));
    heading.pos(RELATIVE + @(FONT_SIZE * 4.75, -(FONT_SIZE * .6), 0.));

    GText info --> GG.scene();
    info.text("Icarus 4.6 (1M context) · Clawed Max\nReady to build AGI?");
    info.font(FONT_FACE);
    info.size(FONT_SIZE);
    info.color(@(1., 1., 1., 0.9));
    info.controlPoints(@(0., 1.));
    info.pos(RELATIVE + @(FONT_SIZE * 22, -(FONT_SIZE * 2), 0.));
  }
}

ClawedCode code();
code.run();
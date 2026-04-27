@import {"clawed.ck", "gkr.ck", "state.ck"}

public class ClawedCodePromptEvent extends Event {
  string prompt;
  string buzzwords;

  fun @construct(string pr) {
    pr => prompt;
  }

  fun @construct(string pr, string buzz) {
    pr => prompt;
    buzz => buzzwords;
  }
}

public class ClawedCode extends GGen {
  "" => string DEFAULT_VERB;
  ["·","✢","*","✶","✻","✽"] @=> string SPINNER_SEQUENCE[];
  @(0.005, 0.005, 0.007) => vec3 COLOR_BG;
  @(.24,.48,1.) => vec3 COLOR_PRIMARY;

  .45 => float CHAR_W;
  1. => float CHAR_H;
  16 => int SCALE_FACTOR;

  // this is the base font size before scalin
  .036 => float _base_font_size;
  // we later set FONT_SIZE according to the _base_font_size
  float FONT_SIZE;
  "fonts/DejaVuSansMono.ttf" => string FONT_FACE;

  vec2 PROMPT_POS;
  vec2 VERB_LINE_POS;

  // .2 => float TOP_BOX_INSET;
  // .12 => float PROMPT_CONTAINER_PADDING;
  float TOP_BOX_INSET;
  float PROMPT_CONTAINER_PADDING;

  float WINDOW_W;
  float WINDOW_H;
  float TITLE_BAR_H;
  (WINDOW_W / WINDOW_H) => float ASPECT_RATIO;

  float CAM_LEFT;
  float CAM_TOP;
  vec2 RELATIVE;

  // terminal display states
  "" => string prompt_text;
  "❯" => string prompt_display;
  DEFAULT_VERB => string current_verb;
  0 => int spinner_idx;
  1000::ms => dur verb_change_delay;
  1 => int num_lines;
  1 => int prompt_editable;
  string terminal_buzzwords[0];

  // draw prompt = the prompt we "draw" from
  DesktopState desktop_state;
  0 => int drawn_length;
  0 => int verb_idx;
  0 => int got_crazy;
  0 => int begun_end_sequence;

  .7 => float clawed_scale;
  vec3 clawed_pos;

  GKeyboardReceiver keyboard;
  GText prompt;
  GText verb_spinner;
  GText verb_line;
  GLines line_top;
  GLines line_bottom;
  Shred @ verb_pulse;
  ClawedAnimated clawed();
  ClawedFlock flock(0, 600::ms, .3);
  WordCloud @ word_cloud;

  // window chrome
  GPlane bg;
  FlatMaterial bg_mat;
  GPlane title_bar;
  FlatMaterial title_bar_mat;
  GText title_text;
  GPlane btn_close;
  FlatMaterial btn_close_mat;
  GPlane btn_min;
  FlatMaterial btn_min_mat;
  GPlane btn_max;
  FlatMaterial btn_max_mat;
  GLines border;

  // promoted from locals in _draw_top_box so re-layout is safe
  GLines outline;
  GText heading;
  GText info;

  int _chrome_attached;
  Shred @ _demon_flash_shred;

  ClawedCodePromptEvent wait;
  Event state_completed;
  Event key_down;

  GlitchCloud @ glitch_cloud;

  fun @construct(GlitchCloud gc) {
    gc @=> glitch_cloud;
  }

  fun void setSize(float w, float h) {
    w => WINDOW_W;
    h => WINDOW_H;

    h * 0.09 => TITLE_BAR_H;
    h * _base_font_size => FONT_SIZE;
    @(FONT_SIZE, -(TITLE_BAR_H+FONT_SIZE*11.)) => PROMPT_POS;
    PROMPT_POS + @(0., -(FONT_SIZE*2.7)) => VERB_LINE_POS;
    FONT_SIZE => TOP_BOX_INSET;
    FONT_SIZE*.6 => PROMPT_CONTAINER_PADDING;

    // defining relative coordinates using abstracted
    // window space rather than the actual GG.camera()
    // (since this is now gonna be a "window" in a fake
    // desktop environment. woohoo...)
    -w/2. => CAM_LEFT;
    h/2. => CAM_TOP;
    @(CAM_LEFT,CAM_TOP) => RELATIVE;
    
    if (!_chrome_attached) {
      _init_bg();
      _init_chrome();
      _init_terminal();
      _init_clawed();
      1 => _chrome_attached;
    }

    _update_prompt_display();
  }

  fun void begin() {
    spork ~ _run_text_input();
  }

  fun void update() {
    flock.pos(@(-1.6,0.9,0.));
    if (word_cloud != null) word_cloud.pos(@(0.,0.,0.));
    keyboard.listen();

    prompt.text(prompt_display);

    verb_spinner.text(SPINNER_SEQUENCE[spinner_idx]);
    verb_line.text("  " + current_verb + "…");
  }

  fun void set_desktop_state(DesktopState st) {
    0 => drawn_length;
    0 => verb_idx;
    0 => got_crazy;
    1 => prompt_editable;

    st @=> desktop_state;

    _update_prompt_display();
  }

  fun void _handle_prompt_event() {
    prompt_text => wait.prompt;
    _gather_buzzwords() => wait.buzzwords;
    wait.broadcast();

    // hide cursor
    0 => prompt_editable;
    _update_prompt_display();

    // verb/spinner init
    _redraw_verb();
    _run_verb();
  }

  fun void _run_verb() {
    // initialize verb_change_delay ONCE to the value from the current
    // desktop state - it can (and in the "crazy" case, will) be mutated
    desktop_state.verb_duration => verb_change_delay;
    0 => verb_idx;

    spork ~ _run_spinner() @=> Shred spinner_shred;
    spork ~ _run_change_verb() @=> Shred verb_shred;

    // wait to kill & remove until cook duration passes
    desktop_state.cook_duration => now;
    Machine.remove(spinner_shred.id());
    Machine.remove(verb_shred.id());
    verb_line --< this;
    verb_spinner --< this;

    state_completed.broadcast();
  }

  fun string _gather_buzzwords() {
    // clear buzzwords on fresh prompt
    terminal_buzzwords.size(0);
    string buzzwords;
    int seen_words[0];

    prompt_text => string pr; // make copy of prompt to mutate
    string matches[1];
    string word;
    int is_match;
    while (RegEx.match("[A-Za-z]+", pr, matches)) {
      matches[0] => word;
      // "I" should be manually ignored (for obvious reasons)
      word != "I" && !seen_words[word] && RegEx.match("^[A-Z]+$", word) => is_match;
      if (is_match) {
        word +=> buzzwords;
        // also store in instance array, for use
        // in rendering (outside of the `ClawedCodePromptEvent`)
        word => string tok;
        terminal_buzzwords << tok;
        1 => seen_words[word];
      }
      RegEx.replace("[A-Za-z]+", "_", pr) => pr;
      if (is_match && pr.length()) " " +=> buzzwords;
      // space delimit when more words remain
    }

    for (0 => int i; i < terminal_buzzwords.size(); i++)
      <<< i, terminal_buzzwords[i] >>>;

    return buzzwords;
  }

  fun void _run_text_input() {
    while (true) {
      keyboard.wait => now;
      if (!prompt_editable) continue;
      key_down.broadcast();
      
      // "enter" key starts the whole shabang
      if (keyboard.wait.enter) {
        _handle_prompt_event();
        continue;
      }

      if (keyboard.wait.backspace) {
        // if (prompt_text.length() > 0)
        //   prompt_text.substring(0, prompt_text.length() - 1) => prompt_text;
        if (drawn_length > 0) drawn_length--;
      } else if (keyboard.wait.ctrl) {
        if (keyboard.wait.val == "u") {
          // ctrl-u: clear prompt
          // "" => prompt_text;
          0 => drawn_length;
        }
      } else {
        // keyboard.wait.val +=> prompt_text;
        if (drawn_length < desktop_state.prompt.length()) drawn_length++;
      }
      _update_prompt_display();
    }
  }

  fun void _get_crazy_with_it() {
    // flap bird
    clawed.animate_flapping();
    // new WordCloud(terminal_buzzwords, 100::ms, 1.25, 4) @=> word_cloud;
    spork ~ _run_add_birdies();
  }

  fun void _run_add_birdies() {
    while (flock.count() < 32){//128) {
      flock.add_birdie();
      700::ms => now;
    }
  }

  fun void _update_prompt_display() {
    "❯ " => string init;

    0 => int start;
    0 => int end;
    int is_first_line;
    int is_last_line;
    0 => int iter;

    1 => num_lines;

    // TODO: find a more reliable method of calculating terminal width:
    // i tuned by hand, and it works-ish (ish!) for a variety of window
    // widths, but not with perfect consistency as to where the
    // line break is. it's more or less the golden ratio hah
    (WINDOW_W/FONT_SIZE * 1.618) $ int => int terminal_width_chars;

    desktop_state.prompt.substring(0, drawn_length) => prompt_text;
    
    while (start < prompt_text.length() && !is_last_line) {
      (start + terminal_width_chars - 4) => end;
      
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

    // _redraw_verb();
    _draw_prompt_container();
  }

  fun void _begin_end_sequence() {
    true => begun_end_sequence;
    spork ~ _run_end_sequence();
  }

  fun void _run_end_sequence() {
    // TODO: consider making this more than a black screen
    // (the idea being that the screen goes black, then the bird
    // comes out in a suit)
    // not sure that positioning a giant black GPlane over the scene
    // is the most efficient way, but fttb it's quick'n'dirty
    2::second => now;
    GPlane cover;
    FlatMaterial mat;
    mat.color(COLOR_BG);
    cover.material(mat);
    // just in front of the scene but behind camera (which is z=11)
    cover.posWorld(@(0.,0.,10.9));

    // get width in terms of GG.viewSize() using frame aspect ratio
    GG.camera().viewSize() => float scale_h;
    scale_h * (GG.frameWidth() / GG.frameHeight()) => float scale_w;

    cover.sca(@(scale_w,scale_h,1.));
    // WARNING to anthony/siqi/any other godforsaken soul perusing this code:
    // I am explicitly adding this cover to the global scene
    cover --> GG.scene();
  }

  fun void _run_change_verb() {
    // WINDOW_H => float max_clawed_scale;
    // allow clawed to grow to the full chugl height
    // rather than just the faux "window"
    GG.camera().viewSize() => float max_clawed_scale;
    clawed_scale => float initial_clawed_scale;
    // we'll be world-positioning clawed now, so its
    // initial position should be world-scale
    clawed.posWorld() => vec3 start_point;
    @(0.,0.,8.) => vec3 end_point;

    _show_verb(desktop_state.cooking_verbs[verb_idx], 0);

    while (true) {
      verb_change_delay => now;
      (verb_idx + 1) % desktop_state.cooking_verbs.size() => verb_idx;
      desktop_state.cooking_verbs.size() > 0 => int verbs_ready;

      (desktop_state.gets_crazy && verb_change_delay < 750::ms) => int passed_extra_crazy_threshold;

      _show_verb(verbs_ready ? desktop_state.cooking_verbs[verb_idx] : DEFAULT_VERB, passed_extra_crazy_threshold);

      // what happens below here is exclusively for crazy mode
      // but to me crazy mode is normal mode. gotta stop writing
      // incessant comments and get to bed. soz
      if (!desktop_state.gets_crazy) continue;

      // all this below the sentry above is for CRAZY MODE only,
      // aka when s#!t gets crazy...
      if (verb_change_delay > 200::ms) .95 *=> verb_change_delay;
      if (clawed.flap_delay > 15::ms) {
        .93 *=> clawed.flap_delay;
      }
      if (passed_extra_crazy_threshold) {
        // get crazy and set the flag
        if (!got_crazy) {
          _get_crazy_with_it();
          1 => got_crazy;
        }
        flock.start(); // set start time for bird additions
        if (clawed_scale >= max_clawed_scale) {
          if (!begun_end_sequence) _begin_end_sequence();
        } else {
          clawed.sca(@(clawed_scale,clawed_scale,1.));

          // basically a bernoulli rv: Ber(0.2)
          if (Math.random2f(0,1) > 0.8) flash_demon();
          
          // linear interpolation between start & end points
          // 2x so it centers before it finishes scaling
          Math.min(2 * (clawed_scale - initial_clawed_scale) / max_clawed_scale, 1) => float t;
          (1. - t) * start_point + t * end_point => vec3 lerp;

          clawed.posWorld(lerp);
          1.01 *=> clawed_scale;
        }
      }
    }
  }

  fun void flash_demon() {
    if (_demon_flash_shred != null) Machine.remove(_demon_flash_shred.id());
    spork ~ _run_flash_demon() @=> _demon_flash_shred;
  }

  fun void _run_flash_demon() {
    clawed.set_demonic(1);
    glitch_cloud.populate(Math.random2(60, 120));
    glitch_cloud.enable();
    Math.random2(40,175)::ms => now;
    clawed.set_demonic(0);
    glitch_cloud.disable();
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
      (1 + (t * t * verb_delay_factor / 1::ms)) => sca;

      verb_spinner.sca(@(sca,sca));
      verb_line.sca(@(sca,sca));
      
      1 +=> prog;
    }
  }

  fun void _show_verb(string verb, int crazy) {
    verb => current_verb;
    if (verb_pulse != null) Machine.remove(verb_pulse.id());
    if (crazy) spork ~ _pulse_verb_once() @=> verb_pulse;
  }

  fun void _init_bg() {
    bg --> this;
    bg_mat.color(COLOR_BG);
    bg.material(bg_mat);
    bg.sca(@(WINDOW_W, WINDOW_H, 1.));
    bg.pos(@(0., 0., -0.01));
  }

  fun void _init_chrome() {
    // title bar
    title_bar --> this;
    title_bar_mat.color(@(0.08,0.08,0.10));
    title_bar.material(title_bar_mat);
    title_bar.sca(@(WINDOW_W, TITLE_BAR_H, 1.));
    title_bar.pos(@(0.,CAM_TOP-TITLE_BAR_H/2.,.005));
    // title txt
    title_text --> this;
    title_text.text("clawed");
    title_text.font(FONT_FACE);
    title_text.size(TITLE_BAR_H * 0.5);
    title_text.color(@(0.82, 0.82, 0.88, 1.));
    title_text.controlPoints(@(0.5, 0.5));
    title_text.pos(@(0.,CAM_TOP-TITLE_BAR_H/2.,.02));
    // btns: close, min, max
    TITLE_BAR_H*.24 => float btn_r;
    TITLE_BAR_H*.8 => float btn_gap;
    CAM_LEFT + TITLE_BAR_H*0.6 => float btn_x0;
    CAM_TOP - TITLE_BAR_H/2. => float btn_y;
    // btn1
    btn_close --> this;
    btn_close_mat.color(@(0.99,0.37,0.34));
    btn_close.material(btn_close_mat);
    btn_close.sca(@(btn_r*2,btn_r*2,1.));
    btn_close.pos(@(btn_x0, btn_y, 0.02));
    // btn2
    btn_min --> this;
    btn_min_mat.color(@(0.99,0.74,0.21));
    btn_min.material(btn_min_mat);
    btn_min.sca(@(btn_r*2, btn_r*2, 1.));
    btn_min.pos(@(btn_x0 + btn_gap, btn_y,.02));
    // btn3
    btn_max --> this;
    btn_max_mat.color(@(0.15,0.78,0.25));
    btn_max.material(btn_max_mat);
    btn_max.sca(@(btn_r*2, btn_r*2, 1.));
    btn_max.pos(@(btn_x0 + btn_gap*2, btn_y, 0.02));
    // window border
    border --> this;
    border.width(.01);
    border.color(@(0.22, 0.22, 0.27));
    WINDOW_W/2. => float hx;
    WINDOW_H/2. => float hy;
    border.positions([@(-hx,hy), @(hx,hy), @(hx,-hy), @(-hx,-hy), @(-hx,hy)]);
    border.pos(@(0., 0., 0.015));
  }

  fun void _init_terminal() {
    _draw_top_box();
    _draw_prompt_container();

    prompt.font(FONT_FACE);
    prompt.size(FONT_SIZE);
    prompt.color(@(1., 1., 1., 0.9));
    prompt.controlPoints(@(0., 1.));
    prompt.pos(RELATIVE + PROMPT_POS);

    prompt --> this;
  }

  fun void _redraw_verb() {
    _init_verb_font(verb_spinner, @(0.,-FONT_SIZE/8.));
    _init_verb_font(verb_line);
    verb_line --> this;
    verb_spinner --> this;
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
    // scale mascot relative to window height
    // TODO: pull out a `TOP_BOX_H` or similar to scale relative to that
    // rather than relative to font size (it's less obvious as to why)
    // mea culpa. i am writing something that will work for wednesday
    FONT_SIZE*3.5 => clawed_scale;
    clawed.sca(@(clawed_scale,clawed_scale,1.));

    // top box bounds (must match _draw_top_box)
    TITLE_BAR_H + TOP_BOX_INSET => float box_top_offset;
    FONT_SIZE * 8.2 => float box_h;


    // park clawed inside the top box, vertically centered
    @(
      clawed.get_full_width()/2. + TOP_BOX_INSET + FONT_SIZE,
      // bird body-origin sits above its visual center because feet extend
      // below the body but nothing balances above, shift down by half foot
      // TODO: move this sort of calculation into the `Clawed` class itself
      // this is kinda a jerry rig ngl
      -(box_top_offset+box_h/2.) + (clawed.FOOT_HEIGHT*clawed_scale)/2.,
      8.
    ) => clawed_pos;

    // clawed.pos(RELATIVE + clawed_pos + @(0.,0.,8.));
    clawed.pos(RELATIVE + clawed_pos);
    clawed.animate_blinking();
    flock.pos(@(0.,0.,0.));
    clawed --> this;
  }

  fun void _draw_prompt_container() {
    line_top --> this;
    line_bottom --> this;
    
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
    outline --> this;
    outline.width(.015);

    RELATIVE.x + TOP_BOX_INSET => float left_corner;
    -left_corner => float right_corner;
    RELATIVE.y - TITLE_BAR_H - TOP_BOX_INSET => float top_corner;
    top_corner - FONT_SIZE * 8.2 => float bottom_corner;

    (FONT_SIZE * 4.75) => float heading_gap_start;
    heading_gap_start + FONT_SIZE * 11. => float heading_gap_end;

    outline.positions([
      @(left_corner,bottom_corner),
      @(right_corner,bottom_corner),
      @(right_corner,top_corner),
      @(left_corner+heading_gap_end,top_corner),
      @(left_corner+heading_gap_start,top_corner),
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

    heading --> this;
    heading.text("Clawed Code v4.5.1");
    heading.font(FONT_FACE);
    heading.size(FONT_SIZE);
    heading.color(@(1., 1., 1., 0.9));
    heading.controlPoints(@(0., 1.));
    // found this new scaled positioning through trial-and-error fiddling
    // TODO: make this cleaner and more reliable (once everything works how
    // i want it to, anyway...)
    heading.pos(RELATIVE + @((TOP_BOX_INSET + FONT_SIZE * .5) + WINDOW_W * 0.1, -(TITLE_BAR_H + (TOP_BOX_INSET+(FONT_SIZE*.25))/2), 0.));

    info --> this;
    info.text("Icarus 4.6 (1M context) · Clawed Max\nReady to build AGI?");
    info.font(FONT_FACE);
    info.size(FONT_SIZE);
    info.color(@(1., 1., 1., 0.9));
    info.controlPoints(@(1., 1.));
    info.pos(RELATIVE + @(WINDOW_W - TOP_BOX_INSET - FONT_SIZE, -TOP_BOX_INSET - (FONT_SIZE * 3), 0.));
  }
}
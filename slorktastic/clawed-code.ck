@import {"clawed.ck", "gkr.ck", "lights.ck", "sounders.ck", "state.ck", "tts.ck"}

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
  0 => int final_view_shown;

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

  // end scene cover
  GPlane cover;

  // promoted from locals in _draw_top_box so re-layout is safe
  GLines outline;
  GText heading;
  GText info;

  int _chrome_attached;
  // Shred @ _demon_flash_shred;
  Shred @ _flash_cues_shred;
  Shred @ _tts_loop;
  Shred @ _add_words_shred;

  Shred spinner_shred;
  Shred verb_shred;

  ClawedCodePromptEvent wait;
  Event state_completed;
  Event key_down;

  GlitchCloud @ glitch_cloud;

  2::second => dur END_SEQUENCE_DELAY;
  20::second => dur CLOUDS_CONSTRAINED_WINDOW;
  0.1 => float WORD_CLOUD_MARGIN_X;
  0.1 => float WORD_CLOUD_MARGIN_Y;
  0 => int _clouds_release_started;
  0 => int _clouds_unconstrained;
  0.1 => float demon_prob;
  0.25 => float MAX_DEMON_PROB;
  DemonSounder demon_sounder;
  BeepSounder beep_sounder;
  Sayer sayer;
  LightsManager _lights;

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
    _lights.init();
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

  fun void disable_lights() {
    <<< "[clawed-code] disabling lights" >>>;
    0 => _lights.is_enabled;
  }

  fun void set_prompt_editable(int enabled) {
    enabled => prompt_editable;
    _lights.set_spotlight(enabled ? 100 : 0);
    // cooking lights OFF when prompt is editable
    // hence the negation
    _lights.set_cooking_lights(!enabled);
  }

  fun void set_desktop_state(DesktopState st) {
    0 => drawn_length;
    0 => verb_idx;
    0 => got_crazy;
    set_prompt_editable(1);

    //tear down any cloud/TTS from prev state
    _kill_spork(_tts_loop);
    null @=> _tts_loop;
    _kill_spork(_add_words_shred);
    null @=> _add_words_shred;
    if (word_cloud != null) {
      word_cloud.disable();
      word_cloud.clear();
      null @=> word_cloud;
    }
    sayer.set_gain(0);

    st @=> desktop_state;

    _update_prompt_display();
  }

  fun void _handle_prompt_event() {
    prompt_text => wait.prompt;
    _gather_buzzwords() => wait.buzzwords;
    wait.broadcast();

    // hide cursor
    set_prompt_editable(0);
    _update_prompt_display();

    // verb/spinner init
    _redraw_verb();
    // start the cloud (and optionally TTS) before chaos if the state opts in
    if (desktop_state.word_cloud_early) _start_word_cloud();
    // sporked so _run_text_input can keep polling keyboard events
    // whoops lol glad i fixed that
    spork ~ _run_verb();
  }

  fun void _run_verb() {
    // initialize verb_change_delay ONCE to the value from the current
    // desktop state - it can (and in the "crazy" case, will) be mutated
    desktop_state.verb_duration => verb_change_delay;
    0 => verb_idx;

    spork ~ _run_spinner() @=> spinner_shred;
    spork ~ _run_change_verb() @=> verb_shred;
    spork ~ _run_flash_cues() @=> _flash_cues_shred;

    // wait to kill & remove until cook duration passes
    desktop_state.cook_duration => now;
    _hide_verb_spinner();

    state_completed.broadcast();
  }

  fun string _gather_buzzwords() {
    // clear buzzwords on fresh prompt
    terminal_buzzwords.size(0);
    string buzzwords;
    int seen_words[0];

    // copy from the DESKTOP STATE rather than drawn prompt,
    // just in case performer does not finish typing!
    desktop_state.prompt => string pr; // make copy of prompt to mutate
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

      <<< "ev", keyboard.wait.val >>>;

      if (begun_end_sequence && (keyboard.wait.val.find("q") >= 0 || keyboard.wait.val.find("Q") >= 0)) {
        _show_final_view();
        continue;
      }

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
    _start_word_cloud();
    spork ~ _run_add_birdies();
  }

  fun void _start_word_cloud() {
    if (word_cloud != null) return;
    new WordCloud(100::ms, 1.25) @=> word_cloud;
    word_cloud.set_constraint_bounds(
      flock.term_center,
      flock.term_w,
      flock.term_h,
      WORD_CLOUD_MARGIN_X,
      WORD_CLOUD_MARGIN_Y
    );
    word_cloud.set_constrained(1);
    spork ~ _run_add_words() @=> _add_words_shred;
    if (desktop_state.tts_enabled) spork ~ _run_tts_loop() @=> _tts_loop;
  }

  fun void _run_add_words() {
    0 => int i;
    while (i < terminal_buzzwords.size()) {
      word_cloud.add_word(terminal_buzzwords[i++]);
      700::ms => now;
    }
  }

  fun void _run_add_birdies() {
    while (flock.count() < 32) {
      flock.add_birdie();
      700::ms => now;
    }
  }

  fun void _run_tts_loop() {
    0 => int idx;
    desktop_state.verb_duration / 1::ms => float delay_start_ms;
    200. => float delay_end_ms;
    (delay_start_ms - delay_end_ms) => float delay_range_ms;

    while (true) {
      word_cloud.count() => int visible;
      if (visible > 0) {
        idx % visible => idx;
        Math.clampf((1. - (verb_change_delay / 1::ms - delay_end_ms) / delay_range_ms)*2., 0., 2.) => float g;
        sayer.set_gain(g);
        sayer.say(terminal_buzzwords[idx].lower());
        Math.random2f(250, 350)::ms => now;
        (idx + 1) % visible => idx;
      } else {
        300::ms => now;
      }
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
    spork ~ _handle_end_sequence_lights();
    spork ~ _run_end_sequence();
  }

  fun void _handle_end_sequence_lights() {
    END_SEQUENCE_DELAY => now;
    <<< "calling all out, waiting" >>>;
    _lights.all_out();
    5::second => now;
    <<< "set spotlight!!!" >>>;
    _lights.set_spotlight(100);
  }

  fun void _run_end_sequence() {
    END_SEQUENCE_DELAY => now;
    // stop demon flashing first and foremost
    // _kill_spork(_demon_flash_shred);
    _kill_spork(_tts_loop);
    sayer.set_gain(0);
    // TODO: consider making this more than a black screen
    // (the idea being that the screen goes black, then the bird
    // comes out in a suit)
    // not sure that positioning a giant black GPlane over the scene
    // is the most efficient way, but fttb it's quick'n'dirty
    if (final_view_shown) return;
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

  fun void _show_final_view() {
    if (final_view_shown) return;
    1 => final_view_shown;
    <<< "showing final view" >>>;
    // hide flocklike things
    word_cloud.disable();
    glitch_cloud.disable(); // this one shouldnt be necessary, just in case
    flock.disable();
    // stop verb stuff
    _hide_verb_spinner();
    // ungruck cover screen and clawed
    clawed --< this;
    cover --< GG.scene();
    spork ~ _run_final_view_click_listener();
  }

  fun void _run_final_view_click_listener() {
    // ignore any mouse already held when final view first appears
    // so the window doesnt insta-close (just in case !)
    while (GWindow.mouseLeft()) GG.nextFrame() => now;
    while (final_view_shown) {
      GG.nextFrame() => now;
      if (!GWindow.mouseLeftDown()) continue;
      GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1.) => vec3 mp;
      this.posWorld() => vec3 wp;
      WINDOW_W/2. => float hx;
      WINDOW_H/2. => float hy;
      if (mp.x > wp.x - hx && mp.x < wp.x + hx && mp.y > wp.y - hy && mp.y < wp.y + hy) {
        this --< GG.scene();
        // force next frame on close
        GG.nextFrame() => now;
        _run_end_fade();
        return;
      }
    }
  }

  fun void _run_end_fade() {
    2::second => now;
    _lights.all_out();
    // fade cover in to black over whole scene
    FlatMaterial fade_mat;
    fade_mat.color(@(0.,0.,0.));
    0. => fade_mat.alpha;
    cover.material(fade_mat);
    cover --> GG.scene();
    
    2::second => dur fade_dur;
    now => time fade_start;
    float t;
    while (now - fade_start < fade_dur) {
      (now - fade_start) / fade_dur => t;
      t => fade_mat.alpha;
      GG.nextFrame() => now;
    }
    1. => fade_mat.alpha;

    2::second => now;
    _lights.house_neutral();
  }

  fun void _hide_verb_spinner() {
    _kill_spork(spinner_shred);
    _kill_spork(verb_shred);
    _kill_spork(_flash_cues_shred);
    verb_line --< this;
    verb_spinner --< this;
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
        _release_clouds_constraint();
        if (clawed_scale >= max_clawed_scale) {
          if (!begun_end_sequence) _begin_end_sequence();
        } else {
          clawed.sca(@(clawed_scale,clawed_scale,1.));

          // basically a bernoulli rv: Ber(demon_prob)
          if (Math.random2f(0,1) < demon_prob) {
            flash_demon();
          }
          if (demon_prob < MAX_DEMON_PROB) 1.04 *=> demon_prob;
          
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
    // crazy-mode default: random short flash
    flash_demon(Math.random2(60,300)::ms);
  }

  fun void flash_demon(dur d) {
    if (_clouds_unconstrained) _lights.flash();
    // no longer sporked - blocking so it actually finishes lol
    _run_flash_demon(d);
  }

  fun void _run_flash_demon(dur d) {
    demon_sounder.start();
    clawed.set_demonic(1);
    _clouds_unconstrained => int show_glitch;
    if (show_glitch) {
      glitch_cloud.populate(Math.random2(60, 120));
      glitch_cloud.enable();
    }
    d => now;
    clawed.set_demonic(0);
    if (show_glitch) glitch_cloud.disable();
    demon_sounder.stop();
    // higher pitch & gain on next
    demon_sounder.escalate();
  }

  fun void _run_flash_cues() {
    desktop_state.flash_cues @=> FlashCue cues[];
    if (cues.size() == 0) return;

    // offsets are absolute from cook start fyi
    now => time start;
    for (0 => int i; i < cues.size(); i++) {
      cues[i] @=> FlashCue cue;
      (start+cue.offset) - now => dur wait;
      if (wait > 0::samp) wait => now;
      if (got_crazy) return;
      flash_demon(cue.duration);
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
      (1 + (t * t * verb_delay_factor / 1::ms)) => sca;

      verb_spinner.sca(@(sca,sca));
      verb_line.sca(@(sca,sca));
      
      1 +=> prog;
    }
  }

  fun void _show_verb(string verb, int crazy) {
    verb => current_verb;
    _kill_spork(verb_pulse);
    if (crazy) spork ~ _pulse_verb_once() @=> verb_pulse;
    _trigger_verb_beep();
  }

  fun void _trigger_verb_beep() {
    desktop_state.verb_duration / 1::ms => float initial_ms;
    verb_change_delay / 1::ms => float current_ms;
    200. => float min_ms;
    Math.max(initial_ms - min_ms, 1.) => float range_ms;
    Math.clampf((initial_ms - current_ms) / range_ms, 0., 1.) => float chaos;
    // full volume until the last 30% of chaos then fade to silence
    Math.clampf(1. - (chaos - 0.7) / 0.3, 0., 1.) => float fade;
    beep_sounder.set_chaos(chaos);
    beep_sounder.set_fade(fade);
    beep_sounder.beep();
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
    flock.set_constrained(1);
    clawed --> this;
  }

  fun void _set_clouds_constrained(int on) {
    flock.set_constrained(on);
    if (word_cloud != null) word_cloud.set_constrained(on);
  }

  fun void _release_clouds_constraint() {
    if (_clouds_release_started) return;
    1 => _clouds_release_started;
    spork ~ _run_release_clouds_constraint();
  }

  fun void _run_release_clouds_constraint() {
    CLOUDS_CONSTRAINED_WINDOW => now;
    _set_clouds_constrained(0);
    1 => _clouds_unconstrained;
    demon_sounder.set_unconstrained(1);
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
    (top - ((FONT_SIZE * 1.13) * num_lines + (FONT_SIZE * 0.5)) - PROMPT_CONTAINER_PADDING) => float bottom;

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

  fun void _kill_spork(Shred sp) {
    if (sp != null) sp.exit();
  }
}
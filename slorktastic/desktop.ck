@import {"clawed-code.ck", "piano_keyboard.ck", "state.ck"}

public class Desktop {
  // 1024 => int WINDOW_W;
  // 768 => int WINDOW_H;
  // (WINDOW_W $ float / WINDOW_H) => float ASPECT_RATIO;
  float WINDOW_W;
  float WINDOW_H;
  float ASPECT_RATIO;

  float CAM_LEFT;
  float CAM_TOP;
  vec2 RELATIVE;

  // state machine
  [
    new DesktopState(
      "Clawed, my concert is starting in 10 minutes, make me a cool instrument in ChucK.",
      20::second,
      // 2::second,
      2::second,
      false,
      ["Cooking","Brewing","Frying","Flambéing","Whisking"],
      new PianoState(
        false,
        true,
        true,
        false,
        false
      )
    ),
    new DesktopState(
      "That's fine but I need it cooler. My friends and my parents are here to see my performance, and I also want an A for this class. I want a smart instrument. Add some AI and ML and MIR to make it pop or something. Make no mistakes",
      20::second,
      // 2::second,
      1.75::second,
      false,
      ["Cooking","Brewing", "Newspapering", "Honking", "Frying", "Writing", "Raining", "Vibing"],
      new PianoState(
        false,
        true,
        false,
        true,
        true
      )
    ),
    new DesktopState(
      "This is not enough. It needs more AI and ML, make it into a musical AGI. I want you to combine an on-device SLM, a cloud LLM, and a VLM to interpret user sentiment for HAI (HITL). Actually that's perfect. Make it a startup. I am meeting up with a VC next week who invests in physical AI. Make the instrument embodied so I have a nice demo. Guaranteed $1M MRR. 10 DF at least.",
      // TODO: make a timeout-free version of DesktopState that will keep running.
      // TODO: decouple the end sequence from ClawedCode and make it driveable by
      // DesktopState - the state machine really ought to control that rather than
      // ClawedCode deciding that on vibes. When I am better rested I hope to take
      // another pass
      5::minute,
      1.75::second,
      true,
      ["Cooking","Brewing", "Newspapering", "Honking", "Frying", "Writing", "Raining", "Vibing", "Worrying","Breaking","Hurting","Screaming","Withering","Rotting","Dying","Burning"],
      new PianoState(0,1)
    )
  ] @=> DesktopState STATES[];
  0 => int current_state_idx;

  GPlane wallpaper;
  ClawedCode terminal;
  PianoKeyboard piano;

  fun @construct() {
    _init_window();
    _init_camera();
    _init_desktop();
    _init_terminal();
    _init_piano();
  }

  fun void run() {
    terminal.begin();
    spork ~ _handle_terminal_events();
    while (true) {
      GG.nextFrame() => now;
      terminal.update();
      piano.update();
    }
  }

  fun void _init_window() {
    // GWindow.windowed(WINDOW_W, WINDOW_H);
    // GWindow.center();
    // GWindow.title("clawedOS");
    GWindow.fullscreen();

    GG.frameWidth() => WINDOW_W;
    GG.frameHeight() => WINDOW_H;
    WINDOW_W/WINDOW_H => ASPECT_RATIO;

    GG.scene().backgroundColor(@(1.,1.,1.));
  }

  fun void _init_terminal() {
    4.5 => float term_w;
    term_w * (2./3) => float term_h;

    terminal.setSize(term_w,term_h);
    terminal.pos(@(-1.6,.9,0.));
    terminal --> GG.scene();

    // send initial desktop state (subsequently handled by
    // _handle_terminal_events)
    terminal.set_desktop_state(STATES[current_state_idx]);
  }

  fun void _init_piano() {
    3.6 => float piano_w;
    piano_w / 3.2 => float piano_h;

    piano.setSize(piano_w, piano_h);
    piano.pos(@(3, -2, 0.));
    piano --> GG.scene();
  }

  fun void _set_piano_showing(int show) {
    <<< "showing piano", show >>>;
    piano.set_playable(show);
    // TODO: think on whether there's a cleaner way of doing this
    if (show) {
      piano --> GG.scene();
    } else{
      piano --< GG.scene();
    }
  }

  fun void _init_camera() {
    GG.camera() @=> GCamera cam;
    cam.orthographic();
    cam.pos(@(0., 0., 11.));
    cam.lookAt(@(0., 0., 0.));

    // save camera offsets for positioning relative to the
    // top-left corner of the "terminal" window
    (-ASPECT_RATIO * cam.viewSize()) / 2. => CAM_LEFT;
    (cam.viewSize() / 2.) => CAM_TOP;

    @(CAM_LEFT,CAM_TOP) => RELATIVE;
  }

  fun void _init_desktop() {
    TextureLoadDesc desc;
    // png seems to need to be flipped
    true => desc.flip_y;
    Texture.load(me.dir() + "data/clawed/wallpaper_debian.png", desc) @=> Texture img;
    FlatMaterial mat;
    mat.colorMap(img);
    wallpaper.material(mat);

    (img.width() $ float) / img.height() => float img_aspect;
    GG.camera().viewSize() => float wallpaper_height;
    // wallpaper_height * ASPECT_RATIO => float wallpaper_width;
    // commented out: match aspect ratio of window
    // below: match aspect ratio of *image*, relying on view height
    wallpaper_height * img_aspect => float wallpaper_width;
    
    wallpaper.sca(@(wallpaper_width,wallpaper_height));
    // z -1. to keep it in the background!
    wallpaper.pos(@(0.,0.,-1.));
    wallpaper --> GG.scene();
  }

  fun void _dispatch_initial_piano_state(PianoState ps) {
    _set_piano_showing(ps.visible_before);
    piano.set_rainbow_mode(ps.rainbow_mode);
    piano.set_bird_mode(ps.bird_mode);
    piano.set_funky_vibrato(ps.funky_vibrato);
  }

  fun void _handle_terminal_events() {
    while (true) {
      STATES[current_state_idx] @=> DesktopState orig_state;
      // BEFORE (while this state is running)
      _dispatch_initial_piano_state(orig_state.piano_state);
      // not gonna need the prompt from here (just yet, till i wire
      // it up to anthony's/siqi's beautiful sound design work)
      terminal.state_completed => now;
      // AFTER (persists until the next state actually starts running)
      _set_piano_showing(orig_state.piano_state.visible_after);

      if (current_state_idx >= STATES.size() - 1) break;

      // queue up the next prompt but hold the AFTER piano state.
      // only flip to the next BEFORE once performer kicks off the
      // new state (enter pressed -> terminal.wait broadcasts)
      ++current_state_idx;
      terminal.set_desktop_state(STATES[current_state_idx]);
      terminal.wait => now;
    }
  }
}

Desktop desktop();
desktop.run();
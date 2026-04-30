@import {"clawed-code.ck", "piano_keyboard.ck", "state.ck", "keyboard_sound.ck"}

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
      40::second,
      // 2::second,
      7::second,
      false,
      ["Cooking","Brewing","Caramelizing","Whisking", "Stirring", "Chopping onions"],
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
      40::second,
      // 2::second,
      6::second,
      false,
      ["Cooking","Brewing", "Newspapering", "Doodling", "Calculating", "Scampering", "Vibing"],
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
      4::second,
      true,
      ["Cooking","Brewing","Frying" , "Newspapering", "Honking", "Writing", "Raining", "Vibing", "Worrying","Breaking","Hurting","Screaming","Withering","Rotting","Dying","Burning"],
      new PianoState(0,1)
    )
  ] @=> DesktopState STATES[];
  0 => int current_state_idx;

  GPlane wallpaper;
  GPlane wallpaper_filter;
  FlatMaterial wallpaper_filter_mat;
  ClawedCode @ terminal;
  PianoKeyboard piano;
  keyBeats kbs(160::ms, [1, 2, 1, 2, 2], 1); // basic snare 
  keyBeats kbs1(80::ms, [4, 1, 1, 1, 1], 0); // hats
  keyBeats kbs2(160::ms, [5, 3], 2); // kick drum
  keyBeats kbs3(80::ms, [3, 1, 2, 1, 1, 3, 3, 2], 3); // high snare
  keyBeats kbs4(320::ms, [5, 3], 4); // crash

  
  
  GlitchCloud glitch_cloud;

  fun @construct() {
    new ClawedCode(glitch_cloud) @=> terminal;
    _init_window();
    _init_camera();
    _init_desktop();
    _init_terminal();
    _init_piano();
    glitch_cloud.disable();
  }

  fun void _kb_listener(){
    while (true) {
      terminal.key_down => now;
      1 => kbs.wasKeyDown;
      1 => kbs1.wasKeyDown;
      1 => kbs2.wasKeyDown;
      1 => kbs3.wasKeyDown;
      1 => kbs4.wasKeyDown;
    }
  }

  fun void run() {
    terminal.begin();
    spork ~ _handle_terminal_events();
    spork ~ _kb_listener();
    spork ~ kbs.addTrack(0::second);
    spork ~ kbs1.addTrack(10::second);
    spork ~ kbs2.addTrack(20::second);
    spork ~ kbs3.addTrack(50::second);
    spork ~ kbs4.addTrack(80::second);
    GG.nextFrame() => now;
    // window dims aren't real until after the first frame ticks
    GG.frameWidth() => WINDOW_W;
    GG.frameHeight() => WINDOW_H;
    WINDOW_W/WINDOW_H => ASPECT_RATIO;
    _init_glitch();
    while (true) {
      GG.nextFrame() => now;
      terminal.update();
      piano.update();
      glitch_cloud.pos(@(0.,0.,0.));
    }
  }

  fun void set_glitching(int on) {
    if (on) {
      glitch_cloud.populate(Math.random2(60, 120));
      glitch_cloud.enable();
    } else {
      glitch_cloud.disable();
    }
  }

  fun void _init_glitch() {
    GG.camera().viewSize() => float vh;
    vh * ASPECT_RATIO => float vw;
    @(-vw/2., vw/2.) => glitch_cloud.x_range;
    @(-vh/2., vh/2.) => glitch_cloud.y_range;
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

    @(1.,.1,.1) => wallpaper_filter_mat.color;
    0.009 => wallpaper_filter_mat.alpha;
    wallpaper_filter.material(wallpaper_filter_mat);

    (img.width() $ float) / img.height() => float img_aspect;
    GG.camera().viewSize() => float wallpaper_height;
    // wallpaper_height * ASPECT_RATIO => float wallpaper_width;
    // commented out: match aspect ratio of window
    // below: match aspect ratio of *image*, relying on view height
    wallpaper_height * img_aspect => float wallpaper_width;
    
    wallpaper.sca(@(wallpaper_width,wallpaper_height));
    // z -1. to keep it in the background!
    wallpaper.pos(@(0.,0.,-1.));
    wallpaper_filter.sca(@(wallpaper_width,wallpaper_height));
    wallpaper_filter.pos(@(0.,0.,-.5));
    wallpaper --> GG.scene();
    wallpaper_filter --> GG.scene();
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
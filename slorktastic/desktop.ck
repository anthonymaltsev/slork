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
      "Chat I don't know how to code, make me a cool piano in ChucK for class",
      10000::ms,
      2000::ms,
      false,
      ["Cooking","Brewing","Caramelizing","Flambéing","Whisking"]
    ),
    new DesktopState(
      "That's fine but I need it cooler. Add some AI and ML to make it pop. Make no mistakes",
      15000::ms,
      2000::ms,
      false,
      ["Cooking","Brewing","Caramelizing","Flambéing","Whisking"]
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
    piano.begin();
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

  fun void _handle_terminal_events() {
    while (true) {
      // not gonna need the prompt from here (just yet, till i wire
      // it up to anthony's/siqi's beautiful sound design work)
      terminal.state_completed => now;
      if (current_state_idx < STATES.size()) {
        terminal.set_desktop_state(STATES[++current_state_idx]);
      }
    }
  }
}

Desktop desktop();
desktop.run();
@import {"clawed-code.ck"}

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

  GPlane wallpaper;
  ClawedCode terminal;

  fun @construct() {
    _init_window();
    _init_camera();
    _init_desktop();
    _init_terminal();
  }

  fun void run() {
    terminal.begin();
    while (true) {
      GG.nextFrame() => now;
      terminal.update();
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
    terminal.pos(@(-.7,.55,0.));
    terminal --> GG.scene();
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
}

Desktop desktop();
desktop.run();
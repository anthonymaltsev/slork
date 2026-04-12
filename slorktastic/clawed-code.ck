@import {"clawed.ck"}

public class ClawedCode {
  @(0.005, 0.005, 0.007) => vec3 COLOR_BG;
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

  "" => string TERMINAL_LINE;

  GText terminal;
  Clawed @ clawed;

  fun @construct() {
    for (0 => int i; i < TERMINAL_W; i++) {
      "_" +=> TERMINAL_LINE;
    }

    _init_window();
    _init_camera();
    _init_terminal();
    _init_clawed();
  }

  fun void run() {
    int val;
    while (true) {
      GG.nextFrame() => now;
      Math.random2(1,10000) => val;
      terminal.text(TERMINAL_LINE + "\n> " + "text will go here!" + "\n" + TERMINAL_LINE);
    }
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
    terminal.font("chugl:cousine-regular");
    terminal.size(FONT_SIZE);
    terminal.color(@(1., 1., 1., 0.9));
    terminal.controlPoints(@(0., 1.));
    terminal.pos(@(CAM_LEFT + FONT_SIZE, CAM_TOP - (FONT_SIZE*12), 0.));
    terminal --> GG.scene();

    _draw_top_box();
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
      @(.24,.48,1.),
      @(.24,.48,1.),
      @(.24,.48,1.),
      COLOR_BG,
      COLOR_BG,
      @(.24,.48,1.),
    ]);

    GText heading --> GG.scene();
    heading.text("Clawed Code v4.5.1");
    heading.size(FONT_SIZE);
    heading.color(@(1., 1., 1., 0.9));
    heading.controlPoints(@(0., 1.));
    heading.pos(@(CAM_LEFT+(FONT_SIZE * 4.), CAM_TOP-(FONT_SIZE * .6), 0.));
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
}

ClawedCode code();
code.run();
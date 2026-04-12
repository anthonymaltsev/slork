@import {"clawed.ck"}

public class ClawedCode {
  GText terminal;
  Clawed @ clawed;

  @(0.005, 0.005, 0.007) => vec3 COLOR_BG;
  80 => int TERMINAL_W;
  24 => int TERMINAL_H;
  .45 => float CHAR_W;
  1. => float CHAR_H;
  .2 => float FONT_SIZE;
  16 => int SCALE_FACTOR;
    (SCALE_FACTOR / FONT_SIZE) => float FONT_RATIO;

  (TERMINAL_W * CHAR_W * SCALE_FACTOR) => float WINDOW_W;
  (TERMINAL_H * CHAR_H * SCALE_FACTOR) => float WINDOW_H;
  (WINDOW_W / WINDOW_H) => float ASPECT_RATIO;

  float CAM_LEFT;
  float CAM_TOP;

  fun @construct() {
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
      terminal.text("zanestjohn@Zanes-MacBook-Pro-3 ~ % " + val + "\nnewline\nyass\nslay\n" + val + "\nwoohoo " + val);
    }
  }

  fun void _init_window() {
    GWindow.windowed(WINDOW_W $ int, WINDOW_H $ int);
    GWindow.center();
    GWindow.title("clawed --dangerously-skip-critical-thinking");
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
    terminal.pos(@(CAM_LEFT + FONT_SIZE, CAM_TOP - FONT_SIZE, 0.));
    terminal --> GG.scene();
  }

  fun void _init_clawed() {
    // clawed == the mascot of "clawed code"
    new Clawed(1., @(-1., 0., 0.)) @=> clawed;
  }
}

ClawedCode code();
code.run();
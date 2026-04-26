@import {"perlin.ck"}

public class Clawed extends GGen {
  @(.14,.28,1.) => vec3 BODY_COLOR;
  @(.12,.24,1.) => vec3 EYE_OPEN_SCA;

  // DEMONIC MODE
  @(1.,.14,.14) => vec3 BODY_COLOR_DEMONIC;
  @(.16,.04,.01) => vec3 HORN_COLOR;

  2. => float BODY_WIDTH;
  1.25 => float BODY_HEIGHT;
  .3 => float WING_WIDTH;
  .3 => float WING_HEIGHT;
  .15 => float WINGTIP_WIDTH;
  .3 => float WINGTIP_HEIGHT;
  .3 => float FOOT_WIDTH;
  .35 => float FOOT_HEIGHT;

  [
    [@(0.,0.,0.), @(WINGTIP_WIDTH,WINGTIP_HEIGHT,0.), @(0.,0.,0.), @(0.,0.,0.)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH,WINGTIP_HEIGHT,0.), @(0.,0.,.1), @(0.,0.,.2)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH+.16,0.,0.),@(0.,0.,0.), @(0,0.,0.)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH,-WINGTIP_HEIGHT,0.),@(0.,0.,0.), @(0,0.,0.)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH,-WINGTIP_HEIGHT,0.),@(0.,0.,-.1), @(0,0.,-.2)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH,-WINGTIP_HEIGHT,0.), @(0.,0.,0.), @(0.,0.,.2)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH+.16,0.,0.),@(0.,0.,0.), @(0,0.,0.)]
  ] @=> vec3 FLAP_PHASES[][];
  FLAP_PHASES.size() => int NUM_FLAP_PHASES;

  int is_demonic;

  0 => int flap_phase;
  100::ms => dur flap_delay;
  vec3 left_wing_baseline_pos;
  vec3 right_wing_baseline_pos;

  // body parts
  GPlane body;
  GPlane wing_left;
  GPlane wing_right;
  GPlane wingtip_left;
  GPlane wingtip_right;
  GPlane eye_left;
  GPlane eye_right;
  GPlane foot_left;
  GPlane foot_right;
  GMesh beak;
  Geometry beak_geo;
  GMesh horn_left;
  GMesh horn_right;
  Geometry horn_left_geo;
  Geometry horn_right_geo;
  FlatMaterial body_mat;
  FlatMaterial eye_mat;
  FlatMaterial horn_mat;

  fun @construct() {
    return Clawed(1., @(0.,0.,0.));
  }

  fun @construct(float scale, vec3 position) {
    //TODO: uncomment on done debugging demon clawed
    return Clawed(scale, position, false);
    // return Clawed(scale, position, true);
  }

  fun @construct(float scale, vec3 position, int demonic) {
    BODY_COLOR => body_mat.color;
    @(0.,0.,0.) => eye_mat.color;
    HORN_COLOR => horn_mat.color;

    // body
    _init_plane(body, @(0.,0.,0.), @(BODY_WIDTH,BODY_HEIGHT,1.));

    // wings & wingtips
    _init_wing(wing_left, wingtip_left, false);  // l
    _init_wing(wing_right, wingtip_right, true); // r

    // eyes
    _init_plane(eye_left, @(-(BODY_WIDTH-.8)/2,(BODY_HEIGHT-.8)/2,0.), EYE_OPEN_SCA, eye_mat);
    _init_plane(eye_right, @((BODY_WIDTH-.8)/2,(BODY_HEIGHT-.8)/2,0.), EYE_OPEN_SCA, eye_mat);

    // feet
    _init_plane(foot_left, @(-(BODY_WIDTH-.8)/2,-(BODY_HEIGHT+FOOT_HEIGHT)/2,0.), @(FOOT_WIDTH,FOOT_HEIGHT,1.), @(.7,.8,.2));
    _init_plane(foot_right, @((BODY_WIDTH-.8)/2,-(BODY_HEIGHT+FOOT_HEIGHT)/2,0.), @(FOOT_WIDTH,FOOT_HEIGHT,1.), @(.7,.8,.2));

    // beak
    _init_beak();

    // horns for demonic mode >:3
    _init_horns();

    // position and scale the whole character
    position => this.pos;
    @(scale, scale, scale) => this.sca;

    "Clawed" => this.name; // since the claude code mascot's internal name is "Clawd"
    // this --> GG.scene();

    if (demonic) set_demonic(1);
  }

  // fun @destruct() {
  //   this --< GG.scene();
  // }

  fun float get_body_width() {
    return BODY_WIDTH;
  }

  fun float get_body_height() {
    return BODY_HEIGHT;  
  }

  fun float get_full_width() {
    return (BODY_WIDTH + (2 * WING_WIDTH) + (2 * WINGTIP_WIDTH)) * this.sca().x;
  }
  fun float get_full_height() {
    return (BODY_HEIGHT + FOOT_HEIGHT) * this.sca().y;
  }

  fun void set_demonic(int on) {
    on => is_demonic;
    if (is_demonic) {
      BODY_COLOR_DEMONIC => body_mat.color;
      @(1.,1.,1.) => eye_mat.color;
      beak_geo.positions([@(-0.1,0.,0.),@(0.1,0.,0.),@(0.,0.2,0.)]);
      horn_left --> this;
      horn_right --> this;
    } else {
      BODY_COLOR => body_mat.color;
      @(0.,0.,0.) => eye_mat.color;
      beak_geo.positions([@(-0.1,0.,0.),@(0.1,0.,0.),@(0.,-0.2,0.)]);
      horn_left --< this;
      horn_right --< this;
    }
  }

  fun void _animate_blinking() {
    while (true) {
      Math.random2(6000, 12000)::ms * (flap_delay / 100::ms) => now;
      eye_left.sca(@(0.,0.,0.));
      eye_right.sca(@(0.,0.,0.));
      300::ms => now;
      eye_left.sca(EYE_OPEN_SCA);
      eye_right.sca(EYE_OPEN_SCA);
    }
  }

  fun void _animate_flapping() {
    while (true) {
      flap_delay => now;
      (flap_phase + 1) % NUM_FLAP_PHASES => flap_phase;
      _redraw_wings();
    }
  }

  fun void _flash_demon() {
    set_demonic(1);
    70::ms => now;
    set_demonic(0);
  }

  fun void _init_wing(GPlane wing, GPlane wingtip, int right) {
    @((right ? 1 : -1) * (BODY_WIDTH+WING_WIDTH)/2.,-WING_WIDTH/2,0.) => vec3 wing_pos;

    if (right) {
      wing_pos => right_wing_baseline_pos;
    } else {
      wing_pos => left_wing_baseline_pos;
    }

    _init_plane(wing, wing_pos, @(WING_WIDTH,WING_HEIGHT,1.));
    // _init_plane(wingtip, wing_pos - @((right ? -1 : 1) * WINGTIP_WIDTH,WINGTIP_HEIGHT,0.), @(WINGTIP_WIDTH,WINGTIP_HEIGHT,1.), BODY_COLOR);
    _init_plane(wingtip, wing_pos, @(.14,.28,1.));
    _redraw_wings();
  }

  fun void _position_wing(GPlane wing, GPlane wingtip, int right) {
    FLAP_PHASES[flap_phase] @=> vec3 phase[];
    (right ? right_wing_baseline_pos : left_wing_baseline_pos) => vec3 baseline;

    (right ? 1. : -1.) => float mult;

    wing.pos(baseline + phase[0]);
    wing.rot(mult * phase[2]);
    wingtip.pos(baseline + @(mult * phase[1].x, -phase[1].y, phase[1].z));
    wingtip.rot(mult * phase[3]);
  }

  fun void _redraw_wings() {
    // reposition both wings according to current flap phase
    _position_wing(wing_left, wingtip_left, 0);
    _position_wing(wing_right, wingtip_right, 1);
  }

  fun void _init_beak() {
    // isosceles triangle beak
    beak_geo.vertexCount(3);
    beak_geo.indices([0,1,2]);

    FlatMaterial beak_mat;
    @(.7,.8,.2) => beak_mat.color;

    new GMesh(beak_geo, beak_mat) @=> beak;

    // new: "orthographic"-esque downward beak centered on body
    beak.pos(@(0.,0.,0.));
    beak_geo.positions([@(-0.1,0.,0.),@(0.1,0.,0.),@(0.,-0.2,0.)]);
    // old - right-side-of-body beak
    // beak_geo.positions([@(-0.1,0.0,0.0),@(0.1,-0.1,0.0),@(-0.1,-0.2,0.0)]);
    // beak.pos(@((BODY_WIDTH+.2)/2,.2));

    beak --> this;
  }

  fun void _init_plane(GPlane plane, vec3 pos, vec3 sca) {
    body_mat => plane.mat;
    sca => plane.sca;
    pos => plane.pos;
    plane --> this;
  }
  fun void _init_plane(GPlane plane, vec3 pos, vec3 sca, vec3 color) {
    FlatMaterial plane_mat;
    color => plane_mat.color;
    plane_mat => plane.mat;
    sca => plane.sca;
    pos => plane.pos;
    plane --> this;
  }
  fun void _init_plane(GPlane plane, vec3 pos, vec3 sca, FlatMaterial mat) {
    mat => plane.mat;
    sca => plane.sca;
    pos => plane.pos;
    plane --> this;
  }

  fun void _init_horns() {
    //note, horns not connected to this until set_demonic(1) called
    horn_left_geo.vertexCount(3);
    horn_left_geo.indices([0,1,2]);
    horn_left_geo.positions([@(-.12,0.,0.),@(.12,0.,0.),@(0.,.3,0.)]);
    new GMesh(horn_left_geo, horn_mat) @=> horn_left;
    horn_left.pos(@(-(BODY_WIDTH*.25), BODY_HEIGHT/2., 0.));

    horn_right_geo.vertexCount(3);
    horn_right_geo.indices([0,1,2]);
    horn_right_geo.positions([@(-.12,0.,0.),@(.12,0.,0.),@(0.,.3,0.)]);
    new GMesh(horn_right_geo, horn_mat) @=> horn_right;
    horn_right.pos(@(BODY_WIDTH*.25, BODY_HEIGHT/2., 0.));
  }
}

public class ClawedAnimated extends Clawed {
  Shred @ blinking;
  Shred @ flapping;
  Shred @ demon_flash;

  fun @construct(float scale, vec3 position) {
    ClawedAnimated(scale, position, false);
  }

  fun @construct(float scale, vec3 position, int demonic) {
    Clawed(scale, position, demonic);
    "Clawd (Animated)" => this.name;
    animate_blinking();
  }

  fun @destruct() {
    _kill_spork(blinking);
    _kill_spork(flapping);
    _kill_spork(demon_flash);
  }

  fun void animate_blinking() {
    spork ~ _animate_blinking() @=> blinking;
  }
  
  fun void animate_flapping() {
    spork ~ _animate_flapping() @=> flapping;
  }

  fun void flash_demon() {
    _kill_spork(demon_flash);
    spork ~ _flash_demon() @=> demon_flash;
  }

  fun void _kill_spork(Shred sp) {
    if (sp != null) Machine.remove(sp.id());
  }
}

public class ClawedFlock {
  ClawedAnimated birdies[];
  Perlin2D perlin[];

  0 => int birdie_count;
  1::second => dur _freq;
  1 => float _scale;
  0 => int wait_count;
  10 => int MAX_WAIT;
  0 => int started;
  time start_time;
  20::second => dur time_to_be_constrained_to_window;

  4.5 => float term_w;
  term_w * (2./3) => float term_h;
  0.5 => float bird_w;
  0.4 => float bird_h;
  @(-1.6,.9,0.) => vec3 term_center;

  fun @construct(int size, dur freq, float scale) {
    freq => _freq;
    scale => _scale;
    new ClawedAnimated[size] @=> birdies;
    new Perlin2D[size] @=> perlin;

    for (0 => int i; i < size; i++) {
      add_birdie();
    }
  }

  fun void start() {
    if (!started) {
      1 => started;
      now => start_time;
    }
  }

  fun void add_birdie() {
    birdie_count++ => int i;
    birdies << new ClawedAnimated(Math.random2f(.5,1.1) * _scale, @(Math.random2f(term_center.x - 0.4, term_center.x + 0.4),Math.random2f(term_center.y - 0.4, term_center.y + 0.4),7.));
    // add to top-level scene, since the GGen no longer auto-adds
    birdies[i] --> GG.scene();
    birdies[i].animate_blinking();
    birdies[i].animate_flapping();
    perlin << new Perlin2D();
    perlin[i].init(1003 + i, _freq * (1 + i * 0.07), 8);
  }

  fun void pos(vec3 pos_in) {
    if (++wait_count >= MAX_WAIT) {
      for (0 => int i; i < birdies.size(); i++) {
        pos_in + perlin[i].generate(now + 8::second) => vec3 new_pos;
        now - start_time => dur time_being_crazy;
        if (time_being_crazy < time_to_be_constrained_to_window) {
          @(Math.clampf(new_pos.x, -1.6-term_w/2. + bird_w, -1.6+term_w/2. - bird_w), Math.clampf(new_pos.y, 0.9-term_h/2. + bird_h, 0.9+term_h/2. - bird_h), Math.clampf(new_pos.z, 0., 0.)) => new_pos;
        }
        birdies[i].pos(new_pos);
      }
      0 => wait_count;
    }
  }
}

// TODO: make a superclass for both ClawedFlock and WordCloud
// to manage perlin/positioning calculations
public class WordCloud {
  GText word_objs[];
  Perlin2D perlin[];

  0 => int word_count;
  1::second => dur _freq;
  1 => float _scale;
  0 => int wait_count;
  16 => int MAX_WAIT;

  fun @construct(string words[], dur freq, float scale, int reps) {
    words.size() => int size;
    freq => _freq;
    scale => _scale;
    new GText[size] @=> word_objs;
    new Perlin2D[size] @=> perlin;

    for (0 => int i; i < reps; i++) {
      for (0 => int j; j < size; j++) {
        add_word(words[j]);
      }
    }
  }

  fun void add_word(string word) {
    word_count++ => int i;
    create_word_text(word, @(Math.random2f(-2,2),Math.random2f(-2,2),0.)) @=> word_objs[i];
    new Perlin2D() @=> perlin[i];
    perlin[i].init(1003 + i, _freq * (1 + i * 0.07), 8);
  }

  fun void pos(vec3 pos_in) {
    if (++wait_count >= MAX_WAIT){
      for (0 => int i; i < word_objs.size(); i++) {
        word_objs[i].pos(pos_in + GG.camera().viewSize() * perlin[i].generate(now + (i * 8::second)));
      }
      0 => wait_count;
    }
  }

  fun GText create_word_text(string word, vec3 pos) {
    GText txt --> GG.scene();
    txt.font("fonts/DejaVuSansMono.ttf");
    txt.size(_scale * .4 * Math.random2f(.6,1.1));
    txt.color(@(1., 1., 1., 0.9));
    txt.controlPoints(@(0., 1.));
    txt.text(word);
    txt.pos(pos);
    return txt;
  }
}
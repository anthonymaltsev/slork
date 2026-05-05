@import {"perlin.ck", "perlin_cloud.ck"}

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
  .25 => float FOOT_HEIGHT;
  .08 => float CLAW_WIDTH;
  .22 => float CLAW_HEIGHT;
  .07 => float CLAW_CURVE;
  3 => int CLAWS_PER_FOOT;
  @(.7,.8,.2) => vec3 CLAW_COLOR;

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
  GMesh @ claws[6];
  Geometry claw_geos[6];
  FlatMaterial body_mat;
  FlatMaterial eye_mat;
  FlatMaterial horn_mat;
  FlatMaterial claw_mat;

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

    // claws (new, hope u guys like!)
    _init_claws();

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
    (is_demonic ? CLAW_HEIGHT : 0.) => float claw_h;
    return (BODY_HEIGHT + FOOT_HEIGHT + claw_h) * this.sca().y;
  }

  fun void set_demonic(int on) {
    on => is_demonic;
    if (is_demonic) {
      BODY_COLOR_DEMONIC => body_mat.color;
      @(1.,1.,1.) => eye_mat.color;
      beak_geo.positions([@(-0.1,0.,0.),@(0.1,0.,0.),@(0.,0.2,0.)]);
      horn_left --> this;
      horn_right --> this;
      for (0 => int i; i < claws.size(); i++) claws[i] --> this;
    } else {
      BODY_COLOR => body_mat.color;
      @(0.,0.,0.) => eye_mat.color;
      beak_geo.positions([@(-0.1,0.,0.),@(0.1,0.,0.),@(0.,-0.2,0.)]);
      horn_left --< this;
      horn_right --< this;
      for (0 => int i; i < claws.size(); i++) claws[i] --< this;
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

  fun void _init_claws() {
    // claws are not connected until we call set_demonic(1)
    CLAW_COLOR => claw_mat.color;
    -(BODY_HEIGHT/2) - FOOT_HEIGHT => float foot_bottom_y;

    for (0 => int s; s < 2; s++) {
      (s == 0 ? -1. : 1.) => float side_sign;
      side_sign * (BODY_WIDTH-.8)/2 => float foot_cx;
      for (0 => int i; i < CLAWS_PER_FOOT; i++) {
        s * CLAWS_PER_FOOT + i => int aidx;
        claw_geos[aidx].vertexCount(3);
        claw_geos[aidx].indices([0,1,2]);
        //tips curve outward from each foot's center as talons would be
        claw_geos[aidx].positions([
          @(-CLAW_WIDTH/2, 0., 0.),
          @(CLAW_WIDTH/2, 0., 0.),
          @(side_sign * CLAW_CURVE, -CLAW_HEIGHT, 0.)
        ]);
        new GMesh(claw_geos[aidx], claw_mat) @=> claws[aidx];
        (i - (CLAWS_PER_FOOT - 1) / 2.) * (FOOT_WIDTH / CLAWS_PER_FOOT) => float dx;
        claws[aidx].pos(@(foot_cx + dx, foot_bottom_y, 0.));
      }
    }
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
  }

  fun void animate_blinking() {
    spork ~ _animate_blinking() @=> blinking;
  }
  
  fun void animate_flapping() {
    spork ~ _animate_flapping() @=> flapping;
  }

  fun void _kill_spork(Shred sp) {
    if (sp != null) Machine.remove(sp.id());
  }
}

public class ClawedFlock extends PerlinCloud {
  4.5 => float term_w;
  term_w * (2./3) => float term_h;
  0.5 => float bird_w;
  0.4 => float bird_h;
  @(-1.6,.9,0.) => vec3 term_center;

  @(0.5,1.1) => vec2 spawn_scale_range;
  0.4 => float spawn_jitter;
  7. => float spawn_z;

  fun @construct(int size, dur freq_in, float scale_in) {
    PerlinCloud(freq_in, scale_in, 10);
    set_constraint_bounds(term_center, term_w, term_h, bird_w, bird_h);
    for (0 => int i; i < size; i++) add_birdie();
  }

  fun int birdie_count() { return count(); }

  fun void add_birdie() {
    new ClawedAnimated(
      Math.random2f(spawn_scale_range.x, spawn_scale_range.y) * scale,
      @(Math.random2f(term_center.x - spawn_jitter, term_center.x + spawn_jitter),
        Math.random2f(term_center.y - spawn_jitter, term_center.y + spawn_jitter),
        spawn_z)
    ) @=> ClawedAnimated b;
    b.animate_blinking();
    b.animate_flapping();
    add(b);
  }
}

public class WordCloud extends PerlinCloud {
  "fonts/DejaVuSansMono.ttf" => string font_face;
  @(1., 1., 1., 0.9) => vec4 word_color;
  @(0.6, 1.1) => vec2 spawn_size_range;
  0.4 => float size_factor;
  @(-2., 2.) => vec2 spawn_xy_range;

  // ratios for our font (DejaVuSansMono) used to estimate each word
  // bounding half-extent for constraint clamp
  0.6 => float CHAR_W_RATIO;
  0.5 => float LINE_H_RATIO;

  // half-extent (half-width, half-height) per element: populated as
  // we add words to the cloud :)
  vec2 _word_half_extents[0];

  fun @construct(dur freq_in, float scale_in) {
    PerlinCloud(freq_in, scale_in, 16);
  }

  fun @construct(string words[], dur freq_in, float scale_in, int reps) {
    PerlinCloud(freq_in, scale_in, 16);
    for (0 => int r; r < reps; r++) {
      for (0 => int j; j < words.size(); j++) add_word(words[j]);
    }
  }

  fun int word_count() { return count(); }

  fun void add_word(string word) {
    <<< "adding word", word >>>;
    add(create_word_text(word,
      @(Math.random2f(spawn_xy_range.x, spawn_xy_range.y),
        Math.random2f(spawn_xy_range.x, spawn_xy_range.y), 0.)));
  }

  fun GText create_word_text(string word, vec3 pos) {
    GText txt;
    txt.font(font_face);
    scale * size_factor * Math.random2f(spawn_size_range.x, spawn_size_range.y) => float font_size;
    txt.size(font_size);
    txt.color(word_color);
    txt.controlPoints(@(0.5, 0.5));
    txt.text(word);
    txt.pos(pos);
    // record half-extents IN LOCKSTEP (!) with PerlinCloud.elements
    _word_half_extents << @(font_size * CHAR_W_RATIO * word.length() / 2.,
                            font_size * LINE_H_RATIO);
    return txt;
  }

  fun time _sample_time(int i) {
    return now + (i * 8::second);
  }

  fun vec3 _position_for(int i, vec3 base, vec2 offset) {
    GG.camera().viewSize() => float vs;
    return base + @(vs * offset.x, vs * offset.y, 0.);
  }

  fun vec2 _element_half_extent(int i) {
    if (i < 0 || i >= _word_half_extents.size()) return @(0., 0.);
    return _word_half_extents[i];
  }
}

public class GlitchCloud extends PerlinCloud {
  @(0.05, 0.6) => vec2 size_range;
  7. => float spawn_z;

  @(-3., 3.) => vec2 x_range;
  @(-2., 2.) => vec2 y_range;

  float VW;
  float VH;
  float ASPECT_RATIO;

  fun @construct() {
    PerlinCloud(200::ms, 1., 8);
  }

  fun void populate(int n) {
    _init();
    clear();
    for (0 => int i; i < n; i++) _add_square();
  }

  fun void _init() {
    GG.frameWidth()/GG.frameHeight() => ASPECT_RATIO;
    GG.camera().viewSize() => VH;
    VH * ASPECT_RATIO => VW;
  }

  fun vec3 _random_pos() {
    return @(
      Math.random2f(-VW/2., VW/2.),
      Math.random2f(-VH/2., VH/2.),
      spawn_z);
  }

  fun void _add_square() {
    GPlane sq;
    FlatMaterial mat;
    @(1.,1.,1.) => mat.color;
    mat => sq.mat;
    Math.random2f(size_range.x, size_range.y) => float s;
    @(s, s, 1.) => sq.sca;
    _random_pos() => sq.pos;
    add(sq);
  }

  fun vec3 _position_for(int i, vec3 base, vec2 offset) {
    return _random_pos();
  }
}
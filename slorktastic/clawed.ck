@import {"perlin.ck"}

public class Clawed extends GGen {
  @(.14,.28,1.) => vec3 BODY_COLOR;
  @(.12,.24,1.) => vec3 EYE_OPEN_SCA;

  2. => float BODY_WIDTH;
  1.25 => float BODY_HEIGHT;
  .3 => float WING_WIDTH;
  .3 => float WING_HEIGHT;
  .15 => float WINGTIP_WIDTH;
  .3 => float WINGTIP_HEIGHT;
  .3 => float FOOT_WIDTH;
  .35 => float FOOT_HEIGHT;

  [
    [@(0.,0.,0.), @(WINGTIP_WIDTH,WINGTIP_HEIGHT,0.)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH+.16,0.,0.)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH,-WINGTIP_HEIGHT,0.)],
    [@(0.,0.,0.), @(WINGTIP_WIDTH+.16,0.,0.)]
  ] @=> vec3 FLAP_PHASES[][];
  FLAP_PHASES.size() => int NUM_FLAP_PHASES;

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

  fun @construct() {
    return Clawed(1., @(0.,0.,0.));
  }

  fun @construct(float scale, vec3 position) {
    // body
    _init_plane(body, @(0.,0.,0.), @(BODY_WIDTH,BODY_HEIGHT,1.));

    // wings & wingtips
    _init_wing(wing_left, wingtip_left, false);  // l
    _init_wing(wing_right, wingtip_right, true); // r

    // eyes
    _init_plane(eye_left, @(-(BODY_WIDTH-.8)/2,(BODY_HEIGHT-.8)/2,0.), EYE_OPEN_SCA, @(0.,0.,0.));
    _init_plane(eye_right, @((BODY_WIDTH-.8)/2,(BODY_HEIGHT-.8)/2,0.), EYE_OPEN_SCA, @(0.,0.,0.));

    // feet
    _init_plane(foot_left, @(-(BODY_WIDTH-.8)/2,-(BODY_HEIGHT+FOOT_HEIGHT)/2,0.), @(FOOT_WIDTH,FOOT_HEIGHT,1.), @(.7,.8,.2));
    _init_plane(foot_right, @((BODY_WIDTH-.8)/2,-(BODY_HEIGHT+FOOT_HEIGHT)/2,0.), @(FOOT_WIDTH,FOOT_HEIGHT,1.), @(.7,.8,.2));

    // beak
    _init_beak();

    // position and scale the whole character
    position => this.pos;
    @(scale, scale, scale) => this.sca;

    "Clawed" => this.name; // since the claude code mascot's internal name is "Clawd"
    this --> GG.scene();
  }

  fun @destruct() {
    this --< GG.scene();
  }

  fun float get_body_width() {
    return BODY_WIDTH;
  }

  fun float get_body_height() {
    return BODY_HEIGHT;  
  }

  fun float get_full_width() {
    return BODY_WIDTH + (2 * WING_WIDTH) + (2 * WINGTIP_WIDTH);
  }
  fun float get_full_height() {
    return BODY_HEIGHT + FOOT_HEIGHT;
  }

  fun void _animate_blinking() {
    while (true) {
      Math.random2(6000, 12000)::ms => now;
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

    _init_plane(wing, wing_pos, @(WING_WIDTH,WING_HEIGHT,1.), BODY_COLOR);
    // _init_plane(wingtip, wing_pos - @((right ? -1 : 1) * WINGTIP_WIDTH,WINGTIP_HEIGHT,0.), @(WINGTIP_WIDTH,WINGTIP_HEIGHT,1.), BODY_COLOR);
    _init_plane(wingtip, wing_pos, BODY_COLOR);
    _redraw_wings();
  }

  fun void _position_wing(GPlane wing, GPlane wingtip, int right) {
    FLAP_PHASES[flap_phase] @=> vec3 phase[];
    (right ? right_wing_baseline_pos : left_wing_baseline_pos) => vec3 baseline;

    wing.pos(baseline + phase[0]);
    wingtip.pos(baseline + @((right ? 1. : -1.) * phase[1].x, -phase[1].y, phase[1].z));
  }

  fun void _redraw_wings() {
    // reposition both wings according to current flap phase
    _position_wing(wing_left, wingtip_left, 0);
    _position_wing(wing_right, wingtip_right, 1);
  }

  fun void _init_beak() {
    // isosceles triangle beak
    Geometry beak_geo;
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
    return _init_plane(plane, pos, sca, BODY_COLOR, 0);
  }
  fun void _init_plane(GPlane plane, vec3 pos, vec3 sca, vec3 color) {
    return _init_plane(plane, pos, sca, color, 0);
  }
  fun void _init_plane(GPlane plane, vec3 pos, vec3 sca, vec3 color, int skip_add) {
    FlatMaterial plane_mat;
    color => plane_mat.color;
    plane_mat => plane.mat;
    sca => plane.sca;
    pos => plane.pos;
    plane --> this;
  }
}

public class ClawedAnimated extends Clawed {
  Shred @ blinking;
  Shred @ flapping;

  fun @construct(float scale, vec3 position) {
    Clawed(scale, position);
    "Clawd (Animated)" => this.name;
  }

  fun @destruct() {
    if (blinking != null) {
      Machine.remove(blinking.id());
      Machine.remove(flapping.id());
    }
  }

  fun void animate() {
    spork ~ _animate_blinking() @=> blinking;
    spork ~ _animate_flapping() @=> blinking;
  }
}

// class FlockBird{
//     FlyingBird b[];
//     Perlin3D p[];

//     fun void init(int size, int id, dur freq, float amp, float scale) {
//         new FlyingBird[size] @=> b;
//         new Perlin3D[size] @=> p;
//         for(0 => int i; i < size; i++) {
//             new FlyingBird(0.5, scale) @=> b[i];
//             sun.shadowAdd(b[i], true);
//             // b[i] --> GG.scene();

//             p[i].init(id*1003 + i, freq * (1 + i * 0.07), amp);
//         }
//     }

//     fun void pos(vec3 pos_in) {
//         for (0 => int i; i < b.size(); i++) {
//             b[i].pos() => vec3 prev;
//             b[i].pos(pos_in + p[i].generate(now + 10::second));
//             b[i].pos() => vec3 curr;
//             b[i].orient_to_vec(curr-prev);
//         }
//     }

// }

public class ClawedFlock {
  ClawedAnimated birdies[];
  Perlin2D perlin[];

  fun @construct(int size, dur freq) {
    new ClawedAnimated[size] @=> birdies;
    new Perlin2D[size] @=> perlin;

    for (0 => int i; i < size; i++) {
      new ClawedAnimated(1, @(0.,0.,0.)) @=> birdies[i];
      birdies[i].animate();
      perlin[i].init(1003 + i, freq * (1 + i * 0.07), 8);
    }
  }

  fun void pos(vec3 pos_in) {
    for (0 => int i; i < birdies.size(); i++) {
      birdies[i].pos(pos_in + perlin[i].generate(now + 4::second));
    }
  }
}
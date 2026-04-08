//-----------------------------------------------------------------------------
// name: siparow_keyboard.ck
// desc: use keyboard to control 2 siparows, one for each string
// dependencies: sparrow.ck, siparow.ck
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import {"siparow.ck", "perlin.ck", "bird_obj.ck"}

// ----------------------- chugl visualizer --------------------------
GG.fullscreen();
GG.camera() @=> GCamera cam;
GG.scene().backgroundColor(Color.SKYBLUE);
GG.bloom(1);

cam.pos(@(0., 5., 15.));
cam.lookAt(@(0., 4., 0.));

GDirLight sun;
sun.pos(@(5., 8., 5.));
sun.lookAt(@(0., 0., 0.));
sun.shadow(true);

GPlane floor;
floor.color(Color.GREEN);
floor.pos(@(0., -1., 0.));
floor.scaX(40.);
floor.scaY(25.);
floor.rotateX(-Math.PI / 2.);
floor.shadowed(true);

sun --> GG.scene();
floor --> GG.scene();

class FlockSphere{
    GSphere b[];
    Perlin3D p[];

    fun void init(int size, int id, dur freq, float amp, float scale) {
        new GSphere[size] @=> b;
        new Perlin3D[size] @=> p;
        for(0 => int i; i < size; i++) {
            b[i].color(Color.WHITE);
            b[i].emission(Color.WHITE);
            b[i].mat(new FlatMaterial());
            b[i].shadowed(true);
            b[i].scaX(scale);
            b[i].scaY(scale);
            b[i].scaZ(scale);
            sun.shadowAdd(b[i], false);
            b[i] --> GG.scene();

            p[i].init(id*1003 + i, freq * (1 + i * 0.07), amp);
        }
    }

    fun void pos(vec3 pos_in) {
        for (0 => int i; i < b.size(); i++) {
            b[i].pos(pos_in + p[i].generate(now + 10::second));
        }
    }

}

class FlockBird{
    FlyingBird b[];
    Perlin3D p[];

    fun void init(int size, int id, dur freq, float amp, float scale) {
        new FlyingBird[size] @=> b;
        new Perlin3D[size] @=> p;
        for(0 => int i; i < size; i++) {
            new FlyingBird(0.5, scale) @=> b[i];
            sun.shadowAdd(b[i], false);
            // b[i] --> GG.scene();

            p[i].init(id*1003 + i, freq * (1 + i * 0.07), amp);
        }
    }

    fun void pos(vec3 pos_in) {
        for (0 => int i; i < b.size(); i++) {
            b[i].pos() => vec3 prev;
            b[i].pos(pos_in + p[i].generate(now + 10::second));
            b[i].pos() => vec3 curr;
            b[i].orient_to_vec(curr-prev);
        }
    }

}

FlockBird bleft;
bleft.init(3, 0, 1::second, 1., 0.33);
@(-1., 0., 0.) => vec3 left_base;
bleft.pos(left_base);

FlockBird bright;
bright.init(3, 1, 1::second, 1., 0.33);
@(1., 0., 0.) => vec3 right_base;
bright.pos(right_base);

fun vec3 gt_pos_to_xyz(float lr, float fb, float mag) {
    mag * Math.sin(Math.pi / 4. * lr) => float x;
    0 - mag * Math.sin(Math.pi / 4. * fb) => float z;
    mag * (1 - Math.pow(Math.sin(Math.pi / 4. * lr), 2) - Math.pow(Math.sin(Math.pi / 4. * fb), 2))=> float y;
    10. => float scale;
    @(scale*x, scale*y, scale*z) => vec3 ret;
    return ret;
}

fun vec3 xyz_to_gt_pos(vec3 pos) {
    Math.sqrt(Math.pow(pos.x, 2) + Math.pow(pos.y, 2) + Math.pow(pos.z, 2)) => float mag;
    Math.asin(pos.x/mag) / (Math.PI/4.) => float lr;
    Math.asin(pos.y/mag) / (Math.PI/4.) => float fb;
    1./10. => float scale;
    @(scale*lr, scale*fb, scale*mag) => vec3 ret;
    return ret;
}

0.05 => float update_scale;
fun vec3 left_update() {
    @(0., 0., 0.) => vec3 offset;
    if (GWindow.key(GWindow.KEY_A)) @(-1., 0., 0.) +=> offset;
    if (GWindow.key(GWindow.KEY_D)) @(1., 0., 0.) +=> offset;
    if (GWindow.key(GWindow.KEY_W)) @(0., 0., -1.) +=> offset;
    if (GWindow.key(GWindow.KEY_S)) @(0., 0., 1.) +=> offset;
    if (GWindow.key(GWindow.KEY_E)) @(0., 1., 0.) +=> offset;
    if (GWindow.key(GWindow.KEY_Q)) @(0., -1., 0.) +=> offset;
    return update_scale * offset;
}
fun vec3 right_update() {
    @(0., 0., 0.) => vec3 offset;
    if (GWindow.key(GWindow.KEY_A)) @(-1., 0., 0.) +=> offset;
    if (GWindow.key(GWindow.KEY_D)) @(1., 0., 0.) +=> offset;
    if (GWindow.key(GWindow.KEY_W)) @(0., 0., -1.) +=> offset;
    if (GWindow.key(GWindow.KEY_S)) @(0., 0., 1.) +=> offset;
    if (GWindow.key(GWindow.KEY_E)) @(0., 1., 0.) +=> offset;
    if (GWindow.key(GWindow.KEY_Q)) @(0., -1., 0.) +=> offset;
    return update_scale * offset;
}
fun void update() {
    left_update() +=> left_base;
    right_update() +=> right_base;
    bleft.pos(left_base);
    bright.pos(right_base);
}

fun void update_loop() {
    while (true) {
        update();
        GG.nextFrame() => now;
    }
}
spork ~ update_loop();

// ------------------------ siparow setup ------------------------------

Siparow left;
Siparow right;

left.init(
    [3500., 4000., 4500.], // freq
    [160::ms, 150::ms, 140::ms], // durs
    [200::ms, 225::ms, 250::ms], // inter_durs
    [0.6, 0.6, 0.5], // gains
    [dac.left, dac.left, dac.left] // out channels
);
right.init(
    [3500., 4000., 4500.], // freq
    [160::ms, 150::ms, 140::ms], // durs
    [400::ms, 450::ms, 500::ms], // inter_durs
    [0.6, 0.6, 0.5], // gains
    [dac.right, dac.right, dac.right] // out channels
);

left.set_them_loose();
right.set_them_loose();

left.propagate_rev(0.05);

spork ~ update_siparows_from_gt();

fun void update_siparows_from_gt() {
    while (true) {

        // left
        xyz_to_gt_pos(left_base) => vec3 bleft_gt_pos;
        left.propagate_gain_mul(gain_norm(bleft_gt_pos.z));
        //left.propagate_dur_mul(dur_norm(gt.axis[0]));
        left.propagate_rev(rev_norm(bleft_gt_pos.x));
        left.propagate_inter_dur_mul(inter_dur_norm(bleft_gt_pos.z));
        left.propagate_freq_mul(freq_norm(bleft_gt_pos.y));

        //right
        xyz_to_gt_pos(right_base) => vec3 bright_gt_pos;
        right.propagate_gain_mul(gain_norm(bright_gt_pos.z));
        //right.propagate_dur_mul(dur_norm(gt.axis[3]));
        right.propagate_rev(rev_norm(bright_gt_pos.x));
        right.propagate_inter_dur_mul(inter_dur_norm(bright_gt_pos.z));
        right.propagate_freq_mul(freq_norm(bright_gt_pos.y));

        10::ms => now;
    }
}

fun float gain_norm(float zero_to_one) {
    return Math.clampf(Math.pow(2 * zero_to_one, 2), 0., 0.6);
}

fun float dur_norm(float neg1_to_1) {
    return (neg1_to_1 + 1) / 2.;
}

fun float inter_dur_norm(float zero_to_one) {
    return 1. - zero_to_one;
}

fun float rev_norm(float neg1_to_1) {
    return Math.pow((neg1_to_1 + 1) / 5.5, 2.);
}

fun float freq_norm(float neg1_to_1) {
    if (neg1_to_1 <= 0) {
        return Math.pow(neg1_to_1 + 1., 2.)+0.025;
    }
    return 0.975*neg1_to_1 + 1.;
    //return Math.sexp(1.85*(neg1_to_1 - 1.));
}


// -------------------------- main loop ------------------------------
//while(true){1::second => now;}
while(true) {
    //<<< gt.axis[0], gt.axis[1], gt.axis[2], gt.axis[3], gt.axis[4], gt.axis[5] >>> ;
    <<< "left: \n    freq:      ", left.get_freq_mul()*left.base_freqs[1],
              "\n    inter dur: ", left.get_inter_dur_mul()*left.base_inter_durs[1] / 44.1, "ms",
              "\n    dur:       ", left.get_dur_mul()*left.base_durs[1] / 44.1, "ms",
              "\n    gain:      ", left.get_gain_mul()*left.base_gains[1]
    >>>;
    <<< "right:\n    freq:      ", right.get_freq_mul()*right.base_freqs[1],
              "\n    inter dur: ", right.get_inter_dur_mul()*right.base_inter_durs[1] / 44.1, "ms",
              "\n    dur:       ", right.get_dur_mul()*right.base_durs[1] / 44.1, "ms",
              "\n    gain:      ", right.get_gain_mul()*right.base_gains[1], "\n"
    >>>;
    
    333::ms => now;
    
}


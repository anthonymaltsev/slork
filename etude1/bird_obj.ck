//-----------------------------------------------------------------------------
// name: bird_obj.ck
// desc: Chugl object for bird like entities
//
// author: Gregg Oliva (gloliva@stanford.edu), Anthony Maltsev (amaltsev@stanford.edu)
// date: Fall 2024, Spring 2026
//-----------------------------------------------------------------------------

class Bird extends GGen {
    // graphics objects
    GCube body;
    GCube leftWing;
    GCube rightWing;
    GCube tailTop;
    GCube tailBottom;

    GCube head;
    GCube beakTop;
    GCube beakBottom;
    GCube eye;

    // Color
    vec3 birdColor;

    // animation variables
    int inFlight;
    int mouthMoving;
    float rotateAmount;

    fun @construct(float flapPeriod, float scale) {
        // set member variables
        1 => inFlight;
        1 => mouthMoving;
        (2 * Math.PI) / (flapPeriod * 1000) => rotateAmount;

        // Colors
        Color.random() => vec3 birdColor;
        birdColor => this.birdColor;

        // Graphics rendering
        // Handle head
        @(0.65, 0.5, 0.8) => head.sca;
        @(0.4, 0.4, 0.) => head.pos;
        birdColor * 0.8 => head.color;

        // Handle eye
        @(0.25, 0.2, 1.1) => eye.sca;
        @(0.2, 0.1, 0.) => eye.pos;
        Color.WHITE * 5. => eye.color;

        // Handle beak
        @(0.6, 0.1, 0.5) => beakTop.sca;
        0.5 => beakTop.posX;
        @(0.5, 0.1, 0.5) => beakBottom.sca;
        @(0.45, -0.1, 0.) => beakBottom.pos;

        Color.BLACK => beakTop.color;
        Color.BLACK => beakBottom.color;

        // Handle body
        0.5  => body.scaY;
        birdColor => body.color;

        // Handle wing
        -0.5 => leftWing.posZ;
        0.5 => rightWing.posZ;
        @(0.5, 0.2, 1.) => leftWing.sca;
        @(0.5, 0.2, 1.) => rightWing.sca;
        birdColor * 1.2 => rightWing.color;
        birdColor * 1.2 => leftWing.color;

        // Handle tail
        @(-0.5, 0., 0.) => tailTop.pos;
        @(0.7, 0.2, 0.6) => tailTop.sca;
        -Math.PI / 4 => tailTop.rotZ;
        birdColor * 1.2 => tailTop.color;

        @(-0.5, 0., 0.) => tailBottom.pos;
        @(0.7, 0.2, 0.6) => tailBottom.sca;
        Math.PI / 4 => tailBottom.rotZ;
        birdColor * 1.2 => tailBottom.color;

        // Name the objects for easy UI debugging
        "Head" => head.name;
        "Body" => body.name;
        "Eye" => eye.name;
        "Left Wing" => leftWing.name;
        "Right Wing" => rightWing.name;
        "Tail Top" => tailTop.name;
        "Tail Bottom" => tailBottom.name;
        "Beak Top" => beakTop.name;
        "Beak Bottom" => beakBottom.name;
        "Bird" => this.name;

        // Create the connections
        rightWing --> body;
        leftWing --> body;
        tailBottom --> body;
        tailTop --> body --> this;
        eye --> head;
        beakBottom --> head;
        beakTop --> head --> this;

        @(scale, scale, scale) => this.sca;
        this --> GG.scene();
    }

    fun void removeBird() {
        this.body --< this;
        this.head --< this;
    }

    fun void animateWing() {
        TriOsc wingAnimator(1.) => blackhole;
        while (true) {
            if (inFlight == 1) {
                Std.scalef(wingAnimator.last(), -1., 1., -Math.PI / 4, Math.PI / 4) => float rotation;
                -rotation => leftWing.rotX;
                rotation => rightWing.rotX;
            }
            GG.nextFrame() => now;
        }
    }

    fun void animateMouth() {
        TriOsc mouthAnimator(1.) => blackhole;
        while (true) {
            if (mouthMoving == 1) {
                Std.scalef(mouthAnimator.last(), -1., 1., 0., Math.PI / 4) => float rotation;
                rotation => beakTop.rotZ;
                -rotation => beakBottom.rotZ;
            }
            GG.nextFrame() => now;
        }
    }

    fun void orient_to_vec(vec3 vec) {
        if (vec.x == 0 && vec.y == 0 && vec.z ==0) return;
        this.pos() + @(-vec.z, vec.x, vec.y) => vec3 target;
        this.lookAt(target);
    }

}


public class FlyingBird extends Bird {
    fun @construct(float flapPeriod, float scale) {
        Bird(flapPeriod, scale);
        "Flying Bird" => this.name;
    }

    fun void animate() {
        spork ~ animateWing();
        spork ~ animateMouth();
    }

}

// ChuGL visuals to support switching between different sets of keyboard sounds. 


class TPlane extends GGen {
    GPlane g --> this;
    FlatMaterial mat;
    g.mat(mat);

    fun TPlane(vec2 pos, float scale, vec3 color, float depth) {
        @(pos.x, pos.y, depth) => this.pos;
        scale => this.sca;
        color => mat.color;
    }

    fun vec3 color() {
        return mat.color();
    }

    fun void color(vec3 c) {
        mat.color(c);
    }
}

// percSets class for different set of sounds ====================================================

public class percSets extends GGen {
    
    TPlane icon_bg --> this;
    GText label --> this;
    GText num --> this;

    @(2, 2, 2) => vec3 COLOR_ICONBG_NONE;
    @(1, 1, 1) => vec3 LABEL_COLOR;
    @(.4, .4, 1) => vec3 NUM_COLOR;
    
    // states
    0 => static int NONE;
    1 => static int ACTIVE;
    0 => int state;

    // booleans
    0 => int activateHappened;
    1 => int deactivateHappened;

    // color map
    [
        @(.584, .584, .584),  // NONE
        @(.827, .89, .214)    // ACTIVE
    ] @=> vec3 colorMap[];

    fun @construct() {
        0.4 => icon_bg.sca;
        COLOR_ICONBG_NONE => icon_bg.color;

        0.05 => label.sca;
        LABEL_COLOR => label.color;
        label.posY(0.7);
        label.maxWidth(0.1);
        label.align(1);

        0.1 => num.sca;
        NUM_COLOR => num.color;
        num.posY(0.3);
        num.maxWidth(0.1);
        num.align(1);
    }

    fun void setName(string n) {
        label.text(n);
    }

    fun void setNum(int n) {
        num.text("" + n);
    }

    fun int active() {
        return state == ACTIVE;
    }

    fun void toggle() {
        if (state == NONE) {
            ACTIVE => state;
        } else {
            0 => state;
        }
        <<<"State: ", state>>>;
    }

    fun void update(float dt) {
        icon_bg.color(colorMap[state]);
    }
}


// ChuGL visuals to support switching between different sets of keyboard sounds. 



// simplified Mouse class from examples/input/Mouse.ck
public class Mouse
{
    vec3 worldPos;

    // update mouse world position
    fun void selfUpdate() {
        while (true) {
            GG.nextFrame() => now;
            // calculate mouse world X and Y coords
            GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1.0) => worldPos;
        }
    }
}


class TPlane extends GGen {
    // a convenient plane class for toolbar setup
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

    Mouse @ mouse;
    Event onHoverEvent, onClickEvent;  // onExit, onRelease

    @(2, 2, 2) => vec3 COLOR_ICONBG_NONE;
    
    // states
    0 => static int NONE;
    1 => static int HOVERED;
    2 => static int ACTIVE;
    0 => int state;

    // input types
    0 => static int MOUSE_HOVER;
    1 => static int MOUSE_EXIT;
    2 => static int MOUSE_CLICK;

    // booleans
    0 => int activateHappened;
    1 => int deactivateHappened;

    // color map
    [
        @(.584, .584, .584),  // NONE
        @(0.1, .719, .884),   // HOVERED
        @(.827, .89, .214)    // ACTIVE
    ] @=> vec3 colorMap[];

    fun @construct(Mouse @ m) {
        m @=> this.mouse;

        0.4 => icon_bg.sca;
        COLOR_ICONBG_NONE => icon_bg.color;
        spork ~ this.clickListener();
    }


    // check if state is active
    fun int active() {
        return state == ACTIVE;
    }

    fun int isHovered() {
        icon_bg.scaWorld() => vec3 worldScale;  // get dimensions
        worldScale.x / 2.0 => float halfWidth;
        worldScale.y / 2.0 => float halfHeight;
        icon_bg.posWorld() => vec3 worldPos;   // get position

        if (mouse.worldPos.x > worldPos.x - halfWidth && mouse.worldPos.x < worldPos.x + halfWidth &&
            mouse.worldPos.y > worldPos.y - halfHeight && mouse.worldPos.y < worldPos.y + halfHeight) {
            return true;
        }
        return false;
    }

    // poll for hover events
    fun void pollHover() {
        if (isHovered()) {
            onHoverEvent.broadcast();
            handleInput(MOUSE_HOVER);
        } else {
            if (state == HOVERED) handleInput(MOUSE_EXIT);
        }
    }


    // handle mouse clicks
    fun void clickListener() {
        now => time lastClick;
        while (true) {
            GG.nextFrame() => now;
            if (GWindow.mouseLeftDown() && isHovered()) {
                onClickEvent.broadcast();
                handleInput(MOUSE_CLICK);
            }
        }
    }

    0 => int lastState;
    fun void enter(int s) {
        state => lastState;
        s => state;
    }

    fun void handleInput(int input) {
        if (state == NONE) {
            if (input == MOUSE_HOVER)      enter(HOVERED);
            else if (input == MOUSE_CLICK) enter(ACTIVE);
        } else if (state == HOVERED) {
            if (input == MOUSE_EXIT)       enter(NONE);
            else if (input == MOUSE_CLICK) enter(ACTIVE);
        } else if (state == ACTIVE) {
            if (input == MOUSE_CLICK){
                // <<<"Before: ", deactivated()>>>;
                enter(NONE);
                <<<"State: ", this.state>>>;
                <<<"Last State: ", this.lastState>>>;
                // <<<"After: ", deactivated()>>>;
            }      
        }
    }

    fun void update(float dt) {
        pollHover();
        // update color based on state
        icon_bg.color(colorMap[state]);

    }
}


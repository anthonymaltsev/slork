//-----------------------------------------------------------------------------
// name: verb_board.ck
// desc: soundboard using verb sounds; press a key to play a sound
//
// author: Anthony Maltsev (amaltsev@stanford.edu)
// date: spring 2026
//-----------------------------------------------------------------------------

@import "arbsynth.ck"

ArbSynth sounds[0];

new ArbSynth("data/verbs/pulse/blade-piercing-body.arr", dac) @=> sounds["A"];
new ArbSynth("data/verbs/cont/chain.arr", dac) @=> sounds["B"];
new ArbSynth("data/verbs/calculator-fingertips.arr", dac) @=> sounds["C"];
new ArbSynth("data/verbs/car-horn-honking.arr", dac) @=> sounds["D"];
new ArbSynth("data/verbs/cell-phone-vibrate-high-quality.arr", dac) @=> sounds["E"];
new ArbSynth("data/verbs/chainsaw.arr", dac) @=> sounds["F"];
new ArbSynth("data/verbs/coffee-brewing-futuristic_1.arr", dac) @=> sounds["G"];
new ArbSynth("data/verbs/cooking-frying.arr", dac) @=> sounds["H"];
new ArbSynth("data/verbs/cooking-in-cooking-pot.arr", dac) @=> sounds["I"];
new ArbSynth("data/verbs/cooking-pasta.arr", dac) @=> sounds["J"];
new ArbSynth("data/verbs/cracking-bones.arr", dac) @=> sounds["K"];
new ArbSynth("data/verbs/cry-of-pain.arr", dac) @=> sounds["L"];
new ArbSynth("data/verbs/crying-man.arr", dac) @=> sounds["M"];
new ArbSynth("data/verbs/cutting-vegetables.arr", dac) @=> sounds["N"];
new ArbSynth("data/verbs/e-oh.arr", dac) @=> sounds["O"];
new ArbSynth("data/verbs/foley-chef-cracking-an-egg-into-bowl.arr", dac) @=> sounds["P"];
new ArbSynth("data/verbs/food-cooking-in-oil.arr", dac) @=> sounds["Q"];
new ArbSynth("data/verbs/frantic-screaming.arr", dac) @=> sounds["R"];
new ArbSynth("data/verbs/frying-food-cooking-kitchen.arr", dac) @=> sounds["S"];
new ArbSynth("data/verbs/geese-honking.arr", dac) @=> sounds["T"];
new ArbSynth("data/verbs/glass-breaking.arr", dac) @=> sounds["U"];
new ArbSynth("data/verbs/groaning-gurgle.arr", dac) @=> sounds["V"];
new ArbSynth("data/verbs/keurig-kcup-brewing.arr", dac) @=> sounds["W"];
new ArbSynth("data/verbs/knife-stab.arr", dac) @=> sounds["X"];
new ArbSynth("data/verbs/liquid-swirl.arr", dac) @=> sounds["Y"];
new ArbSynth("data/verbs/little-creature-hurt.arr", dac) @=> sounds["Z"];
new ArbSynth("data/verbs/man-screaming.arr", dac) @=> sounds["1"];
new ArbSynth("data/verbs/moka-express-brewing.arr", dac) @=> sounds["2"];
new ArbSynth("data/verbs/ouch-oof-hurt.arr", dac) @=> sounds["3"];
new ArbSynth("data/verbs/pencil-on-paper.arr", dac) @=> sounds["4"];
new ArbSynth("data/verbs/pretzel-crunching.arr", dac) @=> sounds["5"];
new ArbSynth("data/verbs/puppy-crying.arr", dac) @=> sounds["6"];
new ArbSynth("data/verbs/rain.arr", dac) @=> sounds["7"];
new ArbSynth("data/verbs/rustling-a-newspaper.arr", dac) @=> sounds["8"];
new ArbSynth("data/verbs/screaming-man.arr", dac) @=> sounds["9"];
new ArbSynth("data/verbs/stomach-gurgle.arr", dac) @=> sounds["0"];
<<<"made synths", "" >>>;
Hid hi;
HidMsg msg;
0 => int device;
if (me.args()) me.arg(0) => Std.atoi => device;
if (!hi.openKeyboard(device)) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

fun string keyChar(int ascii) {
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" => string alpha;
    if (ascii >= 65 && ascii <= 90) return alpha.charAt2(ascii - 65);
    if (ascii >= 48 && ascii <= 57) return Std.itoa(ascii - 48);
    return "";
}

<<< "starting main loop" , "">>>;
while (true) {
    hi => now;
    while (hi.recv(msg)) {
        if (msg.isButtonDown()) {
            keyChar(msg.ascii) => string k;
            if (k != "") {
                <<< k, "->", sounds[k].fname >>>;
                spork ~ sounds[k].playback();
            }
        }
    }
}

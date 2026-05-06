public class PianoState {
  int visible_before;
  int visible_after;
  int rainbow_mode;
  int bird_mode;
  int funky_vibrato;

  fun @construct() {
    PianoState(true, false, false, false, false);
  }
  fun @construct(int vis_before, int vis_after) {
    PianoState(vis_before, vis_after, false, false, false);
  }
  fun @construct(int vis_before, int vis_after, int rainbow, int bird, int funky_vib) {
    vis_before => visible_before;
    vis_after => visible_after;
    rainbow => rainbow_mode;
    bird => bird_mode;
    funky_vib => funky_vibrato;
  }
}

public class FlashCue {
  // NOTE offset is absolute from start of cook_duration
  dur offset;
  dur duration;

  fun @construct(dur off, dur d) {
    off => offset;
    d => duration;
  }
}

public class VerbCue {
  string verb;
  float scale;

  fun @construct(string v) {
    VerbCue(v, 1.);
  }
  fun @construct(string v, float s) {
    v => verb;
    s => scale;
  }
}

public class DesktopState {
  string prompt;
  dur cook_duration;
  dur verb_duration;
  int gets_crazy;
  // word cloud appears at prompt-submit (during cook, before chaos) rather
  // than waiting for the chaos ramp. populated with the same buzzwords
  // ClawedCode otherwise gathers at crazy-time.
  int word_cloud_early;
  // gates the tts sayer that reads buzzwords aloud. defaults on for backward
  // compat with the original chaos behavior, turn off to get a silent cloud.
  int tts_enabled;
  string cooking_verbs[];
  // parallel to cooking_verbs w/ relative multiplier applied to
  // verb_duration per verb, jsyk
  float verb_scales[];
  PianoState @ piano_state;
  // NOTEs provided to any brave soul interacting with my code:
  // 1. scheduled demonic flashes: fired during cook_duration only,
  // NOT while prompt is editable
  // 2. chaos-ramp supersedes: if gets_crazy is on and the ramp kicks
  // in, any remaining cues are dropped on the floor (don't try to mix
  // scheduled cues with crazy mode flashes, they'll fight each other for
  // _demon_flash_shred and you'll have a bad time!!)
  FlashCue flash_cues[];

  fun @construct() {
    DesktopState("This is a placeholder prompt for something much more epic. Get creative me, and maybe go to sleep (zzz)");
  }
  fun @construct(string pr) {
    DesktopState(pr, 5::second, 1::second, false, ["Cooking"], new PianoState());
  }
  fun @construct(
    string pr,
    dur cook_dur,
    dur verb_dur,
    int crazy,
    string verbs[],
    PianoState piano
  ) {
    DesktopState(pr, cook_dur, verb_dur, crazy, verbs, piano, new FlashCue[0]);
  }
  fun @construct(
    string pr,
    dur cook_dur,
    dur verb_dur,
    int crazy,
    string verbs[],
    PianoState piano,
    FlashCue cues[]
  ) {
    DesktopState(pr, cook_dur, verb_dur, crazy, verbs, piano, cues, false, true);
  }
  fun @construct(
    string pr,
    dur cook_dur,
    dur verb_dur,
    int crazy,
    string verbs[],
    PianoState piano,
    FlashCue cues[],
    int wc_early,
    int tts
  ) {
    pr => prompt;
    cook_dur => cook_duration;
    verb_dur => verb_duration;
    crazy => gets_crazy;
    verbs @=> cooking_verbs;
    piano @=> piano_state;
    cues @=> flash_cues;
    wc_early => word_cloud_early;
    tts => tts_enabled;
    //default, every verb gets the same duration!
    float scales[verbs.size()];
    for (0 => int i; i < verbs.size(); i++) 1. => scales[i];
    scales @=> verb_scales;
  }
  fun @construct(
    string pr,
    dur cook_dur,
    dur verb_dur,
    int crazy,
    VerbCue verb_cues[],
    PianoState piano
  ) {
    DesktopState(pr, cook_dur, verb_dur, crazy, verb_cues, piano, new FlashCue[0]);
  }
  fun @construct(
    string pr,
    dur cook_dur,
    dur verb_dur,
    int crazy,
    VerbCue verb_cues[],
    PianoState piano,
    FlashCue cues[]
  ) {
    DesktopState(pr, cook_dur, verb_dur, crazy, verb_cues, piano, cues, false, true);
  }
  fun @construct(
    string pr,
    dur cook_dur,
    dur verb_dur,
    int crazy,
    VerbCue verb_cues[],
    PianoState piano,
    FlashCue cues[],
    int wc_early,
    int tts
  ) {
    string verbs[verb_cues.size()];
    float scales[verb_cues.size()];
    for (0 => int i; i < verb_cues.size(); i++) {
      verb_cues[i].verb => verbs[i];
      verb_cues[i].scale => scales[i];
    }
    DesktopState(pr, cook_dur, verb_dur, crazy, verbs, piano, cues, wc_early, tts);
    scales @=> verb_scales;
  }
}
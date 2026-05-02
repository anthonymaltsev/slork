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

public class DesktopState {
  string prompt;
  dur cook_duration;
  dur verb_duration;
  int gets_crazy;
  string cooking_verbs[];
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
    pr => prompt;
    cook_dur => cook_duration;
    verb_dur => verb_duration;
    crazy => gets_crazy;
    verbs @=> cooking_verbs;
    piano @=> piano_state;
    cues @=> flash_cues;
  }
}
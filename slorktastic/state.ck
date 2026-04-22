public class PianoState {
  int visible_before;
  int visible_after;
  int rainbow_mode;
  int funky_vibrato;

  fun @construct() {
    PianoState(true, false, false, false);
  }
  fun @construct(int vis_before, int vis_after) {
    PianoState(vis_before, vis_after, false, false);
  }
  fun @construct(int vis_before, int vis_after, int rainbow, int funky_vib) {
    vis_before => visible_before;
    vis_after => visible_after;
    rainbow => rainbow_mode;
    funky_vib => funky_vibrato;
  }
}

public class DesktopState {
  // TODO: add some fields to control the "bad" keyboard instrument
  string prompt;
  dur cook_duration;
  dur verb_duration;
  int gets_crazy;
  string cooking_verbs[];
  PianoState @ piano_state;

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
    pr => prompt;
    cook_dur => cook_duration;
    verb_dur => verb_duration;
    crazy => gets_crazy;
    verbs @=> cooking_verbs;
    piano @=> piano_state;
  }
}
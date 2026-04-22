public class DesktopState {
  // TODO: add some fields to control the "bad" keyboard instrument
  string prompt;
  dur cook_duration;
  dur verb_duration;
  int gets_crazy;
  string cooking_verbs[];

  fun @construct() {
    DesktopState("This is a placeholder prompt for something much more epic. Get creative me, and maybe go to sleep (zzz)");
  }
  fun @construct(string pr) {
    DesktopState(pr, 5::second, 1::second, false, ["Cooking"]);
  }
  fun @construct(string pr, dur cook_dur, dur verb_dur, int crazy, string verbs[]) {
    pr => prompt;
    cook_dur => cook_duration;
    verb_dur => verb_duration;
    crazy => gets_crazy;
    verbs @=> cooking_verbs;
  }
}

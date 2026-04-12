public class GKeyboardEvent extends Event {
  string val;

  fun @construct(string value) {
    value => val;
  }
}

public class GKeyboardReceiver {
  [
    "a","b","c","d","e","f","g","h","i",
    "j","k","l","m","n","o","p","q","r",
    "s","t","u","v","w","x","y","z"
  ] @=> string CHARS_LOWERCASE[];
  [
    "A","B","C","D","E","F","G","H","I",
    "J","K","L","M","N","O","P","Q","R",
    "S","T","U","V","W","X","Y","Z"
  ] @=> string CHARS_UPPERCASE[];
  [
    "0","1","2","3","4","5","6","7","8","9"
  ] @=> string CHARS_DIGITS[];
  // same order as 0 thru 9, mapped to what the
  // keyboard keys correspond to irl
  [
    ")","!","@","#","$","%","^","&","*","("
  ] @=> string CHARS_DIGITS_SHIFTED[];
  //TODO:
  [""] @=> string MISC_DIGITS[];

  GKeyboardEvent wait_for_text;

  fun @construct() {

  }

  fun listen() {
    (
      GWindow.key(GWindow.KEY_LEFTSHIFT) ||
      GWindow.key(GWindow.KEY_RIGHTSHIFT)
    ) => int has_shift;
    GWindow.keysDown() @=> int keys_down[];
    int key;
    string str_full;
    for (0 => int i; i < keys_down.size(); i++) {
      keys_down[i] => key;
      string str;

      // numbers
      if (key >= GWindow.KEY_0 && key <= GWindow.KEY_9) {
        key - GWindow.KEY_0 => int key_idx;
        (has_shift ? CHARS_DIGITS_SHIFTED[key_idx] : CHARS_DIGITS[key_idx]) => str;
      }
      // letters a-z (or A-Z)
      if (key >= GWindow.KEY_A && key <= GWindow.KEY_Z) {
        key - GWindow.KEY_A => int key_idx;
        (has_shift ? CHARS_UPPERCASE[key_idx] : CHARS_LOWERCASE[key_idx]) => str;
      }

      str +=> str_full;
    }

    if (str_full.length()) {
      str_full => wait_for_text.val;
      wait_for_text.signal();
    }
  }
}
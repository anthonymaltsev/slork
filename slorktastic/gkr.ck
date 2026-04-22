public class GKeyboardEvent extends Event {
  string val;
  int backspace;
  int ctrl;
  int enter;

  fun @construct(string value) {
    value => val;

    0 => backspace;
    0 => ctrl;
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


  string MISC_CHARS[0xff];
  ",<" => MISC_CHARS[44];
  ".>" => MISC_CHARS[46];
  "/?" => MISC_CHARS[47];
  ";:" => MISC_CHARS[59];
  "'\"" => MISC_CHARS[39];
  "[{" => MISC_CHARS[91];
  "]}" => MISC_CHARS[93];
  "\\|" => MISC_CHARS[92];
  "-_" => MISC_CHARS[45];
  "=+" => MISC_CHARS[61];
  "`~" => MISC_CHARS[96];

  GKeyboardEvent wait;

  fun @construct() {

  }

  fun listen() {
    (
      GWindow.key(GWindow.KEY_LEFTSHIFT) ||
      GWindow.key(GWindow.KEY_RIGHTSHIFT)
    ) => int has_shift;
    (
      GWindow.key(GWindow.KEY_LEFTCONTROL) ||
      GWindow.key(GWindow.KEY_RIGHTCONTROL)
    ) => int has_ctrl;
    has_ctrl => wait.ctrl;

    GWindow.keysDown() @=> int keys_down[];
    int key;
    string str_full;
    for (0 => int i; i < keys_down.size(); i++) {
      keys_down[i] => key;
      string str;

      // moved out of the conditional so they always update
      key == GWindow.KEY_BACKSPACE => wait.backspace;
      key == GWindow.KEY_ENTER => wait.enter;

      if (key == GWindow.KEY_BACKSPACE || key == GWindow.KEY_ENTER) {
        "" => wait.val;
        wait.signal();
        continue;
      }
      
      if (key == GWindow.KEY_SPACE) {
        " " => str;
      } else if (key >= GWindow.KEY_0 && key <= GWindow.KEY_9) {
        // numbers
        key - GWindow.KEY_0 => int key_idx;
        (has_shift ? CHARS_DIGITS_SHIFTED[key_idx] : CHARS_DIGITS[key_idx]) => str;
      } else if (key >= GWindow.KEY_A && key <= GWindow.KEY_Z) {
        // letters a-z (or A-Z)
        key - GWindow.KEY_A => int key_idx;
        (has_shift ? CHARS_UPPERCASE[key_idx] : CHARS_LOWERCASE[key_idx]) => str;
      } else if (key < 0x100 && MISC_CHARS[key] != null) {
        MISC_CHARS[key].charAt2(has_shift) => str;
      }

      str +=> str_full;
    }

    if (str_full.length()) {
      str_full => wait.val;
      0 => wait.backspace;
      wait.signal();
    }
  }
}
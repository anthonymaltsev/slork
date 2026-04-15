@import {"clawed-code.ck"};

ClawedCode code();
spork ~ code.run();

while (true) {
  code.wait => now;
  <<< code.wait.prompt, "BUZZ", code.wait.buzzwords >>>;
}
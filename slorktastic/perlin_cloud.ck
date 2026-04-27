@import {"perlin.ck"}

public class PerlinCloud {
  GGen elements[0];
  Perlin2D perlin[0];

  0 => int wait_count;
  10 => int max_wait;

  1003 => int perlin_seed_base;
  0.07 => float perlin_freq_factor;
  8. => float perlin_amp;
  1::second => dur freq;

  1. => float scale;

  // visualization on/off; gates pos() and toggles scene attachment
  1 => int enabled;

  fun @construct() {}

  fun @construct(dur freq_in, float scale_in) {
    freq_in => freq;
    scale_in => scale;
  }

  fun @construct(dur freq_in, float scale_in, int max_wait_in) {
    freq_in => freq;
    scale_in => scale;
    max_wait_in => max_wait;
  }

  fun void set_perlin_params(int seed_base, float freq_factor, float amp) {
    seed_base => perlin_seed_base;
    freq_factor => perlin_freq_factor;
    amp => perlin_amp;
  }

  fun int count() {
    return elements.size();
  }

  fun void add(GGen elem) {
    elements.size() => int i;
    elements << elem;
    Perlin2D p;
    p.init(perlin_seed_base + i, freq * (1. + i * perlin_freq_factor), perlin_amp);
    perlin << p;
    if (enabled) elem --> GG.scene();
  }

  fun void remove_at(int idx) {
    if (idx < 0 || idx >= elements.size()) return;
    if (enabled) elements[idx] --< GG.scene();
    elements.popOut(idx);
    perlin.popOut(idx);
  }

  fun void clear() {
    while (elements.size() > 0) remove_at(elements.size() - 1);
  }

  fun void enable() {
    set_enabled(1);
  }
  fun void disable() {
    set_enabled(0);
  }

  fun void set_enabled(int on) {
    if (on == enabled) return;
    on => enabled;
    for (0 => int i; i < elements.size(); i++) {
      if (on) elements[i] --> GG.scene();
      else elements[i] --< GG.scene();
    }
  }

  //--override hooks–-
  fun time _sample_time(int i) {
    return now + 8::second;
  }
  fun vec3 _position_for(int i, vec3 base, vec2 perlin_offset) {
    return base + @(perlin_offset.x, perlin_offset.y, 0.);
  }

  fun void pos(vec3 base) {
    if (!enabled) return;
    if (++wait_count >= max_wait) {
      0 => wait_count;
      for (0 => int i; i < elements.size(); i++) {
        perlin[i].generate(_sample_time(i)) => vec2 raw;
        elements[i].pos(_position_for(i, base, raw));
      }
    }
  }
}

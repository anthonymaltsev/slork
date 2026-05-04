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

  // bounding-box constraint applied in pos(). while _constrained, each
  // element is anchored at a uniform-random "home" inside the box and
  // the perlin output is rescaled into a small jitter around home;
  // this avoids the edge-clustering you get from clamping post-hoc.
  // bounds inert until set_constraint_bounds is called
  1 => int _constrained;
  0 => int _has_constraint_bounds;
  vec3 _constraint_center;
  1. => float _constraint_w;
  1. => float _constraint_h;
  0. => float _constraint_margin_x;
  0. => float _constraint_margin_y;
  // while constrained, homes are placed UNIFORMLY across the full
  // inner box (stochastically that is), and motion is a fraction of
  // inner_half per axis
  0.35 => float _constrained_motion_range;
  vec3 _home_positions[0];
  int _home_initialized[0];

  vec3 _last_base;
  0 => int _has_last_base;

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

  fun void set_constrained(int on) {
    on => _constrained;
    // each new constrained "session" gets fresh random homes
    if (on) _invalidate_homes();
  }

  fun void set_constraint_bounds(vec3 center, float w, float h, float margin_x, float margin_y) {
    center => _constraint_center;
    w => _constraint_w;
    h => _constraint_h;
    margin_x => _constraint_margin_x;
    margin_y => _constraint_margin_y;
    1 => _has_constraint_bounds;
    // bounds changed => any existing homes are stale
    // bye felicia!
    _invalidate_homes();
  }

  fun void _invalidate_homes() {
    for (0 => int i; i < _home_initialized.size(); i++) 0 => _home_initialized[i];
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
    _home_positions << @(0., 0., 0.);
    _home_initialized << 0;
    if (enabled) elem --> GG.scene();
    _position_initial(i);
  }

  fun void _position_initial(int i) {
    perlin[i].generate(_sample_time(i)) => vec2 raw;
    if (_constrained && _has_constraint_bounds) {
      elements[i].pos(_constrained_pos_for(i, raw));
    } else if (_has_last_base) {
      elements[i].pos(_position_for(i, _last_base, raw));
    }
  }

  fun void remove_at(int idx) {
    if (idx < 0 || idx >= elements.size()) return;
    if (enabled) elements[idx] --< GG.scene();
    elements.popOut(idx);
    perlin.popOut(idx);
    _home_positions.popOut(idx);
    _home_initialized.popOut(idx);
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

  // override to contribute a per-element half-extent (e.g. text width
  // for variable-size GText, as done in WordCloud) atop the global margin
  fun vec2 _element_half_extent(int i) {
    return @(0., 0.);
  }

  fun vec2 _inner_half_bounds(int i) {
    _element_half_extent(i) => vec2 em;
    _constraint_w/2. - _constraint_margin_x - em.x => float hx;
    _constraint_h/2. - _constraint_margin_y - em.y => float hy;
    // guard against bounds smaller than the element+margin
    if (hx < 0.) 0. => hx;
    if (hy < 0.) 0. => hy;
    return @(hx, hy);
  }

  fun void _ensure_home(int i) {
    if (_home_initialized[i]) return;
    _inner_half_bounds(i) => vec2 inner;
    // uniform across the full inner box
    @(
      _constraint_center.x + Math.random2f(-inner.x, inner.x),
      _constraint_center.y + Math.random2f(-inner.y, inner.y),
      _constraint_center.z
    ) => _home_positions[i];
    1 => _home_initialized[i];
  }

  fun vec3 _clamp_to_bounds(int i, vec3 p) {
    _inner_half_bounds(i) => vec2 hb;
    return @(
      Math.clampf(p.x, _constraint_center.x - hb.x, _constraint_center.x + hb.x),
      Math.clampf(p.y, _constraint_center.y - hb.y, _constraint_center.y + hb.y),
      _constraint_center.z
    );
  }

  fun vec3 _constrained_pos_for(int i, vec2 raw) {
    _ensure_home(i);
    _inner_half_bounds(i) => vec2 inner;
    if (perlin_amp == 0.) return _home_positions[i];
    inner.x * _constrained_motion_range / perlin_amp => float jx;
    inner.y * _constrained_motion_range / perlin_amp => float jy;
    _home_positions[i] + @(raw.x * jx, raw.y * jy, 0.) => vec3 p;
    return _clamp_to_bounds(i, p);
  }

  fun void pos(vec3 base) {
    if (!enabled) return;
    base => _last_base;
    1 => _has_last_base;
    if (++wait_count >= max_wait) {
      0 => wait_count;
      for (0 => int i; i < elements.size(); i++) {
        perlin[i].generate(_sample_time(i)) => vec2 raw;
        vec3 final_pos;
        if (_constrained && _has_constraint_bounds) {
          _constrained_pos_for(i, raw) => final_pos;
        } else {
          _position_for(i, base, raw) => final_pos;
        }
        elements[i].pos(final_pos);
      }
    }
  }
}

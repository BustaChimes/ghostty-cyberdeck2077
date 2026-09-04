// Cyberpunk 2077 terminal shader for Ghostty — v3
// Less frequent glitches, 7 different glitch modes, randomized intensity + duration.

const float SCANLINE_STRENGTH = 0.12;
const float ABERRATION_PX     = 1.2;    // color fringe in PIXELS (font-size independent)
const float GLITCH_CHANCE     = 0.08;   // per half-second window (was 0.08)
const float VIGNETTE          = 0.40;
const float GRAIN             = 0.015;
const float INVERT_SHARE      = 0.10;   // fraction of glitches upgraded to mode 6 (invert flash)
const vec3  NEON_YELLOW       = vec3(0.988, 0.933, 0.039);
const vec3  NEON_CYAN         = vec3(0.000, 0.941, 1.000);
const vec3  NEON_MAGENTA      = vec3(1.000, 0.180, 0.592);

float hash(float n)  { return fract(sin(n) * 43758.5453123); }
float hash2(vec2 p)  { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float t = iTime;

    // ---- glitch scheduler ----
    float window   = floor(t * 2.0);           // 0.5s windows
    float wfrac    = fract(t * 2.0);
    float glitchOn = step(1.0 - GLITCH_CHANCE, hash(window));
    float mode     = floor(hash(window * 3.3 + 1.0) * 6.0);   // which effect: 0..5
    mode = mix(mode, 6.0, step(1.0 - INVERT_SHARE, hash(window * 6.6 + 4.0))); // rare upgrade: 6
    float dur      = 0.12 + hash(window * 5.7 + 2.0) * 0.5;   // how long it lasts (6%..31% of window)
    float amp      = 0.5 + hash(window * 9.1 + 3.0);          // intensity 0.5..1.5
    float sub      = floor(t * 24.0);                         // flicker sub-frames
    glitchOn      *= step(wfrac, dur);

    float px    = 1.0 / iResolution.x;      // one pixel in uv units
    float ca    = ABERRATION_PX * px;
    float flash = 0.0;
    float swap  = 0.0;   // channel-swap tint on a block
    float dim   = 1.0;
    float crpt  = 0.0;   // mode 5: cell corruption amount
    vec3  ctint = NEON_CYAN;
    float inv   = 0.0;   // mode 6: full-frame invert

    if (glitchOn > 0.5) {
        if (mode < 0.5) {
            // 0: horizontal band tear (the classic)
            float bands = 24.0 + floor(hash(window * 2.2) * 40.0);
            float band  = floor(uv.y * bands + hash(sub * 7.1) * bands);
            float br    = hash(band + sub * 13.7);
            uv.x += step(0.7, br) * (br - 0.5) * 0.04 * amp;
            ca   += 3.0 * px * amp;
        } else if (mode < 1.5) {
            // 1: RGB split spike (whole screen)
            ca = 8.0 * px * amp * (0.5 + 0.5 * hash(sub));
        } else if (mode < 2.5) {
            // 2: block displacement — random rectangles jump, some tinted
            vec2  cell = floor(uv * vec2(8.0, 12.0));
            float cr   = hash2(cell + sub * 0.37);
            float hit  = step(0.85, cr);
            uv   += hit * (vec2(hash(cr * 11.0), hash(cr * 17.0)) - 0.5) * 0.03 * amp;
            swap  = step(0.96, cr);
        } else if (mode < 3.5) {
            // 3: vertical jitter (frame loses sync)
            uv.y += (hash(sub * 3.1) - 0.5) * 0.02 * amp;
            ca   += 2.0 * px * amp;
        } else if (mode < 4.5) {
            // 4: brightness flicker + a flash band
            float band = floor(uv.y * 6.0 + hash(sub) * 6.0);
            flash = step(0.8, hash(band + sub * 5.5)) * 0.2 * amp;
            dim   = 0.8 + 0.2 * hash(sub * 1.7);
        } else if (mode < 5.5) {
            // 5: glyph/block color corruption — scattered cells channel-swap + neon tint
            vec2  cell = floor(uv * vec2(40.0, 18.0));
            float cr   = hash2(cell + sub * 0.61);
            crpt = step(0.92, cr) * min(amp, 1.0);
            float pick = floor(hash(cr * 29.0 + sub) * 3.0);
            ctint = mix(NEON_CYAN, NEON_MAGENTA, step(0.5, pick));
            ctint = mix(ctint, NEON_YELLOW, step(1.5, pick));
        } else {
            // 6: full-frame invert flash (rare — see INVERT_SHARE)
            inv = 1.0;
            dim = 0.9 + 0.1 * hash(sub * 2.3);
        }
    }

    // ---- sample with chromatic aberration ----
    vec4  src = texture(iChannel0, uv);
    float r   = texture(iChannel0, uv + vec2(ca, 0.0)).r;
    float g   = src.g;
    float b   = texture(iChannel0, uv - vec2(ca, 0.0)).b;
    vec3  col = vec3(r, g, b);

    col  = mix(col, col.brg, swap);
    col *= dim;
    col += flash * NEON_YELLOW * src.a;

    // mode 5: corrupted cells — swap channels, pull toward a neon tint
    vec3 bad = mix(col.gbr, ctint * max(col.r, max(col.g, col.b)), 0.55);
    col = mix(col, bad, crpt);

    // mode 6: negative flash with a neon-yellow cast
    col = mix(col, (vec3(1.0) - col) * mix(vec3(1.0), NEON_YELLOW, 0.35), inv);

    // ---- always-on CRT feel ----
    float scan = 1.0 - SCANLINE_STRENGTH * (0.5 + 0.5 * sin(fragCoord.y * 3.14159265 / 2.0));
    col *= scan;

    float roll = abs(fract(uv.y - t * 0.06) - 0.5);
    col *= 0.97 + 0.03 * smoothstep(0.0, 0.2, roll);

    vec2 vc = uv - 0.5;
    col *= 1.0 - dot(vc, vc) * VIGNETTE;

    col += (hash2(fragCoord + fract(t) * 100.0) - 0.5) * GRAIN * src.a;

    fragColor = vec4(col, src.a);
}

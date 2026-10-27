// CATSPAW // GLITCH
// Datamosh/broken-signal look: per-row block displacement that jumps on a
// beat, RGB channel split, and occasional scanline tears. Driven by the
// vkBasalt timer so it's alive even on a still image.
#include "ReShade.fxh"

uniform float timer < source = "timer"; >;

uniform float Intensity <
    ui_type = "slider"; ui_min = 0.0; ui_max = 2.0;
> = 1.0;

uniform float Split <
    ui_type = "slider"; ui_min = 0.0; ui_max = 0.02;
> = 0.006;

float hash(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float4 PS_Glitch(float4 vpos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float t = timer * 0.001;

    // A "beat" that pulses roughly a few times a second; glitches ride its peak.
    float beat = pow(saturate(sin(t * 4.0) * 0.5 + 0.5), 4.0) * Intensity;

    // Quantize y into horizontal bands; each band gets its own random shove,
    // re-seeded every ~0.1s so blocks snap rather than slide.
    float band = floor(uv.y * 24.0);
    float seed = floor(t * 10.0);
    float r = hash(float2(band, seed));
    float shove = (r - 0.5) * 0.15 * beat * step(0.6, r);

    float2 guv = uv;
    guv.x += shove;

    // Rare full-width scanline tear.
    float tearSeed = hash(float2(seed, 7.0));
    if (tearSeed > 0.92 && abs(uv.y - hash(float2(seed, 3.0))) < 0.01)
        guv.x += (hash(float2(uv.y, seed)) - 0.5) * 0.3 * Intensity;

    guv.x = frac(guv.x);  // wrap instead of sampling black past the edge

    // RGB channel split, widened on the beat.
    float s = Split * (1.0 + beat * 3.0);
    float cr = tex2D(ReShade::BackBuffer, float2(guv.x + s, guv.y)).r;
    float cg = tex2D(ReShade::BackBuffer, guv).g;
    float cb = tex2D(ReShade::BackBuffer, float2(guv.x - s, guv.y)).b;
    float3 col = float3(cr, cg, cb);

    // Flash a few bands toward hazard yellow at the peak for a corrupted-HUD feel.
    if (beat > 0.5 && hash(float2(band, seed + 1.0)) > 0.85)
        col = lerp(col, float3(1.0, 0.8, 0.0), 0.35 * beat);

    return float4(saturate(col), 1.0);
}

technique CatspawGlitch
{
    pass { VertexShader = PostProcessVS; PixelShader = PS_Glitch; }
}

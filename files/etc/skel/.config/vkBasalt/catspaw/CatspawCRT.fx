// CATSPAW // CRT
// Fake old monitor: barrel curvature, aperture-grille RGB mask, scanlines,
// a slow brightness roll, and a corner vignette.
#include "ReShade.fxh"

uniform float timer < source = "timer"; >;

uniform float Curvature <
    ui_type = "slider"; ui_min = 0.0; ui_max = 0.3;
> = 0.10;

uniform float MaskStrength <
    ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
> = 0.5;

uniform float ScanDepth <
    ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
> = 0.4;

// Bend UVs outward from center to fake tube curvature.
float2 curve(float2 uv, float amount)
{
    uv = uv * 2.0 - 1.0;
    float2 offset = abs(uv.yx) / float2(1.0 / amount + 1.0, 1.0 / amount + 1.0);
    uv += uv * offset * offset;
    return uv * 0.5 + 0.5;
}

float4 PS_CRT(float4 vpos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 cuv = curve(uv, Curvature);

    // Anything bent past the edge of the tube is black.
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0)
        return float4(0.0, 0.0, 0.0, 1.0);

    float3 col = tex2D(ReShade::BackBuffer, cuv).rgb;

    // Aperture-grille mask: cycle emphasis R/G/B across every 3 pixels.
    float px = cuv.x * BUFFER_WIDTH;
    int m = (int)fmod(px, 3.0);
    float3 mask = float3(1.0, 1.0, 1.0);
    if (m == 0) mask = float3(1.0, 0.6, 0.6);
    else if (m == 1) mask = float3(0.6, 1.0, 0.6);
    else mask = float3(0.6, 0.6, 1.0);
    col *= lerp(float3(1.0, 1.0, 1.0), mask, MaskStrength);

    // Scanlines plus a slow vertical brightness roll.
    float scan = 0.5 + 0.5 * sin(cuv.y * BUFFER_HEIGHT * 3.14159);
    col *= 1.0 - ScanDepth * (1.0 - scan);
    float roll = 0.97 + 0.03 * sin(cuv.y * 6.2831 + timer * 0.002);
    col *= roll;

    // Corner vignette.
    float2 d = cuv - 0.5;
    col *= smoothstep(1.1, 0.5, dot(d, d) * 2.4);

    // A touch of overall gain so the mask darkening doesn't dim everything.
    col *= 1.25;
    return float4(saturate(col), 1.0);
}

technique CatspawCRT
{
    pass { VertexShader = PostProcessVS; PixelShader = PS_CRT; }
}

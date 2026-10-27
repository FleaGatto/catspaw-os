// CATSPAW // THERMAL
// Maps scene brightness to a predator-style heat gradient
// (black -> indigo -> magenta -> red -> orange -> yellow -> white),
// with faint scanlines so it reads as a sensor feed.
#include "ReShade.fxh"

uniform float Contrast <
    ui_type = "slider"; ui_min = 0.5; ui_max = 2.5;
> = 1.3;

uniform float ScanlineDepth <
    ui_type = "slider"; ui_min = 0.0; ui_max = 0.5;
> = 0.12;

float luma(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

// Six-stop heat ramp.
float3 heat(float t)
{
    t = saturate(t);
    const float3 c0 = float3(0.00, 0.00, 0.00);
    const float3 c1 = float3(0.15, 0.00, 0.35);
    const float3 c2 = float3(0.65, 0.00, 0.55);
    const float3 c3 = float3(0.95, 0.10, 0.05);
    const float3 c4 = float3(1.00, 0.55, 0.00);
    const float3 c5 = float3(1.00, 0.95, 0.30);
    const float3 c6 = float3(1.00, 1.00, 1.00);
    float s = t * 6.0;
    if (s < 1.0) return lerp(c0, c1, s);
    if (s < 2.0) return lerp(c1, c2, s - 1.0);
    if (s < 3.0) return lerp(c2, c3, s - 2.0);
    if (s < 4.0) return lerp(c3, c4, s - 3.0);
    if (s < 5.0) return lerp(c4, c5, s - 4.0);
    return lerp(c5, c6, s - 5.0);
}

float4 PS_Thermal(float4 vpos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 c = tex2D(ReShade::BackBuffer, uv).rgb;
    float l = luma(c);
    l = saturate((l - 0.5) * Contrast + 0.5);

    float3 col = heat(l);

    // Horizontal scanlines tied to the real pixel grid.
    float line = sin(uv.y * BUFFER_HEIGHT * 3.14159);
    col *= 1.0 - ScanlineDepth * (0.5 + 0.5 * line);

    return float4(saturate(col), 1.0);
}

technique CatspawThermal
{
    pass { VertexShader = PostProcessVS; PixelShader = PS_Thermal; }
}

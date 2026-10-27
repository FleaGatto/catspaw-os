// CATSPAW // HAZARD-VISION
// Posterizes the whole screen into the Catspaw palette: black field, deep
// amber mids, hazard-yellow highlights -- then paints Sobel edges in bright
// yellow so everything gets a warning-label outline.
#include "ReShade.fxh"

uniform float EdgeStrength <
    ui_type = "slider"; ui_min = 0.0; ui_max = 2.0;
> = 1.0;

uniform float Posterize <
    ui_type = "slider"; ui_min = 2.0; ui_max = 8.0;
> = 4.0;

static const float3 HAZARD   = float3(1.0, 0.80, 0.0);   // #FFCC00
static const float3 AMBER    = float3(0.55, 0.36, 0.0);
static const float3 EMBER    = float3(0.18, 0.11, 0.0);

float luma(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

float4 PS_Hazard(float4 vpos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 c = tex2D(ReShade::BackBuffer, uv).rgb;
    float l = luma(c);

    // Quantize brightness so the image reads as banded hazard zones.
    float steps = max(2.0, Posterize);
    float q = floor(l * steps) / (steps - 1.0);

    // Ramp black -> ember -> amber -> hazard across the bands.
    float3 col;
    if (q < 0.34)      col = lerp(float3(0,0,0), EMBER,  q / 0.34);
    else if (q < 0.67) col = lerp(EMBER, AMBER, (q - 0.34) / 0.33);
    else               col = lerp(AMBER, HAZARD, (q - 0.67) / 0.33);

    // Sobel edge detect on luma for the warning-label outline.
    float2 px = ReShade::PixelSize;
    float l00 = luma(tex2D(ReShade::BackBuffer, uv + float2(-px.x, -px.y)).rgb);
    float l01 = luma(tex2D(ReShade::BackBuffer, uv + float2( 0.0,  -px.y)).rgb);
    float l02 = luma(tex2D(ReShade::BackBuffer, uv + float2( px.x, -px.y)).rgb);
    float l10 = luma(tex2D(ReShade::BackBuffer, uv + float2(-px.x,  0.0)).rgb);
    float l12 = luma(tex2D(ReShade::BackBuffer, uv + float2( px.x,  0.0)).rgb);
    float l20 = luma(tex2D(ReShade::BackBuffer, uv + float2(-px.x,  px.y)).rgb);
    float l21 = luma(tex2D(ReShade::BackBuffer, uv + float2( 0.0,   px.y)).rgb);
    float l22 = luma(tex2D(ReShade::BackBuffer, uv + float2( px.x,  px.y)).rgb);
    float gx = (l02 + 2.0 * l12 + l22) - (l00 + 2.0 * l10 + l20);
    float gy = (l20 + 2.0 * l21 + l22) - (l00 + 2.0 * l01 + l02);
    float edge = saturate(sqrt(gx * gx + gy * gy) * EdgeStrength);

    col = lerp(col, HAZARD, edge);
    return float4(saturate(col), 1.0);
}

technique CatspawHazard
{
    pass { VertexShader = PostProcessVS; PixelShader = PS_Hazard; }
}

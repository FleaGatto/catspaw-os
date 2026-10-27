// CATSPAW // NIGHT-VISION
// Green-phosphor goggles: brightened monochrome, green tint, animated grain,
// scanlines, and a soft circular goggle vignette.
#include "ReShade.fxh"

uniform float timer < source = "timer"; >;   // milliseconds, from vkBasalt

uniform float Gain <
    ui_type = "slider"; ui_min = 1.0; ui_max = 6.0;
> = 3.0;

uniform float GrainAmount <
    ui_type = "slider"; ui_min = 0.0; ui_max = 0.4;
> = 0.15;

float luma(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

float hash(float2 p)
{
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

float4 PS_NightVision(float4 vpos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 c = tex2D(ReShade::BackBuffer, uv).rgb;

    // Amplify like a light intensifier, then go monochrome-green.
    float l = saturate(luma(c) * Gain);
    float3 col = float3(0.1, 1.0, 0.25) * l;

    // Animated film grain. timer/… makes the seed roll every frame.
    float g = hash(uv * ReShade::ScreenSize + frac(timer * 0.001) * 100.0);
    col += (g - 0.5) * GrainAmount;

    // Tube scanlines.
    col *= 0.85 + 0.15 * sin(uv.y * BUFFER_HEIGHT * 3.14159);

    // Circular goggle vignette.
    float2 d = uv - 0.5;
    d.x *= ReShade::ScreenSize.x / ReShade::ScreenSize.y;  // keep it round
    float v = smoothstep(0.75, 0.35, length(d));
    col *= v;

    return float4(saturate(col), 1.0);
}

technique CatspawNightVision
{
    pass { VertexShader = PostProcessVS; PixelShader = PS_NightVision; }
}

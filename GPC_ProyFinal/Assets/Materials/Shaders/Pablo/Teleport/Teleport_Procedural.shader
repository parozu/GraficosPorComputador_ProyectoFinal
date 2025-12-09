Shader "GPC/Teleport_Procedural"
{
    Properties
    {
        [_HDR] _InnerColor  ("Inner Color", Color) = (0, 0.8, 1, 1)
        [_HDR] _BorderColor ("Border Color", Color) = (0.2, 1, 2, 1)

        _Radius      ("Radius", Range(0, 1))       = 0.4
        _BorderWidth ("Border Width", Range(0, 0.5)) = 0.08
        _NoiseScale  ("Noise Scale", Range(0, 20)) = 6
        _NoiseSpeed  ("Noise Speed", Range(0, 10)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        LOD 100

        Blend SrcAlpha One         // Aditivo
        ZWrite Off
        Cull Off                   // Doble cara (puedes poner Back si solo quieres una cara)

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _InnerColor;
                float4 _BorderColor;
                float  _Radius;
                float  _BorderWidth;
                float  _NoiseScale;
                float  _NoiseSpeed;
            CBUFFER_END

            #ifndef PI
            #define PI 3.14159265359
            #endif

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = posInputs.positionCS;
                OUT.uv = IN.uv;
                return OUT;
            }

            // --- Ruido simple 2D ---
            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
            }

            float4 PortalColor(float2 uv, float time)
            {
                // Centrar UV en (0,0)
                float2 p = uv - 0.5;
                float r = length(p);
                float angle = atan2(p.y, p.x);

                // Disco interior
                float disc = 1.0 - smoothstep(_Radius - _BorderWidth, _Radius, r);

                // Anillo de borde
                float ringInner = _Radius - _BorderWidth;
                float ringOuter = _Radius + _BorderWidth;
                float ring = smoothstep(ringInner, ringInner + fwidth(r), r) *
                             (1.0 - smoothstep(ringOuter - fwidth(r), ringOuter, r));

                // Segmentos angulares para chispas
                float ang01 = angle / (2.0 * PI) + 0.5;      // 0..1
                float segments = 8.0;
                float seg = frac(ang01 * segments);

                float swirl = 0.5 + 0.5 * sin(seg * 2.0 * PI + time * _NoiseSpeed);

                // Ruido interior animado
                float2 np = p * _NoiseScale + time * _NoiseSpeed * float2(0.7, 1.3);
                float n = hash21(np);
                float flicker = lerp(0.7, 1.2, n);

                float inner = disc * flicker;
                float edge  = ring * swirl;

                float4 col;
                col.rgb = inner * _InnerColor.rgb + edge * _BorderColor.rgb;
                col.a   = saturate(inner * _InnerColor.a + edge * _BorderColor.a);
                return col;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // _Time.y es tiempo en segundos * algo (no importa demasiado para este efecto)
                float t = _Time.y;
                float4 col = PortalColor(IN.uv, t);
                return col;
            }

            ENDHLSL
        }
    }

    FallBack Off
}

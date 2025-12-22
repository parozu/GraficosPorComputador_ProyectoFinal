Shader "Custom/TP_PlayerDisappear"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        _Disappear ("Disappear (0=visible, 1=gone)", Range(0,1)) = 0
        _Feather ("Feather (soft edge)", Range(0.0001, 0.2)) = 0.02

        _BoundsMinY ("Bounds Min Y (world)", Float) = 0
        _BoundsMaxY ("Bounds Max Y (world)", Float) = 2

        _NoiseScale ("Noise Scale", Float) = 6
        _NoiseAmp ("Noise Amount", Range(0,1)) = 0.15

        _EdgeColor ("Edge Color", Color) = (0.2,0.8,1,1)
        _EdgeWidth ("Edge Width", Range(0.0001, 0.2)) = 0.03
        _EdgeAlpha ("Edge Alpha Boost", Range(0,1)) = 0.6
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "RenderType"="Transparent" }
        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;

                float _Disappear;
                float _Feather;

                float _BoundsMinY;
                float _BoundsMaxY;

                float _NoiseScale;
                float _NoiseAmp;

                float4 _EdgeColor;
                float _EdgeWidth;
                float _EdgeAlpha;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
            };

            // Ruido barato (0..1) a partir de world position
            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vp = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = vp.positionCS;
                OUT.positionWS  = vp.positionWS;
                OUT.uv          = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                float height = max(1e-5, _BoundsMaxY - _BoundsMinY);
                float yNorm = saturate((IN.positionWS.y - _BoundsMinY) / height); // 0 pies -> 1 cabeza

                // cutoff sube desde -feather hasta 1+feather: al final desaparece TODO
                float cutoff = lerp(-_Feather, 1.0 + _Feather, _Disappear);

                float n = Hash21(IN.positionWS.xz * _NoiseScale); // 0..1
                float d = yNorm + (n - 0.5) * _NoiseAmp;

                // mask=1 visible, mask=0 invisible (pies desaparecen primero)
                float mask = smoothstep(cutoff, cutoff + _Feather, d);

                // borde luminoso en el frente de desaparición
                float edge = 1.0 - saturate(abs(d - cutoff) / max(_EdgeWidth, 1e-5));
                float3 rgb = baseCol.rgb + _EdgeColor.rgb * edge; // “emisión” fake

                float alpha = baseCol.a * mask;

                // que el borde se siga viendo aunque alpha caiga
                alpha = max(alpha, edge * _EdgeAlpha);

                return half4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}

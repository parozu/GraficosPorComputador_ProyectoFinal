Shader "Custom/WatercolorArtURP"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _PaperTex ("Paper Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _LightSteps ("Light Steps", Range(2,6)) = 4
        _ShadeSoftness ("Shade Softness", Range(0,1)) = 0.5

        _NoiseStrength ("Noise Strength", Range(0,1)) = 0.4
        _NoiseScale ("Noise Scale", Range(0.1,10)) = 2

        _PaperStrength ("Paper Strength", Range(0,1)) = 0.5

        _OutlineWidth ("Outline Width", Range(0.001,0.05)) = 0.01
        _OutlineColor ("Outline Color", Color) = (0.2,0.2,0.2,1)

        _ObjectNoiseOffset ("Object Noise Offset", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);  SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_PaperTex);  SAMPLER(sampler_PaperTex);

            float4 _Color;
            float _LightSteps;
            float _ShadeSoftness;
            float _NoiseStrength;
            float _NoiseScale;
            float _PaperStrength;

            float _OutlineWidth;
            float4 _OutlineColor;

            float4 _ObjectNoiseOffset;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.posWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                // Luz y posterización
                Light mainLight = GetMainLight();
                float NdotL = saturate(dot(IN.normalWS, mainLight.direction));
                float stepped = floor(NdotL * _LightSteps) / _LightSteps;
                stepped = lerp(NdotL, stepped, _ShadeSoftness);

                // Color base
                float3 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * _Color.rgb;
                float3 color = baseCol * mainLight.color * stepped;

                // Ruido con variación por objeto
                float2 noiseUV = IN.uv * _NoiseScale + _ObjectNoiseOffset.xy;
                float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
                color *= lerp(1.0, noise, _NoiseStrength);

                // Papel
                float paper = SAMPLE_TEXTURE2D(_PaperTex, sampler_PaperTex, IN.uv * 2).r;
                color *= lerp(1.0, paper, _PaperStrength);

                return float4(color,1);
            }
            ENDHLSL
        }

        // Pass para outline
        Pass
        {
            Name "Outline"
            Tags { "LightMode"="UniversalForward" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vertOutline
            #pragma fragment fragOutline

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 posHCS : SV_POSITION;
            };

            float _OutlineWidth;
            float4 _OutlineColor;

            Varyings vertOutline(Attributes IN)
            {
                Varyings OUT;
                float3 pos = IN.positionOS.xyz + IN.normalOS * _OutlineWidth;
                OUT.posHCS = TransformObjectToHClip(pos);
                return OUT;
            }

            float4 fragOutline(Varyings IN) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }
    }
}

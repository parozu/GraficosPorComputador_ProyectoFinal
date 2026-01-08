Shader "Custom/WatercolorSimpleURP"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _Steps ("Light Steps", Range(2, 6)) = 4
        _ShadeSoftness ("Shade Softness", Range(0,1)) = 0.5

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseStrength ("Noise Strength", Range(0,1)) = 0.4

        _PaperTex ("Paper Texture", 2D) = "white" {}
        _PaperStrength ("Paper Strength", Range(0,1)) = 0.5
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
                float2 uv : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);  SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_PaperTex); SAMPLER(sampler_PaperTex);

            float4 _Color;
            float _Steps;
            float _ShadeSoftness;
            float _NoiseStrength;
            float _PaperStrength;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                Light light = GetMainLight();

                float NdotL = saturate(dot(IN.normalWS, light.direction));
                float stepped = floor(NdotL * _Steps) / _Steps;
                stepped = lerp(NdotL, stepped, _ShadeSoftness);

                float3 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                float3 color = baseCol * _Color.rgb * light.color * stepped;

                // Ruido en UV (muy visible)
                float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv * 4).r;
                color *= lerp(1.0, noise, _NoiseStrength);

                // Papel
                float paper = SAMPLE_TEXTURE2D(_PaperTex, sampler_PaperTex, IN.uv * 2).r;
                color *= lerp(1.0, paper, _PaperStrength);

                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}


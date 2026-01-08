Shader "Custom/WatercolorLitURP_Debug"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}

        _PaperTex ("Paper Texture (Contrast!)", 2D) = "white" {}
        _PaperStrength ("Paper Strength", Range(0, 1)) = 0.5

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseScale ("Noise Scale", Range(0.1, 10)) = 2
        _NoiseStrength ("Noise Strength", Range(0, 1)) = 0.5

        _LightSteps ("Light Steps", Range(2, 8)) = 4
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
                float3 positionWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);  SAMPLER(sampler_MainTex);
            TEXTURE2D(_PaperTex); SAMPLER(sampler_PaperTex);
            TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);

            float _PaperStrength;
            float _NoiseScale;
            float _NoiseStrength;
            float _LightSteps;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                Light light = GetMainLight();
                float NdotL = saturate(dot(IN.normalWS, light.direction));

                // Posterización de luz
                float steppedLight = floor(NdotL * _LightSteps) / _LightSteps;

                float3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                float3 color = albedo * light.color * steppedLight;

                // Ruido (muy visible)
                float2 noiseUV = IN.positionWS.xz * _NoiseScale;
                float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
                noise = lerp(1.0, noise, _NoiseStrength);
                color *= noise;

                // Papel (absorción)
                float paper = SAMPLE_TEXTURE2D(
                    _PaperTex,
                    sampler_PaperTex,
                    IN.positionWS.xz * 0.5
                ).r;

                color *= lerp(1.0, paper, _PaperStrength);

                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}

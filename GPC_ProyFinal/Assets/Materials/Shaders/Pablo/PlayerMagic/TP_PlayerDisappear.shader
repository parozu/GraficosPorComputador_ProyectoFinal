Shader "Custom/TP_PlayerDisappear_Lit"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        // Lighting (simple)
        _AmbientStrength ("Ambient Strength", Range(0,1)) = 0.25
        _SpecColor ("Spec Color", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0,1)) = 0.2

        // Modo manual (si _AutoCycle = 0)
        _Disappear ("Disappear (0=visible, 1=gone)", Range(0,1)) = 0
        _Feather ("Feather (soft edge)", Range(0.0001, 0.2)) = 0.02

        // Importante: estos límites deben cubrir desde los pies hasta la cabeza del player (en WORLD).
        _BoundsMinY ("Bounds Min Y (world)", Float) = 0
        _BoundsMaxY ("Bounds Max Y (world)", Float) = 2

        _NoiseScale ("Noise Scale", Float) = 6
        _NoiseAmp ("Noise Amount", Range(0,1)) = 0.15

        _EdgeColor ("Edge Color", Color) = (0.2,0.8,1,1)
        _EdgeWidth ("Edge Width", Range(0.0001, 0.2)) = 0.03
        _EdgeAlpha ("Edge Alpha Boost", Range(0,1)) = 0.6

        // --- AUTO: Desaparecer (pies->cabeza), esperar 5s, aparecer (cabeza->pies) ---
        [Toggle] _AutoCycle ("Auto Cycle", Float) = 0
        _AutoStartTime ("Auto Start Time (seconds)", Float) = 0
        _DisappearDuration ("Auto Disappear Duration (s)", Float) = 1
        _HoldGone ("Auto Hold Gone (s)", Float) = 5
        _AppearDuration ("Auto Appear Duration (s)", Float) = 1
        [Toggle] _AutoLoop ("Auto Loop", Float) = 0
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

            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;

                float _AmbientStrength;
                float4 _SpecColor;
                float _Smoothness;

                float _Disappear;
                float _Feather;

                float _BoundsMinY;
                float _BoundsMaxY;

                float _NoiseScale;
                float _NoiseAmp;

                float4 _EdgeColor;
                float _EdgeWidth;
                float _EdgeAlpha;

                float _AutoCycle;
                float _AutoStartTime;
                float _DisappearDuration;
                float _HoldGone;
                float _AppearDuration;
                float _AutoLoop;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
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
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            // Devuelve:
            //  phase: 0=desapareciendo, 1=hold invisible, 2=apareciendo
            //  prog: progreso 0..1 de la fase activa (en hold es 1)
            void GetAutoPhase(out int phase, out float prog)
            {
                float dT = max(0.0, _Time.y - _AutoStartTime);

                float disDur = max(1e-4, _DisappearDuration);
                float appDur = max(1e-4, _AppearDuration);
                float hold   = max(0.0, _HoldGone);

                float total = disDur + hold + appDur;
                if (_AutoLoop > 0.5)
                {
                    // fmod seguro
                    dT = dT - total * floor(dT / total);
                }
                else
                {
                    dT = min(dT, total);
                }

                if (dT < disDur)
                {
                    phase = 0;
                    prog = saturate(dT / disDur); // 0..1
                }
                else if (dT < disDur + hold)
                {
                    phase = 1;
                    prog = 1.0;
                }
                else
                {
                    phase = 2;
                    prog = saturate((dT - disDur - hold) / appDur); // 0..1
                }
            }

            half3 ShadeOneLight(Light light, half3 normalWS, half3 viewDirWS, half3 albedo)
            {
                half atten = light.distanceAttenuation * light.shadowAttenuation;
                half3 diff = LightingLambert(light.color, light.direction, normalWS) * atten;
                half3 spec = LightingSpecular(light.color, light.direction, normalWS, viewDirWS, _SpecColor, _Smoothness) * atten;
                return albedo * diff + spec;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                // Normalizamos altura en world Y (0 pies -> 1 cabeza)
                float height = max(1e-5, _BoundsMaxY - _BoundsMinY);
                float yNorm  = saturate((IN.positionWS.y - _BoundsMinY) / height);

                float n = Hash21(IN.positionWS.xz * _NoiseScale); // 0..1
                float noise = (n - 0.5) * _NoiseAmp;

                // ------------------------
                // Elegimos modo manual o auto
                // ------------------------
                float mask = 1.0;
                float edge = 0.0;
                float edgeFactor = 0.0;

                if (_AutoCycle > 0.5)
                {
                    int phase;
                    float prog;
                    GetAutoPhase(phase, prog);

                    if (phase == 1)
                    {
                        // Totalmente invisible durante el hold
                        mask = 0.0;
                        edge = 0.0;
                        edgeFactor = 0.0;
                    }
                    else if (phase == 0)
                    {
                        // DESAPARECER: pies -> cabeza
                        float cutoff = lerp(-_Feather, 1.0 + _Feather, prog);
                        float d = (yNorm + noise);
                        mask = smoothstep(cutoff, cutoff + _Feather, d);

                        edge = 1.0 - saturate(abs(d - cutoff) / max(_EdgeWidth, 1e-5));
                        edgeFactor = step(1e-4, prog) * (1.0 - step(1.0 - 1e-4, prog));
                    }
                    else
                    {
                        // APARECER: cabeza -> pies
                        float cutoff = lerp(-_Feather, 1.0 + _Feather, prog);
                        float yHeadToFeet = (1.0 - yNorm);
                        float d = (yHeadToFeet + noise);
                        mask = 1.0 - smoothstep(cutoff, cutoff + _Feather, d);

                        edge = 1.0 - saturate(abs(d - cutoff) / max(_EdgeWidth, 1e-5));
                        edgeFactor = step(1e-4, prog) * (1.0 - step(1.0 - 1e-4, prog));
                    }
                }
                else
                {
                    // MANUAL: el comportamiento original (desaparece pies->cabeza según _Disappear)
                    float cutoff = lerp(-_Feather, 1.0 + _Feather, _Disappear);
                    float d = (yNorm + noise);
                    mask = smoothstep(cutoff, cutoff + _Feather, d);

                    edge = 1.0 - saturate(abs(d - cutoff) / max(_EdgeWidth, 1e-5));
                    edgeFactor = step(1e-4, _Disappear) * (1.0 - step(1.0 - 1e-4, _Disappear));
                }

                edge *= edgeFactor;

                // --- Lighting (simple) ---
                half3 albedo = baseCol.rgb;
                half3 normalWS = normalize((half3)IN.normalWS);
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);

                half3 ambient = SampleSH(normalWS) * _AmbientStrength;
                half3 lit = albedo * ambient;

                Light mainLight = GetMainLight();
                lit += ShadeOneLight(mainLight, normalWS, viewDirWS, albedo);

                InputData inputData = (InputData)0;
                inputData.positionWS = IN.positionWS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = viewDirWS;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);

                uint pixelLightCount = GetAdditionalLightsCount();
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light addLight = GetAdditionalLight(lightIndex, inputData.positionWS, half4(1,1,1,1));
                    lit += ShadeOneLight(addLight, normalWS, viewDirWS, albedo);
                LIGHT_LOOP_END

                // Emisión fake en el borde (no afectada por la luz)
                float3 rgb = lit + _EdgeColor.rgb * edge;

                float alpha = baseCol.a * mask;

                // que el borde se siga viendo aunque alpha caiga
                alpha = max(alpha, edge * _EdgeAlpha);

                return half4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}
